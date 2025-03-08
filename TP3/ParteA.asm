;parte a
;******************************************************************
; Definición de Variables y Constantes
;******************************************************************
.include "m328pdef.inc"

;El led va conectado al pin PB1 y los pulsadores a los pines PD2-3
.EQU LED_PORT 	= 	PORTB
.EQU LED_DIR 	= 	DDRB
.EQU LED_PIN 	= 	1

.EQU PUL_PORT 	=  	PORTD 
.EQU PUL_DIR 	= 	DDRD
.EQU PUL_PIN 	=  	PIND

;Registros auxiliares para realizar operaciones
.def AUX				= 	R16 
.def pulsador			= 	R17
.def step				= 	R18
.def CERO				=	R19

;Se inicializa la RAM
.DSEG 
.ORG SRAM_START	 

;Inicio del codigo
.CSEG 
.ORG 0x0000
	RJMP	START
.ORG INT0addr
	RJMP Handler_int
.ORG INT1addr	
	RJMP Handler_int
.org INT_VECTORS_SIZE


;Se inicializa el Stack Pointer al final de la RAM utilizando la definicion global RAMEND
START:
	LDI		AUX, HIGH(RAMEND)
	out		sph, AUX
	LDI		AUX, LOW(RAMEND)
	out		spl, AUX

;Se configuran los puertos y los timers
	RCALL	Configure_ports
	RCALL	Configure_Timer1

;Se configuran y habilitan las interrupciones externas
	RCALL	Configure_INT
	RCALL	Enable_INT
	LDI		step, 17 		;Se carga el paso para cambiar el brillo, hay 16 niveles de brillo
	LDI		CERO, 0x00
	SEI 					;Se habilitan las interrupciones globales

main_loop:
	RCALL	set_duty_cycle
	RJMP	main_loop

;******************************************************************
;                          Configuración 
;******************************************************************

Configure_ports: 	
	SBI 	LED_DIR, LED_PIN 					;Configura PB1 como salida

	in 		AUX, PUL_DIR 
	ANDI 	AUX, ~((1 << DDD2)|(1 << DDD3)) 	;Configura PD2-3 como entrada
	OUT 	PUL_DIR, AUX

	in 		AUX, PUL_PORT
	ORI 	AUX, ((1 << DDD2)|(1 << DDD3))  	;Activa la resistencia de pull up para los pulsadores             
	OUT 	PUL_PORT, AUX

	ret

;Configura Timer1 en Fast PWM de 8 bits sin prescaler
;Habilita el modo Compare Output con OCR1A en modo no inversor
;de forma que la primera parte del periodo este en estado alto 
;y en estado bajo luego de la comparacion 
Configure_timer1:	
	CLR		AUX				;Inicializa el contador en 0
	STS		TCNT1H, AUX
	STS		TCNT1L, AUX
	
	lds		AUX, TCCR1A
	ORI		AUX, (1 << WGM10)|(1 << COM1A1)		
	ANDI	AUX, ~((1<< WGM11)|(1 << COM1A0))	
	STS		TCCR1A, AUX							
	
	lds		AUX, TCCR1B							
	ORI		AUX, (1<< WGM12)|(1 << CS10)
	ANDI	AUX, ~((1 << CS12)|(1 << CS11)|(1<< WGM13))	
	STS		TCCR1B, AUX		
	
	LDI		AUX, 255 		;Comienza con un duty cycle de 100% 
	STS		OCR1AL, AUX 
	ret

;Configura INT0 e INT1 por flanco descendente 
Configure_int:
	lds		AUX, EICRA
	ORI		AUX, (1 << ISC01)
	ANDI	AUX, ~( (1 << ISC00) )	
	STS		EICRA, AUX

	lds		AUX, EICRA
	ORI		AUX, (1 << ISC11)
	ANDI	AUX, ~( (1 << ISC10) )	
	STS		EICRA, AUX

	ret

;Habilita las interrupciones externas
Enable_int:
	in 		AUX, EIMSK
	ORI 	AUX, (1<<INT0)|(1<<INT1)
	out 	EIMSK, AUX

	ret

;******************************************************************
;                          Duty Cycle
;******************************************************************

;Lee el estado de los pulsadores y cambia el duty cycle del led
set_duty_cycle:	
	CPI		pulsador, 0x04			;PD3 PD2 = 0 1
	BREQ	lower_brightness
	CPI		pulsador, 0x08			;PD3 PD2 = 1 0
	BREQ    increase_brightness
	RJMP	end_set_duty_cycle 

;Disminuye un nivel de brillo del led
lower_brightness:
	lds		AUX, OCR1AL
	sub		AUX, step
	BRCS	end_set_duty_cycle 		;No se disminuye mas si esta en el limite inferior
	STS		OCR1AH, CERO
	STS		OCR1AL, AUX
	
	RJMP end_set_duty_cycle

;Aumenta un nivel de brillo del led
increase_brightness:
	lds		AUX, OCR1AL 
	add		AUX, step 
	BRCS	end_set_duty_cycle 		;No se aumenta mas si esta en el limite superior
	STS		OCR1AH, CERO
	STS		OCR1AL, AUX

end_set_duty_cycle:
	in		pulsador, PUL_PIN 				;Guarda el estado de los pulsadores
	ANDI	pulsador, 0x0C					;0000 1100 
	ret 

;******************************************************************
;                          Interrupciones 
;******************************************************************

;Activa el timer0 para la rutina de debounce
Handler_Int:
	push	AUX
	in		AUX, SREG
	push	AUX
	
	in		pulsador, PUL_PIN 				;Guarda el estado de los pulsadores
	ANDI	pulsador, 0x0C					;0000 1100
	
	RCALL   debounce_time          ;tiempo anti revote para evitar falsos positivos

End_int:
	pop		AUX
	out		SREG, AUX
	pop		AUX
	reti

;******************************************************************
;                          Retardo
;******************************************************************

;Calculo del retardo
;( 3 + [ (1 + 2) * 127 + (1 + 1) ] + [ 127 * ( (1 + 2) * 149 + (1 + 1) ) ] + [ 149 * 127 * ((1 + 2) * 2 +1+1) ])/8000000 
;t = 0.0261s = 26ms
debounce_time:
	LDI     R18, 3              ;1CM
	LDI     R19, 150            ;1CM
	LDI     R20, 128            ;1CM
L2:
	dec     R20                 ;1CM
	BRNE    L2                  ;2CM si Verdadero, 1CM si Falso
	dec     R19                 ;1CM
	BRNE    L2                  ;2CM si Verdadero, 1CM si Falso
	dec     R18                 ;1CM
	BRNE    L2                  ;2CM si Verdadero, 1CM si Falso
	ret                         ;4CM





