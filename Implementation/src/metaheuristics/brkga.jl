using BenchmarkTools
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
    population = [encode(problem, brkga_config.strategy) for _ in 1:brkga_config.population_size]
    @info "population size = $(problem.package_count)"
    decoder = individual -> decode(problem, individual, brkga_config.strategy)
    evaluator = solution -> evaluate(problem, solution)
    counter = 0

    while counter < brkga_config.max_iterations
        evaluated = [(p, p |> decoder |> evaluator) for p in population]
        sort!(evaluated, by = p -> p[2], rev = EvaluationType != Maximize)

        elite_size = round(Integer, brkga_config.elitism_percent * length(evaluated))
        mutation_size = round(Integer, brkga_config.mutant_percent * length(evaluated))

        final_population = [genes for (genes, _) in evaluated[1:elite_size]]
        elite_crossover_idx = rand(1:elite_size)
        elite_candidate = evaluated[elite_crossover_idx]
        evaluated[elite_crossover_idx], evaluated[1] = evaluated[1], evaluated[elite_crossover_idx]
        popfirst!(evaluated)

        crossovers = length(population) - elite_size - mutation_size
        for _ in 1:crossovers
            candidate = rand(evaluated)
            seed = rand(1:min(length(candidate), length(elite_candidate)))

            elite_part = elite_candidate[1][1:seed]
            random_part = candidate[1][seed:length(candidate)]
            push!(final_population, cat(elite_part, random_part, dims = 1) |> shuffle)
        end

        while length(final_population) < length(population)
            push!(final_population, encode(problem, brkga_config.strategy))
        end
        population = final_population

        counter += 1
    end
    return population
end

test_instances = ["prob-software-85-100-812-12180.txt"]

function get_instance_filepaths(instances = test_instances)
    return Iterators.map(instance -> joinpath("test/instances", instance), instances)
end

function test_brkga()
    test_instance_filepaths = get_instance_filepaths() |> collect
    context = test_instance_filepaths[1] |> open |> make_problem_context_from_file
    brkga_config = BRKGAConfig(100, 0.1, 0.15, 6000, PackagesStrategy(0.5))
    populations = []
    for i in 1:30
        @info "running iteration #$(i)"
        runtime = @elapsed population = search(brkga_config, context, Maximize)
        decoder = individual -> decode(context, individual, brkga_config.strategy)
        evaluator = solution -> evaluate(context, solution)

        insertion = [p |> decoder |> evaluator for p in population], runtime
        @show insertion
        push!(populations, (insertion))
    end

    @show populations
    return populations
end
