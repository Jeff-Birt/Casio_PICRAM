; File - Casio_Com_Macros.s
; Helper macros for Casio 4-bit bus commuinication 
    
PROCESSOR 16F18446    
#include <xc.inc>
  
    
;<editor-fold defaultstate="collapsed" desc="SetCBufPointer_L">-----------------   
; Set Pointer into Command 'CBUF' Buffer
SetCBufPointer_L    MACRO	HI_BYTE, LOW_BYTE, NUMNIB
    MOVLW   HI_BYTE		    ; (1) high byte start of CBUF
    MOVWF   FSR1H		    ; (1) move to File Select Register 1 High
    MOVLW   LOW_BYTE	    	    ; (1) CBUF start low byte (# bytes to rx)
    MOVWF   FSR1L		    ; (1) move to File Select Register 1 Low
    
    BANKSEL COUNTL		    ; (2) make sure in correct bank
    MOVLW   NUMNIB		    ; (1) 
    MOVWF   COUNTL	    	    ; (1) [8]
ENDM
;</editor-fold> ---------------------------------------------------------------- 
    
    
;<editor-fold defaultstate="collapsed" desc="ResetCBufPointer">-----------------    
; Resets FSR1 to point to beginning of CBUF
ResetCBufPtrFSR1   MACRO
    MOVLW   CBUF_FSRxH		    ; (1) high byte start of CBUF
    MOVWF   FSR1H		    ; (1) move to  File Select Register 1 High
    MOVLW   CBUF_FSRxL		    ; (1) CBUF start low byte  
    MOVWF   FSR1L		    ; (1) [4] move to  File Select Register 1 Low
ENDM
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="ResetRxBufPointer">----------------   
; Resets FSR0 to point to beginning of RXBUF
ResetRxBufPtrFSR0    MACRO
    MOVLW   RXBUF_FSRxH		    ; (1) high byte start of RX Buffer
    MOVWF   FSR0H		    ; (1) 
    MOVLW   RXBUF_FSRxL		    ; (1) low byte of RX Buffer
    MOVWF   FSR0L		    ; (1) [4]
ENDM
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="ResetRxBufPointer">----------------   
; Resets FSR1 to point to beginning of RXBUF
ResetRxBufPtrFSR1    MACRO
    MOVLW   RXBUF_FSRxH		    ; (1) high byte start of RX Buffer
    MOVWF   FSR1H		    ; (1) 
    MOVLW   RXBUF_FSRxL		    ; (1) low byte of RX Buffer
    MOVWF   FSR1L		    ; (1) [4]
ENDM
;</editor-fold> ----------------------------------------------------------------
 
    
;<editor-fold defaultstate="collapsed" desc="mBuildCMD_L">----------------------
; mBuildCMD_L - uses litteral values to build command in FSR1
mBuildCMD_L MACRO	TYPE,N0,N1,N2,DEV
    MOVLW   TYPE		    ; (1) Set command type and starting address
    MOVWI   FSR1++		    ; (1) Type = 0x0R, Read
    MOVLW   N0			    ; (1) 
    MOVWI   FSR1++		    ; (1) N0 = 0x0, Address Nibble 0
    MOVLW   N1			    ; (1) 
    MOVWI   FSR1++		    ; (1) N1 = 0x0, Address Nibble 1
    MOVLW   N2			    ; (1) 
    MOVWI   FSR1++		    ; (1) N2 = 0x0, Address Nibble 2
    MOVLW   DEV			    ; (1) 
    MOVWI   FSR1++		    ; (1) [10] Device = 0x0
ENDM
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="mBuildCMD_F">----------------------
; mBuildCMD_F: N0 =0, uses file value to set N1,N2 to build command in FSR1
; User must make sure to be in correct bank before using macro
mBuildCMD_F MACRO	TYPE,N2_N1,DEV
    MOVLW   TYPE		    ; (1) Set command type and starting address
    MOVWI   FSR1++		    ; (1) Type = 0x0R, Read
    MOVLW   0x00		    ; (1) 
    MOVWI   FSR1++		    ; (1) N0 = 0x0, Address Nibble 0
    MOVF    N2_N1,W		    ; (1) 
    ANDLW   0x0F		    ; (1) mask off upper nibble
    MOVWI   FSR1++		    ; (1) N1 = 0x0, Address Nibble 1
    SWAPF   N2_N1,W		    ; (1) Swap HB,LB of N1_N2
    ANDLW   0x0F		    ; (1) mask off upper nibble
    MOVWI   FSR1++		    ; (1) N2 = 0x0, Address Nibble 2
    ;MOVLW   DEV			    ; (1) 
    MOVF    DEV,W
    MOVWI   FSR1++		    ; (1) [12] Device = 0x0
ENDM
;</editor-fold> ----------------------------------------------------------------
    
    
;;<editor-fold defaultstate="collapsed" desc="Enable_Interrupts">----------------
;; SetEffAdd Set Effective Address
;
;Enable_Interrupts MACRO   
;    BANKSEL PIR4		    ; (2) Timer Peripheral Interrupt Register
;    BCF	    PIR4,1		    ; (1) Clear TMR2 inturrpt flag 
;    
;    BANKSEL PIE4		    ; (2) Timer Peripheral Interrupt Enable
;    CLRF    PIE4
;;;    BSF	    PIE4,1		    ; (1) Enable TMR2 interrupt 
;
;    BANKSEL INTCON		    ; (2) 
;    CLRF    INTCON		    ; (1) Clear all interrupts
;    ;BSF	    INTCON,INTCON_PEIE_POSN ; (1) Enable Peripheral Interrupts
;    BSF	    INTCON,INTCON_GIE_POSN  ; (1) Global enable of interrupts
;ENDM
;    
;TMR2_Clear_Interrupt MACRO
;    BANKSEL PIR4		    ; (2) Timer Peripheral Interrupt Register
;    BCF	    PIR4,1		    ; (1) Clear TMR2 inturrpt flag 
;ENDM   
;   
;
;TMR2_Disable_Interrupt MACRO
;    BANKSEL PIE4		    ; (2) Timer Peripheral Interrupt Enable
;    BCF	    PIE4,1		    ; (1) Disable TMR2 interrupt
;ENDM
; 
;TMR2_Enable_Interrupt MACRO
;    BANKSEL PIE4		    ; (2) Timer Peripheral Interrupt Enable
;    BSF	    PIE4,1		    ; (1) Enable TMR2 interrupt 
;ENDM
;
;
;;</editor-fold> ----------------------------------------------------------------