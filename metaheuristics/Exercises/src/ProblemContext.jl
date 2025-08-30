struct ProblemContext
    package_count::Integer
    dependency_count::Integer
    relation_count::Integer
    package_scores::Vector{Integer}
    dependency_scores::Vector{Integer}
    storage_size::Real
    dependency_matrix::Matrix{Bool}
end

struct Solution
    used_packages::AbstractArray{Integer}
end