             .title         "RAM Loader Plugin"


;11/13/00 
;Written by KH
;Version 1.0
             
             ;vectors for standard system calls

send_byte:   .equ 0200h
baton:       .equ 0203h
chk_vram:    .equ 0206h
chk_wram:    .equ 0209h
read_byte:   .equ 020fh
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
             
             .db "RAM Loader"
             .db " plugin"

             .fill 0400h-*,00h    ;all plugins must reside at 400h


             lda #0
             sta 04803h       ;input mode
             sta temp1_lo
             sta temp2_lo       ;dual pointers for 16K mode

             lda #080h
             sta temp1_hi
             lda #0c0h
             sta temp2_hi

             jsr read_byte
             ora #00h           ;if 0, it's 32K else it's 16K
             beq mode_32k

mode_16k:    ldy #00h

m16:         jsr read_byte
             sta (temp1),y
             sta (temp2),y
             iny
             bne m16
             inc temp1_hi
             inc temp2_hi
             bne m16
             beq do_chr

mode_32k:    ldy #00h

m32:         jsr read_byte
             sta (temp1),y
             iny
             bne m32
             inc temp1_hi
             bne m32

do_chr:      lda #020h
             sta temp1_lo
             lda #00h
             sta 02006h
             sta 02006h

dc_loop:     jsr read_byte
             sta 02007h
             iny
             bne dc_loop
             dec temp1_lo
             bne dc_loop
             lda #0fch
             sta 04800h
             jmp (0fffch)







             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
