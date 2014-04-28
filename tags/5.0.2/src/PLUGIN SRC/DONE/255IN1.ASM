             .title        "255 in 1 Reader Plugin"


;02/05/00 
;Written by KH
;Version 1.0
             
             ;vectors for standard system calls

send_byte:   .equ 0200h
baton:       .equ 0203h
wr_ppu:      .equ 020ch

temp1:       .equ 00e0h
temp1_lo:    .equ 00e0h
temp1_hi:    .equ 00e1h
temp2:       .equ 00e2h
temp2_lo:    .equ 00e2h
temp2_hi:    .equ 00e3h
temp3:       .equ 00e4h
temp3_lo:    .equ 00e4h
temp3_hi:    .equ 00e5h


             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "255 in 1"

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             
             lda #04h
             jsr send_byte   ;send byte
             
             lda #000h
             jsr send_byte
             lda #030h       ;send size  3Mbyte
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
             lda #000h
             sta temp2_hi
             
di:          ldy #0
             sty temp1_lo
             lda #080h
             sta temp1_hi
             
             lda temp2_hi
             pha
             asl a
             sec
             rol a
             asl a            ;dirty code
             sta temp3_lo
             pla
             lsr a
             lsr a
             lsr a
             lsr a
             sec
             ror a
             sta temp3_hi    ;more dirty code
             sta (temp3),y
             sta (temp3),y   ;they did it 2 times in their code
             
dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             inc temp1_hi
             bne dump_it
             inc temp2_hi
             lda temp2_hi
             cmp #060h
             bne di


             
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             rts            ;done 


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data
             .end
