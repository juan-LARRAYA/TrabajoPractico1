# Modos del timer de 16 bits - TP3 - Laboratorio de microprocesadores

**1. Objetivo**
El objetivo de este trabajo práctico es utilizar los distintos modos del timer de
16 bits para hacer parpadear un led a distintas frecuencias.

**2. Descripción del proyecto**
Este trabajo práctico se divide en dos partes. La primera busca aumentar o
disminuir el brillo del led mediante dos pulsadores. Esto se hace variando el
ciclo de trabajo de una señal hecha con PWM por el timer 1, hay 16 niveles de
brillo posibles para el led.
En la segunda se busca controlar un servomotor a través de un potenciometro
tambien variando el ciclo de trabajo de la señal hecha con PWM del timer 1
