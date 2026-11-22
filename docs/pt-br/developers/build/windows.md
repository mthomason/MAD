---
layout: default
title: "Compilar a engine no Windows"
description: "A cadeia de ferramentas fixada do Clang e do GNUstep e a compilação nativa da engine para Windows."
lang: pt-BR
---

# Compilar a Engine MAD no Windows — arquitetura e registro de decisões

Esta página registra a compilação da engine para Windows: a cadeia de ferramentas fixada, a portabilidade dos frameworks e suas cunhas, e o ponto de entrada `Windows/Engine/build.ps1`. O guia do aplicativo está em `/windows.html`.

*Escrito na data original; fatos do estado atual reconciliados em 2026-11-22.*

Escrito em 2026-11-18 contra `master` para o branch `windows-engine` (Fase 2
da prova de conceito do Windows). A compilação para Windows é irmã
de `Linux/`: os frameworks Objective-C da engine headless compilados nativamente no
Windows com Clang contra GNUstep Base, para que a mesma engine que executa o aplicativo
macOS e a CLI Linux possa executar no Windows. Este documento é o companheiro técnico
de `Linux/README.md` / `docs/project/MAD_LINUX.md`; ele registra a
receita da cadeia de ferramentas, por que cada peça está fixada e as decisões que este incremento
tomou.

---

## 1. O que isto é, e o que não é

O alvo é um MAD Designer nativo para Windows (WPF no .NET 10 LTS) reutilizando a
engine Objective-C headless existente compilada nativamente para Windows. A compilação da engine
chega em `Windows/`, irmã de `Mac/` e `Linux/`; o aplicativo WPF veio depois
nas Fases 5–6f (`Windows/App`; §6e–§6i).

O incremento da Fase 2b provou a cadeia de ferramentas e a portabilidade dos frameworks. A Fase 2 (o
primeiro incremento) compilou **MADDataStructures** e **MADFoundation** e executou um
teste rápido. A Fase 2b adicionou **MADAPI** (a dependência transitiva que o MADSqlite3
puxa) e **MADSqlite3**, compilou a amalgamação SQLite fixada em uma
biblioteca estática e portou as suítes de teste Linux de MADDataStructures,
MADFoundation e MADSqlite3 (`Testing.h` do GNUstep + `MADTestSupport.h`). Ele ainda
não compilava os frameworks headless restantes, a CLI nem o aplicativo.

---

## 2. A receita da cadeia de ferramentas, e por que cada peça está fixada

O resumo (esta seção se sustenta sozinha):

### 2.1 Compilador: Clang 20.1.8

A falha de inicialização da Fase 1 (`0xC0000005` em todo binário Foundation) era uma
regressão de runtime nos componentes GNUstep do master flutuante — os sete pins
da §2.3 a corrigem — não um bug de geração de código do Clang 23. O Clang 20.1.8 é o
compilador testado pela CI e parte da receita comprovada; Clang 22/23 com os pins não foram
testados. Isto é um pin, não uma preferência; não atualize o LLVM sem um novo
teste de viabilidade.

### 2.2 A substituição do portão STL

Esta máquina traz o Visual Studio 2026 (18.12.0), cuja STL MSVC exige rigidamente
"Clang 22 ou mais recente" (`_MSVC_STL_UPDATE 202609L`, `yvals_core.h:923`):

```c
#elif defined(__clang__)
#if __clang_major__ < 22
_EMIT_STL_ERROR(STL1000, "Unexpected compiler version, expected Clang 22 or newer.");
```

A substituição `-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH` é a própria escotilha de escape
da STL. Ela é comprovadamente benigna: um programa C++ que usa `<map>` compila e
executa com Clang 20.1.8 + a substituição, e o mesmo ocorre com a cadeia de ferramentas completa e os
arquivos `.mm` do MAD (que incluem `<map>`/`<vector>`). Ela é aplicada à compilação da cadeia de ferramentas
(`Engine/toolchain/stl-gate-override.patch`) e a toda unidade de tradução Objective-C++
na compilação dos frameworks.

### 2.3 As sete revisões GNUstep fixadas (a regressão do master flutuante)

`gnustep/tools-windows-msvc` clona o master mais recente de cada componente
(`TAG=` está vazio em seus scripts de fase). Sua CI (`.github/workflows/ci.yml`)
compila e empacota a cadeia de ferramentas, mas **nunca executa um binário**, então uma regressão
de runtime passou despercebida. O teste A/B a isolou:

| Componente | 11-14 (executa) | master 11-17/18 (trava) |
|---|---|---|
| libobjc2 | `a21ae931` | `762f9d7` |
| gnustep-base | `24654296` | `ff647838` |
| libdispatch | `22798930` | `20b4c8b2` |
| gnustep-make | `e7c0730d` | `8fa108c7` |
| libffi | v3.8.0 | v3.8.1 |
| libiconv | v1.19 (`a536e24a`) | v1.19.1 |

A correção é fixar as sete revisões 11-14 comprovadamente boas
(`Engine/toolchain/revision-pins.patch`). O próprio driver também é fixado no
commit `54d08e57` (seu master flutua e não deve ser acompanhado). Ambos os fatos são
registrados em `Windows/Engine/toolchain.conf`.

### 2.4 Os três requisitos não óbvios do wrapper de compilação

O `build.bat` da cadeia de ferramentas deve ser executado a partir do ambiente de desenvolvedor `vcvars64`,
com `BASH` definido para o shell do MSYS2, e pelo caminho **absoluto** de `build.bat`, sem
editar `PATH` (o `PATH` do vcvars64 tem ~2500 caracteres e quebra a resolução de nome simples do cmd). Do Git Bash, invoque `cmd`
com `cmd //c` (não `cmd /c`); do PowerShell, `cmd /c` está correto. `Engine/toolchain/bootstrap.ps1` encapsula
todos os três.

---

## 3. O ponto de entrada de compilação

`Windows/Engine/build.ps1` reproduz a receita a partir do repositório:

1. **Verificação de pré-requisitos** — Clang 20.1.8, lld, CMake, Ninja, MSYS2, git, curl,
   tar, `llvm-lib`, VS 2026, o Windows SDK, NASM.
2. **Bootstrap idempotente da cadeia de ferramentas** — `Engine/toolchain/bootstrap.ps1`
   clona o driver fixado, aplica os dois arquivos de patch e compila o GNUstep
   a partir da fonte em `C:\GNUstep` (configurável; ~20–30 min na primeira execução).
3. **Compilação da biblioteca SQLite** — baixa a amalgamação 3.53.3 de
   `Engine/libraries.conf`, verifica seu sha256, extrai, compila `sqlite3.c`
   com a lista de opções de `Compressor/sqlite3.xcconfig` e a arquiva em um
   `sqlite3.lib` COFF com `llvm-lib`.
4. **Compilação dos frameworks** — compila MADDataStructures, MADFoundation, MADAPI e
   MADSqlite3 (mais as cunhas de `Engine/Compat`).
5. **Compilação dos testes** — compila e vincula um executável por arquivo de teste portado (mais
   o teste rápido).
6. **Execução dos testes** — executa o teste rápido e cada suíte; sai com código não zero em qualquer
   falha.

Os sinalizadores de compilação dos frameworks correspondem ao perfil Debug da compilação Linux: o
`gnustep-config --objc-flags` do GNUstep sob `--enable-debug-by-default` (que a cadeia de ferramentas Linux
usa) traz `-DDEBUG`, então `build.ps1` passa `-DDEBUG=1` a toda
unidade de tradução — biblioteca e teste igualmente — e **não** define
`NS_BLOCK_ASSERTIONS`, mantendo `NSAssert` ativo exatamente como no Linux.

**Decisão — `build.ps1` conduz o Clang diretamente, não pelo CMake.** O suporte à linguagem
Objective-C do CMake no Windows está quebrado para a combinação que esta
receita exige (o `clang` de driver GNU com alvo `x86_64-pc-windows-msvc`):
sua sondagem de link Objective-C passa sinalizadores do GNU-ld (`--out-implib`, `-nostdlib`,
`-nostartfiles`) ao `lld-link` e anexa `.lib` a nomes de biblioteca já
prefixados com `-l`, então o link falha (`undefined symbol: $_OBJC_CLASS_NSObject`
e erros de GC de seção para metadados ObjC). A receita comprovada é invocações diretas de `clang`
— os `compile-mad.sh` / `link-and-run.sh` da fase de viabilidade — e
`build.ps1` é essa receita limpa e tornada idempotente. As listas de fontes por framework ainda
vivem em `Engine/cmake/<Name>Sources.cmake` (o inventário canônico, pronto para CMake, com os motivos de exclusão),
e `build.ps1` as lê de volta para que as duas não possam divergir; uma compilação CMake real pode consumi-las sem mudança
quando o suporte a Objective-C do CMake no Windows chegar.

---

## 4. O que compila, e as cunhas do Windows

| Framework | Compilação Windows | Excluído, e por quê |
|---|---|---|
| MADFoundation | 26 de 27 (+ `madlib.c`) | `MADKeyChain` (Security.framework; já excluído no Linux) e `BDHost` (DNS reverso por socket POSIX — `sys/socket.h`/`netpacket/packet.h`/`ifaddrs.h`/`arpa/inet.h`; precisa de uma portabilidade para Winsock2). O umbrella vai junto com `MADKeyChain`. |
| MADDataStructures | todos os 17 | (`madmap.cpp` também não está no alvo Xcode) |
| MADAPI | 8 de 11 | os três controladores de visão de conexão (`MADConnectionViewController`, `MADConnectionSQLGenericViewController`) — UIKit, não headless. Não é um entregável próprio da Fase 2b; é a dependência transitiva do MADSqlite3. |
| MADSqlite3 | todos os 26 | cinco arquivos `.m` órfãos que também não estão no alvo Xcode (nomeados em `Engine/cmake/MADSqlite3Sources.cmake`) |

`Windows/Engine/Compat/` é uma cópia de `Linux/Compat`, adaptada para Windows:

* **`syslog.h`** — `syslog()` sem operação e as constantes `LOG_*`, para o
  ramo não Apple de `madlog` (`madlog.h` inclui `<syslog.h>` quando `__APPLE__` não está
  definido).
* **`pthread.h`** — `pthread_mutex_t` (recursivo) sobre uma
  `CRITICAL_SECTION` do Windows, para o bloqueio de estado de `MADOperation.m`.
* **`NSData+ReadingOptions` descartado** — o master GNUstep fixado já
  traz `NSDataReadingOptions` e `-options:error:`; a cunha Linux
  (que os re-declara, para gnustep-base 1.31.1) seria uma interface duplicada
  no Windows.
* **`NSPropertyListSerialization+Stream.m`** ganha um
  `#import <Foundation/NSData.h>` explícito — uma divergência de ordem de inclusão de cabeçalhos do Windows
  (os cabeçalhos do Linux acabam chegando ao NSData primeiro; os do Windows não).
* **`MADCompat.h`** (o prelúdio incluído à força) descarta o bloco `<endian.h>` +
  `htonll`/`ntohll` — nem MADFoundation nem MADDataStructures o usam
  (verificado por grep), e `<endian.h>` não existe no Windows. A camada de driver
  (`MAD`) precisará de uma cunha de ordem de bytes do Windows quando for portada.
* **`MADCompat.h`** também ganha um `static inline strlcat` — o UCRT do Windows não
  tem `strlcat`/`strlcpy` (grafias BSD/Apple; o glibc 2.38+ as fornece, e é
  por isso que o Linux não precisa de cunha), e `MADQueryCacheAddRow.m` recorre a ela.
* **`NSURL+FileSystem.m`** responde `-fileSystemRepresentation` com
  `self.path.UTF8String` em vez da grafia `GSNativeChar*` do GNUstep (UTF-16
  no Windows), que quebrava o caminho do `sqlite3_open_v2` quando mascarado como
  `const char *`.

As outras cunhas Linux passam sem mudança, já que o GNUstep-base do Windows e do Linux
são a mesma linha 1.31.x.

---

## 5. As mudanças inevitáveis em código compartilhado

Duas mudanças em código compartilhado foram necessárias, ambas mínimas e portáveis (a CI Linux
e as suítes Apple são os portões):

### 5.1 A renomeação de `itoa`/`ltoa`/`ultoa` em `madlib.c`

`MADFoundation/Source/madlib.c` define `itoa`/`ltoa`/`ultoa`, que colidem
com os nomes não padrão de três argumentos do UCRT do Windows com a mesma grafia.
Eles são renomeados para `mad_itoa`/`mad_ltoa`/`mad_ultoa`, e todo chamador atualizado:

* `MADFoundation/Source/madlib.{c,h}` — as definições e declarações;
  também descarta `#import <strings.h>` (não usado e ausente no Windows).
* `MADFoundation/MADFoundationTests/madlibTests.m` e `Linux/Tests/madlibTests.m`
  — os testes.
* `MAD/Source/model/MADModelQueryTable.m`, `MAD/Source/rptq/RptqQueryTable+Extras.m`
  (`ltoa`) e `MADSqlite3/Source/MADDataTableFast.m`,
  `MADSqlite3/Source/MADQueryCacheAddRow.m` (`ultoa`).

É uma renomeação puramente mecânica, neutra em comportamento na Apple e no Linux.
`uitoa`, `reverse`, `count_digits` e `count_digits_ul` ficam intocados (eles
não colidem com o UCRT). A referência a `itoa` em `MADExplorer` está dentro
de um bloco comentado e não é chamadora.

### 5.2 O ponteiro de cursor da enumeração rápida

`MTStack.m`, `MTQueue.m` e `MTLinkedList.m` armazenam o ponteiro de nó do cursor de `countByEnumerating…
` em `NSFastEnumerationState.extra[0]`, convertido por
`unsigned long`. Isso tem 32 bits no Windows (LLP64) mas 64 no Linux/Apple
(LP64), então o ponteiro era truncado e a enumeração em vários lotes (qualquer
coleção acima do que cabe em um buffer de pilha) travava ou produzia lixo.
Os três arquivos agora copiam o ponteiro para `extra` com `memcpy` (correto em
LP64 e LLP64) e o mantêm em um local `__unsafe_unretained` — a
coleção é dona da cadeia de nós, que sobrevive à chamada, então o ponteiro emprestado
é o modelo honesto de propriedade em toda plataforma. A mudança é neutra em comportamento
na Apple/Linux (os mesmos bytes de ponteiro passam).

---

## 6. Lacunas conhecidas e próximos incrementos

> Esta seção registra as lacunas das Fases 1/2 como estavam então. As Fases 3a–6e
> fecharam todas, exceto as aceitas; veja §6b–§6h e
> `Windows/README.md` para o estado atual.

* **`BDHost`** (DNS reverso) e **`MADKeyChain`** (Security.framework) estão
  excluídos; `BDHost` precisa de uma portabilidade para Winsock2, `MADKeyChain` não tem equivalente
  de chaveiro no Windows ainda. `BDHostTests` não é registrado no Windows pelo
  mesmo motivo (não consegue vincular sem `BDHost.m`) — registrado, não ignorado.
* **Os frameworks headless restantes** (`MAD`, os drivers, `MADFileManager`,
  `MADCocoaExtensions`, …) e **a CLI** são os próximos incrementos.
* **O aplicativo WPF** é uma fase posterior.

## 6b. Fase 3a — os frameworks, a pilha de arquivamento e a CLI

A Fase 3a compila os frameworks headless restantes, as bibliotecas C do contêiner
`.mad` e o `mad.exe`:

* **Frameworks.** `MADCocoaExtensions` (7 arquivos), `MADFileManager` (10) e `MAD`
  (168) juntam-se ao conjunto das Fases 2/2b, a partir das mesmas listas de fontes Linux e com os
  mesmos motivos de exclusão (a cauda de interface, `MADocument`, as operações de chaveiro,
  `MADCloud`). `MADDirectoryMonitor` compila contra uma cunha inerte de `sys/inotify.h`
  — a CLI é de execução única e não precisa de eventos de mudança.
* **Bibliotecas C.** `zlib` 1.3.2, `bzip2` 1.0.8 e `libarchive` 3.8.9 (os
  pins Linux) compilam em `build.ps1`: zlib e bzip2 por clang direto + `llvm-lib`,
  libarchive via CMake + clang-cl (zlib/bzip2 dentro; xml2/lzma/zstd/lz4/openssl
  e as ferramentas fora), correspondendo a `Linux/lib/libraries.sh` / Compressor. A pilha de código de barras —
  `libpng` 1.6.59 e `zint` 2.16.0 — compila da mesma forma (ambas via
  CMake + clang-cl), então `MADBarcodes` também compila e renderiza aqui.
* **CLI.** `CLI/Source` → `mad.exe`, vinculado por inteiro. `inspect`, `schema`, `query`
  e `refresh` (76 linhas) executam em `London.portable.mad`; todos os seis digests de exportação
  correspondem aos pins Mac/Linux byte a byte, e `write --reproducible` grava o
  mesmo documento de 16261 bytes (`09815b24…`) que o Mac e o Linux gravam.

### 6b.1 As duas correções de runtime exclusivas do Windows (Fase 3a final)

* **`write --reproducible` (a leitura de 116 bytes do armazenamento).** O `open`/`read` do
  escritor de arquivos passava por `Windows/Engine/Compat/unistd.h`, cujo `open`
  mapeava para o `_open` do UCRT — que usa por padrão o modo *texto*.  Um armazenamento SQLite
  contém um byte `0x1A` (Ctrl-Z) no deslocamento 116; o `_read` em modo texto para ali
  como EOF, então o escritor viu 116 de 663552 bytes e emitiu um arquivo de 518 bytes.
  A cunha agora faz OR de `_O_BINARY` nos sinalizadores, então `open`/`read` têm o comportamento
  byte a byte do POSIX.  Restrito à cunha do Windows; os bytes Apple/Linux
  não mudam.  Fixado por `MADArchiveManagerTests` (5 testes, 0 necessidades).
* **`export` repetido em um mesmo usuário (a renomeação do `.mdcache`).** O `.mdcache` do
  cache de linhas é um plist lido por `NSInputStream` e depois reescrito atomicamente.
  `Compat/NSPropertyListSerialization+Stream.m` abria o fluxo já aberto
  uma segunda vez; o `GSFileInputStream -open` win32 do GNUstep chama `CreateFileW`
  (`FILE_SHARE_READ`) a cada vez e sobrescreve `_loopID`, vazando o primeiro
  handle.  Esse handle bloqueava o `MoveFileEx` posterior sobre o `.mdcache`
  (`"being used by another process"`), então a segunda exportação falhava.  A cunha
  agora lê o fluxo aberto sem reabri-lo (o contrato da Apple), e duas
  exportações em um mesmo usuário têm sucesso.

### 6b.2 O inventário de testes

As suítes copiadas de MAD/MADFileManager/MADCocoaExtensions/MADAPI estão ligadas em
`build.ps1` (caminhos de fixture adaptados para `Windows/Engine/Tests`): **107 suítes portadas
+ o teste rápido, 966 testes, 6 necessidades, 5 ignorados, 0 falhas**. As seis
necessidades correspondem às lacunas de plataforma da imagem Linux: `MADDirectoryMonitorTests` (3 — o
monitor do Windows é inerte), `MADStoreTests` (1 — Core Data + `MAD.momd`) e
`RptqStoreContextTests` (2 — o caminho do conversor/documento). Quatro suítes MAD que
precisam dos drivers da Fase 3b estão adiadas e registradas em `build.ps1`:
`MADDatabaseDriverDispatchTests`, `MADQueryFullTests`, `MADSQLParserTests` e
`MADQueryMaxFieldLengthTests`. Os cinco ignorados são o benchmark SQLite em sua
escala padrão.

As cunhas adicionais de `Compat` do Windows são `unistd.h`, `dirent.h`, `libgen.h`,
`sys/{unistd,fcntl,inotify}.h`, mais `MADCompat.h` ganhando `strlcpy`, as
macros de modo `S_IS*`/`S_IR*`, `ssize_t`/`mode_t`, `M_PI`, `arc4random` e
`gmtime_r`. As mudanças adicionais mínimas em código compartilhado (todas seguras em `#if __APPLE__`
ou neutras em bytes no Linux; a CI Linux e as suítes Apple são os portões):

* `MADReportSectionRepresentation.m` descarta um `@finally` vazio (a geração de código
  GNUstep-2.2 + ARC do clang 20.1.8 travava com ele).
* `madtar.m` ganha um ramo de mtime `_WIN32` (o `struct stat` do UCRT tem `st_mtime`,
  não `st_mtim`).
* `MADArchiveManager.m`, `MADStore.m` e `MADCLIInspect.m` usam
  `NSString -UTF8String` onde usavam `-fileSystemRepresentation` (a grafia
  NSString do GNUstep retorna UTF-16 no Windows).
* O `+Identifier:` de `MADDatabaseConnection+Constructor.m` retorna as quatro
  constantes de formato de documento diretamente, para que um processo que vincule apenas Sqlite3 ainda possa
  mapear um `driverID` armazenado para um tipo. (A Fase 3b removeu essa proteção — veja §6c.)

## 6c. Fase 3b — os drivers, o BDHost e os fixtures ativos

A Fase 3b adiciona os quatro drivers de banco de dados e as bibliotecas C que eles vinculam:

* **Bibliotecas C** (`Windows/Engine/libraries.conf`, `build.ps1` §3c): OpenSSL
  3.5.9 (Strawberry Perl + `VC-WIN64A` + `nmake`, estático), FreeTDS 1.4.27 (CMake
  `db-lib`, `ENABLE_MSDBLIB`, edição BOOL de `sybdb.h`), MariaDB Connector/C 3.4.11
  (CMake `mariadbclient`, plug-ins de autenticação estáticos), libpq 17.11 (**Meson + MSVC
  `cl.exe`**, `libpq_st` + `libpgcommon_shlib` + `libpgport_shlib` fundidos em um
  `libpq.lib` COFF). O PostgreSQL 17 abandonou a compilação MSVC, então o Meson é seu caminho
  no Windows; `cl.exe` (não `clang-cl`) é usado porque o Meson do PostgreSQL verifica
  `cc.get_id() == 'msvc'` e o `clang-cl` reporta `clang-cl`, descartando silenciosamente
  `win32gettimeofday.c`/`dirent.c` e o diretório de includes `win32_msvc`. Meson e
  Strawberry Perl são pré-requisitos documentados.
* **BDHost** — `MADFoundation/Source/BDHost.m` ganha um ramo `#elif defined(_WIN32)`
  sobre `winsock2.h`/`ws2tcpip.h` (`WSAStartup` uma vez,
  `getaddrinfo`/`getnameinfo`, somente IPv4); `+ipAddresses`/`+ethernetAddresses` são
  removidos por compilação no Windows. `BDHostTests` passa 3/3.
* **Drivers** — quatro listas `cmake/*Sources.cmake` (18/1/3/4 arquivos) e cunhas de cabeçalho
  para `<MADTds/sybdb.h>`, `<MADTdsClient/MADTdsClient.h>` e
  `<MADPostgres/libpq-fe.h>` etc. `MADTdsDb.m` é vinculado normalmente (seu
  `err_handler` global colide com o de `MADDatabaseSQLServer.m`). A proteção `+Identifier:` da Fase 3a
  é removida — a busca no registro funciona com os quatro drivers vinculados,
  fixada por `MADDatabaseDriverDispatchTests` (9/9).
* **Inventário de testes** — **129 suítes + o teste rápido, 1308 testes, 6 necessidades, 5 ignorados
  (48 quando os contêineres ativos não estão em execução), 0 falhas** (o incremento de código de barras
  adicionou `MADBarcodesTests` e `MADBarcodeExportTests`; o fechamento de imagem adicionou
  `MADImageElementTests` e `MADImageExportTests`). Suítes ativas contra os contêineres locais
  `127.0.0.1`: `MADMySQLLiveTests` 44/44, `MADTdsClientLiveTests` 29/29, `MADPostgresLiveTests`
  14/14. O `mad refresh` da CLI retorna 50 linhas MySQL / 20 TDS / 25 PostgreSQL.

## 6d. Fase 4 — o contrato de processo JSON por stdio

A Fase 4 adiciona `mad serve`, a fronteira de processo de longa duração que o shell WPF usará. Ele
lê JSON delimitado por novas linhas na entrada padrão e grava uma resposta JSON delimitada por nova linha
por requisição na saída padrão; os diagnósticos ficam na saída de erro padrão, para que os dois nunca se misturem. A forma de transmissão reutiliza o contrato JSON existente do projeto em vez de
inventar um paralelo.

**Requisição / resposta** — um valor JSON por linha, UTF-8, terminado em `\n`:

```text
request:   { "id": <int|string>, "method": "<name>", "params": { … } }
ok:        { "id": <id>, "ok": true,  "result": { … } }
error:     { "id": <id|null>, "ok": false, "error": { "code": <int>, "message": "…" } }
```

`id` é escolhido pelo cliente e ecoado de volta para correlação; uma requisição malformada responde com
`"id": null`. `error.code` é o código de saída da CLI (MADCLI.h): 1 uso/protocolo, 2 documento ruim,
3 banco de dados inacessível, 4 consulta falhou, 5 exportação falhou. Uma linha malformada, um
método desconhecido, um parâmetro ausente e uma exceção inesperada da engine todos respondem
`ok: false` com uma mensagem — nunca um traceback — e a sessão continua em execução.

**Métodos:**

| método | params | resultado |
|---|---|---|
| `open` | `path`, `host`/`port`/`database` opcionais | `handle`, `filename`, `driver` |
| `create` | `path`, `driver` + campos de conexão, `credentials` opcionais | `handle`, `filename`, `driver` (o documento criado) |
| `test-connection` | `driver` + campos de conexão, `credentials` opcionais | `tableCount` |
| `describe` | `handle` | `driver`, `columns` (chave/nome/tabela/tipo), `tables` (nome + campos) |
| `connection` | `handle` | `driver` + `file`/`host`/`port`/`database`/`server` |
| `apply-connection` | `handle`, `driver` + campos de conexão, `credentials` opcionais | `{}` |
| `query` | `handle` | `sql` |
| `query-model` | `handle` | token `driver`, `sql`, `sqlSourceText`, `tables`/`links`/`predicates`/`groups` (com identificadores do armazenamento) |
| `add-table` | `handle`, `table` (nome de esquema) | o `query-model` completo |
| `remove-table` | `handle`, `table` (id de tabela de consulta) | o `query-model` completo |
| `add-link` | `handle`, `leftField`, `rightField` (ids de campo) | o `query-model` completo (Left Outer Join padrão) |
| `set-link-type` | `handle`, `link`, `type` | o `query-model` completo |
| `swap-link` | `handle`, `link` | o `query-model` completo |
| `delete-link` | `handle`, `link` | o `query-model` completo |
| `add-predicate` | `handle`, `leftField`, `operator`, `value` | o `query-model` completo |
| `remove-predicate` | `handle`, `predicate` | o `query-model` completo |
| `add-group` | `handle`, `field`, `sort` | o `query-model` completo |
| `remove-group` | `handle`, `group` | o `query-model` completo |
| `validate-sql` | `handle`, `sql` | `tables`, `links`, `predicates`, `groups` (as contagens do plano) |
| `apply-sql` | `handle`, `sql` | `tables`, `links`, `predicates`, `groups` |
| `refresh` | `handle`, `rows`/`credentials` opcionais | `rowCount`, `elapsed` |
| `export` | `handle`, `format`, `path`/`deterministic` opcionais | `format` + `data` (os bytes do exportador) ou `path` + `bytes` |
| `write` | `handle`, `out`, `reproducible` opcionais | `path`, `bytes` — serializa o documento ativo |
| `shutdown` | — | `{}`, depois o processo sai com 0 |

Os métodos de conexão (`create`, `test-connection`, `connection`, `apply-connection`)
recebem um token `driver` — `sqlite3` | `mysql` | `sqlserver` | `postgres` — e
campos específicos do driver: SQLite recebe `file`; os drivers de servidor recebem
`host`/`port`/`database` (SQL Server também recebe uma instância `server` opcional), mais a
string `credentials` (`user:password`) existente. Eles reutilizam o
`createDocumentAtURL:`, o `MADDatabase` (connect/getTables/close) e o
`applyDatabaseConnection:` da engine — as mesmas chamadas que a janela de conexão do Mac faz.

`export` é a costura de exportação (`MADReportExporting` / `MADReportExporterRegistry`), não um
novo esquema: `format: "json"` retorna os bytes exatos `mad.report/1` que `mad export
--format json` grava (`MADReportExporterJSON` — `columns` e `rows`), e `format:
"csv"` os bytes RFC 4180. Um formato que esta compilação não consegue produzir (por exemplo `pdf` fora
da Apple) responde com `error.code` 5 e o motivo do exportador. As `columns` de `describe` são
essas mesmas colunas `mad.report/1` (`MADReportExportSource`), e seu `tables` é o
esquema de banco de dados armazenado que `mad schema` imprime. `open` aplica `host`/`port`/`database`
como os verbos de execução única, para que um documento versionado possa executar contra um servidor diferente
para a sessão. `write` agora serializa o documento da sessão ativa em vez de reabrir
`sourceURL`, então uma conexão aplicada na sessão é persistida. O fim de arquivo na entrada padrão
é um encerramento limpo, assim como `shutdown`.

Os métodos `query-model`/`add-table`/…/`apply-sql` são a extensão da área de trabalho Query da Fase 6b.
O contrato original de `serve` expunha a consulta apenas como seu `sql` gerado,
que o Mac deriva mutando os objetos `RptqQuery` em processo; o aplicativo WPF não tem
esse handle em processo, então esses métodos fecham essa lacuna. `query-model` lê o modelo
completo da consulta — tabelas/campos/links/predicados/agrupamentos com seus identificadores do armazenamento, o
`sqlSourceText` inserido e o token do driver — e todo método de mutação responde essa
mesma forma, para que o cliente substitua seu snapshot atomicamente. As mutações chamam as mesmas
fábricas e auxiliares `MADSQLQueryDocument` que o `MADMacQueryViewController` do Mac usa
(`newQueryTableForSchemaTable:`, `newQueryLinksWithLeftField:`, `addQueryGroupWithQueryField:`,
`removeGroupWitObjectID:`, …), e `validate-sql`/`apply-sql` executam o caminho existente
`MADSQLParser` → `MADSQLStatementResolver` → `MADSQLQueryCompiler` sem mudança.
`query` agora retorna primeiro o SQL de todos os campos e recorre à seleção de campos ativos,
correspondendo ao `generatedSQLString:` do Mac — então um documento novo sem elementos de relatório
ainda produz SQL.

**Cliente e testes.** `Windows/Client/` contém o cliente de aceitação de console .NET 10
(`Mad.Client`) e a suíte xunit (`Mad.Client.Tests`), ambos fixados por
`Windows/global.json`. O cliente gera `mad serve` e cobre os sete métodos; os
testes exercitam o caminho de sucesso sobre `CLI/Fixtures/London.portable.mad` (open → describe
→ query → refresh 76 linhas → exportar json/csv → shutdown, saída 0, sem processo órfão),
requisições malformadas, um método desconhecido, um documento ruim, um formato indisponível e
encerramento do processo.

## 6e. Fase 5 — a prova do shell WPF

A Fase 5 adiciona o primeiro aplicativo WPF sobre a fronteira de processo da Fase 4: um
shell `net10.0-windows` em `Windows/App/` que prova que a engine executa a partir de uma interface real.
Ele reutiliza `Mad.Client` sem mudança e adiciona um `EngineService` assíncrono (um `SemaphoreSlim`
serializa o protocolo de linha single-threaded; toda chamada bloqueante executa no pool de
threads), uma camada MVVM feita à mão (`ObservableObject`, `RelayCommand`, `AsyncRelayCommand`)
e um `DocumentViewModel` que espelha o `MADMacDocument` do Mac para a primeira fatia:
open → describe → query → refresh → export.

O shell tem o quadro de três áreas de trabalho (MAD Query / Designer / Viewer). Query mostra o
esquema armazenado e o SQL gerado; Viewer mostra as linhas atualizadas em um `DataGrid` (alimentado pela
análise de `mad.report/1` em um `DataTable`) e exporta CSV/JSON; Designer é um espaço reservado da Fase 6.
Na inicialização ele abre automaticamente `CLI/Fixtures/London.portable.mad` (substituível com
`MAD_DOCUMENT`), então demonstra com zero cliques. A janela Sobre (Overview / License &
Notice / Acknowledgements) renderiza o registro de dependências do Windows a partir de
`ThirdParty/Licenses/Windows/` e a oferta de relink — o conjunto de componentes do Windows, nunca o
da Apple.

A aceitação é verificada headless por `Windows/App/Mad.Designer.Windows.Tests` (xunit):
abrir London → describe (21 colunas / 11 tabelas / driver "Sqlite 3") → refresh 76 linhas →
exportar json (76 linhas) / csv (78 linhas) → encerramento limpo sem órfão, mais o
analisador de `mad.report/1` e as verificações do registro de licenças. O aplicativo e os testes compilam e executam em
`net10.0-windows` (fixado por `Windows/global.json`); a CI Linux não é afetada (ela nunca
compila .NET).

## 6f. Fase 6c — o modelo de layout de relatório (Designer)

A Fase 6c estende o `serve` com o modelo de layout de relatório que a área de trabalho Designer edita, usando o
mesmo padrão granular dos métodos query-model da 6b. `layout-model` lê o snapshot completo;
todo método de mutação muta os objetos `RptqDocumentSection`/`RptqDocumentElement` existentes
e responde esse mesmo snapshot, para que o cliente substitua seu estado atomicamente. O código de barras faz parte
do modelo (o incremento de fechamento de código de barras adicionou o tipo de elemento, suas edições de conteúdo, o
catálogo de simbologias, uma pré-visualização renderizada pela engine e o compositor WPF — §6j; o fechamento de imagem
seguiu com conteúdo PNG e o seletor de arquivos WPF — §6k). As cores estão adiadas (nenhum
tipo de cor portátil no modelo headless). Desfazer/refazer é do lado do cliente.

| método | params | resultado |
|---|---|---|
| `layout-model` | `handle` | `paperSize`, `sections[]`, `elements[]`, `fields[]` |
| `add-element` | `handle`, `kind` (`label`\|`data-field`\|`aggregate`\|`image`\|`line`\|`barcode`), `section`, `x`, `y`; `data` para uma imagem (PNG base64) | o snapshot completo |
| `remove-elements` | `handle`, `elements: [id…]` | o snapshot completo |
| `duplicate-elements` | `handle`, `elements: [id…]` | o snapshot completo |
| `move-elements` | `handle`, `elements: [id…]`, `section` | o snapshot completo |
| `set-element-geometry` | `handle`, `elements: [{id,x,y,w,h}…]` | o snapshot completo |
| `set-element-content` | `handle`, `element`, `content{text,field,function,scope,group,barcodeType,humanReadable,borderStyle,data}` (`data` é o PNG base64 de uma imagem; vazio o limpa) | o snapshot completo |
| `set-element-typography` | `handle`, `elements: [id…]`, `style{fontname,fontsize,bold,italic,underline,strikethrough,hAlign,vAlign}` | o snapshot completo |
| `set-element-box-model` | `handle`, `elements: [id…]`, `box{borderTop,borderBottom,borderLeft,borderRight,padding,margin}` | o snapshot completo |
| `set-section` | `handle`, `section`, `{height,visible,pageBreak}` | o snapshot completo |
| `set-paper-size` | `handle`, `paperSize` (`MTPaperType` int16: Letter 2 / Legal 7 / A4 19) | o snapshot completo |

O snapshot carrega as seções na ordem canônica do designer (Report Header, Page
Header, Group Headers, Detail, Group Footers, Page Footer, Report Footer), cada uma com `id`,
`type` (`MADocumentSectionType`), `title`, `height` (a altura de interface `layoutHeight`),
`visible`, `pageBreak` e `groupField`. Cada elemento carrega `id`, `type`
(`MADPrintPageElementType`), `section`, `x/y/w/h`, `text`, `field` (id de campo de consulta vinculado),
`table`/`column`, `function`/`scope`/`group` (agregado), `fontname`/`fontsize`,
`bold`/`italic`/`underline`/`strikethrough`, `hAlign`/`vAlign`, `borderTop`/`borderBottom`/
`borderLeft`/`borderRight`, `padding` e `margin`. Um elemento de código de barras também carrega o
objeto aninhado `barcode` (§6j); um elemento de imagem carrega `image{data}`, a imagem armazenada como
PNG base64 (vazio quando não tem nenhuma — §6k). `fields[]` lista os campos da consulta (com ids do armazenamento)
para o navegador da barra lateral e o popup de vinculação.

## 6g. Fase 6d — a área de trabalho Viewer (renderizar, tamanho de papel, exportar, imprimir)

A Fase 6d conclui o MAD Viewer sobre o shell 6a–6c. O visualizador do Mac renderiza um
PDF paginado em `PDFView`; o Windows não tem PDFKit, então a pré-visualização renderiza o
fac-símile HTML da engine, e o próprio PDF é gravado pelo exportador da engine no
momento da exportação (§6l):

* **Abordagem de renderização — WebView2 sobre o exportador HTML da engine.** A pré-visualização mostra os
  bytes exatos de `export --format html` (uma caixa `<div class="page" data-index="N">` por
  página, o mesmo formatador que o PDF e todos os outros exportadores usam), hospedados em um WebView2.
  A contagem de páginas na linha de status é o número dessas caixas de página, então a engine
  continua sendo o único paginador e nenhum exportador é reimplementado em C#. A pré-visualização adiciona
  apenas o cromo de apresentação (mesa cinza, espaços e sombras entre páginas) por meio de um estilo injetado;
  os bytes exportados ficam intocados. O HTML é gravado em um arquivo temporário e navegado
  por URL porque `NavigateToString` tem um teto de 2 MB que um relatório grande atingiria. O zoom é
  o `ZoomFactor` do WebView2; a navegação de páginas rola a caixa de página solicitada para a visão.
  **Print** usa `CoreWebView2.ShowPrintUI` — o caminho provisório de impressão HTML. O navegador é
  criado em `Loaded`, não em XAML, para que a área de trabalho se componha headless para seus testes.
* **`ViewerViewModel`** é dono da seleção de tamanho de papel e de seu bloqueio renderizado (US Letter
  padrão, US Legal, A4), dos passos de zoom (0,25–4,0, 1,25×, redefinição para 100%), da navegação
  anterior/próxima, do catálogo de formatos de exportação e da linha de status. A linha de status é a
  do Mac: `Rendered N pages from M cached rows.` com sua gramática de singular/plural, verde em
  sucesso e vermelha em falha. Selecionar um tamanho de papel não muda o relatório renderizado
  até a próxima atualização (a separação `selectedPaperType`/`renderedPaperType` do Mac); a
  seleção sobrevive à atualização, e a exportação usa o papel renderizado.
* **Export** oferece os sete formatos que esta compilação produz, na ordem do visualizador do Mac —
  PDF Document, HTML Page, HTML Flow, CSV, JSON Data, JSON Full Report e Plain Text —
  cada um com sua própria extensão de arquivo (`pdf`, `html`, `html`, `csv`, `json`, `json`, `txt`).
  A barra de ferramentas carrega o seletor de formato; Export abre o diálogo de salvamento filtrado para o
  formato escolhido. O PDF passa pela forma de caminho do `serve` (`export` com um `path`), então a
  engine grava os bytes do exportador no arquivo escolhido e a resposta carrega apenas a
  contagem de bytes; a leitura de volta `data` que os formatos de texto usam é UTF-8 e corromperia um
  PDF binário. Exportar antes de uma atualização atualiza primeiro, como faz o Export do Mac, e
  enquanto uma exportação executa a barra de status mostra sua barra de progresso indeterminada com uma
  linha "Exporting…" (o comando fica desativado; o `serve` não transmite progresso e a exportação
  é uma única requisição).
* **Integração com o documento.** `DocumentViewModel.RefreshAsync` executa a consulta e então chama
  `Viewer.RenderAsync`, que aplica o papel selecionado através do documento (para que o
  snapshot do Designer o acompanhe) e carrega a pré-visualização HTML. Os botões Refresh, Export
  e Print do Viewer todos passam por esse mesmo caminho de documento.
* **Correção da engine.** `set-paper-size` mutava o `RptqDocument` armazenado, mas não o
  documento de renderização, cujo `MTPaper` fica em cache após o primeiro layout, então a segunda mudança de papel
  nunca chegava a uma exportação. Ele agora também chama `setPaperType:` no documento de renderização
  (a chamada que o visualizador do Mac faz antes de atualizar) e reformata um relatório que já está
  disposto, para que o novo tamanho chegue a uma exportação que se segue sem outra atualização.

O Viewer substitui a grade de linhas provisória da Fase 5: o relatório renderizado é a área de trabalho,
como no Mac, e as linhas permanecem disponíveis pelas exportações CSV/JSON.

**Testes.** `ViewerViewModelTests` (gramática de status, catálogo de formatos, contagem de páginas, zoom,
navegação, requisição de impressão), `ViewerSurfaceTests` (a área de trabalho materializada em uma thread
STA — a barra de ferramentas, os sete formatos, o seletor de tamanho de papel, a cor do status e o
rótulo de página) e `ViewerAcceptanceTests` contra a engine (London → 5 páginas / 76 linhas em cache,
bloqueio de tamanho de papel e persistência através de A4 com a caixa de página exportada em 595 × 842,
todo formato de exportação com sua extensão e o PDF verificado por sua assinatura `%PDF-`, uma
exportação para um caminho com um espaço e um caractere não ASCII, o estado de exportação definido enquanto o
PDF é gravado e limpo depois, e a troca de tamanho de papel A4 → Legal → Letter chegando a
cada exportação).

## 6h. Fase 6e — Sobre, localização e o teste rápido do WPF

A Fase 6e fecha o portão de merge sem mudar a engine: conclui o registro de dependências da janela
Sobre, localiza o aplicativo WPF no conjunto de idiomas do aplicativo Mac,
adiciona a contraparte WPF de `MADMacSmokeTest.m` e atualiza este registro e
`Windows/README.md`. O `docs/windows.md` público e suas traduções estão
adiados por design.

**Sobre e o aviso do WebView2.** A pré-visualização do Viewer executa no
controle **Microsoft Edge WebView2** (NuGet `Microsoft.Web.WebView2` 1.0.4314.35).
O SDK que acompanha o aplicativo é BSD-3-Clause e carrega os avisos de terceiros
da Microsoft; o Evergreen WebView2 Runtime é um redistribuível da Microsoft,
não software open-source. A janela Sobre, portanto, lista
`Microsoft Edge WebView2` com ambos os termos e a atribuição do runtime, tudo em
`ThirdParty/Licenses/Windows/WebView2-LICENSE.txt`. O registro é
`docs/project/THIRD_PARTY_LICENSES.md` §10. O resto da lista de componentes está
inalterado (GNUstep Base, gnustep-corebase, libiconv, libobjc2,
libdispatch/BlocksRuntime, libffi e as bibliotecas C), e a oferta de relink LGPL
ainda nomeia a engine Windows; o aplicativo WPF nunca mostra o conjunto Apple.

**Localização.** Toda string voltada ao usuário vive em um `ResourceDictionary` WPF
em `Windows/App/Mad.Designer.Windows/Resources/`: `Strings-en.xaml` é a
fonte autoritativa e `Strings-de.xaml`, `Strings-es.xaml`,
`Strings-ja.xaml`, `Strings-pt-BR.xaml` e `Strings-zh-Hans.xaml` espelham o
conjunto de idiomas do aplicativo Mac (`MAD_APP_LOCALIZATION.md` D1/D9). Os dicionários são
embutidos no assembly principal (não itens `Page` compilados e não assemblies satélite
— o hífen em `Strings-de.xaml` impede que o MSBuild leia o
código de idioma como sufixo de cultura), e `Infrastructure/Localizer.cs` os carrega
com `XamlReader` e serve `Get`/`Format`. O XAML os consome pela
extensão de marcação `{infra:Loc Key}`, que resolve no momento do carregamento; code-behind e
view models chamam `Localizer`. O idioma segue a cultura de interface do SO na inicialização
(`de`, `es`, `ja`, `pt-BR`, `zh-Hans`; qualquer outro é inglês), e
`MAD_LANGUAGE` o substitui para inspeção:

```powershell
$env:MAD_LANGUAGE = "de"
dotnet run --project .\Windows\App\Mad.Designer.Windows\Mad.Designer.Windows.csproj
```

As traduções reutilizam o `Localizable.xcstrings` do Mac onde a origem em inglês
corresponde, depois seguem a política assistida por máquina (MAD_APP_LOCALIZATION.md D14):
o About Overview termina com o aviso de que as traduções são
assistidas por máquina e podem conter erros, em cada idioma. O cromo do Sobre,
o assistente de conexão, as barras de ferramentas e linhas de status de consulta/designer/visualizador, os diálogos
e os nomes de faixas são traduzidos; corpos de licença, avisos de componentes, a oferta de
relink LGPL, direitos autorais e nomes de marca permanecem em inglês verbatim (D6/§8), com uma
frase localizada dizendo que os textos de licença são reproduzidos em seu
inglês original. Palavras-chave SQL, nomes de tipos de dados e identificadores de campo/tabela não são
traduzidos, e o texto de erro que a própria engine retorna (falhas de driver, mensagens do
analisador SQL) permanece em inglês, como fazem as mensagens de driver do Mac.

**O teste rápido.** `Windows/App/Mad.Designer.Windows.Tests/SmokeTests.cs` é
a contraparte em nível de view-model/serviço de `MADMacSmokeTest.m`, não um teste
de pixels:

1. **London.** Abra `CLI/Fixtures/London.portable.mad`, atualize 76 linhas (5
   páginas), depois exporte HTML Page, HTML Flow, CSV, JSON Data, JSON Full Report e
   Plain Text pelo próprio caminho do Viewer. A contagem de bytes e o SHA-256 de cada arquivo
   são verificados contra os pins Mac/Linux em `Linux/README.md` (`html`
   `285541ed…`, `html-flow` `0565204a…`, `csv` `773f6215…`, `json` `569c6ee2…`,
   `json-report` `9d01d0da…`, `text` `7dcee96c…`).
2. **Um novo documento.** Crie um `.mad` a partir de `chinook.sqlite3`, aplique a
   instrução SQL do Mac (`SELECT Customer.FirstName, Customer.LastName, Customer.City
   FROM Customer WHERE Customer.Country = 'United Kingdom';`), adicione um rótulo
   estático, um campo de dados vinculado a `LastName` e um agregado COUNT no escopo do relatório,
   atualize, depois exporte todo formato disponível e verifique a contagem de linhas JSON e
   a contagem de páginas HTML.

O Viewer exporta PDF em ambos os testes pelo caminho de exportação por caminho da engine; o
teste rápido verifica sua assinatura `%PDF-` em vez de lê-lo como texto. A
suíte executa headless com o resto dos testes do aplicativo; veja `Windows/README.md`.

## 6i. Fase 6f — o tema, o shell e a passagem de usabilidade

A Fase 6f é somente apresentação: nenhuma mudança de engine, protocolo, documento ou fluxo de trabalho.
Ela corrige os dois defeitos funcionais que a revisão de design relatou e aplica um
sistema de design inspirado no Fluent e um shell em toda a arquitetura existente de três áreas de trabalho.
(A passagem de tema não fez parte do portão de merge; ela o segue.)

**Defeitos corrigidos.** Help ▸ About encerrava o processo: o
`Overview`, `LicenseNotice` e `SelectedAcknowledgement` somente leitura da janela Sobre estavam vinculados
a `TextBox.Text`, cujo modo de vinculação padrão é TwoWay, e a vinculação lançava
`InvalidOperationException` durante o primeiro layout da janela. As vinculações agora
são OneWay, e `AboutWindowTests` mostra a janela para fixar isso. O defeito de arraste do Designer
era de ordem Z: o fundo opaco de cada faixa era adicionado com seus
elementos, então um elemento arrastado para uma faixa posterior pintava por baixo dessa faixa
e desaparecia até que a soltura reconstruísse a tela; suas alças de redimensionamento também permaneciam
na posição antiga. O elemento arrastado agora pinta acima de todas as faixas, as
alças ficam ocultas durante o arraste, o cromo de seleção atualiza no lugar em vez de
reconstruir, o deslocamento do ScrollViewer é preservado através de uma reconstrução, e a matemática do arraste
é fixada no zoom 2 com a visão rolada.

**O sistema de design.** `Themes/Theme.xaml` é o conjunto único de recursos:
tipografia (Segoe UI Variable Text/Display, tamanhos Fluent), espaçamento, raios de canto,
superfícies, estilos de comando e navegação, botões primários/secundários, alternadores
segmentados, estilos de formulário e cartão e cores de status semânticas. Os pincéis de cromo são
chaves de recurso dinâmico Fluent, então claro/escuro, a cor de destaque do usuário e o alto contraste
seguem o sistema; `App.xaml` adere ao tema Fluent nativo com
`ThemeMode="System"` (o `WPF0001` da API experimental é suprimido). Documentos de relatório
mantêm sua própria paleta fixa: `Infrastructure/DesignPalette.cs` é a
única fonte congelada para papel, tons de elementos, o destaque de seleção, junções e
o minimapa. `MAD_THEME=Light|Dark` é uma substituição de inspeção como
`MAD_LANGUAGE`, e a mesa do WebView2 do Viewer a segue (ou a configuração
AppsUseLightTheme do Windows).

**O shell.** O ícone do aplicativo é gerado a partir da arte MAD existente
(`Assets/AppIcon.png` e o `AppIcon.ico` em vários tamanhos) e é a identidade da janela,
da barra de tarefas e do Sobre. Iniciar sem relatório mostra uma tela de Boas-vindas/Início
(Novo relatório, Abrir relatório, relatórios recentes, uma breve introdução) em vez de um
Viewer vazio. As três áreas de trabalho são um trilho esquerdo ao estilo NavigationView com
ícone + rótulo, um estado selecionado claro e Ctrl+1/Ctrl+2/Ctrl+3; elas ficam desativadas
enquanto a tela de Boas-vindas é mostrada. Um relatório recém-criado abre no Designer; um relatório
existente abre no Viewer. Não há destino Início: as três áreas de trabalho
continuam sendo o conjunto de pares de primeira classe. O menu Arquivo mantém Novo/Abrir/Salvar/Salvar como/Recentes/
Conexão/Sair; a barra de comandos mantém Novo e Abrir (Sobre permanece em Ajuda).

**Organização das áreas de trabalho.** O assistente de conexão é uma janela fixa de 640 × 660
(redimensionável, com um corpo rolável) cujos cartões agrupados mantêm o formulário
específico do driver dentro do mesmo quadro; alternar SQLite → MySQL/SQL Server/
PostgreSQL não a redimensiona. Query tem um interruptor segmentado Designer/SQL, comandos agrupados,
um comando Add table de tamanho normal no cabeçalho do painel de tabelas e uma
barra de zoom inferior com mais/menos, porcentagem e Fit. O Designer agrupa comandos de inserção e
edição, move o minimapa do canto superior esquerdo para um Expander recolhido no topo
do inspetor, e coloca zoom/grade/encaixe/réguas na
barra de visão inferior. O Viewer coloca comandos de documento/página/saída no topo e
zoom, navegação de páginas e a linha de status/papel na parte inferior, dando ao relatório
a área máxima.

**Sobre.** A janela agora relata duas identidades distintas: a engine
(`v9.0 (r4433)`) e o aplicativo Windows (`v0.7`). A decisão estabelecida é
que o aplicativo Windows é pré-1.0 enquanto a engine é madura.

**Acessibilidade e localização.** As superfícies de navegação e comando têm
dicas de ferramenta, rótulos de texto onde um ícone é ambíguo, nomes de Automação de Interface (incluindo
os botões de zoom e de página somente com ícone), atalhos de teclado e estados de foco e
desativado do Fluent. Toda string nova ou renomeada está nos seis dicionários
(`LocalizerTests` verifica completude e placeholders; o inglês continua sendo a
fonte autoritativa); corpos de licença, avisos, direitos autorais e nomes de marca permanecem
em inglês verbatim. A suíte tem 110 testes, incluindo os testes de Boas-vindas/navegação/
primeira área de trabalho, o teste de exibição da janela Sobre, o teste do dicionário de tema e
os testes de zoom/ajuste da consulta.

**Avaliação de faixa de opções.** Nenhuma faixa de opções foi introduzida. A superfície de comando do Designer
são dois grupos (paleta de inserção, edição) mais uma barra de visão; uma faixa adicionaria cromo
e tomaria espaço da tela sem ganho de descoberta nesta contagem de comandos. Uma faixa somente do
Designer vale revisitar apenas se o conjunto de elementos/comandos crescer
substancialmente (por exemplo, grupos completos de tipografia, alinhamento e layout de tabela).
As três áreas de trabalho têm comandos materialmente diferentes, então uma faixa
em todo o aplicativo seria mais complexa, não mais simples.

**Não feito (registrado, não defeitos).** Nenhum quarto destino Início; nenhum fechamento no aplicativo
para a tela de Boas-vindas. A cor da mesa do WebView2 do Viewer é lida quando o navegador é
criado, então uma troca de tema no meio da sessão precisa de reinicialização. O aplicativo WPF de referência
nomeado no briefing não estava presente na estação de trabalho; a direção
segue as orientações de design do Windows 11 da Microsoft, o tema Fluent nativo e a
arte MAD existente, com a paleta e o espaçamento centralizados para fácil
reajuste. O `docs/windows.md` público e suas traduções permanecem adiados.

## 6j. O fechamento do código de barras (2026-11-20)

O elemento de código de barras não é mais uma lacuna em nenhum dos lados da fronteira.

**Engine.** `MADBarcodes` compila aqui (toda subclasse de simbologia; `MADBarcodeView` e
`MADBarcodeCache` permanecem exclusivos da Apple), vinculando libpng 1.6.59 e zint 2.16.0 de
`libraries.conf`. A passagem de codificação de `MADBarcode` é compartilhada, e `-renderedPNGData` grava o
bitmap RGB do zint através do libpng sem Core Graphics, então a engine headless produz o mesmo
símbolo. `MADPrintPageElementBarcode`, `RptqDocumentElementBarcode+Extras` e
`MADDocumentObjectDataReferenceBarcode` estão na compilação headless; a caminhada de páginas coloca o PNG
em `MADReportLineRepresentation.imageData`, o fac-símile HTML o embute como um data URI (a
entrada é o texto `alt`), e o relatório JSON o nomeia com `"image": true`. Um código de barras com
`useStaticInput1`/`inputStatic1` renderiza essa string; um vinculado lê seu campo de consulta.

**serve.** `add-element` aceita `"kind": "barcode"` (Code 128, legível por humanos, estático
`MAD-2026`, 160×48, os padrões do Mac); `layout-model` carrega um objeto `"barcode"` aninhado
(id e nome da simbologia, opções, vinculação de entrada e uma `preview` PNG base64 do mesmo
núcleo de renderização); `set-element-content` edita a simbologia, o sinalizador legível por humanos, o estilo de borda e
a vinculação estática ou de campo; `duplicate-elements` copia as colunas do código de barras;
`barcode-types` retorna a tabela de nomes do MADBarcode como `{id, name}` ordenada por nome.

**WPF.** O botão Barcode da paleta insere um; a tela desenha a pré-visualização da engine
(recurso alternativo de texto quando o zint recusa); o inspetor mostra o seletor de simbologia, Show text, o
seletor de borda e o seletor de entrada (estática, que a caixa Text edita, ou um campo de consulta).
`DesignerAcceptanceTests.Barcode_InsertEditBindAndUnbind` e o teste rápido de documento criado o
fixam (as exportações HTML/JSON carregam o símbolo e seu texto), e os pins de bytes de London estão
inalterados porque os bytes de um documento sem código de barras não se moveram.

**Licença.** zint (BSD-3-Clause) e libpng (PNG Reference Library v2) estão na §10, na lista de componentes
da janela Sobre e em `ThirdParty/Licenses/` (ambos os textos já existiam).

## 6k. O fechamento de imagem (2026-11-20)

O elemento de imagem deixa de ser um espaço reservado. Nenhuma biblioteca foi adicionada: a coluna de imagem do
armazenamento já contém bytes PNG.

**Engine.** Fora da Apple, `MADReferenceImage` e `MADElementImage` são `NSData` — o próprio
formato de transmissão do armazenamento — então o modelo está pronto para headless e `RptqDocumentElementImage (Extras)`
ganhou o `-pngData` / `-setPngData:` portátil, que armazena os bytes verbatim em todos os lugares
(os acessores `-image` da Apple ainda codificam/decodificam a imagem onde UIKit/AppKit existe).
`MADPrintPageElementImage -renderedImageData` responde com o PNG armazenado, então
`MADReportLineRepresentation.imageData` — a costura do fechamento de código de barras — também carrega uma imagem:
o fac-símile HTML a embute como um URI `data:image/png;base64,…` e o relatório JSON a nomeia
`"image": true` sem texto. Na Apple, o caminho PDF ainda desenha o elemento e
`-renderedImageData` responde nil, que é o comportamento de exportação Mac pré-existente.

**serve.** `add-element` aceita `"kind": "image"` com um `"data"` base64 opcional (decodificado
antes de o elemento ser inserido, então uma requisição malformada não deixa nada para trás); `layout-model`
carrega um objeto `"image"` aninhado `{data}`; `set-element-content` aceita `"data"` (PNG base64;
vazio o limpa); `duplicate-elements` copia a imagem.

**WPF.** O botão Image da paleta insere um elemento; o inspetor mostra um
botão localizado "Choose Image…" para uma imagem selecionada (a linha do inspetor do Mac). O seletor decodifica qualquer
PNG/JPEG pelo WIC e o recodifica como PNG (`ImageFileEncoder`) antes de enviá-lo — a
coluna é sempre PNG, então o data URI HTML é honesto. A tela desenha a imagem armazenada e
recorre ao espaço reservado `[Image]` quando o elemento não tem nenhuma. `ImageElementTests` fixa
o protocolo, a recodificação do seletor e a tela; o teste rápido de documento criado adiciona uma
ao documento exportado.

## 6l. O fechamento do PDF (2026-11-20)

`mad export --format pdf` e o `export` do `mad serve` agora gravam um PDF no Windows, e a
metade Windows é a terceira pilha de bibliotecas headless que a compilação carrega.

**Bibliotecas.** `Windows/Engine/libraries.conf` fixa exatamente os pins Linux: pixman
0.46.4 e cairo 1.18.6 (tags git, commits fixados) e FreeType 2.15.0 (tarball), mais
o tarball de fontes Liberation 2.1.5. `build.ps1` compila o FreeType com seu próprio CMake
(clang-cl, estático, somente núcleo), depois pixman e cairo com Meson sob o ambiente MSVC
(`cl`), estaticamente e apenas com a superfície PDF. As compilações Meson encontram
suas dependências locais pelos arquivos `.pc` gerados e a mesma cunha pkg-config nativa do Windows
que a compilação do libpq introduziu (`Ensure-PkgConfigShim`, agora uma função para que
ambas as compilações a compartilhem). Três arquivos se juntam ao link: `cairo.lib`, `freetype.lib`,
`pixman-1.lib`; `msimg32` entra na lista de sistema para a superfície win32 do cairo.

**Fontes.** As faces Liberation são copiadas para `Engine/build/fonts`;
`MADReportExporterPDFCairo` procura `<exe>/fonts` primeiro (para que `mad.exe` encontre
`build/fonts` e um teste em `build/tests` encontre `build/fonts` por `<exe>/../fonts`),
depois os layouts instalados e `MAD_FONTS_DIR`.

**Escritor.** `MADReportExporterPDFCairo` em `MAD/Source` é o corpo não Apple de
`MADReportExporterPDF`; o corpo Apple está intocado e não vincula Cairo. O alvo
estrutural, o mapeamento de fontes e o determinismo são os de
`docs/project/MAD_PDF_LINUX.md`. `MADPDFExportTests` é o teste de aceitação em ambas as
engines; ele lê o PDF de volta e compara contagem de páginas, MediaBox, cada quadro e o texto
de cada linha com o oráculo `json-report`, verifica o código de barras e a imagem como
XObjects de imagem e verifica a igualdade determinística de bytes.

**Licenças.** cairo (MPL-1.1), pixman (MIT), FreeType (FTL) e as fontes Liberation
(SIL OFL 1.1) estão registrados em `THIRD_PARTY_LICENSES.md` §3.5 e §10, seus textos estão
em `ThirdParty/Licenses/`, e `WindowsLicenseRegistry` lista todos os quatro para a janela
Sobre. Nenhum adiciona obrigação de relink.

**Viewer.** O seletor de formato do WPF Viewer lista PDF primeiro, como o do Mac, e
o exporta pela forma de caminho do `serve` (`export` com um `path`), então a engine grava os
bytes do exportador e a resposta carrega a contagem de bytes. Os formatos de texto mantêm a
leitura de volta `data`, cuja decodificação UTF-8 é sem perdas para eles. Uma barra de progresso indeterminada e uma
linha de status "Exporting…" cobrem a chamada; as strings `Format.Pdf` e `Viewer.Exporting`
são distribuídas nos seis dicionários.

## 7. Versões do Windows suportadas

A matriz de SO suportados do .NET 10 (Windows 10 Enterprise 21H2/1809/1607, Windows
11) e a linha de base do GNUstep para Windows 10 1903+; testado no Windows 11 Enterprise
26H2 (build 26300). Windows 7/8 não é suportado pelo .NET 10.

## 8. Licenciamento de terceiros e a página Sobre do Windows

A engine Windows é uma terceira superfície de distribuição, registrada em
`docs/project/THIRD_PARTY_LICENSES.md` §10. Ela adiciona o runtime GNUstep à
superfície de conformidade:

* **GNUstep Base, gnustep-corebase e a biblioteca libiconv** são
  LGPL-2.1-or-later. A distribuição Windows deve carregar o texto LGPL-2.1, o
  aviso e a oferta escrita de relink em `ThirdParty/Licenses/README.md`.
* **libobjc2 (incluindo libBlocksRuntime) e libffi** são MIT; retenha os
  avisos.
* **libdispatch** é Apache-2.0 com a exceção do runtime Swift; distribua o texto
  completo.
* **FreeTDS e MariaDB Connector/C** são vinculados estaticamente sob a eleição
  LGPL-3.0 existente; a edição de `sybdb.h` do FreeTDS está marcada, e a oferta de
  relink existente agora nomeia a engine Windows.
* **As bibliotecas C** (SQLite, zlib, bzip2, libarchive, libpng, zint, OpenSSL,
  libpq) usam as entradas e textos existentes em `ThirdParty/Licenses/`.
* **Microsoft Edge WebView2** (o controle de pré-visualização do WPF Viewer, NuGet
  `Microsoft.Web.WebView2` 1.0.4314.35) é um produto Microsoft, não software
  open-source: o Evergreen WebView2 Runtime é instalado com o Windows 11 e o Edge
  e não é modificado nem redistribuído por este projeto. Ele é registrado
  com a licença BSD-3-Clause do SDK e os avisos de terceiros da Microsoft,
  os Termos de Licença de Software Microsoft do runtime e a atribuição deste projeto —
  tudo em `ThirdParty/Licenses/Windows/WebView2-LICENSE.txt`.
* **gnustep-make** é ferramenta de compilação GPL-3.0-or-later e não é distribuído; seu
  `Testing.h` é compilado apenas em binários de teste, que não são distribuídos. As ferramentas `iconv`
  do libiconv e os programas de teste do gnustep-corebase também não são
  distribuídos. As ferramentas de linha de comando do GNUstep Base (`gdomap`, `gdnc`,
  `defaults`, `plutil`, `gspath`) são GPL-3.0-or-later e não fazem parte de
  `mad.exe`; não os empacote sem o texto GPL e uma oferta de código-fonte
  correspondente.

A divisão exata entre DLL e estático é medida a partir do `mad.exe` compilado com
`dumpbin /dependents` (ou `llvm-objdump -p`) e registrada no relatório da Fase 3b;
ela não é inferida do layout da cadeia de ferramentas. A compilação e qualquer pacote
devem copiar `ThirdParty/Licenses/` e `NOTICE`.

A janela **Sobre** do WPF (prova do shell da Fase 5, concluída na Fase 6e; a
separação de versão engine/aplicativo chegou na Fase 6f) espelha
as três abas do Mac — Overview, License & Notice e Acknowledgements — e
lista todo componente acima, incluindo WebView2, com os textos de
`ThirdParty/Licenses/Windows/` e os textos-raiz compartilhados e a oferta escrita
LGPL. A lista de Acknowledgements é a lista de componentes do Windows, não a do aplicativo
Apple; a aba License & Notice carrega o aviso MIT/marca e a oferta de
relink do Windows; a Overview carrega o aviso de tradução assistida por máquina. Seu
cromo é localizado, enquanto todo corpo de licença, aviso de componente, nome de licença
e linha de direitos autorais permanece em inglês verbatim (D6/§8 de
`MAD_APP_LOCALIZATION.md`). As telas Sobre existentes do iOS e do macOS permanecem
exclusivas da Apple: elas listam as bibliotecas C que o aplicativo Apple vincula e não devem afirmar que o
aplicativo Apple vincula o runtime GNUstep. O `docs/windows.md` público e a
entrada do Windows no `README.md` chegaram com a versão 0.7 não assinada (2026-11-21);
a página está presente nos seis idiomas sob o contrato de documentação
(`docs/project/LOCALIZATION.md`). O workflow de verificação do Windows
(`.github/workflows/windows.yml`) testa as suítes .NET contra o
ativo de engine `mad-windows-x64.zip` anexado ao `v0.7.0`;
`Windows/package.ps1` monta tanto esse ativo quanto o zip de versão do aplicativo.

## Bancos de dados de teste

As três suítes de driver ativas (Fase 3b) são exercitadas contra os mesmos servidores de teste Docker
fixados que as compilações Apple/Linux usam, executados como **contêineres Windows locais vinculados a `127.0.0.1`**
(o Mac mantém a publicação em todas as interfaces para que a imagem Linux e os fixtures da CLI alcancem seus contêineres por nome). Os pontos de entrada
multiplataforma são `TestDatabase/test-databases.sh` (Git Bash) e
`TestDatabase/test-databases.ps1` (PowerShell), que delegam aos três
scripts por framework; `TestDatabase/README.md` é a referência.

```powershell
.\TestDatabase\test-databases.ps1 -Action download   # fetch datasets, no Docker
.\TestDatabase\test-databases.ps1 -Action up         # create/start all three
.\TestDatabase\test-databases.ps1 -Action status     # -Service mysql|tds|postgres
.\TestDatabase\test-databases.ps1 -Action verify
.\TestDatabase\test-databases.ps1 -Action env        # print the env block
```

O bloco `env` é o contrato que as suítes ativas da Fase 3b leem; aplique-o na
mesma sessão que `build.ps1`:

```powershell
$env:MAD_MYSQL_TEST_HOST = "127.0.0.1"; $env:MAD_MYSQL_TEST_PORT = "13306"
$env:MAD_MYSQL_TEST_USER = "root"; $env:MAD_MYSQL_TEST_PASSWORD = "root"
$env:MAD_MYSQL_TEST_SCHEMA = "employees"
$env:MAD_TDS_TEST_HOST = "127.0.0.1"; $env:MAD_TDS_TEST_USER = "sa"
$env:MAD_TDS_TEST_PASSWORD = "Root1@Root2"; $env:MAD_TDS_TEST_DATABASE = "AdventureWorksLT2022"
$env:MAD_PG_TEST_HOST = "127.0.0.1"; $env:MAD_PG_TEST_PORT = "5432"
$env:MAD_PG_TEST_USER = "mad"; $env:MAD_PG_TEST_PASSWORD = "mad_test_pw"
$env:MAD_PG_TEST_DATABASE = "chinook"
```

Não há `MAD_TDS_TEST_PORT` — a suíte TDS fixa 1433. Os resultados de compilação dos drivers
estão documentados no relatório da Fase 3b, não aqui.

## Documentos relacionados

* `docs/project/MAD_LINUX.md` e `Linux/README.md` — a compilação Linux que esta
  compilação Windows espelha.
* `docs/project/MAD_MACOS.md` e `Mac/README.md` — o aplicativo nativo para macOS
  cujo comportamento o aplicativo WPF espelhará.
* `docs/project/THIRD_PARTY_LICENSES.md` §10 — o registro de licenciamento
  da engine Windows; `ThirdParty/Licenses/` e `ThirdParty/Licenses/Windows/` — os
  textos e a oferta escrita de relink.
