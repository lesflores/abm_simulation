# cct_per_child. Elegibilidad por pobreza + transferencia por hijx

Modelo per child. Parte del modelo simple ya corregido (con señal pública) y le agrega **heterogeneidad** y **reglas de política**: cada hogar tiene un número de hijxs y un ingreso, y el programa solo paga a los hogares bajo la línea de pobreza, por hijx y con un tope.

# 1) Parámetros

**Del modelo (igual que en el modelo simple):** `N = 5000`, `Tmax = 36`, `delay_prob_base = 0.30`, `lambda_cred = 0.30`.

**Reglas del programa** (decisiones de diseño de la política):

- `base_transfer_per_child = 300`: monto mensual por hijx cubierto.
- `max_children_paid = 2`: tope de hijxs cubiertos por hogar.
- `poverty_line = 4500`: el hogar es elegible si su ingreso es menor.

**Población** (cómo son los hogares):

- `ingreso_mediano = 4000` e `ingreso_desigual = 0.5`: el ingreso sigue una distribución lognormal.
- `prob_hijos = c(0.25, 0.40, 0.25, 0.10)`: probabilidad de tener 0, 1, 2 o 3 hijxs en edad escolar.

**Interruptor:** `senal_publica = TRUE` mantiene la corrección del modelo simple. Con `FALSE` vuelve la regla original, en la que no asistir cuenta como retraso.

# 2) Atributos nuevos de cada hogar

- `n_hijos`: número de hijxs en edad escolar (0 a 3).
- `Y_hogar`: ingreso mensual del hogar sin la transferencia.
- `elegible`: `TRUE` si `Y_hogar < poverty_line`.

# 3) La nueva regla del beneficio

```r
hijos_cubiertos <- min(st$n_hijos, max_children_paid)
transfer_eff    <- if (st$elegible) base_transfer_per_child * hijos_cubiertos else 0
benefit         <- transfer_eff * st$cred
new_state       <- if (benefit >= st$theta) "A" else "N"
```

Lo demás (señal, credibilidad, re-agendar) es igual que en el modelo simple.

# 4) Resultados

Cada corrida muestra y guarda (el nombre del archivo incluye monto, tope y línea):

- `resumen_*.csv`: asistencia en los meses 1, 12 y 36, para **todos los hogares** y solo para **hogares con hijxs**.
- `por_grupo_*.csv`: asistencia en el mes 36 por elegibilidad y número de hijxs.
- `asistencia_*.png` y `por_grupo_*.png`: las gráficas.

Resultados con los valores base (`set.seed(1)`), mes 36:

| | Asistencia |
| --- | --- |
| Todos los hogares | 18.1% |
| Hogares con hijxs | 24.2% |
| Elegibles con 1 hijx | 11% |
| Elegibles con 2 hijxs | 75% |
| Elegibles con 3 hijxs | 75% |
| No elegibles | 0% |
