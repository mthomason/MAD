---
layout: default
title: "Relatórios multifonte"
description: "Relatórios como tabelas, e drivers para qualquer coisa que retorne uma tabela."
lang: pt-BR
---

# Relatórios Multifonte — relatórios como tabelas, e drivers para qualquer coisa

Esta página descreve relatórios componíveis: o resultado de um relatório se torna uma tabela que outro relatório pode consultar, e um driver pode ficar à frente de qualquer coisa que retorne linhas. É um registro de design; a §8 nomeia as fases, e não todas estão construídas.

**Escopo:** a arquitetura que o usuário descreveu em 2026-11-22: um usuário projeta um relatório
contra uma fonte de dados (MySQL, SQL Server, PostgreSQL, SQLite ou uma API Web como a API Seller
do eBay); o resultado desse relatório é uma tabela SQLite materializada; e outro relatório pode
projetar uma consulta contra esse relatório — unindo a saída de um relatório à saída
de outro relatório, e a fontes base, em um único grafo de consulta. Na atualização, a engine percorre o grafo
de baixo para cima, executa cada folha contra sua própria fonte, materializa cada resultado e, por fim,
executa a consulta compositora sobre as materializações. A costura de driver não SQL faz parte
disto: um driver que fica à frente de uma API recebe uma consulta estruturada, não texto SQL, e retorna
linhas em forma de tabela.
**Data:** 2026-11-22, lido em `eba4225a1`; decisões incorporadas em 2026-11-22 (§9.2).
**Status:** relatório de design. Ele declara a ideia e o design; não implementa
nada e não adiciona trabalho a `TASKS.md`. A auditoria de código que fundamenta a
metade do objeto de dados é [`MAD_DATA_OBJECT.md`](data-object.md); a direção é
[`docs/vision.md`](../vision.md). Este documento adiciona o modelo de composição multifonte
(sub-relatórios dentro do documento primeiro), a API de driver que torna as fontes não SQL de primeira classe
e uma ordem de fases combinada.

---

> **Modelo normativo:** o contrato de execução que esta página motiva está agora declarado de
> forma normativa e em um só lugar em
> [`MAD_COMPOSITION_SPEC.md`](../../project/design/MAD_COMPOSITION_SPEC.html). Onde esta página
> (ou `data-object.md`) divergir dele, a especificação prevalece. A §0 da especificação é
> **final**: cada nó de uma composição é um relatório completo com seu próprio layout e dados,
> e a raiz é o relatório padrão do documento, não o único visível. A frase da §3.2 passo 5 que
> menciona apenas a raiz fica substituída.

## 1. A ideia, em uma página

Um relatório é uma função de fontes de dados para uma tabela. A distinção conta-vs-pedido que
importa para este design já está no código:

- A **definição** é o grafo de consulta — tabelas, campos, links, predicados, agrupamentos —
  mais o layout em faixas. Ela vive no arquivo `.mad`.
- O **resultado** é um esquema (`MADDataColumn`s) e linhas. Ele vive ao lado do documento em um
  cache SQLite complementar (`.maddb` + `.mdcache`), fora do arquivo, porque é
  derivado e regenerável.

A extensão é tornar o resultado **endereçável como uma tabela**. A saída de um relatório então
se torna uma fonte para outro relatório, exatamente como uma tabela de esquema é uma fonte hoje. Um relatório
construído sobre relatórios é um DAG de tabelas derivadas: uma camada semântica portátil onde projetar um
relatório também é projetar uma fonte de dados reutilizável.

A mesma extensão torna os relatórios multifonte naturais. Cada objeto de origem executa contra
seu próprio banco de dados ou API, com seu próprio driver e credenciais, e materializa em sua própria
tabela SQLite. O objeto compositor executa contra o **cache local**, não contra um servidor
remoto, unindo as materializações. Nenhuma engine de federação é adicionada; os snapshots são a
federação.

O exemplo do usuário: uma empresa quer um relatório de seus anúncios no eBay. Um objeto de relatório
consulta a API Seller do eBay e materializa os anúncios; outro consulta o banco de dados MySQL da empresa
em busca de vendas; um relatório compositor une as duas saídas por SKU. Cada driver só
conhece sua própria fonte. A junção acontece no SQLite, localmente.

O driver não SQL é o que torna o primeiro objeto possível. Seu contrato é o mesmo
contrato "esquema mais linhas" satisfeito pelos drivers SQL — mas sua entrada deve ser o grafo de
consulta, não uma string SQL que ele tenha de analisar.

## 2. O que já é verdade no código

As partes caras existem. A §3 de `MAD_DATA_OBJECT.md` é a auditoria detalhada; os fatos
estruturais para este relatório são:

1. **A definição é um grafo, e o armazenamento permite muitos.** `RptqQuery` possui tabelas,
   campos, links, predicados e agrupamentos. `MADModelDocument` constrói um `MADModelDatabase`
   por `RptqQuery`, com a própria nota do código de que as versões atuais usam um. A cardinalidade
   é uma convenção dos fluxos do aplicativo, não do armazenamento (`MAD_DATA_OBJECT.md` §3.1).
2. **O compilador existe e é determinístico.** `MADQueryFull -copySQLWithManagedObjectContext:error:`
   (`MAD/Source/MADQueryFull.m:133-273`) constrói a lista SELECT, a árvore FROM/JOIN a partir de um
   grafo ordenado topologicamente, a cláusula WHERE e o limite, através dos ganchos de dialeto
   do driver.
3. **A costura de execução já tem forma de tabela.** O ponto abstrato de `MADDatabase` é
   `executeSQL:fieldKeys:onConnection:intoResultTable:withError:`
   (`MADAPI/Source/MADDatabaseProtocol.h:33-34`), e o destino é qualquer
   `id <MADDataTableWriting>`, não uma classe concreta de tabela. Todos os quatro drivers o preenchem da mesma
   maneira: remover todos os objetos, adicionar colunas, inserção em lote, adicionar linhas.
4. **A materialização é uma tabela SQLite real.** `MADDataTableFast` grava
   `<tag>.maddb` e a tabela `t<tag>` (`MADSqlite3/Source/MADDataTableFast.m:403-406`,
   `:463-467`, `:503-511`). O plist de esquema é `.mdcache`; linhas e esquema são separáveis
   (`docs/05-companion-files.md` §5). O SQLite já é um driver
   (`MADSqlite3/Source/MADDatabaseSqlite3.m`), então uma consulta cujo "banco de dados" é o cache é
   código de hoje, não código novo.
5. **O cache é descartável e por dispositivo.** Ele não está no documento nem no iCloud
   (`docs/05-companion-files.md` §5.2). Isso é correto para um artefato derivado, mas é uma
   restrição para qualquer design que trate o cache de outro relatório como fonte: o cache pode
   não estar lá.

A mesma seção nomeia os três pontos de fixação de consulta única, e eles ainda são verdadeiros
hoje:

- `MADQueryFull` relê o primeiro banco de dados e a primeira consulta do documento em vez de usar
  a consulta com a qual foi inicializado (`MAD/Source/MADQueryFull.m:147-149`).
- `MADocument -dataTableForQuery:` é um switch de um único slot: ele retorna a única tabela do documento
  para `MADQueryFull` e nil para todo o resto (`MAD/Source/MADocument.m:873-880`).
- `MADQueryActiveQueryFields` varre todo elemento, link e agrupamento no armazenamento sem nenhum
  escopo de consulta (`MAD/Source/MADQueryActiveQueryFields.m:27-100`). Os campos de uma segunda consulta
  vazariam para a lista SELECT da primeira.

Mais dois fatos importam para o design de composição:

- **O endereço é o hash do nome do arquivo.** O documento cria sua tabela com
  `initWithId: self.fileURL.lastPathComponent.hash` (`MAD/Source/MADocument.m:273-275`), e
  o diretório de cache é nomeado por esse hash. Nada pode apontar para a tabela por uma identidade
  estável.
- **Um `MADDataTableFast` é um arquivo.** `filenameCacheMadDB` é `<tag>.maddb`
  (`MADSqlite3/Source/MADDataTableFast.m:403-406`), e cada instância abre suas próprias conexões de inserção
  e de seleção (`:482-501`). Não há hoje um modo "várias tabelas em um `.maddb`".
  A §5.1 de `MAD_DATA_OBJECT.md` descreve esse modo como uma variante de design; a classe atual
  não o implementa.
- **Não há suporte a `ATTACH`.** Uma busca em `MADSqlite3`, `MAD` e `CLI` não encontra nenhum
  uso de `ATTACH DATABASE`. A composição entre arquivos precisa que ele seja adicionado, ou de um passo de cópia para dentro.

## 3. O modelo de composição

### 3.1 Nós e arestas

- Um **objeto de origem** possui um `RptqDatabase` (driver + conexão + credenciais) e uma
  definição de consulta. Ele é executado contra sua fonte.
- Um **objeto compositor** possui uma consulta cujas tabelas são outros objetos de dados (de origem ou
  compositores). Ele é executado contra o cache local. Um objeto compositor não possui uma
  fonte remota neste design: uma tabela remota de que ele precisa é um **objeto de origem** cuja saída
  ele referencia. Isso mantém a taxonomia de nós em dois tipos — folhas remotas e compositores
  locais — e mantém a caminhada de atualização honesta.
- Uma **aresta** é uma referência de tabela em uma consulta compositora ao esquema de saída de outro objeto.
- O grafo deve ser acíclico. Um ciclo é um erro de tempo de design, relatado na referência
  ofensora, não um estouro de pilha na atualização.

### 3.2 A atualização é topológica

1. Percorra o DAG de baixo para cima. O compilador existente já ordena topologicamente o grafo de junções
   (`MAD/Source/MADQueryFull.m:170-204`); o grafo de objetos precisa da mesma disciplina no
   nível de objeto.
2. Execute cada folha contra sua própria fonte, através de seu próprio driver, em sua própria
   materialização.
3. Anexe ou abra as materializações necessárias ao objeto compositor.
4. Execute a consulta compositora contra o banco de dados SQLite local e materialize seu resultado.
5. Repita subindo o grafo. A raiz é um relatório comum; seu cache é o que o visualizador lê.

A paginação não muda. A engine ainda puxa o resultado completo para o cache local; a interface
pagina sobre o cache. Para um driver de API, "paginação" é um **laço interno** sobre as páginas
da API para preencher sua materialização; não é um contrato de streaming ou de paginação com a
engine. O `limit`/`offset` do plano existem para pré-visualizações do modo designer e para um driver que
queira limitar sua busca, não para a paginação do visualizador.

Agrupamento, ordenação e agregados não mudam: eles são calculados sobre o cache local
(`MAD_DATA_OBJECT.md` §3.5). O driver retorna linhas de detalhe; ele não precisa implementar
`GROUP BY` ou o agrupamento do relatório. Uma dica de ordenação no plano permite que um driver empurre uma
solicitação top-N quando um limite está presente; a engine ainda reordena.

### 3.3 Dois layouts de materialização

O instinto do usuário era `ATTACH`, e o código atual o torna o caminho mais curto.

**Layout A — um `.maddb` por objeto de origem, `ATTACH` para unir.**
- O `MADDataTableFast` de cada objeto mantém seu próprio `<tag>.maddb` e `t<tag>`.
- A consulta compositora abre uma conexão com o cache local (ou um banco de dados em memória) e
  executa `ATTACH DATABASE '<path>' AS <alias>` para cada objeto de origem de que precisa.
- A geração de SQL qualifica a tabela como `<alias>.t<tag>`.
- Novo trabalho: suporte a `ATTACH` em `MADDatabaseSqlite3`, gerenciamento de aliases e citação de caminhos.
  A classe já é um wrapper SQLite completo, então esta é uma pequena adição.
- Limites: o `SQLITE_MAX_ATTACHED` do SQLite tem padrão 10, e nenhuma receita de compilação no
  repositório o aumenta (`Compressor/sqlite3.xcconfig`, `Linux/`, `Windows/Engine/`). Aumentá-lo
  é uma mudança de compilação em três plataformas. A v1 trata mais de dez fontes diretas como
  erro de tempo de design.
- O próprio objeto compositor materializa em seu próprio `.maddb`, como qualquer outro resultado.

**Layout B — várias tabelas em um `.maddb`.**
- Um arquivo de cache por documento, várias tabelas `t<tag>`, sem `ATTACH`.
- Isto exige mudar `MADDataTableFast` de "uma instância possui um arquivo" para um modelo de
  arquivo/conexão compartilhado, ou adicionar um registro de tabelas acima dele. É uma mudança maior que
  `ATTACH`, e vai contra o design atual de um arquivo por tabela da classe.
- Sua vantagem é um único arquivo e nenhum limite de anexação.

**Recomendação:** Layout A para a primeira implementação de composição, porque segue
a fronteira atual da classe e corresponde ao modelo do usuário. O Layout B continua sendo a história de arquivo
mais limpa a longo prazo se o modelo de arquivo por tabela for algum dia revisitado.

### 3.4 O que uma referência significa

A referência de tabela de uma consulta compositora precisa de um segundo tipo ao lado de `databaseSchemaTable`
(o `RptqQueryTable.databaseSchemaTable` de hoje, `MAD/Source/rptq/autogen/RptqQueryTable.h:27`).
A decisão do usuário (2026-11-22) é que a composição é **dentro do documento primeiro**: um documento `.mad`
contém várias definições de relatório/consulta — **sub-relatórios** — e o relatório compositor
referencia uma por sua identidade. A propriedade de um único arquivo portátil é preservada, e o
problema de reautorização entre arquivos do iOS não surge na v1. Uma referência a um **relatório em
outro arquivo `.mad`** (uma identidade de documento mais um caminho) é uma preocupação posterior e separada,
adiada atrás da composição no mesmo documento.

O cache é por dispositivo e descartável, então a referência registra *o que executar*, não *onde
os dados estão*:

- **Referência ativa (padrão).** O pai armazena a referência da definição do filho e, na
  atualização, executa o filho e materializa seu resultado.
- **Snapshot fixado.** O pai retém a materialização do filho no cache complementar
  (`.maddb`/`.mdcache`) e a reutiliza em vez de reexecutar o filho. Um pin é um artefato de cache retido,
  **nunca dados embutidos no `.mad`** — o arquivo permanece somente de definição
  (§6). Ativo e fixado ambos leem do diretório de cache; "fixar" significa "manter e reutilizar
  esta materialização", não "copiar os dados para o documento".

A nomenclatura da materialização passa do hash do nome do arquivo para uma identidade estável do objeto, para que os arquivos
não possam colidir e um pai possa endereçar um filho específico (§3.6, §6).

### 3.4.1 Como o pai nomeia as colunas de um filho

`RptqQueryField` tem exatamente uma referência de campo, `databaseSchemaField`
(`MAD/Source/rptq/autogen/RptqQueryField.h:27`), e o construtor de seleção, o construtor de junções,
os predicados e a interface de junção todos leem `queryField.databaseSchemaField.name`. As colunas de saída de um filho
são `MADDataColumn`s, não campos de esquema. A recomendação é **sintetizar uma
tabela e um conjunto de campos de esquema de resultado por objeto** a partir dos `MADDataColumn`s do filho: os
campos de consulta do pai então apontam para linhas comuns de campo de esquema, e todo construtor e interface
existentes funcionam sem mudança. As linhas sintéticas são um snapshot do esquema de resultado do filho e
são atualizadas quando o esquema do filho muda. A alternativa — um segundo tipo de referência de campo
em `RptqQueryField` — toca em todo construtor e não é recomendada. **Decisão do construtor.**

### 3.5 Falha, obsolescência e coordenação

- Se um filho falhar, a atualização do pai falha com o erro do filho e o nome do nó. O
  cache anterior do pai não é substituído por um resultado pela metade.
- Um arquivo de filho ausente, um arquivo movido, um esquema alterado ou uma credencial ausente é um
  erro de tempo de atualização que a interface pode explicar, não um resultado vazio silencioso.
- Ciclos, autorreferências e um filho que também é ancestral são rejeitados antes
  da execução.
- Referências entre documentos (adiadas além da v1) passarão, quando chegarem, pela coordenação
  de arquivos e URLs com escopo de segurança no iOS; o iCloud pode despejar o filho. A CLI e
  o macOS usam caminhos explícitos. O design precisa de uma política de resolução de caminhos nas três.
- O progresso da atualização deve ser por nó. Uma busca longa de API em um filho deve ser visível como o
  progresso desse filho, não como uma parada inexplicada.
- O cancelamento deve alcançar o driver em execução. O método de execução atual é síncrono
  e não tem token de cancelamento; um objeto de opções de execução do plano é o lugar natural para
  um.

### 3.6 O que o pai armazena

No tempo de design, o pai precisa do **esquema de resultado** do filho — nomes de coluna, tipos,
comprimentos — para desenhar a interface de junção e validar referências de campo. Ele não deve precisar das
linhas do filho, e não deve precisar da conexão de origem do filho. O esquema é a mesma
descrição `MADDataColumn` que o cache já serializa. Esta é a metade "descrever sem
executar" do contrato do objeto de dados; é um pré-requisito para a composição, não uma
comodidade opcional.

A decisão do usuário (2026-11-22) é que **o esquema de resultado são os campos ativos** — as
colunas que os elementos, junções e agrupamentos do relatório referenciam — exatamente a lista SELECT
que `MADQueryActiveQueryFields` já calcula (`MAD/Source/MADQueryActiveQueryFields.m:27-100`).
Sem mudança de comportamento: descrever retorna essa lista como `MADDataColumn`s sem executar. A
forma de todas as colunas continua sendo uma preocupação de pré-visualização de tabela, não um esquema de objeto de dados. Os nomes
públicos das colunas devem ser legíveis por humanos: `MADDataColumn.caption` já existe para o nome de exibição,
e o construtor da lista SELECT deve defini-lo a partir do nome de exibição do campo de esquema quando um
existir, em vez de expor apenas o alias interno `"Table0"."Field"`.

Mais uma peça de identidade está faltando: a **raiz**. `RptqDocument -mainQuery` e
`RptqDatabase -defaultQuery` são ambos `hasQueries.anyObject`
(`MAD/Source/rptq/RptqDocument+Extras.m:184-186`,
`MAD/Source/rptq/RptqDatabase+Extras.m:88`), e `MADocument -database` pega
`hasDatabaseSchemas.anyObject` (`MAD/Source/MADocument.m:1248-1258`). Com vários objetos de dados
em um documento, a consulta que o visualizador e o designer renderizam é não determinística. Adicione
uma referência explícita de raiz (ou uma flag) ao documento, migrando a única consulta de hoje para
ela. **Decisão do construtor.**

## 4. A costura do driver para fontes não SQL

### 4.1 Por que o texto SQL é a fronteira errada

Hoje a atualização do relatório compila o grafo em SQL e chama
`executeSQL:fieldKeys:onConnection:intoResultTable:withError:`
(`MAD/Source/MADOperationRefresh.m:134`). Isso é correto para um dialeto SQL. Para uma API REST,
força o driver a analisar SQL de volta em um grafo, e o subconjunto do analisador não corresponde
ao SQL gerado em pelo menos dois lugares: o gerador anexa uma cláusula `LIMIT`
(`MADQueryFull.m:164`) que `MADSQLParser` rejeita (`MAD/Source/sql/MADSQLParser.m:151-154`),
e o designer pode gerar junções `NATURAL`/`CROSS`
(`RptqQueryLinks+Extras.m:76-86`, `MADQueryLinkType.h:15-16`) que o analisador também rejeita
(`MADSQLParser.m:330-338`). Reutilizar o analisador também inverteria o empilhamento: ele vive em
`MAD`, acima dos drivers, e no Linux `mad` vincula os drivers como arquivo inteiro
(`Linux/CMakeLists.txt:469-474`).

Passar `MADQuery`/`MADQueryFull` diretamente também não é a resposta: `MADQueryFull` é
ligado ao armazenamento, em `MAD`, e calcula a lista de campos ativos apenas ao construir SQL. Um
driver compilaria contra o armazenamento do documento.

### 4.2 O plano

Adicione um objeto de valor neutro em relação ao driver em `MADAPI`:

```objc
@interface MADQueryPlanTable : NSObject
@property (copy) NSString *name;                        // schema table or object name
@property (copy) NSString *alias;                       // query alias
@property (copy, nullable) NSString *sourceIdentifier;  // nil = schema table
@end

@interface MADQueryPlanField : NSObject
@property (strong) MADQueryPlanTable *table;
@property (copy) NSString *field;
@property (copy) NSString *outputKey; // exactly what the driver names the column
@end

@interface MADQueryPlanLink : NSObject
@property (assign) MADLinkType type;              // moved down to MADAPI
@property (strong) MADQueryPlanTable *leftTable, *rightTable;
@property (copy) NSString *leftField, *rightField;
@end

@interface MADQueryPlanPredicate : NSObject
@property (assign) MADPredicateOperator op;        // moved down to MADAPI
@property (strong) MADQueryPlanOperand *left, *right; // field reference or literal
@end

@interface MADQueryPlan : NSObject
@property (copy) NSArray<MADQueryPlanTable *> *tables;
@property (copy) NSArray<MADQueryPlanField *> *fields;   // the active SELECT list
@property (copy) NSArray<MADQueryPlanLink *> *links;
@property (copy) NSArray<MADQueryPlanPredicate *> *predicates;
@property (copy) NSArray<MADQueryPlanSort *> *sort;      // pushdown hint
@property (assign) NSUInteger limit;
@property (assign) NSUInteger offset;
@end
```

`MADLinkType`, `MADPredicateOperator` e `MADSortOrder` estão atualmente em `MAD`
(`MAD/Source/MADQueryLinkType.h`, `MADPredicateOperator.h`, `MADSortOrder.h`). Um plano em
`MADAPI` não pode referenciá-los até que eles desçam (ou o plano define seus próprios enums,
o que duplica o modelo). Mover os três enums puros é a correção certa.

A execução se torna um método opcional no protocolo existente:

```objc
@protocol MADDatabaseDataSource <NSObject>
// existing required methods stay ...
@optional
- (BOOL)executeQueryPlan:(MADQueryPlan *)plan
                 options:(MADDatabaseExecutionOptions *)options
          intoResultTable:(id <MADDataTableWriting>)table
                withError:(NSError **)error;
@end

@interface MADDatabaseExecutionOptions : NSObject
@property (copy) BOOL (^isCancelled)(void);
@property (copy) void (^progress)(double fraction, NSString *node);
@property (strong) id credentials;                  // driver-specific, or a resolver
@property (copy) NSArray<MADMaterializationReference *> *attachments; // SQLite composer
@end
```

O plano permanece **lógico**; as opções carregam o contexto de execução. Um driver SQLite compositor
resolve o `sourceIdentifier` de cada tabela para uma anexação (caminho, tabela, alias)
fornecida em `options`. Isso mantém os caminhos de arquivo fora da superfície de driver de terceiros e dá
cancelamento e progresso por nó um lugar. **Decisão do construtor.**

`MADOperationRefresh` o prefere quando o driver o implementa, e recorre ao
caminho SQL existente caso contrário. Os quatro drivers distribuídos não precisam de mudança no primeiro dia. Uma
implementação de referência pode compilar o plano em SQL internamente e verificar que ele corresponde à
saída do compilador atual, o que fixa o plano contra a suíte existente.

### 4.3 Capacidades

A engine e a interface devem perguntar a um driver o que ele pode fazer em vez de codificar IDs de driver:

```objc
@interface MADDatabaseCapabilities : NSObject
@property (assign) MADLinkTypeMask supportedLinkTypes;
@property (assign) MADPredicateOperatorMask supportedOperators;
@property (assign) BOOL supportsLimitOffset;
@property (assign) BOOL supportsServerSideSort;
@property (assign) BOOL supportsNativeStatementText; // SQL editor
@property (assign) BOOL isReadOnly;
@property (assign) NSUInteger maximumPageSize;
@end
```

Isto substitui as listas de drivers e regras de junção codificadas em
`MADDesigner/Source/MADDriverSelectorController.m:64-90,124-140`,
`MAD/Source/rptq/RptqDatabaseCredentals+MADDatabaseConnection.m:19-33`,
`Mac/Source/MADMacConnectionWindowController.m:198-204,359-375`,
`CLI/Source/MADCLIServe.m:277-291` e
`MADDesigner/Source/MADQueryAddLinkJoinTypeController.m:46-95`. O registro já
enumera os drivers (`registeredDriverClasses`); a interface pode usá-lo mais
`driverName`/`imageIconName` em vez de um switch.

### 4.4 O que cada camada mantém

- **A navegação de esquema** permanece `getTables:` / `getTablesFromConnection:error:` e
  `fieldsForTable:connection:error:`. Um driver não SQL retorna valores `MADDatabaseTable` e
  `MADDatabaseField`; o usuário de relatórios os vê no designer de consultas exatamente como
  tabelas de esquema hoje.
- **O contrato de resultado** permanece `id <MADDataTableWriting>`; o driver adiciona
  `MADDataColumn`s e linhas com chave por `fieldKeys`/`outputKey`.
- **Agrupamento, ordenação, agregados** permanecem na engine sobre o cache. O driver retorna
  linhas de detalhe.
- **As junções** são uma capacidade: nativa, do lado do cliente ou sem suporte. A composição é o
  recurso alternativo. Um driver que não suporta junções ainda pode ser um objeto de origem; o usuário
  divide os recursos em objetos separados e os une no relatório compositor.
- **A entrada de texto SQL e a sondagem de validação** são condicionadas por capacidade. Um driver não SQL
  não precisa aceitar um SELECT colado.
- **O registro** pode permanecer na classe de conexão (`MADDatabaseDriver`) por compatibilidade.
  O contrato de longo prazo mais limpo coloca tipo, identificador, capacidades e construção de conexão
  na subclasse de `MADDatabase`; isso pode ser adicionado ao lado do protocolo atual
  sem quebrar os quatro drivers.

## 5. O driver genérico de API

O "um driver para toda uma classe de fontes de dados" do usuário é um driver cujo esquema vem
de um **manifesto de origem**, não do código. A engine vê um `MADDatabase` comum;
o manifesto diz ao driver quais tabelas, campos, endpoints e regras de paginação existem.

Forma mínima do manifesto:

```json
{
  "name": "eBay Seller",
  "baseURL": "https://api.ebay.com",
  "resources": {
    "listings": {
      "path": "/sell/inventory/v1/inventory_item",
      "rowsPath": "inventoryItems",
      "primaryKey": "sku",
      "pagination": { "limitParam": "limit", "offsetParam": "offset", "max": 100 },
      "fields": {
        "sku": "string",
        "listingId": "string",
        "product.title": "string",
        "price.value": "number"
      },
      "filters": { "sku": { "eq": "sku" } }
    }
  }
}
```

O driver mapeia o plano para requisições:

- `tables[0]` seleciona o recurso.
- `fields` se tornam uma lista de seleção ou são ignorados se a API retorna objetos inteiros.
- `predicates` se tornam parâmetros de consulta quando o manifesto nomeia um mapeamento; caso contrário, o
  driver filtra localmente.
- `limit`/`offset` conduzem o laço de páginas. Sem limite, o driver pagina até esgotar.
- `links` são nativos se a API os suportar, do lado do cliente se o driver implementar uma junção
  hash, ou sem suporte (a capacidade desativa o link na interface).
- Os valores JSON mapeiam para `MADDataType` através dos tipos de campo do manifesto.

Em termos de conexão, a linha de credencial de hoje cobre os drivers SQL (`host`, `username`,
`password`, `database`). Para um driver de API que precisa de um segredo de cliente, um token de atualização, um
ID de marketplace ou uma flag de sandbox, a decisão do usuário (2026-11-22) é um único **campo de opções
extensível** na credencial: uma coluna de texto contendo JSON (ou XML), versionada no
formato do armazenamento, analisada pelo driver — em vez de uma nova coluna de armazenamento por driver. Os campos
existentes mapeiam o caso comum (`host` = URL base, `database` = nome do manifesto, `username` =
ID do cliente, `password` = token OAuth). Valores sensíveis (segredo de cliente, token de atualização) pertencem
ao Keychain, não ao documento; o JSON contém a forma não secreta mais uma referência de chave do Keychain.
Isto não é uma solução alternativa — é o ponto de extensibilidade, para que um driver não
mude o formato do documento cada vez que adiciona um parâmetro.

A autoria do manifesto é **fornecida junto/escrita pelo desenvolvedor primeiro** (decisão do usuário,
2026-11-22): o desenvolvedor do driver escreve o manifesto e o distribui com o driver. Um
editor/importador de manifesto voltado ao usuário e sua fronteira de confiança são adiados atrás do sistema de plugins
(§5.1). O desejo de longo prazo — drivers que se conectam e são adicionados/removidos pela
interface — está registrado aqui; é uma preocupação de macOS/Linux/Windows e servidor primeiro, porque o iOS
historicamente bloqueou o carregamento de código arbitrário de terceiros, então no iOS os drivers permanecem
vinculados em tempo de compilação.

O driver genérico também carrega as obrigações não SQL que o plano não carrega: cliente HTTP e
TLS, atualização de autenticação, limites de taxa, novas tentativas, cancelamento, limites de tamanho de resposta e mapeamento
de erros. Essas pertencem ao framework do driver, não à engine.

O que o driver genérico não pode fazer é tão importante quanto o que ele pode: GraphQL arbitrário, uma
fonte cujas linhas não são tabulares, ou junções do lado do servidor que o manifesto não consegue expressar. O
objeto de capacidades é como ele diz isso, e o designer de consultas é onde o usuário descobre.

### 5.1 Drivers plug-and-play (futuro, não v1)

O objetivo maior do usuário é drivers que instalam, registram e desregistram como plugins, e
que podem ser adicionados ou removidos pela interface em vez de vinculados ao aplicativo. O registro
já faz o registro por processo por link (§1 do tutorial de drivers); um sistema de plugins real é uma questão de empacotamento e
confiança em camadas por cima: carregamento dinâmico, um local de descoberta, assinatura/sandbox e uma interface.
Isso é um recurso de macOS/Linux/Windows e servidor, não de iOS,
e está fora do escopo das fases deste design. Está anotado aqui para que a
costura do driver (Fase 0) não se encurrale: os tipos de plano, capacidade e
registro devem permanecer carregáveis a partir de uma imagem vinculada dinamicamente, o que significa nenhum
acoplamento em tempo de compilação a uma lista fixa de drivers.

## 6. O que muda no armazenamento e no formato

Forma mínima, seguindo a §4.4 de `MAD_DATA_OBJECT.md`:

- `RptqQuery` ganha um nome. Ele já é a definição.
- A referência de `RptqQueryTable` ganha um segundo tipo: **um objeto de dados (sub-relatório) no mesmo
  documento**, além de uma tabela de esquema. Uma linha v1 que nomeia uma tabela de esquema significa exatamente
  o que significa hoje. Uma referência a um relatório em *outro* arquivo `.mad` é adiada além da
  v1; quando chegar, precisa de uma identidade de documento e um caminho, mais um marcador ativo/fixado.
- A credencial ganha a coluna de texto **options** extensível (JSON/XML) para parâmetros
  específicos do driver (§5), versionada junto com o formato.
- O endereço da materialização torna-se o hash de identidade do objeto, não
  `fileURL.lastPathComponent.hash`. O nome da tabela permanece `t<tag>`; a tag se torna a
  identidade do objeto.
- Cada objeto ganha seu próprio plist de esquema (`.mdcache`) e tabela. O Layout A mantém um arquivo por
  objeto; o Layout B mudaria o modelo de arquivo.
- O armazenamento precisa de um passo de versão para os novos campos de referência e opções. O armazenamento
  existente já tem maquinário de versionamento para a coluna de origem SQL (`MADStoreSchema.m:314`),
  então este é um padrão conhecido, não um mecanismo novo.

O documento `.mad` permanece uma definição e não contém **nenhum dado, agora ou depois** — essa é a
decisão explícita do usuário. Snapshots e materializações são arquivos de cache complementares no
sistema do usuário, e são o que o `ATTACH` une. A nomeação automática desses arquivos de cache
passa do hash do nome do arquivo para uma identidade estável do objeto, para que os arquivos não possam colidir.

## 7. Interface, CLI e a engine headless

- O painel Adicionar Tabela ganha um segundo tipo de fonte: os outros objetos de dados do documento
  (sub-relatórios). A interface de junção não muda; ambas as extremidades são campos. Referências `.mad`
  entre documentos são uma adição posterior.
- O designer deve poder mostrar o esquema de resultado de um filho sem executá-lo, e
  marcar uma referência quebrada (esquema alterado, credencial ausente) antes da atualização.
- A atualização precisa de progresso e erros por nó. Um filho que falha deve ser nomeado.
- As credenciais são por nó. Sub-relatórios no mesmo documento mantêm suas credenciais no único
  documento, então a política é por objeto; a atualização entre documentos, quando chegar, precisa de uma
  política para obter as credenciais do filho.
- A CLI e a engine headless percorrem o mesmo DAG. `MADOperationRefresh` é compartilhado pelo
  aplicativo, macOS e CLI (`CLI/Source/MADCLIDocument.m:120-127`,
  `Mac/Source/MADMacDocument.m:337-360`), então a caminhada topológica pertence ali ou a um
  auxiliar que ele chama, não a cada front end.
- O formulário de conexão do aplicativo macOS e o mapa de tokens de driver da CLI precisam do mesmo
  tratamento conduzido por registro que o seletor do iOS.

## 8. Fases

Ordenadas para que cada fase chegue verde e o aplicativo de consulta única continue funcionando. A primeira fase é
independente da composição e é a que desbloqueia as fontes não SQL.

| Fase | Trabalho | Depende de |
|---|---|---|
| 0 | **A costura do driver.** Adicione `MADQueryPlan` + tipos de valor e mova os três enums para `MADAPI`; adicione o `executeQueryPlan:` opcional; adicione capacidades; faça a atualização preferir o plano e recorrer ao SQL. Implemente o plano em um driver existente como referência e fixe a equivalência plano-SQL com testes. Sem mudança de comportamento. | — |
| 1 | **O contrato do objeto de dados.** Separe a construção da lista SELECT da execução; adicione descrever/executar; retorne o esquema de resultado como `MADDataColumn`s; faça a atualização chamar o contrato. Esta é a Fase 1 de `MAD_DATA_OBJECT.md`. | 0 (sobrepõe-se) |
| 2 | **A consulta é dona de si.** `MADQueryFull` usa a consulta que lhe foi dada; `dataTableForQuery:` resolve por consulta; `MADQueryActiveQueryFields` limita-se a uma consulta; `MADModelDocument` espelha qualquer consulta. | 1 |
| 3 | **Composição no mesmo documento.** Uma tabela de consulta pode referenciar outro objeto de dados (sub-relatório); atualização topológica; suporte a `ATTACH` em `MADDatabaseSqlite3`; a consulta compositora executa contra o cache local. Este é o modelo de um arquivo portátil do usuário. | 1, 2 |
| 4 | **Composição entre documentos (adiada).** Uma referência a um relatório em outro `.mad`; identidade de documento e resolução de caminho; ativo vs fixado; coordenação de arquivos; política de credenciais; tratamento de ausente/renomeado. Prioridade menor: a composição no mesmo documento satisfaz o modelo do usuário. | 3 |
| 5 | **O driver genérico de API.** Um driver HTTP/JSON conduzido por manifesto; esquema a partir do manifesto; mapeamento plano-requisição; laço de paginação; mapeamento de tipos; o campo `options` extensível da credencial; eBay Seller como exemplo trabalhado. | 0, 1 (e 3 para junções) |
| 6 | **Superfícies e documentação.** Listas de drivers e regras de junção conduzidas por registro; interface de atualização por nó; verbos da CLI; o tutorial de autoria de drivers atualizado com a costura de plano/capacidades. | 0–5 |

Não é uma fase: **o carregamento de drivers plug-and-play** (§5.1) é um recurso de macOS/Linux/Windows e servidor
acompanhado separadamente deste design; nada nas Fases 0–6 depende dele, e a Fase 0
deve apenas evitar o acoplamento a uma lista fixa de drivers para que o carregamento dinâmico continue possível.

A Fase 0 é a parte "não muito distante": são novos tipos de valor, um método opcional, um ramo na
atualização e testes. Ela não exige que o armazenamento, a interface ou o modelo de composição
mudem. A Fase 3 é onde o modelo `ATTACH` do usuário chega, e é menor do que parece
porque o SQLite já é um driver e o compilador já ordena um grafo.

## 9. Decisões

### 9.1 Decisões do construtor registradas neste documento

Estas estão resolvidas a partir do código ou por uma troca de design; podem ser revisitadas, mas o
plano as assume.

1. **Layout A, com `ATTACH`.** Um `.maddb` por objeto; a conexão compositora os anexa.
   Isto segue o modelo de uma tabela por arquivo de `MADDataTableFast`. O Layout B (várias tabelas
   em um arquivo) é uma refatoração posterior, não v1. Isto substitui a recomendação de Layout B
   da §9.2 de `MAD_DATA_OBJECT.md` para este design.
2. **Objetos compositores são somente locais.** As tabelas de uma consulta compositora são objetos de dados; uma
   tabela remota é envolvida em um objeto de origem. Sem execução remota/local mista.
3. **Os campos de filho do pai são campos de esquema comuns.** Sintetize uma tabela/conjunto de campos de esquema de
   resultado por objeto a partir dos `MADDataColumn`s do filho, e atualize-a quando o
   esquema do filho mudar. Sem segundo tipo de referência de campo.
4. **A raiz é explícita.** Uma referência (ou flag) de raiz no nível do documento, migrada da
   consulta única de hoje. Não `hasQueries.anyObject`.
5. **O plano é lógico; o contexto de execução é separado.** `MADDatabaseExecutionOptions`
   carrega cancelamento, progresso, credenciais e o conjunto de anexações do compositor SQLite.
   `MADQueryPlanTable.sourceIdentifier` nomeia a fonte lógica; não é um caminho de arquivo.
6. **Mais de dez fontes diretas é um erro de tempo de design na v1.** Aumentar
   `SQLITE_MAX_ATTACHED` é uma mudança de compilação em três plataformas, adiada.
7. **Construa o plano em paralelo com o compilador SQL, depois fixe a equivalência.** Não
   refatore o compilador SQL para renderizar a partir do plano até que o plano seja provado pela suíte
   atual.
8. **Nomeie o `RptqQuery` existente; não introduza `RptqDataObject` ainda.**
   A §9.1 de `MAD_DATA_OBJECT.md` recomenda isto, e é a migração menor.
9. **Mantenha `MADDatabaseDriver` na classe de conexão por compatibilidade.** Um contrato de
   registro de classe de banco de dados pode ser adicionado ao lado dele depois.
10. **O primeiro driver genérico de API declara junções sem suporte.** Ele depende da composição
    para junções, depois ganha uma junção hash do lado do cliente atrás do objeto de capacidades. Isso mantém
    o primeiro driver como uma busca de recurso único.
11. **A composição no mesmo documento chega antes da composição entre documentos.** A Fase 3 aposenta os
    pontos de fixação sem a complexidade de caminho/coordenação/credenciais; a composição entre documentos é
    a Fase 4.

### 9.2 Decisões respondidas pelo usuário (2026-11-22)

As próprias palavras do usuário seguem; as implicações são do autor.

1. **O esquema de saída são os campos ativos — sem mudança.** A saída de um objeto de dados são as
   colunas que o relatório usa: os campos dos elementos de layout, os campos de junção e os campos de
   agrupamento, que é precisamente a lista SELECT que `MADQueryActiveQueryFields` já calcula
   (`MADQueryActiveQueryFields.m:27-100`). O usuário: *"seriam apenas os campos que são
   usados naquele relatório."* A forma de todas as colunas é apenas uma preocupação de pré-visualização de tabela. Descrever
   retorna essa mesma lista como `MADDataColumn`s sem executar. Duas consequências são anotadas
   como recursos futuros, não parte deste trabalho: **nomes de coluna legíveis por humanos** (definir
   `MADDataColumn.caption`, que já existe, em vez de expor apenas o
   alias `"Table0"."Field"`) e **paginação de pré-visualização** (a pré-visualização atualmente limita a ~512 linhas
   e deveria paginar pelo resultado completo — o usuário sinalizou isto para a lista de desejos, que
   é o `TODO.md` do usuário, não este documento). A regra de zero linhas ainda se aplica: um objeto de origem
   materializa seu esquema completo mesmo quando retorna nenhuma linha.
2. **Espera-se que os drivers executem em todas as plataformas; plug-and-play é o objetivo.** O usuário:
   *"Isso realmente depende da pessoa que escreve o driver, mas sim, eu esperaria isso."* A
   engine headless e o mesmo DAG valem no Linux/Windows; se um *determinado* driver executa
   headless é uma preocupação de seu autor. O desejo maior — *"os drivers poderiam ser plug-and-play…
   adicionar e remover drivers pela interface"* — é a §5.1, um recurso futuro e uma
   preocupação de macOS/Linux/Windows/servidor, porque o iOS historicamente bloqueou o carregamento de código
   arbitrário de terceiros.
3. **Os snapshots vivem no cache complementar, nunca no `.mad`.** O usuário: *"O arquivo `.mad`
   só descreve o esquema… isso não deveria mudar… Estaria no que quer que o arquivo de cache
   seja agora… os arquivos em cache que são armazenamentos de dados Sqlite3, e é isso que seria
   `ATTACH`ado junto."* Então o arquivo permanece somente de definição; um snapshot fixado é um
   `.maddb`/`.mdcache` retido, e a nomenclatura da materialização passa para uma identidade estável do objeto
   para evitar colisões.
4. **Os manifestos são fornecidos junto/escritos pelo desenvolvedor primeiro.** O usuário: *"sua resposta está correta…
   a ideia sempre foi que novos drivers pudessem ser adicionados por algum sistema de plugins… não
   acredito que você possa ter plugins no iOS."* A v1 distribui um driver conduzido por manifesto com
   manifestos escritos pelo desenvolvedor; um editor/importador de manifesto voltado ao usuário e sua fronteira de confiança
   vêm atrás do sistema de plugins.
5. **A composição é dentro do documento primeiro — sub-relatórios em um arquivo portátil.** O usuário:
   *"talvez você pudesse adicionar 'sub-relatórios' ao documento mad… a ideia ainda seria um
   arquivo portátil."* Um `.mad` contém várias definições de relatório/consulta; cada uma executa em uma
   tabela SQLite; o relatório compositor as `ATTACH`a. Isso preserva a propriedade de arquivo único
   e remove o problema de reautorização entre arquivos do iOS para a v1. Referências entre *documentos*
   são adiadas atrás da composição no mesmo documento.
6. **As credenciais ganham um campo de opções extensível.** O usuário: *"poderíamos projetar um e adicioná-lo
   ao formato do relatório… talvez tudo em um campo de banco de dados, que analisamos de alguma forma
   (como JSON ou XML) para que possa ser extensível."* Uma coluna de texto contendo JSON, versionada no
   armazenamento, analisada pelo driver. Valores sensíveis (segredo de cliente, token de atualização) vão
   no Keychain; o JSON contém a forma não secreta mais uma referência do Keychain.

### 9.3 Padrões que o autor assume (decisões do construtor)

- **Ativo é o padrão; fixar significa reter o snapshot do cache.** Ativo executa o filho na
  atualização; fixar reutiliza a materialização retida. Ambos leem do diretório de cache.
- **Política de atualização.** Recalcule todo nó na atualização (a descrição de baixo para cima do usuário). Um
  botão de frescor/reutilização de cache para filhos de API caros é uma adição posterior atrás do
  objeto de capacidades.
- **Nomenclatura.** "Objeto de dados" é o termo do armazenamento/protocolo; "sub-relatório" é o termo voltado ao usuário
  para um objeto referenciado na interface de composição.

## 10. Riscos, e o que faz isto não ser uma linha de código

- **Os três pontos de fixação** (a releitura de `MADQueryFull`, a tabela de dados de um único slot, os
  campos ativos sem escopo) são estruturais para o aplicativo de consulta única de hoje. Eles devem cair
  antes que uma segunda consulta, muito menos uma aninhada, possa executar.
- **O endereço do cache é o hash do nome do arquivo** e o cache é por dispositivo. A endereçabilidade é
  um pré-requisito, não um detalhe.
- **Referências entre documentos** trazem resolução de caminho, despejo do iCloud, coordenação de arquivos,
  filhos ausentes e credenciais para uma fonte que o pai não possui. Esta é a parte mais
  pesada em produto.
- **`ATTACH` tem um limite** (`SQLITE_MAX_ATTACHED`, padrão 10) e precisa de gerenciamento de alias/nome
  e citação de caminhos. Não descubra isso em produção.
- **Custo da atualização completa.** O design do cache é puxar tudo por natureza; um DAG multiplica
  isso. Uma política de cache/frescor faz parte do design, não é uma otimização.
- **Limites de taxa e volume de dados da API.** Um driver que pagina uma API a cada atualização precisa de
  novas tentativas, limites, cancelamento e uma história de progresso visível.
- **Deriva de esquema.** As colunas de um filho podem mudar; a consulta do pai então referencia campos
  que não existem mais. Validação em tempo de design e erros em tempo de atualização são necessários.
- **Estabilidade da API de driver.** Drivers de terceiros compilam contra `MADAPI`; os tipos de plano e
  capacidade se tornam uma superfície pública. Versione-os deliberadamente.
- **Matriz de testes.** Quatro plataformas (iOS, macOS, Linux, Windows), drivers SQL e não SQL,
  composição no mesmo documento e entre documentos. A ordem das fases é a mitigação: um novo
  eixo de cada vez.

## 11. O que isto não é

- **Não é uma engine de federação.** Nada de novo fala com MySQL e uma API em uma instrução. Cada
  objeto executa contra sua própria fonte; a junção é local.
- **Não é uma segunda implementação de consulta.** O grafo, o compilador, os drivers, a tabela de resultados
  e a engine de junção do SQLite já existem.
- **Não é uma mudança no cache que puxa tudo.** O cache de duas passagens é estrutural
  (`docs/05-companion-files.md` §5.1).
- **Não está agendado.** Este é o registro de design para trabalho futuro. `docs/project/registers/TODO.md` é
  a lista de desejos do próprio usuário (o desejo de paginação de pré-visualização pertence lá), `TASKS.md` é a
  fila de engenharia, e `ROADMAP.md` diz o que é pego a seguir. Nada aqui é iniciado por
  iniciativa de um agente.

Dois recursos futuros são nomeados aqui mas pertencem aos arquivos de acompanhamento do usuário, não a este design:
a correção da **paginação de pré-visualização** (§9.2.1) e o **sistema de drivers plug-and-play** (§5.1). Este
documento é onde a forma deles é registrada; ele não os agenda.

## 12. A linha condutora

A aba de consulta já constrói a função. A cadeia de atualização já a compila e executa.
A tabela de resultados já é um esquema e um conjunto de resultados, em disco como SQLite. O SQLite já é
um driver. Os drivers já retornam tabelas. O que falta é o nome, o
endereço, a metade de descrição e a consulta estruturada de que um driver não SQL precisa em vez de
texto SQL. Esses são aditivos: um objeto de valor de plano, um objeto de capacidades, um método opcional
de execução, uma identidade estável de objeto, um segundo tipo de referência de tabela, uma caminhada
topológica e `ATTACH`.

A composição é então o pipeline existente endereçado por algo melhor que um hash de nome de
arquivo. O driver não SQL é o mesmo pipeline com um corpo de execução diferente. Nenhum é uma
engine nova; ambos são o que as abstrações foram construídas para permitir.
