# Mecanizar y controlar un móvil - TP FINAL - Laboratorio de microprocesadores

**1. Objetivo**

● Mecanizar y controlar un móvil, utilizando diversos sensores actuadores
y comunicación serie, integrando habilidades adquiridas durante el
cuatrimestre.

● Comprender y reutilizar código fuente provisto por terceras partes para
integrarlo a un proyecto propio.

**2. Descripción del proyecto**

se implementó el código en assembler para realizar lo siguiente:

● El movimiento vertical es comandado por el potenciómetro conectado a
la entrada analógica ADC0. El programa mide permanentemente la
tensión del potenciómetro, de modo que ante diferentes valores
analógicos, el ojo se mueve verticalmente hacia arriba o hacia abajo, en
un rango de +-45 grados respecto al centro.

● El movimiento horizontal es comandado por datos recibidos por el puerto
serie, el cual está conectado a la PC. Los comandos son ingresados por
un terminal de comunicaciones de PC, por ejemplo, Realterm o la
consola serie de Arduino.
Los comandos implementados son de un carácter ASCII cada uno:
-d: girar a la derecha 9 grados, máximo -45 grados.
-i: girar a la izquierda 9 grados, máximo 45 grados.
