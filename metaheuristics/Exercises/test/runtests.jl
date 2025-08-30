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
    @test context.storage_size == 12180
end