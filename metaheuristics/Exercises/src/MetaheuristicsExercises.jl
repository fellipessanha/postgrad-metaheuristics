module MetaheuristicsExercises

include("ProblemContext.jl")
include("Parsing.jl")
include("Evaluation.jl")
include("Constructive.jl")

export ProblemContext, make_problem_context_from_file, get_dependencies_used_by_package
export get_all_used_dependencies, evaluate

end