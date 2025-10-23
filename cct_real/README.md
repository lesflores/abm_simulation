# Modelo ABM de Decisión Educativa con Transferencias Condicionadas

Este modelo basado en agentes (ABM) simula la **decisión mensual de los hogares** sobre la asistencia escolar de niñxs en el contexto de un programa de transferencias condicionadas.  

Cada hogar decide entre tres opciones:

-  **E**: Solo escuela  
- **ET**: Escuela y trabajo  
-  **T**: Solo trabajo  

El objetivo es analizar cómo **la elegibilidad, la credibilidad del programa, los costos y la puntualidad de los pagos** influyen en las trayectorias de asistencia escolar a lo largo del tiempo.

---

# 1) Parámetros del Programa

Los parámetros controlan el diseño del programa y el entorno de simulación:

| Parámetro | Descripción | Ejemplo |
|------------|-------------|----------|
| `poverty_line` | Línea de pobreza (eligibilidad por ingreso) | 4000 |
| `lambda_cred` | Velocidad de aprendizaje de la credibilidad | 0.10 |
| `delay_prob_base` | Probabilidad base de retraso en pagos | 0.30 |
| `cost_school` | Costo mensual de asistir a la escuela | 100 |

Además, se define una **estacionalidad mensual (`season_vec`)** que modifica la puntualidad del programa entre **−0.03 y +0.02** puntos porcentuales según el mes (por ejemplo, en marzo y abril los pagos son más tardíos).

---

# 2) Construcción de Variables Derivadas

A partir de la base `hogares`, se generan atributos individuales:

- **`elegible`**: TRUE si el ingreso < línea de pobreza.  
- **`cred0`**: Credibilidad inicial (70%, suponiendo 30% de retraso histórico).  
- **`theta`**: Umbral de decisión (mayor en zonas rurales).  
- **`salario_pot`**: Salario potencial estimado con un modelo tipo Mincer.  
- **`state0`**: Estado inicial (E=40%, ET=30%, T=30%).

Esto introduce **heterogeneidad inicial**, clave para evitar comportamientos idénticos entre agentes.

---

# 3) Inicialización de la Simulación

Cada hogar se carga como un agente con su propio estado y atributos mediante:

`sim <- Simulation$new(N)`
`sim$setState(i, list(...))`

# 4) Dinámica Mensual (`tick_handler`)

La función `tick_handler()` define qué ocurre **cada mes** (un “tick” del modelo).

---

## a) Puntualidad del Programa

Cada mes se genera `p_public_tick ∈ [0,1]`, la puntualidad promedio del programa, combinando:

- **Base:** `1 − delay_prob_base`
- **Estacionalidad:** meses mejores o peores (`season_vec`)
- **Política:** mejoras temporales (ej. meses 12–15 +10 p.p.)
- **Ruido:** choque aleatorio (`rnorm(1, 0, 0.02)`)

Los hogares rurales perciben entre **5 y 25 p.p. menos de puntualidad**:

`p_public <- if (st$zona == "rural") p_public_tick - 0.25 else p_public_tick`

## b) Utilidades de Cada Opción

Cada hogar calcula la utilidad esperada de tres decisiones posibles:

| Opción | Fórmula | Intuición |
|--------|----------|-----------|
| `U_E`  | `(transfer_eff * cred) - cost_school - theta` | Escuela completa: recibe la transferencia esperada, paga el costo total y enfrenta la barrera de asistencia. |
| `U_ET` | `(transfer_eff/2) + (w_child*0.5) - (cost_school/2) - (0.5*theta)` | Escuela + trabajo: recibe y paga la mitad, enfrenta barrera parcial. |
| `U_T`  | `w_child` | Solo trabajo: sin transferencia ni costo, pero con ingreso laboral completo. |

---

## c) Elección Probabilística (Softmax)

En lugar de que todos elijan la opción con mayor utilidad (`which.max()`), se usa una elección probabilística tipo **logit/softmax**:

`tau <- 200`
`u_center <- utilities - max(utilities)`
`probs <- exp(u_center / tau)`
`probs <- probs / sum(probs)`
`new_state <- sample(c("E", "ET", "T"), size = 1, prob = probs)`

### Interpretación del parámetro `tau`

`tau` controla la **“temperatura”** o nivel de aleatoriedad en las decisiones:

- τ **pequeño**: decisiones más deterministas.  
- τ **grande**: más mezcla y variabilidad.  

El comando:

`sample(..., prob = probs)`


### Control de la Temperatura (`tau`)

`tau` controla la **temperatura** o nivel de aleatoriedad en las decisiones del hogar:

- τ **pequeño** → decisiones más deterministas.  
- τ **grande** → más mezcla y variabilidad.  

---

## d) Actualización de la Credibilidad

La credibilidad (`cred`) se ajusta según la experiencia del hogar:

`if (new_state %in% c("E", "ET") && st$elegible) {
  paid_on_time <- runif(1) < p_public
  cred_new <- (1 - lambda_cred) * st$cred + lambda_cred * as.numeric(paid_on_time)
} else {
  cred_new <- (1 - lambda_cred) * st$cred + lambda_cred * p_public_tick
}`

### Actualización de la Credibilidad

- Si **participa y es elegible**, aprende de su propio pago (*experiencia directa*).  
- Si **no participa**, actualiza su credibilidad según la **señal pública del mes** (`p_public_tick`).

---

## e) Guardar Estado y Reagendar

Cada agente actualiza su estado (`E`, `ET` o `T`) y sus atributos persistentes (edad, zona, etc.).  
Luego, la función reagenda el siguiente mes:

`if (time < Tmax) schedule(agent, newEvent(time + 1, tick_handler))`

## 5) Ejecución

Se agregan contadores y se corre la simulación:

`sim$addLogger(newCounter("E", "E"))`
`sim$addLogger(newCounter("ET", "ET"))`
`sim$addLogger(newCounter("T", "T"))`

`schedule(sim$get, newEvent(0, tick_handler))`
`res <- sim$run(0:Tmax)`
`res$attend <- (res$E + res$ET) / N`

## Interpretación

- Si la **puntualidad mejora**, la asistencia aumenta (por credibilidad y transferencias efectivas).  
- Si los **costos escolares suben**, la asistencia cae (más hogares migran a `ET` o `T`).  
- Si `tau` es **bajo**, el sistema se vuelve determinista (menos variabilidad).  
- La **credibilidad** modera la respuesta del hogar: a menor `cred`, menor peso a la transferencia.

---

## Conceptual

El modelo integra tres dimensiones:

1. **Económica:** decisiones según utilidad esperada.  
2. **Cognitiva:** aprendizaje de credibilidad (`lambda_cred`).  
3. **Contextual:** estacionalidad y diferencias rural/urbano.

Permite explorar políticas como:

- Incrementos temporales en la puntualidad.  
- Choques negativos (*crisis presupuestal*).  
- Diferencias de respuesta según zona o ingreso.
