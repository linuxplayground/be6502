    .include "lcd.inc"
    .include "acia.inc"
    .include "io.inc"
    .include "via_const.inc"
    .include "xmodem.inc"
    .include "wozmon.inc"
    .include "zeropage.inc"
    .include "syscalls.inc"
    .include "ehbasic.inc"
    .include "tty.inc"
    .include "sysram.inc"
    .include "utils.inc"

    .export _monmain
    .export _monloop

; keyboard flags and bits
KBDON        = %00000001
KBDOFF       = %11111110

KBD_R_FLAG   = %00000001
KBD_S_FLAG   = %00000010
KBD_C_FLAG   = %00000100

; keyboard macros
.macro next_code_up
    lda #(KBDON)
    ora VIA_PORTB
    sta VIA_PORTB
.endmacro
.macro next_code_down
    lda #(KBDOFF)
    and VIA_PORTB
    sta VIA_PORTB
.endmacro
.macro readkey
    next_code_up
    lda #1
    jsr _delay_ms
    lda VIA_PORTA
    pha
    next_code_down
    pla
.endmacro

    .code 
_monmain:
main:
    sei
    ldx #$ff
    txs

    jsr _lcd_init
    jsr _acia_init

    lda #<lcd_message
    sta str_ptr
    lda #>lcd_message
    sta str_ptr + 1
    jsr _lcd_print

    ; set port A as input (for keyboard reading)
    lda #$00
    sta VIA_PORTA
    lda #$00
    sta VIA_DDRA

    ; set up user IRQ location.
    lda #<usr_isr_stub
    sta usr_irq
    lda #>usr_isr_stub
    sta usr_irq + 1

    ; set up VIA Interrupts for keyboard
    lda #$82
    sta VIA_IER
    lda #$00
    sta VIA_PCR

    ; set up pin for kbd next code
    lda VIA_DDRB
    ora #KBDON              ; next code out
    sta VIA_DDRB

    ; initialize the keyboard zeropage variables
    stz kbd_r_ptr
    stz kbd_w_ptr
    stz kbd_flags

    cli
    jsr go_help

_monloop:
loop:
    jsr _acia_read_byte
    cmp #'x'
    beq go_xmodem
    cmp #'r'
    beq go_run
    cmp #'m'
    beq go_mon
    cmp #'h'
    beq go_help
    cmp #'b'
    beq go_basic
    jsr _prompt
    jmp loop

go_mon:
    jsr _wozmon
    jsr _prompt
    jmp loop
    
go_xmodem:
    jsr _xmodem
    jmp loop

go_run:
    jsr $1000
    jsr _new_line
    jmp loop

go_help:
    lda #<load_message
    sta str_ptr
    lda #>load_message
    sta str_ptr + 1
    jsr _acia_write_string
    jmp loop

go_basic:
    jsr BASIC_init
    jmp loop

; keyboard handler ISR
kbd_isr:
        pha
        phx

        lda kbd_flags
        and #(KBD_R_FLAG)       ; check if we are releasing a key
        beq @read_key           ; otherwise read the key
        
        lda kbd_flags           ; flip the releasing bit
        eor #(KBD_R_FLAG)
        sta kbd_flags
        readkey                 ; read the value that's being released
        cmp #$12                ; left shift up
        beq @shift_up
        cmp #$59                ; right shift up
        beq @shift_up

        jmp @exit

@shift_up:
        lda kbd_flags
        eor #(KBD_S_FLAG)       ; flip the shift bit
        sta kbd_flags
        jmp @exit

@read_key:
        readkey
        cmp #$f0                ; if releasing a key
        beq @key_release
        cmp #$12                ; left shift
        beq @shift_down
        cmp #$59                ; right shift
        beq @shift_down

        tax
        lda kbd_flags
        and #(KBD_S_FLAG)       ; check if shif it currently down
        bne @shifted_key

        lda keymap_l,x          ; fetch ascii from keymap lowercase
        jmp @push_key
@shifted_key:
        lda keymap_u,x          ; fetch ascii from keymap uppercase
        ; fall through
@push_key:
        ldx kbd_w_ptr           ; use the write pointer to save the ascii
        sta KBD_BUFFER,x        ; char into the buffer
        inc kbd_w_ptr
        jmp @exit

@shift_down:
        lda kbd_flags
        ora #(KBD_S_FLAG)
        sta kbd_flags
        jmp @exit
@key_release:
        lda kbd_flags
        ora #(KBD_R_FLAG)
        sta kbd_flags
@exit:
        plx
        pla
        rts

usr_isr_stub:
        rti

; user defined IRQ vector
irq:
    ; check if keyboard triggered interrupt
;     Table 1-11 Interrupt Flag Register ($0D) IFR
;       7   6      5      4   3   2     1   0  
;       IRQ Timer1 Timer2 CB1 CB2 Shift CA1 CA2
    jsr kbd_isr
@user_irq:
    ; else run user defined irq
    jmp (usr_irq)           ; user programs can define an IRQ jmp here.

    .segment "VECTORS"

    .word $0000
    .word main
    .word irq

    .RODATA
lcd_message:  .asciiz "Connect to tty                          On 8N1 19200"
load_message: .byte "Press 'x' to start xmodem receive ...", $0a, $0d
              .byte "Press 'r' to run your program ...", $0a, $0d
              .byte "Press 'b' to run basic ...", $0a, $0d
              .byte "Press 'm' to start Wozmon ...", $0a, $0d, $00
keymap_l:
    .byte "?????",$81,$82,$8c,"?",$8a,"??? `?" ; 00-0F
    .byte "?????q1???zsaw2?" ; 10-1F
    .byte "?cxde43?? vftr5?" ; 20-2F
    .byte "?nbhgy6???mju78?" ; 30-3F
    .byte "?,kio09??./l;p-?" ; 40-4F
    .byte "??'?[=????",$0a,"]?\??" ; 50-5F
    .byte "??????",$08,"??1?47???" ; 60-6F
    .byte "0.2568",$1b,"?",$8b,"+3-*9??" ; 70-7F
    .byte "????????????????" ; 80-8F
    .byte "????????????????" ; 90-9F
    .byte "????????????????" ; A0-AF
    .byte "????????????????" ; B0-BF
    .byte "????????????????" ; C0-CF
    .byte "????????????????" ; D0-DF
    .byte "????????????????" ; E0-EF
    .byte "????????????????" ; F0-FF
keymap_u:
    .byte "????????????? ~?" ; 00-0F
    .byte "?????Q!???ZSAW@?" ; 10-1F
    .byte "?CXDE#$?? VFTR%?" ; 20-2F
    .byte "?NBHGY^???MJU&*?" ; 30-3F
    .byte "?<KIO)(??>?L:P_?" ; 40-4F
    .byte "??",$22,"?{+?????}?|??" ; 50-5F
    .byte "?????????1?47???" ; 60-6F
    .byte "0.2568",$80,"??+3-*9??" ; 70-7F
    .byte "????????????????" ; 80-8F
    .byte "????????????????" ; 90-9F
    .byte "????????????????" ; A0-AF
    .byte "????????????????" ; B0-BF
    .byte "????????????????" ; C0-CF
    .byte "????????????????" ; D0-DF
    .byte "????????????????" ; E0-EF
    .byte "????????????????" ; F0-FF

