# Checklist ético y legal

Diez preguntas para responder **antes** de escribir el scraper, no después.

> Esto es material de formación metodológica, no asesoramiento legal. Si tu proyecto toca
> datos personales, contenido protegido o una fuente que prohíbe expresamente la extracción,
> consultá con el área legal de tu institución y con tu comité de ética. Ese trámite es parte
> del método, igual que un consentimiento informado.

---

## El punto de partida

**Público no quiere decir libre.**

Que un dato esté visible sin contraseña no significa que puedas recolectarlo, guardarlo,
cruzarlo y publicarlo. Son cuatro acciones distintas y cada una tiene sus condiciones.

Hay tres planos que se suelen confundir, y conviene separarlos:

| Plano | Qué regula | Quién decide |
|---|---|---|
| **Técnico** | Si podés acceder | El servidor (códigos 200, 403, 429) |
| **Contractual** | Si te dejan | Los términos de uso del sitio |
| **Legal** | Si corresponde | La ley (datos personales, propiedad intelectual) |

Los tres pueden decir cosas distintas. Un sitio puede dejarte pasar técnicamente, prohibirlo
en sus términos, y contener datos que la ley protege. Los tres importan.

---

## Las diez preguntas

### 1. ¿Existe una vía oficial para este dato?

API pública, portal de datos abiertos, archivo descargable, sitemap XML, pedido de acceso a
la información pública. Si existe, usala: es más estable, más rápida y no hay nada que discutir.

**Si no la buscaste, todavía no empezaste el proyecto.**

### 2. ¿Qué dice el `robots.txt`?

No es una ley ni un candado: es una declaración de intención. Pero si vas a ignorar un
`Disallow`, tenés que poder explicar por qué — ante un revisor, ante un comité, ante vos.

### 3. ¿Qué dicen los términos de uso?

Muchos sitios los prohíben explícitamente. Eso los convierte en una cuestión contractual,
no solo de buenos modales. Leelos. Guardá una copia con la fecha: pueden cambiar.

### 4. ¿Hay datos personales?

En Argentina rige la **Ley 25.326 de Protección de Datos Personales**. Un nombre, un correo,
un teléfono, un usuario de red social, un domicilio son datos personales aunque estén
publicados en una web abierta.

Y hay una categoría más exigente, los **datos sensibles** (art. 7): origen racial o étnico,
opiniones políticas, convicciones religiosas o filosóficas, afiliación sindical, y datos
referentes a la salud o a la vida sexual.

Si tu corpus los toca, la conversación cambia de nivel. No es un detalle a resolver después.

### 5. ¿Podés trabajar con menos datos?

El mejor manejo de un dato sensible es no recolectarlo.

- ¿Te alcanza con el agregado en vez del caso individual?
- ¿Podés seudonimizar en el momento de la recolección, y no después?
- ¿Necesitás el nombre, o te alcanza con un identificador?

Recolectar "por las dudas" es lo contrario de un diseño metodológico.

### 6. ¿Quién produjo el contenido y qué derechos tiene?

Los textos periodísticos, las fotos y las bases de datos tienen autor. Para investigación
suele haber margen, pero **redistribuir el corpus crudo no es lo mismo que analizarlo**.

Regla práctica: publicá tus resultados y tu código; para el corpus, publicá metadatos, URLs y
el método de reconstrucción antes que los textos completos.

### 7. ¿Qué carga le estás poniendo al servidor?

Hacé la cuenta antes: cantidad de pedidos por la pausa entre pedidos. Un scraper educado hace
en una hora lo que uno apurado hace en un minuto — y el segundo puede degradar el servicio de
un organismo público que atiende a gente real.

Pausas, caché local, horarios de baja demanda. No cuesta nada.

### 8. ¿Te identificás?

Un `User-Agent` con tu proyecto y un correo de contacto convierte tu scraper en alguien
localizable. Si molestás, te escriben antes de bloquearte. Si necesitás más acceso, ya saben
quién sos.

El anonimato acá no protege: complica.

### 9. ¿Podrías explicar públicamente lo que hiciste?

La prueba más simple y la más dura. Si te incomoda escribir en el apartado metodológico
exactamente cómo obtuviste los datos, el problema no es de redacción.

Un método que no se puede describir no es un método.

### 10. ¿Qué pasa si el sitio dice que no?

Un `403`, un CAPTCHA o una cláusula explícita son una respuesta, no un obstáculo técnico.

**Este curso no enseña a sortearlas.** No por timidez: porque en ese punto el problema deja
de ser técnico. Las salidas reales son otras:

- Buscar la misma información en otra fuente.
- Pedir acceso formalmente, como institución.
- Solicitar información pública, si es un organismo del Estado.
- Reformular la pregunta de investigación con los datos que sí podés obtener.

La cuarta opción se subestima. A veces la pregunta mejora.

---

## Tres casos del curso

### `computrabajo.com` — la puerta cerrada

Devuelve **403 hasta para su propio `robots.txt`**. No atiende programas automáticos, y está
en su derecho.

Insistir con más técnica es empujar una puerta cerrada: frágil, caro y difícil de sostener
en un informe.

### `zonajobs.com.ar` — la puerta abierta con cartel

`robots.txt` permisivo y **cinco sitemaps XML publicados**: listados de URLs que el propio
sitio ofrece para que los programas los recorran.

Mismo rubro, mismo tipo de dato, decisión opuesta. **Elegir bien la fuente es parte del
método**, no un detalle técnico.

### `archivopolitico.com` — el matiz

Su `robots.txt` dice `Allow: /` pero `Disallow: /data/` y `Disallow: /*.json$`.

Traducido: *"leé mis páginas, no te lleves mi base de datos."* El sitio distingue entre
consultar su contenido y apropiarse de su trabajo de compilación.

Es un pedido razonable y bastante frecuente en archivos y repositorios. Ante un caso así,
lo que corresponde es escribir y pedir: quien armó ese archivo suele estar dispuesto a
colaborar con una investigación que lo cite.

### Y un caso sin matices: las redes sociales

Facebook, Instagram y X requieren inicio de sesión y prohíben la extracción en sus términos.
Scrapear con una cuenta propia agrega un incumplimiento contractual sobre otro.

Las alternativas reales:

- Las APIs oficiales, con sus límites y sus costos.
- Programas de acceso académico, cuando existen.
- Repositorios de corpus ya recolectados y publicados por otros equipos.
- Reformular hacia fuentes abiertas: prensa, boletines oficiales, foros públicos.

Freelon (2018), *Computational Research in the Post-API Age*, discute exactamente este
callejón. Vale la pena leerlo antes de decidir.

---

## Para escribir en tu apartado metodológico

Si podés completar estas seis líneas, tu recolección está documentada:

1. **Fuente**: URL exacta y qué es ese sitio.
2. **Período**: fechas de recolección, no de publicación del contenido.
3. **Criterio**: qué se incluyó, qué se excluyó y por qué.
4. **Herramienta**: R, paquetes y versiones. Código disponible en (repositorio).
5. **Volumen**: registros obtenidos, y cuántos se descartaron en la limpieza.
6. **Limitaciones**: qué no pudiste obtener y por qué.

El punto 6 es el que más se omite y el que más credibilidad da.

---

## Referencias

- **Ley 25.326** de Protección de Datos Personales (Argentina) —
  https://servicios.infoleg.gob.ar/infolegInternet/anexos/60000-64999/64790/norma.htm
- **Ley 27.275** de Acceso a la Información Pública —
  https://servicios.infoleg.gob.ar/infolegInternet/anexos/265000-269999/265949/norma.htm
- Luscombe, Dick & Walby (2022). *Algorithmic thinking in the public interest.*
  Quality & Quantity, 56(3), 3073–3093.
- Freelon (2018). *Computational Research in the Post-API Age.*
  Political Communication, 35(4), 665–668.
- Salganik (2018). *Bit by Bit: Social Research in the Digital Age.* Cap. 6: Ética.
