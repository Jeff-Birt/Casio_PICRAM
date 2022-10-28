; Helper functions
PROCESSOR 16F18446

#include <xc.inc>
#include "Helper_Macros.s"

    
;-------------------------------------------------------------------------------
; Definitions declared other files
EXTRN CBUF_START, CBUF_END, CBUF_RAW,COUNTL,TblDevToMask,CMODE; From Casio_Coms.s
EXTRN PRAM_BH, PRAM_BL, PRAM_EH, PRAM_EL,DEVTYPE	    ; From Main.s
    
    
;<editor-fold defaultstate="collapsed" desc="UnitTestInit">---------------------    
 
#define EndableDebug
    
#ifdef EndableDebug
    
;EXTRN NAtoDA_Tests					; Test function
    
#endif
    
;</editor-fold> ----------------------------------------------------------------
    
    
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
; CmdBuffer output: TYPE, BAh, BAl
; CMODE Bit7 to indicate start w/Nh   
; Sets FSR0 to address passed in command
GLOBAL NAtoBA
NAtoBA:
    BANKSEL CBUF_START		    ; (2) Everything in same bank!
    MOVF    CBUF_RAW,W		    ; (1) Transfer CMD Type to W
    MOVWF   CBUF_START		    ; (1) Transfer CMD Type to CBUF
    
    MOVF    CBUF_RAW+3,W	    ; (1) Grab high nibble of Address in Device
    MOVWF   CBUF_START+1	    ; (1) Move to CBUF
    
    SWAPF   CBUF_RAW+2,W	    ; (1) Grab middle nibble of Address in Device
    MOVWF   CBUF_START+2	    ; (1) Swap to high nibble, save in CBUF
    
    MOVF    CBUF_RAW+1,W	    ; (1) Grab low nibble of Address in Device
    IORWF   CBUF_START+2	    ; (1) [10] Or in middle nibble
    
    ; NA to DA section
    BCF	    CMODE,7		    ; (1) CMODE,7= starting nibble for R/W
    BCF	    STATUS, 0		    ; (1) clear carry bit
    RRF	    CBUF_START+1	    ; (1) MSN of NA (Nibble Address) divide by 2
    RRF	    CBUF_START+2	    ; (1) Low nibs of NA divide by 2, carry in
    BTFSC   STATUS,0		    ; (2) Skip ahead if Carry not set
    BSF	    CMODE,7		    ; (1) CMODE,7=1 start with high nibble
    SWAPF   CBUF_RAW+4,W	    ; (1) Grab DEV nibble from raw data
    IORWF   CBUF_START+1	    ; (1) [9] OR DEV # to first byte of 
    
    ; Offset into FSRO section
    BCF	    STATUS,0		    ; (1) Clear carry flag
    MOVF    CBUF_START+2,W	    ; (1) Grab low byte, BAl
    ;ADDLW   PRAM_BL		    ; (1) index into PRAM LB
    MOVWF   FSR0L		    ; (1) move to File Select Register 1 High
    MOVF    CBUF_START+1,W	    ; (1) Grab high byte, BAh
    ANDLW   0x0F		    ; (1) Mask off Device address for now
    ADDLW   PRAM_BH		    ; (1) index into PRAM HB
    MOVWF   FSR0H		    ; (1) move to File Select Register 1 High
    
    RETURN			    ; (9)+[10]+{9]=28 ~3.5us
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
      
 
 ;<editor-fold defaultstate="collapsed" desc="UnitTests">-----------------------  
 

#ifdef EndableDebug
    
;<editor-fold defaultstate="collapsed" desc="NA to DA tests">-------------------    
; CBUF_RAW: TYPE, nl nm nh DEV
; CBUF_START: TYPE, BAh, BAl
; Input: 00, 00, 09, 00, 00 -- Output: 00, 01, 20, 00
; Input: 04, 08, 06, 04, 01 -- Output: 04, 12, 34, 00
; Input: 04, 0D, 03, 02, 00 -- Output: 04, 01, 1E, 80 (COUNTL)
; Input: 04, 0C, 03, 02, 01 -- Output: 04, 11, 1E, 00 (COUNTL)
GLOBAL NAtoDA_Tests

NAtoDA_Tests:
    BANKSEL CBUF_START		    ; (2) Everything in same bank!
    MOVLW   0x04
    MOVWF   CBUF_RAW
    MOVLW   0x0D
    MOVWF   CBUF_RAW+1
    MOVLW   0x03
    MOVWF   CBUF_RAW+2
    MOVLW   0x02
    MOVWF   CBUF_RAW+3
    MOVLW   0x00
    MOVWF   CBUF_RAW+4
    CALL    NAtoBA
    MOVF    COUNTL,W
    CALL    TblDevToMask_Tests
    
    BANKSEL CBUF_START		    ; (2) Everything in same bank!
    MOVLW   0x04
    MOVWF   CBUF_RAW
    MOVLW   0x0C
    MOVWF   CBUF_RAW+1
    MOVLW   0x03
    MOVWF   CBUF_RAW+2
    MOVLW   0x02
    MOVWF   CBUF_RAW+3
    MOVLW   0x01
    MOVWF   CBUF_RAW+4
    CALL    NAtoBA
    MOVF    COUNTL,W
    MOVF    COUNTL,W
    CALL    TblDevToMask_Tests
    
    RETURN

;</editor-fold> ----------------------------------------------------------------  
 
;<editor-fold defaultstate="collapsed" desc="TblDevToMask tests">---------------      
GLOBAL TblDevToMask_Tests

TblDevToMask_Tests:
    BANKSEL CBUF_START		    ; (2) 
    BCF	    CMODE,0		    ; (1) clear DEV1 CMD flag
    
    MOVLW   HIGH TblDevToMask	    ; (1) Must set PLATH to high byte of table
    MOVWF   PCLATH		    ; (1) as assembler can put it anywhere
    SWAPF   CBUF_START+1,W	    ; (1) Get DEV address in low nibble of W
    ANDLW   0x0F		    ; (1) Mask off the high nibble
    CALL    TblDevToMask	    ; (#) DEV # to mask in W high nibble
    
    BANKSEL DEVTYPE		    ; (2) Device type cfg byte, DEV in high nib
    ANDWF   DEVTYPE,W		    ; (1) AND mask from DEV w/DEVTYPE mask
    ANDLW   0xF0		    ; (1) Mask off low nibble
    BTFSC   STATUS,2		    ; (2) If W=0, this DEV is CRAM
    RETURN
    BANKSEL CBUF_START
    BSF	    CMODE,0		    ; (1) Set DEV1 Bit0 flag, indicate PRAM
    
    RETURN
;</editor-fold> ----------------------------------------------------------------
    
#endif
    
;</editor-fold> ---------------------------------------------------------------- 
    
  