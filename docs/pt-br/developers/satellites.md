---
layout: default
title: "Repositórios satélite"
description: "Como o `mad-action` e a imagem de contêiner são publicados a partir deste repositório."
lang: pt-BR
---

# Repositórios satélite

Esta página explica como o GitHub Action `mad-action` e a imagem de contêiner são publicados a partir deste repositório, e a regra que mantém um satélite atualizado.

Um satélite é um repositório fora de `mthomason/MAD` que publica algo
construído a partir do MAD: hoje, o GitHub Action `mad-action`, juntamente com a imagem de contêiner
no GHCR. Satélites são **destinos de publicação, não forks**. O MAD é a
fonte da verdade; um satélite é gerado a partir de um diretório aqui, e as únicas
coisas que cruzam a fronteira são o artefato publicado e os arquivos em
`satellites/<name>/`.

Este é o mesmo modelo da imagem: `Linux/` é a fonte,
`.github/workflows/publish-image.yml` publica `ghcr.io/mthomason/mad` em
cada push para `master`, e nada copia o código-fonte da engine para nenhum outro lugar.
Um usuário da action recebe uma nova engine porque a tag da imagem mudou, não porque
o repositório satélite recebeu um commit.

## Registro

| Satélite | Fonte | Publicado por | Referências | Tag de versão |
|---|---|---|---|---|
| [mthomason/mad-action](https://github.com/mthomason/mad-action) | `satellites/mad-action/` | `.github/workflows/publish-mad-action.yml` | `ghcr.io/mthomason/mad:latest` | `v1` (móvel; `satellites/mad-action/VERSION`) |
| `ghcr.io/mthomason/mad` (imagem, não um repositório) | `Linux/` | `.github/workflows/publish-image.yml` | — | `latest`, `<short-sha>` |

`mthomason/mad-action` é gerado. Não o edite diretamente: uma alteração vai
para `satellites/mad-action/` aqui, pelo fluxo normal de PR, e o workflow de publicação
a leva adiante. Issues e pull requests para a action pertencem a
`mthomason/MAD`.

## O que precisa de um commit no satélite

| Alteração no MAD | Atualização do satélite |
|---|---|
| Código da engine ou do aplicativo | Nenhuma — o próximo push para master republica `:latest`, e a action executa essa versão |
| Documentação | Nenhuma — o README da action aponta para o MAD |
| Verbos da CLI, flags, entrada de credenciais ou formatos de exportação | `satellites/mad-action/action.yml`, `README.md` se o mapeamento de entradas ou a documentação mudarem |
| Nome da imagem ou política de tags | `satellites/mad-action/action.yml`, `README.md`, os workflows |
| `CLI/Fixtures/London.portable.mad` | Automático: o workflow de publicação o copia para `fixtures/` |
| `LICENSE` ou `NOTICE` | Automático: o workflow de publicação copia ambos |
| `satellites/mad-action/**` | Automático: o workflow de publicação sincroniza o diretório |

O workflow de publicação é executado em `master` quando um desses caminhos muda, e
manualmente com `workflow_dispatch`. Ele testa a fonte contra a imagem publicada,
sincroniza o destino, faz commit como `MAD release bot`, move a tag principal
e deixa o próprio workflow de teste do destino rodar no push. O workflow de teste do satélite
também é agendado diariamente — o canário que captura uma alteração na engine
que quebra o wrapper mesmo que o código-fonte do wrapper não tenha mudado.

O GitHub desativa workflows agendados após 60 dias sem atividade no repositório.
O próximo commit de sincronização os reativa; um `workflow_dispatch` manual executa o teste
imediatamente enquanto isso. Esta é a única parte do arranjo que pode
ficar silenciosa sem falhar.

## A lista de verificação de lançamento

**Uma alteração normal na fonte.**

1. Edite `satellites/mad-action/` e/ou o fixture aqui.
2. Execute o wrapper localmente se a interface mudou (`./Linux/build.sh
   --verify` compila `mad-cli:latest`; a action pode ser apontada para ele com
   `image: mad-cli:latest`).
3. Abra o PR. `Linux verification` executa o wrapper contra a própria
   imagem de runtime do PR (`linux.yml`), além do teste da action no
   destino.
4. Faça o merge. `Publish mad-action` testa e publica; a própria execução de teste do satélite,
   no repositório de destino, deve então passar.

**Uma alteração no contrato da CLI.** O mesmo PR atualiza as entradas do `action.yml` e o
README. A publicação move `v1`; os usuários existentes recebem o novo wrapper na
próxima execução. Se a alteração for incompatível — uma entrada renomeada ou removida, um padrão
alterado de forma incompatível — atualize `satellites/mad-action/VERSION` para `v2` no
mesmo PR e atualize as referências `@v1` do README. O workflow então move
`v2` e deixa `v1` onde está, para que os usuários de `mthomason/mad-action@v1` mantenham a
versão principal antiga até migrarem.

**Uma atualização de fixture.** Regenere o fixture no MAD
(`CLI/Fixtures/README.md`); o filtro de caminho o copia. Não edite a cópia no
repositório satélite.

**Rotação da chave de implantação.** Gere uma nova chave ed25519, adicione sua metade pública a
`mthomason/mad-action` como chave de implantação de escrita, defina a metade privada como o
segredo `MAD_ACTION_DEPLOY_KEY` em `mthomason/MAD`, dispare `Publish
mad-action`, depois exclua a chave de implantação antiga. A chave tem escopo no único
repositório de destino e só pode escrever.

## Configuração única, registrada

O repositório de destino foi criado vazio e público. O branch padrão do GitHub é
`main`, e a primeira publicação o preenche; o workflow faz push para `main`. Ele não foi
inicializado com um README ou licença, porque a primeira sincronização fornece
ambos. Issues e a wiki estão desativadas lá: o README encaminha ambos para o MAD. Se
ele for recriado algum dia, repita isto:

1. `gh repo create mthomason/mad-action --public`
2. Desative issues e a wiki.
3. Adicione uma chave de implantação de escrita intitulada `MAD publish workflow`.
4. Defina sua metade privada como o segredo `MAD_ACTION_DEPLOY_KEY` em
   `mthomason/MAD`.
5. Dispare `Publish mad-action`.

O satélite não tem dependências de terceiros próprias: seu corpo é
`docker run` da imagem publicada, e seus arquivos de licença são os do MAD
(`LICENSE`, `NOTICE`).

## Adicionar outro satélite

Crie `satellites/<name>/` aqui, adicione um workflow de publicação no formato de
`publish-mad-action.yml` e adicione a linha de registro acima. As regras são as
mesmas: o MAD é a fonte da verdade, o satélite consome um artefato publicado,
e um arquivo de versão (ou equivalente) nomeia a tag móvel que um usuário fixa. Não
espelhe o código-fonte da engine em um satélite; ele já viaja na imagem.
