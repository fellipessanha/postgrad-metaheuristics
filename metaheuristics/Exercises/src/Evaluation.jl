

function get_dependencies_used_by_package(dependency_matrix::Matrix{Bool}, package::Integer)
    package_dependencies = dependency_matrix[package, :]
    return [idx for (idx, is_used) in enumerate(package_dependencies) if is_used]
end

function get_dependencies_used_by_package(problem::ProblemContext, package::Integer)
    return get_dependencies_used_by_package(problem.dependency_matrix, package)
end

function get_all_dependencies_used_dependencies(problem::ProblemContext, solution::AbstractVector{T}) where T<:Integer
    foldl(solution; init=Set{T}()) do set, package
        push!(set, get_dependencies_used_by_package(problem, package))
        return set
    end
end

function Base.push!(set::Set{T}, values::AbstractVector{T}) where T
    for value in values
        push!(set, value)
    end
    return set
end