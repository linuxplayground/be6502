        .include "utils.inc"
        .include "via_const.inc"
        .include "acia.inc"
        .include "wozmon.inc"

        .import __VIA_START__
VIA_PORTB = __VIA_START__ + VIA_REGISTER_PORTB
VIA_PORTA = __VIA_START__ + VIA_REGISTER_PORTA
VIA_DDRB  = __VIA_START__ + VIA_REGISTER_DDRB
VIA_DDRA  = __VIA_START__ + VIA_REGISTER_DDRA

RESET = %00000100
LATCH = %00000111
WRITE = %00000110


        .code
        
        lda #$ff                        ; porta used to send data to the ay-3-8910
        sta VIA_DDRA
        lda #(RESET|LATCH|WRITE)        ; portb used to set selct registers and reset the ay-3-8910
        sta VIA_DDRB

init:
        jsr reset

        ; set up channel A (tone) at full volume, channel B (noise)
        lda #$3e
        ldx #$07
        jsr write_register
        lda #$1f
        ldx #$08                ; tone is full volume
        jsr write_register

get_key:
        clc
        jsr _acia_read_byte_nw
        bcc get_key
        cmp #$1b                ; escape
        beq @exit

        cmp #'-'
        beq @key_a_s
        cmp #'='
        beq @key_b
        cmp #$08
        beq @key_del
        cmp #'h'
        beq @key_h
        ; jsr _prbyte
        clc                     ; check if A was ascii 0-9
        adc #$c6                ; http://retro.hansotten.nl/6502-sbc/lee-davison-web-site/some-veryshort-code-bits/
        adc #$0a                ; 
        bcc get_key
        ;here A is a number from 0 - 9
        tay
        jmp play
@key_a_s:
        ldy #10
        jmp play
@key_b:
        ldy #11
        jmp play
@key_del:
        ldy #12
        jmp play
@key_h:
        jmp play_happy
@exit:
        jmp exit

play:

        jsr decay

        lda no6ct,y
        ldx #$01                ; course tune = reg 1
        jsr write_register

        lda no6ft,y
        ldx #$00
        jsr write_register      ; fine tune = reg 0

        jsr print_note

        jmp get_key

play_happy:
        ldx #0
@play_happy_1:
        lda happy,x

        cmp #'p'
        beq @play_happy_2
        cmp #'z'
        beq @play_happy_3

        tay
        phx
        lda no6ct,y
        ldx #$01                ; course tune = reg 1
        jsr write_register

        lda no6ft,y
        ldx #$00
        jsr write_register      ; fine tune = reg 0

        jsr decay
        jsr print_note

        lda #$ff
        jsr _delay_ms

        plx
        inx
        jmp @play_happy_1
@play_happy_2:
        phx
        lda #250
        jsr _delay_ms
        lda #250
        jsr _delay_ms           ; half a second delay
        plx
        inx
        jmp @play_happy_1
@play_happy_3:
        jmp get_key
exit:
        jsr reset
        rts

reset:
        lda #$00
        sta VIA_PORTB
        lda #10
        jsr _delay_ms
        lda #RESET
        sta VIA_PORTB
; a contains value to send
; y contains register to send to.
write_register:
        pha                             ; preserve registers

        lda #(LATCH)
        sta VIA_PORTB
        txa
        sta VIA_PORTA                   ; write register

        lda #(RESET)
        sta VIA_PORTB

        lda #(WRITE)
        sta VIA_PORTB
        pla
        sta VIA_PORTA                   ; write data

        lda #(RESET)
        sta VIA_PORTB
        rts

decay:
        phx
        pha
        lda #$ff
        ldx #$0B
        jsr write_register        ; audio register oct13 - Envelop duration fine
        lda #$20
        ldx #$0C
        jsr write_register        ; audio register oct14 - Envelope duration course
        lda #$00
        ldx #$0D
        jsr write_register        ; adio register oct15 - Envelop shape (fade out)
        pla
        plx
        rts

; prints note by reference to no_string_idx and no_strings
; note to print is in Y
print_note:
        lda no_string_idx, y    ; a = index into no_strings
        tay
        lda no_strings, y       ; a = length of string
        tax
@pn1:
        iny                     ; move y index along
        lda no_strings,y
        jsr _acia_write_byte
        dex
        bne @pn1

        lda #$0a                ; perform new line.
        jsr _acia_write_byte
        lda #$0d
        jsr _acia_write_byte

        rts


; notes octave 6 (Fine tune and Course Tune)
             ; 0 . 1 . 2 . 3 . 4 . 5 . 6 . 7 . 8 . 9 . -   +  DEL
no6ft:       ; C . C#  D   D# .E . F . F#  G . G# .A   A#  B .+C
        .byte $23,$3B,$38,$35,$32,$2F,$2C,$2A,$27,$25,$21,$1f,$1d
no6ct:
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; index into note strings
no_string_idx:
        .byte $00,$02,$04,$07,$09,$0c,$0e,$10,$13,$15,$18,$1b,$1d
no_strings:
        .byte 1,"A", 1,"C", 2,"C#", 1,"D", 2,"D#", 1,"E", 1,"F", 2,"F#", 1,"G", 2,"G#", 2,"A#",1,"B",2,"C+"
         ;       0 .    1 .     2 .    3 .     4 .    5 .    6 .     7 .    8 .     9 .     -     =
happy:
        .byte 1,1,3,1,6,5,'p'
        .byte 1,1,3,1,8,6,'p'
        .byte 1,1,12,0,8,6,5,'p'
        .byte 10,10,0,6,8,6,'z'
