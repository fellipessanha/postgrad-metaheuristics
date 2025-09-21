abstract type Move end

struct AddPackageMove <: Move
    package::Integer
end

struct RemovePackageMove <: Move
    package::Integer
end

struct FlipPackageMove <: Move
    package::Integer
end

include("evaluate.jl")
include("apply.jl")
