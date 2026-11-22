---
layout: default
title: "A compilação de bibliotecas estáticas do Compressor"
description: "As bibliotecas C de terceiros, como são compiladas e como o Xcode as alcança."
lang: pt-BR
---

# Bibliotecas Estáticas: o Sistema de Compilação do Compressor

Esta página descreve as bibliotecas C de terceiros que o aplicativo vincula e o sistema de compilação `Compressor` que as produz.

*Escrito na data original; fatos do estado atual reconciliados em 2026-11-22.*

Este documento descreve as bibliotecas estáticas de terceiros que o aplicativo vincula e
o sistema de compilação que as produz — como construído, não como planejado. O estado anterior
à reformulação (duas gerações de scripts sobrepostas, binários versionados, diretórios por plataforma)
está condensado no apêndice ao final.

**Restrição vigente:** nada em `Compressor/library` anterior a esta reformulação
é excluído até que o novo sistema tenha compilado toda combinação e o aplicativo compile e
seus testes passem contra os novos artefatos. A poda acontece por último, um commit por
item.

---

## 1. O que o sistema é

Uma matriz declarativa, um driver, uma receita por biblioteca, um manifesto por compilação.

```
Compressor/
  matrix.conf                  # the single place version/source/platforms/deps live
  build.sh                     # the driver: ensure (default) / --all / --rebuild /
                               #   --verify / --platforms ios,simulator,macosx
  sqlite3.xcconfig             # the single place SQLite compile options live
  lib/common.sh                # download cache, per-arch compile helpers, lipo,
                               #   xcframework creation, manifest writer, lock
  lib/recipes/<lib>.sh         # one recipe per library (configure/cmake + install)
  lib/verify/<lib>.sh          # optional per-library artifact checks
  patches/                     # local modifications to upstream sources, captured
                               #   as diffs (none current; zint's 2.4.2 patch retired)
  media/<sha256>-<archive>     # content-addressed download cache (gitignored)
  src/  build/                 # extracted sources and build trees (gitignored)
  library/
    <lib>.xcframework/         # the single artifact Xcode links (gitignored)
    <lib>/include/             # the canonical header dir consumers name (gitignored)
    manifests/<lib>.json       # version, source hash, flags, slice SHAs (gitignored)
```

### A matriz (`matrix.conf`)

Orientada por linhas e analisável por bash:

```
lib        version  sha256  url   ios-archs  sim-archs  mac-archs  min-ios  min-mac  deps
```

`sha256` é o hash do arquivo baixado — fixado para toda biblioteca. `deps`
nomeia outras linhas da matriz que o driver compila primeiro. Nada sobre a compilação de uma biblioteca
vive em outro lugar: os sinalizadores por biblioteca vivem na receita e são ecoados no
manifesto, então "quais sinalizadores construíram isto?" é respondível apenas pelo manifesto.

### O driver (`build.sh`)

* `build.sh <lib>…` — garante cada biblioteca (dependências primeiro); um no-op rápido quando
  o manifesto corresponde à linha da matriz e toda fatia existe.
* `--all` — toda biblioteca na matriz.
* `--rebuild` — força as bibliotecas **nomeadas**; suas dependências mantêm a verificação
  fresca normal, então iterar sobre uma receita não recompila sua cadeia.
* `--verify` — verifica os artefatos contra a matriz + manifestos: versão e hash
  de origem, arquiteturas das fatias, presença de cabeçalhos, string de versão embutida de cada biblioteca,
  mais as verificações por biblioteca em `lib/verify/`.
* `--platforms ios,simulator,macosx` — limita quais plataformas são compiladas (padrão:
  todas as três).

As compilações são serializadas por um bloqueio em `build/.ensure.lock.d` (um bloqueio por `mkdir` com
recuperação de proprietário obsoleto — `flock` não existe no macOS), porque vários alvos Xcode podem
executar fases de garantia em paralelo durante uma compilação do workspace.

Os downloads chegam ao cache `media/` endereçado por conteúdo, então uma origem fixada é
baixada uma vez e verificada por hash em todo uso. Uma primeira compilação precisa de acesso à rede;
a mensagem de falha diz isso e nomeia o tarball.

### Receitas

Cada receita extrai a origem fixada em `build/<lib>/source`, compila por arquitetura,
faz lipo por plataforma e chama `finish_library`, que cria o xcframework,
instala o diretório de includes canônico e grava o manifesto. Uma biblioteca por
identificador de fatia do xcframework é uma restrição rígida de `-create-xcframework`, então
bibliotecas com vários componentes se fundem: openssl funde crypto+ssl em `libopenssl.a`,
freetds funde ct+sybdb+tds em `libfreetds.a`, e mariadb é um único
`libmariadbclient.a` (o alvo `libmariadb` do Connector/C é fixado como compartilhado no
UNIX, então a receita compila o alvo estático `mariadbclient`). As fatias são inferidas dos comandos de carga
Mach-O das bibliotecas (os sinalizadores `-m*-version-min` por plataforma), e é por isso que nenhuma
dica `-platform` é necessária.

Notas que vale conhecer ao mexer em uma receita:

* **sqlite3** gera a amalgamação no host e depois a compila por fatia
  com a lista de opções analisada de `sqlite3.xcconfig` — a receita é o *único*
  consumidor dessa lista (o alvo MADSqlite3 costumava ser o segundo, que é o
  perigo H7 em `BUGS.md`). As opções fixam o formato de cache `.maddb` (tamanho de página
  8192, `DQS=0`, FTS5, STAT4, …); trate mudanças como decisões de formato.
* **mariadb** compila o alvo estático `mariadbclient` por fatia com
  `WITH_SSL=OPENSSL` contra a instalação openssl por plataforma e
  `WITH_EXTERNAL_ZLIB=ON` contra a instalação zlib, com os plug-ins de autenticação `caching_sha2_password`
  e `sha256_password` compilados estaticamente e todos os outros
  plug-ins desativados (nenhum `.so` de plug-in é distribuído). O layout de instalação DEFAULT aninha
  os cabeçalhos em `include/mariadb`; a receita os achata para que `mysql.h`
  seja resolvido a partir da raiz canônica de includes, e seu preset cruzado responde à
  única sondagem cmake baseada em execução (a verificação LibreSSL) com o resultado do OpenSSL.
* **zint** é o 2.16.0 original compilado por `lib/recipes/zint.sh` com cmake
  (`ZINT_SHARED=OFF`, `ZINT_STATIC=ON`, `ZINT_FRONTEND=OFF`, `ZINT_USE_PNG=ON`,
  vinculado contra o libpng e o zlib da receita) em
  `library/zint.xcframework`.  A compilação direta da era 2.4.2 e seu patch
  local (`patches/zint-2.4.2-mad.patch`) estão aposentados: `ZBarcode_Encode_and_Buffer`,
  que o patch retroportou, é API upstream na 2.16, e os nomes
  `BARCODE_*` do wrapper sobrevivem como aliases.
* **freetds** aplica patch nos cabeçalhos *instalados*, não nas fontes: `typedef int BOOL;`
  é comentado em `sybdb.h` após cada instalação, porque o Objective-C já define
  `BOOL` por typedef — mas a própria biblioteca deve manter o typedef, já que as fontes C do dblib
  o usam.
* **postgres** compila apenas as interfaces de cliente (`src/common`, `src/port`,
  `src/interfaces/libpq`, `src/bin/pg_config` e `src/include`) contra a
  instalação `openssl` por plataforma (`--with-ssl=openssl` e os sinalizadores explícitos de módulo
  desligados), depois funde `libpq.a`, `libpgcommon.a` e `libpgport.a` em um
  único `libpostgres.a` para `postgres.xcframework`.

### O manifesto (`library/manifests/<lib>.json`)

```json
{
  "library": "openssl", "version": "3.5.0",
  "source": { "url": "…", "sha256": "…" },
  "toolchain": { "xcode": "…", "clang": "…" },
  "headers": "ios",
  "flags": "configure: no-shared no-asm no-async; opt: -O3",
  "built": "…",
  "slices": { "ios": { "archs": "…", "sha256": "…" }, … }
}
```

`headers` registra de qual plataforma os cabeçalhos gerados foram adotados pelo diretório de includes
canônico (freetds gera `tds_sysdep_public.h` por plataforma; a cópia do ios é a
canônica, como o layout legado escolheu).

---

## 2. Como o Xcode consome as bibliotecas

Todo alvo consumidor vincula um ou mais xcframeworks por referência de arquivo, nomeia o
diretório canônico `Compressor/library/<lib>/include` em seus caminhos de busca de cabeçalhos e executa
uma fase de shell **Ensure Libraries** primeiro em suas fases de compilação:

```sh
set -euo pipefail
"${SRCROOT}/../Compressor/build.sh" --platforms ios,simulator <lib>
```

A fase não faz nada em milissegundos quando o manifesto está fresco e compila apenas o que
falta caso contrário; `ENABLE_USER_SCRIPT_SANDBOXING = NO` é fixado em todo
alvo que tem uma. As plataformas são fixadas em `ios,simulator` porque nenhum
alvo compila para macOS ainda — as fatias macOS da matriz estão prontas para quando a
desacoplagem do UIKit chegar (veja a Trilha 2 de `ROADMAP.md`).

| Alvo | Vincula | Fase Ensure |
|---|---|---|
| MADSqlite3 | `sqlite3.xcframework` | `sqlite3` |
| MAD | `libarchive.xcframework`, `bzip2.xcframework`, `zlib.xcframework` | `libarchive` |
| MADMySQL | `mariadb.xcframework`, `openssl.xcframework`, `zlib.xcframework` | `mariadb` |
| MADPostgres | `postgres.xcframework`, `openssl.xcframework` | `postgres` |
| MADTds | `freetds.xcframework`, `openssl.xcframework` | `freetds` |
| MADTdsClient | nada do Compressor (símbolos tds vêm via MADTds) | — |
| MADBarcodes | `libpng.xcframework`, `zlib.xcframework`, `zint.xcframework` | `zint` |
| Aplicativo MAD Designer | `openssl.xcframework` | `openssl` |

Fatos sobre cabeçalhos que vale lembrar: xcframeworks de bibliotecas estáticas **não** expõem
seus cabeçalhos de forma confiável, então todo consumidor nomeia o diretório de includes canônico
explicitamente (os cabeçalhos também são incluídos no xcframework para completude
de arquivo). `zint.h`, `sqlite3.h` e `libpq-fe.h` (com seus cabeçalhos complementares)
são cabeçalhos públicos de framework cujas referências de arquivo apontam para os diretórios
de includes canônicos, porque cabeçalhos públicos do MAD importam `<MADBarcodes/zint.h>`,
o `MADSqlite3` exporta `sqlite3.h`, e o `MADPostgres` exporta `libpq-fe.h`.

A lista legada `LIBRARY_SEARCH_PATHS` do alvo MAD Viewer e o Scrimpter (fora
do workspace) são deliberadamente intocados: a falha de link do visualizador é uma decisão de produto
(veja `BUGS.md`), não uma ligação de compilação.

---

## 3. Primeira execução, dia a dia e atualizações de versão

**Primeira execução em um checkout novo** (ou após apagar `Compressor/library/`): compile
as bibliotecas uma vez, antes ou durante a primeira compilação do Xcode:

```
Compressor/build.sh --all --platforms ios,simulator
```

Precisa de acesso à rede para os downloads e de 30–90 minutos na primeira compilação,
a maior parte nos tarballs de origem maiores.
Depois disso, as fases Ensure do Xcode não fazem nada e uma compilação normal prossegue.

**Verificar os artefatos:**

```
Compressor/build.sh --verify --all --platforms ios,simulator
```

**Atualizar uma biblioteca:** edite sua linha em `matrix.conf` (versão, URL, sha256 do
novo arquivo), depois `Compressor/build.sh --rebuild <lib>` e execute a suíte de testes
do framework consumidor mais `--verify`. Uma biblioteca por commit. Se a nova
versão adicionar uma sondagem de execução cmake, o preset do mariadb falha ruidosamente e a nomeia
— responda explicitamente, nunca adivinhando.

**As receitas de zint/freetds/mariadb/postgres carregam conhecimento por versão** (patches,
edições de cabeçalhos instalados, respostas a sondagens, nomes de tipos de plug-in, layout de instalação,
listas de subárvores somente de cliente). Quando uma versão é atualizada, esses são os lugares a reverificar.

---

## 4. Comandos de verificação

```sh
# slice inventory
for f in Compressor/library/*.xcframework/*/lib*.a; do lipo -archs "$f"; done

# version strings (each library embeds its matrix version)
strings Compressor/library/openssl.xcframework/*/libopenssl.a | grep -m1 "OpenSSL 3.5.0"

# sqlite correctness, against the BUILT framework (the H7 gate)
nm MADSqlite3.framework/MADSqlite3 | grep -c sqlite3Fts5Init     # present
strings MADSqlite3.framework/MADSqlite3 | grep -x 'DEFAULT_PAGE_SIZE=8192\|DQS=0'

# wiring cleanliness -- expect "" bases plus the MAD Viewer legacy list only
grep -rn 'LIBRARY_SEARCH_PATHS' --include='*.pbxproj' .

# the fresh-clone simulation (proves portability + on-demand building)
git archive HEAD | tar -x -C /tmp/fresh
cd /tmp/fresh
Compressor/build.sh --all --platforms ios,simulator     # bootstrap path (a)
xcodebuild build -workspace Reports.xcworkspace -scheme "MAD Designer" -destination …
Compressor/build.sh --verify --all --platforms ios,simulator
# path (b): wipe library/ xcframeworks and build in Xcode only -- the ensure
# phases rebuild everything
```

---

## Apêndice: o estado anterior à reformulação (para referência)

Antes de 2026-10-04, as bibliotecas eram compiladas por duas gerações sobrepostas de
ferramentas — scripts `Compressor/build_*.sh` por biblioteca e um driver `compressor.sh`
de 1.293 linhas (não executável: variáveis indefinidas causavam downloads 404
sob `set -e`; suas versões declaradas estavam anos desatualizadas) — e os resultados eram
**versionados**: 99 arquivos `.a` (~350 MB), todos os cabeçalhos e a amalgamação `sqlite3.c`
de 9,2 MB em `Compressor/library/`, mais 53 arquivos-fonte Zint fornecidos
dentro de MADBarcodes. O Xcode os consumia puramente por referência de arquivo com
caminhos de busca condicionais ao SDK, e é por isso que o macOS nunca pôde ser ligado
(`PBXFileReference.path` não é condicional ao SDK — a entrada em `BUGS.md` está
fechada pela religação do xcframework). Os scripts antigos e as árvores versionadas são
removidos na fase de poda, somente depois que o novo sistema compilar toda combinação
e o aplicativo compilar e seus testes passarem contra os novos artefatos.

As versões de linha de base com que a matriz começou, e suas atualizações de destino, são
acompanhadas em `TASKS.md` §6.
