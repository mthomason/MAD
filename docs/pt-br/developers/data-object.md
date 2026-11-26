---
layout: default
title: "O objeto de dados"
description: "A definição, o esquema e o conjunto de resultados de um relatório como um único contrato."
lang: pt-BR
---

# O Objeto de Dados — a definição de um relatório, seu esquema e seu conjunto de resultados

Esta página define o objeto de dados: a definição de um relatório, seu esquema e seu conjunto de resultados como um único contrato. É o design sobre o qual o trabalho multifonte é construído; a especificação do formato descreve o documento como ele é distribuído hoje.

**Escopo:** o conceito levantado em 2026-10-16 — o que é um objeto de dados, como ele é representado
neste código e o que é preciso para formalizá-lo. A montagem multifonte / de sub-relatórios descrita
na mesma conversa está registrada aqui como consequência do contrato, deliberadamente
não construída.
**Data:** 2026-10-16, lido em `445794e11`.
**Status:** documento de design. Ele propõe; não implementa nada, e nada aqui está
agendado. [a visão do projeto](../vision.html) §1 — "um relatório é uma função de fontes de dados para uma tabela" — é
a visão que este arquivo torna concreta e nomeia o código para ela.

---

> **Decisão final sobre a composição (2026-11-26):** o esboço de composição da §5 (incluindo
> sua recomendação de Layout B, §5.1/§9.2) foi substituído pelo documento normativo
> [`MAD_COMPOSITION_SPEC.md`](../../project/design/MAD_COMPOSITION_SPEC.html), que adota o
> Layout A (`ATTACH`, um `.maddb` por nó). A §0 da especificação é **final**: cada nó de uma
> composição é um relatório completo com seu próprio layout e seus próprios dados; a raiz é o
> relatório padrão do documento, não o único. Combinar relatórios leva o layout e o resultado
> de cada filho junto.

## 1. A ideia, e o que ela não é

Hoje o usuário projeta uma consulta ad hoc contra um banco de dados (MySQL, SQL Server ou Sqlite3),
ela retorna uma tabela de dados, e o relatório é construído sobre esses dados pelas ferramentas de layout. O
relatório é consulta mais layout. A generalização é pegar a metade da consulta e torná-la o
objeto:

> Um objeto de dados é uma definição nomeada que produz um **esquema** e um **conjunto de resultados** — a
> consulta de um relatório, separada de seu layout e dotada de uma identidade, para que sua saída possa ser
> atualizada, endereçada e usada como fonte por outro objeto de dados. Um relatório é um objeto de dados
> mais uma apresentação vinculada às colunas do objeto.

As próprias palavras do usuário (2026-10-16): *"algo que retorna um tipo de esquema e um conjunto de
resultados, enquanto o relatório é consulta ad hoc, relatório e design."*

Três consequências, cada uma perseguida abaixo:

1. **A consulta torna-se a fronteira do produto.** O mesmo objeto serve ao designer (o que a
   aba MAD Query edita), ao visualizador (o que a atualização executa), à CLI (o que `mad refresh`
   executa), a um futuro servidor web (o que um endpoint executa) e a uma IA (o que ela redige e a
   engine valida). Uma definição, muitos consumidores — o que só é verdade quando o objeto tem
   um nome e um esquema próprios.
2. **Objetos se compõem.** *"A ideia seria vincular vários deles. No mundo de relatórios,
   estes seriam sub-relatórios"* (usuário). Em termos de dados, é um DAG de tabelas derivadas:
   a saída de um objeto é uma tabela para outro, exatamente como uma tabela de esquema é hoje.
3. **As fontes se multiplicam como consequência, não como recurso.** Um objeto por banco de dados de origem —
   cada um já carrega seu próprio driver e conexão — materializado, depois unido por suas
   saídas. O esboço do usuário: *"você consultaria MySQL em um sub-relatório, e consultaria
   SQL Server em um sub-relatório… e então poderia vincular esses relatórios como tabelas no
   designer de consultas por sua saída."* [a visão do projeto](../vision.html) §1 diz o mesmo: nenhuma engine
   de federação é necessária; os snapshots *são* a federação.

O que ele explicitamente **não** é:

- Não é uma engine de federação. Nada de novo fala com MySQL e SQL Server em uma única instrução; cada
  objeto executa contra sua própria fonte, e a junção acontece sobre os resultados já locais.
- Não é uma segunda implementação de consulta. O gerador de SQL, os drivers, a tabela de resultados e
  a engine de junção SQLite já existem; a §5 é uma montagem sobre eles.
- Não é uma mudança no paradigma de cache de duas passagens que puxa tudo. O cache é estrutural e
  deliberadamente grande (`MAD_FORMAT.md` §5.1); um objeto de dados produz exatamente o que o cache
  já contém hoje.

## 2. Vocabulário, porque "esquema" são quatro coisas diferentes neste código

| Termo | O que é | Classes de hoje |
|---|---|---|
| **Esquema de origem** | As tabelas e campos de um banco de dados que o usuário pode consultar | Navegação ao vivo: `MADDatabaseTable` / `MADDatabaseField` (`MADAPI`). Snapshot: `RptqDatabaseSchemaTable` / `RptqDatabaseSchemaField`, importados uma vez na criação do documento |
| **Definição** | O grafo da consulta: quais tabelas, quais campos, as junções, filtros, agrupamentos, ordenação | `RptqQuery` + `RptqQueryTable` / `RptqQueryField` / `RptqQueryLinks` / `RptqQueryPredicate` / `RptqQueryGroup` |
| **Esquema de resultado** | As colunas da saída: nome, tipo, tipo nativo, comprimento/precisão, chave primária, não nulo | `MADDataColumn` (uma por coluna), carregada na tabela |
| **Conjunto de resultados** | As linhas | Cluster de classes `MADDataTable`; materializado como `MADDataTableFast` |
| **Materialização** | O conjunto de resultados em disco: a tabela SQLite e seu esquema serializado | `<tag>.maddb` (SQLite) + `<tag>.mdcache` (plist, `MADDataTable -copyPlist`) no diretório de cache do documento |
| **Snapshot** | A palavra de `MAD_FUTURE.md`: uma materialização tornada nomeada, versionada e endereçável | Não existe; a §4.3 é como ela começa |
| **Esquema do armazenamento** | Sem relação com tudo acima: o formato de armazenamento do próprio documento | `MADStoreSchema` (`MAD/Source/rptq/store/`) |

O documento hoje contém definições e layouts; as materializações vivem ao lado dele, com chave pelo
documento (não pela definição). Essa separação é a correta — `MAD_FORMAT.md` §5 — e
este design a mantém.

## 3. Como a ideia é representada hoje

Cada peça de um objeto de dados já existe, em uma camada diferente, construída para um propósito
diferente. O que segue é o estado exato de cada uma, com a costura que a formalização apertaria.

### 3.1 A definição existe — `RptqQuery` e seu grafo

O grafo da consulta está completo o suficiente para compilar: tabelas (`RptqQueryTable`, com `alias` e um
`dropIndex` para que uma tabela de esquema possa ser incluída várias vezes), projeções
(`RptqQueryField` — ids de tabela e campo de esquema), junções (`RptqQueryLinks`, com um tipo de link),
filtros (`RptqQueryPredicate`), agrupamentos (`RptqQueryGroup`, conduzindo descritores de ordenação
via `RptqQuery -sortDescriptorsForDatabase:`) e uma linha de ordenação vestigial (`RptqQuerySort`,
lida apenas por descrições de depuração). O designer o edita através do modelo de leitura `MADModel*`
("escreva através de `Rptq`; leia e observe através de `MADModel`" — `MADModel_Layer.md`).

Um agrupamento é uma definição de nível de consulta, não uma seção de relatório. `RptqQueryGroup.hasField`
nomeia o campo pelo qual a consulta agrupa e `sort` sua direção. Para a consulta ser executada, o campo de cada
agrupamento deve pertencer a uma tabela de consulta que o documento seleciona
(`hasField.inQueryTable`): o agrupamento é materializado como uma chave ordenada sobre as linhas do resultado
(`-sortDescriptorsForDatabase:`), e o formatador compara essa chave para encontrar os limites do agrupamento.
Uma seção de cabeçalho/rodapé de agrupamento do relatório é apenas a apresentação desse agrupamento —
ela pode não conter nenhum elemento que exiba o campo de agrupamento, e o agrupamento ainda ocorre.
Nenhum layout pode fornecer um campo de agrupamento ausente, então um agrupamento com um campo nulo, ou um campo não
respaldado por uma tabela de consulta selecionada, é um documento inválido. O designer ainda constrói e
rotula essa seção para que o agrupamento quebrado possa ser visto; a execução da consulta e a renderização o recusam
com `NSInvalidArgumentException` e registram o agrupamento.

Dois fatos sobre sua identidade:

- Um `RptqQuery` pende de uma linha `RptqDatabase` e alcança o documento através de
  "o primeiro de cada": `RptqDatabase -defaultQuery` é `hasQueries.anyObject`
  (`RptqDatabase+Extras.m:88`), `RptqDocument -mainQuery` da mesma forma (`RptqDocument+Extras.m:184`).
- O armazenamento já permite muitos: `MADModelDocument` constrói **um `MADModelDatabase` por
  linha `RptqQuery`** (`MADModelDocument.m:210-240`), com o próprio comentário do código de que "as versões
  atuais do software usam apenas um banco de dados e uma consulta." A cardinalidade é uma convenção
  dos fluxos do aplicativo, não do armazenamento.

### 3.2 O compilador existe — `MADQueryFull`

`MADQueryFull -copySQLWithManagedObjectContext:error:` (`MADQueryFull.m:133`) constrói o SQL:
as colunas projetadas vêm de `MADQuerySelectExpressionActiveFields`, que pergunta a
`MADQueryActiveQueryFields` por todo campo que os *elementos*, links e agrupamentos do relatório
referenciam; FROM/JOIN é compilado a partir de um `MTGraph` de tabelas e links, ordenado topologicamente
(`:170-204`); predicados e a citação de literais passam pelo `MADDatabase`
(`newSafeIdentifier:`, `newSafeLiteral:`); `LIMIT` via `sqlLimitClause:`.

Esta é a geração de SQL determinística e própria que `MAD_FUTURE.md` §3 conta como um diferencial
— ela existe, e é headless (na compilação Linux, `MADSources.cmake:93`).

**Mas ela está soldada ao documento.** `MADQueryFull` armazena a consulta com a qual foi inicializada
em `queryObject` (`:79`) e **nunca a usa**: o caminho SQL relê o primeiro banco de dados e a primeira
consulta do documento (`:147-149`). E ela não implementa `-getSql:error:` (a base
retorna `@""`, `MADQuery.m:48`), então o caminho genérico `MADDatabase -executeQuery:withError:`
não pode executar a consulta principal do documento de forma alguma. O objeto de consulta que você entrega a ela não determina
o que é executado.

### 3.3 A costura de execução existe — `MADDatabase`

O ponto abstrato é
`-[MADDatabase executeSQL:fieldKeys:onConnection:intoResultTable:withError:]`
(`MADAPI/Source/MADDatabase.m:147`, sobrescrito pelos três drivers). Seu destino é
tipado como `id <MADDataTableWriting>` — *qualquer* tabela gravável, não uma classe de tabela. O contrato de preenchimento
é uniforme entre os drivers: `removeAllObjects` → `addColumn:` → `beginBulkInsert` →
`addRowWithDataForFieldKeys:` → `endBulkInsert` (drivers de `MAD_DATA_OBJECT`: MySQL
`MADMySQLFetch+DataTable.m:148-235`, SQL Server `MADDatabaseSQLServer.m:485-571`, Sqlite3
`MADDatabaseSqlite3.m:474-540`).

Os drivers também já preferem a própria tabela de destino de uma consulta à do documento, quando a
consulta conforma-se a `MADQueryDataTableProtocol` (`MADQuery.h:28-50`; o
`-executeQuery:` de cada driver a verifica — por exemplo, `MADDatabaseMySQL.m:331-339`). Múltiplas tabelas de resultado por
processo são um ponto de extensão pretendido, exercitado apenas pela família de consultas de dados de exemplo.

A costura em nível de documento é `MADOperationRefresh` (`MADDesigner/Source/MADOperationRefresh.m`,
131 linhas, zero UIKit): credenciais entram, `document.mainQuery` → SQL, `document.database`
conecta, executa em `document.dataTable`, `dataTableMakeCache` grava o `.mdcache`,
`document.refreshed = YES`. É também o verbo de atualização da CLI, compilado através da fronteira de alvos
por `REFRESH_SOURCES` de `CLI/build.sh` (`ROADMAP.md` §3.4). É *atualizar +
persistir + publicar*, não *executar*: está fixamente ligado ao estado compartilhado do documento, descobre
credenciais inspecionando `self.dependencies` e altera o documento.

### 3.4 O valor de retorno existe — `MADDataTable` e `MADDataColumn`

`MADDataTable` (`MADFoundation/Source/MADDataTable.h`) é o cluster de classes cujo trabalho inteiro
é "esquema mais linhas": metadados mais persistência na base, armazenamento por subclasse
(`MADDataTableVirtual` em memória, `MADDataTableFast` sobre SQLite). O objeto de esquema é
`MADDataColumn` — `identifier`, `fieldName`, `caption`, `type` (`MADDataType`), `nativeType`,
`dataLength`, `dataPercision`, `isPrimaryKey`, `isNotNull`, `isAutoIncrement`, `defaultValue`
— uma descrição de coluna de primeira classe e serializável.

E o esquema já é separável das linhas em disco: `-copyPlist`
(`MADDataTable.m:238-253`) serializa nome + chaves de coluna + plists de coluna + contador de linhas e
**explicitamente nenhuma linha** — que é exatamente o que o arquivo `.mdcache` é, gravado e lido por
`MADDataTableFast` (`-copyPlist` / `-loadWithPlist:`; `MAD_FORMAT.md` §5.3).

O que falta nesta camada:

- **Nenhuma API somente de esquema.** Nada retorna o esquema de resultado de uma consulta sem executá-la.
  Esquema e dados são um único objeto, nunca dois — o esquema é descoberto *a partir* das linhas.
- **Resultados Sqlite3 com zero linhas perdem inteiramente o esquema.** O driver Sqlite3 descobre
  colunas apenas dentro da primeira iteração `SQLITE_ROW` (`MADDatabaseSqlite3.m:496-535`), então um
  resultado vazio produz uma tabela sem colunas e sem DDL. MySQL e SQL Server adicionam colunas
  a partir dos metadados do resultado antes de qualquer linha chegar, então a lacuna é específica do Sqlite3.
- Os `columnKeys` de `MADDataTableFast` são nomes gerados `c<hash>`, não nomes de campo; a superfície
  de esquema utilizável é o dicionário `columns` de `MADDataColumn`. E `for (x in fastTable)`
  silenciosamente não produz nada — a base retorna 0 itens e Fast não sobrescreve
  `countByEnumeratingWithState:`; os chamadores devem usar `objectEnumerator`.

### 3.5 A materialização é uma tabela SQLite hoje

`MADDataTableFast` não é uma abstração sobre uma tabela; ela *é* a tabela. Cada instância possui
uma tabela SQLite física `t<tag>` em `<tag>.maddb` (`-tableName` `MADDataTableFast.m:498`,
`-filenameCacheMadDB` `:399`), com colunas `c<hash-of-fieldName>`. Uma segunda conexão
(`databaseForSelects`) executa o lado de seleção. O agrupamento é índices nessa única tabela
(`-sortUsingDescriptors:` `:737`, `-setupGroupKeyIndexes` `:545`, um índice por nível de prefixo de agrupamento),
e os agregados são SQL sobre o cache (`MADQueryCacheAggregateFunction`, conduzido por
`MADocument -dataForRows:column:groups:function:groupBy:`). **Nenhum `GROUP BY` é gerado
para o banco de dados de origem** — verificado: a string não aparece em nenhum arquivo-fonte. A
origem é consultada de forma plana; tudo agrupado ou agregado é calculado localmente, sobre a
materialização, pelo Sqlite3.

Dois stubs reveladores mostram que a arquitetura tem motivo para querer *muitas* tabelas: a fábrica de classes
`MADDataTable+Constructor` (`newDataTableOfType:withObjectID:cacheDirectory:` — físico mapeia
para `MADDataTableFast` com o id como tag, `:56-78`) torna a segunda e a terceira tabelas baratas por
construção; e `-cacheTableNameForGroupLevel:` (`MADDataTableFast.m:813`) nomearia uma
tabela `s<level>` por nível de agrupamento — ela **não tem chamadores**; as tabelas por agrupamento que ela implica
nunca se materializam.

**O endereço é o nome do arquivo.** A tabela do documento é criada com
`initWithId: fileURL.lastPathComponent.hash` (`MADocument.m:269-283`); o diretório de cache é
nomeado `dataTableIdHash` (`MADURLFactory newURLCacheFilesDirectoryForFilename:`). Uma tabela de resultado
por documento; seu nome muda quando o documento é renomeado; nada pode apontar para ela.

### 3.6 O que falta, em uma tabela

| Camada | Existe | Falta para um objeto de dados |
|---|---|---|
| Definição | Grafo de consulta completo; modelo de leitura; o armazenamento permite muitas consultas | Um nome e uma identidade próprios; uma referência de fonte que possa ser outro objeto de dados |
| Compilador | SQL determinístico a partir do grafo | Liberdade de "a primeira consulta do documento"; um caminho somente de esquema |
| Execução | Qualquer destino `MADDataTableWriting`; três drivers; tabelas de destino por consulta | Uma execução que não seja atualização — sem mutação do documento, credenciais passadas e não descobertas |
| Valor de resultado | `MADDataTable` + `MADDataColumn`; persistência somente de esquema (`-copyPlist`) | Uma API de esquema sem execução; a perda de esquema com zero linhas |
| Materialização | Tabelas SQLite reais `t<tag>`; agrupamento e agregados locais | Tag = hash do nome do arquivo; uma tabela por documento por convenção |
| Vinculação | Layout → `referencesQueryField` → resolvido na renderização por `MADDocumentObjectDataReference*` | Vinculação a *um* objeto de dados em vez da única consulta *do* documento |
| Endereço | — | Tudo |

Três pontos de fixação são os bloqueadores concretos, e todos os três são visíveis no código:

1. `MADQueryFull` ignora seu próprio objeto de consulta (`MADQueryFull.m:147-149`).
2. `MADDocument -dataTableForQuery:` retorna `self.dataTable` para `MADQueryFull` e nil para
   todo o resto (`MADocument.m:908`) — um switch de um único slot.
3. `MADQueryActiveQueryFields` varre **todos** os elementos, links e agrupamentos no armazenamento sem nenhum
   escopo de consulta (`MADQueryActiveQueryFields.m:27-99`), sob seu próprio FIXME no cabeçalho: *"Agora
   mesmo o software só lida com um objeto de consulta."* Os campos de uma segunda consulta vazariam para
   a lista SELECT da primeira.

## 4. O contrato

### 4.1 Forma no código (proposta, ilustrativa)

Duas metades, deliberadamente separadas:

```objc
@protocol MADDataObjectSchema <NSObject>            // describe: no database needed
- (NSArray<MADDataColumn *> *)resultSchema;          // columns, types, from graph + snapshot
@end

@protocol MADDataObjectExecuting <NSObject>          // execute: yields the materialization
- (nullable MADDataTable *)executeIntoDataTable:(nullable MADDataTable *)target
                                      credentials:(MADCredentials *)credentials
                                            error:(NSError **)error;
@end
```

Os nomes são ilustrativos; a divisão é o ponto. **Descrever** deve funcionar sem nenhuma
conexão, sem credenciais e sem linhas — a partir do grafo mais o snapshot de esquema armazenado —
porque é o que o designer desenha, o que a IA valida, o que um servidor web
lista e o que um documento renomeado não pode corromper. **Executar** deve receber uma tabela de destino e
credenciais como argumentos e retornar a tabela — sem mutação do documento, então `MADOperationRefresh`
encolhe para "chamar executar, depois persistir, depois publicar", e a CLI, um servidor e um teste todos
chamam a mesma coisa.

### 4.2 Esquema sem executar

Esta é a primeira prova honesta de que o contrato é real, porque ele é *derivável* e nada o
deriva hoje: o esquema de resultado é exatamente a lista SELECT que `MADQueryFull` já
calcula — os campos ativos da consulta, com alias `Table.Field`, mais o que os agregados e
agrupamentos projetam. Os tipos e larguras vêm do snapshot de esquema
(`RptqDatabaseSchemaField`); as colunas de agregado, de `MADAggregateFunctionType`. O trabalho é
separar a construção da lista SELECT da execução e retorná-la como `MADDataColumn`s. Isso também
corrige a lacuna Sqlite3 de zero linhas de graça, no momento em que as colunas existem antes das linhas: os drivers
já fazem `addColumn:` antes de `addRow:`, e a DDL da tabela é criada na primeira coluna
(`MADDataTableFast.m:526-543`).

### 4.3 Identidade e endereço

Um objeto de dados precisa de um nome que sobreviva a renomeações e de um endereço que sobreviva à regeneração:

- **Identidade:** o `identifier` de uma linha do armazenamento, como toda outra entidade `Rptq`, mais um
  nome voltado ao humano. A tag da materialização torna-se o hash do identificador do objeto, não
  `fileURL.lastPathComponent.hash` — o que aposenta, para este propósito, o endereçamento
  com chave de nome de arquivo (perigo da §5.3 de `MAD_FORMAT.md`; a nota "hash de conteúdo como chave" da §2.2 de `MAD_FUTURE.md`
  é a mesma correção na camada de renderização).
- **Endereço:** o diretório de cache já contém um `.maddb` por documento; a formalização
  natural é uma tabela `t<tag>` **por objeto de dados** nele (as tags já os tornam
  distintos), cada uma com seu próprio plist de esquema no estilo `.mdcache`. O arquivo `.maddb` por objeto
  (o emparelhamento `t<tag>`/`<tag>.maddb` tomado literalmente) é a alternativa; a §5.1 diz quando
  isso importa.

### 4.4 Onde o armazenamento muda — e o que ele já permite

Forma mínima, recomendada:

- `RptqQuery` ganha um nome (ele já é a definição; nada se move).
- A referência de `RptqQueryTable` — hoje um id de tabela de esquema dentro de um `RptqDatabase` — ganha um
  segundo tipo: **outro objeto de dados**. Esta é a única mudança de esquema de que a composição precisa,
  e é aditiva: uma linha v1 com uma referência de tabela de esquema significa exatamente o que significa hoje.
- Multifonte não precisa de nenhuma mudança no armazenamento: o armazenamento já suporta muitas linhas
  `RptqDatabase`, cada uma com sua própria consulta (um `MADModelDatabase` por `RptqQuery`, §3.1). O que os documentos
  de hoje têm é uma de cada porque o fluxo de criação cria uma; o esquema foi
  preparado para o futuro em 2017 e ainda está esperando.

A alternativa mais pesada — uma nova entidade `RptqDataObject` proprietária da definição, com
`RptqQuery` rebaixado — tem nomenclatura mais limpa e uma migração maior. Registrada como decisão 9.1.

## 5. Composição — a montagem de sub-relatórios, documentada, não construída

**Esta seção é deliberadamente não agendada** (o usuário, 2026-10-16: *"Não quero montar
isso… mas quero documentar esta ideia"*). Ela existe para que, quando for desejada, seja um plano
em vez de uma descoberta.

### 5.1 O mecanismo, precisamente

1. Cada objeto de dados executa contra sua própria fonte — seu próprio `RptqDatabase`, driver e
   credenciais — e materializa em sua própria tabela SQLite (uma `t<tag>` no cache do documento,
   conforme a §4.3).
2. O grafo de consulta do objeto compositor é inalterado em espécie: suas "tabelas" incluem objetos de dados;
   junções, filtros e aliases todos se aplicam, porque em ambos os lados uma tabela é um conjunto de colunas
   nomeadas.
3. A execução é topológica sobre o DAG de objetos (o mesmo algoritmo que `MADQueryFull` já
   executa sobre o grafo de junções, `MADQueryFull.m:202`): fontes primeiro, objeto compositor por último, seu
   resultado materializado como qualquer outro.
4. O objeto compositor executa **contra o cache, não contra um banco de dados remoto** — é uma consulta
   cujo "banco de dados" é o `.maddb`. `MADSqlite3` já é um `MADDatabase` completo, então o
   driver para este passo é distribuído hoje. Um `.maddb` contendo várias tabelas `t<tag>` não precisa de
   `ATTACH` de forma alguma; `ATTACH DATABASE` é a variante para **arquivos separados** — um `.maddb` por
   objeto, ou objetos de *documentos diferentes*, que é o caso em que a fronteira do sub-relatório
   é uma fronteira de arquivo e `ATTACH` (ou uma cópia para dentro) é a única rota de junção.

A versão de uma linha, que é toda a razão de isto ser uma montagem e não um projeto: **o
resultado de toda consulta já é uma tabela SQLite, e o SQLite já é um driver.** A
engine de federação está na caixa; atualmente ela é endereçada por um hash de nome de arquivo.

### 5.2 O que seria construído, se desejado

1. O contrato da §4 (descrever/executar, identidade, endereço) — um pré-requisito, não uma fase.
2. O tipo de fonte: `RptqQueryTable` → objeto de dados; a geração de SQL o resolve para a
   tabela de materialização do objeto em vez de `db.table`.
3. A ordem de execução: percorrer o DAG; atualizar objetos obsoletos; depois a consulta compositora.
4. A telescopia do designer (palavra do usuário): no painel Adicionar Tabela, um segundo tipo de
   fonte ao lado das tabelas de esquema — os outros objetos de dados do documento, ou uma caixa de sub-relatório que
   lista os campos de saída do outro objeto. A interface de junção é inalterada; ambas as extremidades são campos.
5. Suporte a `ATTACH` em `MADDatabaseSqlite3` se e quando a composição entre arquivos for desejada.

### 5.3 O que faz isto não ser uma linha de código

Registrado para que a estimativa permaneça honesta: os três pontos de fixação da §3.6
(a releitura de `MADQueryFull`, o `dataTableForQuery:` de um único slot, o
`MADQueryActiveQueryFields` sem escopo) cada um tem de cair antes que uma segunda consulta — muito menos uma *aninhada*
— possa executar; `MADModelDocument` espelha apenas `firstQuery` no caminho de mudança
(`MADModel_Layer.md` §8); e `RptqQuery -sortDescriptorsForDatabase:` agrupa contra o
único cache do documento. Nenhum é difícil; todos são estruturais para o aplicativo atual de consulta única.

## 6. A CLI, o servidor web e a engine

A pergunta do usuário, 2026-10-16: *"a CLI é realmente para testes, compreensão e uso
futuro… é importante, mas o objetivo é ter algo que possa ser chamado a partir do servidor web,
e não sei se a CLI é a melhor maneira de fazer isso."*

A resposta honesta, como os artefatos estão:

- **A CLI é um cliente da engine, não a engine.** Seus seis verbos —
  `inspect`, `schema`, `query`, `refresh`, `export`, `write` — são sítios de chamada de exemplo da cadeia de chamadas
  da §3: abrir o contêiner, ler o armazenamento, gerar SQL, executar em uma tabela, renderizar. O que
  um servidor web precisa é da mesma cadeia atrás de um ponto de entrada estável; um subprocesso é uma
  vinculação dessa cadeia (a forma que a §2 de `MAD_LINUX.md` esboça: `mad --format json` como um
  subprocesso), uma biblioteca vinculada outra, uma API Objective-C/Swift em processo uma terceira.
- **O ponto de entrada é a peça que falta, e ele está nomeado.** Não há hoje nenhuma classe de nível superior
  livre de UIKit que abra um `.mad`, execute a consulta e retorne linhas: na Apple,
  `MADocument` é um `UIDocument`; o `MADCLIDocument` da CLI é headless em *comportamento* mas
  espera no loop de execução por esse UIDocument.  (A Fase D resolveu o lado headless:
  `MADHeadlessDocument` é o ponto de entrada no Linux, e desde a Fase E ele carrega também a metade de renderização
  — `MADDocumentRenderProtocol`, `MADReportPageBuilder` — então `mad export` é executado
  ali.  `MAD_LINUX.md` §9.)  O contrato da §4 é o que esse ponto de entrada exporia:
  abrir → listar objetos de dados → descrever → executar → (esquema, linhas).
- **O formato de transmissão é uma decisão, não três.** Esquema + linhas como JSON é a mesma forma que
  a exportação JSON (`MAD_CLI.md` §8.3, tabela de decisões de `ROADMAP.md`) e a saída estruturada
  que uma camada de IA valida (`MAD_FUTURE.md` §7). `MADDataColumn` já é uma descrição de coluna
  conversível em plist; o plist `.mdcache` já é um esquema de resultado serializado. Projete a forma JSON
  uma vez, abertamente, e a exportação, a API e a IA todas a consomem.
- **O que a CLI continua responsável** é a disciplina que a Trilha 3 de `ROADMAP.md` estabeleceu: o
  documento visível com o aplicativo fora do caminho, os códigos de saída (0–5) como o vocabulário de erro,
  os fixtures de ida e volta que fixam o formato. Esses não se movem para o servidor web; eles são
  como a engine do servidor web permanece honesta.

Os fatos medidos por trás de "isto é barato quando o contrato existir": o caminho de dados já é
headless — geração de SQL, o armazenamento, `MADDataTableFast` e todos os três drivers compilam no
Linux hoje, com 124 executáveis de teste e 1.270 testes verdes (`Linux/README.md`), e desde a
Fase D a CLI compila e executa nessa imagem (`inspect`, `schema`, `query`, `refresh`,
`export`, `write`). Então a ordem que se segue é o contrato primeiro, o ponto de entrada segundo,
as interfaces terceiro — e isso torna "CLI ou servidor web?" uma pergunta com uma resposta de duas linhas
em vez de uma bifurcação arquitetural.

## 7. O que seria preciso — em fases, sobre as trilhas existentes

Ordenado para que o aplicativo continue sendo distribuído e a suíte permaneça verde o tempo todo; cada fase nomeia a
mudança da §3 que ela aposenta.

| Fase | Trabalho | Aposenta |
|---|---|---|
| 1 | **O contrato.** Separe a construção da lista SELECT de `MADQueryFull` da execução; retorne-a como `MADDataColumn`s. Adicione os protocolos descrever/executar; faça `MADOperationRefresh` chamá-los. Sem mudança de comportamento. | Nenhuma API somente de esquema; perda de esquema Sqlite3 com zero linhas |
| 2 | **A consulta é dona de si.** `MADQueryFull` recebe a consulta que lhe foi dada (sem releitura do documento); `-dataTableForQuery:` resolve por consulta; `MADQueryActiveQueryFields` limita-se a uma consulta; `MADModelDocument` espelha qualquer consulta. Um documento, muitos objetos. | Todos os três pontos de fixação da §3.6 |
| 3 | **Identidade e endereço.** Nomeie o objeto no armazenamento; marque materializações pelo identificador do objeto, não pelo nome de arquivo; uma tabela de resultado por objeto no cache; plist de esquema por objeto. | Materialização com hash de nome de arquivo; uma tabela por documento |
| 4 | **A vinculação e as superfícies.** O layout vincula-se ao esquema de um objeto de dados; a CLI ganha `describe`; a forma JSON é fixada uma vez (exportação + API + IA). | Vinculação à "consulta do documento" |
| 5 | **Composição** (§5), somente quando solicitada. | — |

A Fase 1 é a carga útil real do design e a menor: não precisa de mudança no armazenamento, nem de mudança
na interface, nem de novo formato — ela reordena código que já existe, e é demonstrável pelas
suítes atuais mais uma asserção de esquema em uma consulta com zero linhas. As Fases 2–4 são a mesma ideia
aplicada às camadas que sustentam a suposição de consulta única. A Fase 5 é a montagem, documentada,
não agendada.

## 8. O que não fazer

- **Não construa a montagem multifonte agora.** A decisão do usuário, 2026-10-16; este documento é
  o registro, não um item de fila. (Aplicam-se as convenções de `TASKS.md`/`BUGS.md`: nada aqui é
  iniciado por iniciativa do agente.)
- **Não comprima nem reprojete o cache.** Ele é estrutural, o design de duas passagens precisa dele,
  e a §5.1 de `MAD_FORMAT.md` é a análise vigente.
- **Não construa uma engine de federação.** Conforme §1 e §5, as materializações são a
  federação.
- **Não implemente um segundo gerador ou executor de SQL.** Tudo, exceto o endereçamento e
  a ordenação, existe.
- **Não toque nas coisas deliberadamente mortas** (`MADQueryDefinition*`, `RptqQuerySort`,
  `MADQueryFullTableEnumerator`, os campos de substituição de texto livre) como parte disto — elas são
  decisões de limpeza separadas.

## 9. Decisões em aberto

1. **A forma do armazenamento.** Nomear o `RptqQuery` existente (mínimo, recomendado) ou introduzir
   `RptqDataObject` como sua própria entidade (migração mais limpa, maior)?
2. **A unidade de materialização.** Um `.maddb` por documento com uma `t<tag>` por objeto
   (recomendado — sem `ATTACH`, sem novos arquivos), ou um arquivo por objeto (`ATTACH` ao
   compor)?
3. **O que é o snapshot.** A §2.2 de `MAD_FUTURE.md` torna o par de materialização
   (`.maddb` + `.mdcache`) o artefato compartilhável. Sob este design, a unidade de compartilhamento é
   o resultado do objeto de dados ou o documento?
4. **O que o esquema de um objeto de dados expõe para fora.** `MADDataColumn` é rico;
   nome/tipo/comprimento é o que um servidor web e uma IA precisam. A forma JSON (decidida uma vez, §6) é
   onde isto se fixa.
5. **Nomenclatura.** "Objeto de dados" é o termo do usuário e deste documento; `MAD_FUTURE.md` chama o
   artefato da indústria de *modelo*. Um dos dois deve vencer antes que algo seja construído, porque
   ele aterrissa em entidades do armazenamento, protocolos e nos verbos da CLI.

## 10. A linha condutora

A aba de consulta já constrói a função; a cadeia de atualização já a compila e executa;
a tabela de resultados já *é* um esquema e um conjunto de resultados, em disco como SQLite; os drivers que
uniriam duas delas já existem e já compilam no Linux. O que nada disso tem é um
nome, um endereço e uma metade de descrição — as três coisas que transformam "a consulta do relatório" em
um objeto de dados, e um objeto de dados em uma tabela que outro objeto de dados pode usar. O resto — sub-relatórios,
múltiplas fontes, um servidor web apoiado na engine — é composição sobre isso, e compõe
precisamente porque nada novo precisa ser inventado: é o pipeline existente, endereçado por
algo melhor que um hash de nome de arquivo.
