;parte b
;******************************************************************
; Definición de Variables y Constantes
;******************************************************************
.include "m328pdef.inc"

;El SERVO va conectado al pin PB1 y los pulsadores a los pines PD2-3
.EQU SERVO_PORT = 	PORTB
.EQU SERVO_DIR 	= 	DDRB
.EQU SERVO_PIN 	= 	1

.EQU POT_PORT 	=  	PORTC 
.EQU POT_DIR 	= 	DDRC
.EQU POT_PIN 	=  	0


;Registros auxiliares para realizar operaciones
.def AUX				= 	R16 
.def Vin				= 	R17
.def CERO				=	R19

;Se inicializa la RAM
.DSEG 
.ORG SRAM_START	 

;Inicio del codigo
.CSEG 
.ORG 0x0000
	RJMP	START
.ORG 0x002A
    RJMP 	adc_isr
.org INT_VECTORS_SIZE

;Se inicializa el Stack Pointer al final de la RAM utilizando la definicion global RAMEND
START:
	LDI		AUX, HIGH(RAMEND)
	out		sph, AUX
	LDI		AUX, LOW(RAMEND)
	out		spl, AUX

;Se configuran los puertos y los timers
	RCALL	Configure_ports
	RCALL 	Configure_ADC
	RCALL	Configure_Timer1
	LDI		CERO, 0x00
	SEI 					;Se habilitan las interrupciones globales

main_loop:
	RCALL	set_duty_cycle
	RJMP	main_loop

;******************************************************************
;                          Configuración 
;******************************************************************

Configure_ports: 	
	SBI 	SERVO_DIR, SERVO_PIN 	;Configura PB1 como salida

	CBI 	POT_DIR, POT_PIN 		;Configura PC0 como entrada
	SBI 	POT_PORT, POT_PIN 	 	;Activa la resistencia de pull up

	ret
;configura el conversor para que lea y convierta la entrada 
;del porenciometro (PC0 = ADC0)
Configure_ADC:
;Enable ADC, Auto trigger, Enable Interrupt, pre-scaler = 128
  	LDI		AUX, (1<<ADEN)|(1<<ADATE)|(1<<ADSC)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
  	STS     ADCSRA, AUX
;Use AVCC and A0 as input to ADC, left adjust the conversion
  	LDI     AUX, (1<<REFS0)|(1<<ADLAR)	      
  	STS     ADMUX, AUX 
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
	ori		AUX, (1 << WGM10)|(1 << COM1A1)		
	andi	AUX, ~((1<< WGM11)|(1 << COM1A0))	
	sts		TCCR1A, AUX							
	
	lds		AUX, TCCR1B							
	ori		AUX, (1<< WGM12)|(1 << CS10)
	andi	AUX, ~((1 << CS12)|(1 << CS11)|(1<< WGM13))	
	sts		TCCR1B, AUX		
	
	LDI		AUX, 255 		;Comienza con un duty cycle de 100% 
	STS		OCR1AH, CERO 
	STS		OCR1AL, AUX 
	ret

;******************************************************************
;                          Duty Cycle
;******************************************************************

;cambia el duty cycle del SERVO
set_duty_cycle:	
	;agrego un pequeño retardo para que no este
	;cambiado de valor todo el tiempo
	RJMP 	delay		
	STS		OCR1AH, CERO
	STS		OCR1AL, Vin

end_set_duty_cycle: 
	ret 

;******************************************************************
;                          Interrupciones 
;******************************************************************

adc_isr:
    lds 	Vin, ADCL
    lds 	Vin, ADCH
RETI

;******************************************************************
;                          Retardo
;******************************************************************

;Calculo del retardo
;( 3 + [ (1 + 2) * 127 + (1 + 1) ] + [ 127 * ( (1 + 2) * 149 + (1 + 1) ) ] + [ 149 * 127 * ((1 + 2) * 2 +1+1) ])/8000000 
;t = 0.0261s = 26ms
delay:
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


















