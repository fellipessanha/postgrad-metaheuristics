function evaluate(problem::ProblemContext, solution::AbstractVector{T}) where {T<:Integer}
    score            = [problem.package_scores[i] for i in solution] |> sum
    dependencies     = get_all_used_dependencies(problem, solution)
    cost             = [problem.dependency_weights[i] for i in dependencies] |> sum
    oversize_penalty = calculate_solution_oversize_penalty(problem, cost)

    return score - oversize_penalty
end

function evaluate(problem::ProblemContext, solution::Solution)
    evaluate(problem, solution.used_packages)
end

@doc"""
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

    new_dependencies = setdiff(get_dependencies_used_by_package(problem, move.package), solution.used_dependencies)
    additional_cost  = [problem.dependency_weights[dependency] for dependency in new_dependencies] |> sum
    penalty_cost     = (solution.cost <= problem.storage_size ? calculate_solution_oversize_penalty(problem, solution.cost + additional_cost) : 0)
    return problem.package_scores[move.package] - penalty_cost
end

function get_dependencies_used_by_package(dependency_matrix::Matrix{Bool}, package::Integer)::AbstractVector{Integer}
    package_dependencies = dependency_matrix[package, :]
    return [idx for (idx, is_used) in enumerate(package_dependencies) if is_used]
end

function get_dependencies_used_by_package(problem::ProblemContext, package::Integer)
    return get_dependencies_used_by_package(problem.dependency_matrix, package)
end

function get_all_used_dependencies!(
    problem::ProblemContext,
    solution::AbstractVector{T},
    current_set::Set{T},
) where {T<:Integer}
    foldl(solution; init = current_set) do set, package
        for value in get_dependencies_used_by_package(problem, package)
            push!(set, value)
        end
        return set
    end
end

function get_all_used_dependencies(problem::ProblemContext, solution::AbstractVector{T}) where {T<:Integer}
    get_all_used_dependencies!(problem, solution, Set{T}())
end

function get_all_used_dependencies(problem::ProblemContext, solution::Solution)
    get_all_used_dependencies(problem, solution.used_packages)
end

function calculate_solution_oversize_penalty(problem::ProblemContext, cost::Integer)
    return cost > problem.storage_size ? problem.penalty_cost : 0
end
