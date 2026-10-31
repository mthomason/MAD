---
layout: default
lang: pt-BR
---

## 4. Leitura e escrita, conforme implementado

```
write:  document model ──▶ UIManagedDocument ──▶ ~/tmp/<name>.mada/ ──▶ tar.bz2 ──▶ <name>.mad
read:   <name>.mad ──▶ tar.bz2 ──▶ ~/tmp/<name>.mada/ ──▶ UIManagedDocument
```

O diretório intermediário é chamado de **guts**. Sua extensão é `.mada`
(`MADConstants.m:12`, `MADFileExtentionMobleApplicationDocumentArchive`), ele recebe o
nome do documento e é colocado em um diretório temporário
(`MADURLFactory.m:51-56`, `newURLLocalTemporaryDirectory` → `~/tmp`).

- Salvar — `MADocument.m:497-514`: grava o modelo no diretório guts e, em seguida, compacta o guts
  sobre a URL do documento.
- Abrir — `MADocument.m:456-476`: descompacta o documento no diretório guts e lê o
  store a partir dali.

O comentário acima de `-readFromURL:` (`MADocument.m:452-455`) resume isso nas
próprias palavras do autor:

> 1. Unarchive the MAD file; it's a zip file (tar.bz2 maybe).
> 2. Read the unarchived file. It's currently a Core Data file.

"It's currently a Core Data file" ("Atualmente é um arquivo do Core Data") resume toda a motivação da migração em poucas palavras.
