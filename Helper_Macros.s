; File - Helper_Macros.s
; Misc macros
    
PROCESSOR 16F18446  
#include <xc.inc>
    
;<editor-fold defaultstate="collapsed" desc="SetState">-------------------------
; Set State
SetState    MACRO   state
    BANKSEL PSTATE		    ; (2)
    MOVLW   state		    ; (1) program state
    MOVWF   PSTATE		    ; (1) [4]
ENDM
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="DoDelay">--------------------------
; A helper macro for calling the Delay subroutine in Helper_Macros.s
; Delay = LOOPL * LOOPS * 25us, max delay 0xFF * 0xFF * 25us = 1.625 seconds
DoDelay    MACRO   outer,inner 
    BANKSEL Delay		    ; (2) delay = outer * inner * 25us 
    MOVLW   inner		    ; (1) # of inner loops
    MOVWF   LOOPS		    ; (1) 
    MOVLW   outer		    ; (1) # of outer loops
    MOVWF   LOOPL		    ; (1)
    CALL    Delay		    ; (6)+[Delay] 
ENDM    
;</editor-fold> ----------------------------------------------------------------

    
;<editor-fold defaultstate="collapsed" desc="SUM_16">---------------------------
; Add two 16bit values
; V1 added to V2, result saved in V2
; V! and V2 should be in same bank with that bank selected before calling
SUM_16	MACRO	V1H, V1L, V2H, V2L   
    MOVF    V1L,W		    ; (1) Low byte
    ADDWF   V2L			    ; (1) 
    MOVF    V1H,W		    ; (1) High byte
    ADDWFC  V2H			    ; (1) [4]
ENDM
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="SUB_16">---------------------------
; Add two 16bit values
; V1 - V2, result saved in V1
; V1 and V2 should be in same bank with that bank selected before calling
; *** DOES NOT WORK, FIX, make with by 2s compliemtn of V2 and use ADD16
SUB_16	MACRO	V1H, V1L, V2H, V2L   
    BCF	    STATUS,0		    ; (1) clear Carry bit
    MOVF    V2L,W		    ; (1) Low byte
    SUBWF   V1L			    ; (1) 
    MOVF    V2H,W		    ; (1) High byte
    SUBWF   V1H			    ; (1) [5]
ENDM
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="INC_16">---------------------------
; Inccrement a 16bit value V1 -> V1 in RAM as LB,HB
; V1 bank should be selected before calling
INC_16	MACRO	V
    BCF	    STATUS,0		    ; (1) Clear carry flag
    MOVLW   0x01		    ; (1) Low byte
    ADDWF   V			    ; (1) 
    BTFSC   STATUS,0		    ; (2) If carry set INC High byte too
    INCF    V+1			    ; (1) 
ENDM
;</editor-fold> ---------------------------------------------------------------- 
    
    
;<editor-fold defaultstate="collapsed" desc="DEC_16">-------------S--------------
; Decrement a 16bit value V1 - V1 in RAM as LB,HB
; V1 bank should be selected before calling
DEC_16	MACRO	V
    MOVLW   0x01		    ; (1) Low byte
    SUBWF   V			    ; (1) 
    BTFSS   STATUS,0		    ; (2) If carry set DEC High byte too
    DECF    V+1			    ; (1) 
    MOVF    V,W			    ; (1) OR LB and HB together
    IORWF   V+1,W		    ; (1) will set Z correctly for us
ENDM
;</editor-fold> ----------------------------------------------------------------  
    
  
;<editor-fold defaultstate="collapsed" desc="LSR16">----------------------------  
; Nibble address to byte address, i.e. Divide 16-bit value by 2
; Carry set when done start on LSN of byte. PRAM bytes in LH nibble order
; Address from from PB-100 should be store in typical HB LB format
LSR16   MACRO   VAR16
    BCF     STATUS, C       ; (1) Clear carry
    RRF     (VAR16)+1,F     ; (1) Rotate high byte right
    RRF     (VAR16),F       ; (1) [3] Rotate low byte right
ENDM
;</editor-fold> ---------------------------------------------------------------- 
    
    
;<editor-fold defaultstate="collapsed" desc="TurnOffLED">-----------------------
; Turn Off LED
TurnOffLED  MACRO
    BANKSEL PORTA		    ; (2) turn off LED
    MOVLW   0xFF		    ; (1) 
    MOVWF   PORTA		    ; (1) [3]
ENDM
;</editor-fold> ----------------------------------------------------------------
    

;<editor-fold defaultstate="collapsed" desc="TurnOnLED">------------------------
; Turn On LED
TurnOnLED  MACRO
    BANKSEL PORTA		    ; (2) turn off LED
    MOVLW   0x00		    ; (1) 
    MOVWF   PORTA		    ; (1) [3]
ENDM
;</editor-fold> ----------------------------------------------------------------
 

