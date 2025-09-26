
struct AddPackageMove <: Move
    package::Integer
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

function apply!(problem::ProblemContext, solution::Solution, move::AddPackageMove)
    if move.package in solution.used_packages
        return solution
    end

    new_dependencies =
        setdiff(get_dependencies_used_by_package(problem, move.package), keys(solution.used_dependencies))
    for dependency in new_dependencies
        dependency_packages                    = get(solution.used_dependencies, dependency, Set{Integer}())
        solution.used_dependencies[dependency] = union(dependency_packages, move.package)
    end

    additional_weight = [problem.dependency_weights[dependency] for dependency in new_dependencies] |> sum
    solution.weight   += additional_weight

    push!(solution.used_packages, move.package)

    return solution
end
