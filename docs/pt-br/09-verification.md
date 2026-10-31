---
layout: default
lang: pt-BR
---

## 9. Verificação

As afirmações das §§2–5 são reproduzíveis (execute os comandos abaixo a partir da raiz do repositório):

```sh
tar tjf MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad
mkdir -p /tmp/mad && tar xjf … -C /tmp/mad
plutil -p /tmp/mad/meta.plist
file /tmp/mad/StoreContent/analyitics
```

As afirmações da §5 são reproduzíveis a partir do contêiner de um dispositivo ou simulador:

```sh
ls -la ~/Library/Developer/CoreSimulator/Devices/<UDID>/data/Library/Caches/<dataTableIdHash>/
```

Qualquer alteração no formato deve estender as fixtures de round-trip descritas em
`docs/project/MAD_CLI.md` §6, para que a definição neste arquivo seja garantida por um teste automatizado e não
apenas por este texto. A fixture do contêiner existe desde 2026-10-16
(`../Linux/Tests/MADArchiveManagerTests.m`: descompactar, recompactar, descompactar novamente, verificando que a lista de membros e
os bytes permanecem inalterados), e o bit de checkpoint da §7.2 é testado pelo próprio gravador que o define (`mad
write`). O *modo reproduzível* do gravador — timestamp fixo dos membros, uid/gid 0 e percorrimento
ordenado — é o que torna idênticos os documentos gerados em duas plataformas distintas; ele é opt-in, de modo que um
arquivo comum continua registrando os metadados reais do sistema de arquivos, e não altera a versão do formato (o
arquivo continua sendo v1 em ambos os casos). A §5 é a parte que ainda não possui uma fixture desse tipo hoje — os arquivos complementares são
descritos aqui com base em medições reais, e nenhum teste falha automaticamente caso essas medições deixem de ser
verdadeiras.
