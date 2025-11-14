using Random

abstract type SearchStrategy end

abstract type BestImprovement <: SearchStrategy end
abstract type FirstImprovement <: SearchStrategy end
abstract type RandomSearch <: SearchStrategy end

abstract type EvaluationType end

abstract type Minimize <: EvaluationType end
abstract type Maximize <: EvaluationType end

function is_evaluation_better(move_evaluation, best_evaluation, ::Type{Minimize})
    return move_evaluation < best_evaluation
end

function is_evaluation_better(move_evaluation, best_evaluation, ::Type{Maximize})
    return move_evaluation > best_evaluation
end

function stop_criteria(_::Bool, ::Type{BestImprovement})
    return false
end

function stop_criteria(has_updated::Bool, ::Type{FirstImprovement})
    return has_updated
end
function local_search(
    problem::ProblemContext,
    solution::Solution,
    ::Type{SearchStrategy},
    ::Type{EvaluationType},
    ::Type{Move},
)
    @error "local search not implemented for these arguments"
end

function local_search(
    problem::ProblemContext,
    solution::Solution,
    ::Type{RandomSearch},
    ::Type{MoveType},
) where {MoveType<:Move}
    move = iterate_move(problem, MoveType) |> rand |> MoveType
    move_evaluation = evaluate(problem, solution, move)
    return move, move_evaluation
end

function local_search(problem::ProblemContext, solution::Solution, ::Type{RandomSearch}, ::Type{RemoveDependencyMove})
    removable_packages = solution.used_dependencies |> keys |> collect
    if removable_packages |> length <= 0
        return nothing, 0
    end
    move = removable_packages |> rand |> RemoveDependencyMove
    move_evaluation = evaluate(problem, solution, move)
    return move, move_evaluation
end

function local_search(problem::ProblemContext, solution::Solution, ::Type{RandomSearch}, ::Type{RemoveDependencyMove})
    removable_packages = solution.used_dependencies |> keys |> collect
    if removable_packages |> length <= 0
        return nothing, 0
    end

    removed_count = rand(0:length(removable_packages))
    move = removable_packages |> rand |> RemoveDependencyMove
    move_evaluation = evaluate(problem, solution, move)

    return move, move_evaluation
end

function local_search(
    problem::ProblemContext,
    solution::Solution,
    ::Type{StrategyType},
    ::Type{Evaluation},
    ::Type{MoveType},
) where {StrategyType<:SearchStrategy,Evaluation<:EvaluationType,MoveType<:Move}
    best_move = (nothing, 0)
    for idx in iterate_move(problem, MoveType) |> collect |> shuffle
        move = MoveType(idx)
        move_evaluation = evaluate(problem, solution, move)
        should_update = is_evaluation_better(evaluate(problem, solution), best_move[2], Evaluation)
        if should_update
            best_move = (move, move_evaluation)
        end

        if stop_criteria(should_update, StrategyType)
            break
        end
    end
    return best_move
end
