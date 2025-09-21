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
