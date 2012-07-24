         .title        "Powerjoy cart Reader Plugin"


;06/11/00 
;Written by KH
;Version 1.0
             
             ;vectors for standard system calls

send_byte:   .equ 0200h
baton:       .equ 0203h
chk_vram:    .equ 0206h
chk_wram:    .equ 0209h
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
temp4:       .equ 00e6h
romsiz:      .equ 00e7h
curr_bank:   .equ 00e8h

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "Power Joy cart thingy\n\r",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             lda #00h
             sta 0a000h

             ldx #02fh
             
ddloop:      txa
             jsr wr_ppu
             lda #0
             sta 2007h
             dex
             cpx #01fh
             bne ddloop   ;load first byte of 2000, 2400, 2800, 2c00 w/ 00h
             ldx #0       ;H mirroring
             lda #020h
             jsr wr_ppu
             lda #055h
             sta 2007h
             lda #028h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #055h
             beq mirrord
             inx          ;V mirroring
             lda #024h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #055h
             beq mirrord
             inx          ;4 screen
             bne got_mir
             
mirrord:     lda #01h
             sta 0a000h
             lda #024h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #055h
             bne got_mir
             lda #00h
             sta 0a000h
             lda #028h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #055h
             bne got_mir  ;test for MMC3 mirror control
             ldx #04h

got_mir:     txa
             jsr send_byte
             
             lda #000h
             sta 06003h     ;reset metamapper
             
          ;   jmp chr_only
             
             lda #00h
             jsr send_byte
             lda #020h
             jsr send_byte
             lda #001h
             jsr send_byte    ;2Mbytes of PRG
             
             lda #000h
         .db 02ch
send_para:   lda #010h
             sta romsiz     ;starting bank #

send_meta:   lda romsiz 
             sta 06000h
             
             lda #00h
             sta temp3_hi
             lda #020h
             sta temp3_lo    ;# 8K banks

send_plp:    lda #6
             sta 08000h
             lda temp3_hi
             sta 08001h
             inc temp3_hi
             lda #0
             sta temp1_lo
             lda #080h
             sta temp1_hi
             ldx #020h
             ldy #0

send_plp2:   lda (temp1),y
             jsr send_byte
             iny
             bne send_plp2
             inc temp1_hi
             dex
             bne send_plp2    ;send 8K bank
             dec temp3_lo
             bne send_plp
             inc romsiz
             inc romsiz
             lda romsiz
             and #008h
             beq send_meta
             lda romsiz
             and #010h
             beq send_para   ;do 1Mbyte bank

             
chr_only:    lda #00h
             jsr send_byte
             lda #010h
             jsr send_byte
             lda #002h
             jsr send_byte    ;1Mbytes of CHR

             lda #000h
         .db 02ch
para_2:      lda #010h
             sta romsiz
             
meta_2:      lda romsiz
             sta 06000h

             lda #00h
             sta temp3_hi
             lda #000h
             sta temp3_lo    ;# 1K banks
             
send_plp3:   lda #082h
             sta 08000h
             lda temp3_hi
             sta 08001h      ;current bank
             lda #00h
             jsr wr_ppu
             lda 2007h      ;set up PPU
             ldy #0
             ldx #4

send_plp4:   lda 2007h
             jsr send_byte
             iny
             bne send_plp4
             jsr baton
             dex
             bne send_plp4
             inc temp3_hi
             dec temp3_lo
             bne send_plp3
             lda #020h
             adc romsiz
             sta romsiz
             and #040h
             beq meta_2
             lda romsiz
             and #010h
             beq para_2

             lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte    ;end of dumping
             
             rts


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
