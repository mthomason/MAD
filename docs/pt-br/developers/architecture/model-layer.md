---
layout: default
title: "A camada MADModel"
description: "O modelo de leitura do documento sobre as entidades Rptq e como ele é mantido atualizado."
lang: pt-BR
---

# MADModel — a camada de modelo de leitura do documento

Esta página descreve o `MADModel`, o modelo de leitura sobre as entidades `Rptq`: o que é cada classe, como ela é populada e mantida atualizada, e quem a lê.

*Escrito na data original; fatos do estado atual reconciliados em 2026-11-22.*

**Escopo:** `MAD/Source/model/MADModel*.{h,m}`, `MAD/Source/model/MADTableFieldIdentifier.{h,m}` e todo
consumidor da camada em `MAD` e no `MAD Designer`.
**Data:** 2026-10-16, lido em `d7faff320`.
**Status:** referência. Tudo aqui foi lido em primeira mão nesse commit; os candidatos a refatoração da §7
são propostas e não estão aplicados.

---

## 1. O que a camada é

`MADModel*` é uma **visão somente leitura, no escopo do documento, da definição do documento** — a
conexão, o esquema (tabelas e campos) e o grafo de consulta (quais tabelas a consulta usa,
quais campos e as junções entre elas). É a ela que a interface de consulta do designer se vincula.

Ela *não* é o modelo canônico. O modelo canônico é o grafo de objetos `Rptq*` no
armazenamento portátil: é o que o aplicativo edita, salva, converte e renderiza. Um objeto `MADModel*` é
pouco mais que **um identificador de linha do armazenamento (`int64_t`) mais um ponteiro fraco para o
`RptqStoreContext` mais alguns valores de exibição copiados**, resolvidos sob demanda buscando linhas com
`objectsForEntity:identifier:`.

A regra prática que o código segue:

> **Escreva através de `Rptq`; leia e observe através de `MADModel`.**

As duas camadas compartilham um espaço de identificadores: o `identifier` de um objeto de modelo *é* o
`identifier` da linha do armazenamento. Essa é toda a cola — veja §3.

```
MADModelDocument                       one per open .mad — MADocument.documentModel
 └ databases: [MADModelDatabase]       (today: exactly one)
    ├ driverID / driverType / schemaName   ← RptqDatabase + RptqDatabaseCredentals
    ├ tables / tableDictionary : {id → MADModelTable}      ← RptqDatabaseSchemaTable
    │   └ MADModelTable  (name, queryable)
    │      └ fields / fieldIDs : {id → MADModelField}      ← RptqDatabaseSchemaField
    │         └ MADModelField (name, dataType, decimals, width, primaryKey)
    └ queries: [MADModelQuery]         (today: exactly one; `firstQuery` everywhere)
       └ MADModelQuery
          ├ queryTableIDs / tables : {id → MADModelQueryTable}   ← RptqQueryTable
          │   └ MADModelQueryTable  (schemaTable id, dropIndex, alias)
          │      └ queryFields : {id → MADModelQueryField}       ← RptqQueryField
          │         └ MADModelQueryField (schemaTable + schemaField ids)
          └ queryLinkIDs / links : {id → MADModelQueryLink}      ← RptqQueryLinks
              └ MADModelQueryLink   (left/right table+field ids — one join)
```

## 2. As classes

### 2.1 `MADModel` — identidade (`MADModel.h`, `MADModel.m`)

A classe base é apenas identidade: `_uid` (`MADModel.m:32-64`), com `hash`, `isEqual:` (mesma
classe e mesmo `_uid`) e `-objectID` retornando o id em um `NSNumber`.
`+[MADModel newModelDocument:]` (`MADModel.m:35`) é a fábrica nominal — nada a chama;
`MADocument` aloca `MADModelDocument` diretamente. `MADModelType.h` define
`MADModelTypeUnknown/Document/Database/Queries`; nada na árvore usa o enum.

O nome `objectID` e um `debugDescription` comentado que formata
`_objectID.URIRepresentation` são a pista da idade da camada: os objetos costumavam envolver
`NSManagedObjectID`s (veja §5).

### 2.2 `MADModelDocument` — a raiz (`MADModelDocument.h`, `.m`)

- Criado uma vez por documento aberto por `-MADocument.documentModel`
  (`MADocument.m:389-395`), sob demanda, sobre `self.storeContext`. Nada mais em produção
  constrói um; o app delegate não tem parte nisso.
- Contém `databases` (construído por `-updateDocumentDatabaseQuery`, `MADModelDocument.m:210-240`:
  um `MADModelDatabase` *por linha `RptqQuery`* — "banco de dados" aqui significa a conexão mais seu
  esquema mais uma consulta) com acessores de conveniência `firstDatabase` / `firstQuery`. O código
  diz por que o plural é teatro: *"as versões atuais do software usam apenas um banco de dados e
  consulta"* (`MADModelDocument.m:207-208`).
- **Registra-se para as notificações de mudança do armazenamento** (`RptqStoreContextObjectsDidChange`,
  `WillSave`, `DidSave`, `MADModelDocument.m:160-176`) em uma `NSOperationQueue` privada
  (`MADModelDocument.m:83-87`, `_objectContextQueue`). Na inserção/exclusão de uma linha `RptqQueryTable`
  ou `RptqQueryLinks`, ele espelha a mudança em `firstQuery` — veja §3.3.
- `-update` (`MADModelDocument.m:201-205`) reexecuta a varredura documento→banco de dados→consulta e
  *substitui* `_databases` por novos objetos.

### 2.3 `MADModelDatabase` — conexão, esquema e consultas (`MADModelDatabase.h`, `.m`)

- Com chave pelo identificador da linha `RptqDatabase`.
- Os metadados são resolvidos *através do armazenamento, uma propriedade de cada vez*: `driverType`
  (`MADModelDatabase.m:157-164`), `schemaName` (`:166-173`) e `driverID` (`:175-182`) cada um
  busca sob demanda o `RptqDatabase` e lê através de `RptqDatabaseCredentals`. `schemaName`
  e o `driverName` quebrado (§6) ambos respondem com o `dbname` das credenciais.
- `tables` / `tableDictionary` (`-updateTables`, `MADModelDatabase.m:221-247`) listam toda
  `RptqDatabaseSchemaTable` cujo `inDatabase` corresponde, **ordenada por nome** — restaurando a
  ordenação que uma busca anterior à migração aplicava, com um comentário apontando para BUGS.md.
- `queries` (`-updateQueries`, `:249-261`) faz o mesmo para linhas `RptqQuery`.

### 2.4 `MADModelTable` / `MADModelField` — o esquema (`MADModelTable.{h,m}`, `MADModelField.h`)

- `MADModelTable` armazena em cache `name` e constrói sob demanda `fields` / `fieldIDs`
  (`MADModelTable.m:120-146`) a partir de linhas `RptqDatabaseSchemaField` cujo `inTable` corresponde,
  ordenadas por nome. `MADModelField` é um valor simples: nome, sinalizador de chave primária, tipo de dados,
  tipo nativo, casas decimais, largura — sem acesso ao armazenamento.

### 2.5 `MADModelQuery` — uma consulta (`MADModelQuery.h`, `.m`)

A maior classe, e a que realmente justifica sua existência. Ela possui:

- `queryTableIDs` + `tables` (`MADModelQuery.m:213-283`): todo `RptqQueryField` cujo
  `inQueryTable.inQuery` é esta consulta é projetado para um dicionário
  (`MADStoreProjectionForQueryField`, `:59-68`) — a forma exata que as projeções de busca
  antigas do Core Data produziam — e alimentado em `-insertTablesFromFetchRequestResults:`.
- `queryLinkIDs` + `links` (`:302-344`): o mesmo para `RptqQueryLinks`
  (`MADStoreProjectionForQueryLink`, `:70-78`).
- Auxiliares de topologia: `-tablesInLinks` (`:183`) e `-orphanedQueryTables` (`:196`, as tabelas
  que nenhum link toca, via uma subtração de conjuntos com `NSExpression`).
- **A superfície de mutação**: `-insertQueryTable:` / `-insertQueryLink:` /
  `-deleteQueryTableID:` / `-deleteQueryLinkID:` e as variantes baseadas em id. Cada uma aplica a
  mudança às coleções e então reenvia `MADNotificationQueryTableInsert/Delete` ou
  `MADNotificationQueryLinkInsert/Delete` (nomes em `MADModel.h:22-26`) **na fila principal**
  via `[NSOperationQueue mainQueue] addOperationWithBlock:`, com o objeto de modelo afetado no
  `userInfo`. Essas notificações são o fluxo de eventos público da camada; o designer
  se inscreve nelas (§4).

### 2.6 `MADModelQueryTable` / `MADModelQueryField` — as tabelas e campos da consulta

- `MADModelQueryTable` (`MADModelQueryTable.m`) armazena em cache `dropIndex` e o id da tabela **de esquema**,
  e mantém sob demanda `queryFields` / `queryFieldIDs` (construídos por `-addField:schemaField:`, `:92`).
  `-alias` (`:119-129`) é o nome voltado ao SQL: o nome da tabela de esquema para a primeira cópia e
  nome + índice de descarte depois (`Customer`, `Customer0`, …).
- `MADModelQueryField` (`MADModelQueryField.m`) são dois ids: a tabela de esquema e o campo de esquema.
  `-schemaField` (`:52-57`) resolve os metadados reais caminhando
  banco de dados → `tableDictionary[schemaTable]` → `fields[schemaField]`. Essa cadeia —
  link → tabela de consulta → tabela de esquema → campo de consulta → campo de esquema — é o padrão
  definidor da camada; `MADQueryVisualizationViewController.m:1024-1048` a executa à mão para posicionar um
  conector.

### 2.7 `MADModelQueryLink` / `MADTableFieldIdentifier`

- `MADTableFieldIdentifier` (`MADTableFieldIdentifier.{h,m}`) é um pequeno par de valores
  (id de tabela + id de campo) com acessores `NSNumber`.
- `MADModelQueryLink` (`MADModelQueryLink.m`) contém um `MADTableFieldIdentifier` para cada extremidade,
  construído a partir de ids brutos ou de uma linha `RptqQueryLinks` (`-initWithRptqQueryLink:`,
  `:60-76`, que lê `hasLeftField.inQueryTable.identifier` / `hasLeftField.identifier`).
  `-isAdjacentToQueryTable:` (`:78`) e `-tables` (`:82`) respondem às perguntas de grafo que a
  visualização faz.

### 2.8 Os protocolos e as peças vestigiais

- `MADModelIDProtocol` — quatro linhas: `identifier` (`MADModelIDProtocol.h`).
- `MADModelDataProtocol` (`MADModelDataProtocol.h`) — `managedObjectContext`,
  `-initWithIdentifier:managedObjectContext:` e `-update`. Na prática `-update` é um
  gancho interno de atualização: é chamado apenas pelos próprios getters sob demanda da camada
  (`MADModelDocument.m:188`, `MADModelTable.m:99` e `:115`). `MADModelDatabase -update`
  (`MADModelDatabase.m:148`) e `-MADModelQuery -update` (`MADModelQuery.m:354`, um método vazio)
  não têm chamador algum.

## 3. Ciclo de vida

### 3.1 Criação

`MADocument` constrói um `MADModelDocument` sob demanda (`MADocument.m:389-395`) e o mantém durante
toda a vida do documento. Ele mantém o `RptqStoreContext` **fraco**
(`MADModelDocument.m:42`), como todo objeto de modelo que mantém um contexto — o contexto do armazenamento é
de propriedade do documento.

### 3.2 População

Tudo abaixo do documento é **sob demanda e armazenado em cache**: a primeira leitura de `databases`, `tables`,
`fields`, `queryTableIDs`, `queryFields` ou `links` dispara uma passagem de busca e filtragem
(`objectsForEntity:` sobre a entidade Rptq relevante, filtrada pelo identificador do pai, depois
ordenada onde uma busca anterior à migração ordenava). Os caches só são invalidados chamando
`-update` ou pelo caminho de notificação abaixo; nada expira por conta própria.

### 3.3 Mudanças ao vivo — a ida e volta

Adicionar uma tabela ou um link no designer grava **linhas Rptq** (por exemplo, o fluxo de adicionar tabela em
`MADQueryViewController.m:745-790` cria linhas `RptqQueryTable` + `RptqQueryField` e salva
o contexto). O modelo então se atualiza sozinho:

```
user adds a table / link
  → RptqQueryTable / RptqQueryLinks rows written + saved
    → RptqStoreContextObjectsDidChangeNotification
      → MADModelDocument's observer (on its private queue)     MADModelDocument.m:91-158
        → [firstQuery insertQueryTable:/insertQueryLink:]       MADModelQuery.m:361-410
          → MADNotification…Insert/Delete reposted on main      MADModelQuery.m:361-514
            → MADQueryVisualizationViewController, MADQueryBuilderAddTableViewController
```

Duas filas estão em jogo: o modelo *muta* em `_objectContextQueue` (uma
`NSOperationQueue` privada, `MADModelDocument.m:83-87`) e as notificações *chegam* na fila principal.
As coleções em si não são sincronizadas.

### 3.4 Obsolescência

`-update` (documento ou banco de dados) reconstrói coleções com **novos** objetos de modelo; qualquer objeto de modelo
entregue antes continua funcionando para o que armazenou em cache, mas não é mais o que está em
`firstQuery.tables`. Nada na árvore chama `-update` em um objeto de modelo hoje — o
caminho de notificação é o ativo — mas código que armazena objetos de modelo através de um `-update`
estaria lendo entradas obsoletas.

## 4. Consumidores

### 4.1 A aba Query (construtor de consultas ad hoc)

- `MADQueryViewDataSource.m:365` — a célula de cabeçalho da fonte de dados: "You are connecting to
  *driverID* datasource named *schemaName*" a partir de `firstDatabase`.
- `MADQueryViewDataSource.m:533-546` — a lista de tabelas da consulta pega `firstQuery` e usa
  `query.identifier` para filtrar linhas `RptqQueryTable`. Observe o padrão: **o modelo fornece
  identidade e metadados; as linhas em si são objetos Rptq.**
- `MADQueryTableViewController.m:163-174` — o título da caixa de uma tabela de consulta vem de
  `firstQuery.tables[id].alias`; `:186-200` e `:239-266` renderizam a lista de campos de esquema a partir de
  `firstDatabase.tableDictionary[schemaTableID]` → `fieldIDs` / `fields`. Este é todo o modelo de conteúdo
  do navegador de esquema.
- `MADQueryBuilderAddTableViewController.m:29-33` — observa as notificações de inserção/exclusão do modelo
  para manter seu painel de tabelas atual.

### 4.2 A aba Query Visualization (caixas e conectores)

- `MADQueryVisualizationModel` (`MADQueryVisualizationModel.m:40-77`) constrói um `MTGraph` via
  `-[MTGraph initWtthQueryID:]` (`MTGraph+RptqQuery.m:39-67`), que é escrito **inteiramente sobre
  o modelo**: `query.queryTableIDs` se tornam vértices, `query.links` se tornam arestas. Ele então
  ordena topologicamente, calcula `startingPoints` (tabelas para as quais nenhum link aponta *para dentro*) e armazena
  o sinalizador de DAG. (A mesma categoria também tem inicializadores baseados no armazenamento, `:69-93`, anteriores ao
  caminho de modelo; a visualização usa o do modelo.)
- `MADQueryVisualizationViewController` (`MADQueryVisualizationViewController.m`) é o principal
  consumidor do fluxo de notificações: ele se inscreve em todas as quatro notificações de modelo
  (`:314-335`), adiciona/remove caixas e conectores à medida que chegam, remarca tabelas raiz após uma
  exclusão de link usando `-orphanedQueryTables` (`:936`), pergunta `-linksForQueryTable:` por tabela
  (`:644`) e dispõe cada conector caminhando a cadeia de identificadores
  (`:1024-1048`, §2.6).
- `MADQueryVisualizationCacheManager` persiste o layout da tela com chave por identificadores de modelo
  (`updateCacheWithQuery:…`, `MADQueryVisualizationCacheManager.h:20`).

### 4.3 O documento e os testes

`MADocument.documentModel` é o único ponto de entrada de produção. Testes:
`MADDocumentTests.m:263-265` (`databases`/`queries` de um documento reaberto),
`MADDocumentTests.m:399-404` (a ordem de tabelas/campos de um `MADModelDatabase`), mais as suítes
dedicadas `MADModelQueryTableTests`, `MADModelQueryFieldTests` e a cobertura de `MADModelField` /
`MADModelQueryLink` em `MADModelValueTypesTests`.

### 4.4 O que *não* a usa

- **Geração de SQL** — `MADQueryFull` e as classes `Rptq*+Extras` trabalham na camada Rptq
  (por exemplo, `RptqQueryField+Extras.m:137` constrói nomes `table.field` a partir de `RptqQueryTable.alias`).
- **Layout e renderização** — `MADDesignerLayout` e o caminho do relatório trabalham em
  `RptqDocumentElement`; `MADReportFormatter` não usa a camada de forma alguma (suas três
  importações de `MADModel*` em `MADReportFormatter.m:18-20` estão obsoletas).
- **Dados de linha** — nada disso toca o cache `.maddb`; esse é território de `MADDataTableFast` /
  `MADReportFormatter`.

Então o escopo real da camada hoje é: **o lado de consulta do designer, e nada mais.**

## 5. Por que ela existe

A camada é do início de 2017 (cabeçalhos de arquivo `1/22/17`–`6/3/17`) e foi construída na era do Core Data
como um **modelo de visão feito à mão para a interface de consulta**: objetos leves aos quais as visões de tabela do designer
e a tela de visualização podiam se vincular, em vez de `NSManagedObject`s e
`NSFetchedResultsController`s. A evidência está nos arquivos: `-objectID`, a descrição de
depuração de `NSManagedObjectID` comentada em `MADModel.m:66-80`, e três comentários sobreviventes que
dizem "era um `NSFetchedResultsController`" (`MADQueryChooseFieldController.m:149`,
`MTGroupByViewController.m:53`, `MADTableViewControllerCoreDataResults.h:14`).

A migração do armazenamento (Fase C/D de `MAD_STORE_MIGRATION.md`) religou toda busca do Core Data
para `RptqStoreContext` + `objectsForEntity:` **sem mudar a superfície desta camada** — e é
por isso que a §Findings de `MIGRATION_KICKOFF.md` a chama de "[uma] camada de domínio `MADModel*` limpa [que]
já envolve as entidades `Rptq`; é a costura a manter."

Então é MVC de certo tipo, mas não "o modelo do aplicativo": é um **modelo de leitura por documento** (o
"modelo" do MVC como visto pelo controlador), e os objetos de domínio canônicos são o grafo Rptq. A
abstração compra três coisas e é fina em todo o resto: (1) o grafo de consulta em uma
forma moldada para exibição (aliases, adjacência, buscas de id para metadados) sem travessia de relacionamentos;
(2) um lugar que converte notificações de mudança do armazenamento em eventos do grafo de consulta;
(3) uma interface que a UI pôde manter intocada enquanto o armazenamento abaixo dela mudava completamente —
que é exatamente o que aconteceu.

## 6. Arestas ásperas conhecidas

Lidas em primeira mão; nenhuma delas tem consumidor hoje, então todas são latentes.

1. `MADModelField.inTable` (`MADModelField.h:20`) é declarado `weak MADModelField *` — o
   tipo está errado (deveria ser `MADModelTable *`) — e nada nunca o atribui.
2. Os outros ponteiros de retorno ao pai são igualmente inutilizados: `MADModelTable.inDatabase`,
   `MADModelQueryTable.inQuery` e `MADModelQueryField.inQueryTable` nunca são atribuídos por
   nenhum caminho de código na árvore. Apenas `MADModelQuery.inDatabase` é algum dia definido
   (`MADModelQuery.m:108-114`). (`-addField:schemaField:` não ligar o ponteiro de retorno do seu campo
   já está registrado em BUGS.md.)
3. `MADModelDatabase -driverName` (`MADModelDatabase.m:184-215`) termina em `return @"";`, então ele
   responde a string vazia mesmo depois de armazenar o nome real em cache; `-schemaName` já retorna
   a mesma string do mesmo lugar. Não existe leitor.
4. `MADModelDocument.m:228-234` decodifica um id de documento (`docID`) e nunca o usa.
5. `MADModelQuery -update` (`MADModelQuery.m:354`) é vazio; `MADModelDatabase -update` não tem
   chamadores; `+[MADModel newModelDocument:]` não tem chamadores.
6. `MADModelType` é inutilizado.
7. Sem sincronização entre a fila privada que muta o modelo e os leitores da thread principal;
   e `MADModelDocument` mantém o contexto do armazenamento fraco, então um modelo que sobreviva ao seu
   documento não tem contexto para resolver nada.
8. Nomenclatura: um `MADModelDocument` tem `databases`, e um `MADModelDatabase` tem `queries` — mas
   o documento constrói um "banco de dados" *por consulta* e hoje há exatamente um de cada. A
   estrutura é uma preparação para o futuro anterior à simplificação de um banco de dados/uma consulta.

## 7. Candidatos a refatoração (propostas — nenhuma aplicada)

Ordenados por valor sobre risco. A e B são pura arrumação; C muda o que um cabeçalho público promete;
D é uma decisão.

**A. Documentação, não consolidação.** O ganho de clareza mais barato são comentários de cabeçalho por classe
(2–4 linhas: o que a classe é, por que é chaveada, quem a lê) mais este documento. Fundir os
*arquivos* das classes é a opção cara, não a barata: mais de dezesseis arquivos importam os
cabeçalhos por classe (`#import <MAD/MADModelQueryField.h>` etc.), cada cabeçalho é um arquivo separado
nos alvos Xcode, e a cunha de include da compilação Linux é um diretório de links simbólicos por cabeçalho
(`Linux/README.md`, a cunha do MAD). Consolidar tocaria no pbxproj, nas listas de fontes Linux
e em todo sítio de importação por um ganho cosmético. Se alguma fusão for desejada, a direção segura é
a oposta: mantenha uma classe por arquivo e torne o **ponto de entrada** óbvio (documento no topo de
`MADModel.h`, "comece em `MADModelDocument`").

**B. Excluir ou completar a superfície vestigial.** Cada um destes é seguro para o comportamento (nada
os lê), mas toca cabeçalhos, então trate como uma decisão de API:
- `MADModelField.inTable`: corrija o tipo e defina-o em `MADModelTable -update` (uma linha,
  simétrica com os outros pais), ou exclua a propriedade.
- `MADModelDatabase -driverName`: retorne o valor armazenado em cache como seus irmãos, ou exclua-o.
- `MADModelType`: exclua o cabeçalho. (Requer a remoção do arquivo de projeto; faça em um commit.)
- `+[MADModel newModelDocument:]`: faça `MADocument -documentModel` usá-lo (restaurando
  o propósito da fábrica) ou exclua-o.
- A decodificação não utilizada de `docID` em `MADModelDocument.m:228-234`.

**C. Ligar os ponteiros de retorno declarados.** `inDatabase`, `inQuery` e `inQueryTable` existem para que o
grafo possa ser caminhado para cima; hoje apenas buscas para baixo funcionam. Atribuí-los na construção
(`MADModelDatabase -updateTables` já tem `self`; `insertTableRptqQueryTable:` tem a
consulta de modelo; `-addField:schemaField:` tem a tabela) faz o grafo de objetos corresponder aos seus cabeçalhos
e é seguro precisamente porque nada os lê ainda. Semântica a ter em mente: eles são
declarados `weak`, o que é correto para pais de propriedade descendente.

**D. Identidade através de atualizações (uma decisão, não uma arrumação).** `-update` substitui objetos; se
identidade estável através de atualizações for desejada, os métodos de atualização devem mutar no lugar
(reutilizar o objeto para um identificador, adicionar/remover a diferença) em vez de reconstruir. Isso
muda a identidade observável dos objetos entregues, então requer uma escolha deliberada.

**E. Deduplicação mecânica.** `MADModelTable.fields` e `-fieldIDs` (`MADModelTable.m:88-118`)
contêm o mesmo bloco de inicialização duas vezes, e os três getters de `MADModelQuery` repetem a
mesma dança de "garantir coleções, depois atualizar" (`MADModelQuery.m:116-181`). Ambos podem colapsar
em um auxiliar privado cada sem mudança de comportamento; vale fazer apenas quando o arquivo estiver aberto
para outra coisa.

**F. NÃO recomendado: renomear.** `MADModelDatabase` → algo como `MADModelConnection`
leria melhor, mas renomeações aqui são agitação em arquivos de projeto Xcode/Linux sem
retorno funcional.

## 8. Se você mudar esta camada

- Mantenha o contrato somente de identificadores: um objeto de modelo deve permanecer construível apenas a partir de ids
  (é disso que o caminho de notificação e os testes dependem).
- Qualquer coisa que crie ou exclua linhas `RptqQueryTable` / `RptqQueryLinks` é capturada pelo
  observador de `MADModelDocument` automaticamente — mas apenas para linhas alcançadas através de
  `firstQuery`; uma segunda consulta em um documento não é espelhada.
- Os quatro nomes `MADNotification…` são a API pública da camada para a interface; observe-os
  contra o objeto `firstQuery`, como faz `MADQueryVisualizationViewController`.
- A suíte iOS (esquema `MAD`) e `./Linux/build.sh` compilam ambos estes arquivos; veja
  `Linux/cmake/MADSources.cmake`.
