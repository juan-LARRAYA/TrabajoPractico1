;ParteB.asm

;prenda un LED cuando se presiona el pulsador 1 y quede parpadeando hasta que se apague cuando se presiona el pulsador 2. 
;Agregar al informe el diagrama esquemático del hardware, un diagrama en bloques del código y demás requisitos del informe (Informe.pdf)

;El LED está conectado a un pin del microcontrolador y los pulsadores a otros dos pines a elección.



.include "m328pdef.inc"

 
; Defino las constantes del programa

.equ LED_PORT_D = PORTD
.equ LED_PIN = 2
;.equ PIND7 = 7	
;.equ PINB0 = 0



;ALIAS DE LOS REGISTROS.
.def TEMP1 	= 	R18
.def TEMP2	= 	R19
.def TEMP3 	= 	R20
.def AUX 	= 	R21 


; Se inicializa la RAM

.dseg
.org SRAM_START

;Inicio del codigo
.cseg
.org 0x0000
; Segmento de datos en memoria de codigo

; Se inicializa el Stack Pointer al final de la RAM utilizando la definicion global RAMEND
	LDI		AUX,HIGH(RAMEND)
	out		sph,AUX
	LDI		AUX,LOW(RAMEND)
	out		spl,AUX
	

	RCALL configurar_puertos

; Inicio del loop principal 	
main_loop:
	RCALL Boton_1

loop:  ; loop donde se realiza el titilado del led
	SBI 	LED_PORT_D,LED_PIN
	RCALL 	retardo_500ms

	CBI 	LED_PORT_D, LED_PIN
	BRNE 	fin_main_loop  	; Interrumpe el titilado si se aprieta el boton 2
	RCALL 	retardo_500ms
	BRNE 	fin_main_loop 		; Interrumpe el titilado si se aprieta el boton 2

	RJMP 	loop

fin_main_loop:
	RJMP 	main_loop

; Fin del loop principal


; Se configuran los puertos a usar
configurar_puertos:
	LDI 	AUX, ((0 << DDD7)|(1 << DDD2))		;Configura como entrada el pin D7 y el pin D2 como salida, el resto queda como entrada por defecto
	out 	DDRD, AUX
	CBI 	LED_PORT_D, LED_PIN 				;Inicializa el valor del pin del led en 0
	LDI 	AUX, 0x00 							;Configura como entrada el pin B0 y el resto queda como entrada por defecto
	out 	DDRB, AUX 

	;Se configuran las resistencias de pull up
	SBI		LED_PORT_D, PIND7 ;Se activa solamente la resistencia del pin D7 con el pulsador 1
	ret


; Se mantiene en espera hasta que PBO está en 1 (se apretó el botón)
Boton_1:  
	SBIS	PINB, PINB0		;Verifica que PB0 = 0
	RJMP	Boton_1						
	RCALL	retardo_5ms		;Deja esperar para evitar falsos positivos
	SBIS	PINB, PINB0		;Verifica de nuevo que PB0 sea 0
	RJMP	Boton_1
	ret

; Se mantiene en espera hasta que PD7 está en 0 (se apretó el botón)
Boton_2:  
	SBIC	PIND, PIND7		; Verifica que PD7 = 0
	ret					
	RCALL	retardo_5ms						; Deja esperar para evitar falsos positivos
	SBIC	PIND, PIND7		; Verifica de nuevo que PD7 sea 0
	ret
	ORI 	AUX, 0xFF ; Setea el flag Z=0 que sirve para detectar mas adelante que se apreto el boton 2
	ret

;Tiempo de espera de aprox 500 ms que transcurre entre prendido y apagado del led
;Verifica si el boton 2 esta presionado y si lo esta, interrumpe la subrutina

retardo_5ms:	;para 8mhz
	LDI 	TEMP1, 66				;1CM
loop0: 
	LDI 	temp2, 200				;1CM
loop1:
	dec 	TEMP2 					;1CM
	BRNE 	loop1					;2CM si Verdadero, 1CM si Falso
	dec 	TEMP1 					;1CM
	BRNE 	loop0 					;2CM si Verdadero, 1CM si Falso
ret 								;4CM


;Tiempo de espera de aprox 500 ms que transcurre entre prendido y apagado del led
;Verifica si el boton 2 esta presionado y si lo esta, interrumpe la subrutina
retardo_500ms: 
	ldi r18, 21
	ldi r19, 150
	ldi r20, 128

L1: 
	dec r20
	brne L1
	dec r19
	brne L1
	rcall Boton_2
	brne fin_retardo ; Finaliza el retardo si se aprieta el boton 2
	dec r18
	brne L1

fin_retardo:
	ret



