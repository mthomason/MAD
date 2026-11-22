---
layout: default
title: "MADArrayCaching"
description: "O array em disco, somente anexação, por trás do cache de renderização de relatórios."
lang: pt-BR
---

# `MADArrayCaching`

Esta página descreve o `MADArrayCaching`, o array em disco somente anexação usado como cache de renderização do relatório.

*Escrito na data original; fatos do estado atual reconciliados em 2026-11-22.*

Um array ordenado, somente anexação e em disco, usado como **cache de renderização** do relatório. Escrito
em 2026-10-01 contra `master` em `7ebe82f89`.

---

## O que é

`MADArrayCaching<ObjectType>` (em `MADSqlite3`) é uma subclasse de `NSEnumerator` que se comporta como
um `NSMutableArray` cujos elementos vivem em disco em vez de na memória. Cada elemento é serializado
com `NSKeyedArchiver` e armazenado como um BLOB em um arquivo SQLite. É a classe por trás dos
arquivos complementares `.madac` em `MAD_FORMAT.md` §5.

Duas instâncias por documento, ambas de propriedade do `MADReportFormatter`:

| Sufixo do identificador | Contém | Tipo do elemento |
|---|---|---|
| `…ih{w,h}` | os **índices** de página (quais linhas caem em cada página) | `NSArray<NSNumber *>` |
| `…lh{w,h}` | os **layouts** de página (representações de seção por página) | `NSArray<MADSectionRepresentation *>` |

`MADReportFormatter` os preenche com `beginBulkInserts` / `addObject:` / `endBulkInserts` e
os lê de volta com `objectAtIndex:` / `objectAtIndexedSubscript:`. Este é o cache de renderização —
os ~15 MB de arquivos `.madac` em um cache do Music — e é o que permite que uma nova renderização pule o recálculo
do layout de página.

## Formato em disco

`<identifier>.madac` é um arquivo SQLite comum com uma tabela:

| Coluna | Tipo | Significado |
|---|---|---|
| `ci` | INTEGER, chave primária | o índice do elemento (0, 1, 2, …) |
| `ck` | BLOB | o elemento serializado pelo `NSKeyedArchiver` |

O arquivo fica no diretório de cache do documento, nomeado por
`[self.identifier stringByAppendingPathExtension:@"madac"]` (`MADArrayCaching.m:269-274`), onde
`identifier` é o `layoutIdentifier` do formatador + `ih`/`lh` + o tamanho da página.

## API

`initWithIdentifier:cachedDelegate:types:` — `cachedDelegate` fornece o diretório de cache via
`MADCacheProtocol`, `types` é o conjunto de classes que o `NSKeyedUnarchiver` pode decodificar.

Em seguida: `initializeDatabase` (abrir, criar a tabela se ausente), `addObject:` (anexar),
`objectAtIndex:` / `objectAtIndexedSubscript:` (ler), `beginBulkInserts` / `endBulkInserts`
(transação em torno de muitas anexações), `removeAllObjects`, `finalizeDatabase` e os acessores `count` /
`state` / `identifier`.

## Por que é rápido (o design está correto)

- **Instruções preparadas.** As instruções de inserção, seleção e contagem são compiladas uma vez
  (`prepareStatement*`) e re-vinculadas a cada chamada — sem nova análise.
- **Consultas indexadas.** `ci` é a chave primária, então `objectAtIndex:` é um `SELECT ck WHERE ci = ?`
  — uma sondagem de índice O(1), não uma varredura.
- **Inserções em lote em uma transação.** `beginBulkInserts` / `endBulkInserts` envolvem as anexações, então
  uma renderização completa é um único commit em vez de um fsync por página.
- **Um cache de memória por elemento.** `objectAtIndex:` armazena em cache cada elemento que desarquiva (com chave pelo
  índice), então uma leitura repetida — o padrão normal do renderizador — é uma consulta a `NSDictionary` sem
  ida e volta ao SQLite e sem desarquivamento. `lastObjectSelected` permanece para `nextObject`.
- **Duas filas serializadas** (`archivingQueue`, `unarchiveQueue`) mantêm a única conexão SQLite
  com um escritor e um leitor.

O custo dominante é a serialização do `NSKeyedArchiver` / `NSKeyedUnarchiver`, não o SQLite — o
cache de renderização passa seu tempo empacotando grafos `MADSectionRepresentation`, que é o mesmo
trabalho que o formatador faria de qualquer forma.

## Problemas encontrados

Itens 1–4 corrigidos em 2026-10-01; itens 5–6 permanecem abertos e são registrados em vez de corrigidos (o
enumerador é código morto, e a armadilha de concorrência é latente enquanto o formatador é
single-threaded).

1. **`-isEmpty` está invertido.** `MADArrayCaching.m:440` é
   `return _numberOfRows > 0;` — ele retorna YES quando o cache *tem* linhas. É código morto
   (nenhum chamador), então é uma armadilha latente, não um bug ativo. **Corrigido**, e exposto como
   propriedade somente leitura.
2. **`-count` retorna 1 para um cache vazio.** `MADArrayCaching.m:424-438` calcula a contagem como
   `max(ci) + 1`, mas quando a tabela está vazia o `SELECT … ORDER BY ci DESC LIMIT 1` retorna
   `SQLITE_DONE`, e `sqlite3_column_int64` em uma instrução concluída lê lixo; o resultado é 1
   em vez de 0. **Corrigido.**
3. **`-readDataAtIndex:` e `-writeData:` estão mortos.** Não estão no cabeçalho, sem chamadores. São um
   caminho residual de `NSData` bruto substituído por `addObject:`. `readDataAtIndex:` também mistura tipos:
   em um acerto de `lastObjectSelected` ele retorna o objeto *desarquivado*, não `NSData`. **Excluídos.**
4. **As constantes de tabela/coluna estão duplicadas.** `MTArrayCachedTableName` / `…ColumnKey` /
   `…ColumnValue` / `…Extension` são declaradas `static` em `MADArrayCaching.m` e re-declaradas
   globais em `MADArrayCachingEnumerator.m`. Um cabeçalho deveria ser o dono delas. **Corrigido** — as
   declarações `extern` agora vivem em `MADArrayCaching.h` com as definições em
   `MADArrayCaching.m`.
5. **`MADArrayCachingEnumerator` usa o desarquivador antigo.** Ele chama o método obsoleto
   `unarchiveObjectWithData:` (não seguro) onde `MADArrayCaching` usa
   `unarchivedObjectOfClasses:`. E seu `nextObject` reinicia a instrução após cada passo, então
   a iteração manual nunca avança (a enumeração rápida via `countByEnumeratingWithState:` não é
   afetada). **Ainda aberto** — a classe não tem chamadores.
6. **`_numberOfRows` é lido fora da fila.** `addObject:` lê `_numberOfRows` antes do
   `dispatch_*`, então anexações concorrentes colidiriam em um índice. O formatador as chama
   em single-thread hoje, então é latente. **Ainda aberto.**

## Melhorias sugeridas

Em ordem de valor:

1. Corrija `-isEmpty` e `-count` (duas correções de uma linha) e exclua o par morto
   `readDataAtIndex:` / `writeData:`. Seguro para o comportamento: as duas primeiras são correções de bugs, a
   segunda é código morto com um bug de tipo.
2. Mova as constantes `MTArrayCached*` para um único cabeçalho que ambos os arquivos importem.
3. Atualize o `MADArrayCachingEnumerator` para o mesmo desarquivador do `MADArrayCaching` e corrija ou
   remova seu `nextObject` quebrado.
4. Somente se o profiling mostrar: substitua o `NSKeyedArchiver` por um serializador mais leve e específico para cache
   e/ou elimine o `dispatch_sync` por leitura em favor de uma chamada direta quando a fila já for
   própria. Estas são as alavancas de "realmente rápido"; os itens de correção acima vêm primeiro.
