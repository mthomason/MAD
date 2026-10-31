---
layout: default
lang: pt-BR
---

# A Direção: Um Relatório É uma Tabela

Atualizado em 2026-10-29. Esta página descreve a direção para a qual o MAD foi projetado para
evoluir. Nenhum dos mecanismos de composição ou migração descritos aqui foi construído
ainda; o documento de arquitetura que fundamenta o modelo de objetos de dados é
[`docs/project/MAD_DATA_OBJECT.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_DATA_OBJECT.md),
o registro de trabalho é
[`docs/project/MAD_FUTURE.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_FUTURE.md),
e a lista de desejos do produto é
[`docs/project/TODO.md`](https://github.com/mthomason/MAD/blob/master/docs/project/TODO.md).

## Onde o MAD está hoje

Um documento `.mad` é a *definição* de um relatório: o snapshot do esquema, o grafo
de consulta (tabelas, joins, agrupamentos, filtros) e a árvore de layout em bandas. Ao
atualizar (`refresh`), a engine compila o grafo em SQL, lê as linhas uma única vez e
as materializa em um cache SQLite complementar (`.maddb` + `.mdcache`). Os dados de
linhas permanecem deliberadamente fora do documento; a definição se mantém abaixo de 100 KB.

Uma consequência disso passa facilmente despercebida: **um relatório é uma função que mapeia fontes de dados
para uma tabela.** Cada driver retorna um esquema e linhas em formato tabular, e a
saída de um relatório *é* um esquema (`MADDataColumn`) e linhas em formato tabular
(`MADDataTableFast`). A engine já trata ambos de maneira idêntica.

## Para onde ele está indo

Fechar o ciclo entre a definição de um relatório e sua saída materializada
destrava quatro capacidades principais:

### 1. Um arquivo `.mad` como uma tabela de banco de dados ad hoc

Em um banco de dados tradicional, você faz `SELECT` a partir de tabelas base como `employee` ou `sales_data`. Um
relatório conecta múltiplas tabelas, e sua saída é uma tabela SQLite ad hoc
materializada. Hoje nada consegue apontar uma consulta para a saída de outro relatório —
o cache de resultados existe, mas é indexado por um hash de nome de arquivo em vez
de uma identidade endereçável. Tornar essa saída endereçável significa que:

> **O resultado de um relatório passa a ser uma tabela de banco de dados que outros relatórios e
> consultas podem consultar com `SELECT` e combinar com `JOIN`.**

Um relatório construído sobre outro relatório forma um DAG (grafo acíclico direcionado) de tabelas derivadas — uma camada semântica
portável na qual projetar um relatório também significa projetar uma fonte de dados reutilizável.

### 2. Múltiplas fontes de dados em um único relatório

Cada driver (`MADMySQL`, `MADPostgres`, `MADTdsClient`, `MADSqlite3`)
materializa seu conjunto de resultados na mesma representação local de tabela SQLite.
Quando um documento puder conter múltiplas definições de consulta e endereçar cada saída como
uma tabela, um único relatório poderá fazer join de uma tabela do PostgreSQL com uma tabela do SQL Server e com uma
tabela do MySQL — federadas localmente no SQLite, sem um servidor pesado de federação no
meio do caminho. Os próprios snapshots *são* a federação.

### 3. O papel como apenas um paradigma — views nativas em UIKit sobre dados brutos

A paginação em bandas (Report Header, Page Header, Groupings, Detail, Footers) foi
inventada para impressão em papel. Como o layout de um `.mad` é composto por dados paramétricos e
o cache de linhas `.maddb` é um banco SQLite local no dispositivo, as páginas em papel são apenas uma
das formas possíveis de apresentar um relatório. Quando o usuário não está imprimindo, a mesma definição
e o mesmo cache local podem ser renderizados como views nativas interativas em UIKit e exploradores
de dados brutos — diagrame uma vez, visualize como papel ou como interface nativa.

### 4. Convertendo arquivos legados do Crystal Reports (`.rpt`) para arquivos `.mad` abertos

O Crystal Reports (`.rpt`) e arquivos de relatórios legados semelhantes continuam enraizados
em milhares de empresas porque nenhuma engine aberta e portável compartilha seu
modelo de seções em bandas + grafo de consulta relacional. Como o MAD é construído exatamente sobre esse
paradigma estrutural — mas armazenando suas definições em um formato SQLite-in-tar aberto e
documentado —, converter documentos `.rpt` legados em
arquivos `.mad` oferece às organizações um caminho direto de migração para sair de pilhas
proprietárias de relatórios legados.

## O que já existe

As partes mais complexas e custosas já estão prontas: definições portáveis, geração e
parsing determinísticos de SQL, um formato portável de materialização (SQLite), quatro
drivers de banco de dados e uma única engine que roda nativamente no iOS/macOS e em modo
headless no Linux.

## O que isto não é

Uma promessa de prazo. Esta página registra a direção arquitetural; o projeto detalhado e a fila de tarefas
vivem em `docs/project/`, e nada do que está descrito aqui é lançado até que seja
projetado, testado e documentado com o mesmo rigor de todo o restante do repositório.
