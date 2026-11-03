---
layout: default
lang: es-419
---

## 8. Preguntas abiertas

1. **¿El almacén necesita ser de Core Data?** La definición que contiene es un
   grafo de objetos modesto. Un esquema escrito a mano en el mismo archivo SQLite eliminaría
   H3, eliminaría la última dependencia de Apple del formato y es un requisito previo para
   Windows, independientemente de lo que haga la CLI. Es una decisión de diseño para la
   migración de Core Data, no para este documento.
2. **¿Debería la miniatura estar en el documento?** Es regenerable, como la caché de
   filas, y es la única razón por la que existe `AdditionalContent/`. Eliminarla haría
   que todos los miembros de un `.mad` fueran autoritativos.
3. **¿Debería `.mad` llevar la caché de filas de forma opcional?** Una variante «empaquetada» haría que un
   documento se pudiera abrir sin conexión en un segundo dispositivo a costa del tamaño. Hoy nada hace
   esto; se plantea porque el nombre invita a esa expectativa (§5).
4. **¿Deberían los cambios de contenido invalidar la caché de renderizado?** Ahora respondido *mecánicamente*:
   la caché `.madac` se indexa por nombre de archivo y tamaño de página, sin hash de contenido, así que una
   edición del documento con el mismo nombre de archivo sirve páginas obsoletas hasta que se eliminan los archivos
   (§5.3). La parte abierta es una decisión de producto —*debería* una edición invalidarla— y el
   marco del propio usuario es que la caché es fundamental y no lo más urgente
   (§5.1). Así que esto queda registrado, no se está corrigiendo ahora.
