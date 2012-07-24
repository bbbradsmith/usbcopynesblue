             .title      "NINA-03/06 Reader Plugin"


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
             
             .db "Nina-03/06 : " 
             .db "16K-64K PRG, "
             .db "16K-64K CHR"
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
             
             lda #000h       ;determine if this is a 16K or 32K game
             sta temp1_lo
             sta temp2_lo
             lda #080h
             sta temp1_hi
             lda #0c0h
             sta temp2_hi
             
             ldx #040h
             ldy #0

chk_loop:    lda (temp1),y
             cmp (temp2),y
             bne not_16k
             iny
             bne chk_loop
             inc temp1_hi
             inc temp2_hi
             dex
             bne chk_loop
             ldx #040h
             txa
             jsr send_byte
             lda #000h       ;send size
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             ldy #0
             sty temp1_lo
             lda #080h
             sta temp1_hi

dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             jsr baton
             inc temp1_hi
             dex
             bne dump_it
             jmp next_part

not_16k:     lda #0
             jsr wr_bank
             jsr init_crc
             lda #080h
             sta temp1_hi
             lda #00h
             sta temp1_lo
             tay

n16_loop2:   lda (temp1),y
             jsr do_crc
             iny
             bne n16_loop2
             inc temp1_hi
             bne n16_loop2
             jsr finish_crc
             ldx #3

ld_crc2:     lda crc0,x
             sta temp_crc,x
             dex
             bpl ld_crc2     ;store CRC
             lda #08h
             jsr wr_bank
             jsr init_crc
             lda #080h
             sta temp1_hi
             lda #00h
             sta temp1_lo
             tay

n16_loop:    lda (temp1),y
             jsr do_crc
             iny
             bne n16_loop
             inc temp1_hi
             bne n16_loop
             jsr finish_crc

             ldx #3
             ldy #080h

chk_crc2:    lda crc0,x             
             cmp temp_crc,x
             bne crc_fail2
             dex
             bpl chk_crc2
             ldy #040h

crc_fail2:   tya
             asl a
             php
             jsr send_byte
             lda #0
             plp
             rol a
             jsr send_byte
             lda #01h
             jsr send_byte

             
             tya
             clc
                    ;80,40
             rol a  ;0,80
             rol a  ;1,0
             rol a  ;2,1
             sta temp2_lo
             lda #0
             sta temp2_hi
             
crf_loop:    lda #0
             tay
             sta temp1_lo
             lda #080h
             sta temp1_hi
             lda temp2_hi
             asl a
             asl a
             asl a
             jsr wr_bank     ;write 0 or 8h

crf2_loop:   lda (temp1),y
             jsr send_byte
             iny
             bne crf2_loop
             jsr baton
             inc temp1_hi
             bne crf2_loop
             inc temp2_hi
             dec temp2_lo
             bne crf_loop

;determine CHR ROM size (16,32, or 64K)

next_part:   lda #0
             jsr try_crc
             ldx #3

ld_crc:      lda crc0,x
             sta temp_crc,x
             dex
             bpl ld_crc     ;store CRC
             
             lda #002h       ;get CRC of 3rd bank
             jsr try_crc
             php
             lda #020h
             plp
             beq got_it
             lda #04h
             jsr try_crc
             php
             lda #040h
             plp
             beq got_it
             lda #080h

got_it:      pha
             asl a
             php
             jsr send_byte
             lda #0
             plp
             rol a
             jsr send_byte
             lda #02h
             jsr send_byte   ;send our header
             pla     ;20,40,80 for 16K,32K,64K

             lsr a
             lsr a
             lsr a
             lsr a
             tax
             lda #0
             sta temp2_lo

send_bank:   lda temp2_lo
             jsr wr_bank      ;set bank
             inc temp2_lo
             lda #0
             jsr wr_ppu
             lda 2007h
             lda #020h
             sta temp1_hi
             ldy #0

send_blk:    lda 2007h
             jsr send_byte
             iny
             bne send_blk
             jsr baton
             dec temp1_hi
             bne send_blk 
             dex
             bne send_bank

             
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte  ;send end block
             rts

;note, bank counting is weird.
;4100-41FF, 4300-43FF, 4500-45FF ... 5F00-5FFF

;bits 0-2 = CHR bank, bit 3 = PRG bank, bits 4,5 = lockout defeat

wr_bank:     sta 04100h
             rts

try_crc:     jsr wr_bank
             lda #0
             jsr wr_ppu
             jsr init_crc  ;init crc
             lda 2007h

             ldx #020h     ;8K worth of data
             ldy #0

ck_loop2:    lda 2007h
             jsr do_crc
             iny
             bne ck_loop2
             dex
             bne ck_loop2   ;do all 8K
             jsr finish_crc
             ldx #3

chk_crc:     lda crc0,x             
             cmp temp_crc,x
             bne crc_fail
             dex
             bpl chk_crc
             lda #0

crc_fail:    rts             
             


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
