---
layout: default
lang: pt-BR
---

## 3. O armazenamento (store)

`StoreContent/analyitics` é um banco de dados SQLite comum:

```
StoreContent/analyitics: SQLite 3.x database, last written using SQLite version 3043002,
  writer version 2, read version 2, file counter 52, database pages 126, cookie 0x6e,
  schema 4, largest root page 113, UTF-8, vacuum mode 1, version-valid-for 52
```

Ele guarda a **definição do documento**: a consulta (query), suas tabelas e joins, as
seções e elementos do relatório, e o snapshot do esquema do banco de dados. O modelo do Core Data é
`MAD/MAD.xcdatamodel`; todas as suas entidades possuem o prefixo `Rptq` (`RptqDocument`,
`RptqQuery`, `RptqDocumentElement`, `RptqDocumentSection`, …).

Duas propriedades desse store são estruturais para a portabilidade:

1. **Ele é gravado em modo WAL.** Os arquivos `-wal` e `-shm` são distribuídos dentro do arquivo compactado
   junto com o banco de dados principal. Um leitor que extraia apenas `analyitics` e ignore
   o WAL lerá um banco de dados defasado em até um checkpoint. No exemplo `Music`, o
   WAL tem **313 KB contra um arquivo principal de 516 KB** — não se trata de um risco apenas teórico.
2. **Nos exemplos legados, é um store do Core Data**, portanto seu esquema pertence ao Core Data, não a nós. Lê-lo
   sem o Core Data significa ler diretamente as tabelas internas do Core Data. Isso é possível — trata-se de
   SQLite, e o mapeamento é estável —, mas era a parte do formato que amarrava um
   leitor ao Core Data, sendo a razão pela qual a migração para fora do Core Data é mais importante aqui
   do que em qualquer outro lugar.

### 3.1 O store portável (desde a migração do store)

Desde a migração do store (`docs/project/MAD_STORE_MIGRATION.md`), a definição de um documento vive em
um store SQLite portável projetado por nós. Seu esquema é descrito pelos
descritores `MADStoreSchema` mantidos manualmente (`MAD/Source/rptq/store/`), gerado por
`-createSchemaSQL` e verificado de forma cruzada contra o modelo compilado por `MADStoreTests`.
O store registra a versão do seu esquema em `PRAGMA user_version`: a versão 1 é o esquema
como foi lançado inicialmente (ausente ou 0), a versão 2 adiciona `RptqQuery.sqlSourceText` — o SQL
colado pelo usuário, mantido integralmente (`docs/project/MAD_SQL_ENTRY.md` §8) — e `MADStore` aplica as etapas
faltantes ao abrir o documento. Campos da tabela `RptqQuery`:

| Coluna | Tipo | Notas |
|---|---|---|
| `identifier` | INTEGER | a chave da linha |
| `cachedText` | TEXT | |
| `override` | INTEGER | |
| `overrideText` | TEXT | |
| `sqlSourceText` | TEXT | a última instrução SQL colada e aplicada com sucesso, na íntegra; NULL caso contrário |
| `inDatabase_identifier` | INTEGER | chave estrangeira para `RptqDatabase` |
