---
layout: default
lang: pt-BR
---

## 8. Questões em aberto

1. **O store realmente precisa usar Core Data?** A definição que ele armazena é um
   grafo de objetos modesto. Um esquema SQLite próprio dentro do mesmo arquivo elimina
   o risco H3, remove a última dependência da Apple do formato e é um pré-requisito para
   Windows independentemente do que a CLI faça. Esta foi uma decisão de projeto abordada na
   migração do Core Data (`docs/project/MAD_STORE_MIGRATION.md`).
2. **A miniatura (thumbnail) deve ficar dentro do documento?** Ela é regenerável, assim como o cache
   de linhas, e é a única razão para a existência de `AdditionalContent/`. Removê-la tornaria
   todos os membros de um `.mad` estritamente essenciais (authoritative).
3. **O `.mad` deveria poder carregar o cache de linhas opcionalmente?** Uma variante "empacotada" (packed) permitiria
   abrir um documento offline em um segundo dispositivo, ao custo de um arquivo maior. Nada faz
   isso hoje; a questão é levantada porque o nome do formato frequentemente sugere essa expectativa (§5).
4. **Alterações de conteúdo deveriam invalidar o cache de renderização?** Do ponto de vista *mecânico*, a resposta já é conhecida:
   o cache `.madac` é indexado pelo nome do arquivo e pelo tamanho da página, sem hash de conteúdo, de modo que editar
   um documento mantendo o mesmo nome de arquivo exibe páginas defasadas até que os arquivos de cache sejam excluídos
   (§5.3). A questão em aberto é uma decisão de produto — se uma edição *deve* invalidá-lo — e a
   posição atual do autor é que o cache é parte estrutural da arquitetura e não uma mudança urgente no momento
   (§5.1). Portanto, o ponto fica registrado, sem alteração imediata.
