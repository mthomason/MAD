---
layout: default
lang: pt-BR
---

## 6. Riscos e armadilhas que um segundo leitor precisa tratar

Estes são defeitos reais no formato atual, não opiniões. Cada um é listado com o que ele
pode quebrar.

| # | Risco / Armadilha | Consequência |
|---|---|---|
| H1 | **Sem magic bytes.** O arquivo é detectado apenas pela extensão (`MADocument.m:459`). | O Windows não possui associação nativa para `.mad`, e um arquivo renomeado torna-se inidentificável. Veja a §7. |
| H2 | **WAL e SHM são incluídos no arquivo.** `analyitics-wal` tem 313 KB contra um banco de dados de 516 KB. | Um leitor que ignore o WAL lê dados desatualizados. Uma CLI precisa aplicar (replay) o WAL ou exigir um checkpoint antes de compactar. |
| H3 | **Esquema interno do Core Data (v0 legado).** | Amarra qualquer leitor ao Core Data, que não existe fora das plataformas Apple. O formato não pode ser considerado portável sem resolver isso. |
| H4 | **Arquivos ocultos são ignorados** (`MADArchiveManager.m:111`). | Qualquer futuro membro oculto (iniciado por ponto) é descartado silenciosamente do arquivo compactado. |
| H5 | **`analyitics` está com erro de grafia** em disco. | Não pode ser corrigido sem quebrar a compatibilidade com documentos existentes. |
| H6 | **`version` é `double` no gravador e inteiro nos exemplos.** | Os consumidores precisam aceitar ambos os tipos. |
| H7 | **Flags de compilação do SQLite não estavam fixadas.** `build_sqlite3.sh` declarava 20 defines; o target `MADSqlite3` aplicava apenas um. | A engine que grava `.maddb` usava páginas de 4096 bytes onde o script pedia 8192, além de omitir FTS5 e STAT4. O tamanho de página é gravado no cabeçalho do arquivo, de modo que o formato acabava definido por acidente. **Agora corrigido**: as definições ficam em `Compressor/sqlite3.xcconfig`, lido tanto pelo target quanto pelo script. Caches gravados desde então têm páginas de 8192 bytes; caches antigos continuam abrindo normalmente, pois o SQLite lê o tamanho da página a partir do cabeçalho. Consulte `docs/project/LIBRARIES.md` §4. |
