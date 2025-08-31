using Statistics

function analyse_constructive_solution(generator::Function, evaluator::Function, sample_size=30)
    generated_solutions = [generator() for _ in 1:sample_size]
    evaluations = [evaluator(solution) for solution in generated_solutions]

    mean = Statistics.mean(evaluations)
    std = Statistics.std(evaluations)

    return mean, std

end