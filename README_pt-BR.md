[English](README.md) | [简体中文](README_zh.md) | [日本語](README_ja.md) | **Português (Brasil)**

# <a href="StaticResources/Images/icons/document/Designer%20Icon@3x.png"><img src="docs/assets/mad-designer-macos-icon-256.png" alt="Ícone do MAD Designer" width="44" height="44" align="absmiddle" /></a> MAD (Mobile Analytics Document)

**Um formato aberto e uma engine embarcável para relatórios relacionais — onde cada relatório é um grafo de consulta portável, uma tabela SQLite materializada e um layout paramétrico.**

O MAD é uma plataforma de relatórios relacionais construída do zero em Objective-C para consultas ad hoc, geração de relatórios e design: o aplicativo **MAD Designer** para iOS e macOS nativo (`AppKit`), onde consultas e layouts são construídos visualmente ou a partir de SQL; o aplicativo **MAD Viewer**, onde relatórios são lidos e atualizados; a **CLI `mad` e a engine headless** que rodam em Linux e macOS; e a **especificação aberta `.mad`**.

Um arquivo `.mad` armazena toda a definição de um relatório — o snapshot do esquema do banco de dados, o grafo de consulta relacional (tabelas, joins, predicados, agrupamentos) e a árvore de layout em bandas — em um único arquivo com menos de 100 KB, claramente separado dos dados que ele exibe. Um relatório é um arquivo executável, não um servidor: qualquer runtime que entenda `.mad` pode inspecionar o esquema, compilar SQL determinístico para o banco de dados de destino, materializar o conjunto de resultados em uma tabela SQLite local e renderizá-lo em views nativas AppKit/UIKit, HTML paginado, PDF, CSV ou JSON.

O repositório é um projeto único e autocontido: os aplicativos para iPad/iPhone, o aplicativo desktop nativo para macOS (`AppKit`) (`Mac/`), quatorze frameworks (doze multiplataforma para iOS, Simulador do iOS e macOS nativo; onze headless no Linux), o build e a suíte de testes headless para Linux (126 executáveis de teste, 1.303 testes), a ferramenta de linha de comando `mad` e o sistema de build (`Compressor`) que compila as bibliotecas C de terceiros a partir de códigos-fonte com versões fixadas. O código é publicado sob a licença MIT; o formato `.mad` é uma especificação aberta (consulte [`docs/`](docs/pt-br/)), embora os nomes do projeto e a arte visual dos aplicativos não façam parte da concessão da licença (consulte [`NOTICE`](NOTICE)).

[![Linux verification](https://github.com/mthomason/MAD/actions/workflows/linux.yml/badge.svg)](https://github.com/mthomason/MAD/actions/workflows/linux.yml)

## Por que o MAD

Hoje, qualquer desenvolvedor pode pedir a um LLM para gerar um script SQL avulso e uma tabela em React em dez minutos. Seis meses depois, a organização tem quarenta miniaplicativos sob medida, quarenta definições incompatíveis de um `INNER JOIN` entre `customers` e `invoices`, credenciais de banco de dados hardcoded, cálculos de agregação alucinados e zero interoperabilidade entre dispositivos móveis, desktop, pipelines de CI e parceiros externos.

O MAD resolve o problema de relatórios no **nível do formato e da engine**:

* **Interoperabilidade através de um contrato compartilhado.** Em vez de espalhar SQL ad hoc e código de integração de interface em scripts isolados, um documento `.mad` empacota o contrato de esquema, a AST da consulta e o layout de apresentação em um único artefato inspecionável, comparável via diff e versionável. O mesmo arquivo de 80 KB abre nativamente no macOS e no iPad, roda em modo headless em um contêiner Docker Linux, executa no GitHub Actions ou pode ser embarcado dentro de outro aplicativo — produzindo SQL e exportações idênticos byte a byte entre Apple e Linux.
* **SQL determinístico e cálculos locais em duas passagens.** Nem o usuário final nem um modelo de IA precisam escrever manualmente SQL específico de dialeto ou calcular totais no código da aplicação. A engine valida o grafo de consulta contra o snapshot de esquema do documento, compila SQL determinístico para o driver de protocolo, busca o conjunto de resultados uma única vez para um cache local de linhas em SQLite (`MADDataTableFast`) e calcula agrupamentos, chaves de ordenação e agregações de cabeçalho/rodapé localmente em duas passagens.
* **Desenvolvido do zero, não remendado.** O gerador de SQL, o parser de SQL, a engine de tabelas de dados, o store portável, o modelo de layout e o renderizador de páginas são código próprio em Objective-C distribuído em quatorze frameworks. O código de terceiros limita-se estritamente ao protocolo de comunicação — MariaDB Connector/C, FreeTDS, `libpq` e SQLite — além de `libarchive`/`bzip2` e `zint` para códigos de barras. Nenhum SDK proprietário de relatórios está sendo revendido.
* **Mobile-first significa orçamento de memória controlado.** Como o conjunto de resultados é materializado em uma tabela SQLite indexada em disco e as páginas são formatadas em um cache indexado pela geometria da página, um celular ou um pequeno contêiner consegue paginar e agregar relatórios de centenas de milhares de linhas sem manter todo o conjunto de dados na RAM.

A documentação técnica e a especificação do formato também estão disponíveis em <https://docs.everydayapps.com>.

## Veja em ação

**[MAD Designer para macOS](docs/pt-br/macos.md)** — o aplicativo desktop nativo em `AppKit` (`Mac/`), mostrando o canvas visual de relacionamentos do **MAD Query** e o workspace de layout em bandas do **MAD Designer**:

![Workspace MAD Query no aplicativo nativo para macOS](docs/assets/macos-native-mad-query.png)

![Workspace MAD Designer no aplicativo nativo para macOS](docs/assets/macos-native-mad-designer.png)

**MAD Designer para iOS**, da escolha de uma fonte de dados até a leitura do relatório finalizado no MAD Viewer (28 segundos; [vídeo](https://docs.everydayapps.com/assets/app-preview.mp4)):

[![Prévia do aplicativo MAD Designer](docs/assets/app-preview-poster.png)](https://docs.everydayapps.com/assets/app-preview.mp4)

**A mesma engine rodando em modo headless no Linux**: `inspect`, `schema`, `query`, `refresh` e `export` através da CLI `mad`, sem servidor de relatórios:

![A CLI mad inspecionando, consultando, atualizando e exportando um documento .mad](docs/assets/mad-cli-demo.gif)

O [relatório exportado](https://docs.everydayapps.com/assets/london.html) da gravação é HTML puro, podendo ser aberto em qualquer navegador.

## Por dentro do Formato `.mad`

Um arquivo `.mad` não é uma impressão estática como um PDF, nem um dump de linhas de dados. Ele é um **programa declarativo** que transforma uma conexão de banco de dados em uma tabela tipada e uma visualização formatada.

A arquitetura divide um relatório entre **a definição portável** (dentro do arquivo `.mad`, tipicamente de 15 a 80 KB) e **os caches complementares derivados** (gerados localmente ao atualizar e descartáveis a qualquer momento):

| Camada | Arquivo / Membro | Formato | Papel |
|---|---|---|---|
| **1. Contêiner** | `<Name>.mad` | Cabeçalho v1 `MADFILE\0` de 16 bytes + arquivo tar bzip2 `pax restricted` | Arquivo externo identificável pelo conteúdo (compatível com `tar xjf` na v0; cabeçalho + tar bzip2 na v1). |
| **2. Store de Definição** | `StoreContent/analyitics` | SQLite portável (`MADStoreSchema`, versionado via `PRAGMA user_version`) | Armazena o grafo de objetos `Rptq*`: o snapshot do esquema do banco de dados importado, o grafo de consulta (tabelas, aliases, joins, predicados, agrupamentos e `sqlSourceText` opcional) e a árvore de layout em bandas de seções/elementos. Zero dependências de Core Data ou da Apple. |
| **3. Metadados e Prévia** | `meta.plist`, `AdditionalContent/` | XML Property List + `thumbnail@2x.png` opcional | Metadados do gerador, versão do formato e pré-visualização opcional do documento. |
| **4. Tabela Materializada** *(complementar)* | `<hash>.maddb` + `<hash>.mdcache` | Banco SQLite de linhas (`t<tag>`) + plist de esquema de colunas (`MADDataColumn`) | **A saída do relatório como uma tabela de banco de dados.** Mantém as linhas buscadas, índices de chaves de grupo e metadados de tipos de coluna para que agregações em duas passagens (`SUM`, `COUNT`, `AVG`, `MIN`, `MAX`), ordenação e nova renderização nunca precisem consultar novamente o banco de dados remoto. |
| **5. Cache de Páginas** *(complementar)* | `<hash>{ih,lh}{w,h}.madac` | Bancos SQLite de índice (`ih`) e layout (`lh`) indexados pela geometria da página | Quebras de página e quadros de elementos pré-calculados para um viewport alvo (por exemplo, `{612, 792}` US Letter), mantendo a rolagem e a exportação instantâneas. |

A especificação completa — layout do contêiner, tabelas do store, esquemas dos arquivos complementares, peculiaridades conhecidas (incluindo por que o nome interno do arquivo de store é historicamente grafado como `analyitics` por compatibilidade retroativa) e verificação de digests multiplataforma — está documentada capítulo a capítulo em [`docs/`](docs/pt-br/).

## Para Onde o MAD Está Indo: Roadmap e Visão

Como o MAD já separa o **grafo de consulta**, a **tabela de resultados SQLite materializada** e o **layout de apresentação**, a arquitetura viabiliza quatro grandes capacidades que estão sendo ativamente projetadas e enfileiradas (consulte [`docs/vision.md`](docs/pt-br/vision.md), [`docs/project/MAD_DATA_OBJECT.md`](docs/project/MAD_DATA_OBJECT.md) e [`docs/project/TODO.md`](docs/project/TODO.md)):

1. **Um relatório `.mad` como uma tabela de banco de dados ad hoc (Objetos de Dados Componíveis).**
   Em um banco de dados tradicional, você faz `SELECT` a partir de tabelas base como `employee` ou `sales_data`. Um relatório `.mad` faz join e filtra múltiplas tabelas, e sua saída (`.maddb` + `.mdcache`) já é uma tabela SQLite física com esquema tipado (`MADDataColumn`). Ao tornar a saída de um relatório endereçável como fonte de tabela dentro do designer de consultas, **um arquivo `.mad` torna-se uma tabela de banco de dados virtual/materializada**. Outros relatórios, consultas ou ferramentas podem fazer `SELECT` e `JOIN` contra um relatório `.mad` exatamente como fariam com qualquer tabela em um banco de dados.
2. **Múltiplas fontes de dados em um único relatório (Federação sem servidor).**
   Cada driver de banco de dados (`MADMySQL`, `MADPostgres`, `MADTdsClient`, `MADSqlite3`) materializa o resultado de sua consulta na mesma representação local de tabela SQLite (`MADDataTableFast`). Uma vez que um relatório possa conter múltiplos objetos de consulta e tratar cada saída materializada como uma tabela local, um único relatório `.mad` poderá unir uma tabela `customers` do PostgreSQL com uma tabela `orders` do SQL Server e uma tabela SQLite local — federadas localmente sobre SQLite sem um servidor pesado de federação no meio do caminho.
3. **Além do paradigma do papel: UIKit nativo e visualizações interativas de dados.**
   O layout de página em bandas (Report Header, Page Header, Group Headers/Footers, Detail, Page/Report Footer) nasceu da impressão em papel. No MAD, a paginação em papel está se tornando **apenas um paradigma de visualização** sobre o objeto de dados do documento. Quando você não estiver imprimindo ou exportando um fac-símile paginado, o mesmo layout e a mesma tabela `.maddb` local alimentarão componentes UIKit nativos ricos e interativos e visualizações de exploração de dados brutos — projete uma vez, renderize tanto como papel paginado quanto como interface nativa interativa.
4. **Conversão de arquivos legados do Crystal Reports (`.rpt`) e relatórios corporativos para `.mad`.**
   Milhares de empresas ainda estão presas a décadas de arquivos do Crystal Reports (`.rpt`) que ninguém quer reescrever à mão e que nenhum dashboard SaaS moderno consegue importar de forma limpa. Como o MAD compartilha o DNA clássico de seções em bandas + grafo de consulta relacional do Crystal Reports — mas armazenando tudo em um formato SQLite-in-tar aberto e inspecionável —, o MAD está construindo importadores para converter definições `.rpt` legadas diretamente em arquivos `.mad` abertos.

## Experimente

A engine headless executa a CLI `mad` em Docker. Baixe a imagem publicada e inspecione um dos documentos de exemplo incluídos no repositório:

```sh
docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro ghcr.io/mthomason/mad \
    mad inspect /docs/London.portable.mad
```

Todos os comandos funcionam da mesma maneira — `schema`, `query`, `refresh`, `export` (fac-símile HTML paginado e `html-flow` refluível, texto puro, CSV, contrato de dados JSON e `json-report`; PDF roda nativamente em plataformas Apple e é adiado no Linux por decisão de projeto):

```sh
docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro ghcr.io/mthomason/mad \
    mad refresh /docs/Music.portable.mad
docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro -v "$PWD/out":/out ghcr.io/mthomason/mad \
    mad export /docs/London.portable.mad --format html --out /out/london.html
```

As tags publicadas são `latest` e o SHA curto do commit, compiladas para `linux/amd64` pelo workflow de publicação a cada push na `master`. Em Macs com Apple Silicon, adicione `--platform linux/amd64` — o Docker Desktop executa a tag sob emulação e, sem a flag, o pull falha (`no matching manifest`). Para construir uma imagem `arm64` nativa localmente (`mad-cli:latest`) e executar toda a suíte de verificação multiplataforma, basta um comando:

```sh
./Linux/build.sh --verify                 # build the toolchain and run the checks (~20 min first time)
```

Os documentos de exemplo atualizam seus dados contra o banco de dados de exemplo Sqlite3 incluído dentro da imagem; as fixtures de MySQL, SQL Server e PostgreSQL esperam os servidores de teste descritos em [`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md).

## Em CI

A GitHub Action [mad-action](https://github.com/mthomason/mad-action) executa um arquivo `.mad` versionado dentro de um workflow e envia sua exportação como artefato:

```yaml
- uses: mthomason/mad-action@v1
  with:
    command: export
    document: reports/sales.mad
```

Ela executa a imagem publicada, portanto a Action e a CLI são exatamente a mesma engine. A Action é gerada a partir de [`satellites/mad-action/`](satellites/mad-action/) neste repositório; [`docs/project/SATELLITE_REPOS.md`](docs/project/SATELLITE_REPOS.md) documenta como o repositório satélite é mantido atualizado.

## Drivers de banco de dados

O MAD comunica-se com bancos de dados por meio de subclasses de `MADDatabase`. Quatro drivers são distribuídos hoje:

* **MySQL / MariaDB** — `MADMySQL`, sobre MariaDB Connector/C;
* **SQL Server** — `MADTdsClient`, sobre FreeTDS;
* **PostgreSQL** — `MADPostgres`, sobre `libpq`;
* **SQLite** — `MADSqlite3`, para documentos de exemplo, bancos de dados locais e tabelas internas de materialização.

Um driver é um framework que cria uma subclasse de `MADDatabase` e se registra em `MADDatabaseDriverRegistry` — o designer de consultas e a engine nunca enxergam o protocolo de rede. Escrever um novo driver é a primeira contribuição recomendada (veja o tutorial de criação de drivers em [`docs/tutorials/driver-authoring.md`](docs/pt-br/tutorials/driver-authoring.md)). O ponto de extensão é real: os usuários podem construir uma consulta visualmente ou colar SQL (`MADSQLParser`), a engine gera a instrução específica do dialeto e o driver só precisa executá-la e transmitir as linhas para `id<MADDataTableWriting>`.

## Embarcando a engine

Onze dos quatorze frameworks não dependem de UIKit e compilam em modo headless. A CLI `mad` mostrada acima é essa mesma engine vestindo uma interface de linha de comando: o conjunto de comandos — `inspect`, `schema`, `query`, `refresh`, `export`, `write` — é a superfície de incorporação, e uma aplicação que vincule `MAD`, um framework de driver e `MADSqlite3` passa a contar com relatórios relacionais completos sem nenhum servidor no meio do caminho. Drivers e formatos de exportação (`<MADReportExporting>` / `MADReportExporterRegistry`) registram-se automaticamente, de modo que adicionar uma fonte de dados ou um formato de saída exige apenas criar uma subclasse, e não manter um fork.

## Aplicativo nativo para macOS

O aplicativo desktop nativo para macOS ([`docs/macos.md`](docs/pt-br/macos.md), [`Mac/`](Mac/)) é construído diretamente com `AppKit` (SDK `macosx`, `MACOSX_DEPLOYMENT_TARGET = 12.0`) sobre os doze frameworks MAD multiplataforma e as dez bibliotecas C estáticas universais (`arm64` + `x86_64`) compiladas pelo `Compressor`:

* **Arquitetura `NSDocument` nativa (`MADMacDocument` / `MADMacDocumentController`):** Abre e salva arquivos `.mad` nativamente a partir do Finder ou do painel padrão de abertura (com um botão integrado **New Document**), migra automaticamente arquivos `.mad` legados do Core Data via `MADStoreConverter` e integra `MADDesignerLayout` diretamente com `NSDocument.undoManager` (`Cmd+Z` / `Cmd+Shift+Z`).
* **Assistente de Conexão de Banco de Dados e Importação de Esquema (`MADMacConnectionWindowController`):** Conecta-se a **SQLite**, **MySQL / MariaDB**, **Microsoft SQL Server** ou **PostgreSQL**, verifica a conectividade, armazena credenciais nas Chaves do macOS (`MADKeyChain`) e importa esquemas de tabelas e colunas para um novo documento `.mad`.
* **Três workspaces integrados** (`Cmd+1`, `Cmd+2`, `Cmd+3`):
  1. **MAD Query (`MADMacQueryViewController`):** Alterna entre o **Query Designer** interativo (cartões de tabelas arrastáveis, conectores de join em curvas de Bézier com badges clicáveis de tipo de join, popovers de filtro `WHERE` e `GROUP BY`) e o editor **SQL Query** (`MADSQLParser` + `MADSQLQueryCompiler`).
  2. **MAD Designer (`MADMacDesignerViewController`):** Visualização dividida em três painéis com **Page & Section Minimap** interativo, outline **Report Bands**, origem de arrasto pesquisável **Query Fields**, canvas de design com zoom e réguas (`MADMacDesignerCanvasView`) com arrastar e soltar entre seções e guias inteligentes de alinhamento, além de um **Page & Element Inspector** de cartão duplo.
  3. **MAD Viewer (`MADMacViewerViewController`):** Atualização de dados ao vivo (`Cmd+R`), repaginação instantânea por **Page Size** (`US Letter`, `Legal`, `Tabloid`, `A3`, `A4`, `A5`, `B4`, `B5`, `JIS B4`, `JIS B5`), pré-visualização emoldurada em `PDFView`, impressão nativa com `NSPrintOperation` (`Cmd+P`) e exportação (`Cmd+E`) para **PDF**, **HTML**, **HTML Flow**, **CSV**, **JSON**, **JSON Full Report** e **Plain Text**.

Consulte [`docs/macos.md`](docs/pt-br/macos.md) para o guia completo e [`docs/project/MAD_MACOS.md`](docs/project/MAD_MACOS.md) para a auditoria de portabilidade multiplataforma.

## Compilação e testes

O workspace (`Reports.xcworkspace`) compila os quatorze frameworks, os aplicativos iOS e o aplicativo nativo para macOS (`MAD Designer Mac`).

### macOS nativo

Compile, execute a suíte ponta a ponta de smoke tests e empacote os artefatos de release `.zip` e `.dmg` a partir da raiz do repositório:

```sh
./Mac/build.sh                     # build 12 macOS frameworks + Mac/build/MAD Designer.app
./Mac/build.sh --no-frameworks     # rebuild only MAD Designer.app (fast iteration)
./Mac/build.sh --smoke-test        # build and run the end-to-end macOS smoke suite
./Mac/build.sh --package           # create Mac/build/MAD-Designer-macOS.zip and .dmg
```

Você também pode compilar e depurar interativamente no Xcode usando o esquema compartilhado **`MAD Designer Mac`**, ou executar a suíte de testes unitários de qualquer framework nativamente no macOS:

```sh
xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
	-destination 'platform=macOS,arch=arm64' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
```

### Simulador do iOS

Execute a suíte de testes de um framework no Simulador do iOS:

```sh
xcodebuild test -workspace Reports.xcworkspace -scheme MADFoundation \
	-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
```

(`MADMySQL`, `MADTdsClient` e `MADPostgres` também possuem suítes de testes live que se comunicam com um servidor de banco de dados real e são puladas quando o servidor não está acessível — consulte [`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md).)

### Linux (Engine Headless e CLI)

A engine headless é verificada da mesma forma no Linux. A partir da raiz do repositório, com o Docker instalado:

```sh
./Linux/build.sh       # build the toolchain image, compile the eleven frameworks, run the suites
```

Isso executa 126 binários de teste e 1.303 testes dentro do contêiner, e `--verify` adiciona as verificações ponta a ponta da CLI contra as fixtures versionadas e seus digests fixados. Consulte [`Linux/README.md`](Linux/README_pt-BR.md) para detalhes sobre a imagem, as versões fixadas e as divergências do GNUstep encontradas durante o porte.

## Apoie o projeto

O MAD é software livre e continuará sendo livre. Um único mantenedor cuida do projeto: os documentos de arquitetura, a matriz de testes em duas plataformas e o desenvolvimento assistido por agentes consomem tempo real e tokens de API. Se o MAD economiza tempo da sua equipe, veja como retribuir — e muito obrigado de qualquer forma:

* **[Patrocine o mantenedor](https://github.com/sponsors/mthomason)** — contribuição única ou mensal via GitHub Sponsors.
* **Envie créditos de API.** O projeto é desenvolvido com agentes de IA; créditos da OpenAI, Anthropic ou de tokens de agentes são revertidos diretamente para o trabalho no projeto. Entre em contato pela página de patrocínio ou por uma issue.
* **[Contribua](CONTRIBUTING_pt-BR.md).** Um driver de banco de dados, um elemento de documento, um formato de exportação, um importador legado ou uma correção — os pontos de extensão foram feitos para isso.

## Licença

MIT — consulte [`LICENSE`](LICENSE). A licença cobre o software; os nomes "MAD", "MAD Designer" e "MAD Viewer", os ícones dos aplicativos e demais artes visuais dos produtos, bem como a mídia de pré-visualização do aplicativo pertencem ao autor e estão excluídos da licença (consulte [`NOTICE`](NOTICE)). Cada componente de terceiros, sua respectiva licença e as obrigações associadas à sua distribuição estão registrados em [`docs/project/THIRD_PARTY_LICENSES.md`](docs/project/THIRD_PARTY_LICENSES.md).

## Conformidade de exportação

Os drivers MySQL, FreeTDS e PostgreSQL utilizam OpenSSL/TLS; nenhuma criptografia proprietária ou customizada é implementada. Pelas diretrizes de conformidade de exportação da Apple, trata-se de criptografia isenta, e o aplicativo define `ITSAppUsesNonExemptEncryption = NO`.
