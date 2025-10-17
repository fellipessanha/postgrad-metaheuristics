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
        move = rand(config.descents)
        best_move, upgrade = local_search(problem, reference, move.search, EvaluatorType, move.move)

        if best_move != nothing
            candidate = apply!(problem, candidate, best_move)
            candidate_eval = candidate |> evaluator
            if is_evaluation_better(candidate_eval, best_eval, EvaluatorType)
                @debug "improved: $(candidate_eval)"
                best = copy(candidate)
                best_eval = candidate_eval
                reference = candidate
            end
        end

        reference = update_reference(reference, best)

        used_perturb = config.perturbations |> rand
        used_move, _ = local_search(problem, reference, used_perturb.search, used_perturb.move)
        if used_move != nothing
            reference = apply!(problem, reference, used_move)
        else
            reference = generate_random_greedy_initial_solution(problem, config.α)
        end

        counter += 1
    end

    @info [p for p in best.used_packages] |> sort, best |> evaluator
    return best
end

function get_instance_filepaths(instances = test_instances)
    return Iterators.map(instance -> joinpath("./Implementation/test/instances", instance), instances)
end

function test_vnd(instances = ["prob-software-85-100-812-12180.txt"])
    test_instance_filepaths = get_instance_filepaths(instances) |> collect
    context = test_instance_filepaths[1] |> open |> make_problem_context_from_file
    config = VNDConfig(
        [LocalSearch(AddPackageMove, BestImprovement), LocalSearch(AddPackageMove, FirstImprovement)],
        [LocalSearch(RemoveDependencyMove, RandomSearch), LocalSearch(RemovePackageMove, RandomSearch)],
        nothing,
        10,
        0.5,
    )
    solutions = []
    evaluator = solution -> evaluate(context, solution)
    sols = []
    for i in 1:3
        thing = search(config, context, Maximize)
        push!(sols, thing)
        @show thing |> evaluator
    end

    return sols
end
