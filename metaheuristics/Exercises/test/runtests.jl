using MetaheuristicsExercises
using Statistics
using Test

test_instances = ["prob-software-85-100-812-12180.txt"]
test_instance_filepaths = Iterators.map(instance -> joinpath("instances", instance), test_instances)

for instance in test_instance_filepaths
    contents = open(instance)
    context = MetaheuristicsExercises.make_problem_context_from_file(contents)


    package_count = context.package_count
    dependency_count = context.dependency_count
    relation_count = context.relation_count
    storage_size = context.storage_size
    summary = join([package_count, dependency_count, relation_count, storage_size], '-')

    @test occursin(summary, instance)

    first_package_dependencies = [5, 13, 20, 26, 34, 39, 48, 83, 92, 94, 100]
    other_package_dependencies = [18, 26, 34, 66, 75, 78, 88]
    @test MetaheuristicsExercises.get_dependencies_used_by_package(context, 1) == first_package_dependencies
    @test MetaheuristicsExercises.get_dependencies_used_by_package(context, 14) == other_package_dependencies

    @test MetaheuristicsExercises.get_all_used_dependencies(context, [1, 14]) == Set(vcat(first_package_dependencies, other_package_dependencies))

    # no oversize penalty
    @test MetaheuristicsExercises.evaluate(context, [1, 14]) > 0
    # with oversize penalty
    @test MetaheuristicsExercises.evaluate(context, collect(1:30)) < 0

    @test_throws AssertionError MetaheuristicsExercises.generate_random_greedy_initial_solution(context, 2)
    @info "threw successfully!"



    greedy_solutions = [MetaheuristicsExercises.generate_greedy_initial_solution(context) for i in 1:30]
    @test allequal(greedy_solutions)
    @info "greedy solutions seem consistent ☑️"


    random_solutions = [MetaheuristicsExercises.generate_random_initial_solution(context) for i in 1:30]
    @test allunique(random_solutions)
    @info "random solutions seem random 🤔"

    random_evaluations = [evaluate(context, solution) for solution in random_solutions]
    @test MetaheuristicsExercises.evaluate(context, greedy_solutions[1]) >= mean([evaluate(context, solution) for solution in random_solutions])
    @info "greedy approach performs better than random, on average 🧮"

end

