             .title      "BMC-9999999 in 1 Reader Plugin"


;01/2/01 
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
temp4_lo:    .equ 00e6h
temp4_hi     .equ 00e7h
temp5:       .equ 00e8h
temp5_lo:    .equ 00e8h
temp5_hi     .equ 00e9h
romsiz:      .equ 00eah
curr_bank:   .equ 00ebh
x_temp:      .equ 00ech
y_temp:      .equ 00edh

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "BMC-9999999in1"
             .db "\n\r",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

;check mirroring             

             
             
             ldx #00h
             
             lda #020h
             jsr wr_ppu
             lda #055h
             sta 2007h
             lda #0aah
             sta 2007h
             lda #024h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #055h
             bne horz_mir
             lda 2007h
             cmp #0aah
             bne horz_mir
             lda #020h
             jsr wr_ppu
             lda #0aah
             sta 2007h
             lda #024h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #0aah
             bne horz_mir
             inx

horz_mir:    txa
             jsr send_byte   ;send byte
             
             lda #000h
             jsr send_byte
             lda #002h
             jsr send_byte
             lda #001h
             jsr send_byte   ;128K PRG

             lda #000h
             sta temp2

sb:          lda temp2
             tax
             sta 08000h,x
             lda #000h
             sta temp1_lo
             tay
             lda #080h
             sta temp1_hi

sd:          lda (temp1),y
             jsr send_byte
             iny
             bne sd
             inc temp1_hi
             bne sd
             inc temp2
             lda temp2
             cmp #04h
             bne sb

             lda #000h
             jsr send_byte
             lda #001h
             jsr send_byte
             lda #002h
             jsr send_byte   ;64K CHR

             lda #000h
             sta temp2

sc:          lda temp2
             tax
             sta 08000h,x

             ldx #020h
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

             inc temp2
             lda temp2
             cmp #08h
             bne sc

             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte
             rts

             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end

