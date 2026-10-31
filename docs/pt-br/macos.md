---
layout: default
title: MAD Designer para macOS
description: >-
  Designer e visualizador nativo de relatórios relacionais em AppKit para macOS com suporte a SQLite, MySQL, MariaDB, PostgreSQL e SQL Server — canvas visual de consultas, designer em bandas com minimapa e exportação para PDF/HTML/CSV/JSON.
image: /assets/macos-native-mad-designer.png
lang: pt-BR
---

# <a href="https://raw.githubusercontent.com/mthomason/MAD/master/StaticResources/Images/icons/document/Designer%20Icon@3x.png"><img src="../assets/mad-designer-macos-icon-256.png" alt="Ícone do MAD Designer para macOS" width="48" height="48" style="vertical-align: middle; margin-right: 10px;" /></a>MAD Designer para macOS

O **MAD Designer para macOS** é um aplicativo desktop nativo em `AppKit` (SDK `macosx`, `MACOSX_DEPLOYMENT_TARGET = 12.0`) para criar, consultar, diagramar, atualizar, imprimir e exportar Mobile Analytics Documents (`.mad`). Ele vincula os mesmos frameworks próprios em Objective-C e bibliotecas C estáticas universais (`Compressor`) que alimentam os aplicativos iOS e a engine headless.

Cada arquivo `.mad` criado ou editado no macOS é compatível byte a byte com os aplicativos para iPad/iPhone, com a CLI `mad` no Linux e com a GitHub Action [`mad-action`](https://github.com/mthomason/mad-action).

---

## Workspaces

Cada documento `.mad` aberto roda em uma janela `NSDocument` nativa (`MADMacDocument` / `MADMacWindowController`) com um controle segmentado **Workspace** centralizado na barra de ferramentas da janela (`Cmd+1`, `Cmd+2`, `Cmd+3`), que alterna entre os três estágios de construção e leitura do relatório:

### 1. MAD Query (`Cmd+1`)

![Workspace MAD Query no macOS mostrando a lista Database Tables, os cartões visuais de tabelas e os conectores de join LEFT OUTER](../assets/macos-native-mad-query.png)

O workspace **MAD Query** (`MADMacQueryViewController`) constrói o grafo de consulta relacional armazenado em `RptqQuery`. Um seletor na barra do workspace alterna entre duas visualizações mutuamente exclusivas da consulta:

* **Query Designer (Grafo Visual):**
  * **Barra Lateral Database Tables:** Exibe todas as tabelas importadas para o snapshot do esquema do documento (`RptqDatabaseSchemaTable`), com contagem de colunas e marcas de seleção para as tabelas que participam atualmente da consulta. Dê um duplo clique em qualquer tabela (ou clique em **+ Add Table to Query**) para adicioná-la ao canvas.
  * **Canvas Interativo de Relacionamentos (`MADMacQueryCanvasView`):** Renderiza cada tabela da consulta como um cartão arrastável e redimensionável (`MADMacQueryTableCardView`) sobre um canvas com grade de pontos, estilizado com cores de cabeçalho topológicas (raiz/filho) calculadas por `MTGraph`.
  * **Conectores Visuais de Join (`MADMacQueryLinksOverlayView`):** Arrastar de uma coluna em um cartão de tabela até uma coluna em outro cartão cria um join (por padrão `LEFT OUTER`), desenhado com curvas de Bézier cúbicas suaves, setas direcionais e badges em formato de pílula. Clicar ou clicar com o botão direito em um badge de join abre um popover inspetor ou menu de contexto para alterar o tipo de join (`INNER`, `LEFT OUTER`, `RIGHT OUTER`, `FULL OUTER`, `CROSS`), inverter a direção do join ou excluir o vínculo.
  * **Filtros, Agrupamentos e Auto-Layout:** Popovers na barra superior permitem editar **predicados `WHERE`** (`Filters (WHERE)`), **`GROUP BY` / ordem de classificação** (`Groupings (GROUP BY)` — que cria automaticamente as bandas correspondentes de `Group Header` e `Group Footer` no layout) e acionar **Arrange Tables** para posicionamento topológico automático dos cartões.
* **SQL Query (Entrada Direta e Inspeção de SQL):**
  * Exibe o SQL determinístico e específico do dialeto gerado a partir do grafo visual e permite colar ou editar uma instrução `SELECT` diretamente.
  * Valida e compila o SQL informado de volta para o grafo de objetos portável `RptqQuery` por meio de `MADSQLParser`, `MADSQLStatementResolver` e `MADSQLQueryCompiler`, preservando a instrução original em `RptqQuery.sqlSourceText`.

---

### 2. MAD Designer (`Cmd+2`)

![Workspace MAD Designer no macOS mostrando Page & Section Minimap, Report Bands, Query Fields, canvas de design em bandas e Inspector](../assets/macos-native-mad-designer.png)

O workspace **MAD Designer** (`MADMacDesignerViewController`) diagrama as bandas paramétricas e os elementos do relatório dentro de uma split view de três painéis redimensionáveis pelo usuário:

* **Barra de Ferramentas Superior do Designer:**
  * **Paleta de Elementos:** Clique ou arraste para qualquer banda de seção para inserir um **Label** (rótulo estático), **Data Field** (campo de dados), **Aggregate** (agregação), **Barcode** (código de barras), **Image** (imagem) ou **Line** (linha).
  * **Alinhamento e Dimensionamento:** Botões de alinhamento para múltiplos elementos (`Align Left`, `Center`, `Right`, `Top`, `Middle`, `Bottom`) e **Size to Fit**.
  * **Controles do Canvas:** Botões independentes para **Grid**, **Snap** e **Rulers** (réguas), além de um controle deslizante contínuo de **Zoom** (`50%–250%`) com redefinição para `100%` em um clique.
* **Barra Lateral Esquerda de Navegação:**
  * **Page & Section Minimap (`MADMacDesignerMinimapView`):** Visão geral proporcional em tempo real de todas as bandas do relatório, blocos de elementos em miniatura e o retângulo do viewport de rolagem ativo. Clique ou arraste dentro do minimapa para saltar e selecionar qualquer banda.
  * **Outline Report Bands:** Lista `Report Header`, `Page Header`, quaisquer bandas de `Group Header` / `Group Footer`, `Report Detail`, `Page Footer` e `Report Footer`, com contagem de elementos, alturas em pontos e indicadores de quebra de página. Dar um duplo clique em uma linha alterna a visibilidade da seção.
  * **Navegador Query Fields:** Lista filtrável de todas as colunas `RptqQueryField` da consulta. Arraste qualquer campo diretamente para uma banda de seção no canvas (ou dê um duplo clique) para criar um elemento de campo de dados vinculado (`RptqDocumentElementLabelDataField`).
* **Canvas Interativo Central (`MADMacDesignerCanvasView`):**
  * Canvas `NSView` com coordenadas invertidas (origem no topo esquerdo) e zoom, equipado com réguas horizontais e verticais em pontos, guias de margem de papel, cabeçalhos de seção codificados por cores (`RH`, `PH`, `GH`, `DTL`, `GF`, `PF`, `RF`) e alças inferiores de arrasto para redimensionar a altura das seções.
  * Suporta seleção por retângulo (marquee), multisseleção com `Shift`-clique, alças de redimensionamento de 8 pontos, guias inteligentes de alinhamento, ajuste à grade (grid snap), edição de texto inline com duplo clique, arrastar e soltar entre seções (`-moveElement:toSection:atOrigin:`) e suporte completo a desfazer/refazer via `NSUndoManager` (`Cmd+Z` / `Cmd+Shift+Z`) tanto para edições individuais quanto em lote.
* **Barra Lateral Direita do Inspetor:**
  * **`1 · PAGE & SELECTED SECTION`:** Configura o tamanho de **Paper** (papel) alvo, exibe o badge da banda ativa, edita a altura da seção (**Height (pt)**) com botão **Fit Height**, e alterna **Section Visible** e **Page Break After**.
  * **`2 · SELECTED ELEMENT INSPECTOR`:** Quatro cartões contextuais exibidos quando um elemento está selecionado:
    1. **Element & Band Assignment:** Reatribui o elemento a outra banda de seção, duplica (`Cmd+D`) ou exclui (`Delete`).
    2. **Content & Data Binding:** Texto estático, coluna vinculada da consulta (`table.column`), função de agregação (`SUM`, `COUNT`, `AVG`, `MIN`, `MAX`, `STDDEV`, `VARIANCE`) e escopo (`Report` ou `Group`), formatação monetária ou simbologia de código de barras (`zint`).
    3. **Typography & Appearance:** Família da fonte, tamanho em pontos, estilos Bold / Italic / Underline / Strikethrough, alinhamento horizontal e vertical do texto, cor do texto e preenchimento de fundo.
    4. **Position, Size & Box Model:** Coordenadas exatas em pontos (`X`, `Y`, `W`, `H`), largura/cor da borda, padding e margens.

---

### 3. MAD Viewer (`Cmd+3`)

O workspace **MAD Viewer** (`MADMacViewerViewController`) atualiza a consulta contra sua fonte de dados ativa, materializa o conjunto de resultados no cache local de tabela SQLite (`MADDataTableFast`) e renderiza as páginas diagramadas:

* **Barra de Ferramentas do Viewer:**
  * **Seletor Page Size (`MTPaper`):** Repagina e renderiza novamente o relatório de forma instantânea para **US Letter**, **US Legal**, **US Tabloid**, **A3**, **A4**, **A5**, **B4**, **B5**, **JIS B4** ou **JIS B5**.
  * **Refresh (`Cmd+R`):** Executa a consulta por meio do driver de banco de dados registrado no documento, popula o cache SQLite complementar `.maddb` / `.mdcache`, calcula agrupamentos e agregações em duas passagens e reconstrói o cache de páginas.
  * **Zoom e Navegação de Páginas:** Diminuir zoom, redefinir para `100%`, aumentar zoom e avançar/retroceder páginas (`Previous`, `Page N of M`, `Next`).
  * **Print (`Cmd+P`) e Export (`Cmd+E`):** Imprime nativamente via `NSPrintOperation` ou abre o `NSSavePanel` com um seletor de formato para todos os sete exportadores registrados:
    * **PDF Document (`.pdf`)** — PDF vetorial nativo via CoreGraphics / AppKit (`MADReportExporterPDF`)
    * **HTML Page (`.html`)** — fac-símile de página com posicionamento absoluto (`MADReportExporterHTML`)
    * **HTML Flow (`.html`)** — HTML semântico responsivo e refluível (`MADReportExporterHTMLFlow`)
    * **CSV Spreadsheet (`.csv`)** — exportação de linhas de detalhe compatível com RFC 4180 (`MADReportExporterCSV`)
    * **JSON Data (`.json`)** — contrato de esquema + linhas de detalhe (`MADReportExporterJSON`)
    * **JSON Full Report (`.json`)** — seções hierárquicas, grupos e elementos avaliados (`MADReportExporterJSONReport`)
    * **Plain Text (`.txt`)** — tabela de texto monoespaçado (`MADReportExporterText`)
* **Pré-visualização de Página Emoldurada e Barra de Status:** Renderiza páginas nítidas com sombra projetada dentro de um `PDFView` nativo e informa o total de páginas renderizadas, a quantidade de linhas em cache e as dimensões do papel na barra de status inferior.

---

## Abrindo e Criando Documentos

* **Inicialização e Painel de Abertura (`MADMacDocumentController`):** Iniciar o aplicativo sem abrir um arquivo exibe o painel **Open Report** do macOS filtrado para documentos `.mad` (`com.everydayapps.productivity.mad` e `com.thomason.report.mad`), com um botão principal **New Document** na barra inferior esquerda. Dar um duplo clique em qualquer arquivo `.mad` no Finder abre-o diretamente em sua janela de workspace.
* **Migração Automática de Documentos Legados:** Abrir um arquivo `.mad` mais antigo baseado em Core Data converte seu store automaticamente para o esquema SQLite portável (`MADStoreSchema`) por meio de `MADStoreConverter`.
* **Novo Relatório a partir de Conexão de Banco de Dados (`Cmd+N`):** Clicar em **New Document** (ou selecionar **File → New Document…**) abre o assistente de conexão de banco de dados (`MADMacConnectionWindowController`):
  * Escolha **SQLite**, **MySQL**, **Microsoft SQL Server** ou **PostgreSQL**.
  * Selecione um banco de dados local `.sqlite3` / `.db` ou informe o host do servidor, porta, instância opcional do SQL Server, nome do banco de dados, usuário e senha.
  * Clique em **Test Connection** para verificar a conectividade e inspecionar a quantidade de tabelas encontradas.
  * Clique em **Create Document…** para importar o esquema de tabelas e colunas do banco de dados para um novo arquivo `.mad` e abri-lo no workspace **MAD Query**. As credenciais são armazenadas nas Chaves do macOS (Keychain) via `MADKeyChain`.

---

## Arquitetura: `AppKit` Nativo sobre Frameworks Multiplataforma

Em vez de encapsular a interface do iOS com Mac Catalyst, o MAD compila doze de seus quatorze frameworks nativamente para `macosx` (`SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"`, `MACOSX_DEPLOYMENT_TARGET = 12.0`) e constrói uma arquitetura de documentos `AppKit` dedicada (`Mac/Source/`) sobre eles:

| Camada | Componentes | Papel no macOS |
|---|---|---|
| **Bibliotecas C Estáticas (`Compressor`)** | `sqlite3`, `zlib`, `openssl`, `bzip2`, `libpng`, `libarchive`, `freetds`, `mariadb`, `postgres`, `zint` | Fatias universais (`arm64` + `x86_64`) para `macosx` dentro de pacotes `.xcframework`, verificadas por `./Compressor/build.sh --verify --all --platforms ios,simulator,macosx`. |
| **Frameworks Core e de Drivers** | `MADFoundation`, `MADDataStructures`, `MADCocoaExtensions`, `MADFileManager`, `MADAPI`, `MADSqlite3`, `MADTds`, `MADTdsClient`, `MADMySQL`, `MADPostgres`, `MADBarcodes`, `MAD` | Modelo compartilhado em Objective-C, store SQLite portável (`Rptq*`), parser/compilador SQL, drivers de protocolo de banco de dados, renderizador de código de barras zint, engine de undo/redo `MADDesignerLayout` e `MADPrintPageRenderer` / `MADReportExporterPDF`. |
| **Frontend Nativo em `AppKit` (`Mac/`)** | `MADMacAppDelegate`, `MADMacAboutWindowController`, `MADMacDocumentController`, `MADMacDocument`, `MADMacWindowController`, `MADMacConnectionWindowController`, `MADMacQueryViewController`, `MADMacDesignerViewController`, `MADMacDesignerCanvasView`, `MADMacViewerViewController` | Ciclo de vida nativo de `NSDocument`, janela About / Overview / Acknowledgements, barra de ferramentas e barra de menus, canvas visual de consultas, designer de relatórios de 3 painéis com minimapa e inspetor, e visualizador de relatórios em `PDFView`. |

A auditoria arquitetural completa e o registro de correções do porte multiplataforma estão documentados em [`docs/project/MAD_MACOS.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_MACOS.md).

---

## Compilação, Testes e Empacotamento

### No Xcode

Abra o `Reports.xcworkspace`, selecione o esquema compartilhado **`MAD Designer Mac`** com o destino **My Mac** e pressione **Run (`Cmd+R`)** para compilar e depurar interativamente o aplicativo nativo para macOS.

Para executar a suíte de testes unitários de qualquer framework nativamente no macOS:

```sh
xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
	-destination 'platform=macOS,arch=arm64' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
```

### Build de Linha de Comando, Suíte de Smoke Tests e Empacotamento de Release

O script autônomo `Mac/build.sh` compila todos os doze frameworks para macOS, monta e assina o bundle `Mac/build/MAD Designer.app`, executa a suíte de smoke tests ponta a ponta headless + AppKit (`Mac/Tests/MADMacSmokeTest.m`) e gera os pacotes distribuíveis `.zip` e `.dmg`:

```sh
./Mac/build.sh                     # build 12 macOS frameworks + MAD Designer.app
./Mac/build.sh --no-frameworks     # rebuild only MAD Designer.app (fast iteration)
./Mac/build.sh --smoke-test        # build and run the end-to-end macOS smoke suite
./Mac/build.sh --package           # package MAD-Designer-macOS.zip and MAD-Designer-macOS.dmg
```
