# Validación del Modelo Basado en Agentes (ABM) para Programas de Transferencias Condicionadas

Este documento describe **el proceso de validación empírica** aplicado al modelo basado en agentes (ABM) que simula las decisiones educativas de los hogares bajo esquemas de transferencias condicionadas (CCT).  
El objetivo de la validación es verificar **qué tan bien el modelo reproduce los patrones observados en los datos reales** y si sus resultados generalizan más allá del conjunto de calibración.

---

## Objetivo de la validación

El modelo busca capturar los efectos combinados de:

- La **credibilidad institucional** (medida por la puntualidad y aprendizaje de los hogares).  
- La **magnitud del subsidio educativo**.  
- La **aleatoriedad en la toma de decisiones** (temperatura de decisión `τ`).  

La validación se enfoca en determinar si, con una calibración mínima, el modelo puede reproducir **la distribución empírica de la inversión educativa y la asistencia escolar**.

---

## 1. Metodología de validación *hold-out*

Se aplicó una validación tipo **hold-out (entrenamiento/prueba)** para medir la capacidad de generalización del modelo:

1. La base empírica de hogares (`hogares_base.xlsx`) se dividió aleatoriamente:
   - **70% Train**: para calibrar parámetros del modelo.  
   - **30% Test**: para validar los resultados con datos no usados en la calibración.

2. En la fase de calibración, se exploraron 16 combinaciones de parámetros dentro de una grilla factorial:

| Parámetro | Rango evaluado |
|------------|----------------|
| Probabilidad de retraso (`delay_prob_base`) | 0.10, 0.40 |
| Monto del subsidio (`subsidy_base`) | 300, 800 |
| Temperatura de decisión (`tau`) | 100, 400 |
| Velocidad de aprendizaje (`lambda_cred`) | 0.10, 0.30 |

3. Para cada combinación se ejecutó una simulación completa de 30 periodos (`Tmax = 30`), y se calculó una **función de pérdida (L)**:

```r
L = 0.7 * (esc_sim - esc_obs)^2 + 0.3 * (mean(inversion_alta) - asis_obs)^2


## 📐 Detalles de la función de pérdida

**Donde:**

- `esc_sim` → nivel **simulado final de inversión educativa**.  
- `esc_obs` → nivel **promedio de escolaridad observada** en los datos reales.  
- `asis_obs` → **proporción observada de asistencia escolar**.

> La pérdida pondera más la escolaridad final (70%) que la asistencia (30%), reflejando la prioridad del modelo en capturar la **movilidad educativa intergeneracional**.

---

## 🧪 2. Resultados de calibración

El proceso de calibración identificó el conjunto de parámetros con **menor pérdida (L)** durante la fase *train*:

| Parámetro | Valor óptimo |
|------------|--------------|
| `delay_prob_base` | **0.40** |
| `subsidy_base` | **300** |
| `tau` | **400** |
| `lambda_cred` | **0.10** |
| **Pérdida Train (L)** | **0.0816** |

📌 Este escenario indica que **niveles bajos de subsidio y alta incertidumbre en los pagos** reproducen mejor el patrón real de inversión educativa.  
Esto sugiere que la **credibilidad institucional** (capacidad del programa para mantener confianza a largo plazo) juega un papel más relevante que el monto económico inmediato.

---

## 🧾 3. Resultados de validación (TEST)

Con los parámetros óptimos, se volvió a ejecutar la simulación sobre el **30% de los hogares no usados en la calibración**.

> ✅ **Pérdida en TEST (L) = 0.0920**

El incremento marginal (de **0.0816 → 0.0920**) demuestra que el modelo **generaliza bien**, manteniendo un error bajo al enfrentarse a datos nuevos.  
Esto confirma que el ABM **no está sobreajustado** y puede replicar con estabilidad los patrones empíricos observados.

---

## 📈 4. Evaluación visual

Se generó la siguiente gráfica para comparar el promedio observado de inversión educativa con la curva simulada en la base de *test*:

```r
obs_mean <- mean(hog_test$escolaridad_hijxs)

ggplot(res_test, aes(x = times, y = inversion_alta)) +
  geom_line(color = "#7B1FA2", size = 1.2) +
  geom_hline(yintercept = obs_mean, linetype = "dashed", color = "gray40") +
  annotate("text", x = Tmax * 0.7, y = obs_mean + 0.02,
           label = paste0("Media observada: ", round(obs_mean, 2)),
           color = "gray30", size = 3.5, hjust = 0) +
  labs(
    title = "Validación del modelo ABM (Base de Test)",
    subtitle = "Curva simulada vs. promedio observado de inversión educativa",
    x = "Periodo / generación",
    y = "% hogares con inversión media o alta"
  ) +
  theme_minimal(base_size = 13)
