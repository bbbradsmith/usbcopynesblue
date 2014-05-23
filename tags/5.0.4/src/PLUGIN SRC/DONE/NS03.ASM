             .title        "NS03 Cart Reader Plugin"


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

;Board Name BMC-NS03 (The board has no marking except "12 in 1" on it
;Cart: NS03 7 in 1
;
;Discrete mapper, made out of '161, '32, '153, '139, '00, '374*2, and 
;512K CHR/PRG
;
;This is fairly basic.  The submapper is an MMC1-like clone, but unlike
;the real article, you only write once to the registers.  
;
;The supermapper:
;
;Writing anywhere in 0e000h thru 0fffh accesses the supermapper.
;
;7       0
;---------
;xxxx AMZZ
;
;A = A14 disable for upper bank.  When set, the upper 16K of cart space 
;will follow the (lower 16K of cart space) OR 01h. 
;
;Z = 128K bank select.  This selects which 128K bank of CHR and 128K
;PRG the submapper will "See".
;
;M = mirroring. 0 = 5, 1 = 3
;
;The submapper:
;
;It has two registers:
;
;0a000h - 0bfffh controls the lower CHR bank 
;0c000h - 0dfffh controls the upper CHR bank and the lower PRG bank
;
;0a000h:
;
;7       0
;---------
;CCCC Cxxx
;
;C = CHR bank. Select a 4K CHR bank at 0000-0fffh in PPU space
;
;
;0c000h:
;
;7       0
;---------
;CCCC CPPP
;
;C = CHR bank. Select a 4K CHR bank at 1000-1fffh in PPU space
;
;P = PRG bank. Select a 16K PRG bank at 8000h-bfffh.
;              Note: when bit "A" is 0, c000h-ffffh is set to the
;              last 16K of the 128K suppermapper bank.  When set to "1",
;              the last 16K follows the first 16K OR 01h. i.e. if the lower
;              16K is on bank 04h, then the upper 16K would be on bank 05h.
;              if the lower 16K is on bank 05h, the upper bank will still
;              be on 05h. (since 05h OR 01h = 05h) 
;

             
             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "NROM -- 16K and 32K" 
             .db " carts w/ 8K CHR ROM",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             

             lda #4
             jsr send_byte   ;send byte
             
             lda #000h
             jsr send_byte
             lda #008h       ;send size (512K)
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
             
             ldy #0
             sty temp1_lo
             sty temp2_lo
             sty 0a000h
             sty 0c000h
             sty 0e000h
             ldx #4
             
dump_it2:    lda temp2_lo
             sta 0e000h
             lda #00h
             sta temp2_hi
             
dump_it3:    lda temp2_hi
             sta 0c000h

             lda #080h
             sta temp1_hi

dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             inc temp1_hi
             lda temp1_hi
             cmp #0c0h
             bne dump_it   ;do 16K
             inc temp2_hi
             lda temp2_hi
             cmp #008h
             bne dump_it3  ;do 128K
             inc temp2_lo
             dex
             bne dump_it2  ;do 512K
             
             lda #000h
             jsr send_byte
             lda #008h
             jsr send_byte
             lda #002h
             jsr send_byte  ;send CHR header
             
             
             lda #000h
             sta temp2_lo
             
dump_chr3:   lda #00h
             sta temp2_hi
             lda temp2_lo
             sta 0e000h
             
dump_chr2:   lda temp2_hi
             asl a
             asl a
             asl a
             sta 0a000h         ;CHR sel
             lda #000h
             sta 02006h
             lda #000h
             sta 02006h     ;set PPU address to 0000h
             lda 02007h     ;read garbage byte
             ldx #10h
             ldy #0
             
dump_chr:    lda 02007h
             jsr send_byte
             iny
             bne dump_chr
             dex
             bne dump_chr   ;dump 4K of CHR
             inc temp2_hi
             lda temp2_hi
             cmp #020h
             bne dump_chr2  ;dump 256K of CHR
             inc temp2_lo
             lda temp2_lo
             cmp #004h
             bne dump_chr3  ;dump 512K of CHR
             
             
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             rts            ;done 


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
