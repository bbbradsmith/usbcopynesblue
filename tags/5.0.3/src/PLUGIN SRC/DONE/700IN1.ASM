             .title        "700 in 1 Reader Plugin"


;02/04/00 
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
             
             .db "700 in 1"
             
             .fill 0400h-*,00h    ;all plugins must reside at 400h

             
             lda #04h
             jsr send_byte   ;send byte
             

             lda #000h
             sta temp2_hi
             jsr send_byte
             lda #020h       ;send size   2mbyte
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
di2:         lda temp2_hi     ;  1xPP PPP0 xBxx xxxx
             asl a
             ora #080h
             sta temp3_hi
             asl a
             asl a
             lda #000h
             tay
             ror a
             lsr a
             sta temp3_lo
             
             ldy #0
             sta (temp3),y
             
             ldy #000h
             sty temp1_lo
             lda #080h
             sta temp1_hi

dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             inc temp1_hi
             bne dump_it
             inc temp2_hi
             lda temp2_hi
             cmp #040h
             bne di2
             
             
             lda #000h
             sta temp2_hi
             jsr send_byte
             lda #010h
             jsr send_byte
             lda #002h
             jsr send_byte  ;send CHR header
             
di3:         lda temp2_hi    
             lsr a
             php
             lsr a
             tax
             lda #000h
             rol a
             plp
             rol a
             sta 08000h,x
             
             ldy #0
             
             lda #000h
             sta 02006h
             lda #000h
             sta 02006h     ;set PPU address to 0000h
             lda 02007h     ;read garbage byte
             ldx #020h

dump_chr:    lda 02007h
             jsr send_byte
             iny
             bne dump_chr
             dex
             bne dump_chr   ;dump 8K of CHR
             inc temp2_hi
             lda temp2_hi
             cmp #080h
             bne di3
             
             
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             rts            ;done 


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data
             .end
