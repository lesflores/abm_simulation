# cct_simple · Umbral + credibilidad

Modelo mínimo de un programa de transferencias condicionadas (CCT) a la asistencia escolar. Cada hogar decide cada mes si manda a sus hijxs a la escuela comparando cuánto espera recibir del programa con su umbral personal. Lo que espera recibir depende de su credibilidad, es decir, de cuánto confía en que el pago llegará a tiempo, y esa credibilidad se aprende con la experiencia.

Es el modelo de la sesión 1. Sirve para aprender la estructura del paquete `ABM` y para una lección central del curso: **antes de interpretar una gráfica, hay que verificar si el patrón viene del mundo o de un supuesto del código.**

# 1) Preparación

**Paquetes y semilla.**
`library(ABM)` carga la infraestructura de simulación (agentes, eventos, contadores) y `library(ggplot2)` el gráfico.

`set.seed(1)` fija la aleatoriedad para que el experimento sea reproducible: todos obtienen la misma curva.

# 2) Parámetros del modelo

`N = 5000`: número de hogares (1 agente = 1 hogar).

`Tmax = 36`: meses a simular.

`transfer_amount = 600`: monto nominal mensual.

`delay_prob_base = 0.30`: probabilidad de que el pago llegue tarde.

`lambda_cred = 0.30`: qué tan rápido se ajusta la credibilidad (0 = lento, 1 = muy rápido).

**Interruptores:**

`senal_publica = FALSE`: qué señal recibe un hogar que **no** asiste.
- `FALSE` (regla original): su señal es 0, como si el pago hubiera llegado tarde.
- `TRUE` (corrección): recibe la señal pública `1 - delay_prob_base`, es decir, lo que se sabe en su comunidad sobre la puntualidad del programa.

`con_trabajo = FALSE`: si es `TRUE`, una proporción `prop_trabajo = 0.40` de los hogares tiene un hijo que trabaja y nunca asiste. Es el ejercicio de tarea.

# 3) Construir el "mundo" y el estado inicial

`sim <- Simulation$new(N)` crea la simulación con IDs 1..N.

Estado principal del agente: "A" (asiste) o "N" (no asiste).

Atributos por agente:

`theta`: umbral individual de decisión (heterogéneo, ~ Normal(300, 80)). Representa todo lo que le cuesta al hogar cumplir con la escuela, expresado en pesos.

`cred`: credibilidad inicial = 1 − `delay_prob_base` (= 0.70).

`trabaja`: `TRUE` si el hogar tiene un hijo que trabaja (solo si `con_trabajo = TRUE`).

**Seeding:** `seedA <- 10`. Los primeros 10 agentes arrancan en "A". Esto **no cambia el resultado**: la regla de decisión no mira el estado anterior del hogar, solo su credibilidad y su umbral. Únicamente mueve el primer punto de la gráfica.

Nota: en `setState(...)` el primer elemento de la lista siempre es el **estado**; lo demás son atributos con nombre.

# 4) Loggers (contadores automáticos)

`sim$addLogger(newCounter("A", "A"))` y `("N", "N")` crean dos columnas de salida que, en cada tick, cuentan cuántos hogares están en A y cuántos en N.

En versiones recientes del paquete puede aparecer un aviso de que `newCounter()` está obsoleto. Es solo una advertencia: el modelo corre bien.

# 5) Dinámica mensual (el "handler" del tick)

La función `tick_handler(time, sim, agent)` define qué pasa cada mes. Para cada hogar sigue el patrón **leer → decidir → escribir**.

**Leer.** `ai <- getAgent(sim, i)` da una referencia al agente i; `st <- getState(ai)` trae su ficha:

1. `st[[1]]`: su estado, "A" o "N"
2. `st$theta`: su umbral
3. `st$cred`: su credibilidad (0 a 1)
4. `st$trabaja`: si tiene un hijx que trabaja

**Decidir.**

- **Beneficio esperado:** `benefit = transfer_amount * st$cred`. Es el monto nominal multiplicado por la probabilidad percibida de que el pago llegue a tiempo. Si la credibilidad es alta, el hogar espera más; si es baja, espera menos aunque el monto sea el mismo.
- **Regla de decisión:** asiste si `benefit >= st$theta`. Si `trabaja` es `TRUE`, no asiste.

**Señal del mes.** Es lo que el hogar observa sobre la puntualidad del programa:

- Si asistió, observa su propio pago: `runif(1) > delay_prob_base` es 1 (puntual, con probabilidad 0.70) o 0 (tarde, con probabilidad 0.30).
- Si no asistió y `senal_publica = FALSE`, su señal es **0**. Ojo: esto significa que no asistir cuenta como un retraso. La credibilidad de quien sale cae cada mes, su beneficio esperado nunca vuelve a superar su umbral y ya no regresa. En términos técnicos, no asistir es un **estado absorbente**.
- Si no asistió y `senal_publica = TRUE`, su señal es `1 - delay_prob_base`. No ve su propio pago, pero sabe cómo funciona el programa en su comunidad, y puede volver a asistir cuando su credibilidad se recupera.

**Actualización de credibilidad** (promedio móvil exponencial):

`cred_new <- (1 - lambda_cred) * st$cred + lambda_cred * senal`

Da más peso a lo reciente y menos a lo pasado; el peso de los meses anteriores decae exponencialmente. Con `lambda_cred = 0.1` la credibilidad cambia poco cada mes; con `0.8` cambia mucho. Si la señal es 1, la credibilidad sube hacia 1; si es 0, baja hacia 0.

`theta` no cambia: es un rasgo fijo del hogar en este modelo.

**Escribir.** `setState(ai, list(new_state, theta = st$theta, cred = cred_new, trabaja = st$trabaja))`. `setState` reemplaza la ficha completa: si se omite un atributo, desaparece. Por eso se vuelven a escribir `theta` y `trabaja` aunque no cambien.

**Re-agendar** para el próximo mes: `if (time < Tmax) schedule(agent, newEvent(time + 1, tick_handler))`. Esta línea es la que hace avanzar el reloj; sin ella, la simulación corre un solo mes.

# 6) Ejecutar la simulación

`schedule(sim$get, newEvent(0, tick_handler))` agenda el primer tick en t = 0.

`res <- sim$run(0:Tmax)` corre todo y regresa un data.frame con `times` (el mes), `A` y `N` (los contadores).

`res$attend <- res$A / N` calcula la proporción que asiste.

El punto de `times = 0` es el **estado inicial**, antes de la primera decisión. Por eso la gráfica arranca casi en cero y salta en el mes 1.

# Qué está modelando

- **Micro-regla:** cada hogar decide A/N comparando su beneficio esperado (`monto * cred`) con su umbral (`theta`).
- **Aprendizaje:** la credibilidad se mueve según la experiencia reciente con el programa.
- **Supuestos que conviene tener presentes:** el hogar es miope (solo mira la transferencia de este mes, no los beneficios futuros de estudiar); un pago tarde se trata como si no hubiera llegado; y el umbral reúne en un solo número, en pesos, costos que no son dinero (tiempo, transporte, trabajo infantil).

# Lectura de resultados

Resultados con `set.seed(1)` y los parámetros base (proporción que asiste):

| Configuración | Mes 1 | Mes 12 | Mes 36 |
| --- | --- | --- | --- |
| Regla original (`senal_publica = FALSE`) | 0.93 | 0.38 | 0.14 |
| Con señal pública (`senal_publica = TRUE`) | 0.93 | 0.77 | 0.76 |
| Regla original + `con_trabajo = TRUE` | 0.56 | 0.23 | 0.09 |
| Señal pública + `con_trabajo = TRUE` | 0.56 | 0.46 | 0.46 |

- **Con la regla original**, la asistencia cae sin estabilizarse, sin importar qué tan puntual sea el programa: los parámetros solo cambian la velocidad de la caída. No es un hallazgo sobre los hogares, sino una consecuencia de tratar la no asistencia como un retraso.
- **Con señal pública**, la asistencia se estabiliza desde el mes 3, y la puntualidad sí cambia el nivel: con `delay_prob_base = 0.10` se queda cerca de 97%, y con `0.50` cerca de 30%.
- `lambda_cred` sí cambia el nivel en la versión corregida (más alto, menos asistencia), porque la regla de umbral es abrupta: con λ alto, un solo retraso basta para que un hogar cercano a su umbral deje de asistir ese mes.
