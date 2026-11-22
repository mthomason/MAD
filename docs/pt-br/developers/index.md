---
layout: default
title: Desenvolvedores
description: "Incorpore a engine MAD, use a CLI mad, leia o contrato do objeto de dados e compile a engine headless."
lang: pt-BR
---

# Desenvolvedores

MAD é uma engine de relatórios relacionais embarcada: um documento `.mad` portátil,
uma engine Objective-C própria e uma ferramenta de linha de comando `mad` que executa a mesma
engine de forma headless no Linux e no Windows. Estas páginas são para quem quer
incorporá-la, controlá-la a partir de um script, adicionar uma fonte de dados ou compilá-la a partir do código-fonte.

## Comece aqui

* [A especificação do formato `.mad`](../README.html) — o que é um documento, o
  contêiner, o armazenamento e o alvo normativo `v1`.
* [MAD Designer para macOS](../macos.html) — o aplicativo nativo em `AppKit`.
* [MAD Designer para Windows](../windows.html) — o aplicativo nativo em WPF.
* [Visão](../vision.html) — relatórios como fontes de dados compostíveis.

## Engine e CLI

* [A ferramenta de linha de comando `mad`](cli.html) — abrir, inspecionar, consultar, atualizar e
  exportar um documento sem uma interface gráfica.
* [O objeto de dados](data-object.html) — a definição, o esquema e o
  conjunto de resultados de um relatório como um único contrato.
* [Relatórios multifonte](multi-source.html) — relatórios como tabelas e drivers
  para qualquer coisa que retorne uma tabela.
* [Colar SQL no designer de consultas](sql-entry.html) — o subconjunto suportado,
  o analisador e o caminho de aplicação.

## Arquitetura

* [A arquitetura do MADDataTable](architecture/data-table.html) — o
  cluster de classes da tabela de dados entre os frameworks.
* [A camada MADModel](architecture/model-layer.html) — o modelo de leitura do documento
  sobre as entidades `Rptq`.
* [MADArrayCaching](architecture/array-caching.html) — o array em disco
  do cache de renderização.

## Compilação e testes

* [Compilar a engine no Linux](build/linux.html) — a compilação com Docker e os
  doze frameworks headless.
* [Compilar a engine no Windows](build/windows.html) — a cadeia de ferramentas fixada do Clang e do
  GNUstep.
* [Portabilidade e o aplicativo nativo para macOS](build/macos.html) — a auditoria dos
  frameworks e a arquitetura AppKit.
* [A compilação de bibliotecas estáticas do Compressor](build/libraries.html) — as bibliotecas C
  de terceiros e como o Xcode as alcança.
* [O escritor de PDF headless](build/pdf.html) — Cairo, FreeType e
  exportação determinística.

## Satélites e código-fonte

* [Repositórios satélite](satellites.html) — como o `mad-action` e a
  imagem de contêiner são publicados a partir deste repositório.
* [Código-fonte](https://github.com/mthomason/MAD) — o repositório, as issues e o
  [guia de contribuição](https://github.com/mthomason/MAD/blob/master/CONTRIBUTING.md).
