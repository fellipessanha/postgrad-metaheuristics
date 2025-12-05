struct ProblemContextPenalties
    capacity::Integer
    forfeit_pair_count::Integer
    item_count::Integer
    weights::Vector{Integer}
    scores::Vector{Integer}
    pair_penalties::Dict{Tuple{Int,Int},Int}
    penalty_lookup::Dict{Int,Dict{Int,Int}}  # item -> (other_item -> penalty)
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
        # Convert from 0-indexed to 1-indexed and ensure sorted order
        item_pair = Tuple(sort(item_ids .+ 1))

        if haskey(pair_penalties, item_pair)
            pair_penalties[item_pair] += forfeit_cost
        else
            pair_penalties[item_pair] = forfeit_cost
        end
    end

    # Build penalty lookup: item -> (other_item -> penalty)
    penalty_lookup = Dict{Int,Dict{Int,Int}}()
    for ((item1, item2), penalty) in pair_penalties
        # Add both directions for O(1) lookup
        if !haskey(penalty_lookup, item1)
            penalty_lookup[item1] = Dict{Int,Int}()
        end
        penalty_lookup[item1][item2] = penalty

        if !haskey(penalty_lookup, item2)
            penalty_lookup[item2] = Dict{Int,Int}()
        end
        penalty_lookup[item2][item1] = penalty
    end

    return ProblemContextPenalties(
        capacity,
        forfeit_pair_count,
        item_count,
        weights,
        scores,
        pair_penalties,
        penalty_lookup,
    )
end

function Base.copy(solution::SolutionPenalties)
    return SolutionPenalties(copy(solution.items), copy(solution.Pairs), solution.weight)
end
