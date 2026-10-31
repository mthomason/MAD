---
layout: default
lang: pt-BR
---

## 5. O que *não* está no documento: os arquivos complementares

Um arquivo `.mad` é uma definição, não um conjunto de dados. Tudo o que um relatório *exibe* é derivado,
regenerável e deliberadamente mantido fora do arquivo compactado. Três tipos de arquivo são gerados ao lado dele:

| Arquivo | Gravado por | O que armazena |
|---|---|---|
| `<hash>.maddb` | `MADDataTableFast` | os dados de linhas do relatório |
| `<hash>.mdcache` | `MADDataTable` (`:354`) | uma plist descrevendo as tabelas virtuais sobre esses dados |
| `<hash>{ih,lh}{w, h}.madac` | `MADArrayCaching`, alimentado por `MADReportFormatter` (`:179`, `:183`) | conteúdo de página renderizado — um banco de dados **SQLite**, indexado pelo identificador de layout e pelo tamanho da página. `ih` é o cache de *índice* do relatório, `lh` é o cache de *layout* do relatório |

Os três ficam juntos em um diretório por documento, nomeado por `dataTableIdHash`.
`MADocument.m:286-300` constrói a tabela a partir de um diretório fornecido por
`MADURLFactory newURLCacheFilesDirectoryForFilename:` (`MADURLFactory.m:47-49`), que
resolve para um local por usuário e por dispositivo fora do documento:

```objc
MADDataTableFast *datatable = [[MADDataTableFast alloc] initWithId:dataTableIdHash];
...
NSURL *cacheUrl = [self newUrlCacheForFilename:cacheName];
self.urlDataTableCache = cacheUrl;
[datatable loadFromCacheWithUrl:cacheUrl error:&error];
```

### 5.1 Os tamanhos não são o que o nome sugere

Valores medidos em um diretório real de cache em `Library/Caches/`:

| Tipo | Arquivos | Total |
|---|---|---|
| `<hash>.maddb` | 1 | 816 KB |
| `<hash>.mdcache` | 1 | 1,7 KB |
| `<hash>{ih,lh}{...}.madac` | 6 | **~15 MB** |

Os arquivos `.madac` são o cache de páginas do formatador. As chaves `ih` e `lh` vêm de
`MADReportFormatter.m:179` e `:183`, que montam `<layoutIdentifier>ih<CGSize>` e
`<layoutIdentifier>lh<CGSize>`; `{612, 792}` equivale ao tamanho US Letter em pontos. Portanto, o cache é
indexado pela *identidade do layout e pela geometria da página* — o que torna reais as duas armadilhas
descritas na §5.3.

Comparado a um documento de menos de 80 KB, o cache de renderização tem aproximadamente **200× o tamanho do documento**. Os
dados de linhas, que poderiam parecer o maior volume, representam menos de 6% do diretório.

**Por que ele é deliberadamente desse tamanho.** O tamanho é consequência do projeto arquitetural, não um
acidente a ser otimizado. Há duas razões, ambas descritas pelo próprio autor (2026-10-01):

1. **Renderização em duas passagens (two-pass rendering).** A contagem de páginas e os agrupamentos não podem ser conhecidos até que todo o conjunto de
   linhas esteja disponível. Um grupo de contagem no rodapé do relatório pode ser somado ao final, mas um
   no cabeçalho do relatório precisa ser conhecido antes que a primeira página seja diagramada — e as páginas
   não podem ser numeradas até que a contagem de linhas seja conhecida —, de modo que todo o conjunto de resultados é buscado
   uma única vez e mantido no dispositivo.
2. **O cache é a plataforma para visualizações futuras.** Uma vez que as linhas estão armazenadas localmente, diferentes
   visualizações dos mesmos dados podem ser construídas a partir de um único cache sem consultar novamente a
   fonte, ao contrário de um site web que consulta o banco de dados a cada página. Há
   mais recursos planejados sobre esse mesmo cache, portanto tratá-lo como mero espaço temporário descartável seria
   um erro.

O cache poderia ser comprimido, mas essa não é uma mudança prioritária no momento.

### 5.2 As consequências

- Um `.mad` é **pequeno e autocontido**: é uma definição, não um conjunto de dados. Ambos
  os exemplos distribuídos têm menos de 80 KB.
- Tudo no diretório de cache é **descartável**. Apagá-lo custa apenas uma nova atualização (`refresh`),
  nunca a perda de um documento.
- Ele **não é compartilhado** entre dispositivos e não fica no iCloud, mesmo que o documento esteja lá.
  Cada dispositivo busca os dados novamente na primeira abertura.
- Portanto, o `.mad` **não** é um "arquivo SQLite comprimido com os dados dentro", como poderia
  parecer à primeira vista. É um arquivo SQLite comprimido com a *definição* dentro.

### 5.3 O que os arquivos complementares ainda não definem

O diretório é nomeado e populado pelo código, mas não possui especificação formal. Há três lacunas que uma
segunda plataforma teria de adivinhar:

1. **O cache de renderização é indexado pelo nome do arquivo, não pelo conteúdo — confirmado em 2026-10-01.**
   `MADReportFormatter -layoutIdentifier` (`MADReportFormatter.m:186`) retorna
   `_overrideIdentifier ? _overrideIdentifier.hash : _filename.hash`. Assim, a chave é o
   *nome* do documento mais o tamanho da página, e nada no caminho de carregamento verifica o conteúdo:
   `MADArrayCaching -initializeDatabase` (`MADArrayCaching.m:141`) reutiliza o arquivo SQLite
   existente sempre que sua tabela `ac` está presente, sem versão, timestamp ou hash de conteúdo
   em lugar algum da chave ou do carregamento. **Editar um documento mantendo o mesmo nome de arquivo
   não invalida seus arquivos `.madac`** — uma página defasada continua sendo exibida até que os arquivos sejam
   apagados ou que um tamanho de página diferente seja renderizado.

   **Medido em 2026-10-01, consistente com esse comportamento.** Uma atualização e exportação headless foram
   executadas contra o documento London às 15:22. No diretório de cache logo após:

   | Arquivo | Tamanho | mtime |
   |---|---|---|
   | `<hash>.maddb` | 835.584 | 15:22 |
   | `<hash>.mdcache` | 1.644 | 15:22 |
   | `<layoutId>ih{612, 792}.madac` | 81.920 | 15:22 |
   | `<layoutId>lh{612, 792}.madac` | 737.280 | 15:22 |
   | `<layoutId>ih{0, 0}.madac` | 1.867.776 | **10:52** |
   | `<layoutId>lh{0, 0}.madac` | 4.333.568 | **10:52** |

   Uma atualização regrava apenas os arquivos de que precisa — as entradas `{612, 792}` (US Letter, a
   geometria de página do PDF) — e deixa o restante intacto. As entradas `{0, 0}` não foram tocadas e,
   juntas, somam 6,0 MB dos 15 MB do diretório. `{0, 0}` é o tamanho de página antes de uma
   geometria real ser conhecida, portanto esses dois arquivos são quase certamente resultado de uma passagem de medição;
   sob o esquema indexado por nome de arquivo, eles também nunca são invalidados por nada além da
   exclusão manual.
2. **Nada define o que pode ser excluído.** Todos os três tipos são regeneráveis, então todos os três
   deveriam ser seguros para exclusão — mas um `.maddb` de 0 bytes em um diretório de resto intocado mostra que o
   diretório é criado antes de ser preenchido, e nada especifica se tal
   diretório vazio tem algum significado.
3. **O esquema da plist `.mdcache`.** Agora conhecido — trata-se do esquema serializado da tabela de
   resultados, gravado por `MADDataTableFast -copyPlist` e lido por `-loadWithPlist:`. Chaves de nível
   superior: `name`, `columnKeys` (array ordenado de IDs `c<hash>`), `columns` (um dicionário indexado por
   `c<hash>`, sendo cada item uma plist `MADDataColumn`: `caption`, `fieldName`, `identifier`, `type`,
   `nativeType`, `dataLength`, `dataPercision`, `isPrimaryKey`, `isNotNull`,
   `isAutoIncrement`, `defaultValue`), `rowCounter`, `sortDescriptors` e o valor
   `bulkInsertLoop` da tabela rápida. `defaultValue` usa a sentinela `~MTNull~`
   (`MADDataColumnNullSentinel`, `MADDataColumn.m:23`). Observe duas peculiaridades persistentes:
   `dataPercision` está grafado incorretamente no formato, e a sentinela `~MTNull~` é um terceiro marcador de nulo,
   distinto da família `"<null>"` / `"(null)"` documentada em `docs/project/BUGS.md` Track 1.5.
