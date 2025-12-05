using JuMP
using HiGHS
using JSON

"""
    solve_kpf_ilp(problem::ProblemContextPenalties; time_limit=nothing, verbose=false)

Solve the Knapsack Problem with Forfeits (KPF) using Integer Linear Programming.

The ILP formulation follows [Cerulli et al., 2020]:

    Maximize  Σᵢ pᵢxᵢ - Σf∈F dₓvf                    (1)
    subject to:
        Σᵢ wᵢxᵢ ≤ H                                  (2) capacity constraint
        xᵢ + xⱼ - vf ≤ 1,  ∀f = {i,j} ∈ F           (3) forfeit pair activation
        0 ≤ vf ≤ 1,  ∀f ∈ F                          (4) forfeit variable bounds
        xᵢ ∈ {0, 1},  ∀i ∈ I                         (5) binary item selection

Where:
- xᵢ = 1 if item i is selected, 0 otherwise
- vf = 1 if both items in forfeit pair f are selected (penalty applies)
- pᵢ = profit/score of item i
- wᵢ = weight of item i
- dₓ = penalty cost for forfeit pair f
- H = knapsack capacity

# Arguments
- `problem::ProblemContextPenalties`: The KPF problem instance
- `time_limit::Union{Real, Nothing}`: Optional time limit in seconds
- `verbose::Bool`: Whether to print solver output

# Returns
NamedTuple with:
- `objective`: Optimal objective value
- `items`: Set of selected item indices
- `status`: Solver termination status
- `solve_time`: Time taken to solve
"""
function solve_kpf_ilp(
    problem::ProblemContextPenalties;
    time_limit::Union{Real,Nothing} = nothing,
    verbose::Bool = false,
    n_warmstart_solutions::Int = 5,
)
    model = Model(HiGHS.Optimizer)

    if !verbose
        set_silent(model)
    end

    if time_limit !== nothing
        set_time_limit_sec(model, time_limit)
    end

    n_items       = problem.item_count
    forfeit_pairs = collect(keys(problem.pair_penalties))
    n_forfeits    = length(forfeit_pairs)

    # Decision variables
    # x[i] = 1 if item i is selected
    @variable(model, x[1:n_items], Bin)

    # v[f] = 1 if both items in forfeit pair f are selected (penalty activated)
    @variable(model, 0 <= v[1:n_forfeits] <= 1)

    # Objective (1): Maximize profit minus penalties
    # Σᵢ pᵢxᵢ - Σf∈F df*vf
    profit  = sum(problem.scores[i] * x[i] for i in 1:n_items)
    penalty = sum(problem.pair_penalties[forfeit_pairs[f]] * v[f] for f in 1:n_forfeits)
    @objective(model, Max, profit - penalty)

    # Constraint (2): Capacity constraint
    # Σᵢ wᵢxᵢ ≤ H
    @constraint(model, capacity, sum(problem.weights[i] * x[i] for i in 1:n_items) <= problem.capacity)

    # Constraint (3): Forfeit pair activation
    # xᵢ + xⱼ - vf ≤ 1, ∀f = {i,j} ∈ F
    # This ensures: if both xᵢ=1 and xⱼ=1, then vf must be ≥ 1 (so vf=1)
    @constraint(
        model,
        forfeit_activation[f in 1:n_forfeits],
        x[forfeit_pairs[f][1]] + x[forfeit_pairs[f][2]] - v[f] <= 1
    )

    # Generate warm-start solutions using GRASP with different α values
    if n_warmstart_solutions > 0
        α_values = range(0.0, 1.0, length = n_warmstart_solutions)
        best_warmstart_obj = -Inf
        best_warmstart_solution = nothing

        for α in α_values
            solution = generate_random_greedy_initial_solution(problem, α)
            obj = evaluate(problem, solution)

            if obj > best_warmstart_obj
                best_warmstart_obj = obj
                best_warmstart_solution = solution
            end
        end

        # Set the best GRASP solution as warm-start
        if best_warmstart_solution !== nothing
            for i in 1:n_items
                set_start_value(x[i], i ∈ best_warmstart_solution.items ? 1.0 : 0.0)
            end

            # Also set forfeit variables based on the solution
            for (f, pair) in enumerate(forfeit_pairs)
                both_selected = pair[1] ∈ best_warmstart_solution.items && pair[2] ∈ best_warmstart_solution.items
                set_start_value(v[f], both_selected ? 1.0 : 0.0)
            end

            if verbose
                @info "Warm-start with GRASP solution (α values: $(collect(α_values)))"
                @info "  Best warm-start objective: $(best_warmstart_obj)"
                @info "  Items in warm-start: $(length(best_warmstart_solution.items))"
            end
        end
    end

    # Solve
    optimize!(model)

    # Extract results
    status = termination_status(model)
    solve_time = JuMP.solve_time(model)

    if status == OPTIMAL || status == TIME_LIMIT
        obj_value = objective_value(model)
        selected_items = Set{Int}([i for i in 1:n_items if value(x[i]) > 0.5])

        return (objective = obj_value, items = selected_items, status = status, solve_time = solve_time, model = model)
    else
        return (objective = nothing, items = Set{Int}(), status = status, solve_time = solve_time, model = model)
    end
end

"""
    solve_and_compare_kpf(problem::ProblemContextPenalties; time_limit=60, verbose=false)

Solve KPF using ILP and compare with heuristic solutions.
"""
function solve_and_compare_kpf(problem::ProblemContextPenalties; time_limit::Real = 60, verbose::Bool = false)
    # Solve with ILP
    @info "Solving KPF with ILP (time limit: $(time_limit)s)..."
    ilp_result = solve_kpf_ilp(problem; time_limit = time_limit, verbose = verbose)

    @info "ILP Result:"
    @info "  Status: $(ilp_result.status)"
    @info "  Objective: $(ilp_result.objective)"
    @info "  Items selected: $(length(ilp_result.items))"
    @info "  Solve time: $(ilp_result.solve_time)s"

    # Compare with greedy
    greedy_solution = generate_greedy_initial_solution(problem)
    greedy_eval     = evaluate(problem, greedy_solution)

    @info "Greedy Result:"
    @info "  Objective: $(greedy_eval)"
    @info "  Items selected: $(length(greedy_solution.items))"

    # Compare with BRKGA
    brkga_result = test_brkga(
        problem;
        population_size = 1000,
        strategy = GraspThresholdStrategy(0.5, 0.7),
        iterations = 50000,
        max_time = time_limit,
    )

    @info "BRKGA Result:"
    @info "  Objective: $(brkga_result.best_score)"
    @info "  Items selected: $(length(brkga_result.best_solution))"
    @info "  Runtime: $(brkga_result.runtime)s"

    # Summary
    @info "Summary:"
    if ilp_result.objective !== nothing
        gap_greedy = (ilp_result.objective - greedy_eval) / ilp_result.objective * 100
        gap_brkga  = (ilp_result.objective - brkga_result.best_score) / ilp_result.objective * 100
        @info "  ILP vs Greedy gap: $(round(gap_greedy, digits=2))%"
        @info "  ILP vs BRKGA gap: $(round(gap_brkga, digits=2))%"
    end

    return (ilp = ilp_result, greedy = greedy_solution, greedy_eval = greedy_eval, brkga = brkga_result)
end

"""
    run_benchmark_comparison(; time_limit=60, n_instances=5, output_dir="deliveries/final_project")

Run solve_and_compare_kpf for the first n_instances on sizes 500, 700, 800, and 1000.
Save results to JSON files in the output directory.
"""
function run_benchmark_comparison(;
    time_limit::Real = 60,
    n_instances::Int = 5,
    output_dir::String = "deliveries/final_project",
    instances_base_path::String = "test/kpf_instances/LK",
)
    sizes = [500, 700, 800, 1000]
    all_results = Dict{String,Any}()

    # Create output directory if it doesn't exist
    mkpath(output_dir)

    # Generate timestamp using time() - Unix epoch seconds
    timestamp = string(round(Int, time()))

    for size in sizes
        size_dir = joinpath(instances_base_path, string(size))
        if !isdir(size_dir)
            @warn "Directory not found: $size_dir, skipping size $size"
            continue
        end

        # Get sorted list of instance files
        instance_files = filter(f -> endswith(f, ".txt"), readdir(size_dir))
        sort!(instance_files)

        # Take first n_instances
        instances_to_run = instance_files[1:min(n_instances, length(instance_files))]

        @info "Running benchmarks for size $size ($(length(instances_to_run)) instances)"

        size_results = Dict{String,Any}[]

        for (idx, instance_file) in enumerate(instances_to_run)
            instance_path = joinpath(size_dir, instance_file)
            @info "  [$idx/$(length(instances_to_run))] Processing: $instance_file"

            try
                # Parse instance
                problem = open(instance_path) do io
                    make_kpf_context_from_file(io)
                end

                # Run comparison
                result = solve_and_compare_kpf(problem; time_limit = time_limit, verbose = false)

                # Build result dictionary
                instance_result = Dict{String,Any}(
                    "instance" => instance_file,
                    "size" => size,
                    "n_items" => problem.item_count,
                    "n_forfeit_pairs" => length(problem.pair_penalties),
                    "capacity" => problem.capacity,
                    "time_limit" => time_limit,
                    "ilp" => Dict{String,Any}(
                        "objective" => result.ilp.objective,
                        "n_items_selected" => length(result.ilp.items),
                        "items" => collect(result.ilp.items),
                        "status" => string(result.ilp.status),
                        "solve_time" => result.ilp.solve_time,
                    ),
                    "greedy" => Dict{String,Any}(
                        "objective" => result.greedy_eval,
                        "n_items_selected" => length(result.greedy.items),
                        "items" => collect(result.greedy.items),
                    ),
                    "brkga" => Dict{String,Any}(
                        "objective" => result.brkga.best_score,
                        "n_items_selected" => length(result.brkga.best_solution),
                        "items" => collect(result.brkga.best_solution),
                        "runtime" => result.brkga.runtime,
                    ),
                )

                # Calculate gaps if ILP found a solution
                if result.ilp.objective !== nothing
                    instance_result["gaps"] = Dict{String,Any}(
                        "greedy_gap_percent" =>
                            (result.ilp.objective - result.greedy_eval) / result.ilp.objective * 100,
                        "brkga_gap_percent" =>
                            (result.ilp.objective - result.brkga.best_score) / result.ilp.objective * 100,
                    )
                end

                push!(size_results, instance_result)

                # Save individual instance result
                instance_name = replace(instance_file, ".txt" => "")
                instance_output_file = joinpath(output_dir, "result_$(instance_name).json")
                open(instance_output_file, "w") do io
                    JSON.print(io, instance_result, 2)
                end

                @info "    ILP: $(result.ilp.objective) | Greedy: $(result.greedy_eval) | BRKGA: $(result.brkga.best_score)"
                @info "    Saved to: $instance_output_file"

            catch e
                @error "Failed to process $instance_file" exception = (e, catch_backtrace())
                push!(size_results, Dict{String,Any}("instance" => instance_file, "size" => size, "error" => string(e)))
            end
        end

        all_results[string(size)] = size_results
    end

    # Save combined results
    combined_output = Dict{String,Any}(
        "timestamp" => timestamp,
        "time_limit" => time_limit,
        "n_instances_per_size" => n_instances,
        "sizes" => sizes,
        "results" => all_results,
    )

    return combined_output
end
