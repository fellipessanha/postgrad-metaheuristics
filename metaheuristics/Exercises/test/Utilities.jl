test_instances = ["prob-software-85-100-812-12180.txt"]

function get_instance_filepaths(instances=test_instances)
    return Iterators.map(instance -> joinpath("instances", instance), test_instances)
end