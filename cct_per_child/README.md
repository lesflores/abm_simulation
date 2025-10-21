# Simulación ABM con elegibilidad por pobreza y transferencias por hijo
# 1) Preparación

**Paquete y semilla**

- `library(ABM)` carga la mini-infraestructura de simulación: define agentes, eventos y contadores.

- `set.seed(1)` asegura que la aleatoriedad sea reproducible, es decir, obtendrás los mismos resultados cada vez que corras la simulación.

# 2) Parámetros del modelo

- `N = 5000:` número de hogares simulados (cada agente representa un hogar).

- `Tmax = 36:` duración de la simulación en meses (3 años).

- `delay_prob_base = 0.30:` probabilidad de retraso en el pago (30% de los meses no llega a tiempo).

- `lambda_cred = 0.30:` ritmo de aprendizaje de la credibilidad (0 = olvida lento, 1 = muy reactivo).

- `base_transfer_per_child = 300:` monto base mensual por hijx elegible.

- `max_children_paid = 2:` máximo de hijxs cubiertos por hogar.

- `poverty_line = 4500:` umbral de ingreso (en pesos) para determinar elegibilidad al programa.

# 3) Crear la simulación y el estado inicial

- `Simulation$new(N)` crea el "mundo" con N agentes numerados del 1 al N.

- `seedA <- 10:` número de hogares que comienzan asistiendo (A) para evitar que todos empiecen en N.

**Bucle de inicialización**

- `theta:` umbral individual de decisión (cuánto beneficio necesita un hogar para asistir); distribuido ~ Normal(300, 80).

- `cred0:` credibilidad inicial (0.70 si probabilidad de pago puntual = 70%).

- `state0:` estado inicial (A = asiste, N = no asiste).

- `n_hijos:` número de hijxs beneficiarios potenciales (0–3, con probabilidades dadas).

- `Y_hogar:` ingreso del hogar sin transferencias; modelado lognormal para simular desigualdad.

- `elegible:` TRUE si el ingreso está por debajo de la línea de pobreza; FALSE si no.

- `sim$setState(...):` guarda todos los atributos dentro del agente.

Nota: el primer elemento de la lista (state0) siempre es el estado del agente; los demás son atributos.

# 4) Loggers (contadores automáticos)

`sim$addLogger(newCounter("A", "A"))`
`sim$addLogger(newCounter("N", "N"))`

- Crea dos columnas `(A y N)` que cuentan, en cada mes `(tick),` cuántos hogares están asistiendo o no.

- Luego, se usa para calcular proporciones `(res$attend = res$A / N).`

# 5) Dinámica mensual (el "handler" del tick)

La función `tick_handler(time, sim, agent)` describe **qué ocurre cada mes.**

- `getAgent(sim, i)` devuelve el handle (referencia) del agente i.

- `getState(ai)` devuelve su estado actual `(st[[1]])` y atributos `(st$theta, st$cred, st$n_hijos,` etc.).

**a. Cálculo del beneficio esperado**

`hijos_cubiertos <- min(st$n_hijos, max_children_paid)
transfer_eff    <- if (st$elegible) base_transfer_per_child * hijos_cubiertos else 0
benefit         <- transfer_eff * st$cred`

- Si el hogar es elegible, recibe la transferencia base × número de hijos cubiertos (hasta el límite).

- Si no es elegible, `transfer_eff = 0.`

- El beneficio esperado es esa cantidad multiplicada por la credibilidad (probabilidad percibida de que el pago llegue). Si el hogar desconfía (cred baja), su beneficio esperado es menor, aunque el monto sea alto.

**b. Decisión de asistencia**

`new_state <- if (benefit >= st$theta) "A" else "N"`

- Si el beneficio esperado supera el umbral `(theta),` el hogar decide asistir (A).

- Si no, se queda en N.

**c. Pago puntual o retrasado**

`paid_on_time <- (new_state == "A") && (runif(1) > delay_prob_base)`

- Si asiste, se lanza una moneda (runif(1) genera un número 0–1):
    - Mayor a 0.30: pago puntual (TRUE)
    - Menor a 0.30: pago retrasado (FALSE)
    Nota: la probabilidad de pago puntual es 70%, 
- Si no asiste, no se evalúa el pago (queda FALSE).

**d. Actualización de credibilidad**

`cred_new <- (1 - lambda_cred) * st$cred + lambda_cred * as.numeric(paid_on_time)`

- EMA (promedio móvil exponencial): actualiza la credibilidad dando más peso a lo reciente.

- `lambda_cred = 0.3` la experiencia del mes afecta un 30% del valor nuevo.

- Si el pago fue puntual `(paid_on_time = TRUE → 1), cred_new` sube hacia 1;
si fue tardío `(FALSE - > 0),` baja hacia 0.

- Ejemplo:
   - cred pasada = 0.70; pago puntual - > cred_new = 0.7×0.7 + 0.3×1 = 0.79
   - cred pasada = 0.79; pago tardío - > cred_new = 0.7×0.79 + 0.3×0 = 0.55
 
**e. Guardar estado actualizado**

- `new_state:` A/N del mes actual

- `theta:` no cambia

- `cred_new:` credibilidad actualizada

- `n_hijos, Y_hogar, elegible:` atributos fijos por ahora

**f. Re-agendar evento**

`if (time < Tmax) schedule(agent, newEvent(time + 1, tick_handler))`

- Agenda el mismo proceso para el siguiente mes `(t+1).`

- Así, la simulación se repite hasta `Tmax.`

# 6) Ejecutar la simulación

- `schedule(sim$get, ...)` lanza la primera ejecución en t=0.

- `sim$run(0:Tmax)` ejecuta toda la simulación y devuelve un data.frame con:
   - `time:` el mes
   - `A y N:` los contadores de asistencia/no asistencia
- `res$attend:` proporción de hogares que asistieron en cada mes.

# Qué modela esta versión

- **Heterogeneidad:** cada hogar tiene diferente umbral `(theta),` ingreso `(Y_hogar),` y número de hijxs `(n_hijos).`
- **Elegibilidad:** solo los hogares bajo la línea de pobreza reciben transferencias.
- **Condicionalidad:** la asistencia depende del beneficio esperado y de la credibilidad en los pagos.
- **Aprendizaje:** la credibilidad se ajusta mes a mes según experiencias previas (puntualidad de pagos).

# Interpretación esperada

- Los hogares no elegibles (con ingresos > pobreza_line) nunca recibirán transferencias, por lo que tenderán a no asistir.
- Los hogares más pobres y con más hijxs tendrán un beneficio esperado mayor - > mayor probabilidad de asistir.
- Si los pagos suelen llegar puntuales, la credibilidad crece y la asistencia se mantiene o sube.
- Si hay muchos retrasos, la credibilidad cae y la asistencia disminuye.
