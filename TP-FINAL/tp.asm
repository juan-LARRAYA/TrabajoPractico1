;1.El movimiento vertical será comandado por el potenciómetro conectado a la entrada analógica ADC0.
;El ojo se moverá verticalmente hacia arriba o hacia abajo, en un rango de +-45 grados respecto al centro.

;2.El movimiento horizontal será comandado por datos recibidos por el puerto serie, el cual estará conectado a la PC. 
;Los comandos a implementar serán de un caracter ASCII cada uno: 
;d: girar a la derecha 9 grados, máximo -45 grados
;i: girar a la izquierda 9 grados, máximo 45 grados

;Flash instructions:
;avrdude -c arduino -p m328p -P [COM] -U flash:w:tp.hex:i
.include "m328Pdef.inc"

;******************************************************************
; Definición de Variables y Constantes
;******************************************************************

.EQU SERVO_PORT_V 	= 	PORTB	;El puerto de PWM del SERVO_Vertical va conectado al pin PB1
.EQU SERVO_DIR_V 	= 	DDRB
.EQU SERVO_PIN_V	= 	1

.EQU SERVO_PORT_H 	= 	PORTB 	;El puerto de PWM del SERVO_Horizontal va conectado al pin PB2
.EQU SERVO_DIR_H 	= 	DDRB
.EQU SERVO_PIN_H	= 	2

.EQU POT_PORT 		=  	PORTC 	;El POTenciometro va conectado al ADC0 (PC0) 
.EQU POT_DIR 		= 	DDRC
.EQU POT_PIN 		=  	0

;Available values for test
.EQU 		COMMAND_D 	= 'd'
.EQU 		COMMAND_I 	= 'i'
.EQU 		ASTERISK 	= '*'

.EQU    F_CPU 		= 	16000000               ;Oscillator frequency (Arduino UNO runs at 16MHz)
.EQU    baud 		= 	9600                   ;baudrate
.EQU    bps    		= 	(F_CPU/16/baud) - 1    ;prescaler

;Registros auxiliares para realizar operaciones
.def    	temp 		= 	R16
.def		aux 		= 	R17
.def		num_msb 	= 	R18
.def		num_lsb 	= 	R19
.def		nivel 		=	R20
.def		nivel_2 	= 	R21
.def		cero 		=	R22


.cseg
.org 0x0000
	RJMP	onReset

; UART vector
.org UDREaddr
    RJMP	onUDREaddr

; ADC vector
.org ADCCaddr
	RJMP	onADCCaddr


;**************************************************************
; Main program
;**************************************************************

onReset:
	;Stack pointer init
	LDI		temp, LOW(RAMEND)   
	out		spl, temp
	LDI   	temp, HIGH(RAMEND)   
	out   	sph, temp

	;Initialize ADC
	RCALL	adcInit
	  
	;Initialize UART     
	LDI		R16, LOW(bps) 
	LDI    	R17, HIGH(bps)
	RCALL  	uartInit                   
	RCALL   uartInterruptEnable
	;Global de interrupt enable
	SEI

	RCALL 	Configure_ports 
	RCALL 	Configure_Timer1	

	;Valor de TOP, 8 bits más significativos
	LDI 	aux, 0b10011100 	;156
	sts 	ICR1H, aux

	;Valor de TOP, 8 bits menos significativos
	LDI 	aux, 0b00111111 	;63
	sts 	ICR1L, aux

	;Se inicializan los servos
	LDI 	nivel, 0
	LDI 	nivel_2, 4

	LDI 	cero, 0 		;Registro con  valor cero

	RCALL 	duty_cycle
	RCALL	duty_cycle_2

;main loop
mainLoop:
  	RJMP    mainLoop

;******************************************************************
; 		INTERRUPCIONES
;******************************************************************
onUDREaddr:
    push	temp
    in      temp, sreg
    push    temp

    call	uart_isr  

	pop     temp
	out     sreg, temp
    pop     temp
    RETI

onADCCaddr:
	push	temp
    in      temp,sreg
    push    temp

    call	adc_isr  

	pop     temp
	out     sreg, temp
    pop     temp
    RETI

;Custom UART ISR
uart_isr:
;For the ADC test, it just takes the latest sample from the ADC and sends it out
	STS     UDR0, R24		;PARA ADC.

;check Rx flag	
	lds 		temp, UCSR0A
	SBRS		temp, RXC0		;si rx(recibe)Comlete 
	RJMP		uart_isr_end		
	lds			temp, UDR0
	CPI			temp, COMMAND_D
	BREQ		derecha
	CPI			temp, COMMAND_I
	BREQ		izquierda
;the default case is to send an asterisk
	LDI			temp, ASTERISK

uart_isr_end:
	call 		duty_cycle_2
	ret

derecha:
	CPI 		nivel_2, 10
	BREQ 		uart_isr_end
	inc 		nivel_2
	RJMP 		uart_isr_end

izquierda:
	CPI 		nivel_2, 0
	BREQ 		uart_isr_end
	dec 		nivel_2
	RJMP 		uart_isr_end

; Custom ADC ISR
adc_isr:
    lds 		R24, ADCL
    lds			R24, ADCH
    
	LDI			nivel, 0
	CPI			R24, 24
	BRLO		end_nivel
	LDI			nivel, 1
	CPI			R24, 48
	BRLO		end_nivel
	LDI			nivel, 2
	CPI			R24, 72
	BRLO		end_nivel
	LDI			nivel, 3
	CPI			R24, 96
	BRLO		end_nivel
	LDI			nivel, 4
	CPI			R24, 120
	BRLO		end_nivel
	LDI			nivel, 5
	CPI			R24, 144
	BRLO		end_nivel
	LDI			nivel, 6
	CPI			R24, 168
	BRLO		end_nivel
	LDI			nivel, 7
	CPI			R24, 192
	BRLO		end_nivel
	LDI			nivel, 8
	CPI			R24, 216
	BRLO		end_nivel
	LDI			nivel, 9
	CPI			R24, 240
	BRLO		end_nivel
	LDI			nivel, 10
	
end_nivel:
	call		duty_cycle
  	ret

;PB1 - PWM1
duty_cycle:
;MSB
	LDI 		ZL, LOW(segmento_msb<<1)
	LDI 		ZH, HIGH(segmento_msb<<1)
	add 		ZL, nivel
	adc 		ZH, cero

	;Ciclo de trabajo, 8 bits más significtivos
	LPM 		num_msb, Z
	STS 		OCR1AH, num_msb

	;LSB
	LDI 		ZL, LOW(segmento_lsb<<1)
	LDI 		ZH, HIGH(segmento_lsb<<1)
	add 		ZL, nivel
	adc 		ZH, cero

	;Ciclo de trabajo, 8 bits menos significtivos
	LPM 		num_lsb, Z
	STS 		OCR1AL, num_lsb
	ret


; PB2 - PWM2
duty_cycle_2:
	;MSB
	LDI 		ZL, LOW(segmento_msb<<1)
	LDI 		ZH, HIGH(segmento_msb<<1)
	add 		ZL, nivel_2
	adc 		ZH, cero

	;Ciclo de trabajo, 8 bits más significtivos
	LPM 		num_msb, Z
	STS 		OCR1BH, num_msb

	;LSB
	LDI 		ZL, LOW(segmento_lsb<<1)
	LDI 		ZH, HIGH(segmento_lsb<<1)
	add 		ZL, nivel_2
	adc 		ZH, cero

	;Ciclo de trabajo, 8 bits menos significtivos
	LPM 		num_lsb, Z
	STS 		OCR1BL, num_lsb
	ret

;******************************************************************
; 			Configuracion 
;******************************************************************
adcInit:
	push	temp

;Enable ADC, Auto trigger, Enable Interrupt, pre-scaler = 128
  	LDI		temp, (1<<ADEN)|(1<<ADATE)|(1<<ADSC)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
  	STS     ADCSRA, temp
;Use AVCC and A0 as input to ADC, left adjust the conversion
  	LDI     temp, (1<<REFS0)|(1<<ADLAR)	      
  	STS     ADMUX, temp 
  	
  	pop     temp
  	ret

uartInit: 		;
;prescaler (baudrate)
	STS		UBRR0L, R16                    
  	STS     UBRR0H, R17

;enable transmission and reception
  	lds     R16, (1<<RXEN0)|(1<<TXEN0)
  	STS     UCSR0B, R16                   
; Asynchronous USART, Disabled parity mode,
;2 Stop Bit Select, 8 bit character size
  	lds     R16, (1<<UCSZ00)|(1<<UCSZ01)|(1<<USBS0)
  	STS     UCSR0C, R16
	ret

uartInterruptEnable:
	push	temp

    lds     temp, UCSR0B       
    sbr     temp, (1<<UDRIE0)
    STS     UCSR0B, temp

	pop		temp
    ret

Configure_ports:
	CBI 		POT_DIR, POT_PIN 		;Configura PC0 como entrada
	SBI 		POT_PORT, POT_PIN 	 	;Activa la resistencia de pull up

	;Configurar PB1 como salida
	SBI 		SERVO_DIR_V, SERVO_PIN_V

	;Configurar PB2 como salida
	SBI 		SERVO_DIR_H, SERVO_PIN_H
	ret

Configure_Timer1:
	CLR			AUX				;Inicializa el contador en 0
	STS			TCNT1H, AUX
	STS			TCNT1L, AUX
	
	;Clear OC1A AND OC1B on compare match(set output to low level)
	lds			AUX, TCCR1A		
	ORI			AUX, (1 << WGM11)|(1 << COM1A1)|(1 << COM1B1)		
	ANDI		AUX, ~((1<< WGM10)|(1 << COM1A0)|(1 << COM1B0))	
	STS			TCCR1A, AUX							
	;fast PWM mode, clk(I/O)/8 (from prescaler)
	lds			AUX, TCCR1B							
	ORI			AUX, (1<< WGM13)|(1<< WGM12)|(1 << CS11)
	ANDI		AUX, ~((1 << CS12)|(1 << CS10))	
	STS			TCCR1B, AUX		
	
	ret
;******************************************************************
; 				Tablas
;******************************************************************
;ESTOS SON LOS VALORES QUE HACEN AL SERVO MOVERSE DE A 9GRADOS ENTRE +-45 GRADOS

;Tabla con los 8 bits más significativos para el servo
segmento_msb:
	.db 0x03, 0x04, 0x05, 0x06, 0x07, 0x07, 0x08, 0x09, 0x0A, 0x0A, 0x0B

;Tabla con los 8 bits menos significativos para el servo
segmento_lsb:
	.db 0xE8, 0xB0, 0x78, 0x40, 0x08, 0xD0, 0x98, 0x60, 0x28, 0xF0, 0xB8

;tabla en binario 
;HEX	BIN 			DEC
; 3E8 	0011 1110 1000 	1000
; 4B0	0100 1011 0000  1200
; 578	0101 0111 1000  1400
; 640	0110 0100 0000  1600
; 708	0111 0000 1000  1800
; 7D0	0111 1101 0000  1900
;ETC











