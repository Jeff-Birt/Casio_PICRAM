; File - ConfigClkPmd.s
; Macros for configuration and control of Clock, PMD, Effective Address  
    
PROCESSOR 16F18446
#include <xc.inc>
    
;<editor-fold defaultstate="collapsed" desc="Configuration">-------------------- 
; Configuration for PIC16F18446
; CONFIG1
  CONFIG  FEXTOSC = OFF         ; External Oscillator mode selection bits (Oscillator not enabled)
  CONFIG  RSTOSC = HFINT1       ; Power-up default value for COSC bits (HFINTOSC (32MHz))
  CONFIG  CLKOUTEN = OFF        ; Clock Out Enable bit (CLKOUT function is disabled; i/o or oscillator function on OSC2)
  CONFIG  CSWEN = ON            ; Clock Switch Enable bit (Writing to NOSC and NDIV is allowed)
  CONFIG  FCMEN = ON            ; Fail-Safe Clock Monitor Enable bit (FSCM timer enabled)

; CONFIG2
  CONFIG  MCLRE = ON            ; Master Clear Enable bit (MCLR pin is Master Clear function)
  CONFIG  PWRTS = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  LPBOREN = OFF         ; Low-Power BOR enable bit (ULPBOR disabled)
  CONFIG  BOREN = ON            ; Brown-out reset enable bits (Brown-out Reset Enabled, SBOREN bit is ignored)
  CONFIG  BORV = LO             ; Brown-out Reset Voltage Selection (Brown-out Reset Voltage (VBOR) set to 2.45V)
  CONFIG  ZCD = OFF             ; Zero-cross detect disable (Zero-cross detect circuit is disabled at POR.)
  CONFIG  PPS1WAY = ON          ; Peripheral Pin Select one-way control (The PPSLOCK bit can be cleared and set only once in software)
  CONFIG  STVREN = ON           ; Stack Overflow/Underflow Reset Enable bit (Stack Overflow or Underflow will cause a reset)

; CONFIG3
  CONFIG  WDTCPS = WDTCPS_31    ; WDT Period Select bits (Divider ratio 1:65536; software control of WDTPS)
  CONFIG  WDTE = OFF            ; WDT operating mode (WDT Disabled, SWDTEN is ignored)
  CONFIG  WDTCWS = WDTCWS_7     ; WDT Window Select bits (window always open (100%); software control; keyed access not required)
  CONFIG  WDTCCS = SC           ; WDT input clock selector (Software Control)

; CONFIG4
  CONFIG  BBSIZE = BB512        ; Boot Block Size Selection bits (512 words boot block size)
  CONFIG  BBEN = OFF            ; Boot Block Enable bit (Boot Block disabled)
  CONFIG  SAFEN = OFF           ; SAF Enable bit (SAF disabled)
  CONFIG  WRTAPP = OFF          ; Application Block Write Protection bit (Application Block not write protected)
  CONFIG  WRTB = OFF            ; Boot Block Write Protection bit (Boot Block not write protected)
  CONFIG  WRTC = OFF            ; Configuration Register Write Protection bit (Configuration Register not write protected)
  CONFIG  WRTD = OFF            ; Data EEPROM write protection bit (Data EEPROM NOT write protected)
  CONFIG  WRTSAF = OFF          ; Storage Area Flash Write Protection bit (SAF not write protected)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (Low Voltage programming enabled. MCLR/Vpp pin function is MCLR.)

; CONFIG5
  CONFIG  CP = OFF              ; UserNVM Program memory code protection bit (UserNVM code protection disabled)
;</editor-fold> ----------------------------------------------------------------
  
  
;<editor-fold defaultstate="collapsed" desc="ConfigClock">----------------------    
; Configure Clock
; All OSCXXXX are one same page so only 1 BANKSEL is needed
ConfigClock MACRO
    BANKSEL OSCCON1		;
    MOVLW   0x60		; (088D) NOSC HFINTOSC; NDIV 1;
    MOVWF   OSCCON1		;
         
    MOVLW   0x00		; (088F) CSWHOLD may proceed; SOSCPWR Low power 
    MOVWF   OSCCON3		;
 
    MOVLW   0x00		; MFOEN disabled; ADOEN disabled; SOSCEN disabled 
    MOVWF   OSCEN		; (0891) EXTOEN disabled; HFOEN disabled

    MOVLW   0x06		; HFFRQ 32_MHz
    MOVWF   OSCFRQ		;(0893) 

    MOVLW   0x00		; HFTUN 0
    MOVWF   OSCTUNE		; (0892)
ENDM
;</editor-fold> ----------------------------------------------------------------
    
    
;<editor-fold defaultstate="collapsed" desc="ConfigPMD">------------------------     
; Configure peripheral power
;
; For now we are just turning on all peripherals later we will be selective
; all PMDx on same bank so we just need one BANKSEL
ConfigPMD MACRO
    BANKSEL PMD0	    ; (0796) CLKRMD CLKR enabled; SYSCMD SYSCLK enabled; 
    MOVLW   0x00	    ; FVRMD FVR enabled; IOCMD IOC enabled; 
    MOVWF   PMD0	    ; NVMMD NVM enabled;
 
    MOVLW   0x00	    ; TMR4MD TMR4 enabled; TMR5MD TMR5 enabled;
    MOVWF   PMD1	    ; (0797) TMR2MD TMR2 enabled; TMR3MD TMR3 enabled; TMR6MD TMR6 enabled; 
    
    MOVLW   0x00	    ; (0798) NCO1MD NCO1 enabled;
    MOVWF   PMD2	    ;
    
    MOVLW   0x00	    ; ADCMD ADC enabled; CMP2MD CMP2 enabled;
    MOVWF   PMD3	    ; (0799) DAC1MD DAC1 enabled; 

    MOVLW   0x00	    ; CCP4MD CCP4 enabled; CCP3MD CCP3 enabled;
    MOVWF   PMD4	    ; (079A) PWM6MD PWM6 enabled; PWM7MD PWM7 enabled; 

    MOVLW   0x00	    ; (079B) CWG2MD CWG2 enabled; CWG1MD CWG1 enabled; 
    MOVWF   PMD5	    ;

    MOVLW   0x00	    ; MSSP2MD MSSP2 enabled;
    MOVWF   PMD6	    ; (079C)
    
    MOVLW   0x00	    ; DSM1MD DSM enabled; SMT1MD SMT1 enabled; 
    MOVWF   PMD7	    ; (079D) CLC1MD CLC1 enabled; CLC2MD CLC2 enabled; 
ENDM
;</editor-fold> ----------------------------------------------------------------


