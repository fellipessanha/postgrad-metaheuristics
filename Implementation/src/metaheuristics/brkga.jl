using BenchmarkTools
using JSON
using Statistics
using Random
struct PackagesStrategy
    used_package_threshold::Float64
end

struct GraspThresholdStrategy
    use_item_threshold::Float64
    α::Float64
end

struct BRKGAConfig
    population_size::Integer
    mutant_percent::Float32
    elitism_percent::Float32
    max_iterations::Integer
    strategy::Any
    max_time::Union{Real,Nothing}
    elite_bias::Float32
end

function encode(problem::ProblemContext, _::PackagesStrategy)
    return [rand() for _ in 1:problem.package_count]
end

function encode(problem::ProblemContextPenalties, strategy::GraspThresholdStrategy)
    # Generate a feasible solution using greedy constructive
    solution = generate_random_greedy_initial_solution(problem, strategy.α)

    # Encode: selected items get keys in [threshold, 1], others in [0, threshold)
    threshold = strategy.use_item_threshold
    return [
        if idx in solution.items
            threshold + rand() * (1 - threshold)  # [threshold, 1]
        else
            rand() * threshold  # [0, threshold)
        end for idx in 1:problem.item_count
    ]
end

function decode(problem::ProblemContext, individual::AbstractArray, strategy::PackagesStrategy)
    return [idx for (idx, gene) in enumerate(individual) if gene > strategy.used_package_threshold]
end

function decode(problem::ProblemContextPenalties, individual::AbstractArray, strategy::GraspThresholdStrategy)
    return [idx for (idx, gene) in enumerate(individual) if gene > strategy.use_item_threshold]
end

function search(
    brkga_config::BRKGAConfig,
    problem::Union{ProblemContext,ProblemContextPenalties},
    ::Type{EvaluatorType},
) where {EvaluatorType<:EvaluationType}
    init_time = time()
    population = [encode(problem, brkga_config.strategy) for _ in 1:brkga_config.population_size]
    @debug "population size = $(problem.package_count)"
    decoder = individual -> decode(problem, individual, brkga_config.strategy)
    evaluator = solution -> evaluate(problem, solution)
    counter = 0

    while counter < brkga_config.max_iterations && time() - init_time < brkga_config.max_time
        evaluated = [(p, p |> decoder |> evaluator) for p in population]
        sort!(evaluated, by = p -> p[2], rev = EvaluationType != Maximize)

        elite_size = round(Integer, brkga_config.elitism_percent * length(evaluated))
        mutation_size = round(Integer, brkga_config.mutant_percent * length(evaluated))

        elites = [genes for (genes, _) in evaluated[1:elite_size]]
        normal_parents = [genes for (genes, _) in evaluated[(elite_size+1):end]]

        non_elites = [
            crossover(rand(elites), rand(normal_parents), brkga_config.elite_bias) for
            _ in 1:(length(population)-elite_size-mutation_size)
        ]

        mutants = [encode(problem, brkga_config.strategy) for _ in 1:mutation_size]
        population = vcat(elites, non_elites, mutants)

        counter += 1
    end
    return population
end

function crossover(elite::AbstractVector, normal::AbstractVector, bias::Real)::AbstractArray{Real}
    return [rand() > bias ? elite[key] : normal[key] for key in eachindex(normal)]
end

# Instance paths
test_kpf_instances = ["04_id_104b_objs_500_size_1500_sets_3000_maxNumConflicts_2_maxCost_15_seme_1328.txt"]
test_kp_dependencies_instances = ["prob-software-85-100-812-12180.txt"]

function get_kpf_instance_filepaths(instances = test_kpf_instances)
    return Iterators.map(instance -> joinpath("test/kpf_instances/LK/500", instance), instances)
end

function get_kp_dependencies_instance_filepaths(instances = test_kp_dependencies_instances)
    return Iterators.map(instance -> joinpath("test/instances", instance), instances)
end

# Abstract test_brkga that works with any problem type
function test_brkga(
    problem::Union{ProblemContext,ProblemContextPenalties};
    strategy::Union{PackagesStrategy,GraspThresholdStrategy} = PackagesStrategy(0.5),
    population_size = 120,
    elitism = 0.14,
    mutations = 0.2,
    iterations = 10000,
    crossover_points = 0.97,
    max_time = 10,
    elite_bias = 0.6,
    random_seed = 42,
)
    if random_seed !== nothing
        Random.seed!(random_seed)
    end

    evaluator = solution -> evaluate(problem, solution)
    brkga_config = BRKGAConfig(population_size, elitism, mutations, iterations, strategy, max_time, elite_bias)

    runtime = @elapsed population = search(brkga_config, problem, Maximize)
    decoder = individual -> decode(problem, individual, brkga_config.strategy)

    sorted_solutions = sort([p |> decoder for p in population], rev = true, by = evaluator)
    best_solution = sorted_solutions[1]
    best_score = evaluator(best_solution)

    @show best_score

    return (solutions = sorted_solutions, runtime = runtime, best_solution = best_solution, best_score = best_score)
end

# Test BRKGA for KPF instances (Knapsack with Penalties/Forfeits)
function test_brkga_kpf(;
    population_size = 120,
    elitism = 0.14,
    mutations = 0.2,
    iterations = 10000,
    crossover_points = 0.97,
    random_seed = 42,
)
    results = []
    for instance in get_kpf_instance_filepaths() |> collect
        println("running brkga for KPF instance $(instance)")
        context = instance |> open |> make_kpf_context_from_file

        result = test_brkga(
            context;
            strategy = GraspThresholdStrategy(0.5, 0.7),
            population_size = population_size,
            elitism = elitism,
            mutations = mutations,
            iterations = iterations,
            crossover_points = crossover_points,
            random_seed = random_seed,
        )

        push!(results, (instance = instance, result = result))
    end

    json_data = [
        Dict("instance" => r.instance, "solution" => r.result.best_solution, "score" => r.result.best_score) for
        r in results
    ]
    write("brkga_kpf_output.json", JSON.json(json_data))
    return results
end

# Test BRKGA for KP with Dependencies instances
function test_brkga_kp_dependencies(;
    population_size = 120,
    elitism = 0.14,
    mutations = 0.2,
    iterations = 10000,
    crossover_points = 0.97,
    random_seed = 42,
)
    results = []
    for instance in get_kp_dependencies_instance_filepaths() |> collect
        println("running brkga for KP with Dependencies instance $(instance)")
        context = instance |> open |> make_problem_context_from_file

        result = test_brkga(
            context;
            strategy = GraspThresholdStrategy(0.5, 0.5),
            population_size = population_size,
            elitism = elitism,
            mutations = mutations,
            iterations = iterations,
            crossover_points = crossover_points,
            random_seed = random_seed,
        )

        push!(results, (instance = instance, result = result, cost = get_cost(context, result.best_solution)))
    end

    json_data = [
        Dict(
            "instance" => r.instance,
            "solution" => r.result.best_solution,
            "score" => r.result.best_score,
            "cost" => r.cost,
        ) for r in results
    ]
    write("brkga_kp_dependencies_output.json", JSON.json(json_data))
    return results
end
