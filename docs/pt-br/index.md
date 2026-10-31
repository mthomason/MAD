---
layout: default
title: MAD — Documento Analítico Móvel (Mobile Analytics Document)
description: >-
  Um formato aberto e uma engine embarcável para relatórios relacionais — MAD Designer e MAD Viewer para macOS nativo (AppKit) e iOS, a CLI headless mad para Linux e macOS, e a especificação aberta .mad.
image: /assets/mad-icons-banner.png
lang: pt-BR
---

<p><a href="https://raw.githubusercontent.com/mthomason/MAD/master/StaticResources/Images/icons/document/Designer%20Icon@3x.png"><img src="../assets/mad-designer-macos-icon-256.png" alt="Ícone do MAD Designer" width="64" height="64" align="left" style="margin-right: 16px; margin-bottom: 8px;" /></a><strong>Um formato aberto e uma engine embarcável para relatórios relacionais — onde cada relatório é um grafo de consulta portável, uma tabela SQLite materializada e um layout paramétrico.</strong></p>

O MAD é uma plataforma embarcada de relatórios relacionais para consultas ad hoc, geração de relatórios e design: os aplicativos **MAD Designer** e **MAD Viewer** para iOS e macOS nativo (`AppKit`), a engine headless que os executa em Linux e macOS, e o formato aberto de documento `.mad`. Um arquivo `.mad` armazena toda a definição de um relatório — o snapshot do esquema do banco de dados, o grafo de consulta (tabelas, joins, predicados, agrupamentos) e o layout em bandas de seus elementos — em menos de 100 KB, claramente separado da tabela SQLite materializada (`.maddb` + `.mdcache`) que ele produz ao atualizar os dados.

O código está em
[github.com/mthomason/MAD](https://github.com/mthomason/MAD), sob licença MIT;
os nomes e a arte visual dos aplicativos não são cobertos por essa licença (consulte o
[NOTICE](https://github.com/mthomason/MAD/blob/master/NOTICE)).

## Veja em ação

**[MAD Designer para macOS](macos.html)** — aplicativo desktop nativo em `AppKit` (`NSDocument`, canvas visual de tabelas/joins para consultas, minimapa interativo de seções e designer de relatórios em bandas, além de visualizador paginado de relatórios em PDF/HTML/CSV/JSON):

![Workspace MAD Query no aplicativo nativo para macOS](../assets/macos-native-mad-query.png)

![Workspace MAD Designer no aplicativo nativo para macOS](../assets/macos-native-mad-designer.png)

**MAD Designer para iOS**, da escolha de uma fonte de dados até a leitura do relatório finalizado no
MAD Viewer:

<video controls playsinline preload="metadata" width="360"
  poster="../assets/app-preview-poster.png">
  <source src="../assets/app-preview.mp4" type="video/mp4">
  Seu navegador não suporta o elemento de vídeo; a
  <a href="../assets/app-preview.mp4">prévia do aplicativo</a> é um arquivo MP4 comum.
</video>

**A mesma engine rodando em modo headless no Linux**: `inspect`, `schema`, `query`, `refresh` e
`export` através da CLI `mad`, sem servidor de banco de dados e sem credenciais:

![A CLI mad inspecionando, consultando, atualizando e exportando um documento .mad](../assets/mad-cli-demo.gif)

O [relatório exportado](../assets/london.html) da gravação é HTML puro, podendo ser aberto em
qualquer navegador.

## Por que o MAD

* **Interoperável por contrato.** Em vez de espalhar scripts SQL avulsos e
  código de integração de dashboards sob medida pela organização, um arquivo `.mad` empacota o
  contrato do esquema, a AST da consulta e o layout de apresentação em um único
  artefato inspecionável e comparável via diff, que gera SQL e exportações idênticos byte a byte
  entre plataformas Apple e Linux.
* **Desenvolvido do zero, não remendado.** A geração de SQL, o parser de SQL, a
  engine de tabelas de dados, o armazenamento (store), o modelo de layout e o renderizador são
  implementações próprias em Objective-C distribuídas em quatorze frameworks. O código de terceiros
  limita-se estritamente ao protocolo de comunicação — MariaDB Connector/C, FreeTDS, `libpq`, SQLite — além de
  `libarchive`/`bzip2` e `zint` para códigos de barras. Nenhum SDK proprietário de relatórios está sendo
  revendido.
* **Mobile-first e com orçamento de memória controlado.** Uma atualização (`refresh`) lê o conjunto de resultados uma única vez
  para um cache de linhas em SQLite (`MADDataTableFast`) e calcula agrupamentos e agregações em duas passagens
  a partir dali, mantendo a renderização paginada rápida mesmo dentro da memória de um
  celular.
* **Embarcável e portável.** Onze dos quatorze frameworks não dependem de
  UIKit e compilam em modo headless, passando em 1.303 testes no Linux em Docker.
  O contêiner `.mad` é um arquivo tar comprimido com bzip2 contendo um store SQLite portável;
  nenhum framework da Apple é necessário para abri-lo.

## O formato `.mad`

A especificação aberta, um capítulo por arquivo:

[O que é um documento](01-document.html) ·
[O contêiner](02-container.html) ·
[O armazenamento (store)](03-store.html) ·
[Leitura e escrita](04-reading-writing.html) ·
[Arquivos complementares](05-companion-files.html) ·
[Riscos e armadilhas](06-hazards.html) ·
[`v1` normativa](07-normative.html) ·
[Questões em aberto](08-open-questions.html) ·
[Verificação](09-verification.html)

## Usando a engine

* [MAD Designer para macOS](macos.html) — o aplicativo desktop nativo em `AppKit`:
  canvas visual de consultas, designer de relatórios em bandas com minimapa e inspetor,
  visualizador paginado e instruções de como compilar ou empacotar a partir do código-fonte.
* [Compilação e testes](https://github.com/mthomason/MAD#build-and-test) —
  os comandos exatos para as suítes do iOS, as suítes nativas do macOS e o build do Linux.
* [A CLI `mad`](https://github.com/mthomason/MAD#try-it) — inspecione,
  atualize e exporte um `.mad` via Docker em uma única linha de comando.
* [mad-action](https://github.com/mthomason/mad-action) — execute um arquivo
  `.mad` versionado no GitHub Actions e envie a exportação como artefato; `mthomason/mad-action@v1`.
* [Tutorial de criação de drivers](tutorials/driver-authoring.html) — a
  primeira contribuição recomendada: crie uma subclasse de `MADDatabase`, registre o
  driver e retorne linhas.

## A direção

[Visão](vision.html) — relatórios como tabelas de banco de dados componíveis, consultas
multifonte em um único relatório, views nativas em UIKit além do paradigma do papel
e conversão de arquivos legados do Crystal Reports (`.rpt`) para arquivos `.mad` abertos.

---

O aplicativo **MAD Designer** — o designer de relatórios construído sobre esta engine — possui
seu próprio site em [mad.everydayapps.com](https://mad.everydayapps.com/).
