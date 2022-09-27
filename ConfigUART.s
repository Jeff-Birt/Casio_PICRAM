; File - ConfigUART.s
; Configuratiion macro for UART
    
PROCESSOR 16F18446
#include <xc.inc>
    
;<editor-fold defaultstate="collapsed" desc="ConfigUART">----------------------- 
; Configure UART
ConfigUART MACRO
    BANKSEL BAUD1CON		; ABDOVF no_overflow;
    movlw   0x08		; SCKP Non-Inverted; BRG16 16bit_generator;
    movwf   BAUD1CON		; WUE disabled; ABDEN disabled; 
    
    BANKSEL RC1STA		; SPEN enabled; RX9 8-bit;    
    movlw   0x90		; CREN enabled; 
    movwf   RC1STA		; 
    
    BANKSEL TX1STA		;
    movlw   0x24		; CONFIGURE SPBRG FOR DESIRED BAUD RATE
    movwf   TX1STA		; 
    
    BANKSEL SP1BRGL		;
    movlw   0xA0		; baud rate =  19200bps, at 32MHZ / 1
    ;movlw   0x40		; baud rate =  9600bps, at 32MHZ / 1
    movwf   SP1BRGL		;
    
    movlw   0x01		; baud rate =  19200bps, at 32MHZ / 1
    ;movlw   0x03		; baud rate =  9600bps, at 32MHZ / 1
    movwf   SP1BRGH		;  
       
    BANKSEL RB4PPS		; Sets RB4 as TX output pin
    movlw   0x0F		; overriedes TRISB
    movwf   RB4PPS		;//RB4->EUSART1:TX1
    
    BANKSEL RX1PPS		; Sets RB6 as RX input pin
    MOVLW   0x0E		; overriedes TRISB
    MOVWF   RX1PPS		;//RB5->EUSART1:RX1
ENDM
;</editor-fold> ----------------------------------------------------------------

