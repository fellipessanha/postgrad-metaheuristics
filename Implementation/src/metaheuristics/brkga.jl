struct PackagesStrategy
    used_package_threshold::Float64
end

struct BRKGAConfig
    population_size::Integer
    mutant_percent::Float32
    elitism_percent::Float32
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

    evaluated = [(p, p |> decoder |> evaluator) for p in population]

    sort!(evaluated, by = p -> p[2], rev = EvaluationType != Maximize)

    elite_size = round(Integer, brkga_config.elitism_percent * length(evaluated))
    mutation_size = round(Integer, brkga_config.mutant_percent * length(evaluated))

    @info "elite: $(elite_size); mutants: $(mutation_size), total: $(length(evaluated))"

    final_population = [genes for (genes, _) in evaluated[1:elite_size]]
    elite_crossover_idx = rand(1:elite_size)
    elite_candidate = evaluated[elite_crossover_idx]
    evaluated[elite_crossover_idx], evaluated[1] = evaluated[1], evaluated[elite_crossover_idx]
    popfirst!(evaluated)

    crossovers = length(population) - elite_size - mutation_size
    for _ in 1:crossovers
        candidate = rand(evaluated)
    end
end

test_instances = ["prob-software-85-100-812-12180.txt"]

function get_instance_filepaths(instances = test_instances)
    return Iterators.map(instance -> joinpath("test/instances", instance), instances)
end

function test_brkga()
    test_instance_filepaths = get_instance_filepaths()
    for instance in test_instance_filepaths
        context = instance |> open |> make_problem_context_from_file
        search(BRKGAConfig(30, 0.14, 0.20, PackagesStrategy(0.5)), context, Maximize)
    end
end
