; File - ConfigPWM6.s
; Configuration of PWM6 used for CWG1
    
PROCESSOR 16F18446  
#include <xc.inc>

;<editor-fold defaultstate="collapsed" desc="ConfigCWG1">-----------------------
; Config PWM6    
ConfigPWM6 MACRO
    BANKSEL PWM6CON	; (038E) PWM6POL active_lo; PWM6EN enabled; 
    MOVLW   0x90;	; polarity inverted (active low)
    MOVWF   PWM6CON	; 
    
    MOVLW   0x0C	; 22% w/prescale of 1
    MOVWF   PWM6DCH	; (038D)

    MOVLW   0x00	; 22% w/prescale of 1
    MOVWF   PWM6DCL	; (038C)
    
    BANKSEL CCPTMRS1	; (021F) Select timer
    BSF	    CCPTMRS1,CCPTMRS1_P6TSEL_POSN;
ENDM
;</editor-fold> ----------------------------------------------------------------
