---
layout: default
title: "A ferramenta de linha de comando `mad`"
description: "Abra, inspecione, consulte, atualize e exporte documentos `.mad` sem uma interface gráfica."
lang: pt-BR
---

# `mad` -- a Interface de Linha de Comando do MAD Designer

Esta página descreve a ferramenta de linha de comando `mad`: a superfície de incorporação da engine, e a maneira mais rápida de exercitar um documento `.mad` sem o aplicativo. Leia primeiro a especificação do formato se o contêiner e o armazenamento forem novidades para você.

Este documento define uma ferramenta de linha de comando que abre, inspeciona, atualiza e exporta
documentos `.mad` sem uma interface de usuário.

Este registro foi escrito quando a camada de apresentação do aplicativo Apple era inteiramente UIKit, portanto ele não podia ser executado como um aplicativo nativo para macOS ou Windows. Os aplicativos nativos para macOS (AppKit) e Windows (WPF) agora existem; a CLI `mad` continua sendo o caminho headless que executa a mesma engine sem uma UI. O caminho de dados -- abrir o documento, executar a consulta, preencher o cache, renderizar o relatório -- está quase inteiramente livre de UIKit (veja §4), e é isso que torna a CLI portátil.

---

## 1. Escopo

**No escopo.** Um único binário, `mad`, que pode:

- abrir um documento `.mad` e relatar o que há nele
- imprimir o esquema do banco de dados contra o qual o documento foi criado
- imprimir a consulta que o documento define, como SQL
- conectar-se ao banco de dados de origem, executar a consulta e preencher o cache de linhas
- exportar um relatório renderizado

**Fora do escopo, deliberadamente.** Qualquer coisa que edite um documento. A CLI lê e
executa documentos; ela não os projeta. A análise de argumentos, os verbos e os códigos de saída
são toda a superfície.

---

## 2. Por que uma CLI primeiro

| | CLI | Aplicativo Mac |
|---|---|---|
| Precisa de um kit de ferramentas de interface | não | AppKit (reescrita) ou Catalyst (rejeitado) |
| Precisa que os frameworks sejam portáveis | **sim** | sim |
| Precisa que o cache de linhas seja portável | **sim** | sim |
| Precisa que `.mad` esteja definido | **sim** | sim |
| Entrega algo que você pediu | sim | sim |
| Trabalho descartado se o formato mudar | nenhum | a interface |

Tudo o que o aplicativo Mac precisa para existir -- frameworks portáveis, um
formato de arquivo definido, bibliotecas compiladas para mais de uma plataforma -- a CLI precisa
primeiro. Fazer a portabilidade da interface primeiro seria a maneira cara de descobrir os mesmos
problemas. O aplicativo Mac continua sendo uma decisão separada, tomada depois, com os
frameworks já portáveis.

---

## 3. Superfície de comandos

```
mad <command> [options] <document.mad>
```

### `mad inspect <doc.mad>`

Lê somente o contêiner. Sem conexão com o banco de dados, sem Core Data.

```
$ mad inspect London.mad
London.mad
  format      v0 (bzip2 tar, no magic header)
  generator   MAD Designer
  version     1
  store       StoreContent/analyitics (SQLite 3.43.2, 126 pages)
  wal         present, 313152 bytes (not checkpointed)
  thumbnail   none
  elements    14 sections, 63 elements
```

Este é o verbo que prova que `MAD_FORMAT.md` §7 foi implementado: ele deve funcionar
em uma amostra v0. É também o verbo que torna visíveis os perigos do formato -- H2
(o WAL não checkpointado) é relatado em vez de sofrer silenciosamente.

### `mad schema <doc.mad>`

Imprime o esquema do banco de dados capturado na definição do documento: o driver, as
tabelas ordenadas por nome, e os campos de cada tabela com seu tipo de exibição e um marcador
`pk`. Ele lê o snapshot armazenado no momento da criação, então não precisa de credenciais e
nem de banco de dados de origem. (O plano original aqui era emitir SQL `CREATE TABLE`; o
snapshot armazena a abstração `MADDataType` em vez dos nomes de tipo de cada dialeto de origem,
então um `CREATE TABLE` fiel precisa de um mapeamento por dialeto que ainda não existe.
A listagem legível é o que a ferramenta produz até então.)

### `mad query <doc.mad>`

Imprime o SQL que a consulta do documento gera, sem executá-lo. Este é o
recurso em torno do qual o aplicativo é construído -- o usuário monta tabelas, junções e
filtros, e o software escreve o SQL -- então expô-lo é o primeiro verbo não trivial natural.

```
$ mad query London.mad --format sql
SELECT ... FROM ... WHERE ...
```

### `mad refresh <doc.mad>`

Conecta-se ao banco de dados de origem, executa a consulta e preenche o cache de linhas. Este é o
caminho de dados, e é o verbo do qual o resto depende.

```
$ mad refresh London.mad --credentials user:pass
refreshed 148,392 rows in 1.21 s (122,638 rows/s)
cache  ~/Library/Caches/MADDesigner/<id>/<tag>.maddb
```

Opções: `--credentials`, `--host`, `--port`, `--database`, `--no-cache` (executar
sem persistir), `--rows N` (parar após N linhas, para testes rápidos).

`--rows` existe porque é o que torna o verbo testável em CI contra um servidor
ativo sem puxar um milhão de linhas, e porque o benchmark em
`MADDataTableFastBenchmarkTests` já prova que o caminho é mensurável em escala.

### `mad export <doc.mad>`

Renderiza o relatório e o grava.

```
$ mad export London.mad --format pdf  --out London.pdf
$ mad export London.mad --format json --out -          # to the standard output
```

Os formatos são a costura de exportação (§5.3): cada um é uma classe registrada no
`MADReportExporterRegistry`, e o texto de uso nomeia o que a compilação tiver.

| formato | grava | onde executa |
|---|---|---|
| `pdf` | o relatório renderizado (páginas, desenhadas) | Apple: `UIPrintPageRenderer` do UIKit, Core Graphics; Linux explica por que não |
| `html` | o relatório renderizado como um arquivo HTML, uma caixa de página por página, impresso de um navegador | ambas as plataformas |
| `html-flow` | o relatório renderizado como HTML refluível, uma tabela por seção | ambas as plataformas |
| `text` | as linhas como uma tabela de largura fixa | ambas as plataformas |
| `csv` | as linhas como CSV RFC 4180 | ambas as plataformas |
| `json` | o esquema e as linhas como JSON (§8.3) | ambas as plataformas |
| `json-report` | `json` mais as seções do relatório renderizado | ambas as plataformas |

`--out` é opcional para os formatos Foundation -- ausente, ou `-`, grava a saída padrão
-- e obrigatório para `pdf`. Os formatos Foundation gravam os mesmos bytes na Apple
e no Linux para o mesmo documento (`Linux/README.md`; as exportações das duas plataformas do
fixture London são iguais por digest).

**A ordem definida.** A ordem de agrupamento da exportação faz parte desse contrato, então é uma
ordem definida, não a da plataforma: as chaves de texto são comparadas sem diferenciar maiúsculas de minúsculas, depois por
ordem de ponto de código nos bytes UTF-8. A dobra de caixa é a dobra de caixa simples (um para um) do
Unicode 17.0.0, mantida como uma tabela versionada (`MADStringOrderingTable` em
`MADFoundation/Source/NSString+Comparison.m`, gerada a partir das entradas de status C/S do
`CaseFolding.txt` do UCD) -- ASCII e todo par Unicode que a tabela mapeia
são dobrados; qualquer outra coisa, incluindo diacríticos, é comparada como seu próprio ponto de código. Como
a dobra envia cada letra para a faixa minúscula, que segue cada byte de pontuação
ASCII, uma chave liderada por pontuação (`[1997] Black Light Syndrome`) é ordenada antes
de uma liderada por palavra (`Core`) -- o mesmo lugar onde o `NOCASE` do SQLite a coloca. O UTF-8 preserva
a ordem dos pontos de código, então a comparação de bytes é a comparação de pontos de código. Um
comparador (`-[NSString mad_orderedCompare:]` e seu núcleo C
`MADStringOrderedCompareUTF8`) conduz todos os três sítios: a ordenação `LSASC` do cache,
os descritores de ordenação em memória (`MADDataTypeSelectorForSorting`) e a comparação de limites de agrupamento
do formatador de relatórios. A ordem é determinística entre plataformas,
versões de SO e locales; ela mudou da ordem localizada em 2026-10-25, então
exportações anteriores a essa data não são iguais às exportações posteriores.

**`json-report`** (`MAD_LINUX.md` §10.1, §9 Fase E) é o mesmo esquema com o
relatório renderizado como um membro `report`: páginas, as seções de cada página na ordem de desenho (tipo,
nível de agrupamento, visibilidade), as linhas de cada seção, e o tipo de elemento, quadro e
texto resolvido de cada linha. É o que os testes e um renderizador leem, e é a própria
estrutura do renderizador -- a caminhada pelas páginas sem nada desenhado -- então não pode divergir do que um PDF
mostra. O quadro é onde a linha fica **na página** (o quadro do elemento deslocado por
sua seção), que é o que um renderizador ou um navegador precisa. A metade de renderização é compilada
no Linux agora, então este formato executa em ambas as plataformas.

**`html`** é o artefato em forma de página que um navegador imprime: uma caixa de página CSS por página
percorrida, cada elemento posicionado absolutamente em seu quadro, seu texto resolvido na
fonte, tamanho, peso, inclinação, decoração e alinhamento do próprio elemento. A regra de quebra de linha
é a do renderizador (`NSLineBreakByTruncatingTail` -> `white-space: pre; overflow:
hidden; text-overflow: ellipsis`). É um arquivo UTF-8 com um bloco de estilo embutido
e nenhum script. **`html-flow`** é o mesmo relatório com as páginas descartadas: uma `<section>`
por seção do relatório, uma `<table>` por seção, um `<td>` por elemento, mobiliário de página
emitido uma vez, e uma classe gerada por estilo de elemento distinto. É uma visão de leitura;
`json` é o contrato de dados. Nenhum dos dois carrega cores (as colunas de cor do armazenamento não têm
leitor em nenhuma das plataformas hoje) nem imagens no Linux (o caminho Apple as desenha a partir de
`UIImage`; uma exportação Linux coloca a caixa vazia).

A renderização para PDF passa pelo `MADPrintPageRenderer`; o wrapper de folha de compartilhamento
`MADActivityItemProviderPdf` é seu outro chamador, e `MADActivityItemProviderDelegate.h`
é o protocolo com o qual ele fala. Todos os três vivem no framework `MAD` em vez de no
aplicativo. O que o PDF não é é **headless**: ele é o `UIPrintPageRenderer` do UIKit, e é por isso
que é o único formato ainda implementado do lado da CLI (veja §5.3).

### `mad write <doc.mad> --out <copy.mad>`

Grava o documento como um `.mad` -- uma *cópia*: o diretório de conteúdo interno no qual o documento foi
lido, arquivado novamente com o cabeçalho v1.  Ele não edita o documento que leu,
e a CLI continua não projetando documentos (§1); para o que este verbo serve é o
requisito de identidade de bytes -- o mesmo documento gravado em duas plataformas deve ser o
mesmo arquivo -- e o fixture de ida e volta da §6.1, que precisa de um gravador que um script possa executar.

```
$ mad write London.portable.mad --out copy.mad --reproducible
wrote /tmp/copy.mad (16261 bytes, reproducible)
```

`--reproducible` fixa o que o relógio e o sistema de arquivos carimbariam de outra forma no
arquivo: um tempo de modificação fixo (2001-01-12T00:00:00Z, o instante ao qual a exportação PDF
fixa suas datas), proprietário e grupo 0, e uma caminhada de membros ordenada
(`MADArchiveManager.reproducible`).  Sem ele, uma gravação comum é escrita, com os
metadados reais dos membros.  O documento é aberto de forma headless em ambas as plataformas
(`MADHeadlessDocument`), então os dois lados da comparação executam o mesmo gravador, e
o mesmo documento grava os mesmos bytes ali (16.261 bytes no fixture London,
`Linux/README.md`).

### Opções globais

| Opção | Significado |
|---|---|
| `--verbose` | registrar o caminho de dados em cada estágio |
| `--quiet` | suprimir tudo exceto o resultado |
| `--credentials user:pass` | credenciais do banco de dados de origem; caso contrário, o chaveiro |
| `--host <name>` | substituição do host do banco de dados de origem (refresh, export) |
| `--port <n>` | substituição da porta do banco de dados de origem, 1-65535 (refresh, export) |
| `--database <name>` | substituição do nome do banco de dados de origem (refresh, export) |
| `--no-keychain` | nunca tocar no chaveiro |
| `--format <name>` | formato de saída |
| `--out <path>` | caminho de saída; padrão stdout |
| `--deterministic` | fixar as datas e o identificador da exportação, para que duas execuções sobre dados inalterados sejam idênticas em bytes |
| `--reproducible` | fixar as entradas do arquivo `.mad` -- tempo, propriedade, ordem dos membros (`write`) |

A definição de conexão -- host, porta e nome do banco de dados -- faz parte do
armazenamento portátil do documento; o nome de usuário e a senha nunca fazem. `--host`,
`--port` e `--database` substituem a conexão armazenada apenas nesta execução,
então um documento versionado pode ser executado contra um contêiner de serviço de CI sem
ser reescrito. Qualquer coisa não fornecida mantém seu valor armazenado. Eles são recusados
em um documento Sqlite3, cuja conexão é um arquivo, e nos verbos que não
se conectam (`inspect`, `schema`, `query`, `write`) eles são simplesmente ignorados.
As credenciais permanecem em `--credentials`; o armazenamento não contém nome de usuário nem senha.

### Códigos de saída

| Código | Significado |
|---|---|
| 0 | sucesso |
| 1 | erro de uso |
| 2 | o documento não pôde ser lido ou não é um `.mad` |
| 3 | banco de dados de origem inacessível, ou credenciais rejeitadas |
| 4 | a consulta falhou no servidor |
| 5 | a exportação falhou |

Códigos distintos importam porque o primeiro uso real desta ferramenta é um script, e um
script precisa distinguir "o documento está ruim" de "o servidor está fora do ar".

---

## 4. O que precisa existir antes que a CLI possa ser compilada

O caminho de dados já está quase livre de UIKit. Isso é medido, não estimado:

| Framework | Arquivos que importam UIKit | Necessário para a CLI |
|---|---|---|
| `MADDataStructures` | 0 / 37 | sim |
| `MADFileManager` | 0 / 31 | sim |
| `MADSqlite3` | 0 / 65 | sim |
| `MADMySQL` | 0 / 42 | sim |
| `MADTds` / `MADTdsClient` | 0 / 3, 0 / 9 | sim |
| `Scrimpter` | 0 / 48 | não |
| `MADFoundation` | 4 / 66 | sim |
| `MADAPI` | 3 / 34 | parcialmente |
| `MAD` | 28 / 464 | parcialmente |

Quatro arquivos em `MADFoundation` carregam toda a dependência de UIKit do framework base:

| Arquivo | Uso de UIKit | Disposição |
|---|---|---|
| `MADApplication.{h,m}` | um wrapper de `UIApplication` | não necessário para a CLI; excluído do alvo headless |
| `MADURLFactory.m:32` | `UIScreen.mainScreen.scale > 1.0` | uma chamada; retornar 2.0 fora do iOS |
| `MADOperation.m:550-563` | `beginBackgroundTaskWithName:` | um recurso, protegido por `#if TARGET_OS_IPHONE` |

O autor já sinalizou o último (`MADOperation.m:21`): *"Queria não precisar
importar UIApplication aqui, mas é realmente a maneira mais limpa."* Para uma compilação headless
não é a maneira mais limpa, e é o único lugar no framework base onde isso é
verdade.

Os três arquivos UIKit do `MADAPI` são *controladores de visão* de conexão e simplesmente não fazem
parte de um alvo headless.

### 4.1 O núcleo de atualização precisa se mover

A única peça substancial de trabalho é esta. A orquestração de atualização está **no alvo do aplicativo,
não em um framework**:

| Arquivo | Linhas | Símbolos UIKit | Papel |
|---|---|---|---|
| `MADDesigner/Source/MADOperationRefresh.m` | 131 | **0** | constrói o SQL, executa-o, grava o cache |
| `MADDesigner/Source/MADOperationRefreshReload.m` | 196 | 3 | recarga do lado da interface |
| `MADDesigner/Source/MADRefreshOperationReload.m` | 132 | 1 | recarga do lado da interface |

`MADOperationRefresh.m` importa somente `MADAPI`, `MADFoundation` e `MAD`, e não toca
em UIKit. Ele já é o verbo de atualização da CLI; ele está apenas no alvo errado. Ele
se muda para o framework `MAD`, e as duas operações `Reload` permanecem no aplicativo,
que é o que seus nomes vêm dizendo o tempo todo.

### 4.2 O alvo headless

Uma configuração de compilação de `MADFoundation`, `MADAPI` e `MAD` que compila sem
UIKit, mais o próprio alvo da CLI. Mecanicamente, isto é `SUPPORTED_PLATFORMS` estendido
com `macosx`, os caminhos de busca de bibliotecas por SDK de `LIBRARIES.md` §6, e as três
exclusões de nível de arquivo acima.

**Feito no Linux, 2026-10-16** (`MAD_LINUX.md` §9 Fase D), e feito desta maneira: o
alvo headless são os doze frameworks compilados por `Linux/CMakeLists.txt` contra
GNUstep, e a CLI é um alvo ao lado deles. A peça que a §4.1 atribuiu ao framework
`MAD` -- a cadeia de atualização -- mudou-se para lá, e a peça que ela não antecipou --
`MADocument`, um `UIDocument`, sobre o qual `MADCLIDocument` foi construído -- é respondida por
`MADHeadlessDocument` atrás de `MADDocumentDataProtocol`: a mesma metade de dados, sem
ciclo de vida de documento e nada para renderizar. `inspect`, `schema`, `query` e `refresh`
são as mesmas fontes em ambas as plataformas; `export` é PDF e permanece na Apple (§5.2,
a preparação da §9). Um alvo macOS ainda é o da Trilha 5.1, mas agora ele tem a costura e a
classe de documento que lhe faltava.

---

## 5. Design

### 5.1 Um binário, sem frameworks no caminho

`mad` vincula os frameworks headless diretamente. Ele não carrega o bundle do
aplicativo, e não deve exigir que o modelo Core Data esteja presente em uma fase de compilação --
uma restrição com a qual a suíte de testes já se deparou (veja a nota sobre
`MADTestReportFormatter` na memória do projeto).

### 5.2 O verbo de atualização reutiliza o caminho medido

`mad refresh` deve chamar o mesmo código que o aplicativo chama:
`MADOperationRefresh` → `MADDatabase executeSQL:fieldKeys:onConnection:intoResultTable:`
→ `<MADDataTableWriting>`. Ele não deve reimplementá-lo. O benchmark adicionado em
`MADDataTableFastBenchmarkTests` mede exatamente este caminho com 200.000 linhas
(1,16 s de ingestão, 2,5 MB transitórios), então uma CLI que o regrida aparecerá como um
teste com falha em vez de como uma reclamação de usuário.

### 5.3 A exportação é um protocolo, não um switch

`MAD_FORMAT.md` descreve documentos; documentos contêm elementos de relatório. A exportação deve
ser um ponto extensível, correspondendo ao objetivo declarado do projeto de que os desenvolvedores "criem novos
formatos de exportação de documentos (por exemplo, exportar para PDF e JSON)". Defina
`<MADReportExporting>` com um método e registre implementações, para que `--format json`
seja uma nova classe em vez de um novo ramo em um switch.

**Feito em 2026-10-16**, na forma que o registro de drivers da §5.1 já tem: `MADReportExporting.h` é o
protocolo (o nome de um formato, extensão, se ele precisa de `--out`, se esta compilação pode
produzi-lo, e um método de exportação), `MADReportExporterRegistry` é a busca, e cada
exportador se registra em `+load` -- então quais formatos um processo tem é o que ele vincula,
e a CLI pede um pelo nome. `text`, `csv` e `json` são os do próprio framework
(`MADReportExporterText/CSV/JSON`, Foundation puro, ambas as plataformas);
`MADReportExportSource` é o único lugar onde um documento é lido como colunas e linhas, então os
formatos não podem discordar sobre o que é um documento; e `MADReportExportWriter` é o único
lugar onde os bytes chegam a um arquivo ou à saída padrão.

`json-report`, `html` e `html-flow` também estão na costura, construídos sobre o protocolo da metade de renderização
(`MADDocumentRenderProtocol`: um documento que pode preparar suas linhas, formatar e
entregar seu formatador) e sobre uma única caminhada de páginas (`MADReportPageBuilder`). **`pdf` também está na
costura** agora: `MADReportExporterPDF` se registra em todos os lugares, seu corpo é o do
Core Graphics (da Apple), e fora da Apple ele responde `+isAvailable NO` com o motivo
(`MAD_LINUX.md` §10.2: o escritor Linux é o próximo passo). A CLI não tem mais braços locais;
todo formato, `pdf` incluído, é procurado no registro.

### 5.4 Credenciais

A CLI nunca deve solicitar entrada. Ela recebe `--credentials`, ou lê o chaveiro que o
aplicativo gravou, ou falha com o código de saída 3. `--no-keychain` existe para que uma execução de teste
não possa ler ou gravar as credenciais reais de um desenvolvedor.

### 5.5 Executá-la: a imagem Linux

`Linux/build.sh --runtime` compila `mad-cli:latest`, uma camada somente de runtime com a
CLI no PATH, as bibliotecas compartilhadas que ela vincula e o banco de dados de exemplo Sqlite3 — sem
compilador, fontes ou binários de teste (283 MB em disco; `Linux/README.md` tem o
conteúdo). Um documento é montado, não armazenado:

	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad inspect /docs/London.portable.mad
	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad refresh /docs/MySQL.employees.mad --credentials root:root --rows 50

A imagem é publicada (2026-10-26, revertendo a decisão anterior de não publicar)
como `ghcr.io/mthomason/mad`, marcada com `latest` e o SHA curto do commit,
enviada por `.github/workflows/publish-image.yml` em cada push para master
(mais `workflow_dispatch`). As tags publicadas são **linux/amd64**, compiladas pela
CI em ubuntu-latest; o `mad-cli:latest` local do Mac é arm64, e em
Apple silicon a tag publicada precisa de `--platform linux/amd64` (executar sob
emulação; sem a flag, o pull falha com `no matching manifest`).
Os mesmos verbos sobre a imagem publicada:

	docker run --rm --platform linux/amd64 -v "$PWD/CLI/Fixtures":/docs:ro \
		ghcr.io/mthomason/mad mad inspect /docs/London.portable.mad

Um documento Sqlite3 resolve seu nome de banco de dados armazenado contra o diretório
Application Support por usuário, que é
`/root/GNUstep/Library/ApplicationSupport` na imagem; `chinook.sqlite3` está
lá, então os fixtures London e Music atualizam sem configuração. O cache de linhas
vive sob o mesmo home e é por contêiner; toda exportação atualiza o
próprio documento, então um cache não precisa persistir entre execuções. Os componentes LGPL
na imagem publicada obrigam ofertas de relink; a oferta escrita em
`ThirdParty/Licenses/README.md` nomeia a imagem (`THIRD_PARTY_LICENSES.md`
§9 é a entrada do registro).

`Linux/build.sh --verify` recompila a imagem e executa a verificação repetível: todos
os seis verbos nos fixtures, o digest fixado de cada formato, a recusa do `pdf`, os
bytes do gravador e os códigos de saída (`Linux/verify-cli.sh`; `--live` adiciona os três
bancos de dados ativos).

---

## 6. Testes

O formato e a CLI são fixados por **fixtures de ida e volta**, não por prosa:

1. **Fidelidade do contêiner.** Desempacote `Music.mad` e `London.mad`, reempacote-os e
   afirme que a lista de membros e os bytes de cada membro estão inalterados. Isso fixa
   `MAD_FORMAT.md` §2 e captura H4 (arquivos ocultos) imediatamente.  **Implementado
   em 2026-10-16** como a ida e volta de `Linux/Tests/MADArchiveManagerTests.m` -- `mad write`
   grava o contêiner em ambas as plataformas agora -- com os bytes do modo reproduzível
   fixados contra os do Mac.
2. **Legibilidade v0.** `mad inspect` em ambas as amostras distribuídas deve ter sucesso e relatar
   os valores em `MAD_FORMAT.md` §2 -- incluindo o WAL não checkpointado, que é a
   asserção que prova que o perigo do WAL está sendo relatado em vez de ignorado.
3. **Ida e volta sem cache.** Abra um documento, atualize, exporte, feche, reabra. A
   segunda abertura não deve precisar da rede. Isso fixa a §5 do documento de formato -- que
   o cache é derivado e externo.
4. **Escala.** `mad refresh --rows 200000` contra uma fonte SQLite local, afirmado
   contra os mesmos limites que o benchmark usa, para que a CLI não possa se tornar silenciosamente o
   caminho lento.
5. **Códigos de saída.** Um teste por linha da tabela na §3, conduzido por entradas
   deliberadamente quebradas.

Os fixtures ficam ao lado das amostras que testam. Os testes que precisam de um servidor MySQL, SQL Server
ou PostgreSQL ativo **são ignorados** quando nenhum está acessível, seguindo a convenção existente
em `MADMySQLLiveTests.m`, `MADTdsClientLiveTests.m` e
`MADPostgresLiveTests.m`.

---

## 7. Fases

| Fase | Entregável | Depende de |
|---|---|---|
| 0 | `MAD_FORMAT.md`, `MAD_CLI.md`, `LIBRARIES.md` | -- |
| 1 | Sistema de compilação de bibliotecas, flags do sqlite fixadas | Fase 0 |
| 2 | Caminhos de busca por SDK; fatias macOS conectadas | Fase 1 |
| 3 | Subconjunto headless; `MADOperationRefresh` movido para `MAD` | Fase 2 |
| 4 | Alvo `mad`: `inspect`, `schema`, `query` | Fase 3 |
| 5 | `mad refresh` | Fase 4 |
| 6 | `mad export` (PDF primeiro) | Fase 5 |
| 7 | Fixtures de ida e volta conectados à matriz de testes | Fase 6 |

As fases 4-6 são ordenadas por dependência, não por dificuldade: `inspect` precisa apenas do
contêiner, `query` precisa do modelo do documento, e `refresh` precisa de uma conexão
com o banco de dados.

---

## 8. Questões em aberto

1. **A CLI é distribuída ou é uma ferramenta de desenvolvedor?** Isso decide se ela precisa de
   assinatura de código, notarização e um instalador, e se `--credentials` pode
   aceitar um argumento em texto simples ou deve receber um descritor de arquivo.
2. **`mad` deve aceitar o cache de linhas de um arquivo externo?** Um `.mad` empacotado
   (§8.3 do documento de formato) tornaria possível a exportação offline. Nada precisa disso
   ainda.
3. **Qual é a forma da exportação JSON? — respondido em 2026-10-16: ambas, a metade do relatório como
   seu próprio formato.** `--format json` é o contrato de dados, `--format json-report`
   adiciona o relatório renderizado como um membro extra. A forma está em
   `MADReportExporterJSON.h`, implementada por `MADReportExporterJSON` (a metade de dados,
   ambas as plataformas) e `MADReportExporterJSONReport` (o membro do relatório, onde a
   metade de renderização está). Suas colunas são as da própria consulta, na ordem que a lista
   SELECT define -- o alias da coluna, ordenado (`BUGS.md`, a entrada da lista SELECT) --
   e um valor mantém seu tipo JSON: números são números, NULL é `null`, datas são
   ISO 8601 e binário é base64.
