struct AddDependencyMove <: Move
    dependency::Integer
end

function evaluate(problem::ProblemContext, solution::Solution, move::AddDependencyMove)::Integer
    if move.dependency in keys(solution.used_dependencies)
        return 0
    end

    weight        = problem.dependency_weights[move.dependency]
    new_packages  = get_allowed_packages(problem, union(solution.used_dependencies |> keys, move.dependency))
    removed_score = [problem.package_scores[package] for package in new_packages] |> sum
    penalty_cost  = calculate_solution_oversize_penalty(problem, solution.weight + weight)
    return -(removed_score - penalty_cost)
end

function apply!(problem::ProblemContext, solution::Solution, move::AddDependencyMove)::Solution
    if move.dependency in keys(solution.used_dependencies)
        return solution
    end

    solution.weight += problem.dependency_weights[move.dependency]
    new_packages = get_allowed_packages(problem, union(solution.used_dependencies |> keys, move.dependency))
    solution.used_packages = new_packages
    solution.used_dependencies[move.dependency] = get_dependency_packages(problem, solution, move.dependency)

    return solution
end
