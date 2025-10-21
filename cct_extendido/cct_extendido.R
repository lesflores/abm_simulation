# =========================
# 0) Paquetes y semilla
# =========================
library(ABM)
set.seed(1)

# =========================
# 1) Parámetros del modelo
# =========================
N      <- 5000
Tmax   <- 36
delay_prob_base <- 0.30
lambda_cred     <- 0.30

# 💔 ELIMINADO: transfer_amount (ya no usamos monto fijo)
# transfer_amount <- 600

# Monto por hijx y condiciones del programa
base_transfer_per_child <- 500
max_children_paid       <- 2
poverty_line            <- 4500

# NUEVO: parámetros socioeconómicos adicionales
beta_age    <- 0.08      # efecto edad sobre salario esperado (tipo Mincer)
beta_school <- 0.12      # efecto grado escolar
cost_school <- 100       # costo percibido de asistir (transporte, materiales)
urban_penalty <- 50      # hogares rurales: umbral mayor (más difícil asistir)

# =====================================
# 2) Crear simulación y estado inicial
# =====================================
sim <- Simulation$new(N)
seedA <- 10

for (i in 1:N) {
  theta  <- rnorm(1, mean = 300, sd = 80)
  cred0  <- 1 - delay_prob_base
  # state0 <- if (i <= seedA) "A" else "N"
  state0 <- sample(c("E", "ET", "T"), 1, prob = c(0.4, 0.3, 0.3))
  
  # Hijxs, ingreso, elegibilidad (ya estaba)
  n_hijos  <- sample(0:3, 1, prob = c(0.25, 0.40, 0.25, 0.10))
  Y_hogar  <- rlnorm(1, meanlog = log(4000), sdlog = 0.5)
  elegible <- (Y_hogar < poverty_line)
  
  # NUEVO: características individuales/ambientales
  edad   <- sample(10:17, 1)                          # edad del hijx mayor
  grado  <- max(1, edad - 6)                          # grado aproximado
  sexo   <- sample(c("M", "F"), 1, prob = c(0.5, 0.5))
  zona   <- sample(c("urbana", "rural"), 1, prob = c(0.7, 0.3))
  if (zona == "rural") theta <- theta + urban_penalty  # umbral mayor
  
  sim$setState(i, list(
    state0,
    theta     = theta,
    cred      = cred0,
    n_hijos   = n_hijos,
    Y_hogar   = Y_hogar,
    elegible  = elegible,
    edad      = edad,        # NUEVO
    grado     = grado,       # NUEVO
    sexo      = sexo,        # NUEVO
    zona      = zona         # NUEVO
  ))
}

# ======================================
# 3) Loggers (contadores automáticos)
# ======================================
sim$addLogger(newCounter("E", "E"))   # Solo escuela
sim$addLogger(newCounter("ET", "ET")) # Escuela + trabajo
sim$addLogger(newCounter("T", "T"))   # Solo trabajo

# =========================================================
# 4) Handler mensual (la dinámica)
# =========================================================
tick_handler <- function(time, sim, agent) {
  for (i in 1:N) {
    ai <- getAgent(sim, i)
    st <- getState(ai)
    
    # 💔 ELIMINADO: benefit <- transfer_amount * st$cred
    
    # Beneficio por hijx si elegible
    hijos_cubiertos <- min(st$n_hijos, max_children_paid)
    transfer_eff    <- if (st$elegible) base_transfer_per_child * hijos_cubiertos else 0
    
    # NUEVO: salario potencial del niño (modelo tipo Mincer)
    w_child <- exp(log(100) + beta_age * st$edad + beta_school * st$grado + rnorm(1, 0, 0.2))
    
    # NUEVO: utilidades de tres opciones (E=solo escuela, ET=escuela y trabajo, T=solo trabajo)
    U_E  <- transfer_eff * st$cred - cost_school
    U_ET <- (transfer_eff/2) + (w_child * 0.5) - (cost_school/2)
    U_T  <- w_child
    
    utilities <- c(E = U_E, ET = U_ET, T = U_T)
    new_state <- names(which.max(utilities))
    
    # NUEVO: pagado a tiempo solo si recibe transferencia (E o ET)
    paid_on_time <- (new_state %in% c("E", "ET")) && (runif(1) > delay_prob_base)
    
    # Actualizar credibilidad (EMA)
    cred_new <- (1 - lambda_cred) * st$cred + lambda_cred * as.numeric(paid_on_time)
    
    # Guardar nuevo estado y atributos
    setState(ai, list(
      new_state,
      theta     = st$theta,
      cred      = cred_new,
      n_hijos   = st$n_hijos,
      Y_hogar   = st$Y_hogar,
      elegible  = st$elegible,
      edad      = st$edad,
      grado     = st$grado,
      sexo      = st$sexo,
      zona      = st$zona
    ))
  }
  
  if (time < Tmax) schedule(agent, newEvent(time + 1, tick_handler))
}

# ==============================
# 5) Ejecutar la simulación
# ==============================
schedule(sim$get, newEvent(0, tick_handler))
res <- sim$run(0:Tmax)
# res$attend <- res$A / N
res$attend <- (res$E + res$ET) / N  # Proporción que estudia (solo escuela o escuela+trabajo)


res

# ==============================
# 6) Gráfico
# ==============================
library(ggplot2)

p <- ggplot(res, aes(x = times, y = attend)) +
  geom_area(fill = "yellow2", alpha = 0.12) +
  geom_line(size = 1.4, color = "orange", lineend = "round") +
  coord_cartesian(ylim = c(0, 1)) +
  labs(title = "CCT: Decisión educativa (E / ET / T) con salarios y contexto",
       x = "Mes", y = "% hogares que asisten") +
  theme_minimal(base_size = 14)

p

ggsave("asistencia_cct_extendido.png", plot = p, width = 8, height = 5, dpi = 300)





# Para monitorear cada categoría por separado en proporciones:

res$rate_E  <- res$E  / N
res$rate_ET <- res$ET / N
res$rate_T  <- res$T  / N   # trabajo infantil puro

res
# Y graficar series separadas:
  

ggplot(res, aes(times, rate_E)) +
  geom_line(size=1.2) +
  coord_cartesian(ylim=c(0,1)) +
  labs(title="Solo escuela (E)", x="Mes", y="Proporción") +
  theme_minimal(base_size=13)

ggplot(res, aes(times, rate_ET)) +
  geom_line(size=1.2) +
  coord_cartesian(ylim=c(0,1)) +
  labs(title="Escuela + trabajo (ET)", x="Mes", y="Proporción") +
  theme_minimal(base_size=13)

ggplot(res, aes(times, rate_T)) +
  geom_line(size=1.2) +
  coord_cartesian(ylim=c(0,1)) +
  labs(title="Solo trabajo (T)", x="Mes", y="Proporción") +
  theme_minimal(base_size=13)
