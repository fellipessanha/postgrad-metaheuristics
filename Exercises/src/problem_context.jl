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

struct Solution
    used_packages::AbstractArray{Integer}
    used_dependencies::AbstractDict{Integer}
    cost::Integer
end
