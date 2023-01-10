; SNAKE Game written for the BE6502 board as described in the kicad repo:
; https://github.com/linuxplayground/be6502-kiad

        .include "utils.inc"    ; ROM Util Routines
        .include "zeropage.inc" ; free locations start at $d0
        .include "acia.inc"     ; UART Routines
        .include "via_const.inc"; Required for comms with AY-3-8910 Sound chip.

        .import __VIA_START__
VIA_PORTB = __VIA_START__ + VIA_REGISTER_PORTB
VIA_PORTA = __VIA_START__ + VIA_REGISTER_PORTA
VIA_DDRB  = __VIA_START__ + VIA_REGISTER_DDRB
VIA_DDRA  = __VIA_START__ + VIA_REGISTER_DDRA

        .import __TMS_START__
VDP_VRAM                = __TMS_START__ + $00   ; TMS Mode 0
VDP_REG                 = __TMS_START__ + $01   ; TMS Mode 1

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
VDP_TMP         = $d0 ; 2 bytes: used primarily as a pointer to VRAM addresses.
direction       = $d2 ; 1 byte: Stores direction snake is moving in.
snake_x         = $d3 ; 1 byte: Snake head X
snake_y         = $d4 ; 1 byte: Snake head Y
snake_head      = $d5 ; 1 byte this contains the current head character based on direction.
snake_length    = $d6 ; 2 bytes: Currently only one byte used.
apple_x         = $d8 ; 1 byte: current apple X
apple_y         = $d9 ; 1 byte: current apple Y
seed            = $da ; 1 byte: Psudo random number generator seed.
bin2dec_tmp     = $db ; 1 byte: used by calc_score function - convert binary to decimal
score           = $dc ; 1 byte: track the score - incremented each time an apple is eaten
snake_body      = $5000 ; buffer: snake segments are stored as vram address words

; AY-3-8910 Sound interface on VIA IO Port B
; AY-3-8910 Sound data on VIA IO Port A
RESET = %00000100
LATCH = %00000111
WRITE = %00000110

main:
        ; Configure VIA ports to communicate with the AY-3-8910
        lda #$ff                        ; porta used to send data to the ay-3-8910
        sta VIA_DDRA
        lda #(RESET|LATCH|WRITE)        ; portb used to set selct registers and reset the ay-3-8910
        sta VIA_DDRB

        ; initialise memory and video memory.
        jsr clear_ram                   ; clear all video memory
        jsr init_g1                     ; set up TMS9918 for Graphics 1 mode
        jsr init_patterns               ; Copy font and characters to video ram
        jsr init_colors                 ; Copy color table to video ram
        jsr clear_screen                ; Zero out name table (clears screen)
        jsr clear_snake_buffer          ; Zero out snake segments buffer

        ; Initial game settings
        lda #12                         ; snake starts in the middle of the screen
        sta snake_y
        lda #16
        sta snake_x

        lda #mov_right                  ; snake moves right at first
        sta direction

        lda #snake_head_right           ; use the right facing snake head
        sta snake_head

        lda #2                          ; Starting length is 2 segments after head
        sta snake_length

        stz score                       ; set score to zero

        lda #'0'                        ; set the 3 ascii chars for the score to '0'
        sta str_score_val
        sta str_score_val + 1
        sta str_score_val + 2

        lda #$53                        ; arbitrary starting number for the seed
        sta seed
        
        ; set up sound chip
        jsr audio_reset                 ; reset the AY-3-8910 sound chip.
        lda #$2A
        ldx #$07
        jsr audio_write_register        ; enable tone on channel C and noise on channel B
        lda #$1f
        ldx #$0A
        jsr audio_write_register        ; channel C (tone) volume controlled by envelope
        lda #$00
        ldx #$09
        jsr audio_write_register        ; channel B (noise) volume OFF
        

        ; show start game screen
        jsr start_screen                ; prompt user to start game

        ; game started
        jsr gen_apple_position          ; set up first apple location
        jsr draw_apple                  ; display the apple on the screen
        clc                             ; claer carry - we use this a flag often in this game
        jsr game_loop                   ; enter the game loop
exit:
        rts                             ; return to monitor (OS)

; Show the "PRESS SPACE TO START" prompt and increase the seed until the user
; presses space.  As the user will take different amounts of time to press the
; space bar, the value of the seed will be different each time.  This gives the
; effect of random starting locations for the apples
start_screen:
        ldx #6
        ldy #14
        jsr xy_to_vram                  ; Convert X,Y coordinates to vram location.
        lda #<str_space_to_start        ; Set up string pointer to starting byte of
        sta str_ptr                     ; of the "PRESS SPACE TO START" string.
        lda #>str_space_to_start
        sta str_ptr + 1
        jsr vdp_print                   ; print string to screen.

        clc                             ; clear carry
@start_loop:
        inc seed                        ; increment the seed
        jsr _acia_read_byte_nw          ; ROM (OS) routine to check for key press on
        bcc @start_loop                 ; serial terminal.  If carry clear then no key pressed.
        cmp #$20                        ; a key was pressed.  Check if it was a SPACEBAR
        bne @start_loop                 ; not SPACEBAR - keep looping.

        jsr clear_screen                ; SPACEBAR Pressed.  Clear the screen again
        rts                             ; return to caller.

; This is the main game loop. INPUT -> UPDATE -> DRAW -> LOOP
game_loop:
        jsr read_keys                   ; check use input
        jsr update_snake                ; calculate new location of snake head based on user input
        bcs end_game                    ; if update_snake detects collision, then game over.
        jsr collide                     ; check for collision with snake body and apples
        bcs end_game                    ; if collide function detects collision with snake body, game over
        jsr delete_tail                 ; remove the last segment of the snake
        jsr shift_down                  ; move all the snake segments down the snake buffer
        jsr draw_snake                  ; draw all the snake segments from start of snake buffer to start
                                        ; of buffer + snake length

        ldy #$40                        ; delay for 0x40 x 0xFF cycles (at 1MHz this is about 41ms)
        jsr delay
        jmp game_loop                   ; start the loop again

; Game over.  Play a sound and display the game over and score.
end_game:

        ; crash sound fading out
        lda #$1F
        ldx #$09
        jsr audio_write_register        ; channel B (noise) volume controlled by envelope

        lda #$00
        ldx #$0A
        jsr audio_write_register        ; channel A (tone) volume OFF
        
        lda #$a0
        ldx #$0B
        jsr audio_write_register        ; set envelope fine duration

        lda #$40
        ldx #$0C
        jsr audio_write_register        ; set envelope course duration

        lda #$00
        ldx #$0D                        ;                       __
        jsr audio_write_register        ; set envelope shape to   \__ 

        lda #$0f
        ldx #$06
        jsr audio_write_register        ; Set noise duration

        ldx #10                         ; set up cursor on screen
        ldy #8
        jsr xy_to_vram

        lda #<str_game_over             ; set string pointer to game over text
        sta str_ptr
        lda #>str_game_over
        sta str_ptr + 1
        jsr vdp_print                   ; print the game over text

        ldx #10                         ; set up cursor on screen
        ldy #9
        jsr xy_to_vram

        lda #<str_score_title           ; set string pointer to SCORE: text
        sta str_ptr
        lda #>str_score_title
        sta str_ptr + 1
        jsr vdp_print


        lda score                       ; load accumulated score into A register
        jsr calc_score                  ; call the calc_score function

        ldx #17
        ldy #9
        jsr xy_to_vram                  ; set up cursor on screen

        lda #<str_score_val
        sta str_ptr
        lda #>str_score_val
        sta str_ptr + 1
        jsr vdp_print                   ; print 3 digit score string to screen

        rts

; psudo random number generator
; https://codebase64.org/doku.php?id=base:small_fast_8-bit_prng
prng:
        lda seed                        ; this is the seed that was set while waiting
        beq doEor                       ; for the user to press space
        asl                             ; I really don't know how the rest of this works
        bcc noEor                       ; read the linked website I got this from.
doEor:  
        eor #$1d
noEor:  
        sta seed
        rts

; Delay routine
; Y contains the number of outer loops
; each inner loop is 256 cycles.
                                ; 6 cycles (JSR)
delay:
delay_1:
        ldx #$00                ; 2 cycles
delay_2:
        dex                     ; 2 cycles
        bne delay_2             ; 2 cycles
        dey                     ; 2 cycles
        bne delay_1             ; 2 cycles
        rts                     ; 6 cycles

; check if any keys have been pressed.  Update snake direction and head char.
; don't allow reverse directions
read_keys:
        jsr _acia_read_byte_nw  ; monitor (OS) routine checks if a key was pressed
        bcc @return             ; no key pressed, just return - don't change anything
        cmp #'w'                ; check for UP
        beq @up
        cmp #'a'                ; check for LEFT
        beq @left
        cmp #'d'                ; check for RIGHT
        beq @right
        cmp #'s'                ; check for DOWN
        beq @down
        jmp @return             ; some other key was pressed.  We don't care.
@up:
        lda #mov_down           ; If we are currently moving down, we can not move up
        bit direction
        bne @return
        lda #mov_up             ; set the direction to #mov_up
        sta direction
        lda #snake_head_up      ; set the new snake head char to up
        sta snake_head
        jmp @return
@down:
        lda #mov_up             ; If we are currently moving up, we can not move down
        bit direction
        bne @return
        lda #mov_down           ; set the direction to #mov_down
        sta direction
        lda #snake_head_down    ; set the new snake head char to down
        sta snake_head
        jmp @return

@left:
        lda #mov_right          ; If we ar moving right, we can not move left
        bit direction
        bne @return
        lda #mov_left           ; set the direction to left
        sta direction
        lda #snake_head_left    ; set the new snake head char to left
        sta snake_head
        jmp @return
@right:
        lda #mov_left           ; If we are moving left, we can not move right
        bit direction
        bne @return
        lda #mov_right          ; set the direction to right
        sta direction
        lda #snake_head_right   ; set the new snake head char to right
        sta snake_head
        jmp @return
@return:
        rts

; Based on the current direction, figure out the new HEAD location and check
; for collisions with boundaries
update_snake:
        lda direction           ; branch to lables based on direction.
        cmp #mov_up
        beq @move_up
        cmp #mov_down
        beq @move_down
        cmp #mov_left
        beq @move_left
        cmp #mov_right
        beq @move_right
        jmp @return             ; return sort of pointless, because direction will
@move_up:                       ; always be one of up, down, left or right        
        lda snake_y
        dec                     ; decrement Y
        bmi @collide            ; if we have gone into negatives, we are at top of screen
        sta snake_y             ; save Y
        jmp @return
@move_down:
        lda snake_y
        inc                     ; increment Y
        cmp #24                 ; check for bottom of screen (24 rows)
        beq @collide            ; if we have reached 24 we have collided bottom of screen
        sta snake_y             ; save y
        jmp @return
@move_left:
        lda snake_x
        dec                     ; decrement X
        bmi @collide            ; if we have gone into negatives, we are off the left of screen
        sta snake_x             ; save X
        jmp @return
@move_right:
        lda snake_x
        inc                     ; increment X
        cmp #32                 ; check for right of screen (32 colls)
        beq @collide            ; if we have reached 32 we have colled into right
        sta snake_x             ; save X
        
        ; fall through
@return:
        clc                     ; clear carry - no collision
        rts                     ; return to game loop
@collide:
        lda #<str_collide_wall  ; write a debug message to the Serial console.
        sta str_ptr
        lda #>str_collide_wall
        sta str_ptr + 1
        jsr _acia_write_string
        sec                     ; set carry - we have collided - this will be checked
        rts                     ; in the game loop

; Eat the apple, increment score, play a sound, gind a new apple position, draw the new
; apple, increase the snake length
eat_apple:
        inc score                       ; because the score is stored in the first page of RAM
                                        ; it's zeropage and zeropage memory locations can be
                                        ; directly incremented
        lda #$ff
        ldx #$0B
        jsr audio_write_register        ; audio register oct13 - Envelop duration fine
        lda #$4
        ldx #$0C
        jsr audio_write_register        ; audio register oct14 - Envelope duration course
        lda #$00
        ldx #$0D
        jsr audio_write_register        ; adio register oct15 - Envelop shape (fade out)
        lda #$80
        ldx #$04
        jsr audio_write_register        ; tone on channel C

        jsr gen_apple_position          ; generate a new apple position
        jsr draw_apple                  ; draw the new apple

        ; the snake length will never be longer than 128 segments.
        ; we double it, add 2 and then check for overflow.
        ; an alternative would be to just match for 127
        lda snake_length                ; load the snake length
        asl                             ; muliply length by 2
        clc                             ; clear carry
        adc #2                          ; add 2 to length
        bcs @return                     ; if adding 2 causes an overflow, then just return.
        lsr                             ; divide by 2
        sta snake_length                ; store length.
@return:
        rts                             ; back to game loop

; check if we have collided with ourself or an apple.
; use the current location of the snake head (remember it's not drawn yet) to
; read the data in Video RAM.  If that data looks like a snake or an apple we
; have collided.  Otherwise we are good to go.
collide:
        ldx snake_x
        ldy snake_y
        jsr xy_to_vram                  ; convert snake X,Y to vram location

        jsr cin                         ; read the VRAM at vram location
        beq @no_collide                 ; if data read is $00, then no collision
        cmp #$90                        ; If data read is an apple then handle that.
        beq @collide_apple
@collide:                               ; if we get here we must have collided with our self.
        lda #<str_collide_self
        sta str_ptr
        lda #>str_collide_self
        sta str_ptr + 1
        jsr _acia_write_string
        sec                             ; set the carry - this is how the main game loop
        rts                             ; knows that game is over.
@no_collide:
        clc                             ; clear the carry - so the main game loop doesn't 
        rts                             ; end the game.
@collide_apple:
        jsr eat_apple                   ; call the eat apple routine
        clc                             ; clear the carry - game aint over.
        rts

; This is the fundimental animation step.  
; Delete the last segment (tail), draw the new head
delete_tail:
        lda snake_length                ; load the snake length
        asl                             ; times 2
        tax                             ; use the length (muliplied by 2) as an index into the buffer
        lda snake_body,x                ; load the snake buffer at buffer + x (end of tail)
        sta VDP_TMP                     ; save to LOW byte of VRAM pointer
        lda snake_body + 1,x            ; load the snake buffer at buffer + 1 + x (end of tail + 1)
        sta VDP_TMP + 1                 ; save to HIGH byte of VRAM pointer.
        lda #$00
        jsr cout                        ; write empty byte to VRAM at location of tail
        rts

; move all the snake vram addresses in the snake buffer along by one word (2 bytes)
; we start at the end and pull the second to last segment into the last segment and
; keep going until the first segment after the head.
; the ASL (x2) is becasue each segment represented in the buffer is both a HIGH and LOW
; byte.
;
; I am convinced that there is a more efficient way to do this.  It's sitting there
; on the edge of conciousness.  I intuitively think I don't need to shift all the bytes along.
shift_down:
        lda snake_length
        asl
        tax                             ; use the sanke length as an index into the buffer
@shift_down_lp:
        lda snake_body - 2, x           ; these steps move the two bytes from x-1 to x
        sta snake_body, x
        lda snake_body - 1, x
        sta snake_body + 1, x
        dex                             ; decrement index twice
        dex
        cpx #2                          ; stop if we are at the segment directly after the head
        bpl @shift_down_lp              ; keep shifting the data along.
        rts

; draw snake head
draw_snake:
        ldx snake_x
        ldy snake_y
        jsr xy_to_vram                  ; find the VRAM address for location X,Y
        lda snake_head
        jsr cout                        ; draw the current head to the screen

        lda VDP_TMP                     ; save the current VRAM address into the top of the snake
        sta snake_body                  ; buffer
        lda VDP_TMP + 1
        sta snake_body + 1
        rts

; this routine finds a random number for X and Y, checks if it's a free spot on the screen
; saves those values into apple_x and apple_y memory addresses.
gen_apple_position:
@get_rand_x:
        jsr prng                        ; get a random number
        and #$1F                        ; mask bits to limit result to below 32
        clc                             ; clear carry
        cmp #30                         ; check that result is less than 30
        bcs @get_rand_x                 ; if over 30 get another random number
        cmp #1                          ; check if result is greater than 1
        bcc @get_rand_x                 ; if less or equal to 1, get a new random number
        sta apple_x                     ; save apple_x
@get_rand_y:
        jsr prng                        ; get a random number
        and #$17                        ; mask bits to limit result to below 23
        clc                             ; clc
        cmp #22                         ; check that result is less than 22
        bcs @get_rand_y                 ; if over 22, get another random number
        cmp #1                          ; check if result is greater than 1
        bcc @get_rand_y                 ; if less or equal to 1, get a new random number
        sta apple_y                     ; save apply_y

        ldx apple_x                     ; convert apply X,Y to VRAM address
        ldy apple_y
        jsr xy_to_vram
        jsr cin                         ; load data at VRAM address
        cmp #$00                        ; check if empty space
        bne gen_apple_position          ; if not empty space - find new random location
@no_collide:
        rts

; draw the apple (CHAR 90) at VRAM location
draw_apple:
        ldx apple_x
        ldy apple_y
        jsr xy_to_vram
        lda #$90
        jsr cout
        rts

; cout - print A at vram pointed to by VDP_TMP
cout:
        phx                             ; save X register to stack
        pha                             ; save A register to stack
        lda VDP_TMP                     ; load LOW byte of vram pointer
        ldx VDP_TMP + 1                 ; load HIGH byte of vram pointer
        jsr vdp_set_ram_address         ; set the VRAM Write Address in the TMS9918A register
        pla                             ; pull A from stack
        sta VDP_VRAM                    ; save A to VRAM (this writes to the display)
        plx                             ; pull X from stack
        rts

; cin - load A from vram pointed to by VDP_TMP
cin:
        lda VDP_TMP                     ; load LOW byte of vram pointer
        ldx VDP_TMP + 1                 ; load HIGH byte of vram pointer
        jsr vdp_get_ram_address         ; set the VRAM Read Address in the TMS9918A register
        lda VDP_VRAM                    ; read the VRAM at the address into A
        rts

; VRAM address will be in VDP_TMP when done.
; there are 24 rows of 32 characters in each row.
; an address location is start_of_name_table + (y * 32) + x
xy_to_vram:
        lda #<name_table                ; set vram pointer to start of name table
        sta VDP_TMP
        lda #>name_table
        sta VDP_TMP + 1

@mul_32:
        lda #0                          ; keep adding 32 until Y = 0
@mul_32_lp:
        cpy #$00
        beq @mul_32_add_x               ; if Y is already zero - just add the X to vram pointer
        clc                             ; clear carry
        adc #32                         ; add 32
        sta VDP_TMP                     ; save result to LOW byte of vram pointer
        bcc @mul_32_cont                ; if carry is clear (no overflow) keey going
        inc VDP_TMP + 1                 ; overflowed - increment high byte of vram pointer
@mul_32_cont:
        dey                             ; decrement Y
        bne @mul_32_lp                  ; if Y is not 0, then do it all again
@mul_32_add_x:
        clc                             ; clear carry
        txa                             ; transfer x to a
        adc VDP_TMP                     ; add A to the low byte of the vram pointer (adds x)
        sta VDP_TMP
        bcc @done                       ; if no overflow we are done
        inc VDP_TMP + 1                 ; there is an overflow, increment high byte of vram pointer
@done:
        rts
        
; there are 768 locations on the screen.  In HEX this is 0x300 or 3 * 0x100 (00-FF)
; so we start with the start of the name table.  Then set the cursor.
; load a $00 into each of the 768 VRAM locations.
clear_screen:
        lda #<name_table
        ldx #>name_table
        jsr vdp_set_ram_address         ; set VDP_RAM address in TMS register
        lda #$00                        ; load A with empty char
        jsr cs_pg                       ; process a page (00-FF)
        jsr cs_pg                       ; process a page (00-FF)
        ; fall through - Page
cs_pg:
        ldx #$00                        ; set up a counter
cs_pg_1:
        sta VDP_VRAM                    ; the VRAM address in the TMS auto increments on
        dex                             ; each write; decrement counter
        bne cs_pg_1                     ; while counter is not 0, loop
        rts

; Clear the snake buffer.  This is to avoid strange artifacts on screen.
; it's only called at the start of a game.
clear_snake_buffer:
        ldx #$00                        ; set up a counter
@clear_snake_buffer_lp:
        stz snake_body, x               ; save zero to snake buffer + counter
        dex                             ; decrement counter
        bne @clear_snake_buffer_lp      ; while not zero; loop
        rts

; Clears all the VRAM.  There are 16kb of addressable Video memory.  These 
; are all cleared when game starts.
clear_ram:
        lda #$00                        ; set vram cursor to (0x0000)
        ldx #$00
        jsr vdp_set_ram_address
        lda #$FF                        ; use the VRAM pointer to count from
        sta VDP_TMP                     ; 0x0000 to 0x3FFF (16kbyes)
        lda #$3F
        sta VDP_TMP + 1
@clr_1:
        lda #$00                        ; save $00 into video memory at current cursor
        sta VDP_VRAM                    ; the cursor auto increments on access
        dec VDP_TMP                     ; decrement the pointer low byte
        lda VDP_TMP
        bne @clr_1
        dec VDP_TMP + 1                 ; if low byte gets to 0, decrement high byte
        lda VDP_TMP + 1
        bne @clr_1                      ; while pointer is not zero, keep looping.
        rts
; copy all the pattern bytes into the pattern table address space in the video ram.
init_patterns:
        ldx #>pattern_table             ; set the VRAM cursor to the pattern table start address
        lda #<pattern_table
        jsr vdp_set_ram_address
        lda #<patterns                  ; load the low byte of the pattens
        sta VDP_TMP                     ; save to vram address pointer low
        lda #>patterns                  ; load the high byte of the patterns
        sta VDP_TMP + 1                 ; save to vram address pointer high
@ip_1:
        lda (VDP_TMP)                   ; load the data pointed to by the vram address pointer
        sta VDP_VRAM                    ; save to vram.  vram cursor auto increments on access

        lda VDP_TMP                     ; load the low byte of the address pointer
        clc
        adc #1                          ; add 1 with carry
        sta VDP_TMP                     ; save to low byte of pointer
        lda #0                          ; load 0
        adc VDP_TMP + 1                 ; add 0 with carry (if there was a carry it will be added)
        sta VDP_TMP + 1                 ; save to high byte of pointer
        cmp #>end_patterns              ; check if we are at the end of the patterns table
        bne @ip_1
        lda VDP_TMP
        cmp #<end_patterns
        bne @ip_1        
        rts

; just like how we did with patterns, copy the colour table to vram.
init_colors:
        ldx #>color_table               ; set the VRAM cursor to the colour table start address
        lda #<color_table
        jsr vdp_set_ram_address
        lda #<colors                    ; load the low byte of the colors
        sta VDP_TMP                     ; save to vram address pointer low
        lda #>colors                    ; load the high byte of the colors
        sta VDP_TMP + 1                 ; save to vram address pointer high
@ic_1:
        lda (VDP_TMP)                   ; load the data pointed to by the vram address pointer
        sta VDP_VRAM                    ; save to vram.  vram cursor auto increments on access

        lda VDP_TMP                     ; load the low byte of the address pointer
        clc
        adc #1                          ; add 1 with carry
        sta VDP_TMP                     ; save to low byte of pointer
        lda #0                          ; load 0
        adc VDP_TMP + 1                 ; add 0 with carry (if ther ewas a carry it will be added)
        sta VDP_TMP + 1                 ; save to high byte of pointer
        cmp #>end_colors                ; check if we are at the end of the colors table
        bne @ic_1
        lda VDP_TMP
        cmp #<end_colors
        bne @ic_1        
        rts

; initialise graphics 1 mode.  Loop through the data in the init_g1_data table into the registers
; of the TMS9981A VDP
init_g1:
        ldx #0                          ; set up a counter
@init_g1_1:
        lda init_g1_data, x             ; load value of register
        jsr vdp_set_register            ; set register X with value A
        inx                             ; increment X
        cpx #7                          ; check if we have done 7 registers
        bne @init_g1_1                  ; if not then loop
        rts

; set a TMS9918A register
; x = register
; a = value
vdp_set_register:
        sta VDP_REG                     ; save the value
        txa                             ; transfer x to A
        ora #$80                        ; turn on the most significant bit (bit 7)
        sta VDP_REG                     ; save the register number
        rts

; set the cursor in VRAM for writing
; x = ram high
; a = ram low
vdp_set_ram_address:
        sta VDP_REG                     ; save low byte
        txa                             ; transfer X to A
        ora #$40                        ; turn off most significant bit (bit 7), turn on bit 6
        sta VDP_REG                     ; save high byte
        rts

; set the cursor in VRAM for reading
; x = ram high
; a = ram low
vdp_get_ram_address:
        sta VDP_REG
        txa
        sta VDP_REG
        rts

; print null terminated string pointed to by str_ptr at current cursor location.
; str_ptr is defined in zeropage.inc (part of OS)
vdp_print:
        lda VDP_TMP
        ldx VDP_TMP + 1
        jsr vdp_set_ram_address         ; set the vram cursor to address pointed to by vram pointer
        ldy #$00                        ; set an index counter
@message_lp:
        lda (str_ptr), y                ; load the data from address pointed to by str_ptr indexed by y
        beq @done                       ; if char is a zero, then we are done.
        sta VDP_VRAM                    ; save data to VRAM
        iny                             ; increment index
        jmp @message_lp                 ; loop
@done:
        rts


; convert A (8 bit bin) to decimal.
; stores ascii text data in score_val

calc_score:
        sta bin2dec_tmp                 ; save A into a temp variable
@hundreds_lp:
        lda bin2dec_tmp                 ; load A from temp variable
        cmp #100                        ; check if less than 100
        bcc @tens_lp                    ; if less than 100 goto tens
        lda bin2dec_tmp                 ; load A from temp variable
        sec                             ; set carry
        sbc #100                        ; subtract with carry 100
        sta bin2dec_tmp                 ; save result to temp variable
        lda str_score_val               ; load the 100s place in the score value string
        inc a                           ; increment by 1 - in ascii from 30 to 31 for example.
        sta str_score_val               ; save 100s place
        jmp @hundreds_lp                ; loop
@tens_lp:
        lda bin2dec_tmp                 ; same as 100s but for 10s place
        cmp #10
        bcc @ones_lp
        lda bin2dec_tmp
        sec
        sbc #10
        sta bin2dec_tmp
        lda str_score_val + 1
        inc a
        sta str_score_val + 1
        jmp @tens_lp
@ones_lp:                               ; anything left after dealing with 100s and 10s places
        lda bin2dec_tmp                 ; is just saved as ASCII to the 1s place.
        adc #$30
        sta str_score_val + 2
        rts

; resets the audo AY-3-8910
audio_reset:
        lda #$00
        sta VIA_PORTB
        lda #10
        jsr _delay_ms
        lda #RESET
        sta VIA_PORTB
        rts

; a contains value to send
; x contains register to send to.
audio_write_register:
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

init_g1_data:
reg_0: .byte $00       ; r0
reg_1: .byte $C0       ; r1 16kb ram + M1
reg_2: .byte $05       ; r2 name table at 0x1400
reg_3: .byte $80       ; r3 color start 0x2000
reg_4: .byte $01       ; r4 pattern generator start at 0x800
reg_5: .byte $20       ; r5 Sprite attriutes start at 0x1000
reg_6: .byte $00       ; r6 Sprite pattern table at 0x0000
reg_7: .byte $14       ; r7 Set background and forground color

; patterns are fonts etc.  Each group of 8 bytes is represented in the name_table
; so if we write 0x23 to a location in the name_table, the '#' character will be
; written to the display in whatever location is the current vram cursor
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
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 8a - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 8b - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 8c - 
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 8d -
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 8e -
        .byte $00,$00,$00,$00,$00,$00,$00,$00 ; 8f -   
        .byte $04,$68,$37,$7F,$7F,$7F,$7F,$3E ; 90 - apple     
        


end_patterns:

; in graphics 1 mode, these colors refer to the patterns in groups
; of 8.  Each byte covers 8 patterns.  so pattern 90 for example is covered by color $34
; in this table.  0x3 is the forground color (light green) and 0x4 is the background color
; (blue)
colors:
        .byte $f4,$71,$71,$71,$71,$71,$71,$71   ; 00 - 3F
        .byte $71,$71,$71,$71,$71,$71,$71,$71   ; 40 - 7F
        .byte $f4,$f4,$34,$f4,$f4,$f4,$f4,$f4   ; 80 - BF
        .byte $f4,$f4,$f4,$f4,$f4,$f4,$f4,$f4   ; C0 - FF
end_colors:

; game strings

str_collide_self:
        .asciiz "Collide Self!"
str_collide_wall:
        .asciiz "Collide Wall!"
str_game_over:
        .asciiz "GAME OVER!"
str_space_to_start:
        .asciiz "PRESS SPACE TO START"
str_score_title:
        .asciiz "SCORE: "
str_score_val:
        .asciiz "000"