function evaluate(problem::ProblemContext, solution::AbstractVector{T}) where T<:Integer
    score = [problem.package_scores[i] for i in solution] |> sum

    dependencies = get_all_used_dependencies(problem, solution)
    cost = [problem.dependency_weights[i] for i in dependencies] |> sum
    oversize_penalty = cost > problem.storage_size ? cost * problem.penalty_cost : 0
    return score - oversize_penalty
end

function get_dependencies_used_by_package(dependency_matrix::Matrix{Bool}, package::Integer)
    package_dependencies = dependency_matrix[package, :]
    return [idx for (idx, is_used) in enumerate(package_dependencies) if is_used]
end

function get_dependencies_used_by_package(problem::ProblemContext, package::Integer)
    return get_dependencies_used_by_package(problem.dependency_matrix, package)
end

function get_all_used_dependencies(problem::ProblemContext, solution::AbstractVector{T}, current_set::Set{T}) where T<:Integer
    foldl(solution; init=current_set) do set, package
        push!(set, get_dependencies_used_by_package(problem, package))
        return set
    end
end

function get_all_used_dependencies(problem::ProblemContext, solution::AbstractVector{T}) where T<:Integer
    get_all_used_dependencies(problem, solution, Set{T}())
end

function Base.push!(set::Set{T}, values::Vector{V}) where {T,V<:T}
    for value in values
        push!(set, value)
    end
    return set
end