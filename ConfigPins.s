; File - ConfigPins.s
; Configuration of default values for I/O pins
    
PROCESSOR 16F18446
#include <xc.inc>
    
;<editor-fold defaultstate="collapsed" desc="ConfigPins">-----------------------
; Config PINs    
ConfigPins MACRO
    ;Set up PortA
    BANKSEL PORTA		; (000C)
    MOVLW   0x00		; 
    MOVWF   PORTA		; Init PORTA
    
    MOVLW   0x00		; (0018) Enable latch for bit 2
    MOVWF   LATA		;
    
    MOVLW   0x00		; (0012), Bit 2 (LED) output
    MOVWF   TRISA		; rest are inputs
    
    MOVLW   0x00		; digital I/O 
    MOVWF   ANSELA		; (1F38)
    
    BANKSEL WPUA		; 
    MOVLW   0x00	        ; no pullups
    MOVWF   WPUA		; (1F39)
    
    MOVLW   0x00		;
    MOVWF   ODCONA		; (1F3A) not open drain
    
    MOVLW   0x37		; slew rate control on all pins
    MOVWF   SLRCONA		; (1F3B) 
    
    MOVLW   0x3F		; Set all port A for ST input level?
    MOVWF   INLVLA		; (1F3C)
    
    
    ;Set up PortB
    BANKSEL PORTB		; (000D)
    CLRF    PORTB		; Init PORTB
    
    MOVLW   0x00		; 
    MOVWF   LATB		; (0019) Data Latch
    
    MOVLW   0x7F		; Set all (available) pins as inputs
    MOVWF   TRISB		; (001B)
    
    BANKSEL ANSELB		; (1F43)
    MOVLW   0x00		; all digital I/O
    MOVWF   ANSELB		;
    
    MOVLW   0x20		; pullup on pin 5
    MOVWF   WPUB		; (1F44)
    
    MOVLW   0x00		;
    MOVWF   ODCONB		; (1F45) not open drain
    
    MOVLW   0xF0		; 
    MOVWF   SLRCONB		; (1F46) slew rate control
    
    MOVLW   0xF0		;
    MOVWF   INLVLB		; (1F47) Set all port A for ST input level?
    
    
    ;Set up PortC
    BANKSEL PORTC		; (000E)
    CLRF    PORTC		; Init PORTC
    
    MOVLW   0x00		; 
    MOVWF   LATC		; (001A) Data Latch
       
    MOVLW   0x9F		; Bit 5 output, rest inputs
    MOVWF   TRISC		; (0014)
    
    BANKSEL ANSELC		; 
    MOVLW   0x00		; all digital I/O
    MOVWF   ANSELC		; (1F4E)

    MOVLW   0x00		; no pullups
    MOVWF   WPUC		; (1F4F)
    
    MOVLW   0x00		; no open drain
    MOVWF   ODCONC		; (1F50) 
    
    MOVLW   0xFF		; Slew rate control on all pins
    MOVWF   SLRCONC		; (1F51) 
    
    MOVLW   0xFF		;
    MOVWF   INLVLC		; (1F52) Set all port A for ST input level?
ENDM
;</editor-fold> ----------------------------------------------------------------
    
