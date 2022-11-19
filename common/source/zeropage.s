        .zeropage

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