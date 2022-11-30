; set up user irq vector
        .include "zeropage.inc"
        .include "via_const.inc"
        .include "utils.inc"

        .import __VIA_START__
VIA_PORTB = __VIA_START__ + VIA_REGISTER_PORTB
VIA_PORTA = __VIA_START__ + VIA_REGISTER_PORTA
VIA_DDRB  = __VIA_START__ + VIA_REGISTER_DDRB
VIA_DDRA  = __VIA_START__ + VIA_REGISTER_DDRA
VIA_T1CL  = __VIA_START__ + VIA_REGISTER_T1CL
VIA_T1CH  = __VIA_START__ + VIA_REGISTER_T1CH
VIA_T1LL  = __VIA_START__ + VIA_REGISTER_T1LL
VIA_T1LH  = __VIA_START__ + VIA_REGISTER_T1LH
VIA_T2CL  = __VIA_START__ + VIA_REGISTER_T2CL
VIA_T2CH  = __VIA_START__ + VIA_REGISTER_T2CH
VIA_SR    = __VIA_START__ + VIA_REGISTER_SR
VIA_ACR   = __VIA_START__ + VIA_REGISTER_ACR
VIA_PCR   = __VIA_START__ + VIA_REGISTER_PCR
VIA_IFR   = __VIA_START__ + VIA_REGISTER_IFR
VIA_IER   = __VIA_START__ + VIA_REGISTER_IER
VIA_PANH  = __VIA_START__ + VIA_REGISTER_PANH

        .import __ACIA_START__
ACIA_DATA    = __ACIA_START__ + $00
ACIA_STATUS  = __ACIA_START__ + $01

        .import _acia_write_byte        

LEDON        = %00000001
LEDOFF       = %11111110

.macro ledon
        lda VIA_PORTB
        ora #LEDON
        sta VIA_PORTB
.endmacro

.macro ledoff
        lda VIA_PORTB
        and #LEDOFF
        sta VIA_PORTB
.endmacro

.macro blink
        ledon
        lda #1
        jsr _delay_sec
        ledoff
.endmacro

        .code
        sei
        ; set port A as input
        lda #$00
        sta VIA_DDRA

        ; set up user IRQ location.
        lda #<test_irq
        sta usr_irq
        lda #>test_irq
        sta usr_irq + 1

        lda #(VIA_IER_SET_FLAGS|VIA_IER_CA1_FLAG)
        sta VIA_IER
        lda #(VIA_PCR_CA1_INTERRUPT_POSITIVE)
        sta VIA_PCR

        lda VIA_DDRB
        eor #LEDON
        sta VIA_DDRB

        cli

main:
        jmp main

; PRBYTE:      
;         PHA             ;Save A for LSD.
;         LSR
;         LSR
;         LSR             ;MSD to LSD position.
;         LSR
;         JSR PRHEX       ;Output hex digit.
;         PLA             ;Restore A.
; PRHEX:       
;         AND #$0F        ;Mask LSD for hex print.
;         ORA #$B0        ;Add "0".
;         CMP #$BA        ;Digit?
;         BCC ECHO        ;Yes, output it.
;         ADC #$06        ;Add offset for letter.
; ECHO:        
;         PHA             ;*Save A
;         AND #$7F        ;*Change to "standard ASCII"
;         STA ACIA_DATA   ;*Send it.
; @WAIT:       
;         LDA ACIA_STATUS ;*Load status register for ACIA
;         AND #$10        ;*Mask bit 4.
;         BEQ @WAIT       ;*ACIA not done yet, wait.
;         PLA             ;*Restore A
;         RTS             ;*Done, over and out...


test_irq:
        pha
        phx
        phy
        blink
        bit VIA_PORTA
@exit:
        ply
        plx
        pla
        rti
