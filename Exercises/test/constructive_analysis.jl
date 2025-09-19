using BenchmarkTools
using Statistics
using MetaheuristicsExercises
using Plots

include("utilities.jl")

function analyse_constructive_solution(generator::Function, evaluator::Function, sample_size = 30)
    generated_solutions, elapsed_time, _ = @btimed [$generator() for _ in 1:$sample_size] evals = 30
    evaluations                          = [evaluator(solution) for solution in generated_solutions]
    mean                                 = Statistics.mean(evaluations)
    std                                  = Statistics.std(evaluations)
    minimum                              = Statistics.minimum(evaluations)

    return generated_solutions, mean, std, elapsed_time, minimum
end

function run_constructive_analysis(context::ProblemContext)
    α_sample_size = 30.0
    α_samples = [i / α_sample_size for i in 0:α_sample_size]
    results = []
    for α in α_samples
        generator() = generate_random_greedy_initial_solution(context, α)
        evaluator   = solution -> evaluate(context, solution)
        result      = analyse_constructive_solution(generator, evaluator, 30)

        @info "α=$(α) ran in $(result[2])s"
        push!(results, result)
    end

    @show results
    return results
end

function normalize_vector(array::AbstractArray)
    return [element/maximum(array) for element in array]
end

function plot_constructive_analysis(test_results::AbstractVector, output_name="constructive_analysis_output")
	means   = [result[2] for result in test_results] |> normalize_vector
	stds    = [result[3] for result in test_results] |> normalize_vector
	times   = [result[4] for result in test_results] |> normalize_vector
	minimum = [result[5] for result in test_results] |> normalize_vector

    n = length(test_results)
	myplot = plot(
        [i/n for i in 1:n],
        [times means stds minimum],
        label=["times" "means" "stds" "minimum"],
        ylabel="relative (%)", xlabel="α ∈ [0,1]"
    )

    savefig(myplot, output_name)
end

function main()
    instance = (get_instance_filepaths() |> collect)[1]
    
    instance |> open |>
        make_problem_context_from_file |>
        run_constructive_analysis |>
        plot_constructive_analysis
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end