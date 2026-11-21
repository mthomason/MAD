---
layout: default
title: MAD Designer para Windows
description: >-
  Designer e visualizador de relatórios relacionais nativo para Windows (WPF) para SQLite, MySQL, MariaDB, PostgreSQL e SQL Server — canvas visual de consultas, designer de relatórios em bandas, visualizador com paginação exata e exportação para HTML/CSV/JSON, sobre o mesmo motor headless do Linux e do macOS.
image: /assets/mad-designer-icon-512.png
lang: pt-BR
---

# <a href="https://raw.githubusercontent.com/mthomason/MAD/master/StaticResources/Images/icons/document/Designer%20Icon@3x.png"><img src="../assets/mad-designer-icon-512.png" alt="Ícone do MAD Designer para Windows" width="48" height="48" style="vertical-align: middle; margin-right: 10px;" /></a>MAD Designer para Windows

**MAD Designer para Windows** é um aplicativo de desktop nativo para Windows Presentation Foundation (WPF) sobre .NET 10 para criar, consultar, diagramar, atualizar e exportar Mobile Analytics Documents (`.mad`). Ele executa o mesmo motor Objective-C próprio (`mad.exe`) do aplicativo para macOS e da CLI `mad` headless do Linux, de modo que todo documento que ele grava é compatível com os apps de iPad/iPhone, a CLI `mad` e a GitHub Action [`mad-action`](https://github.com/mthomason/mad-action).

> **Esta compilação 0.7 não é assinada.** Ela é compilada e publicada a partir do código-fonte público, mas não possui um certificado comercial de assinatura de código, então o Windows SmartScreen avisará na primeira execução. Nada está oculto: revise a compilação (abaixo), verifique o checksum SHA-256 e execute-a.

## Download e Instalação

* **Download direto:** [**MAD-Designer-Windows-0.7.zip**](https://github.com/mthomason/MAD/releases/download/v0.7.0/MAD-Designer-Windows-0.7.zip)
* **Versão:** app 0.7 / motor 9.0 (r4433).
* **Requisitos:** Windows 10 (1903 ou posterior) ou Windows 11, 64 bits. O arquivo é autocontido, então **não é necessário instalar o runtime do .NET**. O visualizador usa o runtime Evergreen do Microsoft Edge WebView2, que acompanha o Windows 11 e o Edge atualizado; em imagens antigas do Windows 10, instale o [runtime Evergreen](https://developer.microsoft.com/microsoft-edge/webview2/).

1. Baixe o `.zip` e extraia-o para uma pasta de sua escolha. Mantenha a estrutura de pastas: o aplicativo, o motor e as licenças ficam juntos.
2. Execute `Mad.Designer.Windows.exe` na raiz da pasta extraída.
3. Na primeira execução, o Windows SmartScreen pode exibir *“O Windows protegeu o seu PC”*. Escolha **Mais informações** e depois **Executar assim mesmo** — a compilação não é assinada de propósito (veja abaixo).

### O que há no arquivo

```
MAD-Designer-Windows-0.7/
  Mad.Designer.Windows.exe   o aplicativo WPF (autocontido)
  ...                        os arquivos do próprio aplicativo
  CLI/Fixtures/              London.portable.mad (um relatório de exemplo) e
                             chinook.sqlite3 (os dados de exemplo que ele atualiza)
  Windows/Engine/build/mad.exe       o motor headless
  Windows/Engine/build/*.dll         o runtime GNUstep/ObjC/VC do motor
  Windows/Engine/build/fonts/        as fontes Liberation usadas pela exportação em PDF
  ThirdParty/Licenses/       todas as licenças e avisos de terceiros
  LICENSE, NOTICE, README-Windows.txt
```

**Onde fica o motor:** `Windows/Engine/build/mad.exe`, ao lado das DLLs de runtime e da pasta `fonts`. O aplicativo o encontra pela mesma estrutura relativa ao repositório usada pela árvore de código-fonte; ele não usa uma instalação global do GNUstep. Deixe as pastas onde o arquivo as colocou.

### Verificando o download

A página da versão publica um checksum SHA-256 do arquivo. Compare-o após o download:

```powershell
Get-FileHash .\MAD-Designer-Windows-0.7.zip -Algorithm SHA256
```

Também é possível revisar a extração arquivo por arquivo: o arquivo compactado contém apenas o aplicativo publicado, o motor compilado por `Windows/Engine/build.ps1`, o documento de exemplo e os textos das licenças. `mad.exe` é o mesmo motor de linha de comando documentado no [guia do Linux](https://github.com/mthomason/MAD/blob/master/Linux/README.md) e no [registro de compilação do Windows](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_WINDOWS.md).

### Revisando e assinando esta compilação

Você pode executar `mad.exe` diretamente para inspecionar um documento sem abrir a interface gráfica:

```powershell
.\Windows\Engine\build\mad.exe inspect .\CLI\Fixtures\London.portable.mad
```

Se quiser que o Windows pare de avisar sobre a *sua própria* cópia, crie um certificado local de assinatura de código e assine o executável. Esta é uma decisão de confiança local — ela não torna o download público confiável para mais ninguém:

```powershell
$cert = New-SelfSignedCertificate -Type CodeSigningCert `
    -Subject "CN=MAD Designer (local review)" `
    -CertStoreLocation Cert:\CurrentUser\My
Set-AuthenticodeSignature -FilePath .\Mad.Designer.Windows.exe -Certificate $cert
```

Para confiar nesse certificado nesta máquina, exporte-o e importe-o em **Autoridades de Certificação Raiz Confiáveis** com `certmgr.msc` ou `Import-Certificate`; faça isso apenas com um certificado que você criou e controla.

## Workspaces

O aplicativo tem as mesmas três etapas de relatório do app para macOS:

* **MAD Query** — o canvas visual de consultas (cartões de tabela arrastáveis, conectores de join Bézier, selos de tipo de join, filtros e agrupamentos) e o editor SQL direto, ambos sobre o esquema importado do documento.
* **MAD Designer** — o workspace de layout em bandas: o minimapa de página e seções, o esboço das bandas do relatório, os campos de consulta pesquisáveis, o canvas de design com zoom e réguas, com guias de alinhamento e desfazer/refazer, e o inspetor de elementos para conteúdo, tipografia e geometria.
* **MAD Viewer** — atualiza a consulta na tabela materializada local, escolhe o tamanho da página (US Letter, US Legal, A4), percorre as páginas renderizadas e exporta.

O visualizador exporta **HTML**, **HTML Flow**, **CSV**, **JSON**, **JSON Full Report** e **Texto simples**. A exportação em PDF existe no motor e na CLI `mad` do Windows, mas ainda não é oferecida no seletor de formato do visualizador desta compilação; para obter um PDF, chame o motor diretamente:

```powershell
.\Windows\Engine\build\mad.exe export .\CLI\Fixtures\London.portable.mad `
    --format pdf --out .\london.pdf
```

## Compilando a partir do código-fonte

O aplicativo é compilado com o SDK do .NET fixado em [`Windows/global.json`](https://github.com/mthomason/MAD/blob/master/Windows/global.json) (10.0.404):

```powershell
dotnet publish Windows\App\Mad.Designer.Windows\Mad.Designer.Windows.csproj `
    -c Release -r win-x64 --self-contained true
```

O motor é a metade mais difícil. `Windows\Engine\build.ps1` reproduz a compilação nativa (Clang 20.1.8, a toolchain MSVC fixada do Visual Studio, NASM, Strawberry Perl, Meson, Python e GNUstep compilado a partir de sete revisões fixadas em `C:\GNUstep`). Ele deve ser executado em um prompt do PowerShell elevado:

```powershell
pwsh -File .\Windows\Engine\build.ps1                 # bootstrap completo da toolchain e compilação
pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain  # recompilar quando a toolchain já existe
```

As duas suítes .NET são executadas contra o motor compilado:

```powershell
dotnet test Windows\App\Mad.Designer.Windows.slnx
```

`Windows/Engine/build.ps1` também executa as suítes nativas portadas, e `Windows/package.ps1` monta o arquivo de versão não assinado e o ativo do motor para CI depois que o motor e o aplicativo são compilados. A receita completa, as correções de runtime específicas do Windows, as obrigações de licença e a matriz de sistemas operacionais suportados estão em [`docs/project/MAD_WINDOWS.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_WINDOWS.md).

## Licença

MAD é licenciado sob a MIT (veja [`LICENSE`](https://github.com/mthomason/MAD/blob/master/LICENSE)); os nomes “MAD”, “MAD Designer” e “MAD Viewer” e as artes do app estão excluídos (veja [`NOTICE`](https://github.com/mthomason/MAD/blob/master/NOTICE)). O motor adiciona o runtime GNUstep (LGPL-2.1-or-later) e as bibliotecas C; cada componente, sua licença e a oferta escrita de relink estão na pasta `ThirdParty/Licenses/` do arquivo e em [`docs/project/THIRD_PARTY_LICENSES.md`](https://github.com/mthomason/MAD/blob/master/docs/project/THIRD_PARTY_LICENSES.md).
