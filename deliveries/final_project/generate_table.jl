using JSON

function generate_latex_table(base_dir::String = ".")
    time_dirs = ["60_s_run", "120_s_run", "180_s_run"]

    # Collect all instances from 60s folder
    instances = Dict{Tuple{Int,String},String}()

    for file in readdir(joinpath(base_dir, "60_s_run"))
        if endswith(file, ".json")
            # Parse size and instance number from filename
            m = match(r"result_(\d+)_.*objs_(\d+)_", file)
            if m !== nothing
                inst_num = m.captures[1]
                size = parse(Int, m.captures[2])
                instances[(size, inst_num)] = replace(file, ".json" => "")
            end
        end
    end

    # Sort by size then instance number
    sorted_keys = sort(collect(keys(instances)), by = k -> (k[1], k[2]))

    println("% Auto-generated LaTeX table rows")
    println(
        "% Format: Size & Instance & B&B & Greedy60 & ILP60 & BRKGA60 & Greedy120 & ILP120 & BRKGA120 & Greedy180 & ILP180 & BRKGA180",
    )
    println()

    current_size = 0
    for (size, inst_num) in sorted_keys
        basename = instances[(size, inst_num)]

        # Get B&B optimal value
        bb_value = get(BB_OPTIMAL, (size, inst_num), "-")

        # Collect scores for each time
        scores = String[]
        for time_dir in time_dirs
            filepath = joinpath(base_dir, time_dir, "$(basename).json")
            if isfile(filepath)
                data = JSON.parsefile(filepath)
                greedy = Int(data["greedy"]["objective"])
                ilp = Int(floor(data["ilp"]["objective"]))
                brkga = Int(data["brkga"]["objective"])
                push!(scores, "$greedy & $ilp & $brkga")
            else
                push!(scores, "- & - & -")
            end
        end

        # Format row
        scores_str = join(scores, " & ")

        # Add multirow marker for first instance of each size
        if size != current_size
            if current_size != 0
                println("        \\midrule")
            end
            current_size = size
        end

        println("        & $inst_num & $bb_value & $scores_str \\\\")
    end
end

# B&B optimal solutions - shared between functions
const BB_OPTIMAL = Dict(
    (500, "01") => 2626,
    (500, "02") => 2660,
    (500, "03") => 2516,
    (500, "04") => 2556,
    (500, "05") => 2625,
    (500, "06") => 2615,
    (500, "07") => 2627,
    (500, "08") => 2556,
    (700, "01") => 3589,
    (700, "02") => 3679,
    (700, "03") => 3664,
    (700, "04") => 3647,
    (700, "05") => 3596,
    (700, "06") => 3542,
    (700, "07") => 3619,
    (700, "08") => 3652,
    (800, "01") => 4184,
    (800, "02") => 4065,
    (800, "03") => 4104,
    (800, "04") => 4056,
    (800, "05") => 4086,
    (800, "06") => 4249,
    (800, "07") => 4121,
    (800, "08") => 4063,
    (1000, "01") => 4940,
    (1000, "02") => 4969,
    (1000, "03") => 5177,
    (1000, "04") => 5143,
    (1000, "05") => 5136,
    (1000, "06") => 5078,
    (1000, "07") => 5119,
    (1000, "08") => 5183,
)

"""
    generate_gap_summary(base_dir::String = ".")

Generate a summary table with average gaps (%) relative to B&B optimal for each instance size.
Outputs LaTeX table rows with format:
    Size & Greedy60 & ILP60 & BRKGA60 & Greedy120 & ILP120 & BRKGA120 & Greedy180 & ILP180 & BRKGA180
"""
function generate_gap_summary(base_dir::String = ".")
    time_dirs = ["60_s_run", "120_s_run", "180_s_run"]
    sizes = [500, 700, 800, 1000]

    # Collect all instances from 60s folder
    instances = Dict{Tuple{Int,String},String}()

    for file in readdir(joinpath(base_dir, "60_s_run"))
        if endswith(file, ".json")
            m = match(r"result_(\d+)_.*objs_(\d+)_", file)
            if m !== nothing
                inst_num = m.captures[1]
                size = parse(Int, m.captures[2])
                instances[(size, inst_num)] = replace(file, ".json" => "")
            end
        end
    end

    println("% Auto-generated LaTeX table - Average Gap (%) by instance size")
    println("% Gap = (optimal - value) / optimal * 100")
    println(
        "% Format: Size & Greedy60 & ILP60 & BRKGA60 & Greedy120 & ILP120 & BRKGA120 & Greedy180 & ILP180 & BRKGA180",
    )
    println()

    for size in sizes
        # Collect gaps for this size
        # Structure: time_idx => (greedy_gaps, ilp_gaps, brkga_gaps)
        gaps_by_time = [Float64[] for _ = 1:3]  # greedy, ilp, brkga
        gaps_all_times = [[Float64[] for _ = 1:3] for _ = 1:3]  # [time][method]

        for (key, basename) in instances
            inst_size, inst_num = key
            if inst_size != size
                continue
            end

            optimal = get(BB_OPTIMAL, (size, inst_num), nothing)
            if optimal === nothing
                continue
            end

            for (time_idx, time_dir) in enumerate(time_dirs)
                filepath = joinpath(base_dir, time_dir, "$(basename).json")
                if isfile(filepath)
                    data = JSON.parsefile(filepath)
                    greedy = Float64(data["greedy"]["objective"])
                    ilp = Float64(data["ilp"]["objective"])
                    brkga = Float64(data["brkga"]["objective"])

                    # Calculate gaps (as percentage)
                    greedy_gap = (optimal - greedy) / optimal * 100
                    ilp_gap = (optimal - ilp) / optimal * 100
                    brkga_gap = (optimal - brkga) / optimal * 100

                    push!(gaps_all_times[time_idx][2], ilp_gap)
                    push!(gaps_all_times[time_idx][3], brkga_gap)
                end
            end
        end

        # Calculate averages
        row_values = String[]
        for time_idx = 1:3
            for method_idx = 1:3
                gaps = gaps_all_times[time_idx][method_idx]
                if !isempty(gaps)
                    avg_gap = round(mean(gaps), digits = 2)
                    push!(row_values, string(avg_gap))
                else
                    push!(row_values, "-")
                end
            end
        end

        println("        $size & $(join(row_values, " & ")) \\\\")
    end
end

"""
    generate_detailed_gap_table(base_dir::String = ".")

Generate a detailed table with gaps for each instance.
"""
function generate_detailed_gap_table(base_dir::String = ".")
    time_dirs = ["60_s_run", "120_s_run", "180_s_run"]

    # Collect all instances from 60s folder
    instances = Dict{Tuple{Int,String},String}()

    for file in readdir(joinpath(base_dir, "60_s_run"))
        if endswith(file, ".json")
            m = match(r"result_(\d+)_.*objs_(\d+)_", file)
            if m !== nothing
                inst_num = m.captures[1]
                size = parse(Int, m.captures[2])
                instances[(size, inst_num)] = replace(file, ".json" => "")
            end
        end
    end

    sorted_keys = sort(collect(keys(instances)), by = k -> (k[1], k[2]))

    println("% Auto-generated LaTeX table - Gap (%) per instance")
    println("% Gap = (optimal - value) / optimal * 100")
    println(
        "% Format: Size & Instance & Greedy60 & ILP60 & BRKGA60 & Greedy120 & ILP120 & BRKGA120 & Greedy180 & ILP180 & BRKGA180",
    )
    println()

    current_size = 0
    for (size, inst_num) in sorted_keys
        basename = instances[(size, inst_num)]
        optimal = get(BB_OPTIMAL, (size, inst_num), nothing)

        if optimal === nothing
            continue
        end

        # Collect gaps for each time
        row_values = String[]
        for time_dir in time_dirs
            filepath = joinpath(base_dir, time_dir, "$(basename).json")
            if isfile(filepath)
                data = JSON.parsefile(filepath)
                greedy = Float64(data["greedy"]["objective"])
                ilp = Float64(data["ilp"]["objective"])
                brkga = Float64(data["brkga"]["objective"])

                greedy_gap = round((optimal - greedy) / optimal * 100, digits = 2)
                ilp_gap = round((optimal - ilp) / optimal * 100, digits = 2)
                brkga_gap = round((optimal - brkga) / optimal * 100, digits = 2)

                push!(row_values, "$greedy_gap & $ilp_gap & $brkga_gap")
            else
                push!(row_values, "- & - & -")
            end
        end

        if size != current_size
            if current_size != 0
                println("        \\midrule")
            end
            current_size = size
        end

        println("        & $inst_num & $(join(row_values, " & ")) \\\\")
    end
end

# Helper function for mean (avoid importing Statistics)
mean(x) = sum(x) / length(x)

# Run if called directly
if abspath(PROGRAM_FILE) == @__FILE__
    base_dir = length(ARGS) > 0 ? ARGS[1] : "."
    println("=== Raw Values Table ===")
    generate_latex_table(base_dir)
    println()
    println("=== Gap Summary by Size ===")
    generate_gap_summary(base_dir)
    println()
    println("=== Detailed Gap Table ===")
    generate_detailed_gap_table(base_dir)
end
