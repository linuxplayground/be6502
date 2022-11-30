        .include "zeropage.inc"
        .include "acia.inc"
        .include "via_const.inc"
        .include "utils.inc"
        .include "wozmon.inc"
        .include "tty.inc"
        .include "sysram.inc"

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

main:
        sei
        lda kbd_r_ptr           ; get current read pointer into keyboard buffer
        cmp kbd_w_ptr           ; compare with write pointer into keyboard buffer
        cli
        bne @keyboard_key_pressed
        jmp main
@keyboard_key_pressed:
        ldx kbd_r_ptr
        lda KBD_BUFFER,x        ; load the char stored in the buffer at the read pointer index
        cmp #$0a
        beq enter_pressed
        cmp #$08
        beq backspace_pressed
        cmp #$81
        beq f1_pressed
        cmp #$82
        beq f2_pressed
        cmp #$8a
        beq f10_pressed         ; save screen
        cmp #$8b
        beq f11_pressed         ; restore screen
        cmp #$8c
        beq f12_pressed
        cmp #$80
        beq shift_escape_pressed
        jsr _acia_write_byte    ; output it
next_loop:
        inc kbd_r_ptr
        jmp main

enter_pressed:
        jsr _new_line
        jmp next_loop

backspace_pressed:
        jsr _acia_write_byte    ; move back one ($08)
        lda #' '                ; write a space ($20)
        jsr _acia_write_byte
        lda #$08                ; move back one ($08)
        jsr _acia_write_byte
        jmp next_loop

f1_pressed:                     ; push out red escape code
        lda #<red
        sta str_ptr
        lda #>red
        sta str_ptr + 1
        jsr _acia_write_string
        jmp next_loop           
f2_pressed:                     ; push out green escape code
        lda #<green
        sta str_ptr
        lda #>green
        sta str_ptr + 1
        jsr _acia_write_string
        jmp next_loop
f10_pressed:
        ; lda #<save
        ; sta str_ptr
        ; lda #>save
        ; sta str_ptr + 1
        ; jsr _acia_write_string
        jmp next_loop
f11_pressed:
        ; lda #<restore
        ; sta str_ptr
        ; lda #>restore
        ; sta str_ptr + 1
        ; jsr _acia_write_string
        jmp next_loop
f12_pressed:                    ; push out reset escape code
        lda #<reset
        sta str_ptr
        lda #>reset
        sta str_ptr + 1
        jsr _acia_write_string
        jmp next_loop           
shift_escape_pressed:
        lda #<cls
        sta str_ptr
        lda #>cls
        sta str_ptr + 1
        jsr _acia_write_string
        jmp next_loop
        
        .RODATA
red:
  .byte $1b,"[1;31m", $00
green:
  .byte $1b,"[1;32m", $00

reset:
  .byte $1b,"[1;0m", $00
cls:
  .byte $1b,"[2J", $00
