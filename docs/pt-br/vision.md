---
layout: default
title: "A direção"
description: "A direção do MAD: de relatórios a objetos de dados componíveis, uma engine embarcável e documentos escritos por IA."
lang: pt-BR
---

# A Direção: De Relatórios a Dados Componíveis

Atualizado em 2026-11-22. Esta página declara a direção para a qual o MAD foi
projetado para crescer. Ela separa o que já é entregue hoje do que é proposto, e
aponta para os registros públicos de design em vez das notas internas de
trabalho: o [design do objeto de dados](developers/data-object.html), os
[relatórios multifonte](developers/multi-source.html) e a
[especificação do formato](README.html).

## O que existe hoje

Um documento `.mad` é a **definição** de um relatório: o snapshot do esquema, o
grafo de consulta (tabelas, joins, predicados, agrupamentos) e a árvore de
layout em bandas. Ao atualizar, a engine compila o grafo em SQL, lê as linhas
uma única vez e as materializa em um cache SQLite complementar (`.maddb` +
`.mdcache`). Os dados de linhas permanecem fora do documento de propósito; a
definição se mantém abaixo de 100 KB.

A engine já tem as peças de que uma direção mais ampla precisa:

* Um formato de documento aberto e portável: um arquivo tar comprimido com
  bzip2 contendo um store SQLite portável, sem exigir nenhum framework da
  Apple para abri-lo.
* Um construtor de consultas que compila definições estruturadas em SQL, além
  de um parser de SQL para instruções digitadas diretamente.
* Quatro drivers SQL — MySQL, SQL Server, PostgreSQL e SQLite — cada um
  retornando um esquema e linhas como uma tabela.
* Materialização local em SQLite (`MADDataTableFast`) que torna agrupamentos,
  agregações e renderização repetida viáveis em um celular.
* Aplicativos nativos para iOS e macOS, um aplicativo nativo para Windows e a
  mesma engine rodando de forma headless no Linux e no Windows por meio do
  `mad serve` e da CLI `mad`.

Uma consequência é fácil de passar despercebida: **um relatório é uma função de
fontes de dados para uma tabela.** Todo driver retorna um esquema e linhas em
formato tabular, e a saída de um relatório *é* um esquema e linhas em formato
tabular. A engine já trata os dois de forma idêntica.

## Para onde está indo

As direções abaixo são propostas. Elas se baseiam na arquitetura acima, mas
nenhuma delas é entregue hoje, a menos que esta página diga que sim.

### Objetos de dados componíveis

Em um banco de dados, você seleciona de tabelas base como `employee` ou
`sales_data`. Um relatório conecta várias tabelas entre si, e sua saída é uma
tabela SQLite ad hoc e materializada. Hoje nada consegue apontar uma consulta
para a saída de outro relatório: o cache de resultados existe, mas é indexado
por um hash de nome de arquivo em vez de uma identidade endereçável.

Dar a essa saída uma identidade estável tornaria o resultado de um relatório
uma tabela da qual outros relatórios podem selecionar e com a qual podem fazer
join. Um relatório construído sobre um relatório torna-se um grafo acíclico
direcionado de tabelas derivadas — uma camada semântica portável na qual
projetar um relatório também é projetar uma fonte de dados reutilizável. O
[design do objeto de dados](developers/data-object.html) descreve o modelo e o
que é preciso para formalizá-lo.

### Materialização local multifonte

Cada driver materializa seu conjunto de resultados na mesma representação local
de tabela SQLite. Quando um documento puder conter várias definições de
consulta e endereçar cada saída como uma tabela, um único relatório poderá
fazer join de uma tabela do PostgreSQL com uma tabela do SQL Server e com uma
tabela do MySQL — combinadas localmente no SQLite sem um servidor de federação
no meio do caminho. Cada fonte entende seus próprios dados; o MAD entende as
tabelas resultantes. O [design multifonte](developers/multi-source.html) registra
a arquitetura e as fases, nem todas construídas.

### Uso embarcado e headless

O MAD não precisa se limitar a aplicativos chamados MAD. A mesma engine poderia
ser embarcada nos produtos de outros desenvolvedores: um sistema de inventário,
um aplicativo financeiro, uma ferramenta de manufatura ou um sistema de gestão
específico de um setor que precise de consultas, relatórios, exportações e
resumos operacionais sem construir um subsistema de relatórios do zero.

O aplicativo hospedeiro fornece acesso aos dados, integração e sua própria
experiência de usuário. O MAD fornece capacidades reutilizáveis de consulta,
materialização, relatório e exportação. A costura do driver é deliberadamente
ampla — uma fonte precisa fornecer um esquema e linhas, não necessariamente um
banco de dados SQL convencional —, de modo que o mesmo contrato possa acomodar
bancos de dados relacionais, dados locais de aplicativos, arquivos estruturados
e dispositivos. Algumas dessas fontes já têm drivers hoje; outras precisariam
de um.

Essa direção também vai além do software de desktop: um appliance ou sistema
industrial com recursos suficientes poderia usar a engine localmente para
transformar medições e registros de manutenção em relatórios de diagnóstico,
sem conectividade contínua. Não é uma afirmação de que a engine completa caiba
em um microcontrolador minúsculo ou em um laço de controle de tempo real
rígido.

### Apresentação além do papel

A paginação em bandas — Cabeçalho do Relatório, Cabeçalho da Página, Agrupamentos, Detalhe, Rodapés —
foi inventada para impressão em papel. O layout de um `.mad` é composto por
dados paramétricos, e o cache de linhas é um SQLite local, de modo que as
páginas em papel são uma apresentação dos dados, e não sua definição.

Manter a definição e sua tabela materializada separadas tornam possíveis outras
apresentações sobre o mesmo objeto de dados: tabelas interativas e exploradores
de dados, views nativas de aplicativo, gráficos e dashboards, views embarcadas
em aplicativos e visualizadores baseados em navegador. Relatórios paginados
tradicionais continuam importantes; o objetivo é torná-los uma apresentação útil
entre várias, não abandoná-los.

### Documentos escritos por IA

A estrutura declarativa do MAD o torna adequado a um modelo diferente de
relatório assistido por IA. Em vez de gerar uma imagem de um gráfico, um modelo
poderia propor um documento MAD real: descobrir as fontes e os metadados de
esquema disponíveis, escolher as tabelas e os campos relevantes, construir os
grafos de consulta e relacionamentos, propor um layout e submeter o resultado à
engine para validação e execução.

A divisão de responsabilidades importa. O modelo interpreta a intenção e propõe
uma definição estruturada; o MAD a valida e executa. O modelo deve produzir
grafos de consulta e definições de layout, e não SQL arbitrário não verificado,
e a engine deve permanecer responsável pela geração de SQL, pelo acesso aos
dados e pela materialização.

O resultado seria um documento `.mad` normal e editável, e não uma resposta
pontual. O grafo de consulta poderia ser inspecionado, os joins e filtros
editados, a apresentação personalizada, os resultados atualizados sem o modelo
e o documento reutilizado em outros lugares. Isso mantém o usuário no controle
do artefato e evita que a operação dependa da IA que o escreveu. Autorização,
validação e controles de proteção de dados fariam parte de tornar isso real; a
validação estrutural por si só não prova que uma análise está semanticamente
correta.

### Servidor opcional e implantação web

Aplicativos nativos, componentes embarcados e execução headless devem permanecer
de primeira classe. Um serviço futuro poderia acrescentar agendamento, catálogos
de documentos, controles de acesso, gerenciamento de snapshots, relatórios
compartilhados e APIs, e um designer baseado em navegador poderia operar no
mesmo modelo de documento que os clientes nativos.

A engine e o formato do documento continuam sendo a fundação comum. Um cliente
que precise de execução local, infraestrutura privada ou operação offline não
deveria ter de adotar uma implantação em nuvem para se beneficiar da engine, e
uma futura implementação web não deveria bifurcar a semântica de consulta.

### Conversão de relatórios legados

Um futuro importador poderia trazer definições de formatos de relatório legados
para arquivos `.mad` abertos. Esse é um caminho de compatibilidade para
organizações com bibliotecas de relatórios de longa vida, não o centro da
direção e nem um substituto para as direções acima.

## Três maneiras de usar o MAD

Estas não são produtos separados nem bases de código separadas. São usos
diferentes da mesma arquitetura, conectados pelo modelo de objeto de dados.

### O MAD como aplicativo

Uma experiência completa de consulta, design e relatórios para pessoas que
trabalham diretamente com seus dados, com aplicativos nativos, portabilidade de
documentos e relatórios práticos.

### O MAD como engine embarcada

Um componente reutilizável de acesso a dados, consulta, materialização e
relatórios para desenvolvedores que incorporam o MAD em seu próprio software ou
dispositivos, com ênfase na arquitetura de drivers, execução headless,
definições reutilizáveis e processamento local.

### O MAD como plataforma de dados escrita por IA

Um sistema em que as pessoas descrevem as informações de que precisam e um
modelo constrói objetos de dados e documentos MAD validados, com geração
estruturada, validação por máquina e artefatos editáveis que permanecem úteis
independentemente da IA. Esta é uma proposta; a criação por IA ainda não está disponível.

## Por que isso importa

O problema é prático. Muitas organizações operam sistemas substanciais e de
longa vida construídos em torno de bancos de dados relacionais e aplicativos de
negócios especializados. Elas querem acesso confiável aos seus próprios dados,
relatórios que possam manter sem desenvolvimento personalizado repetido,
ferramentas nativas com boas experiências de usuário, controle sobre credenciais
e onde os dados são processados, uso continuado da infraestrutura de banco de
dados existente e portabilidade entre plataformas e ambientes.

A parte difícil costuma ser colocar os dados em uma forma confiável e
utilizável. Apresentá-los é o passo final. O MAD investe na aquisição de dados,
modelagem relacional, materialização e execução, e a interface fica por cima
desse trabalho em vez de escondê-lo.

O valor é positivo: portabilidade, controle local, componibilidade,
processamento confiável, extensibilidade e uma experiência acessível. Uma
empresa deveria conseguir obter respostas úteis de seus dados sem aceitar
dependências de plataforma desnecessárias.

## O que isto não é

Uma promessa, um roadmap com datas ou uma afirmação de que as propostas acima
são entregues. Esta página registra uma direção. Cada capacidade ainda precisa
ser projetada, testada e documentada como todo o restante do repositório, e
algumas dessas direções podem mudar à medida que forem construídas.

## O princípio norteador

> **O documento define o trabalho. A engine o executa. A apresentação torna o
> resultado útil.**
