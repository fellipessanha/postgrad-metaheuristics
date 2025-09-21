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
        @test get_all_used_dependencies(context, Set([1, 14])) ==
              vcat(first_package_dependencies, other_package_dependencies) |> Set
    end

    @testset "$(instance): evaluation penalty is working" begin
        # no oversize penalty
        @test evaluate(context, Set([1, 14])) > 0
        # with oversize penalty
        @test evaluate(context, Set(1:30)) < 0
    end

    @testset "$(instance): constructive follows correct assumptions:" begin
        @test_throws AssertionError generate_random_greedy_initial_solution(context, 2)
        @info "threw successfully!"

        greedy_solutions::AbstractVector{MetaheuristicsExercises.Solution} =
            [generate_greedy_initial_solution(context) for i in 1:2]
        @test allequal([solution.used_packages for solution in greedy_solutions])
        @test all([solution.weight <= context.storage_size for solution in greedy_solutions])
        @info "greedy solutions seem consistent ☑️"

        random_solutions = [generate_random_initial_solution(context) for i in 1:30]
        @test allunique([solution.used_packages for solution in random_solutions])
        @test all([solution.weight <= context.storage_size for solution in random_solutions])
        @info "random solutions seem random 🤔"

        random_evaluations = [evaluate(context, solution) for solution in random_solutions]
        @test evaluate(context, greedy_solutions[1]) >=
              mean([evaluate(context, solution) for solution in random_solutions])
        @info "greedy approach performs better than random, on average 🧮"

        check_solution = random_solutions[1]

        used_package = check_solution.used_packages |> rand
        @test evaluate(context, check_solution, MetaheuristicsExercises.AddPackageMove(used_package)) == 0
        @info "AddPackageMove with used index did not increase cost 0️⃣"

        unused_packages = setdiff(Set(1:context.package_count), check_solution.used_packages)
        @test evaluate(context, check_solution, MetaheuristicsExercises.RemovePackageMove(unused_packages |> rand)) == 0
        @info "Random RemovePackageMove with unused index has cost 0️⃣"
    end

    # will be used to test the moves
    greedy_solution = generate_greedy_initial_solution(context)
    greedy_evaluation = evaluate(context, greedy_solution)
    @testset "$(instance): test removing package has expected results in dependencies" begin
        removed_package = 69
        removed_dependencies =
            MetaheuristicsExercises.get_removed_dependencies_by_package(greedy_solution, removed_package)

        @test 54 in removed_dependencies
    end

    @testset "$(instance): test adding and removing package evaluates to the same number" begin
        for package in greedy_solution.used_packages
            remove_move       = MetaheuristicsExercises.RemovePackageMove(package)
            remove_score_diff = evaluate(context, greedy_solution, remove_move)
            @test remove_score_diff < 0

            removed_solution = MetaheuristicsExercises.apply(context, copy(greedy_solution), remove_move)
            @test greedy_evaluation + remove_score_diff == evaluate(context, removed_solution)

            readd_move       = MetaheuristicsExercises.AddPackageMove(package)
            readd_score_diff = evaluate(context, removed_solution, readd_move)

            @test readd_score_diff > 0
            @test remove_score_diff + readd_score_diff == 0

            readded_solution = MetaheuristicsExercises.apply(context, copy(removed_solution), readd_move)

            @test greedy_solution.used_packages == readded_solution.used_packages
            @test greedy_solution.used_dependencies == readded_solution.used_dependencies
        end
    end
end
