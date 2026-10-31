[English](README.md) | [简体中文](README_zh.md) | [日本語](README_ja.md) | **Português (Brasil)**

# Framework MADTds

O **MADTds** é um framework para iOS (e macOS) que encapsula o cabeçalho `sybdb.h` da biblioteca FreeTDS. Ele simplifica a integração e o uso de bancos de dados Sybase / SQL Server (protocolo TDS) em projetos iOS, fornecendo uma API nativa em Objective-C para interagir facilmente com bancos de dados TDS em aplicações Apple.

## Recursos

- Operações de banco de dados simplificadas usando a interface `MADTdsDb`.
- Inclui a biblioteca FreeTDS para suporte robusto às funcionalidades de bancos de dados Sybase / TDS.
- Totalmente compatível com iOS e projetado para funcionar dentro do ambiente do Xcode.
- Script de build customizado para gerenciar as dependências do FreeTDS.

---

## Instalação

### Pré-requisitos

- Xcode 13 ou superior
- iOS 12.0 ou superior
- Binários pré-compilados do FreeTDS (incluídos com o framework)

### Passos

1. Clone ou baixe o repositório.
2. Adicione o `MADTds.xcodeproj` ao seu workspace do Xcode.
3. Vincule o `MADTds.framework` ao seu target em **General > Frameworks, Libraries, and Embedded Content**.
4. Adicione os cabeçalhos necessários do diretório `freetds/lib/include` aos caminhos de busca do seu projeto:
   - Acesse **Build Settings** do seu target.
   - Configure **Header Search Paths** para incluir `MADTds/freetds/lib/include`.

---

## Uso

### Importando o Framework

Adicione as seguintes instruções de importação ao arquivo onde deseja utilizar o MADTds:

```objc
#import <MADTds/MADTds.h>
#import <MADTds/MADTdsDb.h>
```

### Conectando a um Banco de Dados

Veja um exemplo de como conectar a um banco de dados e executar uma consulta:

```objc
MADTdsDb *db = [[MADTdsDb alloc] init];

// Configure the connection
db.server = @"your-server";
db.database = @"your-database";
db.username = @"your-username";
db.password = @"your-password";

if ([db connect]) {
    NSLog(@"Connected to database successfully.");
    NSArray *results = [db executeQuery:@"SELECT * FROM your_table"];
    NSLog(@"Query Results: %@", results);
} else {
    NSLog(@"Failed to connect to database.");
}
```

---

## Estrutura de Diretórios

```
MADTds.xcodeproj/              - Xcode project configuration
MADTds/                        - Core framework source
├── MADTds.h                   - Framework entry point
├── MADTdsDb.h                 - Database connection interface
├── MADTdsDb.m                 - Database connection implementation
madtds/MADTds.docc/            - Documentation for the framework
freetds/                       - Bundled FreeTDS library
├── lib/include/               - Header files for FreeTDS
├── lib/libct.a                - FreeTDS Client Library
├── lib/libsybdb.a             - FreeTDS Database Library
build_tds.sh                   - Script to manage FreeTDS builds
README.md                      - Project documentation
```

---

## Compilando o Framework

1. Certifique-se de que o script `build_tds.sh` possui permissão de execução:
   ```bash
   chmod +x build_tds.sh
   ```
2. Execute o script para compilar a biblioteca FreeTDS:
   ```bash
   ./build_tds.sh
   ```
3. Abra o `MADTds.xcodeproj` no Xcode e compile o framework.

---

## Documentação

A documentação está disponível na pasta `madtds/MADTds.docc`. Para visualizá-la:
1. Abra o `MADTds.xcodeproj` no Xcode.
2. Acesse o menu **Product > Build Documentation**.

---

## Contribuindo

Contribuições são bem-vindas! Siga estes passos:

1. Faça um fork do repositório.
2. Crie uma nova branch para sua funcionalidade ou correção de bug.
3. Faça commit de suas alterações e envie-as (push) para o seu fork.
4. Envie um pull request descrevendo suas alterações.

---

## Licença

Este projeto utiliza a **Licença MIT**. Consulte o arquivo `LICENSE` para mais detalhes.

---

## Agradecimentos

- [FreeTDS](http://www.freetds.org) por fornecer a biblioteca de comunicação TDS/Sybase.
- À comunidade de desenvolvedores iOS pela inspiração e apoio.

---
