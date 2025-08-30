

function get_dependencies_used_by_package(dependency_matrix::Matrix{Bool}, package::Integer)
    package_dependencies = dependency_matrix[package, :]
    return [idx for (idx, is_used) in enumerate(package_dependencies) if is_used]
end

function get_dependencies_used_by_package(problem::ProblemContext, package::Integer)
    return get_dependencies_used_by_package(problem.dependency_matrix, package)
end

function get_all_dependencies_used_dependencies(problem::ProblemContext, solution::Vector{<:Integer})
    used_dependencies = Set{Integer}()

    for package in solution
        push!(used_dependencies, get_dependencies_used_by_package(problem, package))
    end

    return used_dependencies
end

function Base.push!(set::Set{Integer}, values::Vector{<:Integer})
    for value in values
        push!(set, value)
    end
    return set
end