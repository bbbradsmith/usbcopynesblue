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

;Board name: UNL-SA-72008
;
;
;
;
;
;

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "NROM -- 16K and 32K" 
             .db " carts w/ 8K CHR ROM",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             
;check mirroring             

             
             
             ldx #00h
             
             lda #020h
             jsr wr_ppu
             lda #055h
             sta 2007h
             lda #0aah
             sta 2007h
             lda #024h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #055h
             bne horz_mir
             lda 2007h
             cmp #0aah
             bne horz_mir
             lda #020h
             jsr wr_ppu
             lda #0aah
             sta 2007h
             lda #024h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #0aah
             bne horz_mir
             inx

horz_mir:    txa
             jsr send_byte   ;send byte
             
             lda #000h
next_part:   jsr send_byte
             lda #001h       ;send size (64K)
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             ldy #0
             sty temp1_lo
             
             
             lda #000h
             sta 04100h     ;bank 0 for PRG
             
             ldx #080h
             stx temp1_hi

dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             inc temp1_hi
             bne dump_it
             
             lda #004h
             sta 04100h     ;bank 1 for PRG
             
             ldx #080h
             stx temp1_hi

dump_its:    lda (temp1),y
             jsr send_byte
             iny
             bne dump_its
             inc temp1_hi
             bne dump_its
             
             lda #080h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #002h
             jsr send_byte  ;send CHR header (32K)
             
             lda #0
             sta temp1_lo   ;counter
             
dumbp:       lda temp1_lo
             sta 04100h
             jsr dump_chrb  ;dump 8K of CHR
             inc temp1_lo
             lda #4
             cmp temp1_lo
             bne dumbp      ;do 32K worth
             
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             rts            ;done 
             
dump_chrb:   lda #000h
             sta 02006h
             ldx #020h
             lda #000h
             sta 02006h     ;set PPU address to 0000h
             lda 02007h     ;read garbage byte
             ldy #0
             
dump_chr:    lda 02007h
             jsr send_byte
             iny
             bne dump_chr
             jsr baton
             dex
             bne dump_chr   ;dump 8K of CHR
             rts
             

             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
