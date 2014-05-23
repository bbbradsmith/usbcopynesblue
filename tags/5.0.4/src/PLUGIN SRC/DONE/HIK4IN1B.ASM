             .title        "BMC-1995SuperHik4in1 Reader Plugin"


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
             
             .db "BMC-1995SuperHik4in1"
             .db "\n\r",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             ldx #04h

got_mir:     txa
             jsr send_byte
             
             lda #0
             sta 0821bh
             sta 06004h
             sta 07006h
             lda #09h
             sta 07001h
             lda #000h
             sta 06004h
             sta 07006h
             lda #0bdh
             sta 06000h
             sta 06001h
             

             lda #0
             sta 06004h
             sta 0821dh
             
 ;            lda #0fch
 ;            sta 04800h   ;disable copyNES
 ;            jmp 0c106h
             
;    jmp do_chr
             
             lda #000h
             jsr send_byte
             lda #008h
             jsr send_byte
             lda #001h
             jsr send_byte
             
             lda #0
             sta temp2_hi

db:          lda temp2_hi
             asl a
             tax
             sta 08000h,x
             lda #000h
             sta temp2_lo

ds:          lda temp2_lo             
             sta 07000h
             lda #000h
             sta temp1_lo
             tay
             lda #080h
             sta temp1_hi
             ldx #040h

dd:          lda (temp1),y
             jsr send_byte
             iny
             bne dd
             inc temp1_hi
             dex
             bne dd
             
             inc temp2_lo
             lda temp2_lo
             cmp #008h
             bne ds
             
             inc temp2_hi
             lda temp2_hi
             cmp #004h
             bne db

;do CHR
do_chr:             

             lda #000h
             jsr send_byte
             lda #008h
             jsr send_byte
             lda #002h
             jsr send_byte

             lda #0
             sta temp2_hi

db2:         lda temp2_hi
             asl a
             tax
             sta 08000h,x
             lda #080h
             sta temp2_lo

ds2:         lda temp2_lo             
             sta 06000h
             lda #000h
             sta temp1_lo
             tay
             ldx #008h
             lda #00h
             sta 02006h
             sta 02006h
             lda 02007h

dd2:         lda 02007h
             jsr send_byte
             iny
             bne dd2
             dex
             bne dd2
             
             inc temp2_lo
             lda temp2_lo
             cmp #0c0h
             bne ds2
             
             inc temp2_hi
             lda temp2_hi
             cmp #004h
             bne db2







             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte
             rts


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
