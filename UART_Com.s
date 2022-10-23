; File - UART_Com.s
; Helper functions for UART communications

PROCESSOR 16F18446
#include <xc.inc>
#include "Helper_Macros.s"
#include "Casio_Com_Macros.s"
  
EXTRN DownloadHandler, UploadHandler, StatusHandler	; From Casio_Com.s
EXTRN XHandler,YHandler, ZHandler			; From Casio_Com.s
EXTRN WaitForIdle,COUNTL,COUNTH,TEMP,TEMP3,TEMP4,CMODE	; From Casio_Com.s
EXTRN RXBUF_FSRxH, RXBUF_FSRxL,CBUF_START,CBUF_END	; From Casio_Com.s
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
    
Is_D:				    ; D = Download PB-100 -> PC, ASCII Dump
    MOVF    MTEMP,W		    ;
    SUBLW   0x44		    ; If W = 'D' then
    BTFSS   STATUS, 2		    ; Z flag will be set
    GOTO    Is_R		    ;
    MOVLW   0x02		    ; Set to ASCII output mode
    CALL    DownloadHandler	    ;
    GOTO    RxPoll_Done		    ;
    
Is_R:				    ; R = Download PB-100 -> PC, RAW Dump
    MOVF    MTEMP,W		    ;
    SUBLW   0x52		    ; If W = 'D' then
    BTFSS   STATUS, 2		    ; Z flag will be set
    GOTO    Is_S		    ;
    MOVLW   0x00		    ; Set to RAW output mode
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
; A 10 second timeout is implemented except for EOL character
; Uses TEMP, TEMP3, CMODE, COUNTH, COUNTL
; *** Should move Rx byte and timeout into a seperate function and call 
; *** from all three locations. Caller would need to look at 3rd count byte
; *** to know if timeout occured
GLOBAL RxBuffer
    
RxBuffer:
    ResetRxBufPtrFSR0		    ; (4) Resets FSR0 to beginning of RXBUF
    BANKSEL TEMP		    ; (2) Used to count # bytes recieved
    MOVLW   0x10		    ; (#) read in 16 (or 32) bytes at a time
    MOVWF   TEMP		    ; (#) ASCII mode 32 bytes -> 32 nibbles
    MOVLW   0x40		    ; (1) Using TYEMP3 as a third digit for 
    MOVWF   TEMP3		    ; (1) timeout counter.
    
RxWait1:
    BANKSEL COUNTH		    ; (2) Used along with Delay to add a timeout
    CLRF    COUNTH		    ; (1) Delay is 25us, COUNTH makes 256 loop
    CLRF    COUNTL		    ; (1) Zero timeout counter
    
RxWait2:	
    BANKSEL COUNTH		    ; (2) @19200 a byte takes ~500us
    DEC_16  COUNTL		    ; (#) DEC timeout counter. If not zero check
    BTFSC   STATUS,2		    ; (2) for Rx, if zero DEC 3rd counter byte
    GOTO    RxBufDec3		    ; (2) DECs the 3rd digit and loops back

RxWait3:
    BANKSEL PIR3		    ; (2) Check to see we have byte incoming
    BTFSS   PIR3,5		    ; (1) If PIR3 Bit5 set, a byte is in Rx reg
    GOTO    RxWait2		    ; (2) if not, keep trying
    
RxMode:
    BANKSEL CMODE		    ; (2) 
    BTFSC   CMODE,1		    ; (2) 0 = RAW mode, 1 = ASCII mode
    GOTO    RxMode_ASCII	    ; (2) 

RxMode_Raw:
    BANKSEL RC1REG		    ; (2)
    MOVF    RC1REG,W		    ; (1) Grab byte from Rx buffer
    MOVWI   FSR0++		    ; (1) Write to buffer, inc pointer
    GOTO    RxLoop		    ; (1)

RxMode_ASCII:
    BANKSEL RC1REG		    ; (2)
    MOVF    RC1REG,W		    ; (1) Grab byte from Rx buffer  
    BANKSEL TEMP4		    ; (2) 
    MOVWF   TEMP4		    ; (1) Save W to temp
    SWAPF   TEMP4		    ; (1) Swap nibbles
    MOVLW   0xF0		    ; (1) Mask off low nibble
    ANDWF   TEMP4		    ; (1) 
    
RxWait4:
    BANKSEL PIR3		    ; (2) Check to see we have byte incoming
    BTFSS   PIR3,5		    ; (1) If PIR3 Bit5 set, a byte is in Rx reg
    GOTO    RxWait4		    ; (2) if not, keep trying
    
    BANKSEL RC1REG		    ; (2)
    MOVF    RC1REG,W		    ; (1) Grab byte from Rx buffer    
    ANDLW   0x0F		    ; (1) Mask off high byte
    BANKSEL TEMP4		    ; (2) 
    IORWF   TEMP4,W		    ; (1) OR two nibbles into Packed byte in W
    MOVWI   FSR0++		    ; (1) Put packed byte in buffer
    
RxLoop:   
    BANKSEL TEMP		    ; (2) 
    DECFSZ  TEMP		    ; (2) DEC the Rx byte counter
    GOTO    RxWait1		    ; (2) If > 0 loop back
    GOTO    RxBufferDone	    ; (2) If = 0 we are done
    
RxBufDec3:			    
    BANKSEL TEMP3		    ; (2) Three lines tacked in to add a 3rd
    DECFSZ  TEMP3		    ; (2) timeout counter byte, if timeout end
    GOTO    RxWait1		    ; (2) else keep trying
       
RxBufferDone:    
    BANKSEL CMODE		    ; (2) Unified exit
    BTFSS   CMODE,1		    ; (2) If ASCII mode read in EOL
    RETURN			    ; (2) In RAW mode so done, RETURN

RxWait5:
    BANKSEL PIR3		    ; (2) There is no timeout for the EOL byte
    BTFSS   PIR3,5		    ; (1) A rather bad way to do things.
    GOTO    RxWait5		    ; (2) 
    
    BANKSEL RC1REG		    ; (2) Grab '0A' from Rx buffer
    MOVF    RC1REG,W		    ; (1) could return W=1 if error?
    
RETURN 
    
;</editor-fold> ---------------------------------------------------------------- 
    
    
;<editor-fold defaultstate="collapsed" desc="TxBuffer">------------------------- 
; TxBuffer - Send to UART what is in buffer pointed to by FSR0
; COUNTH, COUNTL = number of bytes to send
; CMODE,0 = raw output, CMODE,1 = ASCII output
; Uses CMODE, COUNTL, COUNTH, FSR0
GLOBAL TxBuffer
 
TxBuffer:
    BANKSEL COUNTL		    ; (2) 
    ;CLRF    CMODE		    ; (1) Clear the burst of 8 counter byte
TxBNext:
    ;BANKSEL TX1REG		    ; (1) make sure we are in UART register bank
    MOVIW   FSR0++		    ; (1) grab next charecter from buffer
    ;MOVWF   TX1REG		    ; (1) put the character in TXREG
    
TxBMode:
    BANKSEL CMODE
    BTFSC   CMODE,1		    ; If in ASCII mode 
    GOTO    TxBMode_ASCII	    ;
    
TxBMode_Raw:   
    BANKSEL TX1REG
    MOVWF   TX1REG		    ; (1) put the character in TXREG  
TxBWait:   
    BTFSS   TX1STA, TX1STA_TRMT_POSN; (2) if TRMT is empty character was sent
    GOTO    TxBWait		    ; (2) if not, check again
    GOTO    TxBLoop

TxBMode_ASCII:    
    BANKSEL TEMP3
    MOVWF   TEMP3
    SWAPF   TEMP3,W
    ANDLW   0x0F
    IORLW   0x30
    BANKSEL TX1REG
    MOVWF   TX1REG		    ; (1) put the character in TXREG 
TxBWait_Nl:   
    BTFSS   TX1STA, TX1STA_TRMT_POSN; (2) if TRMT is empty character was sent
    GOTO    TxBWait_Nl		    ; (2) if not, check again
    
    BANKSEL TEMP3
    MOVF    TEMP3,W
    ANDLW   0x0F
    IORLW   0x30
    BANKSEL TX1REG
    MOVWF   TX1REG		    ; (1) put the character in TXREG 
TxBWait_Nh:   
    BTFSS   TX1STA, TX1STA_TRMT_POSN; (2) if TRMT is empty character was sent
    GOTO    TxBWait_Nh		    ; (2) if not, check again

TxBLoop:
    BANKSEL COUNTL		    ; (2) Bytes to send in COUNTH,COUNTL (HB, LB)
    DEC_16  COUNTL		    ; (4) 16bit DEC of count
    BTFSC   STATUS,2		    ; (2) If Z flag set we are done
    ;GOTO    TxB_Done		    ; (2)
    GOTO    TxB_EOL		    ; (2)
    ;INCF    CMODE		    ; (##) Inc byte used to track bursts of 8
    ;BTFSC   CMODE,3		    ; (2) If Bit3 set, wait for next idle period
    ;CALL    WaitForIdle		    ; (##) 
    GOTO    TxBuffer		    ; (2) keep dumping
    
TxB_EOL: 
    BANKSEL CMODE		    ; If in ASCII mode, CMODE,1=1 
    BTFSS   CMODE,1		    ; we want to send EOL character '0A'
    GOTO    TxB_Done		    ;
    
    MOVLW   0x0A		    ; EOL character
    BANKSEL TX1REG
    MOVWF   TX1REG		    ; (1) put the character in TXREG 
TxBWait_EOL:   
    BTFSS   TX1STA, TX1STA_TRMT_POSN; (2) if TRMT is empty character was sent
    GOTO    TxBWait_EOL		    ; (2) if not, check again
    
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