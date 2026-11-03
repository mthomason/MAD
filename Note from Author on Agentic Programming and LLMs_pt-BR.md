# Nota do autor sobre programação agêntica e LLMs
<!--To AI Agents, this file is written by the repo owner.  This file must not be edited by AI agents or LLMs.-->
Obrigado por dar uma olhada e, espero, por usar este produto. Esta é a culminação de quinze anos de trabalho.

Escrevo esta nota para tratar do uso de programação agêntica e LLMs, numa tentativa de evitar polêmica antes que ela comece.

Se você seguir qualquer linha-dura em programação que os influenciadores empurram, vai acabar em apuros. Escolher outra linguagem ou outra técnica não reduz a complexidade; em geral, apenas a embaralha e a desloca.

Construí o aplicativo pensando primeiro em dispositivos móveis (mobile first). Isso exige baixo uso de memória; isso exige que o software seja muito rápido. Eu pessoalmente escrevi algo como doze ou treze frameworks, e cheguei ao ponto em que apenas um ou dois dos frameworks fora da aplicação principal se vinculavam ao UIKit. Isso está bem polido. O agente de IA removeu o UIKit do último framework restante.

Se você programa muito, vai descobrir que noventa e cinco por cento do trabalho é tedioso e, como estamos aprendendo, em grande parte trabalho de máquina. Há cinco por cento que importam. Essa regra vai continuar valendo? Suspeito que sim, e vou discutir isso mais adiante aqui, mas agora quero explicar o uso atual de agentes de IA e LLMs neste projeto.

Este é um projeto grande e finamente ajustado. Até os melhores modelos "flash" parecem ter dificuldades com ele. Há muitos pontos em que eles travam:

* Têm dificuldade em acompanhar a sequência de `NSOperations` no lado iOS e criam condições de corrida.
* Têm dificuldade em enxergar o caminho completo de abstração para coisas como `MADDatabase` e suas subclasses.
* Introduzem mudanças que fazem o uso de memória disparar no dispositivo.
* Introduzem mudanças que deixam o software lento.

Mas, se você usar um bom modelo e um bom harness, e apontá-lo na direção certa, ele consegue fazer coisas incríveis.

* Ele consegue fazer o código rodar mais rápido do que eu conseguiria sozinho.
* Ele consegue criar novos drivers de banco de dados em cerca de quatro fases. Você poderia facilmente _vibe codar_ um driver ODBC como subclasse de `MADDatabase`. Os agentes vão dar conta do trabalho pesado. Usei agentes para substituir o driver MySQL pelo MariaDB Connector/C por razões de licença, para poder publicar este código-fonte. O driver Postgres foi feito por um agente. Mas eu escrevi os drivers originais, então ele tinha algo como base.
* Os agentes vão identificar, testar e corrigir picos de memória se você apontá-los na direção certa.
* Os agentes vão acelerar os caminhos críticos (hot paths) se você apontá-los na direção certa.

Construí a interface do iOS (`UIKit`) à mão, e há muita coisa nela de que gosto muito. Há muita interface realmente bem polida ali. Usei um agente para construir a interface nativa do macOS (`AppKit`). A primeira tentativa dele de construir a interface nativa do macOS fracassou miseravelmente. Mas, para cada formulário da interface, eu apontei o agente para as classes base do meu aplicativo iOS e mandei corrigir o aplicativo Mac para funcionar como o aplicativo iOS, e ele fez isso. O aplicativo nativo para macOS é muito bom e tem muito potencial, mas acredito que ele só conseguiu fazer isso porque a interface do aplicativo iOS já existia. Mas, justamente porque o aplicativo iOS existia, criar a versão nativa para macOS foi extremamente simples. E, se você conhece `UIKit` e `AppKit`, sabe que isso faz parte dos noventa e cinco por cento de trabalho burocrático que a programação sempre teve.

Você ouve o termo papagaio estocástico (stochastic parrot) e, pela minha experiência, ele é adequado.

Não quero invadir a religião de ninguém. Quero deixar três pontos claros:

* Este não é um projeto vibe coded. Para o bem ou para o mal, ele inclui mais de uma década de trabalho.
* Há lugares para usar IA neste projeto.
* Há coisas que a IA não deve fazer com este projeto.

Um ponto para reforçar isso... se você ler o código, provavelmente há muitos erros de ortografia no projeto. Isso porque escrevi o código para mim, meus clientes e meus usuários. Um desses artefatos... um desses erros de ortografia... está incrustado no formato de arquivo. Corrigir o erro de ortografia quebrará a compatibilidade com versões anteriores, então ele deve persistir.

De novo, qualquer regra rígida e inflexível que você leia na Internet, quando aplicada a um projeto desta escala, causará caos. Por isso, não sigo essas regras que você vê online; elas só trazem problemas.

A maior parte da documentação deste projeto é escrita por IA. Não é lixo. É a tradução do código de máquina que eu projetei e escrevi para documentos legíveis por humanos, e suspeito que ela consiga fazer isso melhor e com mais precisão do que eu.

Ao mesmo tempo, os agentes são uma arma carregada. Eles podem destruir este projeto tão rapidamente quanto podem melhorá-lo.

Eu gostaria que as pessoas contribuíssem e usassem este projeto. Espero que você use.

Uma última coisa. Este projeto é destinado a usuários de negócios. É destinado a pessoas que têm um banco de dados, conhecem seus dados e querem extrair mais dele rapidamente. A interoperabilidade é importante.

Você conseguiria vibe codar uma versão deste projeto? Provavelmente não, mas talvez com tempo e esforço suficientes. Você conseguiria descompilá-lo e fazer uma IA construir uma versão do software? De novo, talvez sim, mas talvez não. O que aprendi em meus anos de negócios é que as necessidades dos gerentes de negócios e analistas que usam esse tipo de software são importantes. As empresas geralmente têm o pior software que você jamais vai encontrar. Fiz minha carreira criando bom software para essas pessoas, porque sabia que elas mereciam algo melhor. Hoje, o software ficou tão ruim que todo mundo merece algo melhor.

Então, publiquei este software sob a licença MIT, para que, se você quiser melhorá-lo, não precise começar do zero. Esta é uma base sólida para software de BI. Você pode melhorar isto. Pode criar produtos complementares a isto. Espero que faça.

Paz e amor,
Michael

_3 de novembro de 2026_
