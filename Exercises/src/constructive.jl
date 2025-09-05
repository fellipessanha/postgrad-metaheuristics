using DataStructures: BinaryMaxHeap

@doc """
    # generate_random_greedy_initial_solution(problem::ProblemContext, α::Integer) -> Vector

Generate an initial solution using a randomized greedy algorithm for the package selection problem.
The generated solution will always follow the condition that `dependency_storage <= storage_size`

# Arguments
- `problem::ProblemContext`: The problem instance containing package scores, dependency weights, 
  storage capacity, and dependency relationships
- `α::Integer`: Randomization parameter controlling the size of the restricted candidate list (RCL).
  Must be in [0, 1] where:
  - α = 0: purely greedy (selects best package)
  - α = 1: purely random (selects from all available packages)
  - 0 < α < 1: selects randomly from top α% of packages

# Returns
- `Vector`: A feasible solution containing the indices of selected packages

# Example
```julia
problem = make_problem_context_from_file(open("instance.txt"))
solution = generate_random_greedy_initial_solution(problem, 0.3)
```
"""
function generate_random_greedy_initial_solution(problem::ProblemContext, α::Real)
    @assert α <= 1 && α >= 0 "α ∈ [0, 1], got $(α)"
    cost              = 0
    packages_heap     = BinaryMaxHeap([(value, idx) for (idx, value) in enumerate(problem.package_scores)])
    feasible_packages = Vector{Tuple{Integer,Integer}}()
    used_dependencies = Set{Integer}()
    cost              = 0

    fill_feasible_package(feasible_packages, packages_heap, problem, α)

    initial_solution = Vector{Integer}()
    while !isempty(feasible_packages) && cost < problem.storage_size
        _value, idx      = pop_random_item!(feasible_packages)
        new_dependencies = setdiff(get_dependencies_used_by_package(problem, idx), used_dependencies)
        cost             += [problem.dependency_weights[i] for i in new_dependencies] |> sum

        if cost > problem.storage_size
            break
        end

        union!(used_dependencies, new_dependencies)
        push!(initial_solution, idx)

        fill_feasible_package(feasible_packages, packages_heap, problem, α)
    end

    return initial_solution
end

function generate_random_initial_solution(problem::ProblemContext)
    generate_random_greedy_initial_solution(problem, 1)
end

function generate_greedy_initial_solution(problem::ProblemContext)
    generate_random_greedy_initial_solution(problem, 0)
end

function should_fill_feasible_package(
    feasible_package::AbstractVector,
    packages_heap::BinaryMaxHeap,
    problem::ProblemContext,
    α,
)
    return !isempty(packages_heap) &&
           (isempty(feasible_package) || length(feasible_package) / problem.package_count < α)
end

function fill_feasible_package(
    feasible_package::AbstractVector,
    packages_heap::BinaryMaxHeap,
    problem::ProblemContext,
    α,
)
    while should_fill_feasible_package(feasible_package, packages_heap, problem, α)
        pushfirst!(feasible_package, pop!(packages_heap))
    end
end

function swapindex!(arr::AbstractVector, i::Integer, j::Integer)
    arr[i], arr[j] = arr[j], arr[i]
end

@doc """
# `pop_item_in_index!`
removes item in position `index::Integer`, from `list::AbstractVector`.

does this in `O(1)` execution time by swapping the specified item with the last intem in `list`,
then performing `pop!` in `list`
# Examples
```jldoctest
julia> v = [10, 20, 30, 40, 50]
5-element Vector{Int64}:
 10
 20
 30
 40
 50

julia> removed_item = pop_item_in_index!(v, 2)
20

julia> v
4-element Vector{Int64}:
 10
 50
 30
 40
```
"""
function pop_item_in_index!(list::AbstractVector, index::Integer)
    swapindex!(list, index, length(list))
    return pop!(list)
end

function pop_random_item!(list::AbstractVector)
    index = rand(1:length(list))
    return pop_item_in_index!(list, index)
end