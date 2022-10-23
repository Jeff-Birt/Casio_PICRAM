; Helper functions
PROCESSOR 16F18446

#include <xc.inc>
#include "Helper_Macros.s"

;-------------------------------------------------------------------------------
; Definitions declared other files
EXTRN CBUF_START, CBUF_END, COUNTL			    ; From Casio_Coms.s
EXTRN PRAM_BH, PRAM_BL, PRAM_EH, PRAM_EL		    ; From Main.s
    
;<editor-fold defaultstate="collapsed" desc="Delay">-----------------------  
; Delay - delay in increments of 25us 
; Before calling set value of LOOPL, LOOPS then 'CALL Delay'
; Uses 3 bytes of common RAM to store loop counters
; Delay = LOOPL * LOOPS * 25us, max delay 0xFF * 0xFF * 25us = 1.625 seconds
    
; Reserve RAM for loop counter
PSECT   Loop_Counter,global,class=COMMON,size=0x03,noexec,delta=1,space=1
GLOBAL  LOOPS,LOOPL
    LOOPS:	DS  0x01	    ; # of inner loops
    LOOPM:	DS  0x01	    ; unmodified copy of LOOPS
    LOOPL:	DS  0x01	    ; # of outer loops
    

; psect for Delay code body
PSECT   Delay,class=CODE,delta=2
GLOBAL Delay
    
Delay:
	MOVF	LOOPS,W			; (1) Copy inner loop value to restore
	MOVWF	LOOPM			; (1) on each inner loop pass
Delay0:	
	MOVF	LOOPM,W			; (1) Grab an unmodified inner loop 
	MOVWF	LOOPS			; (1) value on each pass
Delay1:
	MOVLW	0xCF			; (1) Gives us a 25us core delay
Delay2:
 	ADDLW	0x01			; (1) Count up, until roll over to zero 
 	BTFSS 	STATUS,STATUS_ZERO_POSN	; (1-2) if rolled over skip next line
 	GOTO 	Delay2			; (2) Keep going on core loops
 	DECFSZ 	LOOPS,1			; (1) Dec #inner loops, skip next if zero
 	GOTO 	Delay1			; (1-2) Keep going on inner loops
	DECFSZ	LOOPL,1			; (1) Dec #outer loops, skip next if zero
	GOTO	Delay0			; (1-2) Keep going on iouter loops
 RETURN
 
;  Sample code
;    BANKSEL Delay
;    MOVLW   0x40		    ; delay = W * 25us,  
;    MOVWF   LOOPS
;    MOVLW   0x01		    ; delay = W * 25us,  
;    MOVWF   LOOPL
;    CALL    Delay		    ; let it come up to speed
 
;</editor-fold> ----------------------------------------------------------------
   
    
;<editor-fold defaultstate="collapsed" desc="WaitForBtnPress">------------------
; WaitForBtnPress - Wait for Button Pressed with 100ms debounce 
GLOBAL WaitForBtnPress
WaitForBtnPress:
    BANKSEL PORTB		    ; 
waitBtn:
    BTFSC   PORTB,5		    ; skip next if btn pressed
    GOTO    waitBtn		    ; keep looping
    DoDelay 0xFA,0x10		    ; Debounce, delay = CB * 10 * 25us = 100ms 
    BANKSEL PORTB		    ; 
    BTFSC   PORTB,5		    ; If button still down skip 
    GOTO    waitBtn		    ; Button up after debounce, keep waiting
    RETURN
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="WaitForBtnRelease">----------------
; WaitForBtnRelease - Wait for Button Released with 100ms debounce
GLOBAL WaitForBtnRelease
WaitForBtnRelease:
    BANKSEL PORTB		    ; 
waitBtn2:
    BTFSS   PORTB,5		    ; skip next if btn released
    GOTO    waitBtn2		    ; keep looping
    DoDelay 0xFA,0x10		    ; Debounce, delay = CB * 10 * 25us = 100ms 
    BANKSEL PORTB		    ; 
    BTFSS   PORTB,5		    ; If button still down skip 
    GOTO    waitBtn2		    ; Button up after debounce, keep waiting
    RETURN
;</editor-fold> ----------------------------------------------------------------  
    
    
;<editor-fold defaultstate="collapsed" desc="NAtoBA">---------------------------
; NAtoBA - Convert nibble address to byte address
; CmdBuffer  input: TYPE, DA-NAh, NAl 
; CmdBuffer output: TYPE, BAh, BAl, B7, DA_Temp  (B7 -> Bit7 start with Nh)
; COUNTL Bit7 to indicate start w/Nh   
; Sets FSR0 to address passed in command
GLOBAL NAtoBA
NAtoBA:
    BANKSEL CBUF_START		    ; (2) 
    ;CLRF    CBUF_START+3	    ; (1) Clear B7 ahead of time
    CLRF    COUNTL
    MOVLW   0xF0		    ; (1) mask to keep only DA
    ANDWF   CBUF_START+1,W	    ; (1) save DA to W
    MOVWF   CBUF_START+4	    ; (1) Save DA to temp location
    
    ; NA to DA section
    MOVLW   0x0F		    ; (1) mask to keep high nibble of NA
    ANDWF   CBUF_START+1	    ; (1) mask off DA (Device Address)
    BCF	    STATUS, 0		    ; (1) clear carry bit
    RRF	    CBUF_START+1	    ; (1) MSN of NA (Nibble Address) divide by 2
    RRF	    CBUF_START+2	    ; (1) Low nibs of NA divide by 2, carry in
    BTFSC   STATUS,0		    ; (2) Skip ahead if Carry not set
    ;BSF	    CBUF_START+3,7	    ; (1) Set Bit 7 of B7 to indicate start w/Nh
    BSF	    COUNTL,7
    MOVF    CBUF_START+4,W	    ; (1) get DA saved earlier
    IORWF   CBUF_START+1	    ; (1) Put DA back where it was
    
    ; Offset into FSRO section
    BCF	    STATUS,0		    ; (1) Clear carry flag
    MOVF    CBUF_START+2,W	    ; (1) Grab low byte, BAl
    ;ADDLW   PRAM_BL		    ; (1) index into PRAM LB
    MOVWF   FSR0L		    ; (1) move to File Select Register 1 High
    MOVF    CBUF_START+1,W	    ; (1) Grab high byte, BAh
    ANDLW   0x0F		    ; (1) Mask off Device address for now
    ADDLW   PRAM_BH		    ; (1) index into PRAM HB
    MOVWF   FSR0H		    ; (1) move to File Select Register 1 High
    
    RETURN			    ; (2) [26] ~3.4us
;</editor-fold> ----------------------------------------------------------------   
    
    
;<editor-fold defaultstate="collapsed" desc="NA to DA tests">-------------------    
;    ; CmdBuffer  input: TYPE, DA-NAh, NAl 
;    ; CmdBuffer output: TYPE, BAh, BAl, B7, DA  (B7 -> Bit7 start with Nh)
;    ; Input: 04, 02, 3D -- Output: 04, 01, 1E, 80, 00
;    ; Input: 04, 12, 3C -- Output: 04, 01, 1E, 00, 01
;    MOVLW   0x04		    ; Write command
;    MOVWF   CBUF_START		    ;
;    MOVLW   0x12		    ; DA-Nh
;    MOVWF   CBUF_START+1	    ;
;    MOVLW   0x3C		    ; Nm-Nl
;    MOVWF   CBUF_START+2	    ;    
;    CALL    NAtoBA
;    CALL    Index2PRAM
;    
;    MOVF    FSR0H,W		    ; Tack on PRAM address to CMD buffer
;    MOVWF   CBUF_START+5	    ; for testing
;    MOVF    FSR0L,W		    ;
;    MOVWF   CBUF_START+6	    ;
;    
;    ; Tx what is in buffer pointed to by FSR1
;    BANKSEL TEMP		    ; (2)
;    MOVLW   0x07		    ; (1) 7 bytes
;    MOVWF   TEMP		    ; (1) write W to Buffer Count
;    
;    MOVLW   CBUF_FSRxH		    ; (1) high byte start of CBUF
;    MOVWF   FSR1H		    ; (1) move to File Select Register 1 High
;    MOVLW   CBUF_FSRxL	    	    ; (1) CBUF start low byte (# bytes to rx)
;    MOVWF   FSR1L		    ; (1) move to File Select Register 1 Low    
;    
;    CALL    TxCmdBuf
;
;    GOTO    block
;</editor-fold> ----------------------------------------------------------------  
           

;<editor-fold defaultstate="collapsed" desc="Index2PRAM">-----------------------
; Index2PRAM - Set index into PRAM based on address sent in last command
; CmdBuffer  input: TYPE, BAh, BAl, B7, DA_Temp  (B7 -> Bit7 start with Nh)
; Output:   Sets FSR0 with index into PRAM for Byte Address 
GLOBAL Index2PRAM
Index2PRAM:
    BANKSEL CBUF_START		    ; (2) 
    BCF	    STATUS,0		    ; (2) Clear carry flag
    MOVF    CBUF_START+2,W	    ; (1) Grab low byte, BAl
    ADDLW   PRAM_BL		    ; (1) index into PRAM LB
    MOVWF   FSR0L		    ; (1) move to File Select Register 1 High
    MOVF    CBUF_START+1,W	    ; (1) Grab high byte, BAh
    ANDLW   0x0F		    ; (1) Mask off Device address for now
    ADDLW   PRAM_BH		    ; (1) index into PRAM HB
    MOVWF   FSR0H		    ; (1) move to File Select Register 1 High
    
    RETURN			    ; (2) [10] ~2.5us
;</editor-fold> ---------------------------------------------------------------- 
    
    
;<editor-fold defaultstate="collapsed" desc="Test">---------------------------
;    ; CmdBuffer  input: TYPE, DA-NAh, NAl 
;    ; CmdBuffer output: TYPE, BAh, BAl, B7, DA  (B7 -> Bit7 start with Nh)
;    ; Input: 04, 02, 3D -- Output: 04, 01, 1E, 80, 00
;    ; Input: 04, 12, 3C -- Output: 04, 01, 1E, 00, 01
;    MOVLW   0x04		    ; Write command
;    MOVWF   CBUF_START		    ;
;    MOVLW   0x12		    ; DA-Nh
;    MOVWF   CBUF_START+1	    ;
;    MOVLW   0x3C		    ; Nm-Nl
;    MOVWF   CBUF_START+2	    ;    
;    CALL    NAtoBA
;    CALL    Index2PRAM
;    
;    MOVF    FSR0H,W		    ; Tack on PRAM address to CMD buffer
;    MOVWF   CBUF_START+5	    ; for testing
;    MOVF    FSR0L,W		    ;
;    MOVWF   CBUF_START+6	    ;
;</editor-fold> --------------------------------------------------------------
    
  