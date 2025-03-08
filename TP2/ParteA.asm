;parte a 

.include "m328pdef.inc"

.equ PUL_PIN        =   PIND
.equ PUL_BIT_1      =   2
.equ PUL_BIT_2      =   3

.equ LED_DIR_AD     =   DDRB
.equ LED_PORT_AD    =   PORTB

.equ LED_DIR_EG     =   DDRC
.equ LED_PORT_EG    =   PORTC

;Ubicaciones en la EEPROM de las posiciones iniciales y finales de la tabla y del puntero LP

.equ tabla_inicio   =   0x02
.equ tabla_fin      =   0x16
.equ ultima_posicion =  0x17

;Registros auxiliares para realizar operaciones

.def AUX            =   R16
.def TEMP           =   R17
.def counter        =   R23		
.def value_seg      =   R24
.def value_seg_aux  =   R25


;Se inicializa la RAM

.dseg
.org SRAM_START


;Inicio del codigo
.cseg
.org 0x0000
RJMP    inicio
.org INT0addr
RJMP    Handler_Int_Ext0
.org INT1addr
RJMP    Handler_Int_Ext1
.org INT_VECTORS_SIZE


inicio:

;Se inicializa el Stack Pointer al final de la RAM utilizando la definicion global RAMEND
LDI     AUX, HIGH(RAMEND)
out     sph, AUX
LDI     AUX, LOW(RAMEND)
out     spl, AUX


tabla_ok:
RCALL   configurar_puertos
RCALL   chequear_display        ;Rutina de inicio del display

;Se configuran y habilitan las interrupciones
RCALL   configure_int0
RCALL   configure_int1

RCALL   enable_int0
RCALL   enable_int1

SEI

inactivo:
RJMP    inactivo

configurar_puertos:

LDI     AUX, 0x00               ;Configura los pines D2 y D3 como entrada, el resto queda como entrada por defecto
out     DDRD, AUX

LDI     TEMP, 0x0F              ;Configura los pines B0, B1, B2 y B3 como salida, el resto queda como entrada por defecto

out     LED_DIR_AD, TEMP
out     LED_PORT_AD, AUX        ;Inicializa los valores de los pines de los leds en 0

LDI     TEMP, 0x07              ;Configura los pines C0, C1 y C2 como salida, el resto queda como entrada por defecto
out     LED_DIR_EG, TEMP
out     LED_PORT_EG, AUX        ;Inicializa los valores de los pines de los leds en 0

ret


 /******************************************************************************
                    Interrupciones
 ******************************************************************************/

;Configura la interrupcion 0 por flanco ascendente
configure_int0:
lds     TEMP, EICRA
ORI     TEMP, (1 << ISC00) | (1 << ISC01)
STS     EICRA, TEMP
ret

;Configura la interrupcion 1 por flanco ascendente
configure_int1:
lds     TEMP, EICRA
ORI     TEMP, (1 << ISC10) | (1 << ISC11)
STS     EICRA, TEMP
ret

;Habilita la interrupcion 0
enable_int0:
in      TEMP, EIMSK
ORI     TEMP, (1 << INT0)
out     EIMSK, TEMP
ret

;Habilita la interrupcion 1
enable_int1:
in      TEMP, EIMSK
ORI     TEMP, (1 << INT1)
out     EIMSK, TEMP
ret


;Instruccion que se ejecuta cuando se pulsa el boton 1, decrementa en 1 LP mientras siga estando en la tabla y muestra el valor en el display
Handler_Int_Ext0:
push    TEMP
in      TEMP, SREG             ;Guarda SREG en el stack

push    TEMP


RCALL   debounce_time          ;Deja esperar para evitar falsos positivos
SBIS    PUL_PIN, PUL_BIT_1     ;Verifica de nuevo que PD2 sea 1
RJMP    end_routine_int0

CPI     AUX, tabla_fin         ;Se fija si LP apunta al final de la tabla para no incrementarlo
BREQ    end_routine_int0
inc     AUX
RCALL   mostrar_display

end_routine_int0:

pop     TEMP

out     SREG, TEMP             ;Recupera SREG
pop     TEMP
reti

;Instruccion que se ejecuta cuando se pulsa el boton 2, 
;decrementa en 1 LP mientras siga estando en la tabla y muestra el valor en el display
Handler_Int_Ext1:
push    TEMP
in      TEMP, SREG             ;Guarda SREG en el stack
push    TEMP
PUSH    AUX


RCALL   debounce_time          ;Deja esperar para evitar falsos positivos
SBIS    PUL_PIN, PUL_BIT_2     ;Verifica de nuevo que PD3 sea 1
RJMP    end_routine_int1

CPI     AUX, tabla_inicio      ;Se fija si LP apunta al inicio de la tabla para no decrementarlo
BREQ    end_routine_int1
dec     AUX

RCALL   mostrar_display

end_routine_int1:
pop     AUX
pop     TEMP
out     SREG, TEMP             ;Recupera el SREG
pop     TEMP
reti

/******************************************************************************
Display
******************************************************************************/

;Recibe un caracter que este entre 0 y F y lo muestra en el display

mostrar_display:

;Funcion lookuptable: recibe un caracter, busca su par correspondiente en tabla_display y lo guarda en value_seg

LDI     ZH, HIGH(tabla_display<<1)
LDI     ZL, LOW(tabla_display<<1)
LDI     TEMP, 0
add     ZL, AUX
adc     ZH, TEMP
LPM     value_seg, z

;Traduce el valor contenido en value_seg para que se muestre en el display el caracter correspondiente

mov     value_seg_aux, value_seg
LDI     TEMP, 0x0F
and     value_seg, TEMP
SWAP    value_seg_aux
and     value_seg_aux, TEMP
out     LED_PORT_AD, value_seg_aux     ;enciende los leds
out     LED_PORT_EG, value_seg          
ret


;Muestra en el display las letras A B C D E F con un delay entre cada una y por ultimo muestra el valor de la direccion a la que apunta LP
chequear_display:
LDI     AUX, 0x0A
LDI     counter, 0x06       ;Muestra 6 caracteres

loop_chequear_display:
RCALL   mostrar_display
RCALL   retardo_500ms
inc     AUX
dec     counter
BRNE    loop_chequear_display

ret


/******************************************************************************
                            Retardos
******************************************************************************/


; Tiempo de espera de aproximadamente 40ms para evitar el efecto rebote del boton

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


;Tiempo de espera de aproximadamente 500 ms que transcurre mientras se muestra un caracter

;Calculo del retardo de 500ms considerando que el boton 2 no se apreta
;3 + [ (1 + 2) * 127 + (1 + 1) ] + [ 255 * ( (1 + 2) * 149 + (1 + 1) ) ] + [ 255 * 255 * ((1 + 2) * 40 +2)) ] = #CM
; 1CM = 6.25E-8 s --> #CM = 804397 --> t = 0.503 s
retardo_500ms:
LDI     R18, 41
LDI     R19, 150
LDI     R20, 128

L1:
dec     R20                 ;1CM
BRNE    L1                  ;2CM si Verdadero, 1CM si Falso
dec     R19                 ;1CM
BRNE    L1                  ;2CM si Verdadero, 1CM si Falso
dec     R18                 ;1CM
BRNE    L1                  ;2CM si Verdadero, 1CM si Falso

fin_retardo:
ret

/******************************************************************************
                           Tablas
******************************************************************************/

;Firma ubicada antes de la tabla que indica que la EEPROM ya esta grabada
firma:
.db 0x20,0x21

;Tabla que se guarda en la EEPROM para luego ser mostrada en el display
;El ultimo valor corresponde al vector LP que apunta inicialmente a la primera posicion de la tabla
tabla_eeprom:
.db 0x00,0x02,0x04,0x06,0x08,0x0A,0x0C,0x0E,0x0F,0x0D,0x0B,0x09,0x07,0x05,0x03,0x01,0x00,0x0F,0x00,0x0A,0x08,0x02

;Contiene la informacion para mostrar en el display cada caracter en orden creciente
;El nibble alto corresponde a los leds del puerto B y los del nibble bajo a los del puerto C
tabla_display:
.db 0xF3, 0x60, 0xB5, 0xF4, 0x66, 0xD6, 0xD7, 0x70, 0xF7, 0x76, 0x77, 0xC7, 0x93, 0xE5, 0x97, 0x17



