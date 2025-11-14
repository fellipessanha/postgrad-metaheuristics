using JSON
struct LocalSearch
    move::Type
    search::Type
end

struct VNDConfig
    descents::AbstractArray{LocalSearch}
    perturbations::AbstractArray{LocalSearch}
    max_iterations::Union{Integer,Nothing}
    max_time::Union{Real,Nothing}
    α::Real
    max_perturb::Integer
    max_search::Integer
end

function stop_criteria(config::VNDConfig, timedelta::Real, iteration_counter::Integer)
    if config.max_iterations != nothing && iteration_counter > config.max_iterations
        return false
    end

    if config.max_time != nothing && timedelta >= config.max_time
        return false
    end

    return true
end

function update_reference(current::Solution, best::Solution)::Solution
    return rand() < 0.2 ? copy(best) : current
end

function search(config::VNDConfig, problem::ProblemContext, ::Type{EvaluatorType}) where {EvaluatorType<:EvaluationType}
    init_time = time()
    evaluator(sol) = evaluate(problem, sol)

    best = generate_random_greedy_initial_solution(problem, config.α)
    best_eval = best |> evaluator
    reference = copy(best)
    candidate = copy(best)
    counter = 0

    while stop_criteria(config, time() - init_time, counter)
        for _ in 1:config.max_search
            move = rand(config.descents)
            best_move, upgrade = local_search(problem, reference, move.search, EvaluatorType, move.move)
            if upgrade < 0
                break
            end

            if best_move != nothing
                candidate = apply!(problem, candidate, best_move)
                candidate_eval = candidate |> evaluator
                if is_evaluation_better(candidate_eval, best_eval, EvaluatorType)
                    @info "improved: $(candidate_eval)"
                    best = copy(candidate)
                    best_eval = candidate_eval
                    reference = candidate
                end
            end
        end

        reference = update_reference(reference, best)

        for _ in rand(1:config.max_perturb)
            used_perturb = config.perturbations |> rand
            used_move, _ = local_search(problem, reference, used_perturb.search, used_perturb.move)
            if used_move != nothing
                reference = apply!(problem, reference, used_move)
            else
                reference = generate_random_greedy_initial_solution(problem, config.α)
            end
        end

        counter += 1
    end

    return best
end

function get_instance_filepaths(instances = test_instances)
    return Iterators.map(instance -> joinpath("./test/instances", instance), instances)
end

set_instances = ["sukp02_100_85_0.10_0.75.txt", "sukp07_285_300_0.10_0.75.txt", "sukp28_485_500_0.15_0.85.txt"]

function test_vnd(instances = set_instances)
    random_seed = 42
    Random.seed!(random_seed)
    @info "using random seed $(random_seed)"

    test_instance_filepaths = get_instance_filepaths(instances) |> collect
    sols = Dict()
    for instance in test_instance_filepaths
        context = instance |> open |> make_problem_context_from_file
        config = VNDConfig(
            [LocalSearch(AddPackageMove, BestImprovement)],
            [LocalSearch(RemoveDependencyMove, RandomSearch), LocalSearch(RemovePackageMove, RandomSearch)],
            nothing,
            20,
            0.5,
            40,
            60,
        )

        evaluator = solution -> evaluate(context, solution)
        thing = search(config, context, Maximize)
        sols[instance] = (context, thing)
        @info "instance: $(instance) -> $(thing |> evaluator)"
    end

    data = [(sol, evaluate(problem, sol), get_cost(problem, sol)) for (problem, sol) in sols |> values]
    json_data =
        [Dict("solution" => sol.used_packages, "score" => eval, "cost" => sol.weight) for (sol, eval, cost) in data]
    write("brkga_output.json", JSON.json(json_data))
    return sols
end
