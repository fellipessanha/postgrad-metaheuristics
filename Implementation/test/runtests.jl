using BenchmarkTools
using MetaheuristicsExercises
using Statistics
using Test

include("utilities.jl")

test_instance_filepaths = get_instance_filepaths()

# include("kp_with_dependencies.jl")

include("kp_with_penalties.jl")

# Test KPF instances
for kpf_instance in get_instance_filepaths(
    "kpf_instances/LK/500",
    ["04_id_104b_objs_500_size_1500_sets_3000_maxNumConflicts_2_maxCost_15_seme_1328.txt"],
)
    test_kp_with_penalties(kpf_instance)
end
