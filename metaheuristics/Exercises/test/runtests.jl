using MetaheuristicsExercises
using Test

test_instances = ["prob-software-85-100-812-12180.txt"]
test_instance_filepaths = Iterators.map(instance -> joinpath("instances", instance), test_instances)

for instance in test_instance_filepaths
    contents = open(instance)
    context = MetaheuristicsExercises.make_problem_context_from_file(contents)


    context_variables = [context.package_count, context.dependency_count, context.relation_count, context.storage_size]
    summary = join(context_variables, '-')

    @test occursin(summary, instance)

    first_package_dependencies = [5, 13, 20, 26, 34, 39, 48, 83, 92, 94, 100]
    other_package_dependencies = [18, 26, 34, 66, 75, 78, 88]
    @test MetaheuristicsExercises.get_dependencies_used_by_package(context, 1) == first_package_dependencies
    @test MetaheuristicsExercises.get_dependencies_used_by_package(context, 14) == other_package_dependencies

    @test MetaheuristicsExercises.get_all_dependencies_used_dependencies(context, [1, 14]) == Set(vcat(first_package_dependencies, other_package_dependencies))

end

