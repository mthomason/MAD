---
layout: default
lang: pt-BR
---

# Escrevendo um driver para o MAD em uma tarde

Todas as referências `arquivo:linha` abaixo estão atualizadas conforme o estado do repositório em 2026-10-25.

## O que é um driver

Um driver consiste em duas classes pequenas e uma chamada de registro:

1. uma subclasse de `MADDatabase` (`MADAPI/Source/MADDatabase.h` — o cabeçalho
   diz de forma direta: "This class is built for subclassing") que sabe como
   inspecionar o esquema de uma fonte de dados e executar uma consulta contra ela;
2. uma classe de conexão — uma subclasse de `MADDatabaseConnection` que adota
   o protocolo `MADDatabaseDriver`
   (`MADAPI/Source/MADDatabaseDriverRegistry.h`) e registra a si mesma no método
   `+load`.

Todo o restante — o grafo do designer de consultas, a geração de SQL, o cache
de linhas, o pipeline de renderização, os sete formatos de exportação, a CLI, a imagem
Docker — faz parte da infraestrutura compartilhada na qual o driver se conecta. O contrato que um driver
cumpre é *"retornar um esquema e linhas em formato de tabela"*
(`docs/project/MAD_STRATEGY.md` §3.7), razão pela qual um driver pode servir de fachada para
qualquer coisa que possa ser representada como uma tabela: um banco de dados SQL, um serviço
Web ou um arquivo.

Os três exemplos de servidores para usar como referência são `MADPostgres` (6 arquivos,
`MADPostgres/Source/`, subclasse `MADDatabasePostgres` sobre `libpq`),
`MADMySQL` (18 arquivos, `MADMySQL/Source/`, subclasse `MADDatabaseMySQL`) e
`MADTdsClient` (SQL Server sobre FreeTDS). O Sqlite3 é o quarto driver distribuído
(`MADSqlite3`), e o caso baseado em arquivo local
(`+newDatabaseConnectionWithURL:`) pode ser visto na classe de conexão dele.

## Passo 1 — a constante de tipo

Escolha o próximo valor livre de `MADDatabaseType` (`MADAPI/Source/MADDatabaseType.h`;
os tipos distribuídos ocupam de 1 a 12) ou estenda o enum. Esse valor é gravado dentro do
documento, portanto trata-se de uma constante de formato: uma vez que existam documentos com o seu tipo,
esse número passa a ser permanente.

## Passo 2 — crie uma subclasse de `MADDatabase`

Os pontos de extensão abstratos (seams) ficam em `MADAPI/Source/MADDatabaseProtocol.h`
(`MADDatabaseDataSource`). A superfície obrigatória é:

```objc
- (void)getTables:(void (^)(BOOL success, NSError *error,
                            NSArray <MADDatabaseTable *> *tables))completion;

- (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)dbconn
                                                    error:(NSError **)error;
- (NSArray <MADDatabaseField *> *)fieldsForTable:(NSString *)tableName
                                     connection:(id)dbconn
                                          error:(NSError **)error;

- (id)connectWithConnection:(MADDatabaseConnection *)connection
                 credentals:(MADCredential *)credentals
            connectionError:(NSError **)error;

// The execution seam: the driver fills the table it is handed.  The
// destination is any <MADDataTableWriting>, which is what keeps the
// promise to "anything that returns a table" (MADDataTable.h).
- (BOOL)executeSQL:(NSString *)sql
         fieldKeys:(NSArray *)fieldKeys
      onConnection:(id)dbconn
  intoResultTable:(id <MADDataTableWriting>)dataTable
         withError:(NSError **)error;

- (BOOL)executeQuery:(MADQuery *)query withError:(NSError **)error;
- (BOOL)executeQuery:(MADQuery *)query
       withDataTable:(id <MADDataTableWriting>)dataTable
            andError:(NSError **)error;

// Optional: only file-backed drivers have nothing to dial.
- (void)closeConnection:(id)process;
```

A navegação de esquema (`getTables…`, `fieldsForTable:…`) é o que o fluxo de
criação de documento do aplicativo chama quando importa o esquema de um banco de dados para um novo
`.mad`; o método de execução (`executeSQL:…`) é o que `mad refresh` e o visualizador chamam.
`MADOperationRefresh.m:134` mostra a chamada exata realizada pela cadeia de atualização.

## Passo 3 — a classe de conexão e o registro

```objc
@interface MyDriverConnection : MADDatabaseConnection <MADDatabaseDriver>
@end

@implementation MyDriverConnection
+ (void)load {
	[MADDatabaseDriverRegistry registerDriverClass: self];
}
+ (MADDatabaseType)databaseType { return MADDatabaseTypeMyDriver; }
+ (NSString *)Identifier { return @"MyDriver"; } // stored in documents
+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentials { … }
+ (Class)databaseClass { return [MyDatabase class]; }
+ (instancetype)newDatabaseConnectionWithHost:(NSString *)host
										 database:(NSString *)database
											 port:(NSInteger)port { … }
@end
```

`+Identifier` é o valor armazenado em `RptqDatabaseCredentals.driverID`, portanto também é uma
constante do formato de documento — escolha uma grafia estável ("MySQL", "TDS",
"PostgreSQL" e "Sqlite 3" são os valores distribuídos). Uma segunda classe reivindicando um
tipo já registrado constitui erro de programação; o registro valida isso com uma asserção.

## Passo 4 — vincule (link) o driver para que o registro seja executado

O registro ocorre por processo e **por vinculação (link)**: um processo que não vincula
seu driver não consegue instanciar bancos de dados daquele tipo (o construtor falha imediatamente em uma asserção com
mensagem clara, em vez de falhar silenciosamente mais tarde com `nil`).

* **Apple:** vincule seu framework ao aplicativo ou binário hospedeiro (a CLI lista seus drivers
  na variável `FRAMEWORKS` em `CLI/build.sh`), ou utilize `-ObjC` ao vincular uma
  biblioteca estática — caso contrário, categorias e métodos `+load` são descartados
  silenciosamente pelo linker.
* **Linux:** adicione sua biblioteca estática com **whole-archive** ao target `mad` em
  `Linux/CMakeLists.txt`, da mesma forma que `madsqlite3`, `madmysql`, `madtdsclient`
  e `madpostgres`:

  ```cmake
  target_link_libraries(mad PUBLIC
      "$<LINK_LIBRARY:WHOLE_ARCHIVE,my_driver>" …)
  ```

  Isso não é mero detalhe estético — o trabalho de um driver é invocado por meio de categorias
  (envio de mensagens Objective-C, sem símbolos diretos), e um link estático comum sem `WHOLE_ARCHIVE` descarta esses objetos: a
  falha resultante é um crash no primeiro envio de mensagem em tempo de execução, sem nenhum aviso do linker
  (`Linux/README.md`, seções "The compat shims" / "The drivers are registered").
  Uma lista de arquivos-fonte por driver em `cmake/MyDriverSources.cmake` segue o formato de
  `MADFoundationSources.cmake`, nomeando cada arquivo excluído e o respectivo
  motivo.

## Passo 5 — as convenções de testes (este é o padrão do projeto; siga-o)

Duas suítes no target de testes do framework:

1. **Testes offline** — estruturas de esquema, metadados de campos, colocação de aspas (quoting) em
   identificadores e round-trip das propriedades da conexão. Estes testes sempre rodam.
2. **Testes live** — comunicam-se com um servidor real e **pulam (skip), nunca falham**, quando
   o servidor não está acessível. `MADMySQL/MADMySQLTests/MADMySQLLiveTests.m` é
   o modelo: as credenciais usam como padrão um servidor local documentado e
   todas podem ser sobrescritas por variáveis de ambiente
   (`MAD_MYSQL_TEST_HOST`, `MAD_MYSQL_TEST_PORT`, `MAD_MYSQL_TEST_USER`,
   `MAD_MYSQL_TEST_PASSWORD`, `MAD_MYSQL_TEST_SCHEMA`), e cada teste live
   começa com `XCTSkipIf(![self serverIsAvailable], …)`. Uma máquina
   sem o seu servidor de banco de dados ainda obtém uma suíte verde. Observe o comentário no arquivo de testes do MySQL:
   use `127.0.0.1`, e não `localhost`, dentro do Simulador do iOS.
3. **Testes de registro** — `MADDatabaseDriverRegistryTests` mostra a estrutura:
   registrar um driver de teste, validar a busca (lookup) e validar que o registro duplicado de tipo
   lança exceção. Seu driver ganha um teste desses quase gratuitamente por construção.
4. Porte as suítes para `Linux/Tests/` caso o driver faça parte do
   build headless (consulte `cmake/` e `Linux/README.md`, seção "Adding the next
   framework"); caso contrário, explique no PR por que ele é exclusivo para plataformas Apple.

## Passo 6 — a ressalva honesta: o que um driver não-SQL pode e não pode fazer hoje

Esta é a única parte da arquitetura de drivers que ainda não está finalizada, e está documentada
deliberadamente (`docs/project/MAD_STRATEGY.md` §4.7): a camada de **execução**
já tem o formato ideal para qualquer driver — `executeSQL:…intoResultTable:…` e o
destino `MADDataTableWriting` cumprem fielmente a promessa de "qualquer coisa que retorne uma
tabela" —, mas a camada de **compilação** ainda é compartilhada: `MADQueryFull` compila
o grafo de consulta em uma única string SQL por driver. Seu driver recebe **texto
SQL**, e não o grafo (tabelas, campos, predicados, grupos).

Portanto, um driver REST/Web-service hoje:

* **pode** navegar pelo seu esquema (`getTables…`, `fieldsForTable:…`), aproveitar o
  formulário de conexão que o aplicativo já possui, receber o SQL gerado e
  traduzi-lo em chamadas de API, entregar linhas em qualquer tabela gravável e
  utilizar todo o fluxo de atualização/renderização/exportação — sendo um driver totalmente funcional;
* **não pode** receber o grafo de consulta nativamente: para saber *o que* a engine
  está pedindo, ele precisa fazer o parse do texto SQL recebido. O caminho prático: o próprio parser SQL da engine (construído para o
  recurso de entrada direta de SQL, `docs/project/MAD_SQL_ENTRY.md`) já faz o parse do
  subconjunto suportado — e o SQL gerado pertence a esse subconjunto por construção —, de modo que
  um driver pode reutilizá-lo para recuperar o grafo;
* a **solução definitiva** é um hook de compilação por driver — o mesmo desenho que o
  projeto esboçou para Salesforce SFQL em 2012 — para que "instalar um
  driver" signifique "instalar um driver para qualquer fonte", e não apenas "para dialetos SQL compatíveis".
  Isso está planejado como trabalho de contrato da engine (Stage 1) e
  será um excelente primeiro PR caso você queira um desafio maior do que escrever apenas um driver.

Mais uma observação importante, voltada para implantações em servidor: um
driver instalado pelo usuário representa **código arbitrário executando no processo do servidor**. O
registro atual funciona para drivers próprios e confiáveis; um marketplace de
drivers exigirá assinatura de código, sandboxing ou isolamento em processos workers antes
de existir, e isso deve fazer parte do design da API do servidor desde o início, e não ser acoplado às pressas
depois.

## Passo 7 — enviando sua contribuição

Proponha o driver usando o template de issue de proposta de driver, siga a
regra de test-first em [CONTRIBUTING.md](https://github.com/mthomason/MAD/blob/master/CONTRIBUTING.md) (escreva primeiro o teste
que falha e depois o código até ficar verde; faça snapshot de fixtures em vez de gerá-las
com o código novo) e, se o driver vincular uma nova biblioteca de terceiros,
atualize o arquivo
[docs/project/THIRD_PARTY_LICENSES.md](https://github.com/mthomason/MAD/blob/master/docs/project/THIRD_PARTY_LICENSES.md)
e as obrigações de licenciamento correspondentes — o repositório leva esse controle muito a sério.
