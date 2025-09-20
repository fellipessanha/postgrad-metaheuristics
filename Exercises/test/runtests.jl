using BenchmarkTools
using MetaheuristicsExercises
using Statistics
using Test

include("utilities.jl")

test_instance_filepaths = get_instance_filepaths()

for instance in test_instance_filepaths
    contents = open(instance)
    context = make_problem_context_from_file(contents)

    package_count    = context.package_count
    dependency_count = context.dependency_count
    relation_count   = context.relation_count
    storage_size     = context.storage_size
    summary          = join([package_count, dependency_count, relation_count, storage_size], '-')

    @testset "$(instance): input conforms to file `metadata`" begin
        @test occursin(summary, instance)
    end

    first_package_dependencies = [5, 13, 20, 26, 34, 39, 48, 83, 92, 94, 100]
    other_package_dependencies = [18, 26, 34, 66, 75, 78, 88]

    @testset "$(instance): dependency fetch by package conforms to expected" begin
        @test get_dependencies_used_by_package(context, 1) == first_package_dependencies
        @test get_dependencies_used_by_package(context, 14) == other_package_dependencies
        @test get_all_used_dependencies(context, [1, 14]) ==
              Set(vcat(first_package_dependencies, other_package_dependencies))
    end

    @testset "$(instance): evaluation penalty is working" begin
        # no oversize penalty
        @test evaluate(context, [1, 14]) > 0
        # with oversize penalty
        @test evaluate(context, collect(1:30)) < 0
    end

    @testset "$(instance): constructive follows correct assumptions:" begin
        @test_throws AssertionError generate_random_greedy_initial_solution(context, 2)
        @info "threw successfully!"

        greedy_solutions::AbstractVector{MetaheuristicsExercises.Solution} =
            [generate_greedy_initial_solution(context) for i in 1:2]
        @test allequal([solution.used_packages for solution in greedy_solutions])
        @info "greedy solutions seem consistent ☑️"

        random_solutions = [generate_random_initial_solution(context) for i in 1:30]
        @test allunique([solution.used_packages for solution in random_solutions])
        @info "random solutions seem random 🤔"

        random_evaluations = [evaluate(context, solution) for solution in random_solutions]
        @test evaluate(context, greedy_solutions[1]) >=
              mean([evaluate(context, solution) for solution in random_solutions])
        @info "greedy approach performs better than random, on average 🧮"

        check_solution = random_solutions[1]

        used_package = check_solution.used_packages[1]
        @test evaluate(context, check_solution, MetaheuristicsExercises.AddPackageMove(used_package)) == 0
        @info "AddPackageMove with used index did not increase cost 0️⃣"

        unused_package = setdiff(collect(1:dependency_count), check_solution.used_dependencies)[1]
        @test evaluate(context, check_solution, MetaheuristicsExercises.AddPackageMove(unused_package)) > 0
        @info "AddPackageMove with used index did not increase cost ➕"
    end

    @testset "$(instance): test removing package has expected results in dependencies" begin
        greedy_solution = generate_greedy_initial_solution(context)

        removed_package = 69
        removed_dependencies =
            MetaheuristicsExercises.get_removed_dependencies_by_package(greedy_solution, removed_package)

        @show removed_dependencies
        @test 54 in removed_dependencies
    end
end
