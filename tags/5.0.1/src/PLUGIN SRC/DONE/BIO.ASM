             .title      "Bio Miracle Reader Plugin"


;10/30/00 
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
             .db "Bio Miracle Plugin"

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             
;check mirroring             

             
             
             lda #04h
             jsr send_byte   ;send byte
             
             lda #000h
             jsr send_byte
             lda #002h       ;send size 128K
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
             
             lda #010h
             sta temp3_lo
             lda #000h
             sta temp3_hi

             
di2:         ldy #0
             sty temp1_lo
             lda #060h
             sta temp1_hi
             lda temp3_hi
             sta 0e000h
             ldx #020h

dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             jsr baton
             inc temp1_hi
             dex
             bne dump_it
             inc temp3_hi
             dec temp3_lo
             bne di2
             
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             rts            ;done 


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
