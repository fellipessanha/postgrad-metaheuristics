using BenchmarkTools
using JSON
using Statistics
using Random
struct PackagesStrategy
    used_package_threshold::Float64
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

function decode(problem::ProblemContext, individual::AbstractArray, strategy::PackagesStrategy)
    return [idx for (idx, gene) in enumerate(individual) if gene > strategy.used_package_threshold]
end

function search(
    brkga_config::BRKGAConfig,
    problem::ProblemContext,
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

test_instances = ["sukp02_100_85_0.10_0.75.txt", "sukp07_285_300_0.10_0.75.txt", "sukp28_485_500_0.15_0.85.txt"]

function get_instance_filepaths(instances = test_instances)
    return Iterators.map(instance -> joinpath("../Implementation/test/instances", instance), instances)
end

function test_brkga(
    population_size = 120,
    elitism = 0.14,
    mutations = 0.2,
    iterations = 10000,
    crossover_points = 0.97,
    random_seed = 42,
)
    if random_seed != nothing
        Random.seed!(random_seed)
    end
    populations = []
    data = []
    for instance in get_instance_filepaths() |> collect
        println("running brkga for instance $(instance)")
        context = instance |> open |> make_problem_context_from_file
        evaluator = solution -> evaluate(context, solution)
        brkga_config =
            BRKGAConfig(population_size, elitism, mutations, iterations, PackagesStrategy(crossover_points), 10, 0.6)

        runtime = @elapsed population = search(brkga_config, context, Maximize)
        decoder = individual -> decode(context, individual, brkga_config.strategy)

        insertion = (sort([p |> decoder for p in population], rev = true, by = evaluator), runtime)
        @show insertion[1][1] |> evaluator

        push!(populations, insertion)
        push!(data, (insertion[1][1], evaluate(context, insertion[1][1]), get_cost(context, insertion[1][1])))
    end

    json_data = [Dict("solution" => sol, "score" => eval, "cost" => cost) for (sol, eval, cost) in data]
    write("brkga_output.json", JSON.json(json_data))
    return populations
end
