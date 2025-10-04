abstract type SearchStrategy end

abstract type BestImprovement <: SearchStrategy end
abstract type FirstImprovement <: SearchStrategy end

abstract type EvaluationType end

abstract type Minimize <: EvaluationType end
abstract type Maximize <: EvaluationType end

function is_evaluation_better(move_evaluation, ::Type{Minimize})
    return move_evaluation < 0
end

function is_evaluation_better(move_evaluation, ::Type{Maximize})
    return move_evaluation > 0
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
    ::Type{StrategyType},
    ::Type{Evaluation},
    ::Type{MoveType},
) where {StrategyType<:SearchStrategy,Evaluation<:EvaluationType,MoveType<:Move}
    best_move = (nothing, 0)
    for idx in iterate_move(problem, MoveType) |> collect
        move = MoveType(idx)
        move_evaluation = evaluate(problem, solution, move)
        should_update = is_evaluation_better(move_evaluation, Evaluation)
        if should_update
            best_move = (move, move_evaluation)
        end

        if stop_criteria(should_update, StrategyType)
            break
        end
    end
    return best_move
end
