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
