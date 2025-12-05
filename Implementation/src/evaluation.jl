function evaluate(problem::ProblemContext, solution::Union{AbstractSet{T},AbstractArray{T}}) where {T<:Integer}
    score = [problem.package_scores[i] for i in solution] |> sum
    cost = get_cost(problem, solution)
    oversize_penalty = cost > problem.storage_size ? problem.penalty_cost : 0

    return score - oversize_penalty
end

function get_cost(problem, solution)
    dependencies = get_all_used_dependencies(problem, solution)
    return [problem.dependency_weights[i] for i in dependencies] |> sum
end

function evaluate(problem::ProblemContext, solution::Solution)
    evaluate(problem, solution.used_packages)
end

function get_removed_dependencies_by_package(
    dependency_dict::AbstractDict{Integer,AbstractSet{Integer}},
    package::Integer,
)
    to_remove = Set{Integer}()
    for (dependency, packages) in dependency_dict
        if package in packages && length(packages) == 1
            union!(to_remove, dependency)
        end
    end
    return to_remove
end

function get_removed_dependencies_by_package(solution::Solution, package::Integer)
    return get_removed_dependencies_by_package(solution.used_dependencies, package)
end

function get_dependencies_used_by_package(dependency_matrix::Matrix{Bool}, package::Integer)::AbstractVector{Integer}
    package_dependencies = dependency_matrix[package, :]
    return [idx for (idx, is_used) in enumerate(package_dependencies) if is_used]
end

function get_dependencies_used_by_package(problem::ProblemContext, package::Integer)
    return get_dependencies_used_by_package(problem.dependency_matrix, package)
end

function get_all_used_dependencies!(
    problem::ProblemContext,
    solution::Union{AbstractSet{T},AbstractArray{T}},
    current_set::AbstractSet{T},
) where {T<:Integer}
    foldl(solution; init = current_set) do set, package
        for value in get_dependencies_used_by_package(problem, package)
            push!(set, value)
        end
        return set
    end
end

function get_all_used_dependencies(
    problem::ProblemContext,
    solution::Union{AbstractSet{T},AbstractArray{T}},
) where {T<:Integer}
    get_all_used_dependencies!(problem, solution, Set{T}())
end

function get_all_used_dependencies(problem::ProblemContext, solution::Solution)
    get_all_used_dependencies(problem, solution.used_packages)
end

function calculate_solution_oversize_penalty(problem::ProblemContext, weight::Integer)
    return weight > problem.storage_size ? problem.penalty_cost : 0
end

function evaluate(problem::ProblemContextPenalties, solution::SolutionPenalties)
    score = sum([problem.scores[i] for i in solution.items])
    penalty = sum(values(solution.Pairs); init = 0)
    oversize_penalty = solution.weight > problem.capacity ? sum(problem.scores) : 0

    return score - penalty - oversize_penalty
end

function evaluate(problem::ProblemContextPenalties, items::Union{AbstractSet{T},AbstractArray{T}}) where {T<:Integer}
    score = sum([problem.scores[i] for i in items])
    weight = sum([problem.weights[i] for i in items])

    penalty = 0
    for (pair, cost) in problem.pair_penalties
        (item1, item2) = pair
        if item1 in items && item2 in items
            penalty += cost
        end
    end

    oversize_penalty = weight > problem.capacity ? sum(problem.scores) : 0

    return score - penalty - oversize_penalty
end
