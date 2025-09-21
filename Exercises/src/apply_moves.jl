function apply(problem::ProblemContext, solution::Solution, move::RemovePackageMove)
    if !(move.package in solution.used_packages)
        return solution
    end

    removed_dependencies = get_removed_dependencies_by_package(solution, move.package)
    removed_weight = [problem.dependency_weights[i] for i in removed_dependencies] |> sum

    used_dependencies::AbstractDict{Integer,AbstractSet{Integer}} = copy(solution.used_dependencies)
    for dependency in removed_dependencies
        if solution.used_dependencies[dependency] |> length <= 1
            delete!(used_dependencies, dependency)
        else
            pop!(used_dependencies[dependency], package)
        end
    end

    used_packages = copy(solution.used_packages)
    pop!(used_packages, move.package)

    return Solution(used_packages, used_dependencies, solution.weight - removed_weight)
end
