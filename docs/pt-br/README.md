---
layout: default
lang: pt-BR
---

# O Formato de Documento `.mad`

Este documento define o que é um arquivo `.mad`. Ele descreve o formato **como existe
hoje**, a partir de dois documentos de exemplo distribuídos com o projeto e do código que os lê e escreve,
e em seguida estabelece o formato **como deve ser definido** para que um leitor em
outra plataforma — uma ferramenta de linha de comando, um build para Windows — possa abrir um documento
sem depender do Core Data ou de qualquer framework da Apple.

O formato é relevante porque um relatório é *pequeno* — os exemplos distribuídos têm
menos de 80 KB — e porque a engine que o executa cabe tanto em um celular quanto em um
contêiner: a mesma definição roda no iOS, no macOS e no build headless para Linux.
Para onde o formato está caminhando — a tabela de resultados de um relatório tornando-se uma fonte
de dados para outros relatórios, permitindo que um único documento abranja múltiplos bancos de dados — está descrito em
[`vision.md`](vision.md). A especificação também é publicada como site em
<https://docs.everydayapps.com>.

Tudo na primeira metade foi medido na prática, não inferido. Os dois exemplos são
`../../MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad` e
`…/London.dataset/London.mad`.

---

**O formato `.mad` é uma especificação aberta.** Qualquer pessoa pode lê-la e implementá-la.
A licença MIT cobre o código do projeto. Os nomes "MAD", "MAD Designer"
e "MAD Viewer", bem como os ícones dos aplicativos e demais artes visuais do produto, pertencem ao
autor e não estão licenciados; referências descritivas a arquivos `.mad` e a
este projeto são bem-vindas. Consulte [`../../LICENSE`](https://github.com/mthomason/MAD/blob/master/LICENSE), [`../../NOTICE`](https://github.com/mthomason/MAD/blob/master/NOTICE)
e [`../project/THIRD_PARTY_LICENSES.md`](https://github.com/mthomason/MAD/blob/master/docs/project/THIRD_PARTY_LICENSES.md).

A especificação está organizada com um capítulo por arquivo. Os capítulos 1–6 descrevem o formato como
ele é distribuído atualmente; o capítulo 7 é o alvo normativo (`v1`); os capítulos 8–9 trazem as questões
em aberto e como as afirmações são verificadas:

1. [O que é um documento, em uma frase](01-document.md)
2. [O contêiner](02-container.md)
3. [O armazenamento (store)](03-store.md)
4. [Leitura e escrita, conforme implementado](04-reading-writing.md)
5. [O que *não* está no documento: os arquivos complementares](05-companion-files.md)
6. [Riscos e armadilhas que um segundo leitor precisa tratar](06-hazards.md)
7. [O formato como deve ser definido](07-normative.md)
8. [Questões em aberto](08-open-questions.md)
9. [Verificação](09-verification.md)
