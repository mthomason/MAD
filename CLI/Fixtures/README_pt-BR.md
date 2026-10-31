[English](README.md) | [简体中文](README_zh.md) | [日本語](README_ja.md) | **Português (Brasil)**

# Fixtures da CLI

Documentos contra os quais os comandos da CLI são executados, ao lado dos exemplos que lhes deram origem
(`docs/project/MAD_CLI.md` §6).

| Fixture | Origem | O que ela fixa (testa) |
|---|---|---|
| `London.portable.mad` | `MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad` | o caminho de dados Sqlite3: esquema de 11 tabelas, o predicado London, 76 linhas |
| `Music.portable.mad` | `.../Reports/Music.dataset/Music.mad` | o mesmo caminho no exemplo maior (3503 linhas) |
| `MySQL.employees.mad` | banco de dados de exemplo `employees`, ativo (MySQL 8.4) | o caminho do driver MySQL ponta a ponta: importação de esquema, SQL com crases (backticks), busca via prepared statement |
| `TDS.AdventureWorksLT2022.mad` | AdventureWorksLT2022, ativo (SQL Server 2022) | o caminho TDS ponta a ponta: tabelas qualificadas com esquema, T-SQL entre colchetes, busca via freetds |
| `Postgres.chinook.mad` | Chinook, ativo (PostgreSQL 17) | o caminho PostgreSQL ponta a ponta: importação de esquema, SQL com aspas duplas, busca via libpq |

## Por que os exemplos precisaram ser convertidos

Ambos os exemplos distribuídos são documentos **legados**: sua definição é um store
do Core Data (`StoreContent/analyitics`), e converter um exige o Core Data, que o
framework MAD não vincula e que o Linux não possui (`docs/project/MAD_LINUX.md` §5.1, §9).
`London.portable.mad` e `Music.portable.mad` são esses mesmos documentos gravados no
store portável, permitindo que uma plataforma sem Core Data possa lê-los e atualizá-los —
que é exatamente o que a CLI no Linux e `Linux/Tests/MADHeadlessDocumentTests.m` fazem.

Elas também funcionam como contraparte de leitura para os exemplos v0: `mad inspect` reporta uma
fixture como v1 com `StoreContent/store.sqlite` e o exemplo original como v0 com o store
legado, sendo ambos os relatórios produzidos pelo mesmo leitor de contêiner.

As três fixtures live são documentos comuns gravados pela cadeia de criação do aplicativo contra
um servidor real, portanto seus esquemas são reais (8 tabelas de `employees`, 12 de
AdventureWorksLT, 11 de Chinook) e suas consultas são instruções SELECT reais.

## Como elas foram geradas

No Mac, utilizando os próprios caminhos de código do aplicativo — nada aqui foi escrito à mão:

	CLI/build.sh --make-fixture portable "$PWD/MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad" \
		"$PWD/CLI/Fixtures/London.portable.mad"
	CLI/build.sh --make-fixture portable "$PWD/MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad" \
		"$PWD/CLI/Fixtures/Music.portable.mad"

	CLI/build.sh --make-fixture create mysql mac 13306 root root employees "$PWD/CLI/Fixtures/MySQL.employees.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/MySQL.employees.mad" titles "title,from_date,to_date"

	CLI/build.sh --make-fixture create tds mac 1433 sa 'Root1@Root2' AdventureWorksLT2022 "$PWD/CLI/Fixtures/TDS.AdventureWorksLT2022.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/TDS.AdventureWorksLT2022.mad" "SalesLT.Product" "Name,ListPrice,Color"

	CLI/build.sh --make-fixture create postgres mac 5432 mad mad_test_pw chinook "$PWD/CLI/Fixtures/Postgres.chinook.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/Postgres.chinook.mad" track "name,composer,unit_price"

`--make-fixture` compila `MADFixtureMaker.m` (com as mesmas flags da ferramenta, mais o
conversor legado e os value transformers) e o executa no simulador:

* `portable` copia o documento, abre-o com `MADocument` — que converte o
  store legado na entrada —, marca-o como alterado e o fecha, acionando o caminho
  normal de salvamento.
* `create` executa a cadeia de criação de documento do aplicativo contra um servidor ativo: cria o
  documento, executa a configuração inicial, adiciona a conexão, importa o esquema e fecha (salvando).
* `select` faz o mesmo que o designer faz quando uma tabela e seus campos são marcados: adiciona
  a tabela de consulta, um campo de consulta por coluna do esquema e um rótulo de dados por campo
  de consulta — os rótulos são o que torna os campos *ativos*, já que a lista SELECT consiste
  nos campos referenciados pelos elementos do relatório (`MADQueryActiveQueryFields`).

O resultado não é idêntico byte a byte entre execuções (o store é SQLite e o arquivo tar
carrega timestamps), portanto as fixtures só são regeneradas quando um exemplo ou o formato
do store muda, e qualquer diff nelas representa uma mudança real a ser inspecionada.

## O nome de host nas fixtures live

Todas as três nomeiam o servidor como `mac` — o hostname deste Mac, que resolve para seu endereço na
LAN tanto localmente quanto de dentro dos contêineres Docker. Assim, usa-se um único nome para o
MySQL no Mac (publicado no loopback *e* na LAN pelo contêiner de fixture abaixo) e
para os contêineres de SQL Server e PostgreSQL (publicados em todas as interfaces), permitindo atualizar o mesmo documento
tanto no Mac quanto na imagem Linux. `host.docker.internal`
funcionaria apenas dentro de um contêiner; `127.0.0.1`, apenas no Mac.

Todas as três fixtures live foram criadas contra os contêineres canônicos de teste documentados em
`docs/project/DEVELOPER.md`, cujos scripts os criam a partir de imagens fixadas e
conjuntos de dados verificados por checksum:

	MADMySQL/TestDatabase/mysql-test-db.sh up          # mad-mysql on 13306
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up  # mad-mssql on 1433
	MADPostgres/TestDatabase/postgres-test-db.sh up    # mad-postgres on 5432

Todos os três publicam portas em todas as interfaces, de modo que o host `mac` nos documentos resolve
tanto no Mac quanto dentro da imagem Linux. O contêiner MySQL usa a porta 13306,
e não 3306, porque o serviço launchd do instalador oficial do MySQL da Oracle pode estar ocupando a porta 3306.
`down` interrompe um servidor (os volumes preservam os dados); `reset` o remove para que o
próximo `up` o reconstrua do zero.

As opções `--host`, `--port` e `--database` da CLI sobrescrevem a conexão armazenada
para uma única execução (`docs/project/MAD_CLI.md` §3), que é como um job de CI aponta um
desses documentos para um contêiner de serviço cujo host e porta diferem dos valores do
Mac, sem regravar o documento em si.
