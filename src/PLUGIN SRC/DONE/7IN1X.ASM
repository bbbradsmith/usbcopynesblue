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

;board: 
;ines: 130
;responds to writes at the following addresses:
;
;A000-BFFF - CHR register 0
;C000-DFFF - CHR register 1
;E000-FFFF - control register

;the CHR registers hold the PRG bank as well.  This
;means that the code must set both sets of PRG banks
;to the same value, or else the thing will crash due to
;the PPU swapping the banks out!

;7  bit  0
;---------
;CCCC CPPZ
;
;C - 4K CHR bank
;O - 32K PRG bank
;Z - force lower 16K bank to be the same as the upper 16K
;

;The control word is pretty simple:
;
;7  bit  0
;---------
;xxxx FMBB
;
;B - 128K CHR/PRG bank.  Selects a 128K bank for both.  This cart
;    has 512K of PRG and 512K of CHR.
;
;M - mirroring.  0 = V, 1 = H
;
;F - Force bank.  0 = PRG operates normally.  1 = last 16K of PRG is
;set to the last 16K of the selected 128K sub bank.
;

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "NROM -- 16K and 32K" 
             .db " carts w/ 8K CHR ROM",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             
;check mirroring             

             lda #000h
             sta 0a000h
             sta 0c000h
             sta 0e000h


             lda #04h
             jsr send_byte   ;send byte
             
             lda #000h
             jsr send_byte
             lda #008h       ;send size (512K)
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
             lda #0
             sta temp2_lo    ;bank ctr
             lda #010h
             sta temp2_hi
             
dump_it2:    lda temp2_lo
             lsr a
             lsr a
             and #03h
             ora #08h
             sta 0e000h   ;select 128K bank
             lda temp2_lo
             and #03h
             asl a
             sta 0a000h
             sta 0c000h   ;select 32K bank
             ldy #0
             sty temp1_lo
             
             lda #080h
             sta temp1_hi

dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it    ;256 bytes
             inc temp1_hi
             bne dump_it    ;32K
             inc temp2_lo
             dec temp2_hi
             bne dump_it2   ;512K
             
             
             lda #000h
             jsr send_byte
             lda #008h
             jsr send_byte
             lda #002h
             jsr send_byte  ;send CHR header
             
             
             lda #0
             sta temp2_lo    ;bank ctr
             lda #080h
             sta temp2_hi
             

dump_chr2:   lda temp2_lo
             lsr a
             lsr a
             lsr a
             lsr a
             lsr a
             and #003h
             sta 0e000h
             lda temp2_lo
             asl a
             asl a
             asl a
             sta 0a000h
             sta 0c000h

             ldx #010h
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
