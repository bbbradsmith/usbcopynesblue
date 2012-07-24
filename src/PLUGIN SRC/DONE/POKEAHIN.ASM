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

;Board Name UNL-8237 
;Cart: Pocahontas 2
;
;Seems to check A15, A14, and A13 for writes.
;
;Registers appear to be at A000-BFFFh (control reg), C000-DFFFh (bank reg),
;and E000-FFFFh for interrupts (possibly?)
;
;
;Register A000h controls the operation of C000h.  In fact, it is almost
;identical with respect to how the MMC3 functions, just the bits are out
;of order some.
;
;A000:
;7       0
;---------
;SM?? ?QQQ
;
;S = Swap upper/lower banks for CHR bank selection
;M = PRG mode.  Instead of the bank being located at 8000h via the Q bits
;    being set to mode #2 it is at C000h. 8000h becomes fixed to the first
;    PRG bank like on the MMC3.
;
;Q = 3 bits which make up the mode of C000h
;
;  0 - Select 2K of CHR at 0000h in PPU space
;  1 - Select 1K of CHR at 1000h in PPU space
;  2 - Select 8K of PRG at 8000h (M=0) or A000h (M=1) in CPU space
;  3 - Select 2K of CHR at 0800h in PPU space
;  4 - Select 8K of PRG at A000h in CPU space
;  5 - Select 1K of CHR at 1400h in PPU space
;  6 - Select 1K of CHR at 1800h in PPU space
;  7 - Select 1K of CHR at 1C00h in PPU space
;
;C000:             
;
;This selects the bank chosen via the Q bits in A000h. 
;             
;Mirroring bits have not been found yet, and IRQ operation is still a
;mystery.
;
;5000:
;
;This is the supermapper control register.
;
;CHR banks are ALWAYS under control of the registers at A000/C000.
;PRG bank control can be handed over from the A000/C000 PRG bank regs
;to 5000h.
;
;When in the A000/C000 (submapper) mode, The PRG space is broken up into
;4 parts depending on mode (just like MMC3).
;
;When in the 5000 (supermapper) mode, the PRG space is either 16K or 32K,
;and the submapper's PRG selects do nothing.
;
;7       0
;---------
;KZEx BBBb
;
; K = Mapper mode. 0 = submapper PRG control, 1 = supermapper PRG control
; Z = PRG/CHR page sizes. 0 = 256K, 1 = 128K
;
;
;these bits are ONLY used when in supermapper PRG control mode:
;
; E = PRG bank size. 0 = 16K, 1 = 32K
;
; B = 32K PRG banks
; b = 16K page (only used if in 16K mode)
;
;5001:
;
;Only bit 2 seems to be used, and it selects a 256K CHR ROM superbank.
;
;5002 through 5007 are used, but for what purpose, I dunno
;
;Writing to 5002 changes mirroring sometimes and CHR bank arrangements too
;but their method of operation is unknown
;

     ;plugin header that describes what it does
             
             .org 0380h
             
             .db "NROM -- 16K and 32K" 
             .db " carts w/ 8K CHR ROM",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             lda #000h
             sta 05000h

             lda #4
             jsr send_byte   ;send byte
             
             lda #000h
             jsr send_byte
             lda #004h       ;send size (256K)
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
             
             ldy #0
             sty temp1_lo
             sty temp2_lo
             
             lda #02h
             sta 0a000h      ;PRG bank @ 8000h

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
             cmp #0a0h
             bne dump_it   ;do 8K
             inc temp2_hi
             lda temp2_hi
             cmp #020h
             bne dump_it3  ;do 256K
             
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
             
dump_chr2:   lda temp2_lo
             sta 05001h
             lda #01h
             sta 0a000h
             lda temp2_hi
             sta 0c000h         ;CHR sel
             lda #010h
             sta 02006h
             lda #000h
             sta 02006h     ;set PPU address to 0000h
             lda 02007h     ;read garbage byte
             ldx #4h
             ldy #0         ;1K
             
dump_chr:    lda 02007h
             jsr send_byte
             iny
             bne dump_chr
             dex
             bne dump_chr   ;dump 1K of CHR
             
             inc temp2_hi
             bne dump_chr2  ;dump 256K of CHR
             
             lda temp2_lo
             clc
             adc #004h
             sta temp2_lo
             cmp #008h
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
