        .zeropage

        .exportzp usr_irq
        .exportzp kbd_r_ptr
        .exportzp kbd_w_ptr
        .exportzp kbd_flags
        .exportzp tmp1
        .exportzp lcd_temp_char1
        .exportzp lcd_temp_char2
        .exportzp lcd_temp_char3
        .exportzp str_ptr
        .exportzp crc
        .exportzp crch
        .exportzp ptr
        .exportzp ptrh
        .exportzp blkno
        .exportzp retry
        .exportzp retry2
        .exportzp bflag
        .exportzp XAML 
        .exportzp XAMH 
        .exportzp STL  
        .exportzp STH  
        .exportzp L    
        .exportzp H  
        .exportzp YSAV 
        .exportzp MODE 
        .exportzp MSGL 
        .exportzp MSGH
        .exportzp LAB_WARM
        .exportzp Wrmjpl 
        .exportzp Wrmjph  
        .exportzp Usrjmp  
        .exportzp Usrjpl  
        .exportzp Usrjph  
        .exportzp Nullct  
        .exportzp TPos   
        .exportzp TWidth  
        .exportzp Iclim   
        .exportzp Itempl  
        .exportzp Itemph  
        .exportzp nums_3 
        .exportzp Srchc  
        .exportzp Scnquo 
        .exportzp Ibptr  
        .exportzp Defdim 
        .exportzp Dtypef 
        .exportzp Oquote 
        .exportzp Gclctd 
        .exportzp Sufnxf 
        .exportzp Imode  
        .exportzp Cflag 
        .exportzp TabSiz 
        .exportzp next_s
        .exportzp last_sl
        .exportzp last_sh
        .exportzp des_sk 
        .exportzp ut1_pl 
        .exportzp ut1_ph 
        .exportzp ut2_pl 
        .exportzp ut2_ph 
        .exportzp FACt_1 
        .exportzp FACt_2 
        .exportzp FACt_3 
        .exportzp TempB  
        .exportzp Smeml  
        .exportzp Smemh  
        .exportzp Svarl  
        .exportzp Svarh  
        .exportzp Sarryl 
        .exportzp Sarryh 
        .exportzp Earryl
        .exportzp Earryh
        .exportzp Sstorl
        .exportzp Sstorh
        .exportzp Sutill
        .exportzp Sutilh
        .exportzp Ememl 
        .exportzp Ememh 
        .exportzp Clinel
        .exportzp Clineh
        .exportzp Blinel
        .exportzp Blineh
        .exportzp Cpntrl
        .exportzp Cpntrh
        .exportzp Dlinel
        .exportzp Dlineh
        .exportzp Dptrl 
        .exportzp Dptrh
        .exportzp Rdptrl
        .exportzp Rdptrh
        .exportzp Varnm1
        .exportzp Varnm2
        .exportzp Cvaral
        .exportzp Cvarah
        .exportzp Frnxtl
        .exportzp Frnxth
        .exportzp prstk
        .exportzp comp_f
        .exportzp func_l
        .exportzp func_h
        .exportzp des_2l
        .exportzp des_2h
        .exportzp g_step
        .exportzp Fnxjmp
        .exportzp Fnxjpl
        .exportzp Fnxjph
        .exportzp Adatal
        .exportzp Adatah
        .exportzp Obendl
        .exportzp Obendh
        .exportzp numexp
        .exportzp expcnt
        .exportzp numdpf
        .exportzp expneg
        .exportzp FAC1_e
        .exportzp FAC1_1
        .exportzp FAC1_2
        .exportzp FAC1_3
        .exportzp FAC1_s
        .exportzp negnum
        .exportzp FAC1_o
        .exportzp FAC2_e
        .exportzp FAC2_1
        .exportzp FAC2_2
        .exportzp FAC2_3
        .exportzp FAC2_s
        .exportzp FAC_sc
        .exportzp FAC1_r
        .exportzp csidx
        .exportzp Aspth
        .exportzp LAB_IGBY
        .exportzp LAB_GBYT
        .exportzp Bpntrl
        .exportzp Bpntrh  
        .exportzp Rbyte4  
        .exportzp Rbyte1  
        .exportzp Rbyte2  
        .exportzp Rbyte3  
        .exportzp NmiBase 
        .exportzp IrqBase 
        .exportzp Decss 
        .exportzp Decssp1 
        .exportzp VDP_PATTERN_INIT
        .exportzp VDP_PATTERN_INIT_HI
        .exportzp VDP_TMP_VRAM
       
usr_irq:                .res 2, 0  ; the jump vector for user IRQ routines

kbd_r_ptr:              .res 1
kbd_w_ptr:              .res 1
kbd_flags:              .res 1

tmp1:                   .res 1
lcd_temp_char1:         .res 1
lcd_temp_char2:         .res 1
lcd_temp_char3:         .res 1
str_ptr:                .res 2

crc:                    .res 1	; CRC lo byte  (two byte variable)
crch:                   .res 1	; CRC hi byt:                   
ptr:                    .res 1	; data pointer (two byte variable)
ptrh:                   .res 1	;   "
blkno:                  .res 1	; block number 
retry:                  .res 1	; retry counter 
retry2:                 .res 1	; 2nd counter
bflag:                  .res 1	; block flag 

XAML:                   .res 1
XAMH:                   .res 1
STL:                    .res 1
STH:                    .res 1
L:                      .res 1
H:                      .res 1
YSAV:                   .res 1
MODE:                   .res 1
MSGL:                   .res 1
MSGH:                   .res 1

; ehbasic
; the following locations are bulk initialized from StrTab at LAB_GMEM
LAB_WARM:               .res 1          ; BASIC warm start entry point
Wrmjpl:                 .res 1          ; BASIC warm start vector jump low byte
Wrmjph:                 .res 8          ; BASIC warm start vector jump high byte

Usrjmp:                 .res 1          ; USR function JMP address
Usrjpl:                 .res 1          ; USR function JMP vector low byte
Usrjph:                 .res 1          ; USR function JMP vector high byte
Nullct:                 .res 1          ; nulls output after each line
TPos:                   .res 1          ; BASIC terminal position byte
TWidth:                 .res 1          ; BASIC terminal width byte
Iclim:                  .res 1          ; input column limit
Itempl:                 .res 1          ; temporary integer low byte
Itemph:                 .res 1          ; temporary integer high byte
; end bulk initialize from StrTab at LAB_GMEM
nums_3:                 .res 1          ; number to bin/hex string convert LSB
Srchc:                  .res 1          ; search character
Scnquo:                 .res 1          ; scan-between-quotes flag
Ibptr:                  .res 1          ; input buffer pointer
Defdim:                 .res 1          ; default DIM flag
Dtypef:                 .res 1          ; data type flag, $FF=string, $00=numeric
Oquote:                 .res 1          ; open quote flag (b7) (Flag: DATA scan; LIST quote; memory)
Gclctd:                 .res 1          ; garbage collected flag
Sufnxf:                 .res 1          ; subscript/FNX flag, 1xxx xxx = FN(0xxx xxx)
Imode:                  .res 1          ; input mode flag, $00=INPUT, $80=READ
Cflag:                  .res 1          ; comparison evaluation flag
TabSiz:                 .res 1          ; TAB step size (was input flag)
next_s:                 .res 1          ; next descriptor stack address
                                        ; these two bytes form a word pointer to the item
                                        ; currently on top of the descriptor stack
last_sl:                .res 1          ; last descriptor stack address low byte
last_sh:                .res 1          ; last descriptor stack address high byte (always $00)
des_sk:                 .res 9          ; descriptor stack start address (temp strings)
ut1_pl:                 .res 1          ; utility pointer 1 low byte
ut1_ph:                 .res 1          ; utility pointer 1 high byte
ut2_pl:                 .res 1          ; utility pointer 2 low byte
ut2_ph:                 .res 1          ; utility pointer 2 high byte
FACt_1:                 .res 1          ; FAC temp mantissa1
FACt_2:                 .res 1          ; FAC temp mantissa2
FACt_3:                 .res 1          ; FAC temp mantissa3
TempB:                  .res 1          ; temp page 0 byte
Smeml:                  .res 1          ; start of mem low byte       (Start-of-Basic)
Smemh:                  .res 1          ; start of mem high byte      (Start-of-Basic)
Svarl:                  .res 1          ; start of vars low byte      (Start-of-Variables)
Svarh:                  .res 1          ; start of vars high byte     (Start-of-Variables)
Sarryl:                 .res 1          ; var mem end low byte        (Start-of-Arrays)
Sarryh:                 .res 1          ; var mem end high byte       (Start-of-Arrays)
Earryl:                 .res 1          ; array mem end low byte      (End-of-Arrays)
Earryh:                 .res 1          ; array mem end high byte     (End-of-Arrays)
Sstorl:                 .res 1          ; string storage low byte     (String storage (moving down))
Sstorh:                 .res 1          ; string storage high byte    (String storage (moving down))
Sutill:                 .res 1          ; string utility ptr low byte
Sutilh:                 .res 1          ; string utility ptr high byte
Ememl:                  .res 1          ; end of mem low byte         (Limit-of-memory)
Ememh:                  .res 1          ; end of mem high byte        (Limit-of-memory)
Clinel:                 .res 1          ; current line low byte       (Basic line number)
Clineh:                 .res 1          ; current line high byte      (Basic line number)
Blinel:                 .res 1          ; break line low byte         (Previous Basic line number)
Blineh:                 .res 1          ; break line high byte        (Previous Basic line number)
Cpntrl:                 .res 1          ; continue pointer low byte
Cpntrh:                 .res 1          ; continue pointer high byte
Dlinel:                 .res 1          ; current DATA line low byte
Dlineh:                 .res 1          ; current DATA line high byte
Dptrl:                  .res 1          ; DATA pointer low byte
Dptrh:                  .res 1          ; DATA pointer high byte
Rdptrl:                 .res 1          ; read pointer low byte
Rdptrh:                 .res 1          ; read pointer high byte
Varnm1:                 .res 1          ; current var name 1st byte
Varnm2:                 .res 1          ; current var name 2nd byte
Cvaral:                 .res 1          ; current var address low byte
Cvarah:                 .res 1          ; current var address high byte
Frnxtl:                 .res 1          ; var pointer for FOR/NEXT low byte
Frnxth:                 .res 1          ; var pointer for FOR/NEXT high byte
prstk:                  .res 1          ; precedence stacked flag
comp_f:                 .res 1          ; compare function flag, bits 0,1 and 2 used
                                        ; bit 2 set if >
                                        ; bit 1 set if =
                                        ; bit 0 set if <
func_l:                 .res 1          ; function pointer low byte
func_h:                 .res 1          ; function pointer high byte
des_2l:                 .res 1          ; string descriptor_2 pointer low byte
des_2h:                 .res 1          ; string descriptor_2 pointer high byte
g_step:                 .res 1          ; garbage collect step size
Fnxjmp:                 .res 1          ; jump vector for functions
Fnxjpl:                 .res 1          ; functions jump vector low byte
Fnxjph:                 .res 1          ; functions jump vector high byte
Adatal:                 .res 1          ; array data pointer low byte
Adatah:                 .res 1          ; array data pointer high  byte
Obendl:                 .res 1          ; old block end pointer low byte
Obendh:                 .res 1          ; old block end pointer high  byte
numexp:                 .res 1          ; string to float number exponent count
expcnt:                 .res 1          ; string to float exponent count
numdpf:                 .res 1          ; string to float decimal point flag
expneg:                 .res 1          ; string to float eval exponent -ve flag
FAC1_e:                 .res 1          ; FAC1 exponent
FAC1_1:                 .res 1          ; FAC1 mantissa1
FAC1_2:                 .res 1          ; FAC1 mantissa2
FAC1_3:                 .res 1          ; FAC1 mantissa3
FAC1_s:                 .res 1          ; FAC1 sign (b7)
negnum:                 .res 1          ; string to float eval -ve flag
FAC1_o:                 .res 1          ; FAC1 overflow byte
FAC2_e:                 .res 1          ; FAC2 exponent
FAC2_1:                 .res 1          ; FAC2 mantissa1
FAC2_2:                 .res 1          ; FAC2 mantissa2
FAC2_3:                 .res 1          ; FAC2 mantissa3
FAC2_s:                 .res 1          ; FAC2 sign (b7)
FAC_sc:                 .res 1          ; FAC sign comparison, Acc#1 vs #2
FAC1_r:                 .res 1          ; FAC1 rounding byte
csidx:                  .res 1          ; line crunch save index
Aspth:                  .res 1          ; array size/pointer high byte
; the following locations are bulk initialized from LAB_2CEE at LAB_2D4E
LAB_IGBY:               .res 6          ; get next BASIC byte subroutine
LAB_GBYT:               .res 1          ; get current BASIC byte subroutine
Bpntrl:                 .res 1          ; BASIC execute (get byte) pointer low byte
Bpntrh:                 .res 20         ; BASIC execute (get byte) pointer high byte
                                        ; plus extra space
Rbyte4:                 .res 1          ; extra PRNG byte
Rbyte1:                 .res 1          ; most significant PRNG byte
Rbyte2:                 .res 1          ; middle PRNG byte
Rbyte3:                 .res 1          ; least significant PRNG byte

NmiBase:                .res 3         ; NMI handler enabled/setup/triggered flags
                                       ; bit function
                                       ; === ========
                                       ; 7   interrupt enabled
                                       ; 6   interrupt setup
                                       ; 5   interrupt happened
IrqBase:                .res 3         ; IRQ handler enabled/setup/triggered flags
Decss:                  .res 1         ; number to decimal string start
Decssp1:                .res 16        ; number to decimal string start

; TMS Stuff

VDP_PATTERN_INIT:       .res 1
VDP_PATTERN_INIT_HI:    .res 1
VDP_TMP_VRAM:           .res 2