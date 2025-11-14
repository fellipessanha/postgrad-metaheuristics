# Buscas Locais

Foram implementadas buscas locais de Melhor melhora, de primeira melhora, segundo a implementação abaixo:

```julia
function local_search(
    problem::ProblemContext,
    solution::Solution,
    ::Type{StrategyType},
    ::Type{Evaluation},
    ::Type{MoveType},
) where {StrategyType<:SearchStrategy,Evaluation<:EvaluationType,MoveType<:Move}
    best_move = (nothing, 0)
    for idx in iterate_move(problem, MoveType) |> collect
        move = MoveType(idx)
        move_evaluation = evaluate(problem, solution, move)
        should_update = is_evaluation_better(move_evaluation, best_move[1], Evaluation)
        if should_update
            best_move = (move, move_evaluation)
        end

        if stop_criteria(should_update, StrategyType)
            break
        end
    end
    return best_move
end
```

Onde as funções auxiliares `is_evaluation_better` e `stop_criteria` foram definidas da seguinte maneira:

```julia
function is_evaluation_better(move_evaluation, best_evaluation, ::Type{Minimize})
    return move_evaluation < 0 && move_evaluation < best_evaluation
end

function is_evaluation_better(move_evaluation, best_evaluation, ::Type{Maximize})
    return move_evaluation > 0 && move_evaluation < best_evaluation
end

function stop_criteria(_::Bool, ::Type{BestImprovement})
    return false
end

function stop_criteria(has_updated::Bool, ::Type{FirstImprovement})
    return has_updated
end
```

Resultados obtidos (média e máximo observados) por tipo de movimento / estratégia:

| movimento                           | média | máximo |
|-------------------------------------|:-----:|:------:|
| remover (qualquer critério)         | 0     | 0      |
| adicionar (first improvement)       | 281   | 421    |
| adicionar (best improvement)        | 290   | 512    |

Observa-se que movimentos de remoção não geraram melhorias (valores zero), enquanto a estratégia de Best Improvement para adição superou levemente First Improvement tanto na média (+3,2% aproximadamente) quanto no máximo (+21,6% sobre o máximo de first improvement), indicando que o custo adicional de explorar todo o conjunto de vizinhança trouxe ganhos modestos porém potencialmente relevantes dependendo do critério de parada global.

