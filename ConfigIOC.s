; File - ConfigIOC.s
; Configuratiion of Interrupt On Change settings
    
PROCESSOR 16F18446
#include <xc.inc>
 
;<editor-fold defaultstate="collapsed" desc="ConfigIOC_R">---------------------- 
; Config IOC For Casio general bus monitoring
ConfigIOC_R MACRO 
    BANKSEL PIE0		    ; (2) Periph Interrupt Enable register
    BSF	    PIE0,4		    ; (1) Enable Interrupt-on-Change
    BANKSEL IOCCN		    ; (2) Interrupt on negitive edge register
    CLRF    IOCCN		    ; (1) clear out any previous settings
    CLRF    IOCCP		    ; (1) clear out any previous settings
    BSF	    IOCCN,4		    ; (1) PortC Bit4, /OP, int on negative edge
    BSF	    IOCCN,5		    ; (1) PortC Bit5, CLK2, int on negative edge
    BSF	    IOCCN,6		    ; (1) PortC Bit6, CLK1, int on negative edge
    BSF	    IOCCN,7		    ; (1) PortC Bit7, /CE1, int on negative edge
    BANKSEL IOCCF		    ; (2) IOC flags register
    CLRF    IOCCF		    ; (1) [14] clear interrupts
ENDM
;</editor-fold> ---------------------------------------------------------------- 
    
    
;<editor-fold defaultstate="collapsed" desc="ConfigIOC_I">---------------------- 
; Config IOC For Casio idle mode detection
; CLK1 interruts on falling edge, /CE1 triggers on rising edge
ConfigIOC_I MACRO 
    BANKSEL PIE0		    ; Periph Interrupt Enable register
    BSF	    PIE0,4		    ; Enable Interrupt-on-Change
    BANKSEL IOCCN		    ; Interrupt on negitive edge register
    CLRF    IOCCN		    ; clear out any previous settings
    CLRF    IOCCP		    ; clear out any previous settings
    BSF	    IOCCN,6		    ; PortC Bit6, CLK1, int on negative edge
    ;BSF	    IOCCP,6		    ; PortC Bit6, CLK1, int on positive edge
    BSF	    IOCCP,7		    ; PortC Bit7, /CE1, int on negative edge
    BANKSEL IOCCF		    ; IOC flags register
    MOVLW   0x00		    ; Clear flags before starting
    MOVWF   IOCCF		    ; clear interrupts
ENDM
;</editor-fold> ---------------------------------------------------------------- 

