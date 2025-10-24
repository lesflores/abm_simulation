# Modelo ABM: Transferencias Condicionadas y Credibilidad Institucional

## Objetivo del modelo

El modelo busca **simular las decisiones de inversión educativa** de los hogares bajo un programa de transferencias condicionadas cuya **efectividad depende tanto del monto como de la puntualidad de los pagos**.  

El enfoque permite analizar cómo la **credibilidad institucional** -entendida como la confianza de los hogares en la puntualidad del programa- afecta la acumulación educativa intergeneracional (Es una idea central en estudios de movilidad social y desarrollo humano: Cuando una política pública -como una beca o transferencia- logra que una generación estudie más, también eleva la probabilidad de que la siguiente generación lo haga, rompiendo ciclos de desigualdad educativa).

---

## Propósito general

Evaluar cómo los **parámetros de política pública** (subsidio, puntualidad, elegibilidad y credibilidad) influyen en la proporción de hogares que invierten niveles medios o altos de recursos en educación, dentro de un entorno heterogéneo y dinámico.

---

## ⚙️ Objetivos específicos

1. **Representar la toma de decisiones de los hogares**, considerando:
   - Retornos educativos esperados.
   - Costos y barreras contextuales (θ).
   - Valor esperado del subsidio condicionado a la credibilidad.

2. **Modelar el aprendizaje de la credibilidad (λ)**, actualizada en función de la experiencia del hogar con pagos puntuales o retrasados.

3. **Incorporar heterogeneidad estructural**, diferenciando entre hogares rurales y urbanos, niveles de educación parental e ingresos.

4. **Simular la dinámica intergeneracional**, donde la inversión educativa del hogar incrementa el nivel de escolaridad de hijas/os a lo largo del tiempo.

5. **Comparar escenarios de política**, variando:
   - Puntualidad del pago (`delay_prob_base`)
   - Monto base del subsidio (`subsidy_base`)
   - Temperatura de decisión (`tau`)
   - Velocidad de aprendizaje (`lambda_cred`)

---

## 📈 Resultados esperados

- Trayectorias temporales de la proporción de hogares con **inversión media o alta** (`inversion_alta`).
- Evolución de la **credibilidad promedio** del programa.
- Sensibilidad del modelo ante **shocks**, **estacionalidad** y variaciones en parámetros clave.
- Identificación de **configuraciones óptimas de política** que maximizan la inversión educativa sostenida.

---

## ❓Preguntas que responde el modelo

- ¿Qué pesa más para mejorar la inversión educativa: el monto del subsidio o la puntualidad del programa?
- ¿Cuánta puntualidad mínima se requiere para que la política sea efectiva?
- ¿Cómo cambian los resultados cuando se modifica la regla de elegibilidad?
- ¿Qué combinación de credibilidad (λ), monto y variabilidad en decisiones (τ) genera mejoras sostenidas?

---

## 🧪 Indicadores de calibración

Para validar el modelo, se propone minimizar una función de pérdida ponderada entre datos simulados y observados:

\[
L = 0.7\,|\text{esc\_sim} - \text{esc\_obs}| + 0.3\,|\text{asis\_sim} - \text{asis\_obs}|
\]

donde:
- `esc_sim`: escolaridad promedio simulada.
- `esc_obs`: escolaridad promedio observada.
- `asis_obs`: proporción observada de asistencia escolar.

---

## 🗂️ Estructura del código

1. **Paquetes y datos:** carga de librerías y base real (`hogares_base.xlsx`).
2. **Parámetros del programa:** define elegibilidad, subsidio, credibilidad y temperatura de decisión.
3. **Preparación de variables derivadas:** credibilidad inicial, barreras educativas, estados iniciales.
4. **Simulación principal:** ciclo de actualización mensual (tick handler).
5. **Resultados y visualización:** evolución de inversión educativa.
6. **Experimentos:** comparación entre escenarios con distinta puntualidad, subsidio, τ y λ.

---

## 🧭 Referencia conceptual

El modelo combina:
- **Dimensión económica:** incentivos y retornos tipo Mincer.
- **Dimensión cognitiva:** aprendizaje de credibilidad mediante `λ`.
- **Dimensión contextual:** estacionalidad y brechas rural/urbano.
