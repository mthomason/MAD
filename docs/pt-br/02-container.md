---
layout: default
lang: pt-BR
---

## 2. O contêiner

```
$ file Music.mad
Music.mad: bzip2 compressed data, block size = 900k
```

O gravador (writer) está em `MADArchiveManager.m:86-100`:

| Propriedade | Valor | Onde |
|---|---|---|
| Formato do arquivo | `pax restricted` | `MADArchiveManager.m:88` |
| Filtro de compressão | bzip2 | `MADArchiveManager.m:95` |
| Arquivos ocultos | **ignorados** | `MADArchiveManager.m:111` |
| Caminhos dos membros | relativos à raiz do arquivo | `MADArchiveManager.m:124-130` |

`pax restricted` significa POSIX pax utilizando apenas as extensões que o formato ustar já cobre, de modo que o
arquivo pode ser lido por qualquer implementação de tar. O bzip2 está presente em todos os gerenciadores de pacotes de
todas as plataformas. **Nada no contêiner é específico da Apple.** Um arquivo `.mad`
pode ser descompactado com `tar xjf` tanto no macOS quanto no Linux e no Windows.

### Membros

Ambos os exemplos distribuídos contêm exatamente estas seis entradas, nesta ordem:

```
AdditionalContent/
StoreContent/
StoreContent/analyitics-wal
StoreContent/analyitics-shm
StoreContent/analyitics
meta.plist
```

`AdditionalContent/` está presente, mas vazio em ambos os exemplos. É o diretório que o
documento utiliza para a miniatura (thumbnail): `MADocument.m:571-583` lê
`thumbnail@2x.png` dali para `extraInformation`, e
`MADURLFactory.m:58-68` constrói esse caminho. Ele é gravado por
`-writeAdditionalContent:toURL:…` (`MADocument.m:617-648`) como parte do
protocolo de conteúdo adicional do `UIManagedDocument`.

`StoreContent/` é o armazenamento persistente do Core Data, nomeado por
`+persistentStoreName` (`MADocument.m:650`), que retorna `@"analyitics"`.

> O nome está com erro de grafia, e está gravado **assim em disco, nos documentos distribuídos**.
> Não se trata de um erro de digitação em um comentário que possa ser corrigido: renomeá-lo altera o
> nome de arquivo do store e quebra todos os arquivos `.mad` existentes. Ele permanece assim, e esta nota existe para que
> o próximo desenvolvedor não tente "consertá-lo".

`meta.plist` contém os metadados próprios do documento, gravados em `MADocument.m:636-644`:

```xml
{
  "generator" => "MAD Designer"
  "version"   => 1
}
```

A versão (`version`) é gravada como `double` (`MADocument.m:611`) e lida de volta como inteiro nos
exemplos. Os consumidores do formato devem aceitar ambos.
