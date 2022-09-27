; File - UART_Com.s
; Helper functions for UART communications

PROCESSOR 16F18446
#include <xc.inc>
#include "Helper_Macros.s"
#include "Casio_Com_Macros.s"
  
EXTRN DownloadHandler, UploadHandler, StatusHandler	; From Casio_Com.s
EXTRN XHandler,YHandler, ZHandler			; From Casio_Com.s
EXTRN WaitForIdle,COUNTL,COUNTH,TEMP,CMODE		; From Casio_Com.s
EXTRN RXBUF_FSRxH, RXBUF_FSRxL,CBUF_START,CBUF_END
EXTRN Delay,LOOPS,LOOPL					; From Helper_Functions.s
    
;-------------------------------------------------------------------------------   
; Reserve RAM for keeping track of program state
PSECT   UART_State,global,class=BANK0,size=0x01,noexec,delta=1,space=1
GLOBAL MTEMP
    MTEMP:	DS  0x01	    ; hold last char from UART
 
;-------------------------------------------------------------------------------   
; UART Coms handling code
psect   UART_Code,global,class=CODE,delta=2

;<editor-fold defaultstate="collapsed" desc="Rx_Poll">--------------------------
GLOBAL Rx_Poll 
    
Rx_Poll:
    MOVLW   0x00		    ; (1) Will return zero to indicate null
    BANKSEL PIR3		    ; (2) Check to see we have byte incoming
				    ; from the UART. Change mode and/or respond
    BTFSS   PIR3,5		    ; (1) If PIR3 Bit5 set, a byte is in Rx reg
    GOTO    StateLogic		    ; (2) if not, skip ahead
    BANKSEL RC1REG		    ; (2)
    MOVF    RC1REG,W		    ; (1) Grab byte from Rx buffer

StateLogic:			    ; make sure W >= 'A' & <= 'z'
    BANKSEL MTEMP		    ;
    MOVWF   MTEMP		    ; (1) Save original value between tests
    SUBLW   0x40		    ; 0x40-W
    BTFSC   STATUS,0		    ; If W >= 0x41 (A) skip ahead
    GOTO    RxPoll_Done		    ; else, we are done
    MOVF    MTEMP,W		    ; get back original value
    SUBLW   0x7A		    ; If W <= 7A (z)
    BTFSS   STATUS,0		    ;
    GOTO    RxPoll_Done		    ;

UpperCaseify:
    MOVLW   0xDF		    ; Clearing Bit 5 will set to Upper Case
    ANDWF   MTEMP		    ;
    
Is_U:				    ; U = Upload PC->PB-100
    MOVF    MTEMP,W		    ;
    SUBLW   0x55		    ; If W = 'U' or 'u' then
    BTFSS   STATUS, 2		    ; Z flag will be set
    GOTO    Is_D		    ;
    CALL    UploadHandler	    ;
    GOTO    RxPoll_Done		    ; 
    
Is_D:				    ; D = Download PB-100 -> PC
    MOVF    MTEMP,W		    ;
    SUBLW   0x44		    ; If W = 'D' then
    BTFSS   STATUS, 2		    ; Z flag will be set
    GOTO    Is_S		    ;
    CALL    DownloadHandler	    ;
    GOTO    RxPoll_Done		    ;
    
Is_S:				    ; S = Show Status
    MOVF    MTEMP,W		    ;
    SUBLW   0x53		    ; If W = 'S' then
    BTFSS   STATUS, 2		    ; Z flag will be set
    GOTO    Is_X		    ;
    CALL    StatusHandler	    ; Sets FSR1 to point to buffer TEMP=length
    CALL    TxBuffer		    ; Send buffer out over UART
    GOTO    RxPoll_Done		    ;
    
Is_X:				    ; X = eXperimental
    MOVF    MTEMP,W		    ;
    SUBLW   0x58		    ; If W = 'X' then
    BTFSS   STATUS, 2		    ; Z flag will be set
    GOTO    Is_Y		    ;
    CALL    XHandler		    ; Dumps PRAM
    GOTO    RxPoll_Done		    ;
    
Is_Y:
    MOVF    MTEMP,W		    ; Y = also experimental
    SUBLW   0x59		    ; If W = 'Y' then
    BTFSS   STATUS, 2		    ; Z flag will be set
    GOTO    Is_Z		    ;
    CALL    YHandler		    ; Dump CRAM
    GOTO    RxPoll_Done		    ;
    
Is_Z:
    MOVF    MTEMP,W		    ; Z = Zero all CRAM and PRAM
    SUBLW   0x5A		    ; If W = 'Y' then
    BTFSS   STATUS, 2		    ; Z flag will be set
    GOTO    RxPoll_Done		    ;
    CALL    ZHandler		    ; 
    GOTO    RxPoll_Done		    ;
;    
;Xmt:
;    BANKSEL TX1REG		    ; (1) make sure we are in UART register bank
;    MOVWF   TX1REG		    ; (1) put the character in TXREG  
;Tx:   
;    BTFSS   TX1STA, TX1STA_TRMT_POSN; (2) if TRMT is empty character was sent
;    GOTO    Tx			    ; (2) if not, check again
    
RxPoll_Done:
RETURN

;</editor-fold> ----------------------------------------------------------------  
 
    
;<editor-fold defaultstate="collapsed" desc="RxBuffer">-------------------------
; Reads data from UART 16 bytes at a time, stores in RxBuffer, rerurns to caller
; A 10 second timeout is implemented, #bytes RxD=16-COUNTL
; Uses TEMP, CMODE, COUNTH, COUNTL
GLOBAL RxBuffer 
RxBuffer:
    ResetRxBufPtrFSR0		    ; (4) Resets FSR0 to beginning of RXBUF
    BANKSEL TEMP		    ; (2) Used to count # bytes recieved
    MOVLW   0x10		    ; (#) read in 16 bytes at a time
    MOVWF   TEMP		    ; (#) 
    MOVLW   0x40		    ; (1) Using CMODE as a third digit for 
    MOVWF   CMODE		    ; (1) timeout counter.
    
RxWait1:
    BANKSEL COUNTH		    ; (2) Used along with Delay to add a timeout
    CLRF    COUNTH		    ; (1) Delay is 25us, COUNTH makes 256 loop
    CLRF    COUNTL
    
RxWait2:	
    BANKSEL COUNTH		    ; (2) @19200 a byte takes ~500us
    DEC_16  COUNTL		    ; (#)
    BTFSC   STATUS,2		    ; (2) 
    GOTO    RxBufDec3		    ; (2) DECs the 3rd digit and loops back

RxWait3:
    BANKSEL PIR3		    ; (2) Check to see we have byte incoming
    BTFSS   PIR3,5		    ; (1) If PIR3 Bit5 set, a byte is in Rx reg
    GOTO    RxWait2		    ; (2) if not, keep trying
    
    BANKSEL RC1REG		    ; (2)
    MOVF    RC1REG,W		    ; (1) Grab byte from Rx buffer
    MOVWI   FSR0++		    ; (1) Write to buffer, inc pointer
    
    BANKSEL TEMP		    ; (2) 
    DECFSZ  TEMP		    ; (2) 
    GOTO    RxWait1		    ; (2)
    GOTO    RxBufferDone	    ; (2) 
    
RxBufDec3:			    ; If COUNTL > 0 we did not read in 16 bytes
    BANKSEL CMODE
    DECFSZ  CMODE
    GOTO    RxWait1
       
RxBufferDone:    
    
RETURN 
    
;</editor-fold> ---------------------------------------------------------------- 
    
    
;<editor-fold defaultstate="collapsed" desc="TxBuffer">------------------------- 
; TxBuffer - Send to UART what is in buffer pointed to by FSR1
; CmdBuf->TEMP,TEMP+1 = number bytes to send (LB,HB)
; CmdBuf->TEMP+2 = 'Burst of 8' counter. Send 8 bytes each idle.
; TEMP,TEMP+1=#bytes to Tx (LB,HB), TEMP+2='burst of 8' counter
; Uses CMODE, COUNTL, FSR1
GLOBAL TxBuffer
 
TxBuffer:
    BANKSEL COUNTL		    ; (2) 
    CLRF    CMODE		    ; (1) Clear the burst of 8 counter byte
TxBNext:
    BANKSEL TX1REG		    ; (1) make sure we are in UART register bank
    MOVIW   FSR1++		    ; (1) grab next charecter from buffer
    MOVWF   TX1REG		    ; (1) put the character in TXREG
    
TxBWait:   
    BTFSS   TX1STA, TX1STA_TRMT_POSN; (2) if TRMT is empty character was sent
    GOTO    TxBWait		    ; (2) if not, check again

    BANKSEL COUNTL		    ; (2) Bytes to send in TEMP+1,TEMP (HB, LB)
    DEC_16  COUNTL		    ; (4) 16bit DEC of count
    BTFSC   STATUS,2		    ; (2) If Z flag set we are done
    GOTO    TxB_Done		    ; (2) 
    INCF    CMODE;		    ; (##) Inc byte used to track bursts of 8
    BTFSC   CMODE,3		    ; (2) If Bit3 set, wait for next idle period
    CALL    WaitForIdle		    ; (##) 
    GOTO    TxBuffer		    ; (2) keep dumping
    
TxB_Done: 
    
RETURN
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="TxCRAM">------------------------- 
; TxBuffer - Send to UART  what is in buffer pointed to by FSR0
; Buffer Byte 0=temp, Byte 1, count, Byte 2-n data
;GLOBAL TxCRAM
; 
;TxCRAM:   
;    BANKSEL TX1REG		    ; (1) make sure we are in UART register bank
;    MOVIW   FSR0++		    ; (1) grab next charecter from buffer
;    movwf   TX1REG		    ; (1) put the character in TXREG
;    
;TxWait:   
;    btfss   TX1STA, TX1STA_TRMT_POSN; (2) if TRMT is empty character was sent
;    goto    TxWait		    ; (2) if not, check again
;
;    MOVLW   PRAM_EH+1		    ; (1) PRAM_EH = 0x28 when done
;    XORWF   FSR0H,W		    ; (1) If result 0 FSROH == PRAM_EH+1
;    BTFSS   STATUS,2		    ; (1) Zero flag clear if not equal
;    GOTO    TxBuffer		    ; (2) keep dumping
;    RETURN
;</editor-fold> ---------------------------------------------------------------- 