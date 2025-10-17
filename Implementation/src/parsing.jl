function make_problem_context_from_file(contents::IOStream, penalty_cost = 9999)
    package_count, dependency_count, relation_count, storage_size =
        map(entry -> parse(Int, entry), contents |> readline |> split)
    @debug "package_count: $(package_count), dependency_count: $(dependency_count),\
    relation_count: $(relation_count), storage_size: $(storage_size)"

    package_scores = parse_vector_line(contents |> readline, package_count)

    dependency_weights = parse_vector_line(contents |> readline, dependency_count)
    @assert length(dependency_weights) == dependency_count

    dependencies = map(parse_vector_line, contents |> readlines)
    # +1 because the list is 0-indexed
    dependencies = map(entry -> entry .+ 1, dependencies)
    @assert length(dependencies) == relation_count

    dependency_matrix = zeros(Bool, (package_count, dependency_count))
    for (pkg_idx, deps) in dependencies
        for dep in deps
            dependency_matrix[pkg_idx, dep] = true
        end
    end
    @assert count(dependency_matrix) == relation_count

    return ProblemContext(
        package_count,
        dependency_count,
        relation_count,
        penalty_cost,
        package_scores,
        dependency_weights,
        storage_size,
        dependency_matrix,
    )
end

function parse_vector_line(line::AbstractString)
    string_vector = filter(entry -> !isempty(entry), line |> split)
    return map(entry -> parse(Int, entry), string_vector)
end

function parse_vector_line(line::AbstractString, correct_count::Integer)
    parsed_line = parse_vector_line(line)
    @assert length(parsed_line) == correct_count "Parsed line has incorrect number of elements.\
        Should have $(correct_count), found $(length(parsed_line))"
    return parsed_line
end
