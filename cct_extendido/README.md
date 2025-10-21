# Propósito del modelo

**Cómo los hogares deciden cada mes si:**

- Mandan a sus hijxs solo a la escuela (E),

- Mandan a la escuela y además trabajan (ET), o

- Solo trabajan (T),
dependiendo de los incentivos del programa, los costos, los ingresos, la credibilidad y el contexto.

# Qué representa cada componente

## 1. Población

- `N = 5000:` son 5000 hogares (cada uno con al menos un niño o niña en edad escolar).

- Cada hogar es un **agente** que decide cada mes qué hacer **(E / ET / T).**

## 2. Programa de Transferencias Condicionadas (CCT)

- `base_transfer_per_child = 500:` el monto por hijx elegible si cumple la condición (asistir a la escuela).

- `max_children_paid = 2:` si tienen más hijxs, solo 2 reciben el pago (como límite de apoyo).

`poverty_line = 4500:` solo hogares con ingreso menor a esta línea son elegibles.

Es decir:

El beneficio depende del número de hijxs, pero solo si son pobres y cumplen la asistencia.

## 3. Características del hogar

Cada hogar tiene atributos que afectan sus decisiones:

- `n_hijos:` cantidad de hijxs (0 a 3).

- `Y_hogar:` ingreso base del hogar (sin incluir la transferencia).

- `elegible:` TRUE si está por debajo de la línea de pobreza.

- `edad, grado, sexo, zona:` características del niño/niña mayor, que influyen en el salario potencial y el umbral (por ejemplo, zonas rurales enfrentan más barreras).

- `theta:` umbral individual para decidir (qué tanto beneficio necesita para convencerse de asistir).

- `cred:` credibilidad en el pago puntual (entre 0 y 1).

## 4. Dinámica mensual

Cada mes (tick):

1. Calcula beneficios esperados:

- Si el hogar es elegible, el pago depende de sus hijxs cubiertos `(base_transfer_per_child * hijos_cubiertos).`

- Pero solo lo valora según su credibilidad `(st$cred),` o sea, si cree que el pago sí llegará.

2. Calcula salario potencial `(w_child):`

- Según la edad y grado (modelo tipo Mincer), un niño mayor o con más estudios gana más si trabaja.

3. Evalúa tres opciones:

- **E:** solo escuela - > gana la transferencia, paga el costo escolar.

- **ET:** escuela + trabajo - > mitad de transferencia, mitad del salario, mitad del costo.

- **T:** solo trabajo - > gana el salario completo.

Cada hogar calcula una utilidad esperada (U_E, U_ET, U_T) y elige la mayor:

`utilities <- c(E = U_E, ET = U_ET, T = U_T)
new_state <- names(which.max(utilities))`

4. Decide su nuevo estado (E, ET o T).

5. Simula si el pago fue puntual (prob. 70%):

`paid_on_time <- (new_state %in% c("E", "ET")) && (runif(1) > delay_prob_base)`

6. Actualiza su credibilidad (aprendizaje EMA):
   - Si el pago llegó, la credibilidad sube.
   - Si se retrasó, baja.
   - Este aprendizaje gradual se controla con lambda_cred.
  
# Qué produce el modelo

Cada fila de res es un mes (t = 0, 1, 2, …, 36), y tiene:
  
| Columna  | Significado                                     |
| -------- | ----------------------------------------------- |
| `times`  | Mes de la simulación                            |
| `E`      | Hogares con hijxs que solo estudian             |
| `ET`     | Hogares con hijxs que estudian y trabajan       |
| `T`      | Hogares con hijxs que solo trabajan             |
| `attend` | % de hogares con hijxs escolarizados = (E+ET)/N |

# Qué representa la gráfica

Muestra la proporción de hogares con hijxs que estudian (E+ET) a lo largo de los meses.

Interpreta así:

- Si la línea sube - > más hogares eligen la escuela (mejor desempeño educativo).

- Si baja - > más hogares abandonan la escuela o eligen solo trabajo.

- Si se estabiliza - >  equilibrio del sistema (steady state).

Es un modelo basado en agentes donde los hogares:

- Aprenden y ajustan su confianza en el programa (credibilidad);

- Deciden racionalmente entre educación y trabajo infantil según:

    - montos de beca,
    - ingresos,
    - costos,
    - credibilidad,
    - y contexto rural/urbano.

Se está reproduciendo, a nivel micro, cómo un programa de transferencias condicionadas puede modificar las tasas de escolarización y trabajo infantil bajo distintos escenarios socioeconómicos.
