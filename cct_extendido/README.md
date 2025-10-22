# Código AMB - CCT extendido 

## Estructura
**1. setState:** Crea cada agente y le asigna estado y atributos (lo que va a cargar durante toda la simulación). En el código: dentro del for (i in 1:N) se llama a:

`sim$setState(i, list(state0, theta=..., cred=..., n_hijos=..., ...))`

El primer elemento de la lista es el estado (“E”, “ET” o “T”). El resto son atributos (θ, credibilidad, zona, edad, etc.).

**2. addLogger:** Conecta sensores al simulador. Son funciones que, en cada tiempo, calculan y guardan métricas (conteos, medias, etc.). En el código:

`sim$addLogger(newCounter("E", "E"))
sim$addLogger(newCounter("ET", "ET"))
sim$addLogger(newCounter("T", "T"))`

Cada uno contará cuántos agentes están en ese estado en cada mes.

**Resultado:** cuando termina run, se obtiene un data frame `res` con columnas times, E, ET, T (etc..).

**4. tick_handler:** Es la regla de actualización. Aquí se define cómo pasan las cosas del mes *t* al mes *t+1.* En el código:

Se Recorren agentes `(for (i in 1:N)),` se lee estado/atributos `(getState),` se calcula utilidades `U_E, U_ET, U_T,` se elige el `new_state,` se actualiza `cred (EMA),` y se guarda con `setState(ai, list(new_state, ...)).`Qué hace: agenda eventos para que el motor llame tu tick_handler en los tiempos que tú digas.

Aquí ocurre la inteligencia del modelo (decisión E/ET/T + aprendizaje de credibilidad).

**Patrón mental:** *leer* - > *decidir* - > *escribir* para cada agente, en cada tick.

**5. scheduler:** Agenda eventos para que el motor llame `tick_handler` en los tiempos que se establezcan.

**6. run**: Corre el *event loop* desde el primer evento programado (el tick 0) hasta que ya no queden eventos (o se alcance Tmax). En el código:

`res <- sim$run(0:Tmax)`

El resultado `res` es una serie temporal con lo que los `loggers` midieron en cada mes `(E, ET, T,` etc.). Luego se crean métricas derivadas como `attend, rate_E,` etc.

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

- `poverty_line = 4500:` solo hogares con ingreso menor a esta línea son elegibles.

Es decir:

El beneficio depende del número de hijxs, pero solo si son pobres y cumplen la asistencia.

### hasta aquí: 

| Categoría      | Parámetro                                                      | Sig                                 |
| -------------- | -------------------------------------------------------------- | ----------------------------------- |
| Escenario      | `N`, `Tmax`                                                    | Tamaño y duración                   |
| Programa       | `base_transfer_per_child`, `max_children_paid`, `poverty_line` | Diseño de la transferencia          |
| Comportamiento | `delay_prob_base`, `lambda_cred`                               | Credibilidad y cumplimiento         |
| Socioeconómico | `beta_age`, `beta_school`, `cost_school`, `urban_penalty`      | Determinantes de salario y decisión |


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

# Qué usar real vs simulado 😵‍💫

| Bloque                         | Variable en código                                           | ¿Real, estimado o simulado?                  | De dónde sacarlo / cómo                                                                                                                                                                                                                         |
| ------------------------------ | --------------------------------------------------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Población**                  | `N`                                                             | Simular (tamaño de muestra)                  | El paper usa encuestas reales para **calibrar** y luego simula; puedes elegir N.                                                                                                                                                          |
| **Horizonte**                  | `Tmax`                                                          | Simular                                      | Decisión de diseño (meses).                                                                                                                                                                                                                                   |
| **Reglas CCT**                 | `base_transfer_per_child`, `max_children_paid`, `poverty_line`  | **Real (política)**                          | **Reglas oficiales del programa** (p.ej. Bolsa Família/Prospera: monto por niñx, tope de hijxs, línea de pobreza).                                     |
| **Elegibilidad**               | `elegible <- (Y_hogar < poverty_line)`                          | Estimar con datos reales                     | Con **ingresos del hogar** de la encuesta (PNAD/ENIGH/etc.), marcas elegibilidad conforme a la norma.                                                                                                                                                         |
| **Ingreso del hogar**          | `Y_hogar`                                                       | **Real (encuesta)** o **simulado calibrado** | El paper usa **PNAD 2011** (ingresos declarados). Si no tienes microdatos, simula con una lognormal **calibrada** a medias/percentiles por estado/área.                                                                                                       |
| **Niñez**                      | `edad`, `grado`, `sexo`                                         | **Real (encuesta)** o **simulado calibrado** | Encuestas reportan edad, sexo y asistencia/último grado; el paper usa justamente esas covariables.                                                                                                                                                            |
| **Zona**                       | `zona` (urbana/rural)                                           | **Real (encuesta)**                          | PNAD etiqueta área; el paper presenta diferencias urbano/rural en decisiones E/ET/T.                                                                                                                                                                   |
| **# de hijxs**                 | `n_hijos`                                                       | **Real (encuesta)** o simulado calibrado     | Tamaño/composición del hogar viene en encuesta; el paper trabaja con estructura real de hogares.                                                                                                                                                              |
| **Salario potencial niño**     | `w_child` (tu Mincer)                                           | **Estimado con datos reales**                | El paper **estima** un modelo **Becker–Mincer** con PNAD: OLS de log-salario en función de edad, educación, sexo y variables locales (mediana estatal). Usa esos **coeficientes estimados** para predecir salarios.                                           |
| **Probabilidades de decisión** | (en el código se usa utilidades U_E/U_ET/U_T y `which.max`)       | **Estimado con datos reales**                | El paper **estima un logit multinomial** para obtener **probabilidades** de E/ET/T a partir de covariables (edad, grado, sexo, zona, ingresos, monto del CCT). Se puede reemplazar la regla determinística por sampling según **p(E), p(ET), p(T)** del logit.  |
| **Costos escolares**           | `cost_school`                                                   | Real o **calibrado**                         | Ideal: costo directo (transporte, materiales) de **encuesta de gastos**. Si no hay, calibrar para que tasas E/ET/T se parezcan a las observadas por edad y zona.                                                                                              |
| **Credibilidad**               | `delay_prob_base`, `lambda_cred`, `cred0`                       | **Mixto**                                    | Retrasos de pago: si existe **dato administrativo** úsalo; si no, **supón** (p.ej., 10–30%). `lambda_cred` (aprendizaje) y `cred0` son **mecánica ABM** (no del paper): **calíbralos** para reproducir trayectoria de asistencia.                             |
| **Umbral**                     | `theta` (Normal(300,80))                                        | **Simulado / calibrado**                     | Costo inobservable y calibra su media/desvío para reproducir niveles base de E/ET/T por edad/zona.                                                       |
| **Penalidad rural**            | `urban_penalty`                                                 | Real (si hay distancias/costos) o calibrado  | El paper documenta brecha urbano/rural (más ET y T en rural). Se puede **elevar costos** o umbrales en rural para replicar esas diferencias.                                                                                                                    |
| **Regla ET (tiempo)**          | (la parametrización) `school_share_ET`, `att_min`, `transfer_rule` | **Real (norma de asistencia)** + calibración | Si ET implica asistencia parcial, define si el pago es **proporcional** o **todo/nada** (umbral). Basado en reglas del programa.                                                                                           |
