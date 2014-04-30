             .title        "NROM Reader Plugin"


;06/10/00 
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

;
;cony mapper #1 - 1K CHR banks, 128K PRG.
;

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "NROM -- 16K and 32K" 
             .db " carts w/ 8K CHR ROM",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             
;check mirroring             

             lda #04h
             jsr send_byte   ;send byte
             
             lda #000h
             jsr send_byte
             lda #002h       ;send size (128K)
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
             lda #0
             sta temp2_lo    ;bank ctr
             lda #010h
             sta temp2_hi
             lda #010h
             sta 08100h
             
             
dump_it2:    lda temp2_lo
             sta 08300h
             ldy #0
             sty temp1_lo
             
             lda #080h
             sta temp1_hi

dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it    ;256 bytes
             inc temp1_hi
             lda temp1_hi
             cmp #0a0h
             bne dump_it    ;8K
             inc temp2_lo
             dec temp2_hi
             bne dump_it2   ;128K
             
             
             lda #000h
             jsr send_byte
             lda #004h
             jsr send_byte
             lda #002h
             jsr send_byte  ;send CHR header
             
             
             lda #0
             sta temp2_lo    ;bank ctr
             lda #00h
             sta temp2_hi
             

dump_chr2:   lda temp2_lo
             sta 08310h
             
             ldx #004h
             lda #000h
             sta 02006h
             lda #000h
             sta 02006h     ;set PPU address to 0000h
             lda 02007h     ;read garbage byte
             ldy #0
             
dump_chr:    lda 02007h
             jsr send_byte
             iny
             bne dump_chr
             dex
             bne dump_chr   ;dump 8K of CHR
             inc temp2_lo
             dec temp2_hi
             bne dump_chr2
             
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             rts            ;done 


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
