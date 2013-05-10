             .title       "Nina-001 Reader Plugin"


;06/18/00 
;Written by KH
;Version 1.0
             
             ;vectors for standard system calls

send_byte:   .equ 0200h
baton:       .equ 0203h
chk_vram:    .equ 0206h
chk_wram:    .equ 0209h
wr_ppu:      .equ 020ch
read_byte:   .equ 020fh
init_crc:    .equ 0212h
do_crc:      .equ 0215h
finish_crc:  .equ 0218h

crc0:        .equ 0080h
crc1:        .equ 0081h
crc2:        .equ 0082h
crc3:        .equ 0083h

temp1:       .equ 00e0h
temp1_lo:    .equ 00e0h
temp1_hi:    .equ 00e1h
temp2:       .equ 00e2h
temp2_lo:    .equ 00e2h
temp2_hi:    .equ 00e3h

temp3:       .equ 00e4h
temp3_lo:    .equ 00e4h
temp3_hi:    .equ 00e5h

temp4:       .equ 00e6h   ;for wr_bank
temp4_lo:    .equ 00e6h
temp4_hi:    .equ 00e7h
temp5:       .equ 00e8h
temp5_lo:    .equ 00e8h
temp5_hi:    .equ 00e9h
x_temp:      .equ 00eah
y_temp:      .equ 00ebh

temp_crc:    .equ 00ech



             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "Nina-001: 64K PRG, " 
             .db "64K CHR, 8K WRAM"
             .db 0

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
             

next_part:   lda #000h
             jsr send_byte
             lda #001h       ;send size
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
             lda #0h
             sta 07ffdh
             jsr do_dump
             lda #01h
             sta 07ffdh
             jsr do_dump    ;send out 64K of PRG ROM

             lda #000h
             jsr send_byte
             lda #001h       ;send size
             jsr send_byte
             lda #002h
             jsr send_byte   ;send PRG 
             
             lda #0h
             sta temp2_lo
             lda #010h
             sta temp2_hi

dchr_1:      lda temp2_lo
             sta 07ffeh
             lda #0h
             tay
             sta 2006h
             sta 2006h
             lda 2007h
             ldx #010h

dchr_2:      lda 2007h
             jsr send_byte
             iny
             bne dchr_2
             jsr baton
             dex
             bne dchr_2
             inc temp2_lo
             dec temp2_hi
             bne dchr_1

             lda #020h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #003h
             jsr send_byte
             
             ldx #020h
             lda #0h
             tay
             sta temp1_lo
             lda #060h
             sta temp1_hi
             
d_wram:      lda (temp1),y
             jsr send_byte
             iny
             bne d_wram
             inc temp1_hi
             dex
             bne d_wram
             
             
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte  ;send end block
             rts


do_dump:     ldy #0
             sty temp1_lo
             lda #080h
             tax
             sta temp1_hi

dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             jsr baton
             inc temp1_hi
             dex
             bne dump_it
             rts


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
