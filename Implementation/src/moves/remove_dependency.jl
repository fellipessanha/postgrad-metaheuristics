struct RemoveDependencyMove <: Move
    dependency::Integer
end

struct RemoveDependenciesMove <: Move
    dependency::AbstractArray{Integer}
end

function evaluate(problem::ProblemContext, solution::Solution, move::RemoveDependencyMove)::Integer
    if !(move.dependency in keys(solution.used_dependencies))
        return 0
    end

    weight        = problem.dependency_weights[move.dependency]
    dependants    = solution.used_dependencies[move.dependency]
    removed_score = [problem.package_scores[package] for package in dependants] |> sum
    penalty_cost  = calculate_solution_oversize_penalty(problem, solution.weight - weight)
    return -(removed_score - penalty_cost)
end

function apply!(problem::ProblemContext, solution::Solution, move::RemoveDependencyMove)::Solution
    if !(move.dependency in keys(solution.used_dependencies))
        return solution
    end

    solution.weight -= problem.dependency_weights[move.dependency]
    dependants      = solution.used_dependencies[move.dependency]
    setdiff!(solution.used_packages, dependants)
    pop!(solution.used_dependencies, move.dependency)

    for pair in solution.used_dependencies
        setdiff!(pair[2], move.dependency)
    end

    return solution
end

function apply!(problem::ProblemContext, solution::Solution, move::RemoveDependenciesMove)::Solution
    for dep in move.dependency
        apply!(problem, solution, RemoveDependencyMove(dep))
    end
end

function iterate_move(problem::ProblemContext, ::Type{RemoveDependencyMove})
    return 1:problem.dependency_count
end
