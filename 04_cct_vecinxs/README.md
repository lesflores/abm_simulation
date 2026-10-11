# cct_vecinos. Lo que hacen los vecinxs importa

Modelo 4. Parte del modelo 3 (estudiar, estudiar y trabajar, o solo trabajar, con decisiones con ruido) y agrega tres cosas:

1. **Comunidades:** 60 comunidades de 50 hogares; el 40% son rurales.
2. **La norma de los vecinxs:** estudiar vale más puntos si en la comunidad muchas familias mandan a sus hijxs solo a estudiar.
3. **La temporada agrícola:** de junio a septiembre, el trabajo rural paga 40% más.

Simula 48 meses y reporta el promedio de los meses 24 a 47 (dos años completos, con dos temporadas).

# 1) Parámetros nuevos

| Parámetro | Valor base | Qué significa |
| --- | --- | --- |
| `n_comunidades`, `hogares_por_c` | 60, 50 | 3,000 hogares en total |
| `prop_rural` | 0.40 | Proporción de comunidades rurales |
| `theta_rural_ext` | 100 | En lo rural la escuela cuesta más (queda más lejos) |
| `meses_temporada` | 6:9 | Temporada agrícola: junio a septiembre |
| `salario_temporada` | 1.4 | En temporada, el trabajo rural paga 40% más |
| `fuerza_vecinos` | 300 | Cuánto pesa lo que hacen los vecinos |
| `valor_estudiar` | 790 | Calibrado para que el trabajo infantil sea alrededor de 13% |
| `bono_temporada` | 0 | Pago extra por hijx en lo rural durante la temporada |
| `universal_rural` | FALSE | TRUE = todas las familias rurales son elegibles |
| `con_programa` | TRUE | FALSE = el mismo pueblo sin programa |

En lo rural los ingresos también son más bajos, así que hay más familias elegibles.

# 2) La norma de los vecinxs

Cada mes se calcula qué proporción de cada comunidad **solo estudió el mes anterior**, y eso suma puntos a estudiar:

```r
vecinos <- tapply(estado_prev == "E", comunidad, mean)
norma   <- fuerza_vecinos * vecinos[[st$comunidad]]

U_E  <- beca + valor_estudiar     + norma     - theta
U_ET <- beca + valor_estudiar / 2 + norma / 2 + salario / 2 - theta
U_T  <- salario
```

Por ejemplo, con fuerza 300, una comunidad donde 90% solo estudia suma 270 puntos a estudiar; una donde 50% solo estudia, solo 150.

# 3) Resultados

`resumen_*.csv` reporta trabajo infantil en todo el pueblo, en comunidades rurales, en urbanas y en **familias no elegibles** (las que nunca reciben beca), además del costo por hogar. También guarda dos gráficas: trabajo infantil por mes (rural y urbano) y un mapa de comunidades.

## Tres mundos con el mismo presente

Con cada fuerza de vecinxs, `valor_estudiar` se recalibró para que el trabajo infantil actual sea alrededor de 13%:

| `fuerza_vecinxs` | `valor_estudiar` | Con programa | Sin programa | No elegibles con / sin programa |
| --- | --- | --- | --- | --- |
| 0 | 1040 | 13.0% | 20.0% | 18.2% / 18.1% |
| 300 | 790 | 12.8% | 23.1% | 17.6% / 20.0% |
| 600 | 540 | 12.6% | 38.8% | 16.9% / 30.0% |

Los tres reproducen el presente, pero el efecto del programa va de 7 a 26 puntos. Con vecinxs, el programa también reduce el trabajo infantil de familias que nunca reciben beca: el **efecto contagio**, documentado para Progresa por Bobonis y Finan (2009, *Review of Economics and Statistics*, 91(4)).

## ¿Dónde y cuándo pagar? (con $40 extra por hogar)

| Diseño | Cambio | Trabajo infantil | Costo |
| --- | --- | --- | --- |
| Programa actual | | 12.8% | 285 |
| Monto 350 | `base_transfer_per_child <- 350` | 12.3% | 334 |
| Bono de temporada 250 | `bono_temporada <- 250` | 12.0% | 325 |
| Rurales todas elegibles | `universal_rural <- TRUE` | 11.1% | 323 |

# 4) Supuestos que conviene discutir

- La norma solo mira a la propia comunidad, no a comunidades vecinas.
- Todas las comunidades tienen el mismo tamaño.
- La fuerza de los vecinxs es igual en todas partes y no se observa directamente: los datos actuales no alcanzan para saber si es 300 o 600.
