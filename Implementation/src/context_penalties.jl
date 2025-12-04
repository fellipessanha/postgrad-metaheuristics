struct ProblemContextPenalties
    capacity::Integer
    forfeit_pair_count::Integer
    item_count::Integer
    weights::Vector{Integer}
    scores::Vector{Integer}
    pair_penalties::Dict{Tuple{Int,Int},Int}
end

mutable struct SolutionPenalties
    items::AbstractSet{Integer}
    Pairs::AbstractDict{Tuple{Integer,Integer},Integer}
    weight::Integer
end

function make_kpf_context_from_file(contents::IOStream)
    # Line 1: nI nP kS
    item_count, forfeit_pair_count, capacity = map(entry -> parse(Int, entry), contents |> readline |> split)
    @info "item_count: $(item_count), forfeit_pair_count: $(forfeit_pair_count), capacity: $(capacity)"

    # Line 2: item profits
    scores = parse_vector_line(contents |> readline, item_count)
    @assert length(scores) == item_count

    # Line 3: item weights
    weights = parse_vector_line(contents |> readline, item_count)
    @assert length(weights) == item_count

    # Remaining 2*nP lines: forfeit pairs
    pair_penalties = Dict{Tuple{Int,Int},Int}()

    while !eof(contents)
        # Line with: nA_i fC_i nI_i
        line = readline(contents)
        isempty(strip(line)) && break

        metadata = parse_vector_line(line)
        @assert length(metadata) == 3 "Expected 3 values in forfeit metadata line"

        n_allowed, forfeit_cost, n_items = metadata
        @assert n_allowed == 1 "Expected n_allowed to be 1"
        @assert n_items == 2 "Expected n_items to be 2"

        # Next line: id_i_0 id_i_1
        item_ids = parse_vector_line(contents |> readline, 2)
        # Convert from 0-indexed to 1-indexed
        item_pair = Tuple(item_ids .+ 1)

        if haskey(pair_penalties, item_pair)
            pair_penalties[item_pair] += forfeit_cost
        else
            pair_penalties[item_pair] = forfeit_cost
        end
    end

    return ProblemContextPenalties(capacity, forfeit_pair_count, item_count, weights, scores, pair_penalties)
end

function parse_vector_line(line::AbstractString)
    string_vector = filter(entry -> !isempty(entry), line |> split)
    return map(entry -> parse(Int, entry), string_vector)
end

function parse_vector_line(line::AbstractString, correct_count::Integer)
    parsed_line = parse_vector_line(line)
    @assert length(parsed_line) == correct_count "Parsed line has incorrect number of elements. \
        Should have $(correct_count), found $(length(parsed_line))"
    return parsed_line
end

function Base.copy(solution::SolutionPenalties)
    return SolutionPenalties(copy(solution.items), copy(solution.Pairs), solution.weight)
end
