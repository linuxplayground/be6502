        .include "utils.inc"
        .include "zeropage.inc" ; free locations start at $d0
        .include "acia.inc"
        .include "tty.inc"
        .include "wozmon.inc"

        .import __TMS_START__
VDP_VRAM                = __TMS_START__ + $00
VDP_REG                 = __TMS_START__ + $01

VDP_TMP                 = $d0   ; 2 bytes

sprite_pattern_table    = 0
pattern_table           = $800
sprite_attribute_table  = $1000
name_table              = $1400
color_table             = $2000
color_table_size        = 32

; character constants
snake_head_up           = $80 ; 80 - snake head up   
snake_body_vert         = $81 ; 81 - snake body vert  
snake_head_down         = $82 ; 82 - snake head down  
snake_head_right        = $83 ; 83 - snake head right
snake_body_horiz        = $84 ; 84 - snake body horiz
snake_head_left         = $85 ; 85 - snake head left 
snake_bl_corner         = $86 ; 86 - bl corner       
snake_tl_corner         = $87 ; 87 - tl corner       
snake_tr_corner         = $88 ; 88 - tr corner        
snake_br_corner         = $89 ; 89 - br corner        

; movement constants
mov_up          = $01
mov_right       = $02
mov_down        = $04
mov_left        = $08

; snake variables
direction       = $d2 ; 1 byte
snake_x         = $d3 ; 1 byte
snake_y         = $d4 ; 1 byte
snake_head      = $d5 ; 1 byte this contains the current head based on direction.
snake_length    = $d6 ; 2 byte
snake_body      = $5000 ; body segments are stored as words representing vram addresses.

main:
        jsr clear_ram
        lda #'1'
        jsr _acia_write_byte

        jsr init_g1
        lda #'2'
        jsr _acia_write_byte

        jsr init_patterns
        lda #'3'
        jsr _acia_write_byte

        jsr init_colors
        lda #'4'
        jsr _acia_write_byte
        
        jsr clear_screen
        lda #'5'
        jsr _acia_write_byte

        ; starting settings
        lda #12
        sta snake_y
        lda #16
        sta snake_x
        lda #mov_right
        sta direction
        lda #snake_head_right
        sta snake_head

        jsr game_loop

        rts

game_loop:
        jsr read_keys
        jsr update_snake
        bcs end_game
        jsr draw_snake

        ldy #$40
        jsr delay
        jmp game_loop
end_game:
        lda #<str_game_over
        sta str_ptr
        lda #>str_game_over
        sta str_ptr + 1
        jsr _acia_write_string
        rts

; y contains count of loops
delay:
delay_1:
        ldx #$00
delay_2:
        dex
        bne delay_2
        dey
        bne delay_1
        rts

read_keys:
        jsr _acia_read_byte_nw
        bcc @return
        cmp #'w'
        beq @up
        cmp #'a'
        beq @left
        cmp #'d'
        beq @right
        cmp #'s'
        beq @down
        jmp @return
@up:
        lda #mov_down
        bit direction
        bne @return
        lda #mov_up
        sta direction
        lda #snake_head_up
        sta snake_head
        jmp @return
@down:
        lda #mov_up
        bit direction
        bne @return
        lda #mov_down
        sta direction
        lda #snake_head_down
        sta snake_head
        jmp @return

@left:
        lda #mov_right
        bit direction
        bne @return
        lda #mov_left
        sta direction
        lda #snake_head_left
        sta snake_head
        jmp @return

@right:
        lda #mov_left
        bit direction
        bne @return
        lda #mov_right
        sta direction
        lda #snake_head_right
        sta snake_head
        jmp @return

@return:
        rts


; update snake
update_snake:
        lda direction
        cmp #mov_up
        beq @move_up
        cmp #mov_down
        beq @move_down
        cmp #mov_left
        beq @move_left
        cmp #mov_right
        beq @move_right
        jmp @return
@move_up:
        lda snake_y
        dec
        bmi @collide
        sta snake_y
        jmp @return
@move_down:
        lda snake_y
        inc
        cmp #24
        beq @collide
        sta snake_y
        jmp @return
@move_left:
        lda snake_x
        dec
        bmi @collide
        sta snake_x
        jmp @return
@move_right:
        lda snake_x
        inc
        cmp #32
        beq @collide
        sta snake_x
        ; fall through
@return:
        clc
        rts
@collide:
        sec
        rts

; draw snake
draw_snake:
        ldx snake_x
        ldy snake_y
        jsr xy_to_vram
        lda snake_head
        jsr cout
        rts

; cout - print A at vram pointed to by VDP_TMP
cout:
        phx
        pha
        lda VDP_TMP
        ldx VDP_TMP + 1
        jsr vdp_set_ram_address
        pla
        sta VDP_VRAM
        plx
        rts

; VRAM address will be in VDP_TMP when done.
xy_to_vram:
        lda #<name_table
        sta VDP_TMP
        lda #>name_table
        sta VDP_TMP + 1

@mul_32:
        lda #0
@mul_32_lp:
        cpy #$00
        beq @mul_32_add_x
        clc
        adc #32
        sta VDP_TMP
        bcc @mul_32_cont
        inc VDP_TMP + 1
@mul_32_cont:
        dey
        bne @mul_32_lp
@mul_32_add_x:
        clc
        txa
        adc VDP_TMP
        sta VDP_TMP
        bcc @done
        inc VDP_TMP + 1
@done:
        rts
        

clear_screen:
        lda #<name_table
        ldx #>name_table
        jsr vdp_set_ram_address
        lda #$00
        jsr cs_pg
        jsr cs_pg
        ; fall through
cs_pg:
        ldx #$00
cs_pg_1:
        sta VDP_VRAM
        dex
        bne cs_pg_1
        rts

; clear ram
clear_ram:
        lda #$00
        ldx #$00
        jsr vdp_set_ram_address
        lda #$FF
        sta VDP_TMP
        lda #$3F
        sta VDP_TMP + 1
@clr_1:
        lda #$00
        sta VDP_VRAM
        dec VDP_TMP
        lda VDP_TMP
        bne @clr_1
        dec VDP_TMP + 1
        lda VDP_TMP + 1
        bne @clr_1
        rts

init_patterns:
        ldx #>pattern_table
        lda #<pattern_table
        jsr vdp_set_ram_address
        lda #<patterns
        sta VDP_TMP
        lda #>patterns
        sta VDP_TMP + 1
@ip_1:
        lda (VDP_TMP)
        sta VDP_VRAM

        lda VDP_TMP
        clc
        adc #1
        sta VDP_TMP
        lda #0
        adc VDP_TMP + 1
        sta VDP_TMP + 1
        cmp #>end_patterns
        bne @ip_1
        lda VDP_TMP
        cmp #<end_patterns
        bne @ip_1        
        rts

init_colors:
        ldx #>color_table
        lda #<color_table
        jsr vdp_set_ram_address
        lda #<colors
        sta VDP_TMP
        lda #>colors
        sta VDP_TMP + 1
@ic_1:
        lda (VDP_TMP)
        sta VDP_VRAM

        lda VDP_TMP
        clc
        adc #1
        sta VDP_TMP
        lda #0
        adc VDP_TMP + 1
        sta VDP_TMP + 1
        cmp #>end_colors
        bne @ic_1
        lda VDP_TMP
        cmp #<end_colors
        bne @ic_1        
        rts

init_g1:
        ldx #0
@init_g1_1:
        lda init_g1_data, x
        jsr vdp_set_register
        inx
        cpx #7
        bne @init_g1_1
        rts

; x = register
; a = value
vdp_set_register:
        sta VDP_REG
        txa
        ora #$80
        sta VDP_REG
        rts

; x = ram high
; a = ram low
vdp_set_ram_address:
        sta VDP_REG
        txa
        ora #$40
        sta VDP_REG
        rts

init_g1_data:
reg_0: .byte $00       ; r0
reg_1: .byte $C0       ; r1 16kb ram + M1
reg_2: .byte $05       ; r2 name table at 0x1400
reg_3: .byte $80       ; r3 color start 0x2000
reg_4: .byte $01       ; r4 pattern generator start at 0x800
reg_5: .byte $20       ; r5 Sprite attriutes start at 0x1000
reg_6: .byte $00       ; r6 Sprite pattern table at 0x0000
reg_7: .byte $e4       ; r7 Set background and forground color

patterns:
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 00 - 
        .byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; 01 -  BOX
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 02 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 03 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 04 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 05 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 06 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 07 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 08 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 09 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 0A - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 0B - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 0C - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 0D - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 0E - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 0F - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 10 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 11 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 12 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 13 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 14 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 15 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 16 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 17 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 18 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 19 - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 1A - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 1B - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 1C - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 1D - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 1E - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 1F - 
        ; </nonsense>
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 20 - ' '
        .byte $20,$20,$20,$00,$20,$20,$00,$00 ; 21 - !
        .byte $50,$50,$50,$00,$00,$00,$00,$00 ; 22 - "
        .byte $50,$50,$F8,$50,$F8,$50,$50,$00 ; 23 - #
        .byte $20,$78,$A0,$70,$28,$F0,$20,$00 ; 24 - $
        .byte $C0,$C8,$10,$20,$40,$98,$18,$00 ; 25 - %
        .byte $40,$A0,$A0,$40,$A8,$90,$68,$00 ; 26 - &
        .byte $20,$20,$40,$00,$00,$00,$00,$00 ; 27 - '
        .byte $20,$40,$80,$80,$80,$40,$20,$00 ; 28 - (
        .byte $20,$10,$08,$08,$08,$10,$20,$00 ; 29 - )
        .byte $20,$A8,$70,$20,$70,$A8,$20,$00 ; 2A - *
        .byte $00,$20,$20,$F8,$20,$20,$00,$00 ; 2B - +
        .byte $00,$00,$00,$00,$20,$20,$40,$00 ; 2C - ,
        .byte $00,$00,$00,$F8,$00,$00,$00,$00 ; 2D - -
        .byte $00,$00,$00,$00,$20,$20,$00,$00 ; 2E - .
        .byte $00,$08,$10,$20,$40,$80,$00,$00 ; 2F - /
        .byte $70,$88,$98,$A8,$C8,$88,$70,$00 ; 30 - 0
        .byte $20,$60,$20,$20,$20,$20,$70,$00 ; 31 - 1
        .byte $70,$88,$08,$30,$40,$80,$F8,$00 ; 32 - 2
        .byte $F8,$08,$10,$30,$08,$88,$70,$00 ; 33 - 3
        .byte $10,$30,$50,$90,$F8,$10,$10,$00 ; 34 - 4
        .byte $F8,$80,$F0,$08,$08,$88,$70,$00 ; 35 - 5
        .byte $38,$40,$80,$F0,$88,$88,$70,$00 ; 36 - 6
        .byte $F8,$08,$10,$20,$40,$40,$40,$00 ; 37 - 7
        .byte $70,$88,$88,$70,$88,$88,$70,$00 ; 38 - 8
        .byte $70,$88,$88,$78,$08,$10,$E0,$00 ; 39 - 9
        .byte $00,$00,$20,$00,$20,$00,$00,$00 ; 3A - :
        .byte $00,$00,$20,$00,$20,$20,$40,$00 ; 3B - ;
        .byte $10,$20,$40,$80,$40,$20,$10,$00 ; 3C - <
        .byte $00,$00,$F8,$00,$F8,$00,$00,$00 ; 3D - =
        .byte $40,$20,$10,$08,$10,$20,$40,$00 ; 3E - >
        .byte $70,$88,$10,$20,$20,$00,$20,$00 ; 3F - ?
        .byte $70,$88,$A8,$B8,$B0,$80,$78,$00 ; 40 - @
        .byte $20,$50,$88,$88,$F8,$88,$88,$00 ; 41 - A
        .byte $F0,$88,$88,$F0,$88,$88,$F0,$00 ; 42 - B
        .byte $70,$88,$80,$80,$80,$88,$70,$00 ; 43 - C
        .byte $F0,$88,$88,$88,$88,$88,$F0,$00 ; 44 - D
        .byte $F8,$80,$80,$F0,$80,$80,$F8,$00 ; 45 - E
        .byte $F8,$80,$80,$F0,$80,$80,$80,$00 ; 46 - F
        .byte $78,$80,$80,$80,$98,$88,$78,$00 ; 47 - G
        .byte $88,$88,$88,$F8,$88,$88,$88,$00 ; 48 - H
        .byte $70,$20,$20,$20,$20,$20,$70,$00 ; 49 - I
        .byte $08,$08,$08,$08,$08,$88,$70,$00 ; 4A - J
        .byte $88,$90,$A0,$C0,$A0,$90,$88,$00 ; 4B - K
        .byte $80,$80,$80,$80,$80,$80,$F8,$00 ; 4C - L
        .byte $88,$D8,$A8,$A8,$88,$88,$88,$00 ; 4D - M
        .byte $88,$88,$C8,$A8,$98,$88,$88,$00 ; 4E - N
        .byte $70,$88,$88,$88,$88,$88,$70,$00 ; 4F - O
        .byte $F0,$88,$88,$F0,$80,$80,$80,$00 ; 50 - P
        .byte $70,$88,$88,$88,$A8,$90,$68,$00 ; 51 - Q
        .byte $F0,$88,$88,$F0,$A0,$90,$88,$00 ; 52 - R
        .byte $70,$88,$80,$70,$08,$88,$70,$00 ; 53 - S
        .byte $F8,$20,$20,$20,$20,$20,$20,$00 ; 54 - T
        .byte $88,$88,$88,$88,$88,$88,$70,$00 ; 55 - U
        .byte $88,$88,$88,$88,$50,$50,$20,$00 ; 56 - V
        .byte $88,$88,$88,$A8,$A8,$D8,$88,$00 ; 57 - W
        .byte $88,$88,$50,$20,$50,$88,$88,$00 ; 58 - X
        .byte $88,$88,$50,$20,$20,$20,$20,$00 ; 59 - Y
        .byte $F8,$08,$10,$20,$40,$80,$F8,$00 ; 5A - Z
        .byte $F8,$C0,$C0,$C0,$C0,$C0,$F8,$00 ; 5B - [
        .byte $00,$80,$40,$20,$10,$08,$00,$00 ; 5C - \
        .byte $F8,$18,$18,$18,$18,$18,$F8,$00 ; 5D - ]
        .byte $00,$00,$20,$50,$88,$00,$00,$00 ; 5E - ^
        .byte $00,$00,$00,$00,$00,$00,$F8,$00 ; 5F - _
        .byte $40,$20,$10,$00,$00,$00,$00,$00 ; 60 - `
        .byte $00,$00,$70,$88,$88,$98,$68,$00 ; 61 - a
        .byte $80,$80,$F0,$88,$88,$88,$F0,$00 ; 62 - b
        .byte $00,$00,$78,$80,$80,$80,$78,$00 ; 63 - c
        .byte $08,$08,$78,$88,$88,$88,$78,$00 ; 64 - d
        .byte $00,$00,$70,$88,$F8,$80,$78,$00 ; 65 - e
        .byte $30,$40,$E0,$40,$40,$40,$40,$00 ; 66 - f
        .byte $00,$00,$70,$88,$F8,$08,$F0,$00 ; 67 - g
        .byte $80,$80,$F0,$88,$88,$88,$88,$00 ; 68 - h
        .byte $00,$40,$00,$40,$40,$40,$40,$00 ; 69 - i
        .byte $00,$20,$00,$20,$20,$A0,$60,$00 ; 6A - j
        .byte $00,$80,$80,$A0,$C0,$A0,$90,$00 ; 6B - k
        .byte $C0,$40,$40,$40,$40,$40,$60,$00 ; 6C - l
        .byte $00,$00,$D8,$A8,$A8,$A8,$A8,$00 ; 6D - m
        .byte $00,$00,$F0,$88,$88,$88,$88,$00 ; 6E - n
        .byte $00,$00,$70,$88,$88,$88,$70,$00 ; 6F - o
        .byte $00,$00,$70,$88,$F0,$80,$80,$00 ; 70 - p
        .byte $00,$00,$F0,$88,$78,$08,$08,$00 ; 71 - q
        .byte $00,$00,$70,$88,$80,$80,$80,$00 ; 72 - r
        .byte $00,$00,$78,$80,$70,$08,$F0,$00 ; 73 - s
        .byte $40,$40,$F0,$40,$40,$40,$30,$00 ; 74 - t
        .byte $00,$00,$88,$88,$88,$88,$78,$00 ; 75 - u
        .byte $00,$00,$88,$88,$90,$A0,$40,$00 ; 76 - v
        .byte $00,$00,$88,$88,$88,$A8,$D8,$00 ; 77 - w
        .byte $00,$00,$88,$50,$20,$50,$88,$00 ; 78 - x
        .byte $00,$00,$88,$88,$78,$08,$F0,$00 ; 79 - y
        .byte $00,$00,$F8,$10,$20,$40,$F8,$00 ; 7A - z
        .byte $38,$40,$20,$C0,$20,$40,$38,$00 ; 7B - {
        .byte $40,$40,$40,$00,$40,$40,$40,$00 ; 7C - |
        .byte $E0,$10,$20,$18,$20,$10,$E0,$00 ; 7D - }
        .byte $40,$A8,$10,$00,$00,$00,$00,$00 ; 7E - ~
        .byte $A8,$50,$A8,$50,$A8,$50,$A8,$00 ; 7F - checkerboard
        ; Other stuff
        .byte $18,$3C,$3C,$7E,$7E,$7E,$3C,$3C ; 80 - snake head up   
        .byte $3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C ; 81 - snake body vert  
        .byte $3C,$3C,$7E,$7E,$7E,$3C,$3C,$18 ; 82 - snake head down  
        .byte $00,$38,$FE,$FF,$FF,$FE,$38,$00 ; 83 - snake head right
        .byte $00,$00,$FF,$FF,$FF,$FF,$00,$00 ; 84 - snake body horiz
        .byte $00,$1C,$7F,$FF,$FF,$7F,$1C,$00 ; 85 - snake head left 
        .byte $3C,$3C,$3F,$3F,$3F,$3F,$00,$00 ; 86 - bl corner       
        .byte $00,$00,$3F,$3F,$3F,$3F,$3C,$3C ; 87 - tl corner       
        .byte $00,$00,$FC,$FC,$FC,$FC,$3C,$3C ; 88 - tr corner        
        .byte $3C,$3C,$FC,$FC,$FC,$FC,$00,$00 ; 89 - br corner        
        


end_patterns:

; in graphics 1 mode, these colors refer to the patterns in groups
; of 8.  Each byte covers 8 patterns.
colors:
        .byte $f4,$f4,$f4,$f4,$f4,$f4,$f4,$f4   ; 00 - 3F
        .byte $f4,$f4,$f4,$f4,$f4,$f4,$f4,$f4   ; 40 - 7F
        .byte $f4,$f4,$f4,$f4,$f4,$f4,$f4,$f4   ; 80 - BF
        .byte $f4,$f4,$f4,$f4,$f4,$f4,$f4,$f4   ; C0 - FF

end_colors:

str_game_over:
        .asciiz "Game Over!"