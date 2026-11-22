---
layout: default
title: "Colar SQL no designer de consultas"
description: "O subconjunto SQL suportado, o analisador e o caminho de aplicação."
lang: pt-BR
---

# Entrada SQL do MAD — colar uma consulta SQL no designer de consultas

Esta página registra o recurso de entrada SQL: o subconjunto `SELECT` suportado, o analisador e o resolvedor, e o caminho de aplicação que transforma uma instrução de volta no grafo portátil de consulta. As Fases A-D estão implementadas; a Fase E está adiada.

**Escopo:** um novo analisador/resolvedor/compilador em `MAD/Source/sql/`, um caminho de aplicação em `MADocument`,
o popover SQL em `MADDesigner`, o texto de origem persistido (§8, que adiciona o primeiro
passo de versionamento do armazenamento) e os testes que fixam tudo isso.
**Data:** 2026-10-22, lido em `cf0fe3acd`; revisado em 2026-10-22 com a decisão de persistência (§8).
**Status:** implementado — as Fases A–D chegaram em 2026-10-22 e foram mescladas no master como `c48a39fb7`
(a fila de tarefas interna §16). A Fase E (§9) permanece adiada; as §8.1–§8.2 trazem as emendas conforme construído.

---

## 1. O objetivo

Hoje a única maneira de construir uma consulta é o designer visual: escolher tabelas, vinculá-las campo a
campo, adicionar filtros, adicionar agrupamentos — tudo pela interface com abas. O usuário quer uma segunda forma de entrada:

> "…um usuário poderia apertar um botão e ele vira e mostra uma visão de texto multilinha onde ele
> pode colar o SQL… quando esse SQL é salvo, ele cria manualmente a consulta no backend do
> relatório… ele faz tudo o que já faria com o usuário selecionando todos os detalhes…
> o software ainda reconhece quais campos são usados, quais junções são usadas, quais tabelas são usadas,
> e configura completamente o documento da maneira adequada, e então permite que o usuário até
> use o designer de consultas com os campos inseridos pela consulta padrão (se desejar)."

Então: o SQL colado é **compilado no modelo de consulta do documento** (o grafo de objetos `Rptq`),
através exatamente das mesmas fábricas que o designer visual chama. Após aplicar, o designer visual de
consultas, a tela de visualização e o designer de relatórios todos veem a consulta como se tivesse
sido construída à mão — e o usuário pode continuar editando-a ali. Deve haver uma fase de validação.

## 2. O que existe hoje (lido em primeira mão)

### 2.1 O modelo canônico de consulta — o grafo `Rptq`

A consulta do documento vive no armazenamento portátil como objetos `Rptq*` simples
(`MAD/Source/rptq/`); a camada `MADModel*` é uma visão somente leitura sobre eles
(`MADModel_Layer.md`). O importador grava linhas `Rptq` e nada mais.

* `RptqQuery` (`MAD/Source/rptq/autogen/RptqQuery.h:30-34`): `hasQueryTables`,
  `hasQueryLinks`, `hasQueryPredicate` (observe o nome no singular), `hasQueryGroups`.
* `RptqQueryTable` — uma referência de tabela de esquema mais um alias; o alias é *calculado*:
  o nome da tabela de esquema para a primeira cópia, nome + índice de descarte depois
  (`Customer`, `Customer0`, … — `MADModelQueryTable.m:119-129`).
* `RptqQueryField` — dois ids: `inQueryTable` + `databaseSchemaField`. Todo campo de toda
  tabela de consulta ganha uma linha (o fluxo de adicionar tabela cria uma por campo de esquema,
  `MADQueryViewController.m:762-770`).
* `RptqQueryLinks` — uma junção: `hasLeftField`/`hasRightField` (um `RptqQueryField` cada),
  `type` (`MADLinkType`, `MADQueryLinkType.h`: inner / equi / natural / cross / left / right
  / full outer). Exatamente um par de campos por link; o gerador sempre emite `ON l = r`
  (`MADQueryFull.m:366-380`).
* `RptqQueryPredicate` — `comparson` (`MADPredicateOperator`: `=`, `<>`, `>`, `>=`, `<`,
  `<=` — `MADPredicateOperator.h`, `RptqQueryPredicate+Extras.m:245-265`), mais um
  lado esquerdo/direito que é um `RptqQueryField` ou uma string de valor tipado
  (`leftFieldID`/`rigthFieldID`). Todos os predicados são combinados com AND, cada um escrito `(left op right)`
  (`MADQueryPredicate.m:43-93`). Sem OR, sem LIKE, sem IN, sem funções.
* `RptqQueryGroup` — `hasField`, `sort` (`MADSortOrder`), `weight` e `hasSection`: as
  seções de cabeçalho/rodapé de agrupamento do relatório (`RptqQueryGroup.h:24-29`).

O que o modelo **não** contém — os limites que o importador deve respeitar:

* **Nenhuma lista SELECT.** O SELECT é derivado no momento de construir o SQL a partir de quais campos de consulta são
  referenciados por elementos do designer (rótulos de dados, agregados, códigos de barras), links e agrupamentos
  (`MADQueryActiveQueryFields.m:37-97`, `MADQuerySelectExpressionActiveFields.m`).
* **Nenhum ORDER BY livre.** A ordem de classificação existe apenas por agrupamento (`RptqQueryGroup.sort`).
* **Sem OR / IN / LIKE / funções / subconsultas / UNION** — nenhum é representável.
* **Nenhum texto SQL armazenado** e nenhum versionamento do armazenamento para adicionar uma coluna (abaixo, §8).

### 2.2 Geração de SQL — o contrato de ida e volta

`MADQueryFull` constrói o SQL executado a partir do modelo
(`SQLOnlyActiveFields:managedObjectContext:error:`, `MADQueryFull.m:143-273`):

* Parte `SELECT` vinda do driver, depois os campos ativos, ordenados por alias de coluna, escritos
  **sem `AS`**: `"Table0"."Field"` (`MADQuerySelectExpressionActiveFields.m:32-38, 46-53`).
* `FROM` — uma DFS sobre o grafo de junções: `tableName <connector> queryAlias`, depois
  `LEFT OUTER JOIN tableName <connector> queryAlias ON l.field = r.field` por link
  (`MADQueryFull.m:275-426`, texto da junção de `RptqQueryLinks SqlForLinkType:`,
  `RptqQueryLinks+Extras.m:76-86`).
* `WHERE` — as triplas de predicados combinadas com AND (`MADQueryPredicate.m`).
* Sem `GROUP BY`/`ORDER BY` no SQL — agrupamento e ordenação são aplicados sobre o
  cache `.maddb` (`MADParameters+QueryCacheAggregate`, `MADQueryCacheSelectGroupKeys`).
* Uma cláusula `LIMIT` fornecida pelo driver.

O contrato do importador é, portanto: **uma instrução colada é aceitável exatamente quando
poderia ser a saída de `MADQueryFull` para algum modelo.** É isso que torna a ida e volta
honesta — o lado View do popover SQL mostra o SQL regenerado a partir do modelo importado,
e ele lê como o que o usuário colou.

### 2.3 O pipeline de atualização — o padrão que a validação reutiliza

`MADOperationRefresh.m:60-172`: conecta com credenciais fornecidas pelas dependências da operação,
constrói o SQL **na fila principal** (o contexto do armazenamento pertence à fila principal — BUGS.md), depois
`[database executeSQL:fieldKeys:onConnection:intoResultTable:withError:]`
(`MADDatabaseProtocol.h:33`) e `dataTableMakeCache`. Uma sondagem de validação é a mesma
forma de operação menos a construção do cache.

### 2.4 O backend que a interface já chama — a costura que o compilador reutiliza

Gravar linhas `Rptq` e salvar é suficiente; a camada `MADModel*` espelha a mudança na
interface via notificações do armazenamento (`MADModel_Layer.md` §3.3). As fábricas a chamar, verbatim do
código de interface de hoje:

* **Adicionar tabela** — `[RptqQueryTable newQueryTableForSchemaTable:database:forManagedObjectContext:]`
  depois um `[RptqQueryField newQueryField:context]` por campo de esquema, vinculado à tabela,
  tabela adicionada a `query.hasQueryTables`, salvar (`MADQueryViewController.m:744-799`).
* **Adicionar link** — `[RptqQueryLinks newQueryLinksWithLeftField:rightField:joinType:managedObjectContext:]`
  depois `[document.activeDocumentModel addQueryLink:link]`, salvar
  (`MADQueryLinkBuilderController.m:112-122`).
* **Adicionar predicado** — `[RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID:…]` /
  variantes `…WithLeftValue:…` (`MADQueryAddPredicateController.m:142-162`,
  `RptqQueryPredicate+Extras.h:20-39`).
* **Adicionar agrupamento** — `[document addQueryGroupWithQueryField:andSortOrder:]`
  (`MADocument.m:728-792`). Esta única chamada cria a linha de agrupamento *e* as seções de cabeçalho/rodapé
  de agrupamento do relatório *e* seus gerenciadores de layout de seção — "configura completamente o
  documento" para um `GROUP BY`, de graça.
* **Exclusão, para o caminho de substituição** — `removeGroupWitObjectID:fromManagedObjectContext:`
  (`MADocument.m:1130`), `deleteDatafieldsRelatedToTable:inContent:` e
  `deleteAggregateFieldRelatedToTable:inContent:` (`MADocument.h:91-95`), e os caminhos existentes
  de remoção de link/predicado na interface de consulta. A Fase B inventaria estes; qualquer auxiliar simétrico
  ausente para links/predicados é adicionado ali.

### 2.5 A costura da interface

O controlador de visão dividida do construtor de consultas já tem um item de barra de ferramentas `barButtonItemSQL` que
apresenta um popover **somente leitura** `MADViewControllerSQL` (`MADQueryBuilderSplitViewController.m:31,
106-111`; `MADQuery.storyboard`; `MADViewControllerSQL.m:27-56` mostra
`[doc.mainQuery SQLOnlyActiveFields:…]`). O recurso é um modo desta mesma tela, então o
botão, o popover e a navegação já existem.

## 3. O recurso, como o usuário o vê

1. Na aba de consulta, toque no botão SQL existente. O popover agora tem modos **View / Edit**.
2. **View** mostra ambas as representações do SQL da consulta, como um controle segmentado:
   * **Generated** — o SQL que `MADQueryFull` constrói a partir do modelo agora (o conteúdo de hoje
     do popover, mantido como a aba padrão).
   * **As entered** — a última instrução aplicada pelo usuário, verbatim
     (`RptqQuery.sqlSourceText`, §8); oculta ou vazia quando a consulta nunca foi construída
     a partir de SQL colado.
   Ambas as abas são somente leitura — a tela "veja o que você colou, e veja no que se tornou".
3. **Edit** — uma visão de texto multilinha monoespaçada, semeada a partir de `sqlSourceText` quando presente
   (o usuário re-edita *seu* texto, formatação e comentários intactos) e a partir do SQL gerado
   caso contrário; um botão **Revert to generated** re-semeia a partir da forma gerada.
4. **Validate** — verificação estrutural mais, quando o banco de dados do documento pode ser alcançado, uma
   sondagem de servidor com zero linhas (§7). Os erros retornam com linha e coluna.
5. **Apply** — a instrução é compilada no documento (atômica — §6.5) e o texto colado exato
   é persistido como `sqlSourceText` (§8). O popover fecha; a lista de tabelas da consulta,
   a tela de visualização e o designer de relatórios todos mostram a estrutura importada.
   Os seletores de campo do designer funcionam como de costume.
6. Uma aplicação falha ou conflitante não persiste nada — nem o texto, nem qualquer linha. A consulta anterior
   e seu texto anterior permanecem exatamente como estavam.
7. O usuário pode voltar a qualquer momento: o designer visual continua trabalhando na consulta
   importada, View mostra ambas as formas, e Edit reabre as próprias palavras do usuário.

## 4. Arquitetura

```
pasted SQL
  → MADSQLTokenizer        dialect-aware lexer; quotes per driver; tracks line:column
  → MADSQLParser           recursive descent; produces a MADSQLStatement parse tree
  → MADSQLStatementResolver  binds names to RptqDatabaseSchemaTable / RptqDatabaseSchemaField
  → [MADOperationValidateSQL]  server probe, when connected (§7); never writes
  → MADSQLQueryCompiler    the write plan: deletes + creates Rptq rows via the §2.4 factories
  → store save → model notifications → query UI / visualization / designer update
```

**Posicionamento.** Tudo, exceto a operação de sondagem e a interface do editor, vive no framework
`MAD`, Foundation puro, sem UIKit — então ele executa na suíte de testes `MAD` e na imagem
Linux. Os novos arquivos entram em `Linux/cmake/MADSources.cmake` e `./Linux/build.sh` permanece verde.
A operação de sondagem (precisa de drivers, credenciais, alertas UIKit) e a interface do popover vivem em
`MADDesigner/Source`.

**Novos arquivos.** `MAD/Source/sql/MADSQLTokenizer.{h,m}`, `MADSQLParser.{h,m}`,
`MADSQLStatement.{h,m}` (a árvore e seus tipos de valor: `MADSQLColumnReference`,
`MADSQLPredicateTerm`, …), `MADSQLStatementResolver.{h,m}`, `MADSQLQueryCompiler.{h,m}`,
`MADSQLCompileError.{h,m}`. Aplicativo: `MADOperationValidateSQL.{h,m}` (espelhando
`MADOperationRefresh`), mais as mudanças de editor em `MADViewControllerSQL` ou um controlador de editor
irmão na mesma costura do storyboard.

**Uma pequena adição de API.** O lexer precisa da citação de identificadores de cada dialeto (crases do MySQL,
colchetes do T-SQL, aspas duplas) antes que uma conexão exista. Adicione
`+ (NSString *)identifierQuoteCharacters` a `MADDatabase` (padrão: aspas duplas), com
substituições por driver em `MADMySQL`/`MADTdsClient` (`MADPostgres` usa a aspa dupla
padrão) — ou, se preferido, um método de classe no protocolo do driver resolvido através do
`MADDatabaseDriverRegistry`. De qualquer forma, é uma adição de três métodos.

## 5. O subconjunto suportado

O importador aceita **exatamente a linguagem que o modelo pode conter** — um `SELECT`, sem
subconsultas em lugar algum, e cada cláusula dentro dos limites da §2.1:

* **Lista SELECT** — apenas referências de coluna: `col`, `tbl.col`, `schema.tbl.col`, `alias.col`,
  citadas ou nuas, mais `alias.*` / `schema.tbl.*`. A lista é *validada e usada para
  descoberta de tabela/coluna*, não armazenada (o modelo não tem lista SELECT — §2.1): toda coluna
  deve ser resolvida, e uma coluna qualificada nomeia uma tabela que deve aparecer em `FROM`. Expressões,
  agregados, aliases (`AS x`) e `DISTINCT` são rejeitados com um ponteiro para a Fase E (§9),
  que é a fase que torna real a lista de colunas colada sintetizando elementos do designer.
  O texto inserido em si *é* armazenado, verbatim, em `sqlSourceText` (§8) — a forma da validação
  e o texto de entrada são coisas separadas.
* **FROM** — uma referência de tabela `[schema.]name [AS alias]`, depois uma cadeia/árvore de
  `[INNER] JOIN`, `LEFT [OUTER] JOIN`, `RIGHT [OUTER] JOIN`, `FULL [OUTER] JOIN` cada um com
  exatamente uma equi-condição `l.col = r.col` (colunas nuas, de duas partes ou de três partes `schema.tbl.col`;
  nuas permitidas quando não ambíguas).
  * Os aliases devem ser o próprio nome da tabela de esquema (ou sua forma sem pontos), ou a forma
    de índice de descarte (`name0`, `name1`, `schema.name0`, ou `schemaname0` sem pontos correspondendo a
    `RptqQueryTable -queryAlias`) para uma segunda cópia da mesma tabela — o modelo calcula
    aliases por conta própria e não pode conter renomeações (`Customer AS c` é rejeitado: "o designer nomeia
    as tabelas por conta própria").
  * No máximo uma junção entre um dado par de tabelas (o gerador emite um `JOIN` por
    par de tabelas; dois links entre o mesmo par duplicariam o alias).
  * Sem junções por vírgula, sem junções `NATURAL`/`CROSS` (o modelo de link contém exatamente um par de campos
    e o gerador sempre escreve `ON …`), sem subconsultas em `FROM`/`ON`.
* **WHERE** — uma conjunção (AND) de comparações `left op right`, `op` ∈
  `{ =, <>, >, >=, <, <= }` (o conjunto `MADPredicateOperator`), cada lado uma referência de coluna
  ou um literal. Parênteses são aceitos apenas onde não mudam a forma plana de AND.
  Todo o resto — `OR`, `IN`, `BETWEEN`, `LIKE`, `NOT`, funções, subconsultas — é
  rejeitado: o modelo de predicados combina triplas planas com AND e nada mais.
* **GROUP BY** — referências de coluna, importadas em ordem (peso), cada uma tornando-se um agrupamento via
  o auxiliar `MADocument`, que também cria as seções de agrupamento do relatório.
* **ORDER BY** — aceito **somente quando toda coluna é uma coluna de GROUP BY**, e o
  asc/desc mapeia para as ordens de classificação dos agrupamentos. Caso contrário, rejeitado (sem ordenação livre no modelo).
* **LIMIT** — rejeitado: o aplicativo aplica seu próprio limite de modo designer/relatório
  (`MADDocument.limitResultsDesignMode`, `MADQueryFull.limitResults`).

Os literais são tratados por dialeto no momento da geração (`newSafeLiteral:`,
`MADDatabaseSQLProtocol.h`); o importador apenas registra a string de valor e o tipo de dados do campo,
exatamente como a interface de predicados faz (`MADQueryPredicate.m:74-88`).

As rejeições nunca são silenciosas: cada uma nomeia a construção, a cláusula, o motivo (qual
limitação do modelo ela atinge) e a linha:coluna.

## 6. Resolução e compilação

### 6.1 Resolvedor

* Alias (ou nome nu de tabela) → `RptqDatabaseSchemaTable` por nome, sem diferenciar maiúsculas de minúsculas.
  Desconhecido → erro "unknown table".
* Coluna → `RptqDatabaseSchemaField`: qualificada deve existir em sua tabela; nua deve ser única
  no conjunto `FROM`, caso contrário "ambiguous column".

### 6.2 O plano de escrita

A saída do resolvedor é um plano de objetos de valor: lista ordenada de tabelas, lista de junções (`MADLinkType` por
junção), lista de predicados (`MADPredicateOperator` + termos esquerdo/direito), lista de agrupamentos com ordens
de classificação. O plano é validado por inteiro antes que qualquer coisa seja escrita.

### 6.3 Verificação de conflitos — a aplicação é atômica

Aplicar **substitui** a consulta (o SQL colado *é* a consulta — esse é o recurso). Antes de
escrever, verifique toda tabela que o novo plano **não** inclui por referências de elementos do designer
— as três formas que `MADQueryActiveQueryFields` conhece
(`MADQueryActiveQueryFields.m:37-68`: referências de rótulo de dados, agregado, código de barras) mais quaisquer
seções de agrupamento que seriam excluídas. Se um campo de uma tabela descartada for referenciado, aborte
com um erro nomeando os elementos ("este campo é usado por … no designer"); nada é
excluído, nada é escrito, e a consulta antiga ainda executa. Este é o único caso em que a
importação não pode ser atômica e silenciosa, então ela falha ruidosamente.

### 6.4 Escrita

Em ordem inversa de dependência usando os auxiliares da §2.4: remover links e predicados, remover
agrupamentos (pelo caminho existente de remoção de agrupamentos, que desanexa suas seções e gerenciadores de layout),
remover tabelas que não estão no plano (pela família existente
`deleteDatafieldsRelatedToTable:`), depois criar tabelas → links → predicados → agrupamentos
através das mesmas fábricas que a interface chama. Um salvamento; o chamador então marca o documento como sujo
e faz salvamento automático, como faz o fluxo de adicionar tabela (`MADQueryViewController.m:796-799`).

### 6.5 Após a escrita

Sem intervenção na interface: o caminho de notificação do armazenamento atualiza a camada de modelo e ambas as telas de
consulta (`MADModel_Layer.md` §3.3). O compilador retorna um resumo (contagens de tabelas / links / predicados /
agrupamentos) para o popover.

## 7. Validação — dois níveis

**Estrutural (sempre, offline).** Analisar + resolver, §5–§6. Os erros são
`NSError`s do domínio `MADSQLCompileError` com um código, linha, coluna e mensagem. Este é o
recurso inteiro quando o banco de dados do documento está inacessível.

**Sondagem de servidor (quando uma conexão pode ser feita).** Envolva a instrução:

```sql
SELECT * FROM (<user sql>) AS _mad_probe WHERE 1=0
```

O alias de tabela derivada é obrigatório no MySQL e válido no T-SQL; `WHERE 1=0` dobra, então a
sondagem compila a consulta e retorna metadados de coluna sem ler linhas. Execute-a através
da forma `MADOperationRefresh` (`MADOperationRefresh.m:104-162`): conecte com credenciais
das dependências da operação, leituras do armazenamento marshaled para a fila principal, resultados via o
`executeSQL:…intoResultTable:…` do driver para que `MADDataColumn` forneça nomes e tipos. A sondagem
então captura o que a análise estática não consegue — resolução de nomes no servidor (sensibilidade a maiúsculas,
visões, palavras reservadas), diferenças de dialeto e os próprios erros de sintaxe do servidor, que são
expostos com a mensagem do servidor. Nomes/tipos de coluna são comparados com os campos de esquema resolvidos
e as divergências são relatadas como avisos, não falhas.

Offline, ou quando as credenciais não estiverem disponíveis, a sondagem é ignorada e a interface diz
"validado apenas por estrutura".

## 8. O texto de origem persistido — `RptqQuery.sqlSourceText`

O modelo compilado continua sendo a fonte da verdade para execução, mas **o texto colado pelo usuário
faz parte do documento**: um novo atributo de texto anulável `sqlSourceText` em `RptqQuery`
contém a última instrução aplicada com sucesso, verbatim. Excluir as palavras do usuário nunca foi
uma opção — o documento mantém tanto a entrada quanto sua compilação. O usuário escolheu uma única
propriedade em vez de um array de histórico (2026-10-22); um histórico de revisões pode ser adicionado depois como
um relacionamento ordenado de um para muitos e preenchido a partir do texto atual sem perda de dados.

Regras de persistência:

* Escrito somente por uma aplicação bem-sucedida, substituído por inteiro; uma aplicação falha ou conflitante
  não toca nem nas linhas do armazenamento nem neste texto (§3.6).
* A visão Edit o utiliza como semente quando presente; a aba View o mostra como **As entered** ao lado de
  **Generated** (§3.2-3.3).

### 8.1 A mudança no armazenamento

O atributo cai nos dois lados da verificação cruzada do esquema: o modelo compilado e os
descritores `MADStoreSchema` mantidos manualmente, mais a propriedade autogen de `RptqQuery`
(`MAD/Source/rptq/autogen/`). `MAD_FORMAT.md` ganha a coluna em sua lista de campos.

**Emendado (Fase A, 2026-10-22).** A mudança de modelo é uma **nova versão `MAD 4.xcdatamodel`**,
não uma edição de `MAD 3` no local: o hash de uma versão de modelo distribuída fixa os metadados do armazenamento
de todo documento em uso no mundo, e editá-la os orfana. `MAD 4` também descarta
o `elementID="type"` morto de `RptqDocumentElementBarcode.barcodeBorderType` (nenhuma versão anterior a `MAD 3`
tem uma entidade de código de barras; BUGS.md).

### 8.2 Versionamento do armazenamento — novo, pequeno e agora obrigatório

O armazenamento portátil não tem versionamento hoje (`MADStore.m` não carrega nenhum pragma `user_version`).
Esta fase adiciona o mecanismo, deliberadamente mínimo:

* `MADStoreSchema` ganha uma constante de versão e uma lista ordenada de passos de migração. Hoje
  essa lista tem uma entrada: versão 1 (o esquema em uso — `user_version` ausente ou 0)
  → versão 2 (`ALTER TABLE` adicionando `sqlSourceText`).
* Ao abrir, `MADStore` lê `PRAGMA user_version`, aplica os passos ausentes em uma
  transação e grava a nova versão. Armazenamentos novos são criados na versão atual
  (`createSchemaSQL` já gera o esquema inteiro).
* `MADLegacyStoreConversion` não é afetado no fluxo — documentos Core Data convertidos são
  criados na versão atual pelo mesmo caminho de abertura do `MADStore`.
* A engine headless Linux compila o mesmo código `MADStore`, então documentos existentes abrem
  identicamente na imagem; os testes de migração também executam ali.

**Emendado (Fase A, 2026-10-22).** `MADStoreConverter` agora abre cada armazenamento legado com
a versão momd correspondente aos seus metadados, nunca via migração automática: o Core Data não consegue
inferir um mapeamento para esta família de modelos (o conflito de `elementID` do código de barras, BUGS.md), e
o modelo atual do momd não é mais a versão contra a qual os armazenamentos em uso foram escritos.

### 8.3 Considerado e rejeitado: o plist de metadados do guts

O plist de metadados que acompanha o armazenamento no diretório guts poderia conter o texto
sem nenhuma mudança de esquema. Rejeitado: dados de consulta pertencem à parte de consulta do armazenamento
(`MADStorePartQuery` — o contrato do armazenamento é "três partes e nada mais",
`MADStoreSchema.h:12-13`), e a engine headless lê o armazenamento, não o plist.

### 8.4 O futuro que isto desbloqueia

O texto inserido armazenado é a superfície de entrada natural para o design de consultas conduzido por agente
no horizonte do produto (`MAD_FUTURE.md`): um agente — ou uma pessoa — escreve uma instrução, o
compilador abaixo a transforma no documento, e `sqlSourceText` mantém o prompt de registro.
A arquitetura estrita de modelo compilado é o que torna isso gradual: nada sobre o
compilador muda quando o escritor se torna um agente.

## 9. Fases

**Fase A — o texto de origem persistido: versionamento do armazenamento (somente MAD; Linux verde).**
1. `sqlSourceText` em `RptqQuery`: modelo compilado + descritores `MADStoreSchema` + propriedade
   autogen, em uma única mudança (o teste de verificação cruzada falha caso contrário).
2. O mecanismo de versionamento da §8.2 — constante de versão, lista de migração, leitura/aplicação/gravação
   de `user_version` ao abrir, armazenamentos novos na versão atual.
3. Testes: `MADStoreSchemaTests` permanece verde nos dois lados; novos testes de migração (§10.2);
   `MAD_FORMAT.md` atualizado.

Aceitação: um documento criado antes desta fase abre sem problemas, ganha a coluna, mantém seus
dados e faz ida e volta pelo Linux; um documento novo nasce na versão atual. Esta
fase é autocontida — ela chega antes, e independentemente, do analisador.

**Fase B — testes golden, depois o analisador (somente MAD; Linux verde).**
4. Testes SQL golden fixando a saída exata de `MADQueryFull` por dialeto (§10.1) — escritos
   primeiro, para que o analisador seja construído contra o gerador real.
5. `MADSQLTokenizer`/`MADSQLParser`/`MADSQLStatement` + a API de citação de identificadores (§4).
6. `MADSQLParserTests` — a matriz de aceitação/rejeição da §5, códigos de erro, linha:coluna.

Aceitação: toda construção suportada que `MADQueryFull` pode emitir é analisada; toda construção rejeitada
falha com um erro codificado e posicionado; suíte MAD e `./Linux/build.sh` verdes.

**Fase C — resolvedor + compilador (somente MAD; Linux verde).**
7. `MADSQLStatementResolver`, `MADSQLQueryCompiler` com aplicação atômica (§6) e a
   gravação de `sqlSourceText` em caso de sucesso (§8).
8. Inventário de auxiliares de exclusão; adicionar os auxiliares de remoção de link/predicado ausentes.
9. `MADSQLQueryCompilerTests` + o teste de ida e volta de ponto fixo (§10.4).

Aceitação: aplicar uma instrução produz exatamente as linhas Rptq que o designer visual teria
produzido, e armazena o texto verbatim; aplicar sobre uma consulta existente não deixa órfãos; o
caso de conflito aborta com o armazenamento — e o texto anterior — intocados; o teste de ponto fixo
passa.

**Fase D — o aplicativo (MADDesigner).**
10. O popover View/Edit da §3, a sondagem `MADOperationValidateSQL`, a visão de resumo.
11. Testes de interface (§10.6) usando um documento de exemplo (driver sqlite3 — sem servidor necessário).

Aceitação: colar → validar → aplicar mostra as tabelas/junções/predicados no designer de consultas
e na visualização, as seções de agrupamento no designer de relatórios, e a atualização executa a consulta; View
mostra tanto o SQL gerado quanto o texto inserido; fechar e reabrir o documento mantém
o texto inserido.

**Fase E — adiada, com suas próprias decisões.**
* Materialização da lista SELECT: sintetizar elementos do designer (rótulos de dados, agregados) para que
  a atualização retorne exatamente as colunas coladas. Até então, uma consulta importada se comporta como qualquer
  documento novo — o SELECT deriva de elementos, links e agrupamentos (§2.1).
* Um histórico de instruções aplicadas, se algum dia desejado: um relacionamento ordenado de um para muitos preenchido a partir do
  `sqlSourceText` atual (§8) — o companheiro natural do design de consultas conduzido por agente da
  §8.4.

## 10. Testes

### 10.1 Fixar a funcionalidade existente (escrito primeiro)

* **Testes SQL golden** em `MAD/MADTests` (estendendo `MADQueryFullTests.m`, que hoje
  verifica apenas fragmentos, `MADQueryFullTests.m:140-162`): fixtures de armazenamento fixos → strings SQL esperadas
  exatas, por dialeto de driver (configurações MySQL, TDS e PostgreSQL), cobrindo a nomenclatura de aliases
  e a forma de índice de descarte, todo tipo de junção, todo operador de predicado com citação de literal
  e a ordenação de campos ativos. Estes fixam o gerador com o qual o analisador deve fazer ida e volta, e
  também executam na imagem Linux.
* **O contrato de ida e volta** — veja o teste de ponto fixo abaixo; ele fixa gerador ∪ importador
  como um único sistema.

### 10.2 Testes de persistência e migração do armazenamento

* `MADStoreSchemaTests` — a verificação cruzada existente agora confirma que os descritores e o
  modelo compilado concordam sobre `sqlSourceText` (é o teste que força os dois lados da
  §8.1 a chegar juntos).
* Novo `MADStoreMigrationTests` (MAD): construir um armazenamento em disco na versão 1 (o esquema como
  é hoje, `user_version` ausente) com linhas nele → abrir com o novo `MADStore` → a
  coluna existe, `user_version` lê a versão atual, e toda linha e relacionamento pré-existentes
  sobrevivem; um armazenamento novo é criado na versão atual; abrir duas vezes é
  idempotente. Estes também executam na imagem Linux, já que a engine headless compartilha o
  código de migração.
* Asserções no nível do compilador (na §10.4): uma aplicação bem-sucedida armazena o texto **verbatim** —
  comentários, espaços em branco, caixa — e uma aplicação conflitante deixa o texto anterior intacto.

### 10.3 Testes do analisador — `MADSQLParserTests` (MAD)

* Lexer: identificadores citados por dialeto, literais de string com aspas escapadas, comentários
  (`--`, `/* */`), números, operadores, palavras-chave sem diferenciar maiúsculas de minúsculas; posições nos erros.
* Analisador: a matriz completa de aceitação da §5 (tabela única, cada tipo de junção, cadeias de junções, aliases
  incluindo índice de descarte, colunas nuas e qualificadas, conjunções WHERE, GROUP BY,
  ORDER BY ⊆ GROUP BY) e a tabela de rejeição (OR, IN, LIKE, subconsulta, UNION, DISTINCT,
  expressões em SELECT, ON com múltiplas condições, renomeações de alias, junções por vírgula, NATURAL/CROSS,
  LIMIT, tabela/coluna desconhecida, coluna ambígua, ORDER BY fora de GROUP BY) — cada uma verificando
  o **código** de erro e a linha:coluna, nunca apenas a mensagem.

### 10.4 Testes do compilador — `MADSQLQueryCompilerTests` (MAD)

Armazenamento em memória com um fixture de esquema (o padrão que `MADModelQueryTableTests` usa):

* Caminho feliz: aplicar → verificar as linhas Rptq resultantes — tabelas com referências de esquema corretas e
  linhas por campo, links com `MADLinkType` e campos esquerdo/direito corretos, predicados com
  `comparson` e strings de valor corretos, agrupamentos com ordenação/peso **e** as seções de cabeçalho/rodapé
  de agrupamento criadas e gerenciadores de layout; salvo uma vez; `sqlSourceText` é igual à instrução de entrada
  exatamente (comentários e espaços em branco incluídos).
* Caminho de substituição: aplicar sobre uma consulta populada → tabelas/links/predicados/agrupamentos antigos removidos, sem
  linhas órfãs (contagem por entidade), nova estrutura presente, e `sqlSourceText` substituído.
* Caminho de conflito: elemento do designer referenciando o campo de uma tabela descartada → erro, e um
  snapshot de antes/depois mostra o armazenamento inalterado — incluindo o `sqlSourceText` anterior.
* **Ida e volta de ponto fixo**: construir um modelo através das fábricas → gerar SQL via
  `MADQueryFull` → analisar → compilar em um armazenamento novo → gerar SQL novamente → as duas strings
  SQL são iguais. Este é o teste que *define* "o software reconhece o que foi
  colado."

### 10.5 Testes de validação

* Construção do SQL de sondagem por driver (unitário, no alvo de teste do aplicativo): o wrapper, o
  alias, a dobra `WHERE 1=0` — com um banco de dados falso, sem servidor.
* **Testes ativos** no estilo de `MADMySQLLiveTests.m` (ignorar quando não há servidor): SQL colado válido
  sonda limpo com os nomes/tipos de coluna esperados; uma coluna ruim retorna o erro do servidor;
  zero linhas são lidas.

### 10.6 Testes de interface — `MADDesignerUITests`

Com um `.mad` de exemplo (driver sqlite3): abrir o popover SQL, alternar para Edit, colar uma
junção de duas tabelas com um filtro e um agrupamento, Apply, e então verificar que a lista de tabelas da consulta mostra
ambas as tabelas, a tela de visualização mostra duas caixas e um conector, o designer mostra
as seções de agrupamento, e o modo View mostra o SQL regenerado. Depois feche e reabra o
documento: a aba **As entered** ainda mostra o texto colado exato, e a aba **Generated**
ainda mostra o SQL da consulta compilada — o documento manteve ambos.

### 10.7 Restrições de design para teste (vinculantes para implementadores)

* Analisador/resolvedor/compilador: Foundation puro, sem UIKit, sem importações do aplicativo — as suítes MAD e a
  imagem Linux os compilam.
* Toda falha pública é um `NSError` codificado (`MADSQLCompileError`); os testes verificam os códigos.
* A sondagem fica atrás de um pequeno protocolo para que os testes unitários simulem o banco de dados; a cobertura ativa
  vive apenas nas suítes ativas (o padrão existente).
* O compilador recebe o documento/contexto, nunca um controlador de visão; o aplicativo não passa nada
  em forma de interface.
* Novos arquivos MAD são adicionados a `Linux/cmake/MADSources.cmake`; `./Linux/build.sh` permanece verde.
* O mecanismo de migração vive em código `MADStore` compartilhado com uma constante de versão que os testes podem
  referenciar — nunca em caminhos exclusivos da Apple — para que as suítes Linux o exercitem.

## 11. Decisões — resolvidas com o usuário (2026-10-22)

1. **Subconjunto estrito.** Confirmado: qualquer coisa que o modelo não possa conter é rejeitada com um motivo
   (§5). Sem recurso de SQL opaco.
2. **Aplicar substitui a consulta** (atômica, §6.3). Confirmado.
3. **A importação de GROUP BY cria as seções de agrupamento do relatório** automaticamente — o auxiliar
   `MADocument` existente faz isso, e permanece exatamente como está. Confirmado.
4. **A lista SELECT é validada, não armazenada, até a Fase E** — até que a síntese de elementos
   exista, uma consulta importada retorna colunas de junção/agrupamento na atualização até que o usuário adicione
   elementos, exatamente como qualquer documento novo. Confirmado como faseado.
5. **O texto colado é persistido.** Confirmado — `sqlSourceText` em `RptqQuery`, uma única
   propriedade contendo a última instrução aplicada com sucesso (§8), mostrada como **As entered**
   ao lado de **Generated**. A forma gerada continua sendo o que a atualização executa; nada sobre
   o texto ser armazenado muda a execução. Um array de histórico foi considerado e deixado de lado
   (§8, Fase E).
