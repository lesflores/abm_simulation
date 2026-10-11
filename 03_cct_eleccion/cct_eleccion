# =====================================================================
# cct_eleccion. Estudiar, estudiar y trabajar, o solo trabajar
# Modelo 2 del curso de simulación basada en agentes
# Punto de partida: el modelo de la sesión 2 (elegibilidad + monto por hijx)
# Novedades: tres opciones, valor propio de estudiar, salario del hijx
#            y decisiones con ruido (softmax)
# =====================================================================

# =========================
# 0) Paquetes y semilla
# =========================
library(ABM)
library(ggplot2)
set.seed(1)

# =========================
# 1) Parámetros del modelo
# =========================
N               <- 5000   # Hogares (todos con al menos un hijx en edad escolar)
Tmax            <- 36     # Meses
delay_prob_base <- 0.30   # Probabilidad de que el pago llegue tarde
lambda_cred     <- 0.30   # Velocidad de aprendizaje de la credibilidad

# --- Reglas del programa ---
base_transfer_per_child <- 300    # Monto mensual por hijx cubierto
max_children_paid       <- 2      # Tope de hijxs cubiertos
poverty_line            <- 4500   # Línea de pobreza
bono_15_17              <- 0      # Monto EXTRA por hijx si el hijx mayor tiene 15 a 17 años
beca_solo_sin_trabajo   <- FALSE  # TRUE = la beca solo se paga si el hijx estudia y NO trabaja

# --- Población ---
ingreso_mediano  <- 4000
ingreso_desigual <- 0.5
prob_hijos       <- c(0.40, 0.25, 0.10)   # 1, 2 o 3 hijxs (todos los hogares tienen al menos uno)

# --- NUEVO: la decisión ---
valor_estudiar <- 1000   # Cuánto valora la familia que su hijx estudie (en pesos al mes)
salario_12     <- 300    # Lo que aportaría trabajando un hijx de 12 años (pesos al mes)
tau            <- 120    # Ruido de las decisiones: más alto = decisiones menos predecibles

# --- Interruptor heredado ---
senal_publica <- TRUE

# =====================================
# 2) Crear simulación y estado inicial
# =====================================
# Atributos nuevos: edad del hijx mayor y su salario potencial
sim <- Simulation$new(N)

for (i in 1:N) {
  theta    <- rnorm(1, mean = 300, sd = 80)                  # Lo que le cuesta a la familia mandar a la escuela
  cred0    <- 1 - delay_prob_base
  n_hijos  <- sample(1:3, size = 1, prob = prob_hijos)
  Y_hogar  <- rlnorm(1, meanlog = log(ingreso_mediano), sdlog = ingreso_desigual)
  elegible <- Y_hogar < poverty_line
  edad     <- sample(12:17, size = 1)                        # Edad del hijx mayor
  salario  <- salario_12 * exp(0.12 * (edad - 12))           # Más edad, más paga: de 300 (12 años) a ~550 (17 años)
  sim$setState(i, list("E", theta = theta, cred = cred0, n_hijos = n_hijos,
                       Y_hogar = Y_hogar, elegible = elegible, edad = edad, salario = salario))
}

hogares <- data.frame(id = 1:N, elegible = NA, edad = NA, estado = NA)
pagos_mes <- numeric(Tmax + 1)    # Cuánto paga el programa cada mes (para el costo)

# ======================================
# 3) Loggers
# ======================================
sim$addLogger(newCounter("E", "E"))     # Solo estudia
sim$addLogger(newCounter("ET", "ET"))   # Estudia y trabaja
sim$addLogger(newCounter("T", "T"))     # Solo trabaja

# =========================================================
# 4) Regla mensual: leer -> decidir -> escribir
# =========================================================
tick_handler <- function(time, sim, agent) {
  pagado <- 0
  for (i in 1:N) {
    # --- Leer ---
    ai <- getAgent(sim, i)
    st <- getState(ai)
    
    # --- Lo que ofrece el programa (como en el modelo 2, más el bono opcional) ---
    hijos_cubiertos <- min(st$n_hijos, max_children_paid)
    monto_hijx      <- base_transfer_per_child + (if (st$edad >= 15) bono_15_17 else 0)
    transfer_eff    <- if (st$elegible) monto_hijx * hijos_cubiertos else 0
    beca            <- transfer_eff * st$cred                          # Lo que espera recibir
    beca_ET         <- if (beca_solo_sin_trabajo) 0 else beca          # ¿Cobra si estudia y trabaja?
    
    # --- NUEVO: cuánto le conviene cada opción (en pesos al mes) ---
    U_E  <- beca    + valor_estudiar                    - st$theta   # Solo estudia
    U_ET <- beca_ET + valor_estudiar / 2 + st$salario / 2 - st$theta # Estudia y trabaja (medio tiempo cada cosa)
    U_T  <-                                st$salario                # Solo trabaja
    
    # --- NUEVO: decisión con ruido (softmax) ---
    # La opción con más puntos es la más probable, pero no siempre gana.
    U <- c(E = U_E, ET = U_ET, T = U_T)
    prob <- exp((U - max(U)) / tau)
    prob <- prob / sum(prob)
    new_state <- sample(c("E", "ET", "T"), size = 1, prob = prob)
    
    # --- Señal y credibilidad ---
    cobra <- st$elegible && (new_state == "E" || (new_state == "ET" && !beca_solo_sin_trabajo))
    if (cobra) {
      senal  <- as.numeric(runif(1) > delay_prob_base)
      pagado <- pagado + transfer_eff
    } else if (senal_publica) {
      senal <- 1 - delay_prob_base
    } else {
      senal <- 0
    }
    cred_new <- (1 - lambda_cred) * st$cred + lambda_cred * senal
    
    # --- Escribir ---
    setState(ai, list(new_state, theta = st$theta, cred = cred_new, n_hijos = st$n_hijos,
                      Y_hogar = st$Y_hogar, elegible = st$elegible, edad = st$edad, salario = st$salario))
    
    hogares$elegible[i] <<- st$elegible
    hogares$edad[i]     <<- st$edad
    hogares$estado[i]   <<- new_state
  }
  pagos_mes[time + 1] <<- pagado
  if (time < Tmax) schedule(agent, newEvent(time + 1, tick_handler))
}

# ==============================
# 5) Ejecutar
# ==============================
schedule(sim$get, newEvent(0, tick_handler))
res <- sim$run(0:Tmax)
res$E_p  <- res$E / N
res$ET_p <- res$ET / N
res$T_p  <- res$T / N

# ==============================
# 6) Resultados
# ==============================
escenario <- paste0("monto", base_transfer_per_child, "_linea", poverty_line,
                    "_bono", bono_15_17, if (beca_solo_sin_trabajo) "_soloE" else "", "_tau", tau)

ultimos <- res$times >= 25   # Promedio de los últimos 12 meses (equilibrio)
resumen <- data.frame(
  escenario         = escenario,
  solo_estudia      = round(mean(res$E_p[ultimos]), 3),
  estudia_y_trabaja = round(mean(res$ET_p[ultimos]), 3),
  solo_trabaja      = round(mean(res$T_p[ultimos]), 3),
  trabajo_infantil  = round(mean(res$ET_p[ultimos] + res$T_p[ultimos]), 3),
  costo_por_hogar   = round(mean(pagos_mes[(Tmax - 11):Tmax]) / N)   # meses 24 a 35
)
print(resumen)
write.csv(resumen, paste0("resumen_", escenario, ".csv"), row.names = FALSE)

# Referencia real: ENTI 2022 (INEGI), 13.1% de 5 a 17 años en trabajo infantil;
# 3 de cada 10 no asisten a la escuela -> aprox. 87% E, 9% ET, 4% T

# Por elegibilidad (último mes)
por_grupo <- as.data.frame.matrix(prop.table(table(
  ifelse(hogares$elegible, "Elegible", "No elegible"),
  factor(hogares$estado, levels = c("E", "ET", "T"))), 1))
print(round(por_grupo, 3))

# ==============================
# 7) Gráfico
# ==============================
largo <- rbind(
  data.frame(times = res$times, opcion = "Solo estudia",      p = res$E_p),
  data.frame(times = res$times, opcion = "Estudia y trabaja", p = res$ET_p),
  data.frame(times = res$times, opcion = "Solo trabaja",      p = res$T_p))
largo$opcion <- factor(largo$opcion, levels = c("Solo trabaja", "Estudia y trabaja", "Solo estudia"))

p <- ggplot(largo, aes(x = times, y = p, fill = opcion)) +
  geom_area() +
  scale_fill_manual(values = c("Solo estudia" = "gold", "Estudia y trabaja" = "orange", "Solo trabaja" = "firebrick")) +
  labs(title = "¿Qué eligen los hogares cada mes?", subtitle = escenario,
       x = "Mes", y = "Proporción de hogares", fill = NULL) +
  theme_minimal(base_size = 14)
p
ggsave(paste0("eleccion_", escenario, ".png"), plot = p, width = 8, height = 5, dpi = 300)
