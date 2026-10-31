[English](CONTRIBUTING.md) | [简体中文](CONTRIBUTING_zh.md) | [日本語](CONTRIBUTING_ja.md) | **Português (Brasil)**

# Contribuindo para o MAD

Obrigado por estar aqui. O MAD (Mobile Analytics Document) é o projeto — os
aplicativos MAD Designer e MAD Viewer, os frameworks e a engine headless —
e os pontos de extensão (seams) para novos trabalhos são o foco principal: um novo driver de banco de dados, um novo
elemento de documento, um novo formato de exportação. O tutorial de criação de drivers
([`docs/tutorials/driver-authoring.md`](docs/pt-br/tutorials/driver-authoring.md))
guia você passo a passo pelo primeiro; essa é a primeira contribuição recomendada.

## Pré-requisitos

* **macOS com Xcode** — o lado iOS/macOS consiste em um workspace com quatorze frameworks
  mais o aplicativo, compilado para iOS 15+ e macOS 12.0+. Os frameworks são escritos em Objective-C.
* **Docker** — o build Linux da engine headless: uma imagem que compila a partir do código-fonte
  o toolchain Objective-C (libobjc2, libdispatch, GNUstep) e as bibliotecas
  C, compila os onze frameworks headless e executa suas suítes de teste.
* Nenhum servidor de banco de dados é obrigatório para contribuir: as suítes de testes live de MySQL, SQL Server e
  PostgreSQL são puladas automaticamente quando nenhum servidor está acessível, e
  [`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md) documenta os
  contêineres Docker que fornecem esses bancos de teste.

## Primeiros passos

1. Faça um fork do repositório e clone o seu fork.
2. Compile e execute os testes antes de alterar qualquer coisa, para conhecer a linha de base:

   ```sh
   # iOS: any framework's suite, against the iOS Simulator
   xcodebuild test -workspace Reports.xcworkspace -scheme MADFoundation \
       -destination 'platform=iOS Simulator,id=<device-udid>' \
       -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-shared
   ```

   ```sh
   # Linux: the whole headless engine — 126 test executables, 1,303 tests
   ./Linux/build.sh
   ```

   [`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md) traz a matriz completa
   de comandos, o caminho compartilhado de DerivedData esperado pelos
   frameworks e a configuração dos bancos de dados de teste.
3. Escolha uma tarefa: um novo driver, um elemento de relatório ou uma issue marcada com
   "good first issue". Mudanças pequenas são bem-vindas: a cultura de revisão aqui preza pela precisão.

## A regra do test-first

**Escreva primeiro o teste que falha.** Essa é a cultura do projeto, não apenas uma
sugestão: o teste fixa o comportamento esperado antes mesmo de o código existir, e a correção é
a mudança que faz o teste ficar verde. Para trabalhos envolvendo formato de arquivo ou dados, faça um snapshot da
fixture anterior à mudança em vez de gerar o valor esperado com o código novo —
a fixture é a prova de que o comportamento era real.

O ciclo, em ordem:

1. Adicione um teste que falha expressando o comportamento que você pretende implementar.
2. Execute-o e confirme que ele falha pelo motivo correto.
3. Implemente a mudança e faça o teste passar (ficar verde).
4. Execute toda a suíte — iOS *e* `./Linux/build.sh` caso tenha alterado qualquer arquivo
   compilado pelo build do Linux (consulte `Linux/cmake/*Sources.cmake`). Cada commit
   deve manter todas as suítes verdes.

As suítes do Linux registram divergências conhecidas de plataforma como linhas `NEED` em vez de
ignorá-las silenciosamente — um novo `NEED` precisa trazer uma justificativa, e uma divergência
que não seja corrigida nem registrada é tratada como falha.

## Estilo de código

* Tabs, não espaços. Comentários onde realmente agregam valor, não em toda parte.
* Código deliberadamente não utilizado deve ser marcado com o atributo `unused` do clang na
  própria declaração — um aviso de código não utilizado sem marcação significa código morto que deve ser removido.
* Novos arquivos devem conter o cabeçalho de uma linha: `Copyright © 2012-2026 Michael
  Thomason. SPDX-License-Identifier: MIT` (`//` para código-fonte, `#` para scripts).
* [`docs/project/BUGS.md`](docs/project/BUGS.md) registra defeitos em aberto junto com
  os testes que os reproduzem; quando você corrige um defeito, a entrada correspondente é movida para
  [`docs/project/BUGS_FIXED.md`](docs/project/BUGS_FIXED.md) — uma correção não
  registrada é considerada incompleta.

## Developer Certificate of Origin (DCO)

Este projeto exige assinatura DCO (sign-off) em vez de um CLA. Todo commit deve terminar
com:

    Signed-off-by: Name <email>

(`git commit -s` adiciona essa linha automaticamente.) Ao incluí-la, você certifica, nos termos de
[developercertificate.org](https://developercertificate.org), que escreveu
a alteração ou que tem o direito de submetê-la sob a licença do projeto
(MIT, consulte `LICENSE`). A verificação do DCO é executada automaticamente nos pull requests no GitHub.

## Pull requests

* Um assunto por PR. Mantenha os commits fáceis de revisar; o histórico do projeto é um
  registro técnico, não um rascunho.
* Preencha o template de PR — o checklist de test-first existe para auxiliar o
  revisor, e respostas "não aplicável" são perfeitamente aceitas quando verdadeiras.
* Um PR que altere código compilado no build do Linux deve passar com `./Linux/build.sh` verde em sua
  própria branch.

## Issues

Os templates de relato de bug e de proposta de driver estão em
[`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/). Questões de segurança devem seguir o
canal privado descrito em [`SECURITY.md`](SECURITY_pt-BR.md), nunca uma issue pública.

## Ajuda

Pergunte em uma issue (ou no painel Discussions quando estiver aberto). O mantenedor
responde a todas as issues; o projeto nasceu do esforço de uma pessoa e está crescendo para uma comunidade,
então uma pergunta clara demonstrando o que você já tentou receberá a resposta mais rápida.

## Apoio

O código do MAD é licenciado sob MIT e gratuito, e contribuições de código são a melhor forma de
apoio. Se o projeto economiza tempo da sua equipe e você quiser apoiar ainda mais, o
mantenedor aceita [GitHub Sponsors](https://github.com/sponsors/mthomason) e créditos de API
para o desenvolvimento assistido por agentes — tudo retorna diretamente para o avanço do
projeto (consulte a seção "Apoie o projeto" no [README](README_pt-BR.md)).
