             .title        "Sachen Reader Plugin"


;02/03/01 
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
             
             .db "NROM -- 16K and 32K" 
             .db " carts w/ 8K CHR ROM",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             

             lda #04h
             jsr send_byte   ;send byte
             
             lda #000h
             jsr send_byte
             lda #001h       ;send size
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
             lda #00h
             sta temp2_hi

di2:         lda #000h
             sta temp1_lo
             tay
             lda #080h
             sta temp1_hi
             
             lda #05h
             sta 04100h
             lda temp2_hi
             sta 04101h
             
dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             jsr baton
             inc temp1_hi
             bne dump_it
             inc temp2_hi
             lda temp2_hi
             cmp #02h
             bne di2
             
             lda #000h
             jsr send_byte
             lda #001h
             jsr send_byte
             lda #002h
             jsr send_byte  ;send CHR header
             
             ldy #000h
             sty temp2_hi             

di3:         
             
             lda #04h
             sta 04100h
             lda temp2_hi
             and #01h
             sta 04101h
             
             lda #06h
             sta 04100h
             lda temp2_hi
             lsr a
             sta 04101h

             lda #000h
             sta 02006h
             lda #000h
             sta 02006h     ;set PPU address to 0000h
             lda 02007h     ;read garbage byte
             ldy #0


             ldx #020h
             
dump_chr:    lda 02007h
             jsr send_byte
             iny
             bne dump_chr
             dex
             bne dump_chr   ;dump 8K of CHR
             inc temp2_hi
             lda temp2_hi
             cmp #08h
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
