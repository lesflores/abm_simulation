# Modelo 5. ¿Cuál de los tres mundos es el verdadero?

Última sesión del curso. No agrega nada al modelo: usa el modelo 4 (`cct_vecinxs`) para aprender a decidir **cuándo creerle a un modelo**.

El modelo 4 terminó con tres mundos que reproducen el mismo presente (alrededor de 13% de trabajo infantil) pero dicen cosas muy distintas sobre cuánto sirve el programa. Hoy se resuelve con un **piloto como el de Progresa**: comunidades sorteadas que permiten medir el contagio hacia familias no elegibles.

# 1) `simular()`: el mismo modelo, más rápido

`cct_vecinxs` decide hogar por hogar con el paquete ABM y tarda unos 15 segundos. `simular()` aplica las mismas reglas a todas las familias a la vez y tarda menos de un segundo. Comparar las dos versiones (*docking*) es una forma de verificar el modelo:

| Mundo | `cct_vecinxs` | `simular()` |
| --- | --- | --- |
| Vecinxs 0, con programa | 13.0% | 13.3% |
| Vecinxs 300, con programa | 12.8% | 12.9% |
| Vecinxs 600, sin programa | 38.8% | 38.7% |

# 2) El script, sección por sección

| Sección | Qué hace | Resultado |
| --- | --- | --- |
| 0 | Docking: compara `simular()` con `cct_vecinxs` | 12.9% contra 12.8% |
| 1 | 20 réplicas del mismo mundo | 12.8% (IC 95%: 12.6% a 12.9%) |
| 2 | Barrido: efecto del programa según la fuerza de los vecinos | 7, 8, 11, 16 y 27 puntos (fuerza 0 a 600) |
| 3 | Patrones del piloto | Efecto directo 20.5 puntos; contagio 5.8 puntos |
| 4 | Qué mundo reproduce el contagio del piloto | Fuerza 450 (contagio simulado 6.4) |
| 5 | Validación con el efecto directo, que no se usó para elegir | Predice 21.5; el piloto muestra 20.5 |
| 6 | La respuesta | El programa baja el trabajo infantil 16 puntos |

# 3) El piloto

`piloto.csv` tiene una fila por hogar:

- `comunidad`: de 1 a 60.
- `rural`: TRUE si la comunidad es rural.
- `tratada`: TRUE si la comunidad recibió el programa en el sorteo.
- `elegible`: TRUE si el hogar gana menos que la línea de pobreza.
- `trabajo`: proporción de meses del último año en que su hijx estuvo en trabajo infantil.

El sorteo se hizo **por separado entre comunidades rurales y urbanas** (la mitad de cada una). Con un sorteo simple, un grupo podía quedar con más comunidades rurales, y eso parecía contagio aunque no lo hubiera.

Los dos patrones son restas entre comunidades sin programa y con programa:

- **Efecto directo:** en familias elegibles.
- **Contagio:** en familias no elegibles, que nunca reciben beca.

# 4) Referencias

- Bobonis, G. y Finan, F. (2009). Neighborhood peer effects in secondary school enrollment decisions. *Review of Economics and Statistics*, 91(4). 
- Grimm, V. et al. (2020). The ODD protocol for describing agent-based and other simulation models: A second update. *JASSS*, 23(2), 7.
