struct ProblemContext
    package_count::Integer
    dependency_count::Integer
    relation_count::Integer
    penalty_cost::Integer
    package_scores::Vector{Integer}
    dependency_weights::Vector{Integer}
    storage_size::Real
    dependency_matrix::Matrix{Bool}
end

mutable struct Solution
    used_packages::AbstractSet{Integer}
    used_dependencies::AbstractDict{Integer,AbstractSet{Integer}}
    weight::Integer
end

function Base.copy(solution::Solution)
    return Solution(copy(solution.used_packages), copy(solution.used_dependencies), solution.weight)
end
