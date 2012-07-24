             .title        "HKROM WRAM Reader Plugin"


;10/23/00 
;Written by KH
;Version 1.0
;copy of MMC3 reader  w/mods


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
             
             .db "HKROM " 
             .db "1K WRAM",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             lda #00h
             sta 0a000h

             lda #00h
             jsr send_byte

             lda #030h
             sta 0a001h
             lda #067h
             sta 08000h
             lda #017h
             sta 08001h
             lda #00h
             sta 0a001h
             lda #0b0h    ;30,b0,f0
             sta 0a001h
             
             lda #004h
             tax
             jsr send_byte
             lda #0
             jsr send_byte
             lda #3
             jsr send_byte
             lda #0
             sta temp1_lo
             tay
             lda #070h
             sta temp1_hi
            
sr_lp:       lda (temp1),y
             jsr send_byte
             iny
             bne sr_lp
             inc temp1_hi
             jsr baton
             dex
             bne sr_lp
             lda #030h
             sta 0a001h
             

no_ram2:     lda #0
             jsr send_byte
             lda #0
             jsr send_byte
             lda #0
             jsr send_byte

             rts

             .fill 0800h-*,0ffh

             .end
