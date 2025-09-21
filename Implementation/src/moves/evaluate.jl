@doc """
     Evaluate a solution after applying a move.

     # Arguments
     - `problem::ProblemContext`: The problem context.
     - `solution::Solution`: The current solution.
     - `move::Move`: The move to be applied.

     # Returns
     - `score::Integer`: The relative score of the new solution after applying the move.

     # Example
     ```jldoctest
     julia> new_score = evaluate(problem, current_solution, move)
     -42
     # move makes solution worse by 42 points
     julia> new_score = evaluate(problem, current_solution, move)
     13
     # move makes solution better by 13 points
     ```
 """
function evaluate(problem::ProblemContext, solution::Solution, move::Move)
    @error("Not implemented for current move")
end

function evaluate(problem::ProblemContext, solution::Solution, move::AddPackageMove)
    if move.package in solution.used_packages
        return 0
    end

    new_dependencies =
        setdiff(get_dependencies_used_by_package(problem, move.package), keys(solution.used_dependencies))
    additional_weight = [problem.dependency_weights[dependency] for dependency in new_dependencies] |> sum
    penalty_cost = calculate_solution_oversize_penalty(problem, solution.weight + additional_weight)
    return problem.package_scores[move.package] - penalty_cost
end

function evaluate(problem::ProblemContext, solution::Solution, move::RemovePackageMove)
    if !(move.package in solution.used_packages)
        return 0
    end

    removed_dependencies = get_removed_dependencies_by_package(solution, move.package)
    removed_weight = [problem.dependency_weights[dependency] for dependency in removed_dependencies] |> sum
    penalty_cost = calculate_solution_oversize_penalty(problem, solution.weight - removed_weight)
    return -(problem.package_scores[move.package] - penalty_cost)
end
