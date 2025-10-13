function as_set(vec::AbstractVector{Bool})::AbstractSet
    return [idx for (idx, value) in enumerate(vec) if value]
end

function get_package_dependencies(problem::ProblemContext, package::Integer)::AbstractSet{Integer}
    return as_set(problem.dependency_matrix[package, :])
end

function get_package_dependencies(problem::ProblemContext, packages::AbstractSet{Integer})::AbstractSet{Integer}
    dependencies = falses(problem.dependency_count)
    for package in packages
        dependencies = dependencies .⊻ problem.dependency_matrix[package, :]
    end
    return as_set(dependencies)
end

function get_dependency_packages(problem::ProblemContext, dependency::Integer)
    enumerated_depedencies = filter(t -> t[2], problem.dependency_matrix[:, dependency] |> enumerate)
    return [t[1] for t in enumerated_depedencies]
end

function get_dependency_packages(problem::ProblemContext, solution::Solution, dependency::Integer)::AbstractSet
    return Set([pkg for pkg in solution.used_packages if problem.dependency_matrix[pkg, dependency]])
end

function get_allowed_packages(problem::ProblemContext, dependencies::AbstractSet{Integer})
    dependency_union = [i in dependencies for i in 1:problem.dependency_count]
    allowed_packages = Set{Integer}()
    for pkg in 1:problem.package_count
        if sum(problem.dependency_matrix[pkg, :] .&& dependency_union) == length(dependencies)
            union!(allowed_packages, pkg)
        end
    end
    return allowed_packages
end

function get_allowed_packages(problem::ProblemContext, solution::Solution)::AbstractSet{Integer}
    return get_allowed_packages(problem, keys(solution.used_dependencies))
end
