ParteA.asm


.include "m2560def.inc"

.cseg 
.org 0x0000
			jmp		main

.org INT_VECTORS_SIZE
main:
			
; Led en PB5 
; Configuro puerto B
			ldi		r20,0xf0	;(PORTB como salida)
			out		DDRB,r20

; rutina de encendido y apagado
		
prendo:		sbi		PORTB,7 	; encendido del led  5=uno  7=mega
	

demora1:
			ldi 	r20,0x00
			ldi 	r21,0x00
			ldi		r22,0x3
ciclo1:		inc		r20
			cpi		r20,0xff
			brlo	ciclo1
			ldi		r20,0x00
			inc		r21
			cpi		r21,0xff
			brlo	ciclo1
			ldi		r21,0x00
			inc		r22
			cpi		r22,0x20
			brlo	ciclo1
			
			
			cbi		PORTB,7		; apagado del led

demora2:
			ldi 	r20,0x00
			ldi 	r21,0x00
			ldi		r22,0x10
ciclo2:		inc		r20
			cpi		r20,0xff
			brlo	ciclo2
			ldi		r20,0x00
			inc		r21
			cpi		r21,0xff
			brlo	ciclo2
			ldi		r21,0x00
			inc		r22
			cpi		r22,0x20
			brlo	ciclo2


			RJMP	prendo		; reinicio el ciclo



;HACER PARPADEAR EL LED CONECTADO EN EL PIN 2		(Usar la rutina de retardo Dada).


;Realizar un informe con el diagrama esquemático del hardware, un diagrama en bloques del código y demás requisitos del informe (Informe.pdf)


























