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
function generate_random_greedy_initial_solution(problem::ProblemContext, α::Real)::Solution
    @assert α <= 1 && α >= 0 "α ∈ [0, 1], got $(α)"
    weight            = 0
    packages_heap     = BinaryMaxHeap([(value, idx) for (idx, value) in enumerate(problem.package_scores)])
    feasible_packages = Vector{Tuple{Integer,Integer}}()
    used_dependencies = Dict{Integer,AbstractSet{Integer}}()
    weight            = 0

    fill_feasible_package(feasible_packages, packages_heap, problem, α)

    initial_solution = Set{Integer}()
    while !isempty(feasible_packages) && weight < problem.storage_size
        _value, idx             = pop_random_item!(feasible_packages)
        new_dependencies        = setdiff(get_dependencies_used_by_package(problem, idx), used_dependencies)
        new_dependencies_weight = [problem.dependency_weights[i] for i in new_dependencies] |> sum
        weight                  += new_dependencies_weight

        if weight > problem.storage_size
            weight -= new_dependencies_weight
            break
        end

        add_dependencies_to_dependency_map!(
            used_dependencies,
            Dict{Integer,AbstractVector{Integer}}(idx => new_dependencies),
        )
        push!(initial_solution, idx)

        fill_feasible_package(feasible_packages, packages_heap, problem, α)
    end

    return Solution(initial_solution, used_dependencies, weight)
end

function add_dependencies_to_dependency_map!(
    solution::Solution,
    new_dependencies::AbstractDict{T,AbstractVector{V}},
) where {T<:Integer,V<:Integer}
    add_dependencies_to_dependency_map!(solution.used_dependencies, new_dependencies)
end

function add_dependencies_to_dependency_map!(
    solution::Solution,
    new_dependencies::Pair{<:Integer,<:AbstractVector{<:Integer}},
)
    add_dependencies_to_dependency_map!(solution.used_dependencies, new_dependencies)
end

function add_dependencies_to_dependency_map!(
    used_dependencies::AbstractDict{Integer,AbstractSet{Integer}},
    new_dependencies::AbstractDict{Integer,AbstractVector{Integer}},
)
    for pair in new_dependencies
        add_dependencies_to_dependency_map!(used_dependencies, pair)
    end
end

function add_dependencies_to_dependency_map!(
    used_dependencies::AbstractDict{Integer,AbstractSet{Integer}},
    new_dependency::Pair{<:Integer,<:AbstractVector{<:Integer}},
)
    (package, dependencies) = new_dependency
    for dependency in dependencies
        current_packages = get(used_dependencies, dependency, Set{Integer}())
        used_dependencies[dependency] = union(current_packages, package)
    end
end

function generate_random_initial_solution(problem::ProblemContext)::Solution
    generate_random_greedy_initial_solution(problem, 1)
end

function generate_greedy_initial_solution(problem::ProblemContext)::Solution
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

function generate_random_greedy_initial_solution(problem::ProblemContextPenalties, α::Real)::SolutionPenalties
    @assert α <= 1 && α >= 0 "α ∈ [0, 1], got $(α)"

    efficiencies = [(problem.scores[idx] / problem.weights[idx], idx) for idx in 1:problem.item_count]
    items_heap = BinaryMaxHeap(efficiencies)

    feasible_items = Vector{Tuple{Float64,Integer}}()
    selected_items = Set{Integer}()
    active_pairs = Dict{Tuple{Integer,Integer},Integer}()
    weight = 0

    fill_feasible_items_penalties!(feasible_items, items_heap, problem, α)

    while !isempty(feasible_items) && weight < problem.capacity
        _efficiency, idx = pop_random_item!(feasible_items)
        item_weight = problem.weights[idx]

        if weight + item_weight > problem.capacity
            fill_feasible_items_penalties!(feasible_items, items_heap, problem, α)
            continue
        end

        # Calculate penalty for adding this item
        item_penalty = calculate_item_penalty(problem, idx, selected_items)
        item_score = problem.scores[idx]

        # Only add if net contribution is positive (score > penalty)
        if item_score > item_penalty
            push!(selected_items, idx)
            weight += item_weight
            update_active_pairs!(active_pairs, problem, idx, selected_items)
        end

        fill_feasible_items_penalties!(feasible_items, items_heap, problem, α)
    end

    return SolutionPenalties(selected_items, active_pairs, weight)
end

function calculate_item_penalty(problem::ProblemContextPenalties, new_item::Integer, selected_items::Set{Integer})
    total_penalty = 0
    item_conflicts = get(problem.penalty_lookup, new_item, nothing)
    if item_conflicts !== nothing
        for item in selected_items
            penalty = get(item_conflicts, item, 0)
            total_penalty += penalty
        end
    end
    return total_penalty
end

function update_active_pairs!(
    active_pairs::Dict{Tuple{Integer,Integer},Integer},
    problem::ProblemContextPenalties,
    new_item::Integer,
    selected_items::Set{Integer},
)
    item_conflicts = get(problem.penalty_lookup, new_item, nothing)
    item_conflicts === nothing && return

    for other_item in selected_items
        penalty = get(item_conflicts, other_item, 0)
        if penalty > 0
            # Ensure consistent pair ordering (smaller index first)
            pair = new_item < other_item ? (new_item, other_item) : (other_item, new_item)
            active_pairs[pair] = penalty
        end
    end
end

function should_fill_feasible_items_penalties(
    feasible_items::AbstractVector,
    items_heap::BinaryMaxHeap,
    problem::ProblemContextPenalties,
    α::Real,
)
    return !isempty(items_heap) && (isempty(feasible_items) || length(feasible_items) / problem.item_count < α)
end

function fill_feasible_items_penalties!(
    feasible_items::AbstractVector,
    items_heap::BinaryMaxHeap,
    problem::ProblemContextPenalties,
    α::Real,
)
    while should_fill_feasible_items_penalties(feasible_items, items_heap, problem, α)
        pushfirst!(feasible_items, pop!(items_heap))
    end
end

function generate_random_initial_solution(problem::ProblemContextPenalties)::SolutionPenalties
    generate_random_greedy_initial_solution(problem, 1.0)
end

function generate_greedy_initial_solution(problem::ProblemContextPenalties)::SolutionPenalties
    generate_random_greedy_initial_solution(problem, 0.0)
end
