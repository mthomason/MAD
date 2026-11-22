---
layout: default
title: "A arquitetura do MADDataTable"
description: "O cluster de classes da tabela de dados entre os frameworks e seu plano de desacoplamento."
lang: pt-BR
---

# MADDataTable — Relatório de Arquitetura e Desacoplamento

Esta página é o relatório de arquitetura do `MADDataTable` e de toda implementação em `MADFoundation`, `MAD`, `MADSqlite3`, `MADMySQL` e `MADTdsClient`. Ele registra o cluster de classes e o trabalho de desacoplamento.

*Escrito na data original; fatos do estado atual reconciliados em 2026-11-22.*

**Escopo:** `MADDataTable` e toda implementação, subclasse, protocolo e sítio de chamada em
`MADFoundation`, `MAD`, `MADSqlite3`, `MADMySQL` e `MADTdsClient`.
**Branch:** `refactor/mad-database-decouple`
**Data:** 2026-10-01
**Verificação:** `xcodebuild test` — todos os 11 esquemas, 809 testes, 0 falhas; nenhum aviso de nenhum
arquivo no escopo (os dois avisos `-Warc-repeated-use-of-weak` em `MADDatabaseMySQL.m` são
pré-existentes e intocados). (798 na Revisão 2; 804 na Revisão 3; 807 na Revisão 4.)

Todas as referências `file:line` abaixo foram lidas em primeira mão durante esta análise, não inferidas.

> **Revisão 5 — 2026-10-01.** As Fases 3 e 5 estão fechadas e o passo 7 da Fase 1 está provado.
> `-dropTable`, `-dropTableName:`, `-deleteAll` e `-vacuumCacheDb` agora deixam `rowCounter`
> descrevendo o arquivo (§2.5), que era todo o passo 10/11; as três constantes em risco
> estão cobertas por quatro novos testes. Conduzir o loop de linhas do sqlite com um conformador
> `<MADDataTableWriting>` puro — sem `MADDataTable` por trás, sem `.maddb` — é o passo 7 e agora é um teste
> (`MADWritePortRecorder`). O passo 14 está feito: `MADDataTableLocation` foi excluído. Os passos 13 e 15
> são avaliados em vez de feitos, com motivos, em suas entradas abaixo.
>
> Dois defeitos ativos caíram ao escrever esses testes, ambos agora corrigidos. `-deleteAll` entregava uma
> *string* a `-[MADQueryCacheDeleteAllFromTable initWithObject:]`, que a usa como subscrito
> do dicionário de parâmetros e lança exceção na primeira linha — o método não tem chamadores, e é por isso
> que nada nunca o havia atingido; agora usa `-initWithTableName:`. E `MTTableController` lia
> `datatable.count` como cursor de página em seu caminho de falha, onde a tabela ainda contém a
> página anterior, então uma busca falha relatava `hasMore = YES` e tentava de novo para sempre.
>
> Os comentários do contador deslocaram `MADDataTableFast.m` em 13 linhas a partir de `-deleteAll`, então toda
> referência `file:line` depois desse ponto foi redescoberta em vez de ajustada; `MTTableController.m`
> também se moveu, e suas referências foram redescobertas com ele.
>
> **Revisão 4 — 2026-10-01.** O obstáculo do MySQL da Revisão 3 se foi. Os metadados de coluna
> que `MADMySQLFetch+DataTable.m` lê no meio da busca agora são declarados pelo próprio
> `<MADDataTableWriting>`, então todos os três drivers — incluindo `MADDatabaseMySQL`, `MADDatabase.m` e o
> protocolo `MADDatabaseDataSource` — recebem `id <MADDataTableWriting>` e os parâmetros de saída da busca
> são por valor (`&` removido em todos os sítios de chamada). A Fase 2 ("armazenar `urlFastCache`;
> injetar o diretório de cache") e o passo 12 da Fase 4 (serializar o pipeline de escrita) estão feitos, e a
> Fase 3 está feita apenas para o caminho de reidratação. §2.1 e §2.3–§2.5 e §4.2 marcam cada um. Três testes foram
> adicionados; a suíte vai de 804 → 807. Como as correções deslocaram `MADDataTableFast.m` em 87 linhas,
> toda referência `file:line` a ele neste relatório foi redescoberta em vez de ajustada, e as
> contagens de linhas do apêndice foram atualizadas com elas.
>
> **Revisão — 2026-09-30.** As seções §2.5, §3.3, §3.5 e §4.2 foram reescritas depois que a primeira
> revisão foi considerada errada em três pontos: o diagnóstico de `-dataForRow:error:` (uma assinatura de método
> de duas linhas foi mal lida — o método *está* implementado em `MADDataTableFast`), o
> "bug ativo" de `-allObjects` (nenhum chamador de produção) e o enquadramento da deriva de `rowCounter` (inalcançável).
> §4.5 é nova. O texto corrigido está marcado **Corrigido** / **Resolvido**; as alegações originais são deixadas
> visíveis onde eram instrutivas. Três correções de código chegaram com esta revisão — veja §3.5.
>
> **Revisão 3 — 2026-10-01.** O passo 5 da Fase 1 chegou: `<MADDataTableWriting>`,
> `<MADDataTableReading>` e `<MADDataTableCursoring>` são declarados em `MADDataTable.h` e a
> classe adota todos os três. O passo 6 chegou para dois drivers de três — `MADDatabaseSQLServer` e
> `MADDatabaseSqlite3` agora são tipados como porta de escrita. O passo 6 **não pôde** chegar para `MADDatabaseMySQL`,
> e o "excluir o bloco de stub agora redundante" do passo 5 foi recusado; a §4.2 registra o motivo de cada um.
> A passagem inteira é aditiva: nenhum comportamento mudou, e todos os 11 esquemas passam (804 testes).
>
> **Revisão 2 — 2026-09-30.** Os oito sítios de string de formato `sqlite3_mprintf` da §4.5 agora estão
> corrigidos, e a Fase 0 chegou: as operações não implementadas em `MADDataTable.m` fazem asserção em vez
> de falhar silenciosamente (§3.2, §4.2). A tabela da §3.1 e as contagens de linhas do apêndice foram redescobertas
> contra os arquivos alterados. Dois erros da revisão anterior também foram corrigidos: o
> total de testes do workspace foi declarado como 799 e é 798, e a §3.6 citava quatro sítios `_database`
> onde há quinze.

---

## 1. Arquitetura atual e hierarquia de classes

### 1.1 A família de classes

`MADDataTable` **não** é uma única classe — é um pequeno cluster de classes dividido entre três
frameworks ao longo de um eixo de armazenamento, mais um eixo de cursor implementado como objetos enumeradores separados.

```
MADFoundation
└── MADDataTable                          NSObject <NSCoding, NSFastEnumeration>
        │                                 "abstract": declares the full surface,
        │                                 implements metadata + plist persistence
        │
        ├── MADDataTableVirtual            MADFoundation/Source/MADDataTableVirtual.m (240 ln)
        │       In-memory. Rows live in per-column MADDataColumn arrays plus a
        │       `sortIndex` NSMutableArray of row NSDictionaries.
        │
        └── MADDataTableFast               MADSqlite3/Source/MADDataTableFast.m (1368 ln)
                sqlite3-backed. Rows live in a `.maddb` file; the object holds two
                MADDatabaseSqlite3 handles (one for writes, one for reads).

MADSqlite3 (private — NOT exported from the framework)
├── MADDataTableObjectEnumerator          173 ln — wraps a live sqlite3_stmt, yields row dicts
└── MADDataTableSingleColumnEnumerator    149 ln — same, yields a single column (row-ids)

MAD
└── MADDataTable+Constructor              the ONLY place that maps type -> concrete class
                                            (`MADDataTableLocation`, the other class here at
                                            Revision 4, was deleted — see §3.7)
```

Superfície de exportação verificada (a partir de `.framework/Headers` compilados):

| Framework | Cabeçalhos de tabela de dados exportados publicamente |
|---|---|
| `MADFoundation` | `MADDataTable.h`, `MADDataTableType.h`, `MADDataTableVirtual.h` |
| `MADSqlite3` | `MADDataTableFast.h` **somente** |
| `MADMySQL` | nenhum |
| `MADTdsClient` | nenhum |

Essa divisão é deliberada e saudável: os nomes das classes enumeradoras nunca vazam. Os consumidores
só veem `NSEnumerator *`, que é o que `MADDataTable.h` retorna.

### 1.2 Dois eixos ortogonais, um enum

`MADDataTableType` (`MADFoundation/Source/MADDataTableType.h`) codifica apenas o eixo de **armazenamento**:

```objc
typedef NS_ENUM(short, MADDataTableType) {
    MADDataTableTypeVirtual,    // -> MADDataTableVirtual
    MADDataTableTypePhysical,   // -> MADDataTableFast
};
```

O eixo de **acesso** — linha por linha vs. cursor — é ortogonal e é expresso retornando um
enumerador em vez de um tipo. Não existe `MADDataTableTypeCursor`. Isso importa para a
refatoração: a costura do cursor já existe e está corretamente oculta.

### 1.3 O único ponto de seleção de subclasse

`MAD/Source/MADDataTable+Constructor.m:51-69` é o único lugar no código que nomeia uma
subclasse concreta:

```objc
+ (instancetype)newDataTableOfType:(MADDataTableType)type withObjectID:(NSUInteger)objectID {
	switch (type) {
		case MADDataTableTypeVirtual:  result = [[MADDataTableVirtual alloc] initWithId:objectID]; break;
		case MADDataTableTypePhysical: result = [[MADDataTableFast alloc] initWithId:objectID];    break;
		default: NSAssert(NO, @"Not implemented."); break;
	}
	return result;
}
```

Confirmei que **não** há `isKindOfClass:`, `NSClassFromString`, comparação de string de nome de classe
ou sondagem `respondsToSelector:` em uma tabela de dados em lugar algum do código. Esta é a propriedade
mais valiosa para a refatoração — o cluster pode ser remodelado atrás deste único método.

Duas ressalvas no mesmo arquivo:

* `+newDataTableWithDefinition:` chama `NSAssert(NO, @"Not implemented.")` e retorna `nil`
  quando nenhum id de objeto está presente (`:44-46`). A intenção de "padrão para virtual" no comentário em
  `:31-32` é inalcançável — `objectIdSet` controla o único caminho de retorno.
* `+newDataTableForIdentifier:` (`:79-92`) é o ponto de entrada público *de fato*: a maioria dos sítios de chamada
  (`MTTableController.m:90`, `MADQuerySampleDataTable.m:68`, `MADQuerySampleDataTableRange.m:69`)
  passa por `newDataTableWithDefinition:` diretamente, e sempre fixa o tipo em Virtual.

### 1.4 O contrato de escrita

Todo driver de banco de dados popula uma tabela pela API da **classe base**, nunca por uma
específica de subclasse. `MADDatabaseSqlite3.m:474-540` é o loop canônico:

```objc
[dataTable removeAllObjects];
// first row only:
[dataTable addColumn:dataColumn];       // per column, discovered from sqlite metadata
[dataTable beginBulkInsert];
// per row:
[dataTable addRowWithDataForFieldKeys:resultsForRow];
[dataTable endBulkInsert];
```

`MADDatabaseSQLServer.m:500 / :1367 / :1472` usa a forma idêntica de cinco chamadas.
`MADMySQLFetch+DataTable.m:211 / :438 / :442` da mesma forma.

Esta é uma **porta de escrita estreita e bem definida**: cinco métodos. É a fronteira existente
mais forte da família e deve ser preservada verbatim por qualquer refatoração.

Divergência entre drivers:

| Driver | Tabela que constrói | Caminho de escrita |
|---|---|---|
| `MADDatabaseSqlite3` | qualquer uma que receba (tipicamente `MADDataTableFast`) | `executeSQL:...intoResultTable:` |
| `MADDatabaseMySQL` | **constrói** `MADDataTableVirtual` por conta própria (`MADDatabaseMySQL.m:83, 110, 137, 175, 196, 376`) | `MADMySQLFetch+DataTable.m` |
| `MADDatabaseSQLServer` | **nunca constrói uma** — puramente somente escrita em uma tabela fornecida pelo chamador | `MADDatabaseSQLServer.m` |

Então o MySQL não consegue produzir um `MADDataTableFast`, e o SQL Server não consegue produzir nenhuma tabela.
O armazenamento "físico" (respaldado por sqlite) existe apenas para o cache local, não para resultados remotos.

### 1.5 O contrato de leitura

Três estilos distintos de leitura estão em uso em produção:

1. **Acesso aleatório** — `-objectAtRow:` / `-objectAtRow:column:`.
   `MADMySQL` usa `objectAtRow:i column:0` dentro de loops O(n)
   (`MADDatabaseMySQL.m:88-92, 118-122, 150-154, 187-189`) para ler resultados de `SHOW TABLES`.
   `MADQuerySampleDataTable.m:126` / `MADQuerySampleDataTableRange.m:131` chamam `objectAtRow:0`
   uma vez para ler uma linha de largura. `MTTableController.m:281, 284, 393` usa `objectAtRow:` para paginação.

2. **Enumeração** — `-enumeratorForKeyObjectsSorted`.
   `MADocument.m:865-867` retorna isto como `enumeratorForReportData`, consumido por
   `MADReportFormatter.m:449-502`.

3. **Contagens** — `-rowCounter` / `-count` / `-numberOfRows`.
   `MADocument.m:197` (`numberOfResults`), `MTTableController.m:249` (tamanho da tabela) e
   `:377, :399, :449, :455` (aritmética de cursor de página).

`MADReportFormatter` é o consumidor mais tolerante e o que menos restringe a
refatoração. Observe `MADReportFormatter.m:463-472`:

```objc
if (!calculatedRowId) {
    if ([resultRow isKindOfClass:[NSDictionary class]]) { rowIdOnly = NO; }
    calculatedRowId = YES;
}
self.machineState.detailRowId = rowIdOnly
    ? ((NSNumber *)resultRow).unsignedIntegerValue
    : ((NSNumber *)resultRow[MADIdentifierROWID]).unsignedIntegerValue;
```

O formatador **já tolera um enumerador que produz `NSNumber`s de id de linha puros**, bem como
dicionários completos de linha. `enumeratorForAllObjectsSortedRowIdOnly` existe precisamente para esse caso.
Esta é uma costura pronta: um cursor que transmite apenas ids de linha já é uma entrada aceita.

---

## 2. Modelo de memória, ciclo de vida e estado

### 2.1 ARC e a única ivar bruta

Todos os arquivos são ARC (guardas `#if !__has_feature(objc_arc) #warning ...`). O estado vive em extensões
de classe. `MADDataTableFast` tem exatamente uma ivar não objeto:

```objc
@implementation MADDataTableFast {
	sqlite3_stmt *_statementInsert;   // MADDataTableFast.m:103
}
```

Ela é finalizada em `-dealloc` (`:163-165`) e em `-endBulkInsert` (`:1334-1339`). O padrão
está correto, mas *era* frágil: `-endBulkInsert` anulava a instrução **antes** de tomar a
barreira, então a destruição ficava fora da única janela em que nenhuma inserção está em andamento.

**Corrigido (Revisão 4).** A destruição agora executa dentro da barreira, em `:1337-1338`.

### 2.2 Duas conexões sqlite sobre um arquivo

`-reopenDbConnection` (`:385-401`) constrói **duas** instâncias independentes de `MADDatabaseSqlite3`
apontando para o mesmo arquivo `.maddb`:

```objc
// write handle
MADDatabaseConnection *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:urlFastCache];
MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
database.delegate = (id <MADDatabaseResultsProtocol>)cacheDelegate;
database.databaseConnection = connection;
[(MADDatabaseSqlite3 *)database openDatabaseWithFlags:
     SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX];
self.databaseForInserts = database;

// read handle — same URL, separate connection, default flags
MADDatabaseConnection *connectionSelect = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:urlFastCache];
MADDatabaseSqlite3 *databaseSelect = [[MADDatabaseSqlite3 alloc] init];
[databaseSelect setDatabaseConnection:connectionSelect];
[databaseSelect openDatabase];
databaseSelect.delegate = (id <MADDatabaseResultsProtocol>)cacheDelegate;
self.databaseForSelects = databaseSelect;
```

O handle de leitura é aberto com **`-openDatabase` (flags padrão)** e o handle de escrita com
`SQLITE_OPEN_FULLMUTEX`. `SQLITE_OPEN_FULLMUTEX` é um modo de serialização **por conexão**;
ele não arbitra entre duas conexões no mesmo arquivo. Combinado com §2.4, esta é a
maior suposição de correção da família.

### 2.3 O local de armazenamento é resolvido a partir de estado global ambiente

`-urlFastCache` era uma propriedade *calculada* (`:299-311` antes desta revisão), não armazenada:

```objc
- (NSURL *)urlFastCache {
	NSString *filename = [[self filenameCacheMadDB] copy];
	NSURL *cacheDirectory;
	if (self.cacheDelegate == nil) {
		id <UIApplicationDelegate, MADApplicationProtocol> appDelegate = [MADApplication AppDelegate];
		id groupIdentifier = [appDelegate groupIdentifier].copy;
		cacheDirectory = [MADURLFactory newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier];
	} else {
		cacheDirectory = [self.cacheDelegate cachedFilesDirectory].copy;
	}
	return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}
```

Consequências:

* Uma tabela sem `cacheDelegate` **depende silenciosamente do app delegate global** para sua
  identidade em disco. É por isso que `MADDataTableFast` não podia ser instanciado em um teste de lógica sem host
  sem um delegate — a suíte de regressão contorna isso com um stub que conforma a
  `MADCacheProtocol` + `MADDatabaseResultsProtocol`.
* `-setCacheDelegate:` (`:377-383`) chama `-reopenDbConnection`. Trocar um
  delegate **reaponta a tabela para um arquivo diferente** mantendo `tag`/`rowCounter`/
  `columnKeys` em memória. Nada detecta a incompatibilidade.
* `-copyPlist` faz asserção `urlFastCache != nil` (`:243`) — então a URL persistida de uma tabela arquivada
  depende do estado ambiente no momento do arquivamento.

**Corrigido (Revisão 4).** `-urlFastCache` agora resolve uma vez e mantém a resposta
(`_urlFastCache`, em `:347-355`, escrita pelo getter e por `-setCacheDelegate:` em `:377-383`,
que a descarta antes de reabrir). `-newUrlFastCache` (`:357-373`) mantém a resolução em si,
com uma nova primeira escolha: um diretório de cache fornecido na inicialização. `MADDataTableFast` ganhou
`-initWithId:cacheDirectory:` (`:173-181`),
`+[MADDataTable newDataTableOfType:withObjectID:cacheDirectory:]` o repassa (`nil` mantém
o comportamento antigo), e ele abre a conexão imediatamente para que a tabela seja utilizável sem
delegate e sem aplicativo. O reapontamento por troca de delegate acima ainda acontece — essa é a leitura
pretendida de "a URL é derivada do delegate" — mas não depende mais de *quando*
a propriedade foi lida pela primeira vez.

`tag` (definida a partir de `initWithId:fromCache:`, `:190`) é a única identidade estável; ela produz tanto
o nome da tabela (`t<tag>`, `:403-409`) quanto o nome do arquivo (`<tag>.maddb`, `:340-343`).

### 2.4 Segurança de threads: sem bloqueios, uma fila

Fiz grep em toda a família por `dispatch_sync`, `dispatch_async`, `@synchronized`, `NSLock`,
`os_unfair_lock` e `pthread_mutex`. A **única** primitiva de concorrência presente é
`queueBulkAdd`:

* Criada três vezes separadas — `initWithId:fromCache:` (`:186`), `initWithCoder:` (`:202`)
  e `beginBulkInsert` (`:1322`) — cada uma `dispatch_queue_create(..., SERIAL)`.
* Usada em exatamente **dois** lugares: `-endBulkInsert` (`:1334`) envolve a chamada de delegate em
  `dispatch_barrier_sync`, e (desde a Revisão 4) `-addRow:error:` entra nela com
  `dispatch_sync`.
* Antes da Revisão 4 ela **nunca** era usada para serializar `-addRow:error:`.

Então `-addRow:` — o ponto de entrada de mutação — *era* inteiramente desprotegido pela fila. Sob
`_bulkInsertLoop`, `-addRow:` reutiliza uma única `_statementInsert` em cache entre chamadas
(`:529-611`): `sqlite3_bind_*` → `sqlite3_step` → `sqlite3_clear_bindings` →
`sqlite3_reset`, sem exclusão mútua. Duas threads entrando em `-addRow:` concorrentemente disputam
essa instrução compartilhada independentemente de `SQLITE_OPEN_FULLMUTEX`, porque a disputa está na
*sequência* bind/step/clear/reset, não dentro de nenhuma chamada sqlite isolada.

A suíte de regressão registra o comportamento concorrente atual, mas não consegue torná-lo seguro — a
serialização tem de ser adicionada.

**Corrigido (Revisão 4).** `-addRow:error:` (`:504-528`) agora é um wrapper fino que executa o corpo da inserção
(`-insertRow:error:` em `:529`, o método antigo renomeado) sob `dispatch_sync(queueBulkAdd)`, recorrendo
a uma chamada direta apenas quando a fila é nil — o que só acontece para uma tabela que nunca
terminou de inicializar. O `sqlite3_finalize(_statementInsert)` de `-endBulkInsert` se moveu para *dentro*
de seu `dispatch_barrier_sync`, então a instrução em cache só é destruída quando nenhuma inserção está
em andamento. Em uma fila serial, a barreira e o `dispatch_sync` são mutuamente exclusivos, o que é
toda a exclusão mútua de que a sequência bind/step/clear/reset precisa. Dois testes o fixam:
`testFastTableConcurrentWritersLoseNoRows` (novo) conduz quatro escritores de uma fila *concorrente*;
`testFastTableSerializedConcurrentWritesLoseNoRows` mantém o padrão de fila serial do aplicativo, e sua
nota de contrato "a tabela não serializa internamente" foi corrigida. O passo 13 (um par de conexões
por arquivo) está intocado.

### 2.5 `rowCounter` é um contador independente, não um valor derivado

`-insertRow:error:` incrementa `rowCounter` (`:532`) e **nunca consulta o sqlite**.
`-numberOfRows` / `-count` o retornam diretamente (`:1222` / `:1216`), e `-removeAllObjects` o zera
(`:683`). Mas `-dropTable` (`:799`), `-dropTableName:` (`:804`), `-deleteAll` (`:818`) e
`-vacuumCacheDb` (`:789`) **não** o tocavam até a Revisão 5.

As duas fontes de verdade podem, portanto, divergir:

* `rowCounter` diz N; o arquivo `.maddb` contém um número diferente de linhas.
* Em uma ida e volta de `-loadFromCacheWithUrl:` o contador vinha do plist
  (`MADDataTable.m:305-306`) enquanto as linhas vêm do arquivo sqlite — eles são reidratados por
  dois mecanismos não relacionados.

**Corrigido (Revisão 4) — a metade do recarregamento.** `-loadWithPlist:` agora termina com
`self.rowCounter = [self recountRows];` (`:313`), onde `-recountRows` (`:317-338`) pede ao
arquivo de cache `SELECT COUNT(*)` e recorre ao valor do plist apenas quando a tabela ainda
não existe. Um contador inflado pelo caminho em memória não pode mais sobreviver a um recarregamento.
`testFastTableReloadRecountsRowsFromCacheFile` fixa isso carregando um plist cujo contador diz
99 sobre um arquivo que contém 3 linhas.

**Corrigido (Revisão 5) — a metade em memória, que era o passo 10/11.** `-dropTable` (`:799`) e
`-dropTableName:` (`:804`) agora zeram o contador, `-deleteAll` (`:818`) o zera, e
`-vacuumCacheDb` (`:789`) deliberadamente não o faz, porque o VACUUM mantém toda linha — a origem
traz um comentário dizendo isso, já que "por que este *não* o redefine" é exatamente a pergunta
que o próximo leitor terá. `-dropTableName:` recebe um nome arbitrário, então zera o contador
apenas quando a tabela que sumiu é esta; descartar uma tabela estrangeira não deve tocar nesta
contagem. `-numberOfRows` (`:1222`) e `-count` (`:1216`) ainda retornam a ivar em vez de
consultar o arquivo, o que é o ponto — `-recountRows` é a verificação do caminho de recarregamento, não um
custo por leitura.

`-removeAllObjects` (`:674`) escondia todo o perigo, e ainda esconde: é o único chamador de todos
os quatro, e zera o contador por conta própria (`:683`). É exatamente por isso que valia fechar isto
em vez de deixar — o perigo estava a um chamador de estar ativo, `-count` é um cursor de página
para o aplicativo (§4.3), e os quatro métodos privados estão a um `git log -S` de serem chamados de
algum lugar novo. A nota da Revisão 4 aqui chamava a deriva de "real no código, mas nenhum chamador consegue
alcançá-la hoje"; a auditoria de chamadores ainda vale — `-deleteAll` **não tem chamadores em lugar algum do
repositório**, e `-dropTable` só é alcançado a partir de `-removeAllObjects` — mas o contador agora está
correto em todo caminho, em vez de apenas porque seu único chamador por acaso arruma depois.
Quatro testes em `MADDataTableRegressionTests.m` conduzem cada um dos quatro diretamente.

`MADDataTableVirtual` tem a mesma forma (`:179`, `:193`, `:225`), mas seu contador e seu
`sortIndex` são mutados juntos, então é consistente por construção.

Este é o estado mais em risco sob uma refatoração de cluster de classes: `MTTableController.m` lê
`datatable.count` em `:377` e `:399`, e deriva `hasMore = (count == limit)` disso em
`:455`, então um contador que divirja da realidade corromperia a paginação. A Revisão 5 torna essa
derivação total também — uma página vazia não faz mais `offset + count - 1` estourar para `NSUIntegerMax`
(`:380`, `:402`), e o caminho de falha retorna `completion(NO)` (`:449`) em vez de ler uma
contagem que ainda descreve a página *anterior*.

Escrever esses testes revelou um defeito em `-deleteAll` que não tinha nada a ver com o contador:
ele passava uma `NSString` a `-[MADQueryCacheDeleteAllFromTable initWithObject:]`, que usa seu argumento como subscrito
do dicionário de parâmetros, então lançava `unrecognized selector` na primeira
linha. `-initWithTableName:` é o inicializador que recebe um nome e é o que
`MADDatabaseSqlite3 -beginBulkInsert` já usava. Nenhum chamador nunca o atingiu, porque não há
chamador.

### 2.6 Dois mecanismos de persistência não relacionados

| Mecanismo | Onde | Armazena |
|---|---|---|
| Plist, `NSPropertyListBinaryFormat_v1_0` | `MADDataTable.m:193-220`, `:135-191` | `name`, `columnKeys`, `columns` (metadados), `rowCounter`. **Nenhuma linha.** |
| arquivo sqlite `.maddb` | `MADDataTableFast.m` | dados reais das linhas, mais chaves específicas de `MADDataTableFast` (`urlFastCache`, `tag`, `bulkInsertLoop`, `sortDescriptorsSet`, `groupKeyIndexes`) |

`-cacheWithUrl:error:` na classe base é documentado como cache genérico, mas só
serializa *forma*, não *conteúdo*. `MADocument.m:413-414` deriva `urlDataTableCache` de
`[self.dataTable newFilenameMDCache]` (`<tag>.mdcache`) enquanto `MADDataTableFast` lê e
grava `<tag>.maddb` (`:340-343`). Duas extensões de arquivo, dois formatos, dois donos, uma tabela
lógica.

**Avaliado (Revisão 5) — passo 15, que pedia uma reconciliação. O enquadramento está errado, e
essa é a descoberta.** "O plist da base é somente metadados" é verdadeiro para a classe base e falso para
a família: cada subclasse estende `-copyPlist` / `-loadWithPlist:` com exatamente uma chave extra,
e essa chave *é* seu armazenamento.

| Classe | Armazenamento | Chave do plist que o carrega |
|---|---|---|
| `MADDataTable` | nenhum (abstrata) | `name`, `columnKeys`, `columns`, `rowCounter` |
| `MADDataTableVirtual` | `sortIndex`, um array de dicionários de linha (`MADDataTableVirtual.m:106-109`, `:89-104`) | `keySortIndex` — as próprias linhas |
| `MADDataTableFast` | o arquivo `.maddb` | `keyUrlFastCache`, `keyTag`, … — um *localizador* das linhas |

Então as linhas já fazem ida e volta pelo plist onde o plist é o armazenamento, e não podem onde
o armazenamento é um arquivo sqlite. Nem renomear ("chame de metadados") nem a alternativa ("coloque as linhas
nele") é certo para a família como um todo; a classe base são os metadados que *ambas* as subclasses
compartilham, e o mecanismo é por subclasse por design. As duas extensões também não são um conflito:
`MADocument` grava `<tag>.mdcache` (o plist) ao lado de `<tag>.maddb` (as linhas), e
`-loadFromCacheWithUrl:` lê o primeiro para encontrar o segundo — desde que a tag concorde, o que
ela faz, porque `-filename` (`MADocument.m:1397-1399`) é `fileURL.lastPathComponent`
`stringByDeletingPathExtension`, a mesma string que a inicialização usa como hash para a tag.

O que vale fazer, e não está feito aqui, é documentação em vez de reestruturação: nomear os
dois arquivos no diretório de cache de `MADocument` pelo que são, e dizer em `MADDataTable.h` que
`-copyPlist` retorna os metadados compartilhados e que uma subclasse com armazenamento próprio deve estendê-lo.
Essa é uma mudança de comentário sem comportamento a preservar, então pertence a uma passagem de documentação, não
aqui.

### 2.7 Tempo de vida do enumerador

`MADDataTableObjectEnumerator` mantém seu próprio `MADDatabaseSqlite3` + conexão + instrução
preparada, tudo construído em `-initWith...` (`:60-72`) e liberado em `-dealloc` (`:45-49`).
Portanto:

* Um enumerador mantém um handle de banco de dados e um descritor de arquivo vivos enquanto for retido
  — e `MADReportFormatter.m:449-502` mantém um por toda a duração de uma renderização de relatório.
* Qualquer mutação da tabela que descarte ou reconstrua a tabela (`-removeAllObjects`, `-dropTable`)
  invalida a instrução ativa em um enumerador pendente. Nada protege isso.
* Cada chamada `-objectEnumerator` / `-enumeratorFor...` aloca uma **nova conexão** para
  o mesmo arquivo (`:1139`, `:1158`, `:1186`, `:1202`). Enumerar duas vezes abre o sqlite duas vezes.

**Avaliado (Revisão 5) — passo 13, que pedia um par de conexões compartilhado por arquivo. Não
feito, e o motivo está no tempo de vida, não na contagem.** A conexão de inserção não pode ser compartilhada
de forma alguma: `MADDatabaseSqlite3 -endBulkInsert` termina fechando-a e anulando `_database`
(`:794-795`), e é por isso que `MADDataTableFast -removeAllObjects` reabre antes de descartar qualquer coisa
e por que as quatro mutações privadas fazem asserção quando conduzidas diretamente (é errado conduzi-las
diretamente — veja os testes da Revisão 5, que reabrem primeiro exatamente por isso). Um
"par" compartilhado teria, portanto, de ser uma conexão de *leitura* compartilhada mais uma conexão de escrita por
ciclo, o que economiza um handle, não dois.

E a economia é menor do que parece: toda conexão aqui abre
`SQLITE_OPEN_SHAREDCACHE` (`MADDatabaseSqlite3.m:220`), então os enumeradores já compartilham um
cache de páginas e um conjunto de bloqueios no arquivo. O que cada enumeração realmente custa é um
`sqlite3*` e um descritor de arquivo — real, mas não o custo de cache duplicado que o passo implica.

Contra isso, compartilhar a conexão de leitura *perderia* algo. Os enumeradores são mantidos por
toda a duração de uma renderização de relatório (`MADReportFormatter.m:449-502`), e `-removeAllObjects` descarta e
reconstrói a tabela por baixo deles; hoje um enumerador pendente é dono de sua instrução e de seu
handle, então os dois interferem apenas pelo arquivo. Entregar-lhes um handle compartilhado colocaria
essa interação dentro de uma única conexão, em uma classe cujas leituras não carregam bloqueio próprio.
O cenário para o qual projetar é o que a §2.7 já sinaliza — um enumerador ativo através de uma reconstrução
da tabela — e compartilhar conexões o piora, não o melhora. Deixado como está deliberadamente.

---

## 3. API pública vs. abstrações vazadas

### 3.1 Superfície declarada vs. implementação real

`MADDataTable.h` declara 30 métodos (mais as propriedades `name` / `columnKeys` / `sortDescriptors` /
`columns` / `rowCounter` / `tag`, duas das quais o protocolo de escrita re-declara —
veja §4.2). A classe base implementa 18 deles e faz stub de 12:

| Declarado em `MADDataTable.h` | Implementação da base (`MADDataTable.m`) | Virtual | Fast |
|---|---|---|---|
| `-addColumn:` | **asserção** `:365` | sobrescreve `:112` | sobrescreve `:431` |
| `-addRow:error:` | **asserção** `:369` | sobrescreve `:179` | sobrescreve `:504` |
| `-addRowWithDataForFieldKeys:` | **asserção** `:374` | sobrescreve `:197` | sobrescreve `:614` |
| `-sortUsingDescriptors:` | **asserção** `:378` | sobrescreve `:208` | sobrescreve `:634` |
| `-removeAllObjects` | **asserção** `:382` | sobrescreve `:225` | sobrescreve `:674` |
| `-objectAtRow:column:` | **asserção** `:386` | sobrescreve `:159` | sobrescreve `:834` |
| `-objectAtRow:` | **asserção** `:391` | sobrescreve `:151` | sobrescreve `:848` |
| `-columnsEnumerator` | **asserção** `:396` | sobrescreve `:149` | sobrescreve `:1123` |
| `-objectEnumerator` | **asserção** `:401` | sobrescreve `:148` | sobrescreve `:1127` |
| `-beginBulkInsert` / `-endBulkInsert` | no-op `:408-409` | no-op `:236-238` | sobrescreve `:1311`/`:1330` |
| `-allObjects` | `return @[]` `:414-417` | sobrescreve `:118` | sobrescreve `:1209` |
| `-objectAtRow:limit:` | `return @[]` `:419` | sobrescreve `:220` | sobrescreve `:1086` |
| `-count` / `-numberOfColumns` / `-numberOfRows` | `0` `:420-422` | sobrescreve `:122`, `:214`, `:216` | sobrescreve `:1216`, `:1220`, `:1222` |
| `-countByEnumeratingWithState:...` | `0` `:423-427` | sobrescreve `:140` | herda (0) |
| `-enumeratorForAllObjectsSorted*`, `-objectsForGroupKeys:`, `-dataForRow:error:`, `-enumeratorForKeyObjectsSorted` | `NSAssert(NO, @"Not implemented")` `:327-350` | **também** `NSAssert(NO)` `:31-54` | implementado `:1034`, `:1148`, `:1172`, `:1193`; `-dataForRow:error:` `:941` |

### 3.2 Vazamento 1 — a classe base não consegue expressar "abstrata"

Objective-C não tem `abstract`. Então a base costumava retornar **`YES` de `-addRow:error:`** e
**`nil` de todo leitor**. Uma subclasse parcialmente implementada, ou uma instância direta de `MADDataTable`,
aceitaria escritas silenciosamente e relataria sucesso, para depois não ler nada.

**Corrigido (Fase 0).** As nove operações de escrita/leitura que uma subclasse de armazenamento deve sobrescrever agora
abrem com `NSAssert(NO, @"%s must be overridden", __PRETTY_FUNCTION__)` (`MADDataTable.m:365`,
`:369`, `:374`, `:378`, `:382`, `:386`, `:391`, `:396`, `:401`), correspondendo ao grupo `:327-350`.
`-addRow:error:` retorna `false` em Release em vez de `true`, então mesmo com as asserções compiladas
fora ele não afirma mais que uma linha foi armazenada.

Dois grupos foram deliberadamente **deixados** como padrões silenciosos, porque para eles o silêncio é correto:

* `-beginBulkInsert` / `-endBulkInsert` (`:408-409`) — ganchos opcionais. Uma subclasse que não
  precisa do modo em lote pode legitimamente herdar o no-op.
* `-allObjects` (`:414-417`), `-objectAtRow:limit:` (`:419`), `-count` / `-numberOfColumns` /
  `-numberOfRows` (`:420-422`) e `-countByEnumeratingWithState:...` (`:423-427`) — estes
  retornam `@[]` / `0`, que é a resposta *verdadeira* para uma tabela sem linhas, e corresponde ao que
  `MADDataTableVirtual` retorna. Fazer asserção em `-count` transformaria uma resposta correta em um crash.

A metade restante deste vazamento — expressar a divisão no sistema de tipos em vez de por
asserção — é a Fase 1 (§4.2).

### 3.3 Vazamento 2 — um contrato de anulabilidade que já está quebrado

`MADDataTable.h:65` declara (dentro de `@protocol MADDataTableCursoring`):

```objc
- (nonnull NSArray *)allObjects;
```

`MADDataTableFast.m` costumava responder assim (`:1093-1096` antes desta revisão):

```objc
- (NSArray *)allObjects {
	// FIXME: Implement this.
	return nil;
}
```

Um método declarado `nonnull` retornando `nil` em uma subclasse e `@[]` / `[self.sortIndex copy]`
nas outras. Qualquer chamador que confiasse na anotação travaria — era o único `FIXME` da
família que contradizia um contrato de cabeçalho.

**Corrigido:** não há chamador de produção. Os únicos envios a `-allObjects` em uma tabela de dados
estão nesta suíte de regressão, e `MADDataTableRegressionTests.m` deliberadamente fixou o
`nil` em `testFastTableBulkInsertAllObjectsIsUnimplemented`. Então a anotação era uma armadilha
preparada para um chamador futuro, não um crash ativo.

**Corrigido:** `MADDataTableFast -allObjects` (`:1209-1214`) agora retorna toda linha via
`-objectAtRow:0 limit:numberOfRows`, e `@[]` para uma tabela sem colunas, correspondendo à
declaração `nonnull` e ao comportamento existente de `MADDataTableVirtual` (`:118-120`). O teste
que fixava o `nil` foi substituído por dois que verificam o contrato real.

### 3.4 Vazamento 3 — `-objectAtRow:column:` significa coisas diferentes por subclasse

As duas implementações discordam tanto sobre o significado de `row` quanto sobre o armazenamento consultado:

```objc
// MADDataTableVirtual.m:159-163 — reads the per-column store, applies the sort index
- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
	NSString *fieldKey = self.columnKeys[column];
	MADDataColumn *dataInColumn = self.columns[fieldKey];
	return [dataInColumn objectAtIndex:[self sortedIndexForIndex:row]];   // LOGICAL row
}
```

```objc
// MADDataTableFast.m:834-846 — reads the row dictionary, physical order
- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
	NSDictionary *objForRow = [self objectAtRow:row];
	if (objForRow == nil || column >= self.columnKeys.count) return nil;
	NSString *key = self.columnKeys[column];
	MADDataColumn *columnMetaData = self.columns[key];
	if (columnMetaData == nil) return nil;
	return objForRow[columnMetaData.identifier];      // PHYSICAL (sqlite) order
}
```

Observe também que a disciplina de limites difere: Virtual **não** faz verificação de limites em
`column` (`self.columnKeys[column]` lançará `NSRangeException` fora dos limites, capturado apenas pelo
`@try` em `-objectAtRow:`, não aqui) e nenhuma verificação de nil em `dataInColumn`; Fast faz ambas.

Mesmo seletor, dois conjuntos de semântica. `MADMySQL` chama isto em um loop apertado
(`MADDatabaseMySQL.m:88-92` e mais três sítios), então uma refatoração que unifique a semântica será
sentida pelo MySQL primeiro.

### 3.5 Vazamento 4 — `-dataForRow:error:` está implementado em uma subclasse e ausente na outra

**Esta seção estava errada na primeira revisão deste relatório.** Ela afirmava que
`MADDataTableFast` não implementa `-dataForRow:error:` e que o caminho de código de barras/impressão
portanto atingia o `NSAssert(NO)` da classe base. Isso é falso, e levou um leitor a um
caminho falso. A análise corrigida segue.

`MADDataTable.h:67` declara
`- (nullable NSDictionary<NSString *, id> *)dataForRow:(NSUInteger)rowID error:(NSError **)error;`
e a base a implementa como `NSAssert(NO, @"Not implemented: %s")` + `return nil`
(`MADDataTable.m:342-345`).

* **`MADDataTableFast` a implementa**, em `MADDataTableFast.m:941-1015`:

    ```objc
  - (NSDictionary <NSString *, MADResult *> *)dataForRow:(NSUInteger)cacheId
                                                   error:(NSError * __autoreleasing *)outError {
  ```

  É uma assinatura de duas linhas, que é o que a revisão anterior leu errado: o seletor quebra
  em uma segunda linha, e a segunda linha foi tomada por uma sobrecarga separada de `-dataForRow:column:`.
  (O verdadeiro `-dataForRow:column:error:` é um método diferente em `:866-932`.) A
  implementação é real, e a suíte de regressão já a cobre --
  `MADDataTableRegressionTests.m` `testFastTableDataForRowReturnsValues` e
  `testFastTableDataForRowCachesLastRow` ambos enviam o seletor de dois argumentos a um
  `MADDataTableFast` ativo e passam.

* **`MADDataTableVirtual` não implementa nenhuma forma.** Ela tem um stub `-dataForRow:` em
  `:41-44`, mas esse stub é `NSAssert(NO, @"Not implemented: %s")` + `return nil` — não é
  uma sobrecarga funcional, e não é declarado em `MADDataTableVirtual.h`. A
  forma de dois argumentos cai na base que faz asserção. Então a subclasse em memória não tem
  acesso linha por id de forma alguma.

Os sítios de chamada, portanto, não estão em risco: `MADocument.m:875/880/919` despacham para
`MADocument.dataTable`, que é tanto estaticamente quanto de fato um `MADDataTableFast`
(`MADocument.m:159`, alocado em `:230` e `:288`). Os caminhos `MADPrintPageElement.m:80` e
`MADPrintPageElementBarcode.m:30` alcançam o mesmo objeto. Nada em um caminho ativo faz asserção.

O defeito real é mais estreito e agora está corrigido: como `MADDataTableVirtual` nunca
implementou o seletor, qualquer chamador futuro que mantivesse um `MADDataTable *` que por acaso fosse
uma tabela Virtual teria feito asserção em Debug e recebido silenciosamente `nil` em Release.
`MADDataTableVirtual` agora implementa `-dataForRow:error:` delegando a `-objectAtRow:`
e relatando o caso fora de faixa através do ponteiro de erro.

A implementação de `MADDataTableFast` também tinha um defeito genuíno, agora corrigido: seu
`if (sqlite3_prepare == SQLITE_OK)` **não tinha `else`**, então uma falha de preparação retornava `nil`
sem definir `*outError`, e o erro de `-getSql:` era descartado. Seu irmão
`-dataForRow:column:error:` (`:905-932`) trata ambos corretamente. O SQL também era passado a
`sqlite3_mprintf` como a string de *formato* (`sqlite3_mprintf((char *) sql.UTF8String)`), o que
corrompe ou trava em SQL contendo `%`; agora é `sqlite3_mprintf("%s", ...)`, correspondendo
ao irmão em `:901`. Mais oito sítios em `MADSqlite3` tinham o mesmo defeito; todos estão agora
corrigidos — veja §4.5.

### 3.6 Vazamento 5 — `MADDataTableFast` alcança a ivar privada de outra classe

`MADDataTableFast.m` acessa a ivar privada `_database` de `MADDatabaseSqlite3` diretamente em
quinze sítios — `:488`, `:538`, `:784`, `:793`, `:810`, `:829` (através de `_databaseForInserts`)
e `:905`, `:976`, `:1065`, `:1078`, `:1106`, `:1108`, `:1248`, `:1251`, `:1261` (através de
`databaseForSelects`):

```objc
sqlite3 *sqlite_database = _databaseForInserts->_database;                       // :451
NSAssert(prepareResult == SQLITE_OK, @"%s", sqlite3_errmsg(databaseForSelects->_database)); // :1008
```

Isto contorna inteiramente a API de `MADDatabaseSqlite3` e é o motivo de `MADDataTableFast` precisar de um
arquivo sqlite real para fazer qualquer coisa. É também por isso que o alvo de teste precisou do
trabalho de importação do módulo `MADDataTable+Constructor`: a família de classes só é utilizável em código que
vincula os dois frameworks juntos.

### 3.7 Vazamento 6 — API pública morta — **removida (Revisão 5)**

`MADDataTableLocation` (`MAD/Source/MADDataTableLocation.{h,m}`, 67 linhas) era um
objeto de valor `(row, column)` com `NSCoding` e uma fábrica `+newDataTableLocationForRow:inColumn:`.
Fiz grep em todo o código excluindo sua própria implementação: **suas únicas referências
estavam no arquivo de teste de regressão.** Ela estava morta em produção. Também adotava `NSCoding`, mas não
`NSSecureCoding`, o que a suíte de regressão registrava como um contrato.

O passo 14 da Fase 5 oferecia uma escolha — ligá-la a um recurso ou excluí-la. Ela foi excluída, porque
não havia recurso esperando por ela: um commit em toda a sua história (`e702bb062`, a
reorganização do framework `MAD`), nenhum chamador, e nada além de seus próprios três testes descrevendo para que
servia. Uma classe mantida viva apenas por seus testes é uma classe que os testes pagam duas vezes.
Os arquivos, suas duas entradas de compilação no `.pbxproj` e os três testes se foram com ela; a §3.7 permanece
como Vazamento 6 em vez de ser renumerada, para que a numeração citada pelo resto do relatório se mantenha.

### 3.8 Vazamento 7 — a tabela alcança *de volta* a consulta de escrita

`MADDataTableFast` conforma-se privadamente a quatro protocolos
(`:71`):

```objc
@interface MADDataTableFast () <MADQueryParametersStandardProtocol,
                                MADQueryParametersColumnKeysProtocol,
                                MADQueryParametersColumnMetaProtocol,
                                MADQueryParametersColumnDataProtocol>
```

e implementa `-queryTableName` / `-queryColumnKeys` / `-queryColumns` / `-queryRowData`
(`:419-430`) puramente para que `MADQueryCacheAddRow` possa puxar estado de volta da tabela na qual está
escrevendo. O caminho de inserção é, portanto, um ciclo: tabela → objeto de consulta → de volta à tabela. Observe o
risco de colisão de nomes — `-queryRowData` (`:428`) e a propriedade privada `_rowDataLastInserted`
não têm relação com a família pública `-dataForRow:`.

### 3.9 O que *não* está vazado (preserve isto)

* Toda seleção de subclasse está em `MADDataTable+Constructor.m:51-69`.
* A porta de escrita são cinco métodos da classe base (§1.4).
* As classes enumeradoras são privadas de `MADSqlite3` e só aparecem como `NSEnumerator *`.
* `MADReportFormatter.m:463-472` já tolera enumeração apenas de ids de linha.
* `MADArrayCaching` (`MADSqlite3`) é arte anterior neste código para uma abstração de cache com
  uma superfície mais estreita e moldada por protocolo.
* Nenhuma sondagem de classe em tempo de execução em tabelas, em lugar algum.

---

## 4. Estratégia de desacoplamento e refatoração

O objetivo é tornar `MADDataTable` uma *interface estável* sobre estratégias intercambiáveis de armazenamento e acesso,
sem mudar o comportamento do qual os cinco drivers e quatro consumidores já dependem.

### 4.1 Forma alvo

Mantenha os nomes das classes (eles estão gravados em arquivos `NSCoding` e no Core Data), mas mova a
variação para trás de dois protocolos que os construtores retornam:

```
                    ┌─────────────────────────────────────┐
                    │  MADDataTable        (concrete base) │
                    │  metadata, plist persistence,        │
                    │  NSCoding, — no-op defaults removed   │
                    └──────────────┬──────────────────────┘
                                   │
        ┌──────────────────────────┴───────────────────────────┐
        │                                                       │
  MADDataTableVirtual                                   MADDataTableFast
  (unchanged semantics)                          (sqlite; owns a connection pair)

  Both conform to:
     <MADDataTableWriting>   removeAllObjects / addColumn: /
                             begin|endBulkInsert /
                             addRowWithDataForFieldKeys:
     <MADDataTableReading>   objectAtRow: / objectAtRow:column: /
                             count / numberOfRows
     <MADDataTableCursoring> enumeratorForKeyObjectsSorted /
                             enumeratorForAllObjectsSorted /
                             enumeratorForAllObjectsSortedRowIdOnly
```

`MADDatabaseSqlite3.m:474-540` e `MADDatabaseSQLServer.m:500-1472` devem receber
`id <MADDataTableWriting>` em vez de `MADDataTable *`. Só isso remove o perigo de "a classe base
retorna YES de uma escrita que descartei" de todo driver.

### 4.2 Plano sequenciado

**Fase 0 — tornar os modos de falha ruidosos (sem mudança de comportamento).**
1. **Feito**, com um escopo mais estreito que o proposto inicialmente. As nove operações que uma subclasse de armazenamento
   deve sobrescrever agora fazem asserção (`MADDataTable.m:365-403`); as respostas honestas de tabela vazia
   e os ganchos de lote opcionais foram deixados como padrões, porque para eles o valor silencioso
   é o *correto*. Veja §3.2 para a divisão e o raciocínio, e
   `MADDataTableRegressionTests.m` `testBaseTableAbstractOperationsAssert` para o contrato.
2. **Não necessário — veja §3.5.** O texto original aqui dizia para implementar
   `MADDataTableFast -dataForRow:error:` porque ele "atualmente faz asserção". Ele não faz; o
   método está implementado em `:941-1015`, e a leitura anterior confundiu uma assinatura de duas linhas
   com uma sobrecarga de `column:`. A subclasse que realmente faltava com o seletor é
   `MADDataTableVirtual`, e ela agora o implementa delegando a `-objectAtRow:`.
3. **Feito.** `-allObjects` (§3.3) era um método `nonnull` retornando `nil` em
   `MADDataTableFast`; agora retorna as linhas. Na mesma passagem
   `MADDataTableFast -dataForRow:error:` ganhou o `else` ausente em sua verificação de prepare, e
   não descarta mais o erro de `-getSql:` nem passa SQL a `sqlite3_mprintf` como a string de
   formato.
4. Reverificar contra a suíte de regressão existente (`MADDataTableRegressionTests.m`) — ela
   já fixa instanciação, enumeração e concorrência, então detectará um erro aqui.
   (Ela também fixava o contrato de `MADDataTableLocation` até a Revisão 5 excluir a classe.)

**Fase 1 — declarar os protocolos.**

5. **Feito — o bloco de stub foi deliberadamente mantido.** Os três protocolos são declarados em
   `MADFoundation/Source/MADDataTable.h` acima do `@interface`, que agora lê
   `MADDataTable : NSObject <NSCoding, NSFastEnumeration, MADDataTableWriting,
   MADDataTableReading, MADDataTableCursoring>`, e as trinta declarações planas de método que
   costumavam ficar no corpo do `@interface` saíram dele. A divisão é por eixo: **Writing**
   é a superfície mutável (`removeAllObjects`, `addColumn:`, `addRow:error:`,
   `addRowWithDataForFieldKeys:`, `sortUsingDescriptors:`, mais `@optional`
   `beginBulkInsert`/`endBulkInsert`); **Reading** é acesso aleatório e as contagens;
   **Cursoring** é enumeração, com os três enumeradores ordenados e
   `objectsForGroupKeys:` `@optional` porque `MADDataTableVirtual` genuinamente não consegue servi-los.

   O "excluir o bloco de stub agora redundante" do plano **não** foi executado, porque ambos
   os blocos de stub são contratos fixados, não redundância:
   `testBaseTableAbstractOperationsAssert` exige que os nove stubs de asserção da classe base
   existam e lancem, e `testVirtualTableDoesNotImplementSortedEnumerators` verifica que
   `-respondsToSelector:` é **YES** para os quatro seletores exclusivos do sqlite em
   `MADDataTableVirtual`. Excluir qualquer um teria transformado um defeito capturado em um crash
   de seletor não reconhecido e quebrado um teste que existe especificamente para evitá-lo.
   `MADDataTable` satisfaz os membros `@required` dos protocolos fazendo asserção, que é o que a
   Fase 0 colocou ali.

6. **Feito (Revisão 4) — todos os três drivers e o protocolo.** O bloco abaixo é o relato da Revisão 3
   sobre por que isto estava bloqueado; é mantido para o registro. O desbloqueio que ele identificou foi
   tomado: os metadados de coluna de que `MADMySQLFetch+DataTable.m` precisa (`columns`, `columnKeys`) agora são
   declarados pelo próprio `<MADDataTableWriting>`, então a porta de escrita é suficiente para o MySQL também.
   Os dois métodos `fetchWithCommand:dataTable:...` de `MADMySQLFetch` e seu
   `-fetchResultsFromConnection:intoDataTable:...` privado recebem `id <MADDataTableWriting>` por valor e
   retornam a mesma tabela (`(MADDataTable *)dataTable`); todos os 11 sítios de chamada em
   `MADDatabaseMySQL.m` e os 7 em `MADMySQLLiveTests.m` perderam seu `&`. Os metadados foram
   colocados no protocolo de escrita em vez de um quarto porque o MySQL os lê *enquanto escreve* —
   ele corrige o tipo de uma coluna na primeira linha — e porque todo conformador o recebe de graça da
   classe base. O `// FIXME: This is a hack.` da §2.5 está intocado.

   *Texto da Revisão 3, para o registro:* **parcialmente feito — dois drivers de três, e a declaração do protocolo
   deliberadamente não estreitada.** `MADDatabaseSqlite3`
   (`executeSQL:...intoResultTable:`,
   `executeQuery:withDataTable:andError:`, `executeQuery:withError:`) e
   `MADDatabaseSQLServer` (os mesmos dois, mais o `-runQuery:onProcess:withDataTable:` privado
   e `-runSQL:onDataTable:fieldKeys:process:`) agora recebem `id <MADDataTableWriting>`. Ambos são
   genuinamente somente escrita: o `grep` do que eles enviam à tabela retorna exatamente a porta de cinco chamadas
   e nada mais.

   **`MADDatabaseMySQL` não pode ser estreitado ainda**, e tampouco
   `MADAPI/Source/MADDatabaseProtocol.h:28-31`. O obstáculo não está no driver — está em
   `MADMySQLFetch+DataTable.m`, que lê `(*dataTable).columns` e `.columnKeys` *enquanto*
   preenche a tabela, para corrigir o tipo de uma coluna assim que vê a primeira linha
   (`:301` e `:321`, sob o `// FIXME: This is a hack.` existente em `:297`). Uma porta de escrita que
   não expõe os metadados de coluna, portanto, não é suficiente para esse caminho. Como
   `MADDatabaseMySQL` conforma-se a `MADDatabaseDataSource` e deve continuar a fazê-lo, estreitar
   o protocolo o teria feito prometer algo que sua própria implementação não pode cumprir —
   um crash remoto para o próximo chamador, não um erro de compilação. Ambas as declarações carregam um comentário
   apontando para aqui.

   **O desbloqueio concreto, encontrado ao verificar isto:** `MADMySQLFetch+DataTable.m` nunca
   atribui através de seus parâmetros de saída `MADDataTable * __autoreleasing *` —
   `grep -n '\*dataTable *=' MADMySQL/Source/MADMySQLFetch+DataTable.m` não retorna nada. O
   ponteiro é um parâmetro de entrada que os chamadores nunca souberam. Torná-lo por valor
   (`dataTable:(id <MADDataTableWriting>)dataTable`) remove o problema de tipo de ponteiro
   por completo e permite que os 11 sítios de chamada em `MADDatabaseMySQL.m` removam seu `&`. Isso, mais
   adicionar os acessores de metadados de coluna a `<MADDataTableWriting>` ou a um quarto protocolo,
   é tudo o que resta para o MySQL. Fica adiado em vez de agrupado porque
   a §4.3 já classifica o MySQL como o consumidor de maior risco, e a mudança é mecânica o suficiente
   para ser revisada por si só.

7. **Agora possível para sqlite, não provado para MySQL.** O loop de linhas de `MADDatabaseSqlite3` pode ser
   conduzido por qualquer objeto que conforme a `<MADDataTableWriting>` sem nenhum arquivo `.maddb` e nenhum
   app delegate, já que o parâmetro não implica mais a classe `MADDataTable` — e,
   por meio dela, a dependência de `-urlFastCache` em `[MADApplication AppDelegate]` descrita na
   §2.3. Nenhum teste mock foi escrito ainda; é o próximo passo natural e a primeira
   coisa que o diretório de cache injetado da Fase 2 torna mais barata.
   **Revisão 4:** a metade sem host está provada — `testFastTableInitWithCacheDirectoryNeedsNoDelegate`
   constrói uma tabela física funcional com um diretório e nenhum delegate.
   **Revisão 5: feito, ambas as metades.** `testDriverFillsAWritePortWithNoDataTableBehindIt`
   (`MADSqlite3Tests/MADDatabaseSqlite3DatabaseTests.m`) entrega ao loop de linhas um
   `MADWritePortRecorder` — um `NSObject` que conforma a `<MADDataTableWriting>` e nada mais,
   então nenhum `MADDataTable`, nenhum `MADDataTableFast`, nenhum delegate de cache, nenhum `.maddb` — e verifica que as
   cinco chamadas chegam na ordem prometida com ambas as linhas intactas, falhando se qualquer arquivo `.maddb`
   aparecer. O mock só é expressável porque o parâmetro é o protocolo.

**Fase 2 — remover a ambiguidade do local de armazenamento. FEITO (Revisão 4).**
8. ✅ Tornar `urlFastCache` armazenada, não calculada (§2.3). Resolvida uma vez em `_urlFastCache`; uma
   troca de delegate a descarta em `-setCacheDelegate:` antes de reabrir, então a resolução é sempre
   contra o delegate atual.
9. ✅ Injetar o diretório de cache em vez de recorrer a `[MADApplication AppDelegate]` dentro
   da propriedade. `-initWithId:cacheDirectory:` e
   `+newDataTableOfType:withObjectID:cacheDirectory:` o carregam; `nil` mantém a cadeia antiga.
   `testFastTableInitWithCacheDirectoryNeedsNoDelegate` constrói, preenche e lê uma tabela física
   sem delegate algum.

**Fase 3 — tornar `rowCounter` derivado.**
10. ✅ Adicionar um `-recountRows` privado respaldado por `SELECT COUNT(*)`, e fazer `-numberOfRows`/`-count`
    usá-lo (ou invalidar contra ele) em `MADDataTableFast`. Manter a propriedade `rowCounter` para
    compatibilidade de arquivo, mas parar de tratá-la como a fonte da verdade (§2.5).
    **Revisão 4:** `-recountRows` existe e executa ao final de `-loadWithPlist:`, então uma tabela
    recarregada não pode mais carregar um contador que discorde de seu arquivo.
    **Revisão 5:** a metade em memória está fechada — as quatro mutações que nunca tocavam o
    contador agora o deixam descrevendo o arquivo (§2.5). `-numberOfRows`/`-count` ainda retornam a
    ivar por design; esse é agora o único leitor, e `-recountRows` protege o recarregamento.
    Quatro testes cobrem os quatro métodos.
11. ✅ Auditar `MTTableController.m` (era `:375/395/440/445`) — a paginação não deve ler um contador que
    possa divergir do arquivo. **Feito (Revisão 5)**, e não pode, uma vez que o contador seja honesto:
    toda busca começa em `-removeAllObjects`, que limpa a tabela e zera o contador, então
    a contagem na conclusão mede a página recém-escrita e nada mais. Dois defeitos nessas
    linhas exatas foram encontrados e corrigidos de qualquer forma. `offset + count - 1` estourava para `NSUIntegerMax` em uma
    página vazia em `:380`/`:402`; e o caminho de falha em `:449` lia a contagem de uma tabela que o
    driver *não* havia limpado (ele limpa apenas em caso de sucesso), então media a página anterior, e uma
    busca falha relatava `hasMore = YES` e se reemitia. Uma página falha agora relata que não há mais.

**Fase 4 — corrigir a concorrência.**
12. ✅ Serializar `-addRow:error:` em `queueBulkAdd` (§2.4). A fila já existe e já é
    usada para `-endBulkInsert`; estendê-la ao caminho de mutação é uma mudança pequena e contida.
    Mover o `sqlite3_finalize(_statementInsert)` em `-endBulkInsert` para *dentro* da
    barreira para que a instrução em cache só seja destruída quando nenhuma `-addRow:` está em andamento.
    **Feito (Revisão 4)** — a destruição agora é a primeira coisa dentro do
    `dispatch_barrier_sync` em `:1334`.
13. **Avaliado e recusado (Revisão 5)** — um par de conexões compartilhado por arquivo em vez de por
    instância de tabela, já que `-objectEnumerator` atualmente abre uma nova conexão a cada chamada
    (§2.7). O compartilhamento não está disponível para a metade de escrita (`-endBulkInsert` fecha aquele handle) e
    compra quase nada para a metade de leitura (`SQLITE_OPEN_SHAREDCACHE` já compartilha o cache),
    enquanto piora o caso de enumerador ativo através de uma reconstrução em vez de melhorá-lo. A §2.7 tem o
    argumento completo.

**Fase 5 — aposentar a superfície morta.**
14. ✅ Excluir `MADDataTableLocation` (§3.7) e seus três testes, ou ligá-la a um recurso real.
    Ela atualmente é API pública sem chamador de produção. **Removida na Revisão 5** — excluída
    em vez de ligada, porque tem um commit em sua história e nada além de seus próprios testes
    descrevendo-a. As fases Headers e Sources do alvo MAD descartam os dois arquivos com ela.
15. **Avaliado (Revisão 5)** — reconciliar os dois mecanismos de persistência (§2.6). A premissa
    não vale para a família: as linhas *fazem* ida e volta pelo plist onde o plist é
    o armazenamento (`keySortIndex` de `MADDataTableVirtual`), e não podem onde ele é um arquivo sqlite
    (`keyUrlFastCache` de `MADDataTableFast`), então nem renomear nem a alternativa é certo.
    A §2.6 registra a tabela por subclasse e a mudança de documentação que resta fazer.

### 4.3 Classificação de quebra para os consumidores atuais

| Consumidor | Sítio | Risco sob refatoração |
|---|---|---|
| `MTTableController` | `:249, :281, :284, :377, :393, :399, :449, :455` | **Alto** — trata `count` como cursor de página; qualquer mudança na semântica de `rowCounter` quebra a paginação. A Revisão 5 tornou a derivação total — uma página vazia não sofre mais underflow e uma busca falha não lê mais a contagem da página anterior (§2.5) — mas o acoplamento não mudou |
| `MADDatabaseMySQL` | `:88-92, :118-122, :150-154, :187-189` | **Alto** — `objectAtRow:i column:0` O(n); a semântica de `row` por subclasse deve ser unificada primeiro |
| `MADocument` | `:197` (`rowCounter`), `:865-867` (enumerador), `:874-919` (`dataForRow:error:`), `:1053-1072` | **Alto** — mas apenas para o enumerador e `rowCounter`. Seus envios de `-dataForRow:error:` resolvem para `MADDataTableFast`, que implementa o seletor, então o caminho de impressão/código de barras é sólido (veja §3.5) |
| `MADMySQLFetch+DataTable` | `:301, :321` | **Médio** — muta `column.type` no meio da busca atrás de `// FIXME: This is a hack.` (`:297`); o dicionário de coluna deve permanecer publicamente mutável |
| `MADQuerySampleDataTable(Range)` | `:118, :126` / `:123, :131` | **Baixo** — sonda de largura única `objectAtRow:0` |
| `MADReportFormatter` | `:449-502` | **Baixo** — tolerante tanto à enumeração de ids de linha quanto à de dicionários |
| `MADDatabaseSQLServer` | `:500, :1367, :1472` | **Baixo** — somente escrita pela porta de cinco métodos |

### 4.4 Restrições a respeitar

* **Não mude os valores brutos de `MADDataTableType`.** `MADDataTableParametersType` é codificado
  em dicionários de definição (`MTTableController.m:91`, `MTTableViewControllerBarcodeExtraMaxicode.m:104`)
  e o enum é serializado via `initWithShort:`.
* **Não renomeie as classes.** Os arquivos de `MADDataTableFast` carregam
  chaves no estilo `[MADDataTableFast keyTag]` (`:114-119`) e `MADDataTableVirtual` carrega
  `keySortIndex` (`:202`) em arquivos `.mdcache`/`.maddb` existentes.
* **Mantenha a porta de escrita de cinco métodos.** Todos os três drivers dependem da sequência exata
  `removeAllObjects → addColumn: → beginBulkInsert → addRowWithDataForFieldKeys: → endBulkInsert`.
* **Nenhuma sondagem de nome de classe foi introduzida.** Preserve isso: qualquer novo ramo deve ser sobre
  um protocolo ou um enum, nunca sobre uma classe.

### 4.5 SQL passado a `sqlite3_mprintf` como string de formato

Encontrado ao corrigir §3.5. Oito outros sítios de chamada entregavam uma variável a `sqlite3_mprintf` como a
string de *formato* em vez de como argumento. Qualquer `%` no SQL seria então lido como uma
conversão, então uma consulta contendo um é corrompida — ou lê além da lista de argumentos e trava.

**Corrigido.** Todos os oito agora passam um literal `"%s"` e o SQL como argumento, correspondendo aos sítios
que já estavam corretos:

| Arquivo | Sítios |
|---|---|
| `MADSqlite3/Source/MADDataTableFast.m` | `:1062`, `:1102`, `:1245` |
| `MADSqlite3/Source/MADDatabaseSqlite3.m` | `:301`, `:397`, `:875` |
| `MADSqlite3/Source/MADDataTableObjectEnumerator.m` | `:69` |
| `MADSqlite3/Source/MADDataTableSingleColumnEnumerator.m` | `:64` |

Os sítios de referência já corretos eram `MADDataTableFast.m:548`, `:901` e `:973`, e
`MADDatabaseSqlite3.m:459`. Toda chamada `sqlite3_mprintf` em `MADSqlite3` agora usa um
literal `"%s"` ou uma string de formato literal sem conversões — `grep -n
sqlite3_mprintf MADSqlite3/Source/*.m` retorna quatorze chamadas e nenhuma string de formato variável.

A alcançabilidade era baixa: o SQL vem dos construtores de consulta gerados, e uma busca em todo o repositório
não encontrou nenhum padrão `LIKE` que introduzisse um `%`. Os identificadores, porém, vêm do
esquema do banco de dados conectado, então um `%` em um nome de coluna ou tabela teria atingido isto. Era um
bug latente de correção, não um ativo — corrigido porque a mudança é mecânica e a
consequência de estar errado é corrupção silenciosa.

---

## Apêndice — Arquivos examinados

| Arquivo | Linhas |
|---|---|
| `MADFoundation/Source/MADDataTable.h` / `.m` | 123 / 435 |
| `MADFoundation/Source/MADDataTableVirtual.h` / `.m` | 21 / 240 |
| `MADFoundation/Source/MADDataTableType.h` | 17 |
| `MADFoundation/Source/MADDataColumn.h`, `MADDataProtocol.h`, `MADCacheProtocol.h` | — |
| `MADSqlite3/Source/MADDataTableFast.h` / `.m` | 47 / 1355 |
| `MADSqlite3/Source/MADDataTableObjectEnumerator.m` | 173 |
| `MADSqlite3/Source/MADDataTableSingleColumnEnumerator.m` | 149 |
| `MADSqlite3/Source/MADQueryCacheAddRow.m` | 152 |
| `MADSqlite3/Source/MADDatabaseSqlite3.m` | 1346 |
| `MAD/Source/MADDataTable+Constructor.h` / `.m` | 30 / 94 |
| `MAD/Source/MADocument.m`, `MADReportFormatter.m` | — |
| `MADMySQL/Source/MADDatabaseMySQL.m`, `MADMySQLFetch+DataTable.{h,m}` | — |
| `MADTdsClient/Source/MADDatabaseSQLServer.m` | — |
| `MADAPI/Source/MADDatabaseProtocol.h`, `MADQuery.h`, `MADDatabaseResultsProtocol.h` | — |
| `MADDesigner/Source/MTTableController.m` | — |
| `MAD/MADTests/MADDataTableRegressionTests.m` | 69 testes |
