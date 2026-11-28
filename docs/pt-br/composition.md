---
layout: default
title: "Relatórios de Composição"
description: >-
  Combine relatórios de vários bancos de dados em um único documento .mad portátil: cada fonte mantém sua consulta, seu layout e seus dados, e o Resultado os une em um novo relatório.
lang: pt-BR
---

# Relatórios de Composição

Um **Relatório de Composição** combina outros relatórios em um único documento `.mad`. Cada
relatório que você traz é uma **Fonte**; o relatório padrão do documento é o **Resultado**, que
une as tabelas de resultados das fontes em um novo relatório próprio.

A composição é o modo pelo qual um único documento portátil abrange vários bancos de dados — MySQL,
PostgreSQL, SQL Server e SQLite — sem um servidor de federação no meio do caminho. As
fontes são trazidas para o documento **com seus layouts**; combiná-las não reduz uma fonte
a uma tabela. Cada membro de uma composição é um relatório completo.

> **Plataformas:** os Relatórios de Composição estão disponíveis no **MAD Designer para macOS** (0.8)
> e no **MAD Designer para Windows** (0.8). O aplicativo para iOS ainda não cria composições;
> esta página descreve os aplicativos de desktop.


## O modelo mental

> Um relatório de composição combina outros relatórios em um. Você traz relatórios existentes
> (**fontes**), une suas tabelas de resultados para construir um novo relatório **Resultado**, escolhe quais
> **colunas** do resultado mostrar e então projeta e visualiza esse Resultado exatamente como um relatório
> comum. Selecionar uma fonte devolve a você a consulta, o layout e as linhas dessa fonte.

Quatro verbos resumem o fluxo de trabalho: **adicionar fontes → uni-las → escolher as colunas → selecionar**.

| Termo | O que significa |
|---|---|
| **Relatório de Composição** | Um documento `.mad` que contém um grafo de relatórios: o Resultado mais suas fontes. |
| **Resultado** | O relatório padrão do documento. Ele une as tabelas materializadas das fontes e é o que abre primeiro, imprime por padrão e exporta por padrão. |
| **Fonte** | Um relatório filho trazido para a composição. Ele mantém sua própria consulta, conexão de banco de dados, layout e linhas. |
| **Colunas do relatório** | Os campos que o Resultado expõe ao seu próprio layout e aos seus pais. Editados no workspace MAD Query (o item **Outputs…** no macOS, **Columns** no Windows). |
| **Fonte sem layout** | Uma fonte cujo relatório ainda não tem elementos. O Designer oferece criar um layout; o Viewer mostra suas linhas como uma tabela. |

### Todo membro é um relatório

Esta é a regra que torna o recurso legível. Uma fonte não é reduzida a uma tabela
quando é importada: sua definição de consulta, seu próprio layout de relatório e seus dados vêm
junto, e são salvos no mesmo documento `.mad`. As linhas permanecem no armazenamento complementar
(os arquivos `.maddb` e `.mdcache` ao lado do documento), não dentro do `.mad`.

Selecionar uma fonte no seletor **Navegação** (macOS) ou no seletor **Component** e no
painel Composition (Windows) alterna **todos os três workspaces** — MAD Query, MAD Designer e
MAD Viewer — para essa fonte. Uma fonte sem layout ainda é um relatório válido: o Viewer mostra
suas linhas em cache em uma grade em vez de uma página.



## Criando uma composição

### macOS

* **Arquivo ▸ Novo Documento…** oferece **Standard Report** e **Composition Report**.
  Escolher Composition Report pede que você selecione um ou mais relatórios `.mad` existentes e depois
  onde salvar a nova composição.
* **Arquivo ▸ Nova Composição…** é o comando direto para o mesmo fluxo.
* **Arquivo ▸ Converter em Composição…** transforma o relatório padrão aberto em uma composição
  de uma única fonte, mantendo seu layout.
* No workspace **MAD Query**, o menu Add adiciona uma tabela, uma **consulta de origem** a partir de
  uma nova conexão de banco de dados, um **relatório importado** ou a **consulta raiz** composta.

O seletor **Navegação** da barra de ferramentas lista o **Resultado** primeiro (marcado como *Resultado — <nome>*)
e depois cada fonte. Selecionar um item nunca muda o workspace ativo; ele muda
qual relatório aquele workspace está exibindo.

### Windows

* **Arquivo ▸ Nova Composição…** cria uma composição a partir de relatórios existentes.
* **Arquivo ▸ Importar…** adiciona um relatório como fonte da composição aberta.
* **Arquivo ▸ Converter em Composição** transforma o relatório padrão aberto em uma composição.

Um painel **Composition** acoplado fica ao lado do workspace (ausente em um relatório padrão).
Seu grafo mostra o Resultado na profundidade 0 e suas fontes abaixo, com conectores apontando para
o consumidor. O painel e o seletor **Component** da barra de ferramentas compartilham uma seleção; o
painel pode ser recolhido, e o seletor permanece.

## Unindo fontes e escolhendo colunas

No canvas do Resultado, arraste um campo de um cartão de fonte até um campo em outro para criar
uma junção, depois clique no selo da junção para alterar seu tipo (`INNER`, `LEFT OUTER`,
`RIGHT OUTER`, `FULL OUTER`, `CROSS`) ou inverter sua direção. O Resultado é uma consulta
normal: ele pode unir qualquer número de fontes, filtrar, agrupar e ordenar.

Uma fonte que é ela própria uma composição entra no grafo com suas próprias fontes; o pai
referencia o Resultado dessa composição. Um nó compositor referencia apenas seus filhos —
nunca uma tabela remota — de modo que cada folha executa contra seu próprio banco de dados e cada etapa de junção
executa localmente no SQLite.

Use o editor **Colunas do relatório** do Resultado para escolher, nomear e ordenar os campos que o
Resultado expõe. A lista de campos do Designer do Resultado é exatamente esse conjunto. Uma fonte expõe
seus próprios campos de consulta.

## Atualização, credenciais e privacidade

A atualização executa o grafo **filhos primeiro, o Resultado por último**. Cada folha executa contra
seu próprio banco de dados com suas próprias credenciais; cada relatório compositor executa localmente sobre as
tabelas materializadas de seus filhos. Cada nó materializa sua própria tabela, e um nó que falha
faz a atualização falhar, deixando os resultados completos anteriores legíveis.

Uma composição multifonte, portanto, pede **uma credencial por fonte**, uma planilha de cada
vez, com o driver, o host, a porta, o banco de dados e o nome de usuário não secreto já preenchidos.
As senhas nunca são gravadas no arquivo `.mad`: o macOS as mantém no Keychain (ou na
sessão atual), e o Windows as mantém na sessão ou no armazenamento de credenciais da plataforma.
Uma fonte SQLite não precisa de credencial.

## Exemplos

Duas composições executáveis estão em [`Samples/Reports`](https://github.com/mthomason/MAD/tree/master/Samples/Reports):

* **`Chinook-Composition.mad`** — duas fontes SQLite (um relatório Albums com seu próprio
  layout e um relatório Artists sem nenhum) unidas em um Resultado. Ele não precisa de nada além
  do `chinook.sqlite3` incluído.
* **`Composition-MySQL-PostgreSQL-SQLServer.mad`** — uma pequena tabela de MySQL,
  PostgreSQL e SQL Server unidas por `demo_id`, demonstrando um único documento que
  abrange três bancos de dados.

Levante os três servidores ativos e popule a tabela entre bancos de dados com um único script
idempotente (macOS, Linux e Git Bash no Windows):

```sh
./Samples/setup-databases.sh up
```

No Windows PowerShell:

```powershell
.\Samples\setup-databases.ps1 -Action up
```

`up` cria ou inicia os contêineres fixados por meio dos scripts de banco de dados de teste e carrega
a tabela `composition_demo` em cada servidor. `status` informa os contêineres e as contagens de linhas;
`down` os para. O mesmo SQL pode ser impresso sem Docker com
`./Samples/setup-databases.sh sql`. Consulte [o guia de exemplos](https://github.com/mthomason/MAD/blob/master/Samples/README.md)
para o passo a passo da primeira execução, incluindo os prompts de senha por fonte.

## Limites atuais

* **Somente o mesmo documento.** A definição e o layout de cada fonte vivem dentro do único
  arquivo `.mad`. Referenciar um relatório em um arquivo diferente não é suportado.
* **Até dez filhos diretos por relatório compositor.** A compilação SQLite da engine permite
  dez bancos de dados anexados; o Designer rejeita um décimo primeiro filho.
* **Composições aninhadas são somente leitura no workspace MAD Query.** Uma fonte que é ela própria
  uma composição mostra as fontes que ela une, mas criar um compositor aninhado diretamente é
  um trabalho posterior.
* **`json-report` exporta apenas o Resultado.** Todos os outros formatos de exportação exportam o
  relatório selecionado.

## Relacionados

* [MAD Designer para macOS](../macos.html) — o aplicativo nativo em AppKit.
* [MAD Designer para Windows](../windows.html) — o aplicativo nativo em WPF.
* [A direção](../vision.html) — relatórios como fontes de dados componíveis.
* [O objeto de dados](developers/data-object.html) — a definição, o esquema e o conjunto de
  resultados de um relatório como um único contrato.
* [Relatórios multifonte](developers/multi-source.html) — a arquitetura por trás da
  composição no mesmo documento.
