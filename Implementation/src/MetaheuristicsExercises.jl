module MetaheuristicsExercises

include("problem_context.jl")
include("parsing.jl")
include("utilities.jl")
include("evaluation.jl")
include("moves/moves.jl")
include("constructive.jl")
include("search/search.jl")
include("metaheuristics/metaheuristics.jl")

export ProblemContext, Solution, Move
export make_problem_context_from_file, get_dependencies_used_by_package
export get_all_used_dependencies, evaluate, generate_random_greedy_initial_solution
export generate_greedy_initial_solution, generate_random_initial_solution
export get_removed_dependencies_by_package

export apply!, iterate_move
export AddPackageMove, RemovePackageMove, FlipPackageMove
export AddDependencyMove, RemoveDependencyMove

export BestImprovement, FirstImprovement, RandomSearch, Maximize, Minimize, local_search

end
