# 🎓 Modelo ABM de Decisión Educativa con Transferencias Condicionadas

Este modelo basado en agentes (ABM) simula la **decisión mensual de los hogares** sobre la asistencia escolar de niñxs en el contexto de un programa de transferencias condicionadas.  
Cada hogar decide entre tres opciones:

- 🏫 **E**: Solo escuela  
- 🧒💼 **ET**: Escuela y trabajo  
- 💼 **T**: Solo trabajo  

El objetivo es analizar cómo **la elegibilidad, la credibilidad del programa, los costos y la puntualidad de los pagos** influyen en las trayectorias de asistencia escolar a lo largo del tiempo.

---

## 📦 0) Paquetes y Datos

El modelo usa:

```r
library(ABM)
library(dplyr)
library(ggplot2)
library(readxl)

