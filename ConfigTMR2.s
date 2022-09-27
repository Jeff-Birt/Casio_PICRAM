; File - ConfigTMR2.s
; Configuration and control macros for TMR2 use modes
    
PROCESSOR 16F18446
#include <xc.inc>
    
;<editor-fold defaultstate="collapsed" desc="ConfigTMR2_Idle">------------------
; Config Timer 2 - For Idle detection
ConfigTMR2_Idle MACRO 
    BANKSEL T2CLKCON		; (0290) T2CS FOSC/1;
    MOVLW   0x03		;
    MOVWF   T2CLKCON		;

    MOVLW   0x06		; T2PSYNC Not Synchd; T2MODE Resets at TMR2_ers = 0 
    MOVWF   T2HLT		; (028F) T2CKPOL Rising Edge; T2CKSYNC Not Synchd

    MOVLW   0x00;		;
    MOVWF   T2RST		; (0291) T2RSEL T2CKIPPS pin

    MOVLW   0xFF;		; T2PR 48;
    MOVWF   T2PR		; (028D) 

    MOVLW   0x00;		;
    MOVWF   T2TMR		; (028C)

    BANKSEL PIR4		; (0710) Clearing IF flag.
    BCF	    PIR4,PIR4_TMR2IF_POSN;
    
    BANKSEL T2CON		; (028E) T2CKPS 1:1; T2OUTPS 1:1; TMR2ON on; 
    MOVLW   0x80		; start, prescale of 1
    MOVWF   T2CON		;
    
    BANKSEL T2INPPS		;
    MOVLW   0x16		;
    MOVWF   T2INPPS		; RC6->TMR2:T2IN;
    
ENDM
RETURN    
;</editor-fold> ----------------------------------------------------------------
    

;<editor-fold defaultstate="collapsed" desc="ConfigTMR2_CWG">-------------------
; Config Timer 2 - For PWM / CWG use
ConfigTMR2_CWG MACRO 
    BANKSEL T2CLKCON		; (0290) T2CS FOSC/1;
    MOVLW   0x01		;
    MOVWF   T2CLKCON		;

    MOVLW   0x00		; T2CKPOL Rising Edge, T2CKSYNC Not Synchronized
    MOVWF   T2HLT		; (028F) T2PSYNC Not Synchronized, T2MODE Software control

    MOVLW   0x00;		;
    MOVWF   T2RST		; (0291) T2RSEL T2CKIPPS pin

    MOVLW   0x12;		; 444khz w/prescale of 1
    MOVWF   T2PR		; (028D) 

    MOVLW   0x00;		;
    MOVWF   T2TMR		; (028C)

    BANKSEL PIR4		; (0710) Clearing IF flag.
    BCF	    PIR4,PIR4_TMR2IF_POSN;
    
    BANKSEL T2CON		; (028E) T2CKPS 1:1; T2OUTPS 1:1; TMR2ON on; 
    MOVLW   0x80		; start, prescale of 1
    MOVWF   T2CON		;
ENDM
;</editor-fold> ----------------------------------------------------------------
    