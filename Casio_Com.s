; File - Casio_Coms.s
; Helper functions for talking on Casio 4bit bus

PROCESSOR 16F18446
#include <xc.inc>
#include "ConfigIOC.s"
#include "Helper_Macros.s"
#include "Casio_Com_Macros.s"
#include "ConfigCWG1.s"
#include "ConfigTMR2.s"

EXTRN Delay, LOOPS, LOOPL, Index2PRAM			; Helper_Functions.s
EXTRN WaitForBtnPress, WaitForBtnRelease, NAtoBA	; Helper_Functions.s
EXTRN EnableCE, DisableCE, EnableCE_OP, DisableCE_OP	; From Pin_Twiddlings.s
EXTRN WriteNibble, ReadNibble, Port_C_Input		; From Pin_Twiddlings.s
EXTRN Port_C_Output, Port_C_Write,Port_C_Read		; From Pin_Twiddlings.s
EXTRN TxBuffer, RxBuffer				; From UART_Com.s
EXTRN PRAM_BL, PRAM_BH, DEVTYPE				; From Main.s
    

;<editor-fold defaultstate="collapsed" desc="CmdBuf">---------------------------
    
;-------------------------------------------------------------------------------   
; Reserve RAM for Command Buffer use
; CBUF_START->CBUF_START+4=Command, CBUF_START+5->CBUF_START+11=32 Rx nibbles
; CMODE: Bit0=Last CMD for us
PSECT   CmdBuf,global,class=BANK0,size=0x1D, noexec,delta=1,space=1
GLOBAL  TEMP,COUNTL,COUNTH,CMODE,CBUF_START,CBUF_END,CBUF_FSRxH,CBUF_FSRxL;
GLOBAL  RXBUF_FSRxH, RXBUF_FSRxL, DEVICE

    CBUF_START: DS  0x05	; Start address of Command Buffer
    CBUF_END:	DS  0x00	; End address of Command Buffer
    RXBUF_START:DS  0x10	; Start address of Rx buffer
    RXBUF_END:	DS  0x00	; End address of Rx buffer
    COUNTL:	DS  0x01	; Number of nibbles/bytes in command/data
    COUNTH:	DS  0x01	; HB for 16bit counting
    NIBADD:	DS  0x01	; N2,N1 for up/download, 16byte chunks N0==0
    DEVICE:	DS  0x01	; Current RAM device being accessed
    CMODE:	DS  0x01	; Function State flags
    TEMP:	DS  0x01	; Function temp variable
    TEMP1:	DS  0x01	; Function temp variable
    TEMP2:	DS  0x01	; Function temp variable
    
    CBUF_FSRxH	EQU 0x20		; high byte of indirect pointer to CBUF
    CBUF_FSRxL	EQU (CBUF_START - 0x20) ; low byte of indirect pointer to CBUF
    RXBUF_FSRxH	EQU 0x20		; high byte of indirect pointer to RXBUF
    RXBUF_FSRxL	EQU (RXBUF_START - 0x20); low byte of indirect pointer to RXBUF
;</editor-fold> ----------------------------------------------------------------
 

;<editor-fold defaultstate="collapsed" desc="StaticText">-----------------------
; Static text strings for UART coms
PSECT	TEXT,global,class=CODE,delta=2
 
StaticText:
    
VersionText:
    RETLW   0x0D		    ; Length of string
IRPC    char, Version_0.5.2	    ; Macro that adds a RETLW for each character
    RETLW   'char'		    ;
ENDM

; Header format is "PICRAM 1.0 mn***"
; bytes	  Description
; 0-5 	  Name
; 6	  Space
; 7-9	  Version# Major.Minor
; 10	  Space
; 11-12   mn high/low nibble of device mask/count (ASCII)
; 13-15	  Free
;
; m = High Nibble = Device type mask 0=CRAM, 1=PRAM
; n =  Low Nibble = #Devices 1-4
; ASCII $30-$3F = cahracters 0123456789:;<=>? = values 0-F
; mn=22, 0010 0010, #DEV=2, DEV0=CRAM, DEV1=PRAM
; mn=53, 0110 0010, #DEV=3, DEV0=CRAM, DEV1=PRAM, DEV2=PRAM
HeaderText:
    RETLW   0x10		    ; Length of string
IRPC    char, PICRAM 0.5 22***	    ; Macro that adds a RETLW for each character
    RETLW   'char'		    ;
ENDM				    ;
    
;</editor-fold> ----------------------------------------------------------------
 
    
;-------------------------------------------------------------------------------
; Casio 4-bit bus communication functions
PSECT   COMS,global,class=CODE,delta=2
    
;<editor-fold defaultstate="collapsed" desc="InitCBUF">-------------------------
; Initialize CBUF
GLOBAL InitCBUF
    
InitCBUF:
    BANKSEL CBUF_START		    ; (2) 
    CLRF    TEMP		    ; (1) clear spot used for DA
    CLRF    COUNTL		    ; (1) clear spot used for DA
    CLRF    COUNTH		    ; (1) 
    CLRF    CMODE		    ; (1) clear spot used for DA  
RETURN				    ; (2) [7]
    
;</editor-fold> ----------------------------------------------------------------  
    

;<editor-fold defaultstate="collapsed" desc="Casio_Com_Functions">--------------
    
;<editor-fold defaultstate="collapsed" desc="WaitForCE1">-----------------------
; WaitForCE1 - Wait for /CE1 to fall then operate on Command or data as required
; We can have various orders of Commands and Data (C and D), such as:
; CD, CCD, CDDDDD. So, we have to be prepared for anything.
GLOBAL WaitForCE1
    
WaitForCE1:
    SetCBufPointer_L CBUF_FSRxH, CBUF_FSRxL, 0x00 ; [8] Reset FSR1x to CBUF_FSRx, zero COUNTL
    
WaitForCE1_2:			    ; Entry for partial/split commands
    BANKSEL IOCCF		    ; (2) (0x1F55) Interrupt on Change register
    CLRF    IOCCF		    ; (1) clear interrupts
    BANKSEL PIR4		    ; (2) (0x0710) Clearing IF flag.
    BCF	    PIR4,PIR4_TMR2IF_POSN   ; (1) Clear TMR2 overflow register
     
WfCE1_0:    
    BANKSEL PIR4		    ; (2) (0x0710)
    BTFSC   PIR4,1		    ; (2) (10 to check idle)
    GOTO    WfCE1_done		    ; (2) PB-100 clock not running, so exit 
    BANKSEL IOCCF		    ; (2)  
WfCE1_1:
    BTFSS   IOCCF,7		    ; (2) Did /CE1 go low?
    GOTO    WfCE1_0		    ; (2) Nope, try again
    BTFSC   IOCCF,4		    ; (2) Is OP low too?
    GOTO    handleCmd		    ; (2) (9 to handle command)    
 				    
WfCE1_2:
    ; if DEV = 1 we should pay attention. if not wait till DEV = 1
    BANKSEL CBUF_START		    ; (2) Bit 0 set by command handler
    BTFSS   CMODE,0		    ; (2) Bit 0 set means last CMD was for us
    GOTO    WaitForCE1		    ; (2) If not for us skip it
    
WfCE1_3:    
    ; else is RX_Data / TX_Data using current add., branch to correct handler
    BTFSC   CBUF_START,2	    ; (2) Bit3 set is WRITE cmd
    GOTO    writeHandler	    ; (2) else is a READ  
    
readHandler:			    ; PB-100 reading data from PIC
    BANKSEL PORTC		    ; (2) (000E) PortC to data output
    MOVLW   0xF0		    ; (1) Bits 0-3 outputs, 4-7 inputs
    MOVWF   TRISC		    ; (1) Config PortC here minimizes delays
    CALL    TxData_Slave	    ; (3.5us from /CE1 to here)

    CALL    Port_C_Input	    ; (10) PortC set to input data from PB-100
    GOTO    WaitForCE1		    ; (2) go again
    
writeHandler:			    ; PB-100 writing data to PIC
    CALL    RxData_Slave	    ; (#) Read nibbles into PRAM
    GOTO    WaitForCE1		    ; (2) go again
    
handleCmd:
    CALL    RxCmd_Slave		    ; (4us) 
    MOVLW   0x05		    ; (1) did we read in 5 nibbles?
    XORWF   COUNTL,W		    ; (1) if result in W, != 0 COUNT !=5
    BTFSS   STATUS,2		    ; (1-2) 
    GOTO    WaitForCE1_2	    ; (2) If not 5 nibbles not complete CMD
    
    CALL    NAtoBA		    ; (28) Sets FSR0 to CMD address
    CALL    Port_C_Write	    ; (#) Set write mode if needed, PortC to $FF
    
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
    BTFSS   STATUS,2		    ; (2) If W=0, this DEV is CRAM
    BSF	    CMODE,0		    ; (1) Set DEV1 Bit0 flag, indicate PRAM
    
    GOTO    WaitForCE1		    ; (2) wait for next /CE1

WfCE1_done:
				    ; unified exit point
RETURN    		
;</editor-fold> ----------------------------------------------------------------
	
				    
;<editor-fold defaultstate="collapsed" desc="TblDevToMask">---------------------
; Convert DEV value from PB-100 command to mask, DEV and mask passed in W
; Valid mask values: 0000, 0001, 0010, 0100. Return 0000 for invalid DEVs
; Vlaues returned in high nibble to match with DEVTYPE
GLOBAL TblDevToMask				    
			
TblDevToMask:
    ADDWF   PCL,F		    ; (1) add offset to pc to compute goto

    RETLW   0b00010000		    ; (2) DEV = 0
    RETLW   0b00100000		    ; (2) DEV = 1
    RETLW   0b01000000		    ; (2) DEV = 2
    RETLW   0b10000000		    ; (2) DEV = 3
    RETLW   0b00000000		    ; (2) Invalid
    RETLW   0b00000000		    ; (2) Invalid
    RETLW   0b00000000		    ; (2) Invalid
    RETLW   0b00000000		    ; (2) Invalid
    RETLW   0b00000000		    ; (2) Invalid
    RETLW   0b00000000		    ; (2) Invalid
    RETLW   0b00000000		    ; (2) Invalid
    RETLW   0b00000000		    ; (2) Invalid
    RETLW   0b00000000		    ; (2) Invalid
    RETLW   0b00000000		    ; (2) Invalid
    RETLW   0b00000000		    ; (2) Invalid
    RETLW   0b00000000		    ; (2) Invalid
    RETLW   0b00000000		    ; (2) Invalid
				    
;</editor-fold> ----------------------------------------------------------------
				    
 
;<editor-fold defaultstate="collapsed" desc="WaitForCLK1">----------------------
; WaitForCLK1 - Wait for /CLK1 to go low
; Used when waiting for an idle period to end
GLOBAL WaitForCLK1
				    
WaitForCLK1:
    BANKSEL IOCCF		    ; (2)
    CLRF    IOCCF		    ; (1) clear interrupts   
    
wCLK1_1:    
    BTFSS   IOCCF,6		    ; (1-2) Skip ahead if CLK1 went low
    GOTO    wCLK1_1		    ; (2) keep looping until CLK1 goes low
RETURN  
;</editor-fold> ----------------------------------------------------------------
				      
 
;<editor-fold defaultstate="collapsed" desc="WaitForIdle">---------------------- 
; WaitForIdle - Waits until Casio bus is in Idle where the clocks stop and bus
; goes HiZ. /CLK1 resets TMR2, if TMR2 overflows interrupt flag is set.
GLOBAL WaitForIdle
    
WaitForIdle:
    BANKSEL PIR4		    ; (2) (0x0710) Periphrial Interrupt Register
    BCF	    PIR4,PIR4_TMR2IF_POSN   ; (1) Clearing interupt flag for TMR2  
WfI:    
    BTFSS   PIR4,1		    ; (2) Did TMR2 overflow, yes in idle so done
    GOTO    WfI			    ; (2) No, keep waiting
RETURN				    ; (2) [9]
;</editor-fold> ---------------------------------------------------------------- 
    

;<editor-fold defaultstate="collapsed" desc="WaitForPing">----------------------
; WaitForPing - Looks for /OP to go low then two /CLK1 low transitions
; Used when detecting power on and correct place to start listenting to bus
GLOBAL WaitForPing
    
WaitForPing: 
    BANKSEL IOCCF		    ; (2)
    CLRF    IOCCF		    ; (1) clear interrupts
waitFP1:
    BTFSS   IOCCF,4		    ; (2) Did /OP fall?
    GOTO    waitFP1		    ; (2) wait for above 
    
waitFP2:    
    BTFSC   IOCCF,7		    ; (2) Did /CE1 also fall?
    GOTO    WaitForPing		    ; (2) if so no a ping, try again

    CLRF    IOCCF		    ; (1) clear interrupts
waitFP3:    
    BTFSS   IOCCF,6		    ; (2) Wait for /CLK1 to fall first time
    GOTO    waitFP3		    ; (2) wait for above 
    
    CLRF    IOCCF		    ; (1) clear interrupts
waitFP4:    
    BTFSS   IOCCF,6		    ; (2) Wait for /CLK1 to fall 2nd time
    GOTO    waitFP4		    ; (2) wait for above 
    
waitFP5:
    RETURN			    ; (~30) Ping cycle complete
;</editor-fold> ----------------------------------------------------------------

    

;<editor-fold defaultstate="collapsed" desc="RxCmd_Slave">----------------------
; RxCmd_Slave - Read Command in Slave mode, when PB-100 in control of bus
; Uses FSR1 to save Command to CMDBUF, caller sets FSR1 before calling
; Nibble RX order PB-100: CMD=Command Type, AD=Addr. In Device, DA=Device Addr., 
; CMDBUF -> CMD,NA (Nibble address packed into bytes in HB LB order)
; We count number of nibbles recvied. N<5 means a mode change w/o new address
; COUNTL: counts #nibbles read, bit 7 indicates odd/even nibble & flush needed
GLOBAL RxCmd_Slave
  
RxCmd_Slave:
    CLRF    IOCCF		    ; (1) clear interrupts
RxCt:    
    BTFSS   IOCCF,6		    ; (2) Skip if CLK1 (Bit6) went low
    GOTO    RxCt		    ; (2) wait for CLK1 to go low
    CLRF    IOCCF		    ; (1) clear interrupts
RxCt2:    
    BTFSS   IOCCF,6		    ; (2) Skip if CLK1 (Bit6) went low
    GOTO    RxCt2		    ; (2) wait for CLK1 to go low

    CALL    ReadNibble		    ; (##) Read Type nibble, 0-Read or 4-Write
    MOVWI   FSR1++		    ; (1) Write to first byte of buffer
    MOVLW   0x00		    ; (1) Pad buffer with zeros so we can write
    MOVWI   FSR1++		    ; (1) address nibble back in reverse, HB LB
    BANKSEL COUNTL		    ; (2) order
    INCF    COUNTL		    ; (1) Count the nibble we just read

nextNibbleRxC:			    ; Read nibbles every two CLK1 falling edges
    BANKSEL IOCCF		    ; (2) Interrupt On Change register
    CLRF    IOCCF		    ; (1) clear interrupts 
RxC3:  
    BTFSS   IOCCF,6		    ; (2) Skip if CLK1 (Bit6) went low
    GOTO    RxC3		    ; (2) wait for CLK1 to go low
    
    BANKSEL PORTC		    ; (2) Detects command end before 5 nibbles
    BTFSC   PORTC,7		    ; (1) Check if /CE is still low
    GOTO    RxC_done		    ; (2) If /CE high then exit
    
    BANKSEL IOCCF		    ; (2) If /CE still low keep going
    CLRF    IOCCF		    ; (1) Clear flags, wait for 2nd event
RxC4:
    BTFSS   IOCCF,6		    ; (2) Skip if CLK1 (Bit6) went low
    GOTO    RxC4		    ; (2) wait for CLK1 to go low
    CALL    ReadNibble		    ; (2 + 10) {2 + 8}

    BANKSEL COUNTL		    ; (2) make sure in correct bank 
    BTFSS   COUNTL,7		    ; (2) BIT7 of COUNT tells us which position 
    GOTO    RxC_even		    ; (2) to write next nibble to
    
RxC_Odd:			    ; Write nibble to High position
    IORWF   TEMP		    ; (1) OR in H, nibble is LH order in byte
    SWAPF   TEMP,W		    ; (1) Nibbles back to HL order
    MOVWI   FSR1--		    ; (1) Write to buffer
    BCF	    COUNTL,7		    ; (1) Clear flag indicate using Nl next loop
    INCF    COUNTL		    ; (1) Count nibble we just read
    GOTO    nextNibbleRxC	    ; (2) Loop back to read remaining nibbles
    
RxC_even:			    ; Write nibble to Low position
    MOVWF   TEMP		    ; (1) Store even/Low nibble in temp
    SWAPF   TEMP		    ; (1) Swap nibbles to L-H order
    INCF    COUNTL		    ; (2) Count nibble we just read in 
    BSF	    COUNTL,7		    ; (1) Set flag indicate Nh next loop
    GOTO    nextNibbleRxC	    ; (2) Loop back to read remaining nibbles
    
RxC_done:			    ; Command done. Need to check BIT7 of COUNT
    BANKSEL COUNTL		    ; (2) to see if there is a nibble left in 
    BTFSS   COUNTL,7		    ; (1) TEMP. If not RETURN.
    RETURN			    ; (2) [5]
    
    SWAPF   TEMP,W		    ; (1) Flush, Swap nibbles back to HL order
    MOVWI   FSR1--		    ; (1) Save last nibble to buffer 
    BCF	    COUNTL,7		    ; (1) Clear the special flag
RETURN				    ; (2) [7]
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="RxData_Slave">---------------------   
; RxData_Slave - Read in data nibbles in Slave mode, PB-100 in control of bus
; Caller sets FSR0 to point to PRAM buffer, Pack nibbles in bytes in LH order
; If Bit 7 of COUNT set on entering, we need to start with nibble Nh (odd) so,
; we need to read in whole byte into TEMP then mask of Nh
; Skip first /CE1 check for first nibble to get timing correct.
GLOBAL RxData_Slave
 
RxData_Slave:			    
    GOTO    RxD3		    ; (2) Skip first /CE1 tests for first nibble
    
RxD1:
    BANKSEL PORTC		    ; (2) 
    BTFSC   PORTC,7		    ; (1) Check if /CE1 is still low
    GOTO    RD_done		    ; (2) eixt if /CE1 went high
    
    BANKSEL IOCCF		    ; (2) Interrupt on Change flag register
    CLRF    IOCCF		    ; (1) clear interrupts
RxD2:				    ;
    BTFSS   IOCCF,6		    ; (2) Skip if /CLK1 (Bit6) went low
    GOTO    RxD2		    ; (2) /CLK1 not low so keep waiting

RxD3:    
    BANKSEL IOCCF		    ; (2) Entry point for first nibble 
    CLRF    IOCCF		    ; (1) Clear flags, wait for 2nd event
RxD4:
    BTFSS   IOCCF,6		    ; (2) Skip if /CLK1 (Bit6) went low
    GOTO    RxD4		    ; (2) /CLK1 not low so keep waiting
    
    CALL    ReadNibble		    ; (##) returned as low nibble in W 
    BANKSEL COUNTL		    ; (2) make sure in correct bank 
    BTFSS   COUNTL,7		    ; (2) if Bit 7 set Rx nibble Nh 
    GOTO    RD_even		    ; (2) if Bit7 clear Rx nibble Nl
    
RD_Odd:				    ; Odd/High nibble handler
    IORWF   TEMP,W		    ; (1) OR in H, nibble is LH order in byte
    MOVWI   FSR0++		    ; (1) Write to buffer  
    BANKSEL COUNTL		    ; (2) make sure in correct bank 
    BCF	    COUNTL,7		    ; (1) Clear flag indicate using Nl next loop
    GOTO    RxD1		    ; (2) Loop back to read remaining nibbles
    
RD_even:			    ; Even/LOw nibble handler
    MOVWF   TEMP		    ; (1) Store Even/Low nibble in temp
    SWAPF   TEMP		    ; (1) Swap nibbles to L-H order
    
    BSF	    COUNTL,7		    ; (1) set flag to use Nh next loop
    GOTO    RxD1		    ; (2) Loop back to read remaining nibbles
    
RD_done:
    BANKSEL COUNTL		    ; (2) See if there is a nibble left in TEMP.
    BTFSS   COUNTL,7		    ; (1) If not return.
    RETURN			    ; (2)
    
    SWAPF   TEMP,W		    ; (1) If so, Swap nibbles back to HL order
    MOVWI   FSR0++		    ; (1) Save last nibble to buffer
    BCF	    COUNTL,7		    ; (1) Clear the special flag

RETURN   
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="TxData_Slave">---------------------    
; TxData_Slave - Transmit data nibbles from PRAM buffer
; Nibbles packed in bytes in LH order, read from buffer pointed to by FSR0
; Caller should set FSR0 to point to proper location before calling
; If Bit 7 of COUNT set, we need to start with/send nibble Nh 
; Start first nibble after first /CE1, next nibbles every other /CE1
; We skip both /CE1 tests for first nibble to get timing correct.
GLOBAL TxData_Slave    
    
TxData_Slave:  
    MOVIW   FSR0++		    ; (1) Grab first 2 nibbles from buffer
    BANKSEL TEMP		    ; (1) 
    MOVWF   TEMP		    ; (1) in L-H order, stash in temp	
    GOTO    nextNibbleTxD2	    ; (2) Skip both /CE1 checks on first nibble
 
nextNibbleTxD1:			    ; 
    BANKSEL TEMP		    ; (2) 
    MOVIW   FSR0++		    ; (1) Grab 2 nibbles from buffer
    MOVWF   TEMP		    ; (1) in L-H order, stash in temp
    
nextNibbleTxD2:			    ; Use the 2nd nibble from last buffer read  
    BANKSEL TEMP		    ; (2) Make sure in correct bank 
    BTFSS   COUNTL,7		    ; (2) If Bit 7 set, send nibble Nh 
    GOTO    TxD_Nl		    ; (2) if Bit7 clear, send nibble Nl (even)
    
TxD_Nh:    
    MOVF    TEMP,W		    ; (1) Grab odd nibble, in L position of byte
    CALL    WriteNibble		    ; (10) Tx High nibble
    BANKSEL TEMP		    ; (2) make sure in correct bank 
    BCF	    COUNTL,7		    ; (1) Clear flag indicate using Nl next loop
    
    BANKSEL IOCCF		    ; (2) Need to wait for two /CLK1 
    CLRF    IOCCF		    ; (1) falling edges before checking for
Tx_Nh_1:			    ; /CE still being low
    BTFSS   IOCCF,6		    ; (2) Skip if CLK1 (Bit6) went low
    GOTO    Tx_Nh_1		    ; (2) Wait for CLK1 to go low   
    CLRF    IOCCF		    ; (1) falling edges before rreading data
Tx_Nh_2:     
    BTFSS   IOCCF,6		    ; (2) Skip if CLK1 (Bit6) went low
    GOTO    Tx_Nh_2		    ; (2) 
    
    BANKSEL PORTC		    ; (2) 
    BTFSC   PORTC,7		    ; (1) Check if /CE is still low
    GOTO    TxD_done		    ; (2) If not we are done
    GOTO    nextNibbleTxD1	    ; (2) Loop back handle any remaining nibbles
    
TxD_Nl:				    ; Send low nibble
    SWAPF   TEMP,W		    ; (1) swap nibbles to Nh_Nl, keep in W
    CALL    WriteNibble		    ; (10) Tx Low nibble
    BANKSEL TEMP		    ; (2) make sure in correct bank 
    BSF	    COUNTL,7		    ; (1) set flag to use Nh next loop
    
    BANKSEL IOCCF		    ; (2) Need to wait for two /CLK1 
    CLRF    IOCCF		    ; (1) falling edges before checking for
Tx_Nl_1:			    ; /CE still being low
    BTFSS   IOCCF,6		    ; (2) Skip if CLK1 (Bit6) went low
    GOTO    Tx_Nl_1		    ; (2) Wait for CLK1 to go low   
    CLRF    IOCCF		    ; (1) falling edges before rreading data
Tx_Nl_2:     
    BTFSS   IOCCF,6		    ; (2) Skip if CLK1 (Bit6) went low
    GOTO    Tx_Nl_2		    ; (2) 
    
    BANKSEL PORTC		    ; (2) 
    BTFSC   PORTC,7		    ; (1) Check if /CE is still low
    GOTO    TxD_done		    ; (2) If not we are done
    GOTO    nextNibbleTxD2	    ; (2) Loop back handle any remaining nibbles

TxD_done:  

RETURN
;</editor-fold> ----------------------------------------------------------------   
    
    
;<editor-fold defaultstate="collapsed" desc="RxData_Master">--------------------   
; RxData - Read in data nibbles
; Pack nibbles in bytes in LH order, save to buffer pointed to by FSR0
; Caller should set FSR0 to point to location in RAM buffer
; If Bit 7 of COUNT set, we need to start with/send nibble Nh 
;
GLOBAL RxData_Master
 
RxData_Master:    
    BANKSEL IOCCF		    ; (2) Lower /CE with falling CLK2
    CLRF    IOCCF		    ; (1) clear interrupts
RxDM1:  
    BTFSS   IOCCF,5		    ; (1-2) Skip if CLK2 (Bit5) went low
    GOTO    RxDM1		    ; (2) wait for CLK2 to go low
    CALL    EnableCE		    ; (6 + 8) drop /CE (Bit7)
    
    BANKSEL IOCCF		    ; (2) In Master mode read first nibble after
    CLRF    IOCCF		    ; (1) one CLK1 falling edge, make up for
    GOTO    RxDM5		    ; (2) time taken in EnableCE 
    
nextNibbleRxM:			    ; Read nibbles every two CLK1 falling edges 
    BANKSEL IOCCF		    ; (2) Interrupt on Change flag register
    CLRF    IOCCF		    ; (1) clear interrupts
RxDM4:  
    BTFSS   IOCCF,6		    ; (2) Skip if CLK1 (Bit6) went low
    GOTO    RxDM4		    ; (2) wait for CLK1 to go low
    
    CLRF    IOCCF		    ; (1) clear interrupts
RxDM5:
    BTFSS   IOCCF,6		    ; (2) Skip if CLK1 (Bit6) went low
    GOTO    RxDM5		    ; (2) wait for CLK1 to go low
    CALL    ReadNibble		    ; (##) returned as low nibble in W
    
    BANKSEL COUNTL		    ; (2) make sure in correct bank 
    BTFSS   COUNTL,7		    ; (1-2) if Bit 7 set, we need to Rx nibble Nh 
    GOTO    RDM_even		    ; (2) if Bit7 clear, we need to Rx nibble Nl
    
RDM_Odd:			    ; high/Odd nibble handler
    IORWF   TEMP,W		    ; (1) OR in H, nibble is LH order in byte
    MOVWI   FSR0++		    ; (1) Write to buffer
    
    BCF	    COUNTL,7		    ; (1) Clear flag to indicate using Nl next loop
    DECFSZ  COUNTL		    ; (2) dec # bytes to read, skip if result zero  
    GOTO    nextNibbleRxM	    ; (2) Loop back to read remaining nibbles
    GOTO    RxDM_done		    ; (2) Done if COUNT=0
    
RDM_even: 
    MOVWF   TEMP		    ; (1) Store Even/Low nibble in temp
    SWAPF   TEMP		    ; (1) Swap nibbles to L-H order
    
    DECF    COUNTL		    ; (2) dec # nibbles to send
    BTFSC   STATUS,2		    ; (1-2) If COUNT not zero we have more nibbles
    GOTO    RxDM_done		    ; (2)
    BSF	    COUNTL,7		    ; (1) set flag to use Nh next loop
    GOTO    nextNibbleRxM	    ; (2) Loop back to read remaining nibbles
    
RxDM_done:
    BANKSEL TEMP		    ; (2) 
    MOVF    TEMP,W		    ; (1) Grab TEMP just in case
    BTFSC   COUNTL,7		    ; (1-2) If set then TEMP needs flushed
    MOVWI   FSR0++		    ; (1) Write TEMP to buffer
    
    BANKSEL IOCCF		    ; (2) Master mode, Raise /CE for read done
    CLRF    IOCCF		    ; (1) clear interrupts 
RxDM6:  
    BTFSS   IOCCF,5		    ; (2) Skip if CLK2 (Bit5) went low
    GOTO    RxDM6		    ; (2) wait for CLK2 to go low  
    CALL    DisableCE		    ; (2 + 8) Raise /CE (Bit7)  
RETURN   
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="TxCmd_Master">---------------------
; Used when PIC in Master mode, PIC controlling bus
; *** Need to rework this function
; TxCmd_Master - Send command which has been added to CBUF
; DA=device address: Device 0 = $0000-$07FF, Device 1 = $0800-$0FFF
; AD=Address within device, Effective address in PIC = DA*$0800+MA
; Command buffer layout: T1,B1,B0  B1=DVA_AD2, B0=AD1_AD0, COUNT=#nibbles
; Nibble output sequence: T1,AD0,AD1,AD2,DVA.
GLOBAL TxCmd_Master

TxCmd_Master:   
    BANKSEL IOCCF		    ; (2) Interrupt on Change flag register
    CLRF    IOCCF		    ; (1) clear interrupts
TxC1:  
    BTFSS   IOCCF,5		    ; (1-2) Skip if CLK2 (Bit5) went low
    GOTO    TxC1		    ; (2) wait for CLK2 to go low
    CALL    EnableCE_OP		    ; (6 + 8) drop /CE (Bit7) & /OP (Bit4)

; Nibble 1  
    BANKSEL IOCCF		    ; (2) Interrupt on Change flag register
    CLRF    IOCCF		    ; (1) clear interrupts
    GOTO    TxC3		    ; (2) First nibble after 1 wait state
    
; Nibbles 2-n   
nextNibbleTxC:
    BANKSEL IOCCF		    ; (2) Interrupt on Change flag register
    CLRF    IOCCF		    ; (1) clear interrupts
TxC2:  
    BTFSS   IOCCF,6		    ; (2) Skip if CLK1 (Bit6) went low
    GOTO    TxC2		    ; (2) wait for CLK1 to go low
    CLRF    IOCCF		    ; (1) Clear flags, wait for 2nd event
TxC3:  
    BTFSS   IOCCF,6		    ; (2) Skip if CLK1 (Bit6) went low
    GOTO    TxC3		    ; (2) wait for CLK1 to go low
    MOVIW   FSR1++		    ; (1) grab next byte from buffer, inc pointer
    CALL    WriteNibble		    ; (2 + 15) {2 + 13}
    
    BANKSEL COUNTL		    ; * (2) make sure in correct bank 
    DECFSZ  COUNTL		    ; * (2) dec # bytes to send, skip if result zero
    GOTO    nextNibbleTxC	    ; * (2) if bytes left loop back to read them

; Set control lines to end of Command Tx
    BANKSEL IOCCF		    ; (2) Interrupt on Change flag register
    CLRF    IOCCF		    ; (1) clear interrupts
TxC4:  
    BTFSS   IOCCF,6		    ; (2) Skip if CLK1 (Bit6) went low
    GOTO    TxC4		    ; (2) wait for CLK1 to go low
    CALL    DisableCE_OP	    ; (2 + 8) Raise /CE (Bit7) & /OP (Bit4)  
    
; Delay between Command and following data, 25us~50us
TxC5:
    MOVLW   0x02		    ; CMD to DATA delay 25us~50us
    MOVWF   LOOPS		    ; Inner loop
    MOVLW   0x01		    ;  
    MOVWF   LOOPL		    ; Outer loop
    CALL    Delay		    ; Delay = Outer * Inner * 25us = 1us
RETURN
;</editor-fold> ---------------------------------------------------------------- 
    
    
;<editor-fold defaultstate="collapsed" desc="TxData_Master">---------------------    
; TxData_Slave - Transmit data nibbles from PRAM buffer
; Nibbles packed in bytes in LH order, read from buffer pointed to by FSR0
; Caller should set FSR0 to point to proper location before calling
; If Bit 7 of COUNT set, we need to start with/send nibble Nh 
GLOBAL TxData_Master    
    
TxData_Master:  
    MOVIW   FSR0++		    ; (1) Grab first 2 nibbles from buffer
    BANKSEL TEMP		    ; (1) 
    MOVWF   TEMP		    ; (1) in L-H order, stash in temp

TxDM3:    
    BANKSEL IOCCF		    ; (2) Master mode
    CLRF    IOCCF		    ; (1) clear interrupts 
TxDM4:    
    BTFSS   IOCCF,5		    ; (1-2) Wait for CLK2 to go low, drop /CE1
    GOTO    TxDM4		    ; (2) 
    CALL    EnableCE		    ; (6) Lower /CE1
    
    BANKSEL IOCCF		    ; (2) Send first nibble after 1 CLK1 falling
    CLRF    IOCCF		    ; (1) edge to get timing correct. 
    GOTO    TxDM6		    ; (2) 
 
nextNibbleTxDM1:		    ; Grab next two nibbles from buffer
    MOVIW   FSR0++		    ; (1) Grab 2 nibbles from buffer
    MOVWF   TEMP		    ; (1) in L-H order, stash in temp
    
nextNibbleTxDM2:		    ; Use the 2nd nibble from last buffer read
    BANKSEL IOCCF		    ; (2) Need to wait for two /CLK1 
    CLRF    IOCCF		    ; (1) falling edges before rreading data
TxDM5:  
    BTFSS   IOCCF,6		    ; (2) Skip if CLK1 (Bit6) went low
    GOTO    TxDM5		    ; (2) wait for CLK1 to go low
    CLRF    IOCCF
TxDM6:     
    BTFSS   IOCCF,6		    ; (2) Skip if CLK1 (Bit6) went low
    GOTO    TxDM6		    ; (2) wait for CLK1 to go low
    
    BANKSEL TEMP		    ; (2) make sure in correct bank 
    BTFSS   COUNTL,7		    ; (1-2) if Bit 7 set, send nibble Nh 
    GOTO    TxDM_Nl		    ; (2) if Bit7 clear, send nibble Nl
    
TxDM_Nh:    
    MOVF    TEMP,W		    ; (1) grab odd nibble, in L position of b
    CALL    WriteNibble		    ; (10) Tx High nibble

    BANKSEL TEMP		    ; (2) make sure in correct bank 
    BCF	    COUNTL,7		    ; (1) Clear flag to indicate using Nl next loop
    DECFSZ  COUNTL		    ; (2) dec # bytes to send, skip if result zero   
    GOTO    nextNibbleTxDM1	    ; (2) if bytes left loop back to read them
    GOTO    TxDM_done		    ; (2)
    
TxDM_Nl: 
    SWAPF   TEMP,W		    ; (1) swap nibbles to Nh_Nl, keep in W
    CALL    WriteNibble		    ; (10) Tx Low nibble
    BANKSEL TEMP		    ; (2) make sure in correct bank 
    DECF    COUNTL		    ; (2) dec # nibbles to send
    BTFSC   STATUS,2		    ; (1-2) If COUNT not zero we have more nibbles
    GOTO    TxDM_done		    ; (2)
    BSF	    COUNTL,7		    ; (1) set flag to use Nh next loop
    GOTO    nextNibbleTxDM2	    ; (2) if bytes left loop back to send them

TxDM_done:  
    BANKSEL IOCCF		    ; (2) Interrupt on Change flag register
    CLRF    IOCCF		    ; (1) clear interrupts 
TxDM_7:  
    BTFSS   IOCCF,5		    ; (2) Skip if CLK2 (Bit5) went low
    GOTO    TxDM_7		    ; (2) wait for CLK2 to go low  
    CALL    DisableCE		    ; (2 + 8) Raise /CE (Bit7) & /OP (Bit4) 
    
RETURN
;</editor-fold> ----------------------------------------------------------------   
    
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="DownloadHandler">------------------
; Download RAM from both CRAM and PRAM Devices and send out over UART
; Device RAM is output in order, DEV0->DEV3 for all DEVs that exist.
GLOBAL DownloadHandler
    
DownloadHandler:
    CALL    DumpHeader		    ; (#) Start file with header
    
    BANKSEL DEVTYPE		    ; (2) 
    MOVF    DEVTYPE,W		    ; (1) Grab Device type config byte
    BANKSEL TEMP2		    ; (1) 
    MOVWF   TEMP2		    ; (1) Stash it in TEMP2
    SWAPF   TEMP2		    ; (1) Swap type mask to low nibble
    MOVLW   0x0F		    ; (1) mask off high nibble
    ANDWF   TEMP2		    ; (1) TEMP2 is now DEV type mask
    CLRF    DEVICE		    ; (1) Start with current DEV0

dLoop1: 
    BANKSEL TEMP2		    ; branch to correct device type handler
    BTFSS   TEMP2,0		    ; (1) If Bit 0 set it is PRAM, 
    GOTO    dLoopCRAM		    ; (2) else it is CRAM

; If more than 1 DEV in PRAM supported, adjust to correct location in buffer    
dLoopPRAM:
    MOVLW   PRAM_BL		    ; (1) Set FSR1 to point to start of PRAM
    MOVWF   FSR1L		    ; (1) Used only for PIC RAM devices
    MOVLW   PRAM_BH		    ; (1) 
    MOVWF   FSR1H		    ; (1)    
    CALL    DumpPRAM		    ; (#) Dump this PRAM
    GOTO    dLoopTest		    ; (2) See if we have move DEVs to dump
    
dLoopCRAM:
    BANKSEL NIBADD		    ; (2) Zero start nibble address for PB-100
    CLRF    NIBADD		    ; (1) For CRAM
    CALL    DumpCRAM		    ; (#) Dump this CRAM 
    
dLoopTest:
    INCF    DEVICE		    ; (2) Inc to next device #
    MOVF    DEVICE,W		    ; (1) grab device #
    BANKSEL DEVTYPE		    ; (2) 
    XORWF   DEVTYPE,W		    ; (1) XOR, get difference in low nibble
    ANDLW   0x0F		    ; (1) Mask off high nibble
    BTFSC   STATUS,2		    ; (2) If W!=0 keep going
    GOTO    dDone		    ; (2) Else, we are done

    BANKSEL TEMP2		    ; (2) Shift Device type mask right
    RRF	    TEMP2		    ; (1) So we can test device type 
    GOTO    dLoop1		    ; (2) on next loop. Keep going.
    
dDone:   
    
RETURN
;</editor-fold> ----------------------------------------------------------------   
    
    
;<editor-fold defaultstate="collapsed" desc="UploadHandler">--------------------
; Upload from UART to Casio RAM (CRAM) / PIC RAM (PRAM)
; Uses COUNTL, COUNTH, NIBADD, TEMP1
GLOBAL UploadHandler
    
UploadHandler:
    TurnOnLED   
    CALL    WaitForBtnPress	    ; Wait for button pressed  > 100ms
    CALL    WaitForBtnRelease	    ; Wait for button released > 100ms

uCheckHeader:
    ; "PICRAM 1.0 mn***" 
    ; HB = 0b0010, 0=DEV is CRAM, 1=DEV is PRAM
    ; LB = 2 = two devices presnet
    CALL    RxBuffer		    ; (#) This line will Rx the header

    ; Device type in header must match device type in DEVTYPE
    ; if not exit, if so keep going using DEVTPYE processed as above.
    BANKSEL RXBUF_START		    ; (1) DEVTYPE in two ASCII numbers
    SWAPF   RXBUF_START+11	    ; (1) Swap nibbles, 0x32->0x23
    MOVLW   0xF0		    ; (1) mask off low nibble 0x20
    ANDWF   RXBUF_START+11	    ; (1) Save for now
    MOVF    RXBUF_START+12,W	    ; (1) Get low nibble of Device type
    ANDLW   0x0F		    ; (1) Mask off high nibble
    IORWF   RXBUF_START+11,W	    ; (1) Now have complete Device type byte
    
    BANKSEL DEVTYPE		    ; (2) byte 11,12 are mn
    XORWF   DEVTYPE,W		    ; (1) If Device type matches DEVTYPE Z=0
    BTFSS   STATUS,2		    ; (1) Keep processing if match
    GOTO    UploadHandlerDone	    ; (1) else stop and return

uGetDevMask:        
    BANKSEL DEVTYPE		    ; (2) 
    MOVF    DEVTYPE,W		    ; (1) Grab Device type config byte
    BANKSEL TEMP2		    ; (1) 
    MOVWF   TEMP2		    ; (1) Stash it in TEMP2
    SWAPF   TEMP2		    ; (1) Swap type mask to low nibble
    MOVLW   0x0F		    ; (1) mask off high nibble
    ANDWF   TEMP2		    ; (1) TEMP2 is now DEV type mask
    CLRF    DEVICE		    ; (1) Start with current DEV0  

uLoop1:
    BANKSEL NIBADD		    ; (2) Zero start nibble address for PB-100
    CLRF    NIBADD		    ; (1) For CRAM
    
    ; *** need to calc correct PRAM starting address
    BANKSEL PRAM_BH
    MOVLW   PRAM_BH		    ; (1) high byte start of PRAM buffer
    MOVWF   FSR1H		    ; (1) 
    MOVLW   PRAM_BL		    ; (1) low byte of PRAM Buffer
    MOVWF   FSR1L		    ; (1) [4]
    
    BANKSEL TEMP1		    ; (2) Set up loop counter
    MOVLW   0x40		    ; (1) 0x40_loops*0x20_nib=0x400 bytes (1KB)
    MOVWF   TEMP1		    ; (1) TEMP1 is # loops counter
      
uLoop2:    
    CALL    RxBuffer		    ; (#) This line will Rx the header
    ; check for rx error here
    
    BANKSEL TEMP2		    ; (2) Branch to correct device type handler
    BTFSS   TEMP2,0		    ; (1) If Bit 0 set is PRAM, 
    GOTO    uLoopCRAM		    ; (2) else it is CRAM
 
uLoopPRAM:
    ; should have 16 bytes in RXBUF here
    CALL    Upload_PRAM		    ; (#) Dump this PRAM
    GOTO    uLoopTest		    ; (2) ; need to loop to get all 0x40 packets
    
uLoopCRAM:
    ; should have 16 bytes in RXBUF here
    CALL    Upload_CRAM		    ; (#) Sends 16 bytes to PB-100
    
uLoopTest: 
    BANKSEL TEMP1		    ; (2) Current device loop
    DECFSZ  TEMP1		    ; (2) If zero we are done with this device,
    GOTO    uLoop2		    ; (2) else keep looping.
    
    INCF    DEVICE		    ; (2) Inc to next device #
    MOVF    DEVICE,W		    ; (1) grab device #
    BANKSEL DEVTYPE		    ; (2) 
    XORWF   DEVTYPE,W		    ; (1) XOR, get diff in low nibble
    ANDLW   0x0F		    ; (1) Mask off high nibble
    BTFSC   STATUS,2		    ; (2) If W!=0 keep going
    GOTO    UploadHandlerDone	    ; (2) Else, we are done

    BANKSEL TEMP2		    ; (2) Shift Device type mask right
    RRF	    TEMP2		    ; (1) So we can test device type 
    GOTO    uLoop1		    ; (2) on next loop. Keep going.
;  
;                    BANKSEL COUNTH
;    CLRF    COUNTH
;    MOVLW   0x10
;    MOVWF   COUNTL
;    ResetRxBufPtrFSR0		    ; (4) Resets FSR0 to beginning of RXBUF
;    CALL    TxBuffer
;    GOTO    UploadHandlerDone
    
UploadHandlerDone:
    TurnOffLED
RETURN
;</editor-fold> ----------------------------------------------------------------   
    
    
;<editor-fold defaultstate="collapsed" desc="StatusHandler">--------------------
; Sets FSR0 to point to CBUF and sets length in TEMP to 5
; This is a test function
GLOBAL StatusHandler

StatusHandler:      
    BANKSEL VersionText
    MOVLW   LOW VersionText
    MOVWF   FSR0L
    MOVLW   HIGH VersionText
    IORLW   0x80
    MOVWF   FSR0H
    
    BANKSEL COUNTL		    ; (2) Bytes to send in COUNTH, COUNTL (HB, LB)
    MOVLW   0x00		    ; (1) 
    MOVWF   COUNTH		    ; (1) High byte
    MOVIW   FSR0++
    MOVWF   COUNTL		    ; (1) Low byte
    
RETURN
;</editor-fold> ----------------------------------------------------------------   
    
    
;<editor-fold defaultstate="collapsed" desc="XHandler">-------------------------
; Sets FSR1 to point to CBUF and sets length in TEMP to 5
; This is a test function
GLOBAL XHandler

XHandler:   

RETURN
;</editor-fold> ----------------------------------------------------------------  
     
    
;<editor-fold defaultstate="collapsed" desc="YHandler">-------------------------
; Sets FSR1 to point to CBUF and sets length in TEMP to 5
; This is a test function
GLOBAL YHandler

YHandler:   
    CALL    DumpPRAM
    
RETURN
;</editor-fold> ----------------------------------------------------------------  
    
    
;<editor-fold defaultstate="collapsed" desc="ZHandler">-------------------------
; Zeros out all RAM in the PB-100
; FSR0 points to RXBUF, FSR1 points to PRAM
; TEMP1 is loop counter. DEVTYPE HB is DEV type mask, LB is DEV count
; Set a loop counter to zero, compare to DEVTYPE&0x0F
; Can bit test b4 then >> to test b4 again
GLOBAL ZHandler

ZHandler:			    ; Fill RXBUF with zeros
    ResetRxBufPtrFSR0		    ; (4) Resets FSR0 to beginning of RXBUF
    BANKSEL DEVTYPE
    MOVF    DEVTYPE,W		    ; (1) Grab Device type config byte
    BANKSEL TEMP2		    ; (1) 
    MOVWF   TEMP2		    ; (1) Stash it in TEMP2
    SWAPF   TEMP2		    ; (1) Move type mask to low nibble
    MOVLW   0x0F		    ; (1) mask off high nibble
    ANDWF   TEMP2		    ; (1) TEMP2 low nibble is DEV type mask
    
    MOVLW   0x10		    ; (1) Clear 16 bytes
    MOVWF   TEMP1		    ; (1) TEMP1 used as loop counter			    
    MOVLW   0xA5		    ; (1) Set W to fill value
zClearLoop:   
    MOVWI   FSR0++		    ; (1) Write to RXBUF
    DECFSZ  TEMP1		    ; (2) 
    GOTO    zClearLoop		    ; (2) Loop until done
      
    BANKSEL DEVICE		    ; (2) cfg nibble address
    CLRF    DEVICE		    ; (1) Start with DEV0
zLoop1: 
    BANKSEL NIBADD		    ; (2) Zero start nibble address for PB-100
    CLRF    NIBADD		    ; (1) For CRAM
    MOVLW   0x40		    ; (1) 0x40_loops*0x20_nib=0x400 bytes (1KB)
    MOVWF   TEMP1		    ; (1) TEMP1 is # loops counter

    ; adjust to point to correct location in PRAM buffer for device
    MOVLW   PRAM_BL		    ; (1) Set FSR1 to point to start of PRAM
    MOVWF   FSR1L		    ; (1) Used only for PIC RAM devices
    MOVLW   PRAM_BH		    ; (1) 
    MOVWF   FSR1H		    ; (1)    

zLoop2:    
;    BANKSEL RXBUF_START		    ; (2) For testing 
;    MOVF    TEMP1,W		    ; (1) Change first byte of each line,
;    MOVWF   RXBUF_START		    ; (1) 16 bytes/line, to loop counter

    BANKSEL TEMP2
    BTFSS   TEMP2,0		    ; (1) If Bit 0 set is PRAM, else is CRAM
    GOTO    zLoopCRAM		    ; (2) 
     
zLoopPRAM:
    CALL    Upload_PRAM		    ; (#)     
    GOTO    zLoopTest		    ; (2) 
    
zLoopCRAM:
    CALL    Upload_CRAM		    ; (#) Sends 16 bytes to PB-100  
    
zLoopTest:
    BANKSEL TEMP1		    ; (2)
    DECFSZ  TEMP1		    ; (2) If zero we are done
    GOTO    zLoop2		    ; (2) If not keep looping

    INCF    DEVICE		    ; (2) Inc to next device #
    MOVF    DEVICE,W		    ; (1) grab device #
    BANKSEL DEVTYPE		    ; (2) 
    XORWF   DEVTYPE,W		    ; (1) XOR, get diff
    ANDLW   0x0F		    ; (1) Mask off low nibble
    BTFSC   STATUS,2		    ; (2) If W!=0 we are not done
    GOTO    zDone		    ; (2) Else, keep going

    BANKSEL TEMP2		    ; (2) Shift Device type mask right
    RRF	    TEMP2		    ; (1) So we can test next device type 
    GOTO    zLoop1		    ; (2) keep going
    
zDone:

RETURN
;</editor-fold> ----------------------------------------------------------------  
    

;<editor-fold defaultstate="collapsed" desc="DumpCRAM">-------------------------
; Turn on CWG Quadrature Clk and Read RAM in PB-100
; Command buffer layout: CNT,T1,B1,B0  B1=DVA_AD2, B0=AD1_AD0  
; Data Nibbles: T1,AD0,AD1,AD2,DVA. 
; TEMP used in some called functions, TEMP1 used for loop counter
; COUNT H, COUNTL used for nibble counters
; Pass Device# in DEVICE
GLOBAL DumpCRAM 
    
DumpCRAM:       
    BANKSEL TEMP1		    ; (2) Set up loop counter
    MOVLW   0x40		    ; (1) 0x40_loops*0x20_nib=0x400 bytes (1KB)
    MOVWF   TEMP1		    ; (1) TEMP1 is # loops counter
    CLRF    TEMP2		    ; (1) TEMP2 is starting nibble index for CMD
    
    GOTO    dumpLoop2		    ; (2) Skip over PORTC set up to first read

dumpLoop:    
    BANKSEL TEMP2		    ; (2) Enter here for loops 2+
    BCF	    STATUS,0		    ; (1) clear carry flag
    MOVLW   0x02		    ; (1) We are reading in groups of 32 nibbles
    ADDWF   TEMP2		    ; (1) increment the counter
    
dumpLoop2:			    ; Enter here on first loop
    CALL    WaitForPing		    ; (##) Wait for next ping, and next idle
    CALL    WaitForIdle		    ; (##) set up for master mode control
    CALL    Port_C_Output	    ; (##) PORTC Set all Pins to outputs
    ConfigTMR2_CWG		    ; (##) Config TMR2 to output quad. clocks
    CWG_Out_ON			    ; (##) Configure RAxPPS for CWG outputs
    
dumpSetAddrCnt:			    ;  Set starting address in Command Buffer 
    ResetCBufPtrFSR1		    ; (4) Resets FSR1 to beginning of CBUF
    BANKSEL TEMP2		    ; (2) Select bank before using macro
    mBuildCMD_F 0x00,TEMP2,DEVICE   ; (12) Type,N2_N1,Device. N0 always zero
    ResetCBufPtrFSR1		    ; (4) Resets FSR1 to beginning of CBUF

    BANKSEL COUNTL		    ; (2) Set number of nibbles to send
    MOVLW   0x05		    ; (1) 
    MOVWF   COUNTL		    ; (1) 
    CALL    TxCmd_Master	    ; (##) Send read command to PB-100
   
dumpReadNibbles:		    ; Set up to read 32 nibbles from the PB-100
    ResetRxBufPtrFSR0		    ; (4) Resets FSR0 to beginning of RXBUF
    BANKSEL COUNTL		    ; (2)
    CLRF    COUNTH		    ; (1) Make sure HB is zero
    MOVLW   0x20		    ; (1) 32 nibbles to read
    MOVWF   COUNTL		    ; (1) COUNTH,COUNTL (HB,LB) 16bit counter
    CALL    Port_C_Read		    ; (#) Config PORTC bits 0-3 input, 4-7 output
    CALL    RxData_Master	    ; (#) read in 32 nibbles
    
    CWG_Out_OFF			    ; (#) Back to slave mode, monitor PB-100 bus
    ConfigTMR2_Idle		    ; (#) 
    CALL    Port_C_Input	    ; (#) Default to inputs / HiZ

dumpToUART:			    ; Set up # bytes to Tx counter and call Tx 
    TurnOnLED
    ResetRxBufPtrFSR0		    ; (4) Resets FSR0 to beginning of RXBUF
    BANKSEL COUNTL		    ; (2) Set #Bytes to Tx in COUNTH, COUNTL
    CLRF    COUNTH		    ; (1) High byte
    MOVLW   0x10		    ; (1) Send 16 bytes
    MOVWF   COUNTL		    ; (1) Low byte
    CALL    TxBuffer		    ; (#) Tx 16 bytes, (32 nibbles)
    TurnOffLED
    BANKSEL TEMP1		    ; (2)
    DECFSZ  TEMP1		    ; (2) If zero we are done
    GOTO    dumpLoop		    ; (2) If not keep looping
    
RETURN
;</editor-fold> ---------------------------------------------------------------- 
    
    
;<editor-fold defaultstate="collapsed" desc="DumpPRAM">-------------------------
; Dump PRAM to UART with header
; TEMP used in some called functions, TEMP1 used for loop counter
; COUNT H, COUNTL used for nibble counters
; FSR0 used for RXBUF pointer, FSR1 used for PRAM pointer
GLOBAL DumpPRAM  
    
DumpPRAM:       
    BANKSEL TEMP1		    ; (2) Set up loop counter
    MOVLW   0x40		    ; (1) 0x40_loops*0x20_nib=0x400 bytes (1KB)
    MOVWF   TEMP1		    ; (1) TEMP1 is # loops counter
    
    ; this needs to be based on Device# eventaully for > 1K of PRAM
    MOVLW   PRAM_BL		    ; (1) Set FSR1 to point to start of PRAM
    MOVWF   FSR1L		    ; (1) 
    MOVLW   PRAM_BH		    ; (1) 
    MOVWF   FSR1H		    ; (1)    

dPICLoop:			    ; Set up to read 16 bytes from PRAM 
    ResetRxBufPtrFSR0		    ; (4) Resets FSR0 to beginning of RXBUF
    BANKSEL COUNTL		    ; (2)
    CLRF    COUNTH		    ; (1) Make sure HB is zero
    MOVLW   0x10		    ; (1) 16 bytes to send
    MOVWF   COUNTL		    ; (1) COUNTH,COUNTL (HB,LB) 16bit counter

dPICLoop2:			    ;    
    MOVIW   FSR1++		    ; (1) Grab next byte of PRAM
    MOVWI   FSR0++		    ; (1) move it to the RXBUFFER/TXBUFFER
    BANKSEL COUNTL		    ; (2)
    DECFSZ  COUNTL		    ; (2) 
    GOTO    dPICLoop2		    ; (2) keep going 

dPICToUART:			    ; Set up # bytes to Tx counter and call Tx 
    ResetRxBufPtrFSR0		    ; (4) Resets FSR0 to beginning of RXBUF
    BANKSEL COUNTL		    ; (2) Set #Bytes to Tx in COUNTH, COUNTL
    CLRF    COUNTH		    ; (1) High byte
    MOVLW   0x10		    ; (1) Send 16 bytes
    MOVWF   COUNTL		    ; (1) Low byte
    CALL    TxBuffer		    ; (#) Tx 16 bytes, uses FSR0

    BANKSEL TEMP1		    ; (2)
    DECFSZ  TEMP1		    ; (2) If zero we are done
    GOTO    dPICLoop		    ; (2) If not keep looping
    
RETURN
;</editor-fold> ---------------------------------------------------------------- 
    
    
;<editor-fold defaultstate="collapsed" desc="DumpHeader">-----------------------
; Dump file header to UART
; FSR1 points to text in ROM, FSR0 points to TX/RX buffer
GLOBAL DumpHeader

DumpHeader:   
    BANKSEL HeaderText		    ; (2) "PICRAM 1.0 mn***"
    MOVLW   LOW HeaderText	    ; (1) Low byte of pointer
    MOVWF   FSR1L		    ; (1) Read in text using FSR1
    MOVLW   HIGH HeaderText	    ; (1) High byte of pointer
    IORLW   0x80		    ; (1) OR in Bit7 as we are readig from ROM
    MOVWF   FSR1H		    ; (1)
    
    BANKSEL COUNTL		    ; (2) #Bytes is in first char of HeaderText
    MOVLW   0x00		    ; (1) COUNTH, COUNTL (HB, LB)
    MOVWF   COUNTH		    ; (1) High byte
    MOVIW   FSR1++		    ; (1) Grab #bytes in string
    MOVWF   COUNTL		    ; (1) Low byte
    MOVWF   TEMP1		    ; (1) Save extra copy for transfer to RAM
    
    ResetRxBufPtrFSR0		    ; (#) Reset pointer to start of RXBUF
xferLoop:
    MOVIW   FSR1++		    ; (1) Copy HeaderText in ROM to RXBUF
    MOVWI   FSR0++		    ; (1) 
    DECFSZ  TEMP1		    ; (2) loop counter
    GOTO    xferLoop		    ; (2) 
    ResetRxBufPtrFSR0		    ; (#) Reset pointer to start of RXBUF   
    
    BANKSEL DEVTYPE		    ; (2) byte 11,12 are mn
    MOVF    DEVTYPE,W		    ; (1) Grab Device type config byte
    BANKSEL TEMP2		    ; (1) 
    MOVWF   TEMP2		    ; (1) Stash it in TEMP2
    SWAPF   TEMP2		    ; (1) Move type mask to low nibble
    MOVLW   0x0F		    ; (1) mask off high nibble
    ANDWF   TEMP2		    ; (1) TEMP2 low nibble is DEV type mask
    MOVLW   0x30		    ; (1) Convert to ASCII#
    IORWF   TEMP2,W		    ; (1) buffer
    MOVWF   RXBUF_START+11	    ; (1) buffer
    
    BANKSEL DEVTYPE		    ; (2) byte 11,12 are mn
    MOVF    DEVTYPE,W		    ; (1) Grab Device type config byte
    BANKSEL TEMP2		    ; (1) 
    MOVWF   TEMP2		    ; (1) Stash it in TEMP2
    MOVLW   0x0F		    ; (1) mask off high nibble
    ANDWF   TEMP2		    ; (1) TEMP2 low nibble is DEV type mask
    MOVLW   0x30		    ; (1) Convert to ASCII#
    IORWF   TEMP2,W		    ; (1) buffer
    MOVWF   RXBUF_START+12	    ; (1) buffer
    
    CALL    TxBuffer		    ; (#) Send buffer out over UART FSR1

    
RETURN
;</editor-fold> ----------------------------------------------------------------  
    
    
;<editor-fold defaultstate="collapsed" desc="LoadCRAM">-------------------------
; Turn on CWG Quadrature Clk and Read RAM in PB-100
; Command buffer layout: CNT,T1,B1,B0  B1=DVA_AD2, B0=AD1_AD0  
; Data Nibbles: T1,AD0,AD1,AD2,DVA. 
; TEMP used in some called functions, TEMP1 used for loop counter
; COUNT H, COUNTL used for nibble counters
GLOBAL LoadCRAM   
LoadCRAM:     
    
    
;</editor-fold> ---------------------------------------------------------------- 
    

;<editor-fold defaultstate="collapsed" desc="Upload_CRAM">----------------------
; Saves 16 bytes from RXBUFF to the PB-100, 
; Command buffer layout: CNT,T1,B1,B0  B1=DVA_AD2, B0=AD1_AD0  
; Data Nibbles: T1,AD0,AD1,AD2,DVA. 
; COUNT H, COUNTL used for nibble counters
; NIBADD used for nibble address counter
; Caller should set NIBADD to 0 before first call
; FSR0 used for RXBUF, FSR1 for CMDBUF
GLOBAL Upload_CRAM   
    
Upload_CRAM:			    ; Set to MASTER mode after entering Idle
    CALL    WaitForPing		    ; (##) Wait for next ping, and next idle
    CALL    WaitForIdle		    ; (##) set up for master mode control
    CALL    Port_C_Output	    ; (#) Set to Master mode, PIC controls bus
    ConfigTMR2_CWG		    ; (#) clocks, control, and data 
    CWG_Out_ON			    ; (#) Configure RAxPPS for CWG outputs
    
upSetAddrCnt:			    ; Set starting address in Command Buffer 
    ResetCBufPtrFSR1		    ; (4) FSR1 to beginning of CBUF, build CMD
    BANKSEL NIBADD
    mBuildCMD_F 0x04,NIBADD,DEVICE  ; (12) Type,N2_N1,Device. N0 always zero
    ResetCBufPtrFSR1		    ; (4) Resets FSR1 to beginning of CBUF

    BANKSEL COUNTL		    ; (2) Set number of nibbles to send
    MOVLW   0x05		    ; (1) 
    MOVWF   COUNTL		    ; (1) 
    CALL    TxCmd_Master	    ; (##) Send write command to PB-100
   
upWriteNibbles:			    ; Set up to write 32 nibbles to the PB-100
    ResetRxBufPtrFSR0		    ; (4) Resets FSR0 to beginning of RXBUF
    BANKSEL COUNTL		    ; (2)
    CLRF    COUNTH		    ; (1) Make sure HB is zero
    MOVLW   0x20		    ; (1) 32 nibbles to write
    MOVWF   COUNTL		    ; (1) COUNTH,COUNTL (HB,LB) 16bit counter
    CALL    TxData_Master	    ; (#) write 32 nibbles, 16 bytes, from RXBUF
    
    CWG_Out_OFF			    ; (#) Back to slave mode, monitor PB-100 bus
    ConfigTMR2_Idle		    ; (#) 
    CALL    Port_C_Input	    ; (#) Default to inputs / HiZ
    
    BANKSEL NIBADD		    ; (2) Incrment nibble address for next pass
    BCF	    STATUS,0		    ; (1) clear carry flag
    MOVLW   0x02		    ; (1) We are writing in groups of 32 nibbles
    ADDWF   NIBADD		    ; (1) increment the counter for next pass

RETURN 
;</editor-fold> ---------------------------------------------------------------- 
    
    
;<editor-fold defaultstate="collapsed" desc="Upload_PRAM">----------------------
; Saves 16 bytes from RXBUFF to the PRAM, 
; FSR0 used for RXBUF, FSR1 for PICRAM. TEMP used for loop counter
; Caller should set FRS1 to start of PRAM
GLOBAL Upload_PRAM   
    
Upload_PRAM:
    ResetRxBufPtrFSR0		    ; (4) Resets FSR0 to beginning of RXBUF
    BANKSEL TEMP		    ; (2)
    MOVLW   0x10		    ; (1) 0x40 lines of 16 bytes from RXBUF
    MOVWF   TEMP		    ; (1) COUNTH,COUNTL (HB,LB) 16bit counter

uPICLoop: 
    MOVIW   FSR0++
    MOVWI   FSR1++
    DECFSZ  TEMP
    GOTO    uPICLoop
    
RETURN 
;</editor-fold> ---------------------------------------------------------------- 