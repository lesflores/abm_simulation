# cct_eleccion. Estudiar, estudiar y trabajar, o solo trabajar

Modelo 3. Parte del modelo 2 (elegibilidad por pobreza y monto por hijx) y agrega tres cosas:

1. **Tres opciones** cada mes: solo estudiar (E), estudiar y trabajar (ET) o solo trabajar (T).
2. **El valor propio de estudiar**, para que las familias no elegibles también manden a sus hijxs a la escuela.
3. **Decisiones con ruido:** la opción con más puntos es la más probable, pero no siempre gana.

Con los valores base, el modelo reproduce la tasa de trabajo infantil de **13.1%** que reporta la ENTI 2022 del INEGI.

# 1) Parámetros nuevos

| Parámetro | Valor base | Qué significa |
| --- | --- | --- |
| `valor_estudiar` | 1000 | Cuánto valora la familia que su hijx estudie, en pesos al mes |
| `salario_12` | 300 | Lo que aportaría trabajando un hijx de 12 años; crece con la edad hasta unos 550 a los 17 |
| `tau` | 120 | Ruido de las decisiones: más alto, decisiones menos predecibles |
| `bono_15_17` | 0 | Monto extra por hijx si el mayor tiene de 15 a 17 años |
| `beca_solo_sin_trabajo` | FALSE | Si es TRUE, la beca solo se paga cuando el hijx estudia y no trabaja |

Los demás parámetros (monto, tope, línea de pobreza, retraso, aprendizaje y señal pública) son los del modelo 2. Todos los hogares tienen al menos un hijx en edad escolar, para evitar el problema del denominador del modelo 2.

# 2) Los puntos de cada opción

En pesos al mes:

```r
U_E  <- beca    + valor_estudiar                      - theta   # Solo estudia
U_ET <- beca_ET + valor_estudiar / 2 + salario / 2    - theta   # Estudia y trabaja
U_T  <-                                salario                  # Solo trabaja
```

- `beca` es lo que la familia espera recibir: monto × credibilidad, como en los modelos 1 y 2.
- En ET la familia cobra la beca, porque el programa pide asistir, no dejar de trabajar. Con `beca_solo_sin_trabajo <- TRUE`, `beca_ET` vale 0.
- `theta` es lo que le cuesta a la familia mandar a su hijx a la escuela.

# 3) Decisión con ruido (softmax)

```r
prob <- exp((U - max(U)) / tau)
prob <- prob / sum(prob)
new_state <- sample(c("E", "ET", "T"), 1, prob = prob)
```

Con `tau` bajo casi siempre gana la opción con más puntos, como en los modelos 1 y 2. Con `tau` alto, las tres opciones se vuelven parecidas. En econometría esto se llama logit multinomial.

# 4) Resultados

Cada corrida imprime y guarda `resumen_*.csv` (promedio de los últimos 12 meses):

- `solo_estudia`, `estudia_y_trabaja`, `solo_trabaja`
- `trabajo_infantil` = estudia y trabaja + solo trabaja
- `costo_por_hogar`: lo que paga el programa al mes, dividido entre todos los hogares

También imprime la tabla por elegibilidad y guarda la gráfica `eleccion_*.png`.

| Escenario | Cambio | Trabajo infantil | Costo |
| --- | --- | --- | --- |
| Sin programa | `base_transfer_per_child <- 0` | 17.9% | 0 |
| **Base** | | **13.1%** | 258 |
| Monto 450 | `base_transfer_per_child <- 450` | 12.6% | 390 |
| Bono 15–17 | `bono_15_17 <- 200` | 12.5% | 347 |
| Línea 5,500 | `poverty_line <- 5500` | 11.7% | 322 |
| Beca solo sin trabajo | `beca_solo_sin_trabajo <- TRUE` | 8.9% | 255 |
| Poco ruido | `tau <- 60` | 2.5% | 261 |
| Mucho ruido | `tau <- 240` | 32.4% | 245 |

# 5) Calibración con datos reales

Según la ENTI 2022 (INEGI), 13.1% de la población de 5 a 17 años realizaba trabajo infantil, y 3 de cada 10 de ellos no asistían a la escuela. Eso da aproximadamente 87% que solo estudia, 9% que estudia y trabaja y 4% que solo trabaja. `valor_estudiar`, `salario_12` y `tau` se ajustaron para acercarse a esos números: el modelo da 87%, 8% y 5%.

# 6) Supuestos que conviene discutir

- El valor de estudiar es igual para todas las familias.
- El salario solo depende de la edad.
- `tau` decide mucho del resultado y no se observa directamente, se calibra.
- El modelo no incluye lo que costaría verificar que un hijx no trabaja.
