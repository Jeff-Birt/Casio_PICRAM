; File - ConfigCWG1.s
; Configuratiion and contorl macros for CWG1
    
PROCESSOR 16F18446  
#include <xc.inc>
    
;<editor-fold defaultstate="collapsed" desc="ConfigCWG1">----------------------- 
; Config CWG1  - All CWG1xxx on same page, only 1 BANKSEL needed
ConfigCWG1 MACRO
    BANKSEL CWG1CON1	    ; (0611) CWG1POLA non inverted, CWG1POLC non inverted
    MOVLW   0x03	    ; CWG1POLB non inverted, CWG1POLD non inverted
    MOVWF   CWG1CON1	    ;

    MOVLW   0x00	    ;
    MOVWF   CWG1DBR	    ; (060E)

    MOVLW   0x00	    ;
    MOVWF   CWG1DBF	    ; (060F)

    MOVLW   0x14	    ; CWG1LSDB tri-stated, CWG1LSAC tri-stated
    MOVWF   CWG1AS0	    ; (0612) CWG1SHUTDOWN No Auto-shutdown, CWG1REN disabled
    
    MOVLW   0x00	    ; AS2E disabled, AS5E disabled AS4E disabled;
    MOVWF   CWG1AS1	    ; (0613) AS6E disabled
    
    MOVLW   0x00	    ; CWG1STRA disabled, CWG1OVRD low, CWG1OVRA low 
    MOVWF   CWG1STR	    ; (0614) CWG1OVRB low, CWG1OVRC low
    
    MOVLW   0x00	    ;
    MOVWF   CWG1CLK	    ; (060C) CWG1CLKCON

    MOVLW   0x05	    ;
    MOVWF   CWG1ISM	    ; (060D) DAT PWM6_OUT

    MOVLW   0x85	    ; (0610) CWG1LD Buffer_not_loaded, CWG1EN enabled
    MOVWF   CWG1CON0	    ; CWG1MODE Push-Pull mode
ENDM
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="CWG_Out_ON">-----------------------
CWG_Out_ON MACRO
;    BANKSEL RA5PPS		; (1F1D) RA5->PWM6:PWM6OUT
;    MOVLW   0x0D		;
;    MOVWF   RA5PPS		;  
     
    BANKSEL RC6PPS		; (1F11)
    MOVLW   0x05		; RC6->CWG1:CWG1A
    MOVWF   RC6PPS		; 
    
    BANKSEL RC5PPS		; (1F12)
    MOVLW   0x06		; RC5->CWG1:CWG1B
    MOVWF   RC5PPS		;   
ENDM
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="CWG_Out_OFF">-----------------------
CWG_Out_OFF MACRO
    BANKSEL RA5PPS		; (1F1D) RA5->PWM6:PWM6OUT
    MOVLW   0x00		;
    MOVWF   RA5PPS		;  
    
    //BANKSEL RA1PPS		; (1F11)
    MOVLW   0x00		; RA1->CWG1:CWG1A
    MOVWF   RA1PPS		;  
    
    //BANKSEL RA2PPS		; (1F12)
    MOVLW   0x00		; RA2->CWG1:CWG1B
    MOVWF   RA2PPS		;   
ENDM
;</editor-fold> ----------------------------------------------------------------
    


