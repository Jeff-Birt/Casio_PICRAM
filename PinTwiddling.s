; PinTwiddlings.s
; Helper functions for manipulating I/O ports

PROCESSOR 16F18446
#include <xc.inc>  
    
;-------------------------------------------------------------------------------   
; Reserve RAM for PORT ouput state backing store
; Backing store required to be able to read current state of an output in order
; to modify a single bit. The BSF, BCF do not work properly on ports.
PSECT   PortBack,global,class=BANK0,size=0x04,noexec,delta=1,space=1
GLOBAL  PRTA,PRTB

    PRTA:	DS  0x01	; PORTA outputs
    PRTB:	DS  0x01	; PORTB outputs
    PRTC:	DS  0x01	; PORTC outputs
    PRT_TEMP:	DS  0x01	; Temp storage for twiddling bits


;-------------------------------------------------------------------------------      
; PinTwiddle helper functions
psect   PinTwiddle ,global,class=CODE,delta=2


;;<editor-fold defaultstate="collapsed" desc="Port B functions">-----------------
;
;; Shared Port B, I/O direction lables
;GLOBAL IO_DIR_S, IO_DIR_R, IO_ENA_S, IO_ENA_R 
;IO_DIR_S	EQU 00100000B	; Bit5 I/O Dir->Hi, RB5 I/O Direction PIC->PC-4
;IO_DIR_R	EQU 11011111B	; Bit5 I/O Dir->Low, RB5 I/O Direction PC-4->PIC
;IO_ENA_S	EQU 10000000B	; Bit7 I/O Enable->Hi, RB7RB7 I/O Disable
;IO_ENA_R	EQU 01111111B	; Bit7 I/O Enable->Low, RB7RB7 I/O Enable
;
;
;; Initialize PRTB backing store, value passed in W
;InitPRTB:
;    BANKSEL PRTB
;    MOVWF   PRTB
;    RETURN
;    
;; Set Pin on Port B, update PRTB backing store
;; Load W with bit mask, i.e. IO_DIR_S, IO_ENA_S
;SetPrtBPin:
;    BANKSEL PORTB		; Twiddle the I/O buffer control pins
;    IORWF   PRTB,W		; Bit to set in W, OR with PRTB backing store
;    MOVWF   PRTB		; update PRTB backign store
;    MOVWF   PORTB		; update actual port
;    RETURN			;
;
;; Reset Pin on Port B, update PRTB backing store
;; Load W with bit mask, i.e. IO_DIR_R, IO_ENA_R
;ResetPrtBPin:
;    BANKSEL PORTB		; Twiddle the I/O buffer control pins  
;    ANDWF   PRTB,W		; Bit to clear in W, AND with PRTB backing store
;    MOVWF   PRTB		; update PRTB backing store
;    MOVWF   PORTB		; update actual port
;    RETURN			;
;    
;;</editor-fold> ----------------------------------------------------------------
    

;<editor-fold defaultstate="collapsed" desc="Port C functions">-----------------

; Shared Port C function lables
CE_ENABLE	EQU 01111111B	; Bit7 /CE -> Low,  Chip enable for RAM
CE_DISABLE	EQU 10000000B	; Bit7 /CE -> Hi, Chip enable for RAM
OP_ENABLE	EQU 11101111B	; Bit4 /OP -> Low, Write to RAM register
OP_DISABLE	EQU 00010000B	; Bit4 /OP -> Hi, Read from RAM
CE_OP_ENABLE	EQU 01101111B	; Bit7 /CE and /OP -> Low
CE_OP_DISABLE	EQU 10010000B	; Bit7 /CE and /OP -> Hi

	
;<editor-fold defaultstate="collapsed" desc="InitPRTC">-------------------------
; Initialize PRTC backing store, value passed in W
GLOBAL InitPRTC
InitPRTC:
    BANKSEL PRTC
    MOVWF   PRTC
RETURN
;</editor-fold> ----------------------------------------------------------------    

    
;<editor-fold defaultstate="collapsed" desc="Port_C_Input">---------------------
; Port C to input, PB-100 -> PIC, initial configuration
GLOBAL Port_C_Input
Port_C_Input:
    BANKSEL PORTC		; (2) (000E)
    CLRF    PORTC		; (1) Clear all PORTC outputs
    
    BANKSEL LATC		; (2) Clear all Data Latch
    CLRF    LATC		; (1) (001A)

    MOVLW   0xFF		; (1) Set all bits as inputs
    MOVWF   TRISC		; (1)  (0014)
RETURN				; [10]
;</editor-fold> ---------------------------------------------------------------- 

    
;<editor-fold defaultstate="collapsed" desc="Port_C_Output">--------------------  
; Port C to output, PIC -> PC-4
GLOBAL Port_C_Output
Port_C_Output:
    MOVLW   0xFF		; Start Port C out with all pins high
    BANKSEL PRTC		;
    MOVWF   PRTC		; update Port C backing store
    
    BANKSEL PORTC		; (000E)
    CLRF    LATC		; Clear all Data Latch, (001A)
    MOVWF   PORTC		; Port C outputs to 0xFF

    MOVLW   0x00		; All pins outputs
    MOVWF   TRISC		; (0014)
RETURN 
;</editor-fold> ----------------------------------------------------------------     


;<editor-fold defaultstate="collapsed" desc="Port_C_Read">----------------------
; Port C Read, PIC drives CLKs & CTRL lines, PB-100 drives DATA lines
GLOBAL Port_C_Read    
Port_C_Read:
    BANKSEL TRISC		; (2)
    MOVLW   0x0F		; (1) Bits 0-3 inputs, 4-7 outputs
    MOVWF   TRISC		; (1) 
RETURN				; (2) (6)
;</editor-fold> ----------------------------------------------------------------     
    
    
;<editor-fold defaultstate="collapsed" desc="Port_C_Write">---------------------    
; Port C Write, PB-100 drives CLKs & CTRL lines, PIC drives DATA lines
GLOBAL Port_C_Write
Port_C_Write:
    MOVLW   0xFF		; (1) Start Port C out with all pins high
    BANKSEL PRTC		; (2) 
    MOVWF   PRTC		; (2) update Port C backing store
    BANKSEL PORTC		; (2) (000E)
    MOVWF   PORTC		; (1) Init Port C outputs
    MOVLW   0xF0		; (1) Pins 0-3 as outputs
    MOVWF   TRISC
RETURN				; (2) [11]
;</editor-fold> ---------------------------------------------------------------- 
    
    
;<editor-fold defaultstate="collapsed" desc="SetPortCPin">-------------------------     
; Set Pin on Port C, update PRTC backing store
; Load W with bit mask, i.e. CE_ENABLE, CE_DISABLE
GLOBAL SetPrtCPin
SetPrtCPin:
    BANKSEL PORTC		; (2) Twiddle the I/O buffer control pins
    IORWF   PRTC,W		; (1) Bit to set in W, OR with PRTC backing store
    MOVWF   PRTC		; (1) update PRTC backing store
    MOVWF   PORTC		; (1) update actual port
RETURN				; (2) [7]
;</editor-fold> ---------------------------------------------------------------- 

    
;<editor-fold defaultstate="collapsed" desc="ResetPrtCPin">---------------------     
; Reset Pin on Port C, update PRTC backing store
; Load W with bit mask, i.e. CE_ENABLE, CE_DISABLE
GLOBAL ResetPrtCPin
ResetPrtCPin:
    BANKSEL PRTC		; (2) Twiddle the I/O buffer control pins  
    ANDWF   PRTC,W		; (1) Bit to clear in W, AND with PRTC backing store
    MOVWF   PRTC		; (1) update PRTC backing store
    BANKSEL PORTC		; (2)
    MOVWF   PORTC		; (1) update actual port
RETURN				; (2) [9]
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="EnableCE">-------------------------     
; Enable /CE, lower /CE bit
GLOBAL EnableCE
EnableCE:   
    MOVLW   CE_ENABLE		; (1) Set Low for /CE enable
    BANKSEL PRTC		; (2) Twiddle the I/O buffer control pins  
    ANDWF   PRTC,W		; (1) Clear Bit in W, AND w/PRTC backing store
    MOVWF   PRTC		; (1) update PRTC backing store
    MOVWF   PORTC		; (1) update actual port
RETURN				; (2) [8]
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="DisableCE">------------------------     
; Disable /CE, raise /CE bit
GLOBAL DisableCE
DisableCE:
    MOVLW   CE_DISABLE		; Set Hi for /CE disnable
    BANKSEL PRTC		; (2) Twiddle the I/O buffer control pins
    IORWF   PRTC,W		; (1) Bit to set in W, OR with PRTB backing store
    MOVWF   PRTC		; (1) update PRTC backing store
    MOVWF   PORTC		; (1) update actual port
RETURN				; (2) [7]
;</editor-fold> ----------------------------------------------------------------
       
    
;<editor-fold defaultstate="collapsed" desc="EnableOP">-------------------------     
; Enable /OP, lower /OP bit
GLOBAL EnableOP
EnableOP:
    MOVLW   OP_ENABLE		; (1) Set Low for /OP enable
    CALL    ResetPrtCPin	; (1) Update backing store, twiddle port pins
RETURN				; (2) [4]
;</editor-fold> ----------------------------------------------------------------
     

;<editor-fold defaultstate="collapsed" desc="DisableOP">---------------------     
; Disable /OP, raise /OP
GLOBAL DisableOP
DisableOP:
    MOVLW   OP_DISABLE		; (1) Set Hi for /OP disable
    CALL    ResetPrtCPin	; (##)Update backing store, twiddle port pins
RETURN				; (2) [##]
;</editor-fold> ----------------------------------------------------------------
  
    
;<editor-fold defaultstate="collapsed" desc="EnableCE_OP">----------------------     
; Enable /CE and /OP, lower /CE and /OP
GLOBAL EnableCE_OP
EnableCE_OP:
    MOVLW   CE_OP_ENABLE	; (1) Set Low for /OP enable
    BANKSEL PRTC		; (2) Twiddle the I/O buffer control pins  
    ANDWF   PRTC,W		; (1) Clear Bit in W, AND w/PRTC backing store
    MOVWF   PRTC		; (1) update PRTC backing store
    MOVWF   PORTC		; (1) update actual port
RETURN				; (2) [8]
;</editor-fold> ----------------------------------------------------------------
    

;<editor-fold defaultstate="collapsed" desc="DisableCE_OP">--------------------- 
; Disable /CE and /OP, raise /CE and /OP
GLOBAL DisableCE_OP
DisableCE_OP:
    MOVLW   CE_OP_DISABLE	; (1) Set Hi for /CE and /OP disable
    BANKSEL PRTC		; (2) Twiddle the I/O buffer control pins
    IORWF   PRTC,W		; (1) Set Bit in W, OR with PRTB backing store
    MOVWF   PRTC		; (1) update PRTC backing store
    MOVWF   PORTC		; (1) update actual port
RETURN				; (2) [8]
;</editor-fold> ----------------------------------------------------------------

    
;<editor-fold defaultstate="collapsed" desc="ReadNibble">----------------------- 
; Read nibble from PortC, pass nibble in W as low nibble
GLOBAL ReadNibble
ReadNibble:
    BANKSEL PORTC		; (2) Set bank
    MOVF    PORTC,W		; (1) Read in entire port
    XORLW   0xFF		; (1) Compliment data to make it right
    ANDLW   0x0F		; (1) Mask off high nibble
RETURN				; (2) [6]   
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="WriteNibble">----------------------     
; Write nibble to PortC, pass nibble in W as low nibble
; PRTC is backing store for PORTC so we can keep track of its state
; BSF, BCF Read-Modify-Write operations don't work on PORTs correctly
GLOBAL WriteNibble
    
WriteNibble:
    BANKSEL PRTC		; (2) Same bank as PRTC
    XORLW   0xFF		; (1) Compliment data before sending
    IORLW   0xF0		; (1) Set high nibble to all ones
    ANDWF   PRTC		; (1) mask off lower nibble
    ANDLW   0x0F		; (1) get back original value of W
    IORWF   PRTC,W		; (1) OR in our desired lower nibble
    MOVWF   PRTC		; (1) update backing store
    MOVWF   PORTC		; (1) update actual port
    RETURN			; (2) [10]   
;</editor-fold> ----------------------------------------------------------------
    
    
;</editor-fold> ----------------------------------------------------------------   
    