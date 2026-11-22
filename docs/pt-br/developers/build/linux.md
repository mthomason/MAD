---
layout: default
title: "Compilar a engine no Linux"
description: "A compilação Docker, os doze frameworks headless e suas suítes."
lang: pt-BR
---

# Compilar a Engine MAD no Linux — uma avaliação técnica

Esta página registra a compilação Linux: a imagem Docker, a cadeia de ferramentas fixada, os doze frameworks headless e as suítes que eles executam. `Linux/README.md` tem os comandos do dia a dia.

*Escrito na data original; fatos do estado atual reconciliados em 2026-11-22.*

Escrito em 2026-10-04 contra `master` em `c807eeb4d`. A auditoria de dependências (§4) e a
pesquisa de ecossistema (§5-6) em que este documento se baseia foram ambas produzidas no mesmo dia:
a auditoria com grep no diretório de código-fonte de cada framework, a pesquisa a partir de fontes primárias
(release notes, repositórios de pacotes, listas de discussão do projeto). Onde a evidência
era escassa, isso é dito. Este documento é o companheiro técnico de `MAD_FUTURE.md`
§5.1, que esboçou a matriz de plataformas; este é o mergulho.

---

## 1. A pergunta, respondida

Isto pode compilar no Linux? **Sim, condicionalmente — nos dois sentidos.**

- O código que deve compilar — a engine headless — está, por medição, já
  quase livre de dependências Apple. As duas que restam (Core Data e
  UIKit/CoreGraphics) ou estão em meio à migração ou são enumeradas arquivo por arquivo, e
  nenhuma está no caminho de atualização.
- O ecossistema que deve hospedá-lo — Objective-C com Foundation no Linux — existe,
  está empacotado em toda grande distribuição e executa um servidor de groupware de produção
  hoje (SOGo, empacotado no Debian contra GNUstep Base 1.31.1). É de nicho, sua
  cobertura de API moderna não está verificada nas margens, e sua história de UIKit não
  existe — mas este código não precisa de UIKit no Linux. Precisa da engine.

Os dois asteriscos: **o Foundation do GNUstep está presente mas não verificado** para as
APIs exatas nas quais este código mais se apoia (`NSPredicate`/`NSExpression`, arquivamento com chave,
`NSURLSession`), e **não existe UIKit realista no Linux** — o que está bem,
porque a auditoria mostra que o código já confina UIKit a arquivos nomeados, e o
plano de renderização sai do UIKit de qualquer forma.

---

## 2. A questão dos dois produtos: reescrever ou compilar e chamar

A escolha que o usuário colocou: reescrever tudo em Python e manter dois produtos,
ou compilar uma vez e fazer o Python chamar a engine. A auditoria a resolve.

**A engine é grande.** O conjunto de frameworks headless — `MADFoundation` (65 arquivos h+m),
`MADCocoaExtensions` (44), `MADDataStructures` (36), `MADFileManager` (30), `MADAPI`
(33), `MAD` (403), `MADSqlite3` (64), `MADMySQL` (41), `MADTds` (3), `MADTdsClient`
(8) — tem cerca de 727 arquivos. Uma reescrita em Python duplica não apenas volume, mas
*comportamento que é fixado por testes e duramente conquistado*: o gerador de SQL, o
caminho de ingestão do `MADDataTableFast` (200.000 linhas em 1,16 s, medido por benchmark), os mapeamentos de tipo
dos drivers (o tratamento moderno de data/hora do SQL Server existe apenas porque testes ativos
o pegaram duas vezes), a família de sentinelas nulas, o leitor do armazenamento. Duas implementações
disso divergem; a suíte fixa apenas uma. Isso não é "dois produtos", é um produto
e um passivo.

**A superfície de integração já existe.** A CLI *é* o contrato: `mad inspect` → metadados, `mad query` → SQL, `mad refresh` → linhas, `mad export` → formatos, com
códigos de saída que distinguem documento ruim (2) de servidor inacessível (3) de consulta
falha (4). Um serviço Python a chama como subprocesso com `--format json` e obtém
o relatório. A sobrecarga de subprocesso é irrelevante nas escalas de tempo de atualização (os exemplos
atualizam em 0,02-1,2 s; o spawn de processo é ~10 ms). Se a incorporação em processo for algum dia
medida como importante, os mesmos fontes podem compilar uma pequena biblioteca de ABI C para
ctypes/CFFI — mas isso é opcional, não pré-requisito.

**Sobre a razão declarada para preferir Python — a conexão de drivers.** É verdade que o ecossistema
de conectores do Python é amplo, e um `pip install` alcança bancos de dados para os quais este projeto
não tem driver. Mas para as fontes que existem hoje a conexão já é
neutra em linguagem: os drivers MAD ficam sobre freetds e MariaDB Connector/C — as mesmas bibliotecas C
que um programa Python ou C vincularia — e ambos compilam nativamente no Linux (§7).
Compilar a engine move essa conexão para o Linux sem mudança. Onde o Python genuinamente
tem vantagem é em *novos* tipos de fonte (Postgres, BigQuery, REST), e ali a resposta
certa é a costura de extensibilidade que o projeto já promete: uma subclasse de `MADDatabase`
que retorna um esquema e linhas. Um driver que fala HTTP se comporta
identicamente em Objective-C e Python; o Python compra mais conectores prontos, não
um núcleo mais fácil.

**A troca honesta, dita claramente:** esta é uma escolha entre manter *duas
implementações* (Python + Objective-C) com risco permanente de divergência e manter
*uma implementação em uma cadeia de ferramentas de nicho* (clang + libobjc2 + GNUstep) com
risco de ecossistema. Este documento recomenda a última, com um gatilho mensurável para
revisitar: a §9 nomeia o ponto de verificação. A única coisa que torna a recomendação
vinculante é a **forma da exportação JSON** — o contrato Python é tão bom quanto seu
esquema, e defini-lo é a decisão 1 na §10.

E se uma reescrita algum dia acontecer, a linguagem certa é Swift no Linux — não Python
— porque o armazenamento portátil SQLite (o trabalho da Fase C) já é um contrato
neutro em linguagem: qualquer um dos lados que escreva o armazenamento, o outro o lê.

---

## 3. O que deve compilar e o que não deve

| Framework | Necessário headless | Por quê / por que não |
|---|---|---|
| `MADFoundation` | sim | a base: operações, fábrica de URL, chaveiro (excluível), registro |
| `MADCocoaExtensions` | sim | auxiliares usados em todo lugar (11 arquivos UIKit, mas excluíveis) |
| `MADDataStructures` | sim | 0 importações Apple; 3 arquivos C++ (precisa de libc++) |
| `MADFileManager` | sim | 0 importações Apple; coordenador de nuvem excluído (o iCloud está sendo excluído na Fase D de qualquer forma) |
| `MADAPI` | sim | camada de conexão; 3 arquivos UIKit são controladores de visão, não headless |
| `MAD` | sim | o difícil: 29 UIKit, 34 CoreData, 15 CoreGraphics de 403 |
| `MADSqlite3` | sim | 0 importações Apple; `MADArrayCaching` (o armazenamento `.madac`) é 100% limpo |
| `MADMySQL` | sim | 0 importações Apple |
| `MADTds` / `MADTdsClient` | sim | 0 importações Apple |
| `MADExplorer` | não | interface do explorador de arquivos (19 de 32 arquivos importam UIKit) |
| `MADBarcodes` | sim | o núcleo de codificação + PNG é portátil (zint + libpng); apenas `MADBarcodeView` e `MADBarcodeCache` ficam do lado Apple |
| `MADFeedback` | não | sem uso e sem manutenção |
| `Scrimpter` | não | 0 importações Apple, mas sem uso |
| `MADDesigner` (aplicativo) | não | 302 arquivos UIKit; a interface permanece nas plataformas Apple |

Direção das dependências: tudo se apoia em `MADFoundation`; os drivers herdam de
`MADDatabase` em `MAD`, enquanto os arquivos `Constructor` de `MAD` importam os drivers — o
ciclo conhecido (`ROADMAP.md` §3.4). O registro de drivers (`ROADMAP.md` §5.1) importa para o
Linux em dobro: quebra esse ciclo e é o que permite que uma compilação Linux vincule
drivers como plugins em vez de uma pilha importada rigidamente.

---

## 4. A auditoria medida

Arquivos que importam cada framework Apple, por diretório de código-fonte de framework (um arquivo que
importa vários cabeçalhos UIKit conta uma vez):

| Framework | total | UIKit | CoreData | CoreGraphics | Security | os/log | CoreFoundation | dispatch |
|---|---|---|---|---|---|---|---|---|
| MADFoundation | 65 | 4 | 0 | 0 | 1 | 9 | 3 | 1 |
| MADCocoaExtensions | 44 | 11 | 0 | 3 | 0 | 1 | 0 | 0 |
| MADDataStructures | 36 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| MADFileManager | 30 | 0 | 0 | 0 | 0 | 2 | 0 | 5 |
| MADAPI | 33 | 3 | 0 | 0 | 0 | 4 | 0 | 2 |
| MAD | 403 | 29 | 34 | 15 | 1 | 15 | ~19 | 3 |
| MADSqlite3 | 64 | 0 | 0 | 0 | 0 | 4 | 3 | 5 |
| MADMySQL | 41 | 0 | 0 | 0 | 0 | 2 | 0 | 1 |
| MADTds | 3 | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| MADTdsClient | 8 | 0 | 0 | 0 | 0 | 0 | 0 | 3 |

A cauda longa fora dos pilares, cada item com uma disposição:

| Item | Sítios | Disposição |
|---|---|---|
| `os_log` (tudo converge por `madlog.h`, duas cópias) | 9+15+4+2+… arquivos importam a cunha | reescrever um cabeçalho de ~20 linhas contra syslog/printf; nenhum outro sítio de chamada muda |
| `asl.h` (Apple System Log obsoleto) | `MADocument.m:107`, `RptqDocumentElement+Extras.m:60` | trocar pela cunha madlog |
| `copyfile.h` | `MADArchiveManager.m:14`, `madtar.m:18` | rename/link POSIX |
| `mach/machine/vm_param.h` (tamanho de página) | `MADocument.m:108` | `getpagesize()` |
| DNS reverso `CFNetwork`/`CFHost` | `BDHost.m` (1 arquivo) | `getaddrinfo` |
| coordenador de nuvem `NSMetadataQuery` | `MADFileManager` (3 arquivos) | excluir — o iCloud é excluído na Fase D |
| `Security.framework` / `SecItem` | `MADKeyChain.m`, `MADOperationKeyChainGet.m` + teste | excluir — o caminho de atualização recebe credenciais de uma dependência de operação, nunca do chaveiro; a CLI já substitui por `--credentials` |
| proteção `AppKit` em `MADApplication.m` | 1 arquivo | adicionar um ramo `TARGET_OS_LINUX` |
| escala de `UIScreen` em `MADURLFactory.m:32` | 1 linha | retornar 2.0 |
| tarefa em segundo plano de `UIApplication` em `MADOperation.m:549-563` | 1 recurso protegido | remover com `#if` |
| CoreFoundation (`CFNumber`/`CFData`/`CFString`, toll-free bridging) | ~25 sítios em MAD, MADFoundation, MADSqlite3 | equivalentes GNUstep / reescrita mecânica; CoreBase (o clone CF do GNUstep) é imaturo, não confie nele |
| transformadores de valor UIKit (`MADColorTransformer`, `MADLocaleTransformer`, `MADPngImageTransformer`) | 3 arquivos, atualmente arrastados através da fronteira de alvo da CLI | **morrem com a Fase D** — a migração do armazenamento converte os transformáveis em escalares portáteis |

SystemConfiguration: zero ocorrências. CommonCrypto: zero nos frameworks (somente no aplicativo,
validação de recibo). `@import`: zero — tudo é `#import`, que é o que
o GNUstep quer.

---

## 5. Os três pilares

### 5.1 Core Data — a migração em andamento é a alavanca

34 arquivos MAD importam Core Data; `MADocument` é um `UIManagedDocument`; o armazenamento é um
`MAD.momd` compilado; `MADAtomicStore` fica por baixo. Nada disso existe no Linux,
e nada disso precisa existir — porque o projeto já o está substituindo: `MAD_STORE_MIGRATION.md`
Fase C chegou em 2026-10-03, e `RptqStoreContext.h` declara "Nothing here imports
Core Data." A Fase D exclui `UIManagedDocument`, os transformadores de valor, o
`.xcdatamodel` e a maquinaria de iCloud — o que simultaneamente mata vários itens da §4
(os transformadores de valor, o coordenador de nuvem, o `MAD.momd` que a CLI
atualmente copia do bundle do aplicativo).

**Concluir as Fases C e D é o passo de maior alavancagem em direção ao Linux**, e é
trabalho que o projeto já possui para portabilidade, não esforço específico de Linux. Uma nota do plano de migração: documentos antigos da
era do iCloud são recuperados pelo usuário através do aplicativo Arquivos do iOS e convertidos na abertura
(`MADStoreConverter`) — a maquinaria de iCloud não é necessária para recuperá-los, então
a exclusão dela na Fase D não deixa nada preso.

### 5.2 UIKit / CoreGraphics — 29 arquivos, a maioria trivial

Os 29 arquivos UIKit do MAD se decompõem em:

| Tipo | Contagem | Disposição |
|---|---|---|
| structs `CGGeometry` (`CGRect`/`CGSize`/`CGPoint`) | 15 arquivos | structs simples — replicar as definições; zero desenho |
| `UIEdgeInsets` no formatador | ~3 arquivos | substituir pela matemática de struct |
| `UIFont`/`UIColor`/`UIImage` em código de modelo/layout | vários | equivalentes leves para métricas e estilos armazenados |
| `UIActivityItemProvider` / folha de compartilhamento | 2 arquivos | não headless — excluir |
| `UIScreen`/`UIApplication` | 2 arquivos | linhas únicas, §4 |
| `MADPrintPageRenderer` + contextos PDF `UIGraphics` | a costura de exportação | **o trabalho de verdade** — veja abaixo |
| base `UIManagedDocument` de `MADocument` | a classe de documento | morre com a Fase D |

Boa notícia notável: o uso de UIKit em `MADReportFormatter.m` é efetivamente vestigial
(um `UIEdgeInsetsMake`, uma importação não usada de `UIPrintInteractionController`), e
`MADArrayCaching` — o armazenamento de páginas renderizadas `.madac` — já é 100% livre de UIKit/CoreData.
Ele compila em qualquer Foundation ObjC hoje.

**A decisão do renderizador.** Contextos PDF do CoreGraphics não têm equivalente no Linux. O
escalonamento de menor custo: verbos do caminho de dados verdes primeiro; `export --format json` /
`--format csv` depois (Foundation puro — e estes são os formatos que um chamador Python
quer de qualquer forma); páginas HTML/SVG depois (sem dependências nativas); PDF por último, colocando um
escritor cairo ou libharu atrás do mesmo loop de desenho do `MADPrintPageRenderer`, ou
mantendo a renderização de PDF em workers macOS enquanto o Linux serve dados e páginas. O
sinalizador `--deterministic` que a CLI já aplica como patch de bytes em PDFs é a semente de um
teste de renderizador multiplataforma.

### 5.3 Foundation no GNUstep — existe, verificado em parte, arriscado nas margens

O que a pesquisa verificou, a partir de fontes primárias:

- **GNUstep Base 1.31.1** (2025-02-28) é atual; o master está ativo (notável
  trabalho em NSURLSession mesclado em 2026-08). A cadência de lançamentos é lenta — aproximadamente anual.
- Presentes e funcionais: `NSJSONSerialization`, `NSUUID`, `NSRegularExpression`
  (ICU), `NSISO8601DateFormatter`, `NSDateFormatter` (respaldado por ICU — `libicu-dev` é uma
  dependência de compilação obrigatória), `NSOperationQueue`, property lists, `NSXML*`
  (libxml2), arquivamento com chave visando compatibilidade com o XML da Apple.
- **`NSURLSession` é o ponto fraco**: lançado na 1.31.0 como "nova implementação
  experimental", explicitamente não uma classe suportada; o trabalho de desbloqueio de 2026
  (compilar sem blocks) está mesclado, mas a estabilização não terminou. Não construa
  o produto Linux sobre ele — prefira conexões diretas de driver (que é o que a
  atualização faz de qualquer forma) ou libcurl.
- **`libdispatch` é opcional pela própria política do GNUstep** — o mantenedor da base o chama
  de "não está em um estado portátil/confiável o suficiente" para depender dele. Este
  código usa dispatch amplamente (`dispatch_once`, `dispatch_sync`, semáforos).
  swift-corelibs-libdispatch é C e chamável de ObjC (com
  `OS_OBJECT_HAVE_OBJC_SUPPORT=1`), e o *núcleo* usado aqui é a parte estável —
  mas trate dispatch como uma camada que pode ter cunha, não como algo garantido.
- **CoreBase** (o clone CoreFoundation do GNUstep) é imaturo — o guia de compilação diz
  para não confiar nele. Os ~25 sítios CF recebem equivalentes GNUstep.
- **Não verificados nas margens, e estruturais aqui:** `NSPredicate`/`NSExpression`
  (13+ sítios de importação em MAD), `unarchivedObjectOfClass:` (API do iOS 11+ — a cobertura
  do GNUstep varia), comportamento de `NSOperation`+KVO. A presença é provada; a paridade
  de comportamento não é. Este é o risco honesto, e é exatamente o que os fixtures da §8
  existem para testar.

**A prova de existência:** SOGo, um servidor de groupware Objective-C, é distribuído no Debian
sid com dependência rígida de `gnustep-base-runtime (>= 1.31.1)` — o Foundation do GNUstep
executando como daemon de produção em escala. O Darling impulsiona o libobjc2. Ferramentas ObjC não GUI
no Linux são normais, não exóticas.

---

## 6. Cadeia de ferramentas e ecossistema

- **Runtime: libobjc2 2.3** (2025-09-16) — a única maneira de obter Objective-C moderno
  no Linux. ARC, blocks, referências fracas, `@synchronized`, ivars não frágeis, a
  ABI gnustep-2.0. **ARC exige clang + libobjc2**, e os pacotes das distribuições
  tradicionais compilam o GNUstep contra o runtime GCC sem ARC — então o ambiente de compilação
  é montado a partir da fonte (ou do empacotamento libobjc2 do Fedora), não dos padrões do
  Debian. Este é um compromisso operacional real.
- **Blocks**: o libobjc2 2.3 pode consumir o BlocksRuntime do swift-corelibs-libdispatch;
  `libblocksruntime-dev` também está empacotado. Os blocks do código são padrão.
- **Exceções**: clang + libobjc2 fornece exceções nativas baseadas em unwinder; os
  dois mecanismos de exceção do GNUstep não devem ser misturados em um mesmo executável — compile tudo
  com o caminho nativo.
- **Sem módulos clang / suporte a `@import`** — e o código já usa `#import`
  em todo lugar, então isso não custa nada.
- **UIKit no Linux: confirmadamente ausente.** A memória do usuário sobre a Microsoft é o WinObjC —
  o Windows Bridge for iOS, um subconjunto deliberadamente parcial de UIKit no Windows, último
  avanço em 2022, arquivado em 2025-05-28. O Chameleon (UIKit no macOS) morreu em 2015.
  `gnustep/libs-uikit` (junho de 2026) é um experimento de 26 commits com uma estrela. A
  lição a tirar até da Microsoft abandonando a ideia: **não porte o UIKit.**
  A auditoria mostra por que este projeto não precisa — o UIKit já está confinado a
  arquivos nomeados, e tudo o que é headless renderiza por dados, não por visões.
- **Testes: sem XCTest para ObjC no Linux** (swift-corelibs-xctest é somente Swift).
  O `gnustep-tests` + `Testing.h` do próprio GNUstep é o executor de testes sem dependências;
  o UnitKit está arquivado. A camada de aceitação real são os fixtures da §8, não os testes unitários.
- **Criptografia e segredos**: sem porta do CommonCrypto (o próprio conselho do projeto GNUstep é
  `#ifdef` para OpenSSL ou GnuTLS); sem chaveiro (o análogo funcional é
  libsecret/Secret Service, ou keyutils para segredos de sessão) — e conforme a §4 a
  engine headless não precisa de nenhum dos dois.

---

## 7. As bibliotecas C — a parte fácil, com um bloqueio de licença

Toda biblioteca fornecida é C portátil com uma compilação upstream autoconf/cmake:

| Biblioteca | Versão | Licença | Compilação Linux |
|---|---|---|---|
| sqlite3 | 3.53.3 | domínio público | nativa; os sinalizadores de fixação de formato já vivem em `Compressor/sqlite3.xcconfig` |
| zlib | 1.3.2 | Zlib | nativa |
| openssl | 3.5.9 | Apache-2.0 | nativa |
| bzip2 | 1.0.8 | tipo BSD | nativa |
| libpng | 1.6.59 | PNG Reference v2 | nativa |
| libarchive | 3.8.9 | BSD-2 | nativa |
| freetds | 1.4.27 | LGPL-2.0+ | nativa (a receita tem um detalhe BSD de `sed -i ''` a corrigir) |
| mysqlclient | 8.4.10 | **GPL-2.0 + exceção FOSS** | nativa — **mas a GPL é um bloqueio de distribuição para um binário proprietário**; o MariaDB Connector/C (LGPL-2.1) é a substituição já nomeada em `LICENSE_COMPLIANCE_PLAN.md` |
| zint | 2.16.0 | BSD-3 | nativa; o backend de código de barras que o núcleo PNG do MADBarcodes vincula (com o libpng acima) |

Mais o C no repositório (`miniz`, `madmath`, `madpng`, `madtar`, `madlib` — todos portáteis,
todos com licença permissiva). Apenas a camada de *empacotamento* do Compressor é específica da Apple
(`xcrun`, `-isysroot`, `lipo`, `xcodebuild -create-xcframework`); um driver Linux
descarta tudo isso, executa as mesmas compilações upstream nativamente e termina com `ar` +
instalação de includes simples. A complexidade específica do iOS (a compilação de ferramentas de host em duas etapas
do mysqlclient, o cabeçalho gerado por plataforma do freetds) *desaparece* em compilações nativas.
Um alerta da auditoria: o conector MySQL de Karl Kraft não tem licença —
substitua-o pela mudança para MariaDB, não o distribua.

---

## 8. O plano de compilação e teste

- **Sistema de compilação**: CMake para os doze frameworks headless mais a CLI — um conjunto de sinalizadores
  (`clang`, `-fobjc-arc`, `-fblocks`, o `gnustep-config --objc-flags` do GNUstep).
  A dança de cópia de `.momd` em `CLI/build.sh` desaparece com a Fase D, e
  o alcance de `REFRESH_SOURCES` através da fronteira de alvo desaparece com a
  mudança de `MADOperationRefresh` (`ROADMAP.md` §3.4).
- **Camada de aceitação**: os fixtures de ida e volta em `MAD_CLI.md` §6, executados no Linux
  e comparados byte a byte contra a execução macOS/simulador — fidelidade do contêiner, legibilidade
  v0, ida e volta sem cache, códigos de saída. O cache de linhas e a saída JSON/CSV
  são comparáveis byte a byte; o PDF é comparável estruturalmente apenas até que exista um renderizador.
  Esses fixtures são também o *teste de cobertura do Foundation do GNUstep*: execute-os cedo, trie cada falha,
  e as incógnitas da §5.3 se resolvem empiricamente em vez de lendo índices de API.
- **CI**: um job Linux na matriz de testes executando os fixtures; a suíte continua sendo a
  suíte de simulador que é hoje.

### 8.1 O caminho de implantação: contêineres, não compilação cruzada

Como isto realmente é compilado e distribuído?

- **Não faça compilação cruzada a partir do macOS.** Um runtime Objective-C mais GNUstep Base é
  acoplado ao host — compilá-lo de forma cruzada contra um sysroot Linux a partir de um Mac é um projeto
  de pesquisa, não um passo de compilação. O aplicativo iOS continua compilado pelo Xcode no Mac; a engine
  Linux é *compilada no Linux*.
- **O Docker é o ambiente de compilação.** Um Dockerfile, dois estágios: um estágio de cadeia de ferramentas
  que compila da fonte clang + libobjc2 2.3 + GNUstep Base (necessário para ARC — §6), e
  um estágio de compilação que executa o driver Linux do Compressor para as bibliotecas C (§7) e depois
  CMake para os doze frameworks e a CLI. A mesma imagem serve como ambiente de CI
  e artefato de implantação.
- **Qual Linux suportar: uma linha de base, em um contêiner.** Escolha uma única linha de base —
  Debian stable ou um Ubuntu LTS — e compile ali, porque a restrição real de compatibilidade
  é a glibc: tudo o que é vinculado é compilado da fonte exceto a libc, então
  "Linux suportado" significa "a glibc da imagem que distribuímos". Compilar na glibc mais antiga
  que você aceita é a regra. Distribuir um contêiner significa que qualquer host com Docker
  executa o produto sem uma matriz de distribuições.
- **O fluxo de trabalho é o script-e-compile ao qual você já está acostumado, automatizado.**
  `git clone` no compilador Linux → as receitas do Compressor compilam sqlite, zlib, openssl,
  bzip2, libpng, libarchive, freetds e MariaDB da fonte → o CMake compila os
  frameworks com um conjunto de sinalizadores → vincula `mad` → executa os fixtures de ida e volta (acima) →
  marca a imagem. Um runner ubuntu do GitHub Actions é o lugar padrão para isso acontecer
  em cada commit.
- **O papel do macOS.** O Mac continua sendo o host de desenvolvimento do aplicativo, da CLI de
  simulador e das saídas de fixture de referência. As duas plataformas são unidas pelo git e pela
  comparação de bytes dos fixtures — a compilação Linux é *verificada contra* as saídas
  do Mac, que é a garantia de portabilidade tornada executável.

---

## 9. Esforço e fases

Blocos, na ordem em que devem ser feitos:

| Fase | Trabalho | Caráter |
|---|---|---|
| A | Concluir as Fases C + D da migração do armazenamento | trabalho de portabilidade já possuído; remove Core Data, iCloud, transformadores de valor, `.momd` — a maior alavanca única para Linux |
| B | Spike de cadeia de ferramentas: um Dockerfile que compila da fonte clang + libobjc2 + GNUstep Base; compilar um subconjunto de MADFoundation | prova o ambiente e se torna a imagem de compilação/CI; dias |
| C | A lista de cunhas da §4 | limitada e enumerada — madlog, asl, copyfile, vm_param, CFHost, MADApplication, UIScreen, tarefa em segundo plano, ~25 sítios CF, exclusões |
| D | **O ponto de verificação**: verbos do caminho de dados verdes no Linux — `inspect`, `schema`, `query`, `refresh` contra ambas as amostras, fixtures comparados byte a byte | se isto não estiver verde após C, a cauda do Foundation do GNUstep é maior que o estimado, e *esse* é o momento de revisitar a questão da reescrita — não antes |
| E | Exportação: JSON/CSV (o contrato Python), depois páginas HTML/SVG, depois a decisão de PDF (cairo/libharu vs renderização do lado macOS) | Foundation puro primeiro; renderizador por último |
| F | Driver Linux do Compressor (compilações nativas, coluna da matriz, troca para MariaDB, correção do sed do freetds) + polimento do CMake + linha de CI + a imagem implantável | mecânico, condicionado por licença |

Racional da ordenação: A é trabalho possuído, B é barato e reduz o risco de tudo, C é
enumerável, e D é o go/no-go honesto. Nada em E ou F é necessário para *responder*
à pergunta; eles são necessários apenas para *distribuir*.

**Status da Fase A (2026-10-06).** O Core Data está fora do framework MAD: `MADocument` é um
`UIDocument`, o conversor legado e o modelo compilado vivem no alvo do aplicativo
atrás de `MADLegacyStoreConversion`, um documento convertido poda seus arquivos Core Data, e a
varredura framework/MADDesigner removeu as importações, tipos e código morto restantes. Os transformadores
de valor, o painel de nuvem do explorador e os direitos de iCloud são mantidos por decisão
do usuário — estão do lado do aplicativo, então não bloqueiam a compilação headless; o código
de nuvem do gerenciador de arquivos permanece onde está, sem uso (segundo o usuário: não necessário para o
modo headless). O que resta antes de B são quaisquer exclusões de nível de arquivo da §4 que o
spike da cadeia de ferramentas prove necessárias.

**Status da Fase B (2026-10-06).** O spike da cadeia de ferramentas está verde no
branch `linux-port`, mesclado em `master` em 2026-10-16 (`524e0d86e`):
`Linux/` compila uma imagem Docker — Ubuntu 24.04 com o clang 18 da distribuição
(o requisito "da fonte" da §6 é sobre o GNUstep ser compilado contra
libobjc2, não sobre o LLVM), mais libobjc2 2.3, libdispatch 6.1.3,
gnustep-make 2.9.3 e gnustep-base 1.31.1 compilados da fonte, fixados em `Linux/toolchain.conf` —
compila 23 dos 27 arquivos de implementação de MADFoundation e `madlib.c` contra
GNUstep, e executa 15 executáveis de teste (14 suítes portadas e uma sondagem da cadeia de ferramentas)
dentro dela: todos passam, com 5 necessidades registradas e 10 itens de relatório da sondagem.
`./Linux/build.sh` é o ponto de entrada; a suíte iOS permaneceu verde (118 testes) como
prova de que as seis pequenas proteções de plataforma que o trabalho exigiu são neutras em comportamento
na Apple.

A sondagem aposenta a maior parte da lista de riscos da §5.3 para o Foundation que a engine realmente
usa: ARC e zeragem de fracos, blocks, exceções, `@synchronized`, KVO (manual e
chaves dependentes), máquina de estados KVO de `NSOperation`, `NSPredicate
predicateWithFormat:@"error != nil"` (o predicado exato do MAD), dispatch incluindo
o esvaziamento da fila principal sob um executável simples, JSON, datas, plists, descritores de ordenação,
fluxos e arquivamento com chave no caminho permissivo, todos passam. Duas lacunas
são registradas, não escondidas: o arquivador do GNUstep não tem suporte a codificação segura
(`requiringSecureCoding:YES` retorna nil; o caminho permissivo faz ida e volta), e a
`NSOperationQueue` do GNUstep remove sua observação de `isReady` em toda
notificação enquanto a máquina de estados do MADOperation costumava notificar `isReady` mais
de uma vez por enfileiramento — a segunda remoção lançava exceção, então um MADOperation não podia
ser enfileirado no Linux. Isso está resolvido (2026-10-06, `linux-port`, agora em `master`):
o MADOperation conduz o avanço de estado explicitamente a partir de `-willEnqueue` e envia
KVO para `isReady`/`isExecuting`/`isFinished` apenas em mudanças reais de valor, então a
fila vê uma notificação, como na Apple; os testes Linux o verificam claramente em
ambas as plataformas e as necessidades caíram para 3. O mecanismo está escrito em
`Linux/README.md` junto com os arquivos excluídos e as cunhas menores
(`NSOperation.name`, `qualityOfService`, `NSDataWritingFileProtection*`,
`QOS_CLASS_DEFAULT`, contêineres de grupo de aplicativos). As exclusões de nível de arquivo que a Fase A antecipou acabaram sendo exatamente
os quatro arquivos da §4 (`BDHost`, `MADApplication`, `MADKeyChain`, `MADURLFactory`); a
limpeza de cabeçalhos autocontidos que o prelúdio costumava encobrir está feita (2026-10-06):
todo cabeçalho e fonte na compilação Linux importa o que usa, e
`Linux/Compat/MADCompat.h` está reduzido a uma única lacuna real de plataforma, a propriedade
`name` de `NSOperation`.

**Status da Fase C (2026-10-06).** A lista de cunhas da §4 está limpa e a compilação não é
mais um spike: todos os doze frameworks headless da tabela da §3 compilam e vinculam
dentro da imagem — MADFoundation 26 de 27 arquivos, MADDataStructures 17,
MADFileManager 10 de 11, MADCocoaExtensions 7 de 17, MADAPI 8 de 11,
MADSqlite3 26, MADTds 1, MADTdsClient 4 de 5, MADMySQL 18 de 19, MAD 150 de
181 — e suas suítes executam sob ctest: 114 executáveis (1098 testes), todos
verdes, com 6 necessidades registradas, cada uma sendo maquinaria exclusiva da Apple (Core Data, o
modelo compilado, `MADocument`, o conversor) nomeada em `Linux/README.md`. A
cobertura do master mesclada em 2026-10-10 (~100 arquivos de teste Xcode) está portada em
sua totalidade — 55 novos executáveis, suíte por suíte — e o merge encontrou dois defeitos
do lado Apple, ambos corrigidos e em `BUGS.md`: os alvos dos frameworks tinham descartado
`$(inherited)` de seus defines de pré-processador (DEBUG estava morto em toda
compilação Debug de framework), e os fixtures de documento do MAD compartilhavam um armazenamento entre
execuções. Uma camada de bibliotecas
(`Linux/libraries.conf`, `Linux/lib/libraries.sh`) compila sqlite3,
openssl, freetds, zlib, bzip2, libarchive, libpng, zint e mysqlclient nativamente
na imagem (as bibliotecas C da §7; nada é distribuído). Os itens de cauda longa seguiram o que a §4
previu — as importações de `asl.h`/`vm_param.h` eram vestigiais, `copyfile(3)`
se tornou POSIX, `CFHost` se tornou `getaddrinfo`, os sítios CF se tornaram uma
cunha `CFNumberGetValue` — e a cauda UIKit/CoreGraphics é excluída
arquivo por arquivo com motivos, não portada (a disposição da §5.2; `MADocument`, um
UIDocument, e `MADReportFormatter` aguardam a Fase D, que é o problema da CLI tanto
quanto o da plataforma). As suítes do MAD encontraram mais três divergências,
todas corrigidas ou com cunha e registradas em `Linux/README.md`: a codificação BOOL do
runtime (`'C'` fora da Apple), a caminhada ausente de superclasses de `class_getProperty()`
(ambas corrigidas em `RptqObject`) e um stub `+propertyListWithStream:`
(com cunha). A porta de cobertura de testes adicionou mais três, igualmente corrigidas ou com cunha:
`NSOperation.asynchronous`/`-isConcurrent` (uma categoria Compat — sem ela, uma
operação assíncrona em finalização lançava exceção saindo de `-dealloc`), `-coordinateAccessWithIntents:`
(sua implementação GNUstep falha; a categoria Compat chama o acessor na
fila), e URLs sem esquema de `MADURLFactory` (agora
`+fileURLWithPath:`, o que desbloqueou cinco testes de coordenador). A divergência
que ficou fixada por mais tempo — o `-localizedCaseInsensitiveCompare:` do GNUstep é
sensível a maiúsculas, então a ordenação registrada do MADSqlite3 ordenava texto de forma diferente
da Apple — está corrigida agora (2026-10-25): a ordenação, os seletores de ordenação em memória
e o comparador do formatador todos passam por uma única ordem definida de primeira mão
(`NSString+Comparison.h`), e o pin se tornou testes de ordem definida
que valem identicamente em ambas as plataformas. A suíte ativa
`MADTdsClientLiveTests` executa verde de dentro
da imagem contra o contêiner SQL Server (29/29), então o caminho de driver é
exercitado no Linux, não apenas compilado. A Fase D — a CLI e os verbos do caminho de
dados — é o próximo passo e o go/no-go.

**Status da Fase D (2026-10-16).** O ponto de verificação é atingido: `mad` compila dentro da
imagem a partir de `CLI/Source` (os mesmos fontes dos quais a ferramenta de iOS-Simulator é compilada),
vincula os doze frameworks e executa o caminho de dados ali. `inspect` relata tanto uma
amostra v0 legada quanto um fixture v1 portátil; `schema` e `query` produzem as mesmas
respostas que a ferramenta do Mac (idênticas em bytes para `schema`); `refresh` preenche o cache de linhas
na amostra Sqlite3 e é idêntico em bytes ao cache do Mac quando comparado
por nome de campo (76 linhas, 21 colunas); e contra servidores ativos de dentro da
imagem, `mad refresh` puxou 50 linhas do MySQL 8.4 (`employees`, uma busca com
instrução preparada) e 20 do SQL Server 2022 (`AdventureWorksLT2022`, via
freetds). As suítes ativas concordam — `MADMySQLLiveTests` 44/44 e
`MADTdsClientLiveTests` 29/29 na mesma imagem — e a execução do ctest tem 117
executáveis, 1153 testes, 6 necessidades, todos verdes.

Duas coisas tiveram de ser resolvidas para chegar lá, ambas registradas em `Linux/README.md`:

1. **A questão do documento (§5.1, §9 Fase D).** `MADocument` é um `UIDocument`,
   então não pode vir junto. A escolha do usuário (2026-10-16) foi um caminho de documento
   headless, não uma cunha de `UIDocument` em `Compat` e não uma divisão de `MADocument`: a
   metade de dados de um documento agora é um protocolo, `MADDocumentDataProtocol`, ao qual
   `MADocument` conforma-se (todo membro já era um de seus acessores) e
   `MADHeadlessDocument` implementa sobre o mesmo `MADDocumentStore` que o documento do aplicativo
   usa. A cadeia de atualização — movida para `MAD` com o registro de drivers
   (`ROADMAP.md` §3.4, §5.1) — recebe o protocolo, então ambas as plataformas executam o mesmo
   `MADOperationRefresh`; seu único ramo do lado de renderização é `#if __APPLE__`, e
   `mad export` (PDF, Core Graphics) permanece na Apple, que é o escalonamento da §5.2.
2. **O registro de drivers (§3, §5.1).** O construtor não importa mais MySQL
   e TDS: cada driver se registra em `+load` e o construtor o procura
   por tipo. No Linux os arquivos de driver são vinculados por inteiro, porque o trabalho de um driver
   é alcançado por *categorias* e uma categoria é um envio de mensagem que o
   linker não vê — a CLI abortava no MySQL até que isso fosse corrigido (§ a
   nota de arquivo compat em `Linux/README.md`).

As divergências GNUstep que a CLI adicionou: o enumerador de diretório
(`-enumeratorAtURL:…` produz URLs com o diretório contenedor removido —
medido, e a lista de membros da CLI usa `-subpathsAtPath:` em vez disso), e a
ordem das colunas da lista SELECT, que era ordem de conjunto e portanto diferia da da Apple
(mesmos campos, mesmas linhas; anotado em `Linux/README.md`). **Resolvido em 2026-10-16**, com
a decisão da forma da exportação JSON (§10.1 abaixo): a ordem é definida como o alias da coluna
em ambos os construtores de SQL, então o SQL gerado, o cache de linhas e toda exportação
concordam em ambas as plataformas (docs/project/BUGS.md, a entrada da lista SELECT; os testes de ordem em
`Linux/Tests/MADQuerySelectExpressionTests.m`).

**Status da Fase E (2026-10-16, primeira metade).** A costura de exportação é real e os
formatos Foundation executam aqui. `MADReportExporting` + `MADReportExporterRegistry` são
a forma do registro de drivers (um protocolo de implementação, registro em `+load`, uma
busca por nome), e `mad export` escolhe um formato através deles, então um novo formato é uma
nova classe (`MAD_CLI.md` §5.3, ROADMAP.md §5.2). `text`, `csv` e `json` são Foundation puro
e produzem **saída idêntica em bytes no Linux e na Apple** para o fixture London
— medido com `sha256sum` na ferramenta do Mac e na da imagem (§ a seção CLI
de `Linux/README.md`; `Linux/Tests/MADReportExporterTests.m` fixa os mesmos
bytes com um checksum FNV-1a). A forma JSON está decidida (§10.1): `json` é o contrato
de dados — as colunas da consulta em ordem de alias, as linhas, o SQL, o driver — e
`json-report` é o mesmo documento com as seções do relatório renderizado como um membro
extra, a escolha do usuário em 2026-10-16: páginas, seções na ordem de desenho e o tipo,
quadro e texto resolvido de cada linha, construídos a partir da própria caminhada de páginas do renderizador com
nada desenhado — então não pode divergir do que um PDF mostra. Ele precisa da metade de renderização,
então se registra em todos os lugares e relata por que não pode executar aqui. Essa caminhada é
`MADPrintPageRenderer -buildPageAtIndex:context:inPageRect:`, que recebe um contexto anulável:
o caminho PDF passa o seu próprio e desenha como antes, e o json-report passa NULL;
o primeiro protocolo da metade de renderização, `MADDocumentRenderProtocol`, é o que o formato pede
ao documento. A metade restante da Fase E — o membro do relatório no Linux e
HTML/SVG — é a mudança da metade de renderização para o Linux, que a decisão de renderizador do usuário
(HTML/SVG depois, PDF por último, §10.2) coloca no passo HTML. `pdf` ainda é o braço
local da CLI; ele se torna um exportador com esse mesmo passo.

---

**Status da Fase E (2026-10-16, segunda metade: o escritor).** O escritor `.mad` executa no
Linux e ambas as plataformas gravam os mesmos bytes.  `MADArchiveManager.reproducible` é o
modo opt-in que o usuário escolheu (tempo fixo 2001-01-12T00:00:00Z, uid/gid 0, caminhada
de membros ordenada; gravações comuns mantêm os metadados do sistema de arquivos), `MADHeadlessDocument` ganhou
`-writeToURL:reproducible:error:` (a gravação do aplicativo sem as partes do UIDocument), e
`mad write` é o verbo que o alcança em ambas as plataformas.  Medido: o fixture London
gravado no Mac e na imagem é o mesmo arquivo de 16.261 bytes, sha256
`09815b24…` (a migração do armazenamento da Fase A da entrada SQL mudou os bytes gravados; o
fixture em si permanece um armazenamento versão 1); `Linux/Tests/MADArchiveManagerTests.m` fixa
os bytes, a ida e volta e o modo.  Dois defeitos exclusivos do Linux estavam no caminho e estão corrigidos (`BUGS.md`, a
entrada de identidade de bytes): a caminhada que nunca terminava, e `dirname(3)`/`basename(3)`
truncando o caminho do arquivo do chamador no glibc.  O que a comparação cobre é o
contêiner: os membros são os próprios bytes do fixture.  Um escritor Linux que *cria* um
armazenamento a estende à camada de armazenamento.

**Status da Fase E (2026-10-16, terceira parte: a metade de renderização e HTML).** A metade de renderização
mudou para o Linux, e mudou como uma conformidade, não um fork.  A resposta do usuário
sobre a forma foi "um formatador, não dois caminhos, e eles devem renderizar
o mesmo", então:

* `MADReportFormatter` recebe `id <MADDocumentRenderProtocol>`; o protocolo ganhou os
  quatro membros que o formatador lê (`filename`, `storeContext` — ele costumava pedir o
  `-managedObjectContext` de MADocument — `database`, `resetSectionLayoutManagers`)
  e herda os protocolos de dados, cache e fonte de dados de relatório que o formatador atribui
  a partir do documento.
* A caminhada de páginas saiu de `MADPrintPageRenderer` para `MADReportPageBuilder`, uma
  classe Foundation simples: a mesma transação de leitura por página, as mesmas referências de elemento,
  a mesma representação de linha por elemento, com o desenho agora um
  bloco que o chamador passa (o renderizador passa um que desenha; os formatos não passam nenhum).
  O construtor também é dono da geometria do lado de renderização (US Letter, o corte de 1pt) e da
  sequência de preparação (ordenar as linhas, dimensionar o formatador, formatar), que eram copiadas
  no braço PDF da CLI e no json-report.
* `MADDocumentRenderDataSource` é a única implementação das leituras da metade de renderização —
  `MADPrintPageRendererDataSourceProtocol` e `MADReportFormatterDataSource` sobre um
  documento — e tanto `MADocument` quanto `MADHeadlessDocument` respondem perguntando a ela.  Os
  corpos são os de MADocument, movidos; as páginas do aplicativo leem exatamente o que liam antes.
* `MADHeadlessDocument` conforma-se a `MADDocumentRenderProtocol`, então um documento sem
  janela agora formata e percorre.  O ramo de renderização de `MADOperationRefreshInitialize` usa como chave
  o protocolo em vez de `[doc isKindOfClass: [MADocument class]]`.
* A família de elementos compila headless: os inicializadores de `MADPrintPageElement` são
  Foundation (o texto é resolvido ali), e apenas os corpos de `-drawInRect:` são
  `#if __APPLE__`.  Fora da Apple, a imagem do elemento de imagem são os bytes PNG do armazenamento
  (`MADElementImage` é `NSData`), e `-renderedImageData` os entrega à representação de linha
  que os exportadores leem.  `MADElementStylizedText` continua sendo da Apple — é
  desenho, não layout.

**A paginação não precisa de engine de texto**, medido e não assumido: a altura de exibição de uma seção
vem de `MADSectionLayout` (retângulo armazenado + margem + preenchimento + borda), que
está na compilação Linux e está desde a Fase C, então as quebras de página são as mesmas
em toda parte.  As métricas de texto entram apenas quando um elemento é *desenhado*, e o renderizador
desenha com `NSLineBreakByTruncatingTail` — uma linha, recortada — que o CSS escreve
como `white-space: pre; overflow: hidden; text-overflow: ellipsis`.  Nada quebra linha, então
não há modelo de quebra a portar; nenhuma engine de fontes foi adicionada.

**`mad export --format json-report` executa aqui**, na mesma caminhada, e os quadros que ele
relata agora são coordenadas *de página* (o quadro do elemento deslocado por sua seção), que
é o que um renderizador ou navegador precisa.

**Dois novos formatos, ambos nas duas plataformas** (o usuário escolheu os dois): `html` é o
fac-símile — uma caixa de página CSS por página percorrida, cada elemento posicionado absolutamente em
seu quadro com seu texto resolvido e sua fonte, tamanho, traços e alinhamento armazenados; um
navegador o imprime nas mesmas páginas que o PDF tem.  `html-flow` é o mesmo relatório
refluível — `<section>`s, uma `<table>` por seção, um `<td>` por elemento, o mobiliário
de página emitido uma vez; uma visão de leitura, enquanto `--format json` continua sendo o contrato de dados.
Ambos são um arquivo UTF-8 com um `<style>` embutido e nenhum script; o CSS do fac-símile
são as 20 linhas acima mais uma regra de posicionamento, e os estilos do arquivo de fluxo são uma
tabela de classes gerada (nove classes para o fixture London).

**`pdf` está na costura**: `MADReportExporterPDF` se registra em todos os lugares.  Na Apple seu
corpo é Core Graphics + `MADPrintPageRenderer`, sem mudança; fora da Apple ele entrega as mesmas
páginas percorridas ao `MADReportExporterPDFCairo`, que as desenha em uma superfície PDF Cairo
com glifos FreeType de faces Liberation fornecidas (docs/project/MAD_PDF_LINUX.md).  A
CLI não tem mais braços locais.  A mudança Apple foi neutra em bytes: a exportação determinística
da amostra London é o mesmo PDF de 43.177 bytes e 5 páginas antes e depois
(`sha256 3eb2f1c4…` em ambos), medido compilando a CLI do commit anterior e
comparando.  O escritor headless visa paridade estrutural, não paridade de bytes.

**O que a comparação multiplataforma diz.** O texto de cada linha, cada quadro,
cada fonte, a contagem de páginas e a estrutura do arquivo são idênticos na Apple e no Linux para
o fixture London, e os bytes também: `html`, `html-flow` e `json-report` têm o
mesmo sha256 em ambas as plataformas (`Linux/README.md` tem os digests).  Chegar lá exigiu
uma descoberta e sua correção: a moeda renderizada costumava depender da máquina.  O relatório
agora toma seu locale *e* sua contagem de decimais do formato numérico do documento (o
armazenamento mantém ambos; um documento que não diz recorre a `en_US`, não ao
locale da máquina), a fábrica de elementos registra o locale de design nos novos elementos, e
o símbolo de moeda é escrito explicitamente com o sinal de iene normalizado (o GNUstep o escreve
em largura total).  Uma comparação de 60 casos em seis locales é idêntica em bytes; a entrada completa
está no arquivo de `BUGS.md`.

**Status da Fase F (2026-10-17, em parte).** A CLI é um entregável como imagem de runtime,
não um binário em uma árvore de compilação. `Linux/Dockerfile` ganhou um estágio `runtime`
sobre `ubuntu:24.04` carregando `/usr/local/bin/mad` (a regra de instalação do CMake), os
objetos compartilhados que a CLI vincula (GNUstep Base, libobjc2, libdispatch,
libBlocksRuntime, mysqlclient), os diretórios de runtime do GNUstep, os arquivos de mensagem e charset
do mysqlclient e `chinook.sqlite3` no caminho de suporte ao aplicativo; ele
deixa para trás o compilador, fontes, testes, cabeçalhos e arquivos estáticos. Tem
283 MB em disco (66,5 MB comprimidos) contra a imagem de compilação de 6,65 GB.
`./Linux/build.sh --runtime` a compila, e `--verify` executa
`Linux/verify-cli.sh` dentro dela: 30 verificações — os seis verbos, o digest fixado de cada formato
offline, a recusa do `pdf`, os bytes do escritor reproduzível, os
códigos de saída e a própria forma da imagem (sem clang, cmake, git ou árvore de compilação).
Verde em 2026-10-17; `--live` adiciona as atualizações MySQL e TDS (32/32). A suíte
também ganhou um `RESOURCE_LOCK` entre os dois binários de teste que compartilham o
fixture London e o banco de dados de exemplo — o paralelismo do ctest tinha feito esse par
falhar intermitentemente (35 execuções paralelas verdes consecutivas após o bloqueio).

As decisões do usuário no mesmo dia: **sem CI** (a portabilidade Linux é uma prova de
conceito e um teste repetível, não uma versão; `./Linux/build.sh --verify` é
a verificação) e **sem publicação** (nada é puxado de um registro, então a
questão GPL permanece onde a §10.3 a deixou). O driver Linux do Compressor é a
única parte da Fase F não feita, e não é necessária para a CLI: a imagem compila
as bibliotecas C nativamente.

## 10. Decisões para o usuário

1. **A forma da exportação JSON** (`MAD_CLI.md` §8.3, `MAD_FUTURE.md` §10.5) — este é
   o contrato Python; decida-o primeiro, porque tudo na §2 depende dele.
   **Decidido em 2026-10-16: ambos, a metade do relatório como seu próprio formato.** `--format json`
   é o contrato de dados — um envelope (id de formato, documento/driver, o SQL, a contagem de
   linhas), `columns` (chave, nome, tabela, tipo) e `rows` como um objeto por linha com
   valores tipados em JSON — e `--format json-report` é esse documento mais um membro `report`
   (as seções renderizadas). Com isso, a ordem da lista SELECT é definida como o
   alias da coluna, ordenado, para que o SQL gerado, o cache de linhas e toda exportação concordem em
   ambas as plataformas (docs/project/BUGS.md, a entrada da lista SELECT — antes ordem de conjunto). A metade de dados
   está construída (`MADReportExporterJSON`, ambas as plataformas); o membro do relatório aguarda
   a metade de renderização.
2. **Escalonamento do renderizador** — HTML/SVG primeiro, PDF por último, ou workers de PDF do lado
   macOS? **Decidido em 2026-10-16: HTML/SVG depois, PDF por último.** Nenhum renderizador PDF Linux e nenhum
   worker do lado macOS: o passo HTML é também onde a metade de renderização
   (`MADReportFormatter`) se muda para o Linux, o que o `json-report` e os testes também querem.
   `pdf` continua sendo o braço do lado Apple da CLI até então.
   **Feito em 2026-10-16 (o passo HTML).** A metade de renderização está no Linux e `mad export`
   não tem braços locais: `pdf` é um exportador registrado cujo corpo é o da Apple, e ele
   explica por que fora da Apple.  A decisão adicional do usuário no mesmo dia: o escritor PDF Linux
   é o *próximo* passo, não parte deste, porque as caixas de página do fac-símile HTML são
   a geometria que um escritor Linux tem de reproduzir e tornar seu teste.  A forma do escritor
   está registrada aqui para esse passo: **Cairo (desenho, superfície PDF) + Pango (layout,
   quebra de linha) + FreeType/HarfBuzz**, a pilha que GTK/WebKit/Firefox usam e a mais próxima
   que o Linux tem de Core Graphics + Core Text — APIs C chamadas do Objective-C como
   freetds e sqlite3 já são, então nenhum wrapper Impl é necessário.  Licenças: Cairo
   LGPL-2.1/MPL-1.1 dupla, Pango LGPL-2.1, HarfBuzz MIT, FreeType FTL/GPLv2-dupla; o
   projeto já distribui LGPL (FreeTDS, `LICENSE_COMPLIANCE_PLAN.md` §4) e a imagem Linux
   é uma compilação de servidor, então é uma classe conhecida de obrigação.  `libharu` é a
   alternativa permissiva, mas não tem engine de layout; Skia é a mais próxima em capacidade,
   mas é uma compilação C++ pesada.  **Não alcançável: PDFs idênticos em bytes entre plataformas** —
   o escritor do Core Graphics não pode ser reproduzido — então o alvo são as mesmas páginas, caixas,
   texto e fontes, com substitutas métricamente compatíveis para as fontes da Apple
   (a família padrão de `MADFont` é Helvetica Neue, que o Linux não tem).
   **Feito em 2026-11-20 (o fechamento do PDF).** A pilha é Cairo (superfície PDF) +
   FreeType, sem Pango: a caminhada entrega a cada linha seu quadro, texto, fonte, tamanho,
   traços e alinhamento, então não há layout a fazer — apenas avanços de glifos e a
   própria tabela `kern` da face, que o FreeType fornece.  Cairo 1.18.6 (MPL-1.1) e
   pixman 0.46.4 (MIT) são compilados estaticamente; as faces Liberation (SIL OFL 1.1) são
   as substitutas das fontes da Apple.  `MAD_PDF_LINUX.md` registra o que chegou, a
   política de mapeamento de fontes e o residual medido.  O alvo continua estrutural:
   os bytes do Core Graphics não são reproduzíveis.
3. **Momento da substituição mysqlclient → MariaDB Connector/C** — o bloqueio GPL condiciona qualquer binário
   distribuído; a substituição já está nomeada em `LICENSE_COMPLIANCE_PLAN.md`.
4. **Política da cadeia de ferramentas** — clang/libobjc2/GNUstep compilados da fonte (necessários para ARC) são um
   compromisso de manutenção; aceite-o ou permaneça em hosts macOS.
5. **O gatilho da reescrita** — a fase D da §9 é o ponto de verificação mensurável; até que ela
   falhe, a recomendação se mantém: uma engine Objective-C, chamada do Python
   através da fronteira da CLI.
6. **A linha de base de compilação** — Docker sobre uma base Debian-stable ou Ubuntu-LTS, compilada no
   Linux em vez de por compilação cruzada a partir do macOS (§8.1). A escolha define o piso de
   glibc suportado, então faça-a uma vez e deliberadamente.
