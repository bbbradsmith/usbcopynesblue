             .title        "4 in 1 Reader Plugin"


;12/07/00 
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
             
             .db "Pirate 4 in 1 plugin. "
             .db "512K CHR, 512K PRG, "
             .db "pirate MMC3",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h
             
             lda #04h
             jsr send_byte
             
             
; 001h game 0            
; 041h game 1
; 081h game 2
; 0C1h game 3
             
             lda #000h
             jsr send_byte
             lda #008h
             jsr send_byte
             lda #001h
             jsr send_byte
             
             lda #080h
             sta 0a001h

             lda #001h
             sta 06000h
             lda #010h
             jsr send_prg
             lda #041h
             sta 06000h
             lda #010h
             jsr send_prg
             lda #081h
             sta 06000h
             lda #010h
             jsr send_prg
             lda #0c1h
             sta 06000h
             lda #010h
             jsr send_prg


;read CHR stuff             
             
do_chr:      
             lda #000h
             jsr send_byte
             lda #008h
             jsr send_byte
             lda #002h
             jsr send_byte
             
             lda #001h
             sta 06000h
             lda #080h
             jsr send_chr
             lda #041h
             sta 06000h
             lda #080h
             jsr send_chr
             lda #081h
             sta 06000h
             lda #080h
             jsr send_chr
             lda #0c1h
             sta 06000h
             lda #080h
             jsr send_chr

      
             lda #0
             jsr send_byte
             lda #0
             jsr send_byte
             lda #0
             jsr send_byte

             rts









send_prg:    sta temp3_lo
             lda #0
             sta temp3_hi


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
             jsr baton
             dex
             bne send_plp2    ;send 8K bank
             dec temp3_lo
             bne send_plp
             
             rts



send_chr:    sta temp3_lo
             lda #0
             sta temp3_hi


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

             rts

             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
