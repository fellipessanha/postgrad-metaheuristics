module MetaheuristicsExercises

include("ProblemContext.jl")
include("Parsing.jl")
include("Evaluation.jl")

export ProblemContext, make_problem_context_from_file, get_dependencies_used_by_package, get_all_dependencies_used_dependencies

end