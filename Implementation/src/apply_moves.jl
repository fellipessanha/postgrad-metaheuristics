function apply(problem::ProblemContext, solution::Solution, move::RemovePackageMove)
    if !(move.package in solution.used_packages)
        return solution
    end

    removed_dependencies = get_removed_dependencies_by_package(solution, move.package)
    removed_weight       = [problem.dependency_weights[i] for i in removed_dependencies] |> sum
    solution.weight      -= removed_weight

    for dependency in removed_dependencies
        if solution.used_dependencies[dependency] |> length <= 1
            delete!(solution.used_dependencies, dependency)
        else
            pop!(solution.used_dependencies[dependency], package)
        end
    end

    pop!(solution.used_packages, move.package)

    return solution
end

function apply(problem::ProblemContext, solution::Solution, move::AddPackageMove)
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
