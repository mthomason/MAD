---
layout: default
title: "Portabilidade e o aplicativo nativo para macOS"
description: "A auditoria de portabilidade dos frameworks e a arquitetura do aplicativo AppKit."
lang: pt-BR
---

# `MAD_MACOS.md` -- Frameworks multiplataforma e o aplicativo nativo para macOS

Esta página registra a auditoria dos frameworks multiplataforma e a arquitetura do aplicativo nativo para macOS. O guia voltado ao usuário está em `/macos.html`.

*Escrito na data original; fatos do estado atual reconciliados em 2026-11-22.*

Este documento registra a decisão de arquitetura, a auditoria de portabilidade framework por framework
e o plano faseado de migração e implementação para tornar os frameworks MAD
genuinamente multiplataforma (`iphoneos`, `iphonesimulator`, `macosx` e Linux headless)
e construir o frontend nativo para macOS (`AppKit`) do **MAD Designer**.

---

## 1. Decisão: macOS nativo (`AppKit`) vs. Mac Catalyst

**Decisão:** construir um **aplicativo nativo para macOS (SDK `macosx`, `AppKit`)** sobre frameworks
multiplataforma compartilhados (`MACOSX_DEPLOYMENT_TARGET = 12.0`, com suporte a todo Mac Apple
Silicon e a Macs Intel no Monterey ou mais recente). **O Mac Catalyst é rejeitado.**

### Por que o macOS nativo vence

| Dimensão | macOS nativo (`macosx` / `AppKit`) | Mac Catalyst (`maccatalyst` / `UIKit`) |
|---|---|---|
| **Bibliotecas C estáticas (`Compressor`)** | **Já compiladas.** Todos os 10 pacotes `.xcframework` em `Compressor/library/` carregam fatias universais `macosx` (`arm64` + `x86_64`, `-mmacosx-version-min=11.0`) verificadas por `./Compressor/build.sh --verify --all --platforms ios,simulator,macosx`. | **Ausentes.** Não existe nenhuma fatia `maccatalyst` (`-target <arch>-apple-ios15.0-macabi`). O linker Mach-O rejeita vincular arquivos `MACOS` em binários `MACCATALYST`; o Catalyst exigiria adicionar uma 4ª plataforma ao `Compressor` e recompilar todas as 10 bibliotecas C (`openssl`, `mariadb`, `postgres`, `freetds`, `libarchive`, `sqlite3`, `zint`, `libpng`, `bzip2`, `zlib`). |
| **Portabilidade do núcleo da engine** | **90% concluída.** A portabilidade headless para Linux (`MAD_LINUX.md`) já removeu o Core Data do `MAD.framework`, desacoplou os drivers de banco de dados (`MADDatabaseDriverRegistry`) e os exportadores de relatórios (`MADReportExporterRegistry`), e introduziu `MADHeadlessDocument`, `MADSQLQueryCompiler` e `MADDesignerLayout`. | A mesma engine, mas presa aos ciclos de vida de `UIDocument` e de tarefas em segundo plano do iOS. |
| **Ergonomia de desktop** | `NSDocument` / `NSDocumentController` nativos (duplo clique no Finder, `Cmd+N`, `Cmd+O`, `Cmd+S`, `Cmd+Shift+S`, Documentos Recentes, restauração de janela, `NSUndoManager`), visões divididas nativas, visões de tabela/estrutura nativas, `PDFView` / `WKWebView` nativos e menus padrão do macOS. | `UIScrollView` + seções `UICollectionView` com zoom aninhado, barras de abas/navegação do iOS, rodas `UIPickerView` e navegador de documentos em sandbox do iOS (`MADExplorer`). Macs Apple Silicon já executam a compilação para iPad via *Designed for iPad*. |
| **Distribuição via GitHub** | Pacote `.app` independente e limpo, empacotado como `.dmg` e `.zip` para download no GitHub Releases (`arm64` + `x86_64`). | Exige perfil de provisionamento e direitos do Catalyst que não combinam com a ergonomia de distribuição fora da App Store. |

---

## 2. Auditoria das bibliotecas estáticas (`Compressor`)

Todas as dez bibliotecas C fornecidas em `Compressor` compilam fatias universais `macosx` (`arm64` + `x86_64`)
com `-mmacosx-version-min=11.0`:

| Biblioteca | Versão | `ios` (`arm64`) | `simulator` (`arm64` + `x86_64`) | `macosx` (`arm64` + `x86_64`) | Usada por |
|---|---|:---:|:---:|:---:|---|
| `sqlite3` | 3.53.3 | Sim | Sim | Sim | `MADSqlite3`, `MAD` |
| `zlib` | 1.3.2 | Sim | Sim | Sim | `MAD`, `MADMySQL`, `MADPostgres`, `MADBarcodes` |
| `openssl` | 3.5.9 | Sim | Sim | Sim | `MADTds`, `MADMySQL`, `MADPostgres` |
| `bzip2` | 1.0.8 | Sim | Sim | Sim | `MAD` |
| `libpng` | 1.6.59 | Sim | Sim | Sim | `MADBarcodes` |
| `libarchive` | 3.8.9 | Sim | Sim | Sim | `MAD` |
| `freetds` | 1.4.27 | Sim | Sim | Sim | `MADTds`, `MADTdsClient` |
| `mariadb` | 3.4.11 | Sim | Sim | Sim | `MADMySQL` |
| `postgres` | 17.11 | Sim | Sim | Sim | `MADPostgres` |
| `zint` | 2.16.0 | Sim | Sim | Sim | `MADBarcodes` |

Comando de verificação:

```sh
./Compressor/build.sh --verify --all --platforms ios,simulator,macosx
```

---

## 3. Auditoria multiplataforma framework por framework

Doze frameworks formam a pilha multiplataforma (`iphoneos`, `iphonesimulator`, `macosx`,
mais Linux para os doze frameworks headless):

1. **`MADFoundation`** (28 arquivos `.m`):
   - `MADApplication.h`: proteja `<UIKit/UIApplication.h>` com `#if TARGET_OS_IPHONE`
     em vez de `#if __APPLE__` (`MADApplication.m` já tem
     `#elif TARGET_OS_OSX #import <AppKit/NSApplication.h>`).
   - `MADURLFactory.m`: proteja `<UIKit/UIScreen.h>` com `#if TARGET_OS_IPHONE` e use
     `NSScreen.mainScreen.backingScaleFactor > 1.0` em `TARGET_OS_OSX`.
   - `MADKeyChain.m`: usa `Security.framework`, que é nativo tanto no iOS quanto no macOS.
2. **`MADDataStructures`** (17 arquivos `.m`):
   - Foundation puro + C++. Nenhuma mudança no código-fonte necessária.
3. **`MADFileManager`** (11 arquivos `.m`):
   - Remova o `#import <MobileCoreServices/UTType.h>` não utilizado em
     `MADMetaDataLocal.m:16` (`<UniformTypeIdentifiers/UTType.h>` já está importado na
     linha 17).
4. **`MADCocoaExtensions`** (17 arquivos `.m`):
   - `CGGeometry+Extras.h`: forneça `UIEdgeInsets` (struct de layout compatível com `NSEdgeInsets`
     + `UIEdgeInsetsMake` / `UIEdgeInsetsZero` / `UIEdgeInsetsEqualToEdgeInsets`),
     `NSStringFromCGPoint` / `NSStringFromCGSize` / `NSStringFromCGRect` e
     `NSValue (MADCGGeometryExtensions)` (`valueWithCGPoint:`, `CGPointValue`,
     `valueWithCGRect:`, `CGRectValue`, `valueWithCGSize:`, `CGSizeValue`) em
     `TARGET_OS_OSX`.
   - `MADColor.h` / `MADColor.m`: faça a ponte de `MADColor` para `NSColor` em `TARGET_OS_OSX` mantendo
     `UIColor` em `TARGET_OS_IPHONE`.
   - Proteja as categorias `UIView`, `UIAlertController`, `UITextField` e `UIColor`, exclusivas do iOS,
     com `#if TARGET_OS_IPHONE`.
5. **`MADAPI`** (11 arquivos `.m`):
   - 9 arquivos centrais de banco de dados, consulta e registro de drivers são Foundation puro.
   - Proteja `MADConnectionViewController` e `MADConnectionSQLGenericViewController`
     com `#if TARGET_OS_IPHONE`.
6. **`MADSqlite3`** (26 arquivos `.m`):
   - Foundation puro + `sqlite3.xcframework`. Nenhuma mudança no código-fonte necessária.
7. **`MADTds`** (1 arquivo `.m`):
   - Foundation puro + `freetds.xcframework` + `openssl.xcframework`. Nenhuma mudança no código-fonte
     necessária.
8. **`MADTdsClient`** (4 arquivos `.m`):
   - `MADDatabaseSQLServer`, `MADTdsConnection` e `MADDataTypeSQLServer` são
     Foundation puro. Proteja `MADTdsConnectionViewController` com `#if TARGET_OS_IPHONE`.
9. **`MADMySQL`** (19 arquivos `.m`):
   - 18 arquivos de driver são Foundation puro + `mariadb.xcframework`. Proteja
     `MADMySQLConnectionViewController` com `#if TARGET_OS_IPHONE`.
10. **`MADPostgres`** (5 arquivos `.m`):
    - 4 arquivos de driver são Foundation puro + `postgres.xcframework`. Proteja
      `MADPostgresConnectionViewController` com `#if TARGET_OS_IPHONE`.
11. **`MADBarcodes`** (70 arquivos `.m`):
    - 67 classes de simbologia são Foundation puro + `zint.xcframework`.
    - `MADBarcode`, `MADBarcodeCache` e `MADBarcodeView`: faça a ponte de `UIImage` / `NSImage`
      e `UIView` / `NSView` em `TARGET_OS_OSX` sobre o pipeline existente
      `MADBarcodeImageFromZintBitmap` de `CGImageRef`.
12. **`MAD`** (199 arquivos `.m`):
    - Substitua `#if __APPLE__` por `#if TARGET_OS_IPHONE` e `#elif TARGET_OS_OSX`
      nas pontes AppKit dos 9 arquivos compartilhados de modelo/renderização (`RptqObject.m`,
      `RptqDocumentElementImage+Extras.m`, `RptqDocument+Extras.m`,
      `RptqDocumentSection+Extras.m`, `RptqDocumentElement+Extras.m`,
      `MADPrintPageElement.m`, `MADElementStylizedText.m`, `MADFonts.m` e
      `MADReportExporterPDF.m`).
    - Em `MADReportExporterPDF.m`, renderize PDFs paginados em `TARGET_OS_OSX` usando
      `CGPDFContextCreateWithURL` / `CGPDFConsumerCreateWithCFData` e
      `NSGraphicsContext` (`+graphicsContextWithCGContext:flipped:YES`), para que
      `MADPrintPageRenderer` e `MADPrintPageElement` desenhem nativamente no macOS.
    - Proteja os 22 arquivos `UIDocument` (`MADocument`), `UIView` e
      `UICollectionViewLayout` exclusivos do iOS com `#if TARGET_OS_IPHONE`.

`MADExplorer` permanece exclusivo do iOS (o macOS usa `NSDocumentController`, o Finder e `NSOpenPanel` com um botão **New Document** primário). `MADFeedback` e `Scrimpter` permanecem sem uso conforme
`AGENTS.md`.

---

## 4. Plano de implementação faseado

### Fase 1: correções de bugs e habilitação multiplataforma dos frameworks (Concluída)

1. **Corrigidos 6 defeitos surgidos durante a auditoria e a portabilidade para macOS** e arquivados de
   `docs/project/registers/BUGS.md` para `docs/project/registers/BUGS_FIXED.md` com testes unitários:
   - `MADKeyChain` (`MADFoundation/Source/MADKeyChain.m`): parou de solicitar
     `kSecReturnData : @YES` (e de vazar o `CFDataRef` retornado) em
     `+credentialsExist:`, `+saveToken:forKey:withDescription:`, `+deleteKey:` e
     `+deleteSavedPasswordForKey:error:`.
   - `MADURLFactory` (`MADFoundation/Source/MADURLFactory.m`): protegeu
     `+newURLForLocalApplicationSupportDirectory` quando `[NSBundle mainBundle].bundleIdentifier`
     é `nil` (recorrendo a `[MADApplication groupIdentifier]`), e protegeu
     `containerURLForSecurityApplicationGroupIdentifier:` com
     `#if defined(__APPLE__) && TARGET_OS_IPHONE` para que processos macOS sem direitos usem
     diretórios padrão por usuário em vez de disparar avisos do TCC em
     `~/Library/Group Containers/`.
   - `MADDataTable` (`MADFoundation/Source/MADDataTable.m`): protegeu
     `NSDataWritingFileProtectionCompleteUnlessOpen` com
     `#if defined(__APPLE__) && TARGET_OS_IPHONE` para que gravações de cache no macOS sem direitos tenham sucesso.
   - `MADDatabaseSqlite3` (`MADSqlite3/Source/MADDatabaseSqlite3.m`): protegeu
     `[dataTable endBulkInsert]` com `if (rowCounter > 0)` para que consultas `SELECT` com zero linhas
     não executem `COMMIT TRANSACTION` quando `[dataTable beginBulkInsert]` nunca foi
     chamado.
   - `MADBarcode` (`MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m`): corrigiu
     `-drawInRect:` que duplicava `rect.origin` quando `self.center == YES`.
   - `MADDesignerLayout` (`MAD/Source/MADDesignerLayout.m`): preservou o valor prévio de cada elemento
     selecionado em um dicionário ao registrar ações de desfazer em todos os
     métodos de atualização em lote (`setFontsize:`, `setFontname:`, `setVerticalAlignment:`,
     `setHorizontalAlignment:`, `setSizeWidth:`, `setSizeHeight:`, `setMargin*`,
     `setPadding*`, `setBorder*`).
2. **Habilitado `macosx` nos 12 projetos Xcode dos frameworks:**
   - Definido `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"` e
     `MACOSX_DEPLOYMENT_TARGET = 12.0`.
   - Adicionado `platformFilters = (ios, maccatalyst, );` nas referências a `UIKit.framework` e
     vinculado `AppKit.framework` com `platformFilters = (macos, );` onde necessário.
   - Atualizadas as fases de compilação `Ensure Libraries` para passar
     `--platforms ios,simulator,macosx`.
3. **Verificados todos os 12 frameworks no macOS nativo (`-destination 'platform=macOS,arch=arm64'`):**
   - `MADFoundation`: **199 testes passaram, 0 falhas**
   - `MADDataStructures`: **72 testes passaram, 0 falhas**
   - `MADCocoaExtensions`: **80 testes passaram, 0 falhas**
   - `MADFileManager`: **85 testes passaram, 0 falhas**
   - `MADAPI`: **106 testes passaram, 0 falhas**
   - `MADSqlite3`: **118 testes passaram (5 benchmarks ignorados), 0 falhas**
   - `MADTds`: **Compilado sem erros para `macosx`**
   - `MADTdsClient`: **77 testes passaram (incluindo a suíte ativa do SQL Server), 0 falhas**
   - `MADMySQL`: **Todos os testes offline e ativos de MariaDB/MySQL passaram, 0 falhas**
   - `MADPostgres`: **31 testes passaram (incluindo a suíte ativa do PostgreSQL), 0 falhas**
   - `MADBarcodes`: **30 testes passaram, 0 falhas**
   - `MAD`: **650 testes passaram, 0 falhas**

### Fase 2: importação de esquema multiplataforma e camada `NSDocument` (Concluída)

1. **Criação de documentos e importação de esquema multiplataforma (`MADHeadlessDocument`):**
   - Adicionado `+createDocumentAtURL:withDatabaseConnection:credentials:error:` em
     `MADHeadlessDocument` (`MAD/Source/MADHeadlessDocument.h`, `.m`), que conecta a
     qualquer driver registrado (`SQLite3`, `MySQL`, `SQL Server`, `PostgreSQL`), importa todas
     as tabelas do banco de dados (`-getTablesFromConnection:error:`) e colunas
     (`-fieldsForTable:connection:error:`) em `RptqDatabaseSchemaTable` /
     `RptqDatabaseSchemaField`, inicializa as seções padrão do relatório (`Report Header`,
     `Page Header`, `Report Detail`, `Page Footer`, `Report Footer`) e grava o
     contêiner portátil `.mad`.
2. **`MADMacDocument` (subclasse de `NSDocument` em `Mac/Source/MADMacDocument.m`):**
   - Envolve `MADHeadlessDocument` (com conversão automática de `.mad` legado do Core Data via
     `MADStoreConverter` quando necessário), conforma-se a `MADocumentDesignerProtocol` para que
     `MADDesignerLayout` registre desfazer/refazer diretamente no `NSDocument.undoManager`, e
     suporta `readFromURL:ofType:error:`,
     `writeToURL:ofType:forSaveOperation:originalContentsURL:error:` e
     `refreshWithCredentials:maxRows:completion:` assíncrono.

### Fase 3: aplicativo nativo para macOS (`Mac/`) (Concluída)

Construído em `Mac/` (`Mac/Source/`, `Mac/Resources/`, `Mac/Tests/`, `Mac/build.sh`) e integrado ao `MAD Designer.xcodeproj` pelo alvo **`MAD Designer Mac`** e esquema compartilhado:

1. **Ciclo de vida do aplicativo, janela Sobre e controlador de documentos (`MADMacAppDelegate`, `MADMacAboutWindowController` e `MADMacDocumentController`):**
   - Registra todos os quatro drivers de banco de dados e `MADStoreLegacyConverter`, constrói o menu principal nativo do macOS (`MAD Designer`, `File`, `Edit` com `Undo`/`Redo`, `View` alternando áreas de trabalho com `Cmd+1`/`Cmd+2`/`Cmd+3`, `Report` atualizando com `Cmd+R`, `Window`, `Help`) e apresenta o `NSOpenPanel` padrão na inicialização quando nenhum documento está aberto.
   - `MADMacAboutWindowController` apresenta a janela nativa **About MAD Designer** (itens `MAD Designer → About MAD Designer` e do menu `Help`) com a versão/compilação da engine (`MADMeta.plist`) e a versão do aplicativo macOS (`CFBundleShortVersionString`) mostradas como valores distintos, aviso de direitos autorais e de marca/arte reservada, ação **Source Code on GitHub** e três seções em abas: **Overview** (o que é o MAD, o fluxo de relatórios em 4 passos e drivers/faixas/exportadores suportados), **License & Notice** (Licença MIT, `NOTICE` e a oferta escrita de relink LGPL-3.0 para FreeTDS e MariaDB Connector/C) e **Acknowledgements** (barra lateral interativa de todos os 16 componentes open-source de terceiros com suas atribuições e os 12 textos completos de licença incluídos em `Contents/Resources/Licenses/`).
   - `MADMacDocumentController` configura o `NSOpenPanel` com todos os identificadores `UTType` de `.mad` (`com.everydayapps.productivity.mad` e `com.thomason.report.mad`) para que arquivos `.mad` existentes nunca fiquem esmaecidos, e coloca um botão **New Document** primário diretamente na barra inferior esquerda do painel Abrir.
2. **Assistente de conexão de banco de dados e importação de esquema (`MADMacConnectionWindowController`):**
   - Suporta **SQLite** (arquivo `.sqlite3`/`.db` personalizado via `NSOpenPanel`), **MySQL**, **Microsoft SQL Server** e **PostgreSQL**, com **Test Connection**, armazenamento de senha no `MADKeyChain` e **Create Document…** (`NSSavePanel`).
3. **Janela principal do documento (`MADMacWindowController`):**
   - Centraliza o controle segmentado **Workspace** (**MAD Query**, **MAD Designer**, **MAD Viewer**) na barra de ferramentas da janela.
4. **Área de trabalho MAD Query (`MADMacQueryViewController`):**
   - Modos de área de trabalho mutuamente exclusivos **Query Designer** e **SQL Query** (alternados na
     barra de cabeçalho da área de trabalho para que o design visual de consultas e a entrada manual de SQL nunca sejam
     mostrados simultaneamente).
   - **Modo Query Designer**: uma lista **Database Tables** de `200px` à esquerda (redimensionável pelo usuário
     via `NSSplitViewDelegate` sem voltar ao tamanho anterior, e mantida em largura fixa quando a
     janela é redimensionada para que a tela visual seja redimensionada) emparelhada com uma tela visual
     interativa à direita (`MADMacQueryCanvasView`). Um duplo clique em uma tabela de esquema
     a adiciona à consulta (preenchendo todas as linhas `RptqQueryField`) e a exibe como um
     cartão de tabela AppKit flutuante arrastável e redimensionável (`MADMacQueryTableCardView` +
     `MADMacQueryFieldTableView`) estilizado com cabeçalhos topológicos de raiz/filho (`MTGraph`),
     e arrastar de um campo em um cartão de tabela para um campo em outro cria uma
     **Left Outer Join** padrão (`MADLinkTypeLeftOuterJoin`) desenhada com conectores Bezier e
     emblemas de tipo de junção (`MADMacQueryLinksOverlayView`, correspondendo ao `MADConnectorView` do iPad).
     Clicar ou clicar com o botão direito em um conector de junção visual abre um popover de inspetor de junção ou
     menu de contexto para mudar o tipo de link, inverter a direção ou excluir o link; popovers de cabeçalho
     fornecem **Filters (WHERE)**, **Groupings (GROUP BY)** e **Arrange Tables**.
   - **Modo SQL Query**: editor de instruções SQL em largura total exibindo o SQL gerado ou inserido
     e suportando validação, compilação e aplicação (`MADSQLParser` +
     `MADSQLStatementResolver` + `MADSQLQueryCompiler`).
5. **Área de trabalho MAD Designer (`MADMacDesignerViewController` + `MADMacDesignerCanvasView` + `MADMacDesignerMinimapView`):**
   - **Barra superior da área de trabalho (altura `38pt`):** fornece itens de paleta de elementos SF Symbol clicáveis e arrastáveis
     (**Label**, **Data Field**, **Aggregate**, **Barcode**,
     **Image**, **Line**), controles rápidos de alinhamento de vários elementos (`Left`, `Center`,
     `Right`, `Top`, `Middle`, `Bottom`), **Size to Fit**, alternadores **Grid** / **Snap** /
     **Rulers** e um controle deslizante **Zoom** com redefinição para `100%` em um clique.
   - **Visão dividida em 3 painéis redimensionável pelo usuário (`NSSplitViewDelegate`):** a barra lateral de navegação esquerda
     tem padrão de `220pt` (`180–340pt`), o inspetor direito tem padrão de `260pt`
     (`220–380pt`), e ambas as barras laterais mantêm suas larguras ao redimensionar a janela enquanto
     preservam os ajustes de divisória do usuário.
   - **Barra lateral esquerda (minimapa + faixas + navegador de campos de consulta):**
     - **Minimapa interativo de páginas e seções (`MADMacDesignerMinimapView`):** desenha
       faixas proporcionais do relatório com listras codificadas por cor, blocos em miniatura ao vivo dos elementos
       e um retângulo de visão azul; clicar ou arrastar salta para a faixa e a seleciona.
     - **Estrutura de faixas do relatório:** lista todas as seções de relatório e de agrupamento com contagens de elementos,
       alturas e indicadores de quebra de página; um duplo clique alterna a visibilidade da faixa.
     - **Navegador de campos de consulta:** lista filtrável (`NSSearchField`) de todas as colunas
       `RptqQueryField`; arrastar um campo para qualquer faixa de seção na tela (ou um duplo clique)
       insere um `RptqDocumentElementLabelDataField` vinculado.
   - **Tela interativa central (`MADMacDesignerCanvasView`):** tela `NSView` invertida e ampliável
     com réguas horizontais/verticais, margens de papel, faixas de seção codificadas por cor,
     alças de arraste de altura de seção, guias de alinhamento inteligentes, encaixe na grade, seleção
     por retângulo, seleção múltipla com `Shift`+clique, alças de redimensionamento em 8 pontos, edição de rótulo
     em linha com duplo clique, posicionamento inteligente de elementos sem sobreposição
     (`-nextAvailableOriginInSection:forElementSize:`) e arrastar e soltar entre seções
     (`-moveElement:toSection:atOrigin:`) com realce ao vivo da faixa de destino e integração
     completa com `NSUndoManager`.
   - **Barra lateral do inspetor direito (claramente dividida e rolável):**
     - **Cartão 1 (`1 · PAGE & SELECTED SECTION`):** tamanho do papel, emblema da faixa selecionada,
       altura da faixa (`pt`) com botão **Fit Height**, **Section Visible** e **Page Break
       After**.
     - **Divisor visual destacado + Seção 2 (`2 · SELECTED ELEMENT INSPECTOR`):**
       4 cartões de inspetor agrupados (**Element & Band Assignment** com popup de movimentação entre seções,
       **Duplicate** e **Delete**; **Content & Data Binding** com texto estático,
       vinculação de campo de consulta, função e escopo de agregado, formatação de moeda e opções
       de código de barras; **Typography & Appearance** com família/tamanho de fonte, negrito/itálico/sublinhado/
       tachado, alinhamento horizontal/vertical e cores de texto/fundo; e
       **Position, Size & Box Model** com `X`, `Y`, `W`, `H` sincronizados entre
       `rect.origin` e `dropPoint`, mais bordas, preenchimento e margem).
6. **Área de trabalho MAD Viewer (`MADMacViewerViewController`):**
   - **Barra de ferramentas superior do visualizador (altura `40pt`):** popup **Page Size** (tipos de papel padrão
     `MTPaper`: `US Letter`, `US Legal`, `US Tabloid`, `A3`, `A4`, `A5`, `B4`, `B5`, `JIS B4`, `JIS B5`), **Refresh** (`Cmd+R`), controles de **Zoom**
     (`-`, `100%`, `+`), **Page Navigation** (`Previous`, `Page N of M`, `Next`), **Print…**
     (`Cmd+P` via `NSPrintOperation`) e **Export…** (`Cmd+E`).
   - **Pré-visualização paginada emoldurada (`PDFView`):** renderiza páginas PDF paginadas no tamanho de papel
     selecionado a partir do cache local da tabela SQLite (`MADDataTableFast`) com sombras de página e uma
     barra de status inferior (`statusBarView`) exibindo a contagem de páginas renderizadas, a contagem de linhas em cache
     e as dimensões do papel.
   - **Exportação multiformato (`NSSavePanel`):** configura um popup de formato acessório que suporta todos os 7
     exportadores registrados (`PDF`, `HTML`, `HTML Flow`, `CSV`, `JSON`, `JSON Report`, `Plain Text`) e
     atualiza dinamicamente a extensão de arquivo permitida no painel de salvamento.

### Fase 4: compilação, verificação rápida e empacotamento para GitHub Release (Concluída)

```sh
./Mac/build.sh --smoke-test --package
```

Produz:
- `Mac/build/MAD Designer.app` (pacote de aplicativo macOS nativo independente com todos os 12
  frameworks e modelos `.momd` legados do Core Data embutidos e assinados)
- `Mac/build/MAD-Designer-macOS.zip`
- `Mac/build/MAD-Designer-macOS.dmg`

A documentação pública de usuário e desenvolvedor do aplicativo nativo para macOS é publicada em [`docs/macos.md`](../../macos.md) (com capturas de tela em `docs/assets/macos-native-mad-query.png` e `docs/assets/macos-native-mad-designer.png`) e em [`Mac/README.md`](https://github.com/mthomason/MAD/blob/master/Mac/README.md).

### Integração contínua (Concluída)

`.github/workflows/macos.yml` é executado em cada pull request e push para `master`.
Ele compila (e armazena em cache) as bibliotecas estáticas do Compressor, depois executa as
suítes `MADBarcodes` e `MAD` em um simulador de iPhone descoberto no
runner, compila o esquema iOS `MAD Designer` e executa
`./Mac/build.sh --smoke-test`. A janela Sobre relata a versão da engine
(`MADMeta.plist`, `v9.0 (r4433)`) e a versão do aplicativo macOS
(`CFBundleShortVersionString`, `v0.7`) como valores distintos, correspondendo à
apresentação pós-Fase-6f da janela Sobre do Windows.

`macos-latest` é um runner arm64, e `Mac/build.sh` compila os frameworks para
`platform=macOS,arch=arm64`. A primeira execução baixa e compila todo código-fonte
de terceiros fixado para três plataformas (cerca de 15–40 minutos); execuções posteriores
restauram `Compressor/library` do cache do Actions e o passo de garantia não faz nada.
A receita do freetds busca `config.guess`/`config.sub` do Savannah uma vez sem
nova tentativa, então o workflow semeia `Compressor/media` primeiro (veja os comentários
do workflow). Um resíduo, não uma falha de compilação: o passo configure do libarchive encontrou
o `libbz2.tbd` do SDK em vez da instalação do bzip2 do Compressor, porque
`BZIP2_LIBRARY` não é a dica que o `FindBZIP2` do CMake moderno lê; a biblioteca do SDK
está presente e o aplicativo processa o xcframework do bzip2.
