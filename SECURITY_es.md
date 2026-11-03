[English](SECURITY.md) | [简体中文](SECURITY_zh.md) | [日本語](SECURITY_ja.md) | [Português (Brasil)](SECURITY_pt-BR.md) | [Deutsch](SECURITY_de.md) | **Español**

# Política de seguridad

## Versiones compatibles

Solo la última versión recibe correcciones de seguridad. El proyecto aún no ha hecho una
versión pública; una vez la tenga, todo lo anterior a la última versión queda
sin soporte y se espera que los usuarios actualicen.

| Versión | Compatible |
|---|---|
| última versión | :white_check_mark: |
| todo lo anterior | :x: |

## Qué está dentro del alcance

* El motor y sus frameworks: el lector y escritor de `.mad`, el compilador de
  consultas, los renderizadores, los drivers (MySQL, SQL Server, SQLite) y la
  CLI `mad`.
* La propia aplicación, en las partes accesibles desde un documento o una conexión:
  el análisis de documentos, el almacenamiento de credenciales y todo lo que reciba como entrada
  una respuesta de servidor o un archivo.

Recuerde el modelo de confianza: un documento `.mad` contiene una consulta, y
abrir uno es elegir ejecutar un informe: el formato es una definición, no
código en sandbox, y nunca se ejecuta código dentro de un documento.

## Informar de una vulnerabilidad

**No abra un issue público.** Informe de forma privada:

* Una vez que el repositorio esté publicado: use el flujo **Report a vulnerability** de GitHub
  (**Security → Advisories**), que mantiene el informe confidencial y
  nos permite publicar un aviso con su crédito cuando llegue la corrección.
* Hasta entonces, póngase en contacto directamente con el mantenedor.

Incluya, si puede: el componente y la versión afectados, un reproductor mínimo
o el documento/consulta que lo desencadena, y el impacto que espera. Recibirá
un acuse de recibo en el plazo de una semana y una corrección o una evaluación por escrito tan
pronto como exista.

## Expectativas

No hay recompensa por errores. El proyecto es el esfuerzo de un mantenedor solitario; lo que
obtiene es una corrección rápida y acreditada y un aviso por escrito. Se presupone la divulgación
responsable (el informe permanece privado hasta que se publica una corrección), y el aviso
nombra a los informantes que desean ser nombrados.

## Compromisos aceptados y conocidos

Estas son decisiones de diseño, no errores que se puedan informar: están documentadas en
la especificación y en el registro de errores, y cambiarlas es una decisión de producto:

* El contenedor `.mad` aún no tiene bytes mágicos (`docs/06-hazards.md`, riesgo
  H1); en el formato distribuido la detección es por extensión, con bytes mágicos en
  la `v1` normativa.
* La caché de renderizado se indexa por nombre de archivo y tamaño de página, no por contenido
  (`docs/05-companion-files.md` §5.3), así que editar un documento con el mismo
  nombre puede servir páginas obsoletas hasta que se eliminen los archivos de caché.
* Las credenciales de base de datos de las suites de prueba en
  [`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md) son credenciales desechables
  de Docker local, no secretos de producción.
