[English](README.md) | [简体中文](README_zh.md) | [日本語](README_ja.md) | **Português (Brasil)**

# Linux — o build da engine headless

`docs/project/MAD_LINUX.md` §9: a Fase B validou o toolchain (um Dockerfile que
compila a partir do código-fonte clang + libobjc2 + GNUstep Base e compilou um subconjunto
do MADFoundation); a Fase C corresponde à lista de shims da §4, e este diretório é onde ela vive.
O build agora compila **todos os onze frameworks headless** — cada framework da tabela
da §3 de `docs/project/MAD_LINUX.md` mais `MADPostgres`, exceto os exclusivos de interface gráfica (`MADExplorer`, `MADBarcodes`,
`MADFeedback`, `Scrimpter` e o aplicativo) — e executa suas suítes de teste dentro do
contêiner: 126 executáveis de teste, 1.303 testes e 7 `NEED`s registrados. A cobertura
de testes mesclada na `master` em 2026-10-10 (~100 arquivos de teste do Xcode) foi portada na
íntegra, suíte por suíte. Nada daqui é embarcado no aplicativo iOS/macOS; a CLI — marco da
Fase D — também compila e roda aqui (veja "A CLI roda aqui — Fase D" abaixo), e
a imagem de runtime da Fase F a executa como artefato final ("A imagem de runtime — o entregável da CLI (Fase F)" abaixo).

## Executando

	./Linux/build.sh              build the image, run the tests, exit with the result
	./Linux/build.sh --test       run the tests in the existing image
	./Linux/build.sh --runtime    build the runtime image (mad-cli:latest)
	./Linux/build.sh --verify     build the runtime image, then verify the CLI in it
	./Linux/build.sh --probe      run only the toolchain probe, with its report
	./Linux/build.sh --info       print clang and gnustep-config from the image
	./Linux/build.sh --shell      interactive shell in the build image
	./Linux/build.sh --toolchain  build only the toolchain image (the cache base)
	./Linux/build.sh --rebuild    rebuild without cache
	./Linux/build.sh --clean      remove both images

A CLI do Docker Desktop não fica no `PATH` por padrão em alguns ambientes; `build.sh` a localiza em
`/Applications/Docker.app/Contents/Resources/bin` e a adiciona (junto com o
credential helper ao lado dela) ao `PATH` durante a execução. O primeiro build leva de
15 a 25 minutos (o estágio do toolchain) e produz uma imagem de ~2,5 GB; execuções seguintes
usam o cache — apenas a camada de código-fonte é recompilada. A verificação cruzada com `--platform linux/amd64`
foi executada ponta a ponta após a entrada da cobertura completa de testes
(2026-10-11, antes da Fase D): toda a imagem compila sob emulação e a execução coincidiu
exatamente com o arm64 nativo. Hoje esse processo é realizado continuamente pelo
build de CI, que compila a imagem nativamente em amd64
(ubuntu-latest) e executa `--verify` a cada push na `master` — e o
workflow de publicação envia o estágio de runtime dessa mesma plataforma. Caso queira rodar localmente em amd64, use uma tag
separada (`MAD_LINUX_IMAGE=mad-linux:phase-b-amd64 ./Linux/build.sh
--platform linux/amd64`) para não sobrescrever a imagem nativa.

## Versões fixadas (Pins)

`toolchain.conf` é o único lugar onde a versão, a origem
e o hash de cada componente do toolchain são declarados, no mesmo formato de `Compressor/matrix.conf`; fontes
git fixam tanto a tag de release *quanto* o commit exato do checkout, e os tarballs do
GNUstep trazem valores sha256 calculados a partir de `ftp.gnustep.org`.

	libobjc2      2.3      v2.3                 (github.com/gnustep/libobjc2)
	libdispatch   6.1.3    swift-6.1.3-RELEASE  (github.com/apple/swift-corelibs-libdispatch)
	gnustep-make  2.9.3    ftp.gnustep.org tarball
	gnustep-base  1.31.1   ftp.gnustep.org tarball

A combinação de bibliotecas (library-combo) é `ng-gnu-gnu` com ABI de runtime `gnustep-2.2`, de modo que tudo
é compilado com `-fobjc-runtime=gnustep-2.2` e ARC habilitado.

## A camada de bibliotecas C

`libraries.conf` + `lib/libraries.sh` compilam nativamente as bibliotecas C que os frameworks
vinculam, instalando-as em `/usr/local` (`docs/project/MAD_LINUX.md` §7), seguindo a mesma estrutura e propósito da
matriz do `Compressor`.

	sqlite3      3.53.3   the released amalgamation; the option list still comes
	                      from Compressor/sqlite3.xcconfig, the one place it lives
	openssl      3.5.9    static, before freetds
	freetds      1.4.27   --enable-msdblib, apps/server/pool/odbc off, and the
	                      recipe's sybdb.h BOOL edit (spelled for GNU sed)
	zlib         1.3.2
	bzip2        1.0.8    CC=clang: its Makefile hardcodes gcc
	libarchive   3.8.9    the .mad container's tar/bzip2 path
	mariadb      3.4.11   the mariadbclient static target, openssl + external
	                       zlib, auth plugins static, others off (mirrors
	                       Compressor/lib/recipes/mariadb.sh)
	postgres     17.11    the libpq static client library + libpgcommon/libpgport,
	                       with openssl, without readline/icu/gssapi/ldap/pam/xml/
	                       xslt/lz4/zstd/zlib (mirrors Compressor/lib/recipes/postgres.sh)

Duas dependências externas de build permanecem na imagem base como herança do antigo build do mysqlclient
(`libncurses-dev` e `libtirpc-dev`, exigidas pelo cmake do MySQL); o build do MariaDB
não as utiliza, mas elas permanecem na imagem.

## O que é compilado e o que fica de fora

| Framework | Build Linux | Excluído, e por quê |
|---|---|---|
| MADFoundation | 26 de 27 | `MADKeyChain` (Security.framework; §4 — o caminho de atualização nunca lê o Keychain). O cabeçalho umbrella sai junto |
| MADDataStructures | todos os 17 | (os arquivos do target do Xcode; `madmap.cpp` também não faz parte dele) |
| MADFileManager | 10 de 11 | `MADCloudFileCoordinator` (NSMetadataQuery; §4 — sem iCloud no modo headless) |
| MADCocoaExtensions | 7 de 17 | os dez componentes gráficos de UIKit (cores, rótulos, campos de texto, alertas, helpers de view, apresentador de erros, MessageUI) |
| MADAPI | 8 de 11 | os três view controllers de conexão (§3: não são headless) |
| MADSqlite3 | todos os 26 | (cinco arquivos `.m` órfãos também não estão no target do Xcode) |
| MADTds | todos (1) | |
| MADTdsClient | 4 de 5 | seu view controller de conexão |
| MADMySQL | 18 de 19 | seu view controller de conexão |
| MADPostgres | 5 de 6 | seu view controller de conexão |
| MAD | 150 de 181 | a camada de interface (§5.2), `MADocument` + as operações que criam/fecham um documento de UI, as operações de Keychain e os arquivos de elemento baseados em `MADBarcodes`. Todos estão listados em `cmake/MADSources.cmake` |

A lista de fontes de cada framework fica em um arquivo `cmake/<Name>Sources.cmake` ao lado do
build, com as exclusões nomeadas e justificadas — no mesmo formato de
`MADFoundationSources.cmake`. `MADExplorer`, `MADBarcodes`, `MADFeedback` e
`Scrimpter` não entram no build Linux (`docs/project/MAD_LINUX.md` §3).

O build Linux fornece o que falta no GNUstep sem poluir o código-fonte dos
frameworks:

* um shim de include por framework para resolver autoimportações no formato `<Framework/…>`
  (o do MAD é um diretório de links simbólicos, pois o target do Xcode achata seus
  cabeçalhos como `<MAD/Foo.h>`), mais quatro shims de cabeçalhos de bibliotecas
  (`<MADSqlite3/sqlite3.h>`, `<MADTds/sybdb.h>`, o umbrella do MADTdsClient e
  `<MADPostgres/libpq-fe.h>`);
* um cabeçalho de prelúdio (`Compat/MADCompat.h`) contendo as lacunas de plataforma que são
  macros ou typedefs;
* vinculação whole-archive (equivalente ao `-ObjC` da Apple), sem a qual as
  categorias Objective-C dos frameworks seriam descartadas silenciosamente das bibliotecas estáticas;
* `-lgnustep-base` antes de `-lobjc` na linha de link: o libobjc2 exporta um símbolo weak
  `objc_enumerationMutation()` que chama abort, enquanto o GNUstep Base exporta a implementação real
  que lança exceção, vencendo a primeira biblioteca listada na linha de comando.

Os próprios frameworks receberam pequenas guardas de plataforma, todas com `#if __APPLE__`,
de modo que os caminhos de código da Apple permanecem textualmente inalterados. As suítes de teste no macOS e no simulador comprovam
que o comportamento é neutro: MADFoundation, MADDataStructures, MADFileManager,
MADCocoaExtensions, MADAPI, MADSqlite3, MADMySQL, MADTdsClient, MADPostgres
e MAD continuam todos verdes, e o workspace `MAD Designer` compila integralmente.

## Os drivers são registrados, não importados diretamente

Antigamente o construtor importava diretamente os drivers, o que criava uma dependência circular entre `MAD` ↔ drivers
(`docs/project/ROADMAP.md` §5.1). Agora o ponto de desacoplamento é `MADDatabaseDriverRegistry` (`MADAPI`): a classe
de conexão de cada driver adota `MADDatabaseDriver` e registra a si mesma em
`+load`, enquanto `MADDatabase+Constructor` / `MADDatabaseConnection+Constructor` buscam o
driver por `MADDatabaseType` em vez de referenciar classes concretas. Assim, quais drivers um processo possui
depende exclusivamente do que ele *vincula (links)*.

Em plataformas Apple, o binário hospedeiro vincula os frameworks de driver — o aplicativo e a CLI listam MADMySQL,
MADTdsClient e MADPostgres, e o `MAD.framework` não depende mais deles diretamente. No Linux, as bibliotecas estáticas dos drivers são vinculadas com **whole-archive** a partir do target `mad`
(`$<LINK_LIBRARY:WHOLE_ARCHIVE,…>`, propagando-se para todos os consumidores): como uma biblioteca
estática é apenas pesquisada por símbolos referenciados, qualquer membro sem referência direta — como o `+load` de um driver
ou uma categoria — seria descartado sem essa opção. `MADDatabaseDriverDispatchTests` testa o registro, e
`Linux/Tests/MADHeadlessDocumentTests.m` exercita toda a cadeia.

Adicionar um novo driver requer apenas uma entrada de link em `Linux/CMakeLists.txt` e nenhuma alteração em `MAD`.

## Os shims de compatibilidade ficam em uma biblioteca própria — e o motivo

Anteriormente, cada biblioteca estática de framework embutia `Compat/*.m`. Isso fazia com que vincular duas
delas com whole-archive gerasse erro de símbolos duplicados. A CLI revelou o custo
dessa abordagem quando `mad refresh` contra um servidor MySQL ativo **abortava** (SIGABRT)
porque `MADMySQLFetch (DataTable)` — o método que executa o
prepared statement — era uma categoria invocada por envio de mensagem, cujo arquivo objeto o linker
nunca havia incluído.

Agora `madcompat` é sua própria biblioteca estática, vinculada com whole-archive por cada executável
(`mad_add_test`, `ToolchainProbe`, `mad-cli`), mantendo os arquivos estáticos dos frameworks
puros para que também possam usar whole-archive com segurança. Regra geral resultante: **uma
biblioteca estática de framework em Objective-C só é segura para vincular se usar whole-archive**; caso contrário,
suas categorias estarão silenciosamente ausentes em tempo de execução.

## Divergências do GNUstep encontradas pelo probe e pelos testes

* **`NSOperationQueue` e KVO — encontrada aqui, corrigida em `MADOperation`.** A `NSOperationQueue` do GNUstep
  remove sua observação KVO de `"isReady"` a cada notificação
  recebida e verifica `isReady` mais uma vez logo após registrar a
  observação. `MADOperation` costumava avançar sua máquina de estados de dentro do próprio método
  `-isReady`, o que disparava a notificação durante a primeira verificação e fazia a
  segunda tentativa remover uma observação já inexistente — lançando
  `NSInvalidArgumentException`. Agora `MADOperation`
  aciona o avanço de estado explicitamente (`-willEnqueue` inicia a avaliação de condições)
  e emite `will`/`didChangeValueForKey:` para `isReady`, `isExecuting` e
  `isFinished` apenas quando cada valor realmente muda. Os testes no Linux e na Apple validam esse comportamento.
* **Ausência de arquivamento com `requiringSecureCoding:YES`.** No GNUstep, `archivedDataWithRootObject:requiringSecureCoding:YES`
  retorna `nil` sem erro; por isso, os caminhos de código que precisam rodar fora da Apple — o cache de renderização `.madac` em `MADArrayCaching`,
  o conjunto de chaves de grupo em `MADDataTableFast` e os arquivos de `MADFileUtilities` — usam fallback para
  `requiringSecureCoding:NO` fora de `#if __APPLE__`. Na leitura (unarchiving), `unarchivedObjectOfClass:fromData:error:`
  funciona normalmente no GNUstep, enquanto `+unarchiveTopLevelObjectWithData:error:` é implementado via shim em `Compat/` sobre `+unarchiveObjectWithData:`.
* **`-localizedCaseInsensitiveCompare:` diferencia maiúsculas e minúsculas no GNUstep** — resolvido em 2026-10-25. A collation do SQLite
  registrada por `MADDatabaseSqlite3` (`compare_string_utf8_localized_asc_collation`),
  os seletores de ordenação em memória e o comparador de strings do formatador de relatórios agora
  passam todos por uma única ordem definida pelo próprio projeto (`NSString+Comparison.h`:
  case-fold seguido de ordem de code points UTF-8), eliminando qualquer divergência entre plataformas. Consulte a seção `mad export` em `docs/project/MAD_CLI.md`.
* **Codificação de tipo em runtime de `BOOL` e herança em `class_getProperty` — encontradas pelas
  suítes rptq do `MAD`, corrigidas em `RptqObject`.** No GNUstep, `BOOL` é
  `unsigned char` (`'C'`), enquanto na Apple é `signed char` (`'c'`); por isso, os accessors booleanos dinâmicos de `RptqObject` agora registram a
  codificação correspondente a cada plataforma (`MAD_RPTQ_BOOL_TYPE`). Além disso, `class_getProperty()` no GNUstep inspeciona apenas a própria classe sem percorrer a cadeia de superclasses; agora `RptqPropertyNamed` percorre a hierarquia em ambas as plataformas.
* **APIs de arquivo do GNUstep recusam URLs sem esquema (`file://`) — encontrada pelos
  testes portados de `MADFileManager`, corrigida em `MADURLFactory`.** `+newURLForLocalDocumentsDirectory`
  passou a construir sua URL com `+fileURLWithPath:` em vez de `-initWithString:`, resolvendo a diferença em ambas as plataformas.
* **Objetos do libdispatch são ponteiros C comuns fora do Darwin** (`os/object.h` desativa suporte a ObjC e recusa `OS_OBJECT_USE_OBJC=1`), portanto o ARC não pode gerenciá-los como objetos Objective-C: propriedades dispatch usam `assign` fora da Apple.
* **Lacunas menores tratadas com shims ou guardas:** `NSOperation.name`,
  `NSOperation.cancelled` e `NSOperation.asynchronous`, métodos de ubiquidade (iCloud) do `NSFileManager`, `-initWithFilePresenter:` e `-coordinateAccessWithIntents:queue:byAccessor:` no `NSFileCoordinator`, acesso com escopo de segurança e `-fileSystemRepresentation` em `NSURL`, leitores `-options:error:` de `NSData`, `-decodeTopLevelObjectOfClasses:forKey:error:` em `NSCoder`, `-registerUndoWithTarget:handler:` em `NSUndoManager`, `+propertyListWithStream:options:format:error:`, métodos `CG*Value` em `NSValue`, macros `CF_ENUM`/`CFAvailability`, funções de extração de `CFNumber`, `copyfile(3)`, `htonll`, escalares MacTypes (`Float64`, `SInt32`…`UInt64`, `Boolean`), `NS_RETURNS_INNER_POINTER`, `__nullable`, `NSOperation.qualityOfService`, `NSDataWritingFileProtection*`, `containerURLForSecurityApplicationGroupIdentifier:` e `QOS_CLASS_DEFAULT`.
* **Verificados e funcionando perfeitamente:** ARC e weak zeroing, blocos, exceções,
  `@synchronized`, KVO (chaves manuais e dependentes), KVO da máquina de estados de `NSOperation`, `NSPredicate predicateWithFormat:@"error != nil"`, libdispatch (once/queues/groups/semaphores), drenagem da fila principal em executável comum, JSON, UUID, datas, plists, sort descriptors, streams, `NSDecimalNumber`, `NSCalendar` e keyed archiving no caminho permissivo.

**Formatação monetária (encontrada em 2026-10-16, corrigida em 2026-10-17).** Dois comportamentos do GNUstep faziam os valores monetários renderizados diferirem da Apple: `NSNumberFormatterCurrencyStyle` omitia casas decimais e a localidade padrão da imagem (`en_US_POSIX`) inseria espaço após o símbolo monetário e omitia separadores de milhar. Ambos foram resolvidos fazendo o relatório obter a localidade e as casas decimais da configuração numérica do documento (com fallback para `en_US`) e normalizando o símbolo de iene (que o GNUstep emitia como U+FFE5 de largura total). Uma comparação de 60 casos (6 localidades × 10 valores) agora produz bytes idênticos entre as duas plataformas.

## A contagem de `NEED`s

As verificações que dependem de recursos exclusivos da Apple (como `requiringSecureCoding:YES`, `containerURLForSecurityApplicationGroupIdentifier:`, Core Data e o modelo compilado `MAD.momd` em `MADStoreTests` e `RptqStoreContextTests`) são reportadas deliberadamente como `NEED` em vez de `SKIP`, deixando explícito quando um teste requer um recurso inexistente no Linux.

As suítes de bancos de dados live pulam (`SKIP`, nunca falham) quando nenhum servidor está acessível — seguindo o mesmo contrato dos esquemas do Xcode.

## Executando as suítes de bancos de dados live aqui

`MADMySQLLiveTests`, `MADTdsClientLiveTests` e `MADPostgresLiveTests` conversam com servidores reais e são puladas quando nenhum servidor está acessível. Os servidores são os três contêineres documentados em `docs/project/DEVELOPER.md`; inicie-os primeiro:

	MADMySQL/TestDatabase/mysql-test-db.sh up          # mad-mysql on :13306
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up  # mad-mssql on :1433
	MADPostgres/TestDatabase/postgres-test-db.sh up    # mad-postgres on :5432

	docker run --rm \
		-e MAD_MYSQL_TEST_HOST=host.docker.internal \
		-e MAD_MYSQL_TEST_PORT=13306 \
		-e MAD_TDS_TEST_HOST=host.docker.internal \
		-e MAD_PG_TEST_HOST=host.docker.internal \
		--entrypoint bash mad-linux:phase-b -c \
		'/src/Linux/build/MADMySQLLiveTests && /src/Linux/build/MADTdsClientLiveTests && /src/Linux/build/MADPostgresLiveTests'

Medido com esse ambiente limpo: MySQL 44/44 (311 verificações), SQL Server 29/29 (169 verificações) e PostgreSQL 14/14 (132 verificações) — comprovando que todos os três drivers funcionam integralmente no Linux.

## Licenças

Tudo na imagem de build é ferramenta de compilação e teste; nada dali é vinculado ao aplicativo iOS/macOS. O libobjc2 é MIT; o libdispatch é Apache-2.0 com exceção de runtime Swift; o GNUstep Base é LGPL-2.1-or-later; o gnustep-make é GPL-3.0-or-later (presente apenas na imagem de build/teste, nunca na imagem de runtime). As bibliotecas C possuem suas próprias licenças (`docs/project/THIRD_PARTY_LICENSES.md`), tendo o antigo cliente MySQL GPL sido substituído pelo MariaDB Connector/C (LGPL). Como a imagem de runtime é publicada em `ghcr.io/mthomason/mad`, a oferta escrita de relink para os componentes LGPL está documentada em `ThirdParty/Licenses/README.md` e em `docs/project/THIRD_PARTY_LICENSES.md` §9.

## A CLI roda aqui — Fase D

O binário `mad` é compilado por este `CMakeLists.txt` a partir de `CLI/Source` (os mesmos arquivos-fonte que `CLI/build.sh` compila no macOS), vincula os onze frameworks com whole-archive e roda dentro da imagem:

	/build/mad inspect <document.mad>
	/build/mad schema  <document.mad>
	/build/mad query   <document.mad>
	/build/mad refresh --credentials user:pass <document.mad>

**`export` recebeu seus formatos baseados em Foundation e renderização na Fase E (2026-10-16).** A interface de exportação (`MADReportExporting` + `MADReportExporterRegistry`, `docs/project/MAD_CLI.md` §5.3) está integrada ao `mad`, de modo que `text`, `csv`, `json`, `html`, `html-flow` e `json-report` rodam na imagem Linux e geram exatamente os mesmos bytes que a ferramenta no Mac (enquanto `pdf` informa explicitamente por que não está disponível no Linux).

Comparação dos formatos de dados na fixture London (`CLI/Fixtures/London.portable.mad`, atualizada antes do teste, com `sha256sum` em ambas as plataformas):

| formato | bytes | sha256 (idêntico em ambas as plataformas) |
|---|---|---|
| `json` | 64595 | `569c6ee25223c51ecffd15923dd897e75c8362d72f4ece72f8dbeee3e9c8cdbc` |
| `csv` | 12538 | `773f6215a5447f72d499282d337a5916b11f0f3b06cb4c5aec134db6f493cb21` |
| `text` | 40441 | `7dcee96c45951fac0e0057094a6a142c90a88d6d88a1c03278b273f5140c6e49` |

`Linux/Tests/MADReportExporterTests.m` e `MAD/MADTests/MADReportExporterTests.m` fixam os checksums FNV-1a de cada formato em ambas as plataformas.

**Como a classe de documento foi estruturada.** Como `MADocument` herda de `UIDocument`, a metade de dados do documento foi extraída para o protocolo `MADDocumentDataProtocol`, adotado tanto por `MADocument` quanto por `MADHeadlessDocument`. Assim, Apple e Linux executam a *mesma* operação `MADOperationRefresh`.

**Resumo de verificação dentro da imagem:**

| Execução | Resultado |
|---|---|
| `mad inspect` em `London.mad` (exemplo legado) | v0, 6 membros, store + WAL + SHM reportados |
| `mad inspect` em `London.portable.mad` | v1, 4 membros, `StoreContent/store.sqlite (portable)`, 41 seções / 25 elementos |
| `mad schema` nas duas fixtures portáveis | idêntico à saída do Mac, byte a byte |
| `mad query` nas mesmas fixtures | mesmo conjunto e ordem de campos do Mac |
| `mad refresh` em `London.portable.mad` | 76 linhas, cache de linhas idêntico ao do Mac (21 colunas por nome, 76 linhas, todos os valores iguais) |
| `mad refresh --rows 50 --credentials root:root` em `MySQL.employees.mad` | 50 linhas do MySQL 8.4 ativo (prepared statement, banco `employees`) |
| `mad refresh --rows 20 --credentials sa:Root1@Root2` em `TDS.AdventureWorksLT2022.mad` | 20 linhas do SQL Server 2022 ativo (freetds, `AdventureWorksLT2022`) |
| `mad refresh --rows 25 --credentials mad:mad_test_pw` em `Postgres.chinook.mad` | 25 linhas do PostgreSQL 17 ativo (libpq, `chinook`) |

**Ordem determinística de colunas no SELECT (resolvido em 2026-10-16, `docs/project/MAD_LINUX.md` §10.1):** a ordem das colunas agora é definida pelo alias da coluna ordenado com `-compare:` em ambos os geradores de SQL, garantindo que o SQL gerado, o cache de linhas e todas as exportações coincidam em ambas as plataformas (`Linux/Tests/MADQuerySelectExpressionTests.m`).

## O gravador (writer) roda aqui, e as duas plataformas produzem os mesmos bytes

Na Fase E (`docs/project/MAD_LINUX.md` §9), o gravador de arquivos `.mad` também roda no Linux e produz os **mesmos bytes** que o Mac para o mesmo documento por meio de `mad write <doc.mad> --out <copy.mad> [--reproducible]`:

	$ mad write London.portable.mad --out copy.mad --reproducible
	16261 bytes, sha256 09815b24e91e03b6e526008f7c2700074fed10679771b9e1ee4609e54a1192f5
	                                     (identical on the Mac and in this image)

`--reproducible` fixa uid/gid 0, o timestamp `2001-01-12T00:00:00Z` e percorrimento ordenado dos membros. `Linux/Tests/MADArchiveManagerTests.m` cobre o round-trip e valida o checksum FNV-1a do documento inteiro contra os bytes gerados no Mac.

## A camada de renderização e os formatos HTML rodam aqui

A camada de renderização foi desacoplada da Apple por meio do protocolo `MADDocumentRenderProtocol`, do construtor de páginas `MADReportPageBuilder` e de `MADDocumentRenderDataSource`. Medido contra o Mac na fixture London:

| formato | bytes | sha256 (idêntico em ambas as plataformas) |
|---|---|---|
| `json-report` | 118.109 | `9d01d0daabbb5e38921c0bfbed083b288031c9340e9a4af81679d03b691ce94c` |
| `html` | 62.007 | `285541ed59333e0e55b8c7fe5619e4b64dde7aaf8e93a24ba881b40111ab2327` |
| `html-flow` | 54.766 | `0565204a55d02f925602b5c0bf298bb0e41c9cbe56bea6df770e828a35782382` |
| `pdf` | — | não produzido no Linux; `+isAvailable` retorna NO com o motivo |

## A imagem de runtime — o entregável da CLI (Fase F)

`./Linux/build.sh --runtime` constrói o estágio `runtime` do Dockerfile, gerando a imagem enxuta `mad-cli:latest` (**283 MB em disco, 66,5 MB comprimida**, contra 6,65 GB da imagem de build):

	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad inspect /docs/London.portable.mad

A imagem é publicada automaticamente pelo CI (`.github/workflows/publish-image.yml`) em `ghcr.io/mthomason/mad` (`linux/amd64`) com as tags `latest` e `<short-sha>`. Em Macs com Apple Silicon, adicione `--platform linux/amd64` ao usar a imagem publicada:

	docker run --rm --platform linux/amd64 -v "$PWD/CLI/Fixtures":/docs:ro \
		ghcr.io/mthomason/mad mad inspect /docs/London.portable.mad

A imagem de runtime inclui `/usr/local/bin/mad`, as bibliotecas compartilhadas necessárias (GNUstep Base, libobjc2, libdispatch e libBlocksRuntime; as demais bibliotecas C estão vinculadas estaticamente no binário) e o banco de exemplo `chinook.sqlite3` em `/root/GNUstep/Library/ApplicationSupport/`.

**`--verify` é a verificação automatizada completa:** reconstrói a imagem de runtime e executa `Linux/verify-cli.sh` montando o repositório em modo somente leitura, validando 41 verificações ponta a ponta:

	./Linux/build.sh --verify
	...
	MADVERIFY 41 passed, 0 failed

## O que ainda não é feito aqui

O gerador de PDF no Linux — **adiado em 2026-10-17, aguardando pesquisa e decisão do mantenedor; não inicie sem aprovação.** O arquivo de contexto é `docs/project/MAD_PDF_LINUX.md` e a justificativa está em `docs/project/MAD_LINUX.md` §10.2. Até lá, para gerar PDF no Linux, exporte com `--format html` e imprima a partir de um navegador headless/desktop.
