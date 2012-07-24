             .title        "11 in 1 Reader Plugin"


;12/08/00 
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
             
             .db "11 in 1 ball " 
             .db "games reader plugin. "
             .db "512K PRG"

             .fill 0400h-*,00h    ;all plugins must reside at 400h
             
;check mirroring             

             lda #04h
             jsr send_byte   ;send byte
             
             
             lda #000h
             jsr send_byte
             lda #008h
             jsr send_byte
             lda #001h
             jsr send_byte
             
             ldx #000h
             lda #012h
             sta 06000h
             
dd_lp:       stx 08000h
             jsr send_prg
             inx
             cpx #010h
             bne dd_lp

             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte
             rts

send_prg:    lda #00h
             sta temp1+0
             tay
             lda #080h
             sta temp1+1    ;c000h

sp_lp:       lda (temp1),y
             jsr send_byte
             iny
             bne sp_lp
             inc temp1+1
             bne sp_lp
             rts


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
