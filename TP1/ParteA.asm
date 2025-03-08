;ParteA.asm

.include "m328pdef.inc"

 
; Defino las constantes del programa

.equ LED_PORT_D = PORTD
.equ LED_PIN = 2

;ALIAS DE LOS REGISTROS.
.def TEMP1 	= 	R18
.def TEMP2 	= 	R19
.def TEMP3 	= 	R20
.def AUX 	= 	R21


;Inicio del codigo
.cseg 
.org 0x0000
; Segmento de datos en memoria de codigo

; Se inicializa el Stack Pointer al final de la RAM utilizando la definicion global RAMEND
	LDI		AUX,HIGH(RAMEND)
	out		sph,AUX
	LDI		AUX,LOW(RAMEND)
	out		spl,AUX


		
main:
			
; Led en PD2 
; Configuro puerto D
			LDI		AUX,(1 << DDD2)	;(PORTD PD2  como salida) 
			out		DDRD,AUX

; rutina de encendido y apagado
		
prendo:		
	SBI		LED_PORT_D, LED_PIN 	; encendido del led conectado en el pin 2 
	
	RCALL 	retardo_500ms			;espera
			
	CBI		LED_PORT_D,LED_PIN		; apagado del led

	RCALL 	retardo_500ms

	RJMP	prendo		; reinicio el ciclo

retardo_500ms: 
	ldi r18, 21
	ldi r19, 150
	ldi r20, 128
L1: 
	dec r20
	brne L1
	dec r19
	brne L1
	dec r18
	brne L1
	ret

