# Descrição do Problema 2025-2 - Meta-heurísticas

Veja o arquivo anexo: **prob-software-85-100-812-12180.txt**

Esse é um problema de Dependências de Software e instalação de pacotes, com objetivo, maximizar o BENEFICIO total dos Pacotes, respeitando a capacidade maxima b (dada em MB) em relação ao somatório das dependências (cada uma tem um tamanho em MB)

O arquivo é lido da seguinte forma:

**m** (numero de Pacotes de Software) **n** (numero de Dependencias de Software) **ne** (numero de relações Pacote -> Dependência) **b** (capacidade em disco em MB)
vetor de benefícios '**c**' , por Pacote
peso em MB '**a**', por Dependencia
Matriz de associacao (dois elementos por linha, com '**ne**' linhas, com Pacote -> Dependencia)