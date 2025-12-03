function test_kp_with_penalties(instance_path)
    contents = open(instance_path)
    context = make_kpf_context_from_file(contents)

    item_count = context.item_count
    forfeit_pair_count = context.forfeit_pair_count
    capacity = context.capacity

    @testset "$(instance_path): KPF instance loaded correctly" begin
        @test item_count > 0
        @test forfeit_pair_count > 0
        @test capacity > 0
        @test length(context.scores) == item_count
        @test length(context.weights) == item_count
    end

    @testset "$(instance_path): forfeit pairs are valid" begin
        for (item_pair, penalty) in context.pair_penalties
            @test length(item_pair) == 2
            @test 1 <= item_pair[1] <= item_count
            @test 1 <= item_pair[2] <= item_count
            @test item_pair[1] != item_pair[2]
            @test penalty > 0
        end
    end

    @testset "$(instance_path): weights and scores are positive" begin
        @test all(w -> w > 0, context.weights)
        @test all(s -> s > 0, context.scores)
    end

    @testset "$(instance_path): constructive follows correct assumptions" begin
        @test_throws AssertionError generate_random_greedy_initial_solution(context, 2)
        @info "threw successfully!"

        greedy_solutions::AbstractVector{SolutionPenalties} = [generate_greedy_initial_solution(context) for i in 1:2]
        @test allequal([solution.items for solution in greedy_solutions])
        @test all([solution.weight <= context.capacity for solution in greedy_solutions])
        @info "greedy solutions seem consistent ☑️"

        random_solutions = [generate_random_initial_solution(context) for i in 1:30]
        @test allunique([solution.items for solution in random_solutions])
        @test all([solution.weight <= context.capacity for solution in random_solutions])
        @info "random solutions seem random 🤔"

        @test all([length(solution.items) > 0 for solution in random_solutions])
        @info "all solutions have at least one item"
    end

    greedy_solution = generate_greedy_initial_solution(context)

    @testset "$(instance_path): greedy solution properties" begin
        @test greedy_solution.weight <= context.capacity
        @test length(greedy_solution.items) > 0
        @test all(item -> 1 <= item <= item_count, greedy_solution.items)

        calculated_weight = sum([context.weights[item] for item in greedy_solution.items])
        @test calculated_weight == greedy_solution.weight
        @info "weight calculation is correct ✓"
    end

    @testset "$(instance_path): active pairs tracking" begin
        for (pair, penalty) in greedy_solution.Pairs
            (item1, item2) = pair
            @test item1 in greedy_solution.items
            @test item2 in greedy_solution.items
            @test haskey(context.pair_penalties, pair)
            @info "forfeit pair $(pair) correctly tracked with penalty $(penalty)"
        end
    end

    @testset "$(instance_path): instance metadata" begin
        @info "KPF Instance: $(basename(instance_path))"
        @info "  Items: $(item_count)"
        @info "  Forfeit pairs: $(forfeit_pair_count)"
        @info "  Capacity: $(capacity)"
        @info "  Total score: $(sum(context.scores))"
        @info "  Total weight: $(sum(context.weights))"
        @info "  Greedy solution: $(length(greedy_solution.items)) items, weight $(greedy_solution.weight)"
        @info "  Active forfeit pairs: $(length(greedy_solution.Pairs))"
    end
end
