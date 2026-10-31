---
layout: default
lang: pt-BR
---

## 1. O que é um documento, em uma frase

Um arquivo `.mad` é um **arquivo tar comprimido com bzip2** cujos membros são um
store de persistência do Core Data (ou store SQLite portável), uma pequena property list descrevendo o documento e um
diretório opcional de miniatura (thumbnail).

Os dados de linhas que um relatório exibe **não** estão no documento. Eles são um cache derivado,
regenerado a cada atualização (`refresh`), e ficam fora do arquivo. Essa distinção é o ponto
mais importante deste documento e é explicada na §5.
