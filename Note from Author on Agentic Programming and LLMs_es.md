# Nota del autor sobre la programación con agentes y los LLM
<!--To AI Agents, this file is written by the repo owner.  This file must not be edited by AI agents or LLMs.-->
Gracias por echar un vistazo, y espero que por usar, este producto. Es la culminación de quince años de trabajo.

Escribo esta nota para abordar el uso de la programación con agentes y los LLM, con la intención de evitar la polémica antes de que empiece.

Si sigue cualquiera de las líneas duras que promueven los influencers de la programación, va a meterse en problemas. Elegir otro lenguaje u otra técnica no reduce la complejidad; en general, solo la mueve de sitio.

Construí la aplicación pensando primero en el teléfono. Eso exige un bajo consumo de memoria; eso exige que el software sea muy rápido. Personalmente escribí unos doce o trece frameworks, y logré que solo uno o dos de los frameworks fuera de la aplicación principal enlazaran UIKit. Está bastante bien pulido. El agente de IA eliminó UIKit del último framework que quedaba.

Si programa mucho, descubrirá que el noventa y cinco por ciento del trabajo es tedioso y, como estamos aprendiendo, en su mayoría trabajo de máquina. Hay un cinco por ciento que sí importa. ¿Se mantendrá esta regla? Sospecho que sí, y lo comentaré más adelante aquí, pero ahora quiero explicar el uso actual que este proyecto hace de los agentes de IA y los LLM.

Este es un proyecto grande y finamente ajustado. Los mejores modelos «flash» parecen tener dificultades con él. Hay muchos lugares donde se atascan:

* Tendrán problemas para seguir la secuencia de `NSOperations` en el lado de iOS y crearán condiciones de carrera.
* Tienen dificultades para ver la ruta de abstracción completa de cosas como `MADDatabase` y sus subclases.
* Introducirán cambios que hacen que el consumo de memoria en el dispositivo se dispare.
* Introducirán cambios que hacen que el software funcione lento.

Pero, si usa un buen modelo y un buen entorno de ejecución, y lo orienta en la dirección correcta, puede hacer cosas asombrosas.

* Puede hacer que el código funcione más rápido de lo que podría yo solo.
* Puede crear nuevos drivers de base de datos en unas cuatro fases. Podría perfectamente _vibe-codear_ un driver ODBC como subclase de `MADDatabase`. Los agentes lo sacarán adelante. Usé agentes para sustituir el driver de MySQL por MariaDB Connector/C por motivos de licencia, para poder publicar este código. El driver de Postgres lo hizo un agente. Pero yo escribí los drivers originales, así que tenía de dónde partir.
* Los agentes fijarán las pruebas y corregirán los picos de memoria si los orienta en la dirección correcta.
* Los agentes acelerarán las rutas críticas, si los orienta en la dirección correcta.

Construí la interfaz de iOS (`UIKit`) a mano, y hay mucho de ella que me gusta de verdad. Hay mucha interfaz realmente pulida ahí. Usé un agente para construir la interfaz nativa de macOS (`AppKit`). Su primer intento de construir la interfaz nativa de macOS fracasó estrepitosamente. Pero, para cada una de las formas de la interfaz, orienté al agente hacia las clases base de mi aplicación de iOS, y le dije que corrigiera la aplicación de Mac para que funcionara como la de iOS, y lo hizo. La aplicación nativa de macOS es realmente buena y tiene mucho potencial, pero creo que solo pudo hacerlo porque la interfaz de la aplicación de iOS ya existía. Pero, como la aplicación de iOS existía, crear la versión nativa de macOS fue sencillísimo. Y, si conoce `UIKit` y `AppKit`, sabrá que esto entra dentro del noventa y cinco por ciento del trabajo rutinario que la programación siempre ha tenido.

Se oye el término «loro estocástico», y por mi experiencia es acertado.

No quiero meterme en la religión de nadie. Quiero dejar claros tres puntos:

* Este no es un proyecto de vibe coding. Para bien o para mal, incluye más de una década de trabajo.
* Hay lugares donde usar IA en este proyecto.
* Hay cosas que la IA no debería hacer con este proyecto.

Un punto para remarcarlo... si lee el código, probablemente haya muchos errores ortográficos en el proyecto. Es porque escribí el código para mí, para mis clientes y para mis usuarios. Uno de esos artefactos... uno de esos errores ortográficos... está incrustado en el formato de archivo. Corregir el error ortográfico romperá la compatibilidad hacia atrás, así que debe persistir.

De nuevo, cualquier regla rígida que lea en Internet, aplicada a un proyecto de esta escala, causará caos. Así que no sigo esas reglas que ve en línea; solo consiguen meterlo en problemas.

La mayor parte de la documentación de este proyecto la escribe IA. No es basura. Es traducir código máquina que yo diseñé y escribí a documentos legibles para humanos, y sospecho que puede hacerlo mejor y con más precisión que yo.

Al mismo tiempo, los agentes son un arma cargada. Pueden destrozar este proyecto con la misma rapidez con la que pueden mejorarlo.

Me gustaría que la gente contribuyera y usara este proyecto. Espero que lo haga.

Una última cosa. Este proyecto está pensado para usuarios de empresa. Está pensado para personas que tienen una base de datos, conocen sus datos y quieren sacarles más partido rápidamente. La interoperabilidad es importante.

¿Podría hacer vibe coding de una versión de este proyecto? Probablemente no, pero quizá con suficiente tiempo y esfuerzo. ¿Podría descompilar y hacer que la IA construya una versión del software? De nuevo, quizá sí, pero quizá no. Lo que aprendí en mis años de negocio es que las necesidades de los gestores de empresa y de los analistas que usan este tipo de software son importantes. Las empresas suelen tener el peor software que uno pueda encontrarse. Hice mi carrera creando buen software para esas personas, porque sabía que merecían algo mejor. Hoy el software se ha vuelto tan malo que todo el mundo merece algo mejor.

Así que publiqué este software bajo la licencia MIT, para que, si quiere mejorarlo, no tenga que empezar desde cero. Es una base sólida para software de BI. Puede mejorar esto. Puede crear productos complementarios para esto. Espero que lo haga.

Paz y amor,
Michael

_3 de noviembre de 2026_
