abstract type Move end

@doc """
     Evaluate a solution after applying a move.

     # Arguments
     - `problem::ProblemContext`: The problem context.
     - `solution::Solution`: The current solution.
     - `move::Move`: The move to be applied.

     # Returns
     - `score::Integer`: The relative score of the new solution after applying the move.

     # Example
     ```jldoctest
     julia> new_score = evaluate(problem, current_solution, move)
     -42
     # move makes solution worse by 42 points
     julia> new_score = evaluate(problem, current_solution, move)
     13
     # move makes solution better by 13 points
     ```
 """
function evaluate(problem::ProblemContext, solution::Solution, move::Move)
    @error("Not implemented for current move")
end

@doc """
    Apply a move to a solution, modifying it in-place.

    # Arguments
    - `problem::ProblemContext`: The problem context containing dependency relationships and weights.
    - `solution::Solution`: The current solution to be modified.
    - `move::Move`: The move to be applied to the solution.

    # Returns
    - `solution::Solution`: The modified solution after applying the move.

    # Example
    ```jldoctest
    julia> original_weight = solution.weight
    150
    julia> new_solution = apply!(problem, solution, AddPackageMove(5))
    Solution(...)
    julia> new_solution.weight > original_weight
    true
    # Adding package 5 increased the solution weight due to new dependencies
    julia> apply!(problem, solution, RemovePackageMove(5))
    Solution(...)
    # Removing package 5 returns to a lighter solution
    ```
"""
function apply!(problem::ProblemContext, solution::Solution, move::Move)::Solution
    @error("Not implemented for current move")
end

include("add_package.jl")
include("remove_package.jl")
include("flip_package.jl")
include("remove_dependency.jl")
