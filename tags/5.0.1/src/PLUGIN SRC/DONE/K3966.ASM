             .title        "K3966-SS Reader Plugin"


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


;Board: K3966-SS
;Cart: Generic 3 in 1
;(TMNT 3, Darkwing Duck, Chip and Dale)
;
;This cart has a normal old MMC3 mapper on it mapped into the usual place
;hooked up in the usual manner.
;
;6800h and 6801h control the supermapper (the MMC3 is the submapper in this
;case)
;
;Supermapper controls:
;
;6800h:
;
;7       0
;---------
;xxxx xxxJ
;
;J = Jumper read.  Setting this bit will disable the PRG ROM and will
;    switch in the two jumpers.  They can be read anywhere in PRG space,
;    and they will appear in D0 and D1. This of course switched out code!
;
;6801h:
;7       0
;---------
;LAxB CZSU
;
;L = Lock.  When this bit is set, no further writes to 6800h or 6801h are
;    possible until either a power failure or an NES reset occurs.
;
;A = A14 disable.  When low, the "ROM window" is 32K.  When high, the ROM
;    window is 16K.  The ROM window is the address space at 8000h through
;    FFFFh.  When A is high, 8000h through BFFFh will equal C000h through
;    FFFFh.  This is used to allow playing of 16K games (remember this WAS
;    a pirate cart, so if they had space left they could throw on some small
;    games).
;
;B = 256K PRG bank.  This selects which 256K PRG superbank is "seen" by 
;    the MMC3
;
;C = 256K CHR bank.  This selects which 256K PRG superbank is "seen" by 
;    the MMC3
;
;Z = CHR superbank size. 0 = 256K, 1 = 128K
;
;S = PRG superbank size. 0 = 256K, 1 = 128K
;
;U = PRG/CHR superbank 128K half. 0 = lower, 1 = upper             
;
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
             sty 06800h
             ldx #2
             
dump_it2:    lda temp2_lo
             sta 06801h
             lda #00h
             sta temp2_hi
             
dump_it3:    lda #080h
             sta temp1_hi

dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             inc temp1_hi
             lda temp1_hi
             cmp #0a0h
             bne dump_it   ;do 8K
             lda #006h
             sta 08000h
             lda temp2_hi
             sta 08001h
             inc temp2_hi
             lda temp2_hi
             cmp #020h
             bne dump_it3  ;do 256K
             lda #010h
             sta temp2_lo
             dex
             bne dump_it2  ;do 512K
             
             lda #000h
             jsr send_byte
             lda #008h
             jsr send_byte
             lda #002h
             jsr send_byte  ;send CHR header
             
             
             lda #000h
             sta temp3_lo
             lda #002h
             sta temp2_lo
             
dump_chr3:   lda #00h
             sta temp2_hi
             lda temp2_lo
             sta 06801h
             
dump_chr2:   lda #000h
             sta 02006h
             lda #000h
             sta 02006h     ;set PPU address to 0000h
             lda 02007h     ;read garbage byte
             ldx #08h
             ldy #0
             
dump_chr:    lda 02007h
             jsr send_byte
             iny
             bne dump_chr
             dex
             bne dump_chr   ;dump 2K of CHR
             lda #00h
             sta 08000h
             lda temp2_hi
             sta 08001h
             inc temp2_hi
             inc temp2_hi
             bne dump_chr2  ;dump 256K of CHR
             lda #08h
             sta temp3_lo
             dec temp2_lo
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
