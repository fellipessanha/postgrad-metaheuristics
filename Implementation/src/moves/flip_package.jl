
struct FlipPackageMove <: Move
    package::Integer
end

function evaluate(problem::ProblemContext, solution::Solution, move::FlipPackageMove)
    if move.package in solution.used_packages
        return evaluate(problem, solution, RemovePackageMove(move.package))
    end
    return evaluate(problem, solution, AddPackageMove(move.package))
end

function apply!(problem::ProblemContext, solution::Solution, move::FlipPackageMove)
    if move.package in solution.used_packages
        return apply!(problem, solution, RemovePackageMove(move.package))
    end
    return apply!(problem, solution, AddPackageMove(move.package))
end
