test_instances = ["prob-software-85-100-812-12180.txt"]
test_kpf_instances = []

function get_instance_filepaths(directory = "instances", instances = test_instances)
    return Iterators.map(instance -> joinpath(directory, instance), instances)
end
