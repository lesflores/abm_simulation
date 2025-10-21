# 1) Preparación
   
**Paquete y semilla.**
`library(ABM)` carga la mini-infraestructura de simulación (agentes, eventos, contadores).

`set.seed(1)` fija aleatoriedad reproducible (para que tu experimento sea replicable).

# 2) Parámetros del modelo

`N = 5000:` número de hogares (1 agente = 1 hogar).

`Tmax = 36:` meses a simular.

`transfer_amount = 600:` monto nominal esperado.

`delay_prob_base = 0.30:` probabilidad de retraso (o sea, de no pago a tiempo).

`lambda_cred = 0.30:` qué tan rápido se ajusta la credibilidad con un promedio móvil (0=lento, 1=rapidísimo).

# 3) Construir el "mundo" y el estado inicial

`sim <- Simulation$new(N)` crea la simulación con IDs 1..N.

Estado principal del agente: "A" o "N".

Atributos por agente:

`theta:` umbral individual de decisión (heterogéneo, ~ Normal(300, 80)).

`cred:` credibilidad inicial = 1 − delay_prob_base (= 0.70).

**Seeding:** `seedA <- 10.` Los primeros 10 agentes arrancan asistiendo ("A") para no empezar con cero asistencia.

Bucle `for (i in 1:N):` para cada agente, se define theta, cred0 y el estado inicial; luego sim$setState(i, list(state0, theta=..., cred=...)).
Nota: en setState(...) el primer elemento de la lista siempre es el **estado**; lo demás son atributos.

# 4) Loggers (contadores automáticos)

`sim$addLogger(newCounter("A", "A")) y ("N","N")` crean dos columnas de salida que, en cada tick, cuentan cuántos están en A y cuántos en N.
Esto facilita luego calcular la proporción que asiste.

# 5) Dinámica mensual (el "handler" del tick)

- Qué es el handle que regresa `getAgent(sim, i):` Es una referencia al agente `i` que está dentro de `sim.` Con esa referencia puedes leer su estado `(getState(...))` y escribir cambios `(setState(...)).`

La función `tick_handler(time, sim, agent)` define qué pasa cada mes. Dentro:

**1. Recorres los N agentes** `(bucle for (i in 1:N)):`

- `ai <- getAgent(sim, i)` y `st <- getState(ai)` para leer estado y atributos actuales.

`st` la info actual del agente (estado, umbral, credibilidad) y trae tres cosas:

1. `st[[1]]` su estado: "A" (asiste) o "N" (no asiste)

2. `st$theta` su umbral para decidir (qué tanto beneficio necesita)

3. `st$cred` su credibilidad (0 a 1) sobre que el pago llegue a tiempo

- **Beneficio esperado** este mes: `benefit = transfer_amount * st$cred.`
Esto representa el valor esperado del pago: el monto nominal ($600) multiplicado por la probabilidad percibida de que el pago llegue a tiempo.
Así, si la credibilidad (cred) es alta, el hogar espera obtener más beneficio (porque confía en que sí cobrará); si es baja, el beneficio esperado disminuye, aunque el monto nominal sea el mismo.

- **Regla de decisión** mínima:
`new_state <- if (benefit >= st$theta) "A" else "N".`
El hogar asiste si el beneficio esperado supera su umbral.

- **Realización del pago a tiempo** (solo si decidió asistir):
`paid_on_time <- (new_state == "A") && (runif(1) > delay_prob_base).`

Es decir, tiras una moneda: con prob. 0.70 llega a tiempo; con 0.30 se retrasa.

Solo si el hogar asistió `(new_state == "A")` sorteas si el pago fue puntual.

`runif(1)` genera un número entre 0 y 1. Con `delay_prob_base = 0.30,` hay 70% de que sea puntual (número > 0.30).

Resultado: `paid_on_time` es TRUE (puntual) o FALSE (tardío).
(Si no asistió, la expresión completa da FALSE por el &&.)

- **Actualización de credibilidad** (EMA/promedio móvil exponencial): es una forma de actualizar un valor con el tiempo dando más peso a lo reciente y menos a lo pasado. Se llama "exponencial" porque el peso de lo ocurrido en meses anteriores se va haciendo cada vez más pequeño (decae exponencialmente) conforme pasa el tiempo. Lo controla un número entre 0 y 1 llamado lambda: p. ej., 0.1 cambias poco cada mes (recuerdas más el pasado); p. ej., 0.8 cambias mucho cada mes (te influye más lo reciente).
  
`cred_new <- (1 - lambda_cred) * st$cred + lambda_cred*as.numeric(paid_on_time)`

`st$cred` = credibilidad anterior (del mes pasado).

`as.numeric(paid_on_time)` convierte:

`TRUE` = 1 (pago puntual)

`FALSE` = 0 (pago tardío / no asistió

**Orden de operación:** 

1. Calcula el peso de ayer: `1 - lambda_cred.`

2. Multiplica ese peso por la credibilidad anterior: `(1 - lambda_cred) * st$cred.`

3. Convierte paid_on_time a número (1 o 0) y multiplícalo por el peso de hoy:
`lambda_cred * as.numeric(paid_on_time).`

4. Suma las dos partes. Eso es `cred_new.`

Si pagaron a tiempo (1), cred sube hacia 1.

Si se retrasó (0), cred baja hacia 0.

Importante: theta no cambia; es un rasgo fijo del hogar en este modelo.

- **Guardar nuevo estado y atributos:**
`setState(ai, list(new_state, theta = st$theta, cred = cred_new)).`

**2. Re-agendar el evento** para el próximo mes (si time < Tmax):
`schedule(agent, newEvent(time + 1, tick_handler)).`
Así, el mismo handler se ejecuta en t=1,2,…,Tmax.

# 6) Ejecutar la simulación

`schedule(sim$get, newEvent(0, tick_handler))` agenda el primer tick en t=0.

`res <- sim$run(0:Tmax)` corre todo y regresa un data.frame con: times (el mes); A y N (los contadores de asistencia/no asistencia).

Luego calculas la proporción que asiste:
`res$attend <- res$A / N.`

# Qué está modelando

- **Micro‐regla:** cada hogar decide A/N comparando su beneficio esperado `(monto * cred)` con su umbral `(theta).`

- **Aprendizaje:** la credibilidad se mueve según la experiencia reciente con el programa (pagos puntuales vs retrasos).

- **Efecto esperado:**

1. Si los pagos suelen llegar a tiempo (prob. alta de éxito), `cred` tenderá a subir y más hogares asistirán.

2. Si hay muchos retrasos, `cred` cae y la asistencia se erosiona.

3. `lambda_cred` controla cuán sensible es la credibilidad a experiencias recientes.

# Lectura de resultados

- Curva de `attend`: debería estabilizarse en algún nivel, subir o bajar según el balance entre el umbral promedio `(theta)` y la credibilidad endógena que se va formando por la puntualidad de pagos.

- `Con delay_prob_base = 0.30` (70% de puntualidad) y umbrales ~N(300,80) con `transfer_amount=600`, es razonable ver asistencia media-alta que quizá suba al inicio (la credibilidad parte en 0.70 y puede reforzarse si la suerte acompaña).
