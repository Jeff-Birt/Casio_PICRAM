;-------------------------------------------------------------------------------
; Write back nibble 0228, change from 5 to 6
; Preset the starting Effective Address (EA) to $0226
; SetReadAddress 0x05,0x00,0x00,0x00	;CNT,T1,B1,B0  B1=DVA_AD2, B0=AD1_AD0
;    BANKSEL EAL			    ;
;    MOVLW   0x26		    ; B0=AD1_AD0=0x26
;    MOVWF   EAL			    ; 
;    MOVLW   0x02		    ; B1=DVA_AD2=0x02
;    MOVWF   EAH			    ; Effective nibble address $0226
    
;    BANKSEL EAL			    ;
;    MOVLW   0x00		    ; B0=AD1_AD0=0x26
;    MOVWF   EAL			    ; 
;    MOVLW   0x04		    ; B1=DVA_AD2=0x02
;    MOVWF   EAH			    ; Effective nibble address $0226
;    
;    CALL    Port_C_Output	    ; PORTC Set all Pins to outputs
;    SetEffAdd 0x05,0x04,EAH,EAL	    ; Set of Write command  in CMD buffer
;    CALL    TxCmd		    ; (##) Xmt cmd buffer
;    
;    BANKSEL COUNT		    ; (2) 4 nibbles to write, starting @$0226
;    MOVLW   0x20		    ; (1) Bit7=0 start on even nibble
;    MOVWF   COUNT		    ; (1) save to COUNT
;    
;;Now we will change pointer to the '5' in '10 A=5', and chage to '10 A=8'
;    MOVLW   CRAM_BH+0x01	    ; (1) high byte start of CBUF
;    MOVWF   FSR0H		    ; (1) move to File Select Register 1 High
;    MOVLW   0x14	    	    ; (1) CBUF start low byte (# bytes to rx)
;    MOVWF   FSR0L		    ; (1) move to File Select Register 1 Low
;    MOVLW   0x81		    ; (1) Value in Nl,Nh order
;    MOVWI   FSR0++		    ; (1) Write to buffer

;; Now set buffer pointer to the starting byte address of what we want to write
;    MOVLW   CRAM_BH+0x01	    ; (1) high byte start of CBUF
;    MOVWF   FSR0H		    ; (1) move to File Select Register 1 High
;    MOVLW   0x13	    	    ; (1) Byte $0113 is nibbles $0226, $0227
;    MOVWF   FSR0L		    ; (1) move to File Select Register 1 Low
    
;    ; Now set buffer pointer to the starting byte address of what we want to write
;    MOVLW   CRAM_BH+0x01		    ; (1) high byte start of CBUF
;    MOVWF   FSR0H		    ; (1) move to File Select Register 1 High
;    MOVLW   0x10	    	    ; (1) Byte $0113 is nibbles $0226, $0227
;    MOVWF   FSR0L		    ; (1) move to File Select Register 1 Low
;    
;    CALL    Port_C_Output	    ; (##) PORTC bits 0-3 input, 4-7 output
;    CALL    TxData		    ; (##) read in 16 nibbles
;    DoDelay 0x01,0x01		    ; delay = outer * inner * 25us 


