---
layout: default
lang: pt-BR
---

## 7. O formato como deve ser definido

Este é o alvo normativo. Trata-se deliberadamente de uma pequena evolução em relação ao que já existe,
porque o que existe já está quase no formato ideal.

### 7.1 Identificação pelo conteúdo, não pelo nome

Um arquivo `.mad` deve começar com um cabeçalho fixo **fora** do fluxo de compressão,
para que um leitor possa identificá-lo logo pelos primeiros bytes:

```
offset 0  8 bytes   "MADFILE\0"      magic
offset 8  2 bytes   uint16 LE        format major version
offset 10 2 bytes   uint16 LE        format minor version
offset 12 4 bytes   uint32 LE        flags (bit 0: WAL checkpointed)
offset 16 ...       bzip2 stream
```

Justificativa: isso elimina o problema no Windows e em outros ambientes. A extensão passa a ser uma
*convenção* para o gerenciador de arquivos, e não o único meio de identificar o arquivo. Um `.mad`
renomeado para `.zip`, ou um documento recebido por um canal que altere extensões, continua sendo
reconhecivelmente um `.mad`. Além disso, permite detectar a versão sem precisar descomprimir o arquivo.

O cabeçalho é incompatível com os dois exemplos legados distribuídos originalmente. Isso é
aceitável *apenas* porque o leitor pode fazer fallback: ausência do magic `MADFILE` → tratar como um
documento legado v0 (§7.4).

### 7.2 Um store com checkpoint concluído

O gravador executa o checkpoint do WAL do store antes de criar o arquivo compactado, de modo que os membros WAL e SHM
se tornam opcionais e um leitor que os encontre deve aplicá-los (replay) em vez de ignorá-los.
O resultado é registrado no bit 0 de flags do cabeçalho — e **não** em `meta.plist`, que é
gravado antes da execução do checkpoint; assim, a flag no cabeçalho é o registro oficial e
pode ser lida sem descomprimir.

Isso também reduz o tamanho dos documentos: o exemplo `Music` gasta um terço de seus bytes em um WAL
que um checkpoint incorporaria diretamente ao arquivo principal.

### 7.3 Membros

| Membro | Obrigatório | Conteúdo |
|---|---|---|
| `meta.plist` | sim | `generator`, `version` |
| `StoreContent/<name>` | sim | a definição do documento |
| `StoreContent/<name>-wal` / `-shm` | não | presentes apenas quando não houve checkpoint (bit 0 da flag do cabeçalho = 0) |
| `AdditionalContent/` | não | `thumbnail@2x.png` |

### 7.4 Compatibilidade

- **v0** — formato inicial distribuído: sem cabeçalho magic, possivelmente com WAL, `version` 1. Os leitores devem
  aceitá-lo indefinidamente; ambos os documentos de exemplo originais são v0.
- **v1** — cabeçalho magic, store com checkpoint concluído, `version` 1, novos membros conforme descrito acima.

Um gravador emite v1 mantendo `meta.plist` inalterado no restante. Um leitor detecta v0 pela
ausência dos magic bytes.
