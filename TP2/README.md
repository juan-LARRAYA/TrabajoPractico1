# Grabar una tabla en la EEPROM - TP2 - Laboratorio de microprocesadores

**1. Objetivo**
El objetivo de este trabajo práctico es aprender acerca del uso de
interrupciones externas del microcontrolador y poder leer y escribir sobre la
memoria EEPROM.

**2. Descripción del proyecto**
El programa consiste en grabar una tabla en la EEPROM del microcontrolador
para luego mostrar los caracteres contenidos en el display 7 segmentos a
través de las interrupciones externas generadas por los pulsadores. Con el
pulsador 1 se avanza de posición en la tabla mientras que con el pulsador 2 se
retrocede. Al iniciar el programa se verifica si la tabla ya está escrita fijándose
si una firma que precede a la tabla ya esta grabada, si no lo está ́ se graban
ambas. Luego de esto, se inicia el display mostrando la secuencia de
caracteres A B C D E F y se muestra el último carácter mostrado en la
ejecución anterior del programa, en caso de que sea la primera vez que se
ejecuta el programa se muestra el primer elemento de la tabla.
