using DataStructures: BinaryMaxHeap

@doc """
    generate_random_greedy_initial_solution(problem::ProblemContext, α::Integer) -> Vector

Generate an initial solution using a randomized greedy algorithm for the package selection problem.

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
function generate_random_greedy_initial_solution(problem::ProblemContext, α::Integer)
    @assert α <= 1 && α >= 0 "α ∈ [0, 1], got $(α)"
    cost = 0
    packages_heap = BinaryMaxHeap([(value, idx) for (idx, value) in enumerate(problem.package_scores)])
    feasible_packages = Vector{Tuple{Integer,Integer}}()
    used_dependencies = Set{Integer}()
    cost = 0

    fill_feasible_package(feasible_packages, packages_heap, problem, α)

    initial_solution = Vector{Integer}()
    while !isempty(feasible_packages) && cost < problem.storage_size
        chosen = rand(1:length(feasible_packages))
        swapindex!(feasible_packages, chosen, length(feasible_packages))

        v, idx = pop!(feasible_packages)
        new_dependencies = setdiff(get_dependencies_used_by_package(problem, idx), used_dependencies)
        cost += [problem.dependency_weights[i] for i in new_dependencies] |> sum
        if cost <= problem.storage_size
            union!(used_dependencies, new_dependencies)
            push!(initial_solution, idx)

            fill_feasible_package(feasible_packages, packages_heap, problem, α)
        end
    end

    return initial_solution
end

function generate_random_initial_solution(problem::ProblemContext)
    generate_random_greedy_initial_solution(problem, 1)
end

function generate_greedy_initial_solution(problem::ProblemContext)
    generate_random_greedy_initial_solution(problem, 0)
end

function should_fill_feasible_package(feasible_package::AbstractVector, packages_heap::BinaryMaxHeap, problem::ProblemContext, α)
    return !isempty(packages_heap) && (isempty(feasible_package) || length(feasible_package) / problem.package_count < α)
end

function fill_feasible_package(feasible_package::AbstractVector, packages_heap::BinaryMaxHeap, problem::ProblemContext, α)
    while should_fill_feasible_package(feasible_package, packages_heap, problem, α)
        pushfirst!(feasible_package, pop!(packages_heap))
    end
end

function swapindex!(arr::AbstractVector, i::Integer, j::Integer)
    arr[i], arr[j] = arr[j], arr[i]
end