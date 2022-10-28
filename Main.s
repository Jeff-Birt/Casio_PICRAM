; Main.s
; Entry point for Casio_PICRAM
; Emulates a Casio 4-bit RAM chip used in 1980s pocket computers
    
PROCESSOR 16F18446
    
; We only #include for files which are only macros
#include <xc.inc>
#include "ConfigClkPmd.s"
#include "ConfigIOC.s"
#include "ConfigPins.s"
#include "ConfigTMR2.s"
#include "ConfigPWM6.s"
#include "ConfigCWG1.s"
#include "ConfigUART.s"
#include "Casio_Com_Macros.s"
#include "Helper_Macros.s"
 
    
;<editor-fold defaultstate="collapsed" desc="UnitTestInit">---------------------    
    
;#define EndableDebug		    ; Set to 1 enable/assemble units tests

#ifdef EndableDebug
    
EXTRN NAtoDA_Tests					; Test function
    
#endif
    
;</editor-fold> ----------------------------------------------------------------     
    
    
;<editor-fold defaultstate="collapsed" desc="Initialization">-------------------
    
;-------------------------------------------------------------------------------
; Definitions declared other files
EXTRN WaitForBtnPress, WaitForBtnRelease		; Helper_Functions.s
EXTRN Port_C_Input, Port_C_Output			; From Pin_Twiddlings.s
EXTRN WaitForPing, WaitForCE1, WaitForCLK1, InitCBUF	; From Casio_Com.s 
EXTRN Rx_Poll						; From UART_Com.s
    
;-------------------------------------------------------------------------------
; Reset vector,  GOTO to the actual Init routine from here
PSECT   ResetVec,class=CODE,delta=2
GLOBAL resetVec
resetVec:      
    PAGESEL main
    GOTO    main
    
    
;-------------------------------------------------------------------------------      
; Interrupt vector, not used
psect   Isr_Vec,global,class=CODE,delta=2
GLOBAL IsrVec
    
IsrVec:


;-------------------------------------------------------------------------------
; Reserve 1K of linear mapped RAM 0x2400-0x27FF for RAM Buffer
; PRAM is RAM buffer in PIC pretending to be Casio RAM chip
DLABS 1,0x2300,0x0400,PRAM
PRAM_BH equ 0x23		    ; Beginning of 1K RAM buffer Hi byte
PRAM_BL equ 0x00		    ; Beginning of 1K RAM buffer Low byte
PRAM_EH equ 0x26		    ; End of 1K RAM buffer Low byte
PRAM_EL equ 0xFF		    ; End of 1K RAM buffer Hi byte
GLOBAL PRAM_BH, PRAM_BL, PRAM_EH, PRAM_EL   
 
 
;-------------------------------------------------------------------------------
; Main loop states
ST_Init	    equ 0x00		    ; Power on / initialization state
ST_Run	    equ	0x01		    ; Normal Run state, just acting like RAM
ST_POff	    equ	0x02		    ; Powering down state
	    	    
;-------------------------------------------------------------------------------   
; Reserve RAM for keeping track of program state
PSECT   State,global,class=BANK0,size=0x01,noexec,delta=1,space=1
GLOBAL PSTATE, DEVTYPE
    PSTATE:	DS  0x01	    ; Current program state
 
;</editor-fold> ----------------------------------------------------------------  
    
;-------------------------------------------------------------------------------      
; Main code entry    
psect   main,global,class=CODE,delta=2
GLOBAL main     

main:
    SetState	ST_Init		    ; Set program state 
    ConfigPMD			    ; Periph power control
    ConfigPins			    ; Pin configuration
    ConfigClock			    ; Configure clock to proper settings
    ConfigPWM6			    ; PWM6 used for CWG1
    ConfigCWG1			    ; Uses PWM6 and TMR2
    ConfigTMR2_Idle		    ; Configure Timer used for idle detection
    ConfigUART			    ; Config UART for TX only
    CALL    Port_C_Input	    ; Default to inputs / HiZ

;-------------------------------------------------------------------------------
; Wait for button on PORTB Pin 5 pressed/released to start, for debugging only
    TurnOffLED			    ;
    CALL    WaitForBtnPress	    ; Wait for button pressed  > 100ms
    CALL    WaitForBtnRelease	    ; Wait for button released > 100ms

;-------------------------------------------------------------------------------
; Init PRAM and CBUF, wait for Ping before trying to talk to PB-100
    CALL    InitCBUF		    ; [7] Initialize Command BUffer
    ConfigIOC_R			    ; [14] PortC to general bus monitoring
    CALL    WaitForPing		    ; (##) Wait for 'ping' before bus monitoring
 
    
;-------------------------------------------------------------------------------
; Main program loop
    SetState	ST_Run		    ; Set program state 
    
begin:
    
    CALL    WaitForCE1		    ; (#) Monitor bus, return when idle detected
    CALL    Rx_Poll		    ; Service UART coms

    
WaitForDone:  
    CALL    WaitForCLK1		    ; Wait for PB-100 to output clocks before
    GOTO    begin		    ; monitoring buss again.

done:
    goto    done		    ; 

;-------------------------------------------------------------------------------
