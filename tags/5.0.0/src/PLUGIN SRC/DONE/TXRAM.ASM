             .title     "TXROM WRAM Writer Plugin"


;10/23/00 
;Written by KH
;Version 1.0
             
             ;vectors for standard system calls

send_byte:   .equ 0200h
baton:       .equ 0203h
chk_vram:    .equ 0206h
chk_wram:    .equ 0209h
wr_ppu:      .equ 020ch
read_byte:   .equ 020fh

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
             
             .db "TFROM, TGROM, TKROM," 
             .db " TLROM, TSROM\n\r" 
             .db "8K WRAM"
             .db 0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             lda #000h
             sta 04803h   ;input mode

             lda #080h
             sta 0a001h
             
             jsr read_byte
             sta temp2_hi
             lda #0
             sta temp2_lo
             
             sta temp3_lo
             lda #060h
             sta temp3_hi
             ldy #0

sd_loop:     jsr read_byte
             sta (temp3),y
             iny
             bne sd_loop
             inc temp3_hi
             dec temp2_hi
             bne sd_loop

             lda #000h
             sta 0a001h
             
             lda #0ffh
             sta 04803h   ;output mode


             lda #069h
             jsr send_byte
             
             rts

             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
