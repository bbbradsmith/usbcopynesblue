             .title        "GNROM Reader Plugin"


;01/13/01 
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
             
             .db "GNROM, MHROM "
             .db "Carts\n\r" 
             
             .fill 0400h-*,00h    ;all plugins must reside at 400h

             
             
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
             
             lda #000h       ;get CRC of first bank
             jsr wr_bank
             sta temp1_lo
             lda #080h
             sta temp1_hi
             
             jsr init_crc
             ldy #0

chk_loop:    lda (temp1),y
             jsr do_crc
             iny
             bne chk_loop
             inc temp1_hi
             bne chk_loop   ;CRC all 32K
             jsr finish_crc
             ldx #3

ld_crc:      lda crc0,x
             sta temp_crc,x
             dex
             bpl ld_crc     ;store CRC
             jsr init_crc   ;crc for next block
             lda #010h       ;get CRC of 3rd bank
             jsr wr_bank
             lda #0
             sta temp1_lo
             lda #080h
             sta temp1_hi
             
             jsr init_crc
             ldy #0

chk_loop2:   lda (temp1),y
             jsr do_crc
             iny
             bne chk_loop2
             inc temp1_hi
             bne chk_loop2   ;CRC all 32K
             jsr finish_crc
             ldy #1
             ldx #3

chk_crc:     lda crc0,x             
             cmp temp_crc,x
             bne crc_fail
             dex
             bpl chk_crc
             jmp got_64k

crc_fail:    lda #020h       ;get CRC of 5th bank
             jsr wr_bank
             lda #0
             sta temp1_lo
             lda #080h
             sta temp1_hi
             
             jsr init_crc
             ldy #0

chk_loop3:   lda (temp1),y
             jsr do_crc
             iny
             bne chk_loop3
             inc temp1_hi
             bne chk_loop3   ;CRC all 32K
             jsr finish_crc

             ldy #4
             ldx #3

chk_crc2:    lda crc0,x             
             cmp temp_crc,x
             bne got_64k
             dex
             bpl chk_crc2
             dey             ;if the same, it's 128K else it's 256K
             dey

got_64k:     tya
             lsr a
             pha
             lda #0
             ror a
             jsr send_byte
             pla
             jsr send_byte
             lda #01h
             jsr send_byte   ;send our header

             tya             ; # banks to send
             tax
             lda #0
             sta temp2_lo

send_bank:   lda temp2_lo
             jsr wr_bank      ;set bank
             lda #010h
             clc
             adc temp2_lo
             sta temp2_lo    ;inc bank
             lda #0
             tay
             sta temp1_lo
             lda #080h
             sta temp1_hi

send_blk:    lda (temp1),y
             jsr send_byte
             iny
             bne send_blk
             jsr baton
             inc temp1_hi
             bne send_blk   ;send 32K
             dex
             bne send_bank

             
;determine CHR ROM size (16K or 32K)             

             lda #0
             jsr wr_bank   ;first bank of gfx
             lda #0
             jsr wr_ppu
             jsr init_crc  ;init crc
             lda 2007h

             lda #020h     ;8K worth of data
             sta temp1_lo
             ldy #0

qck_loop:     lda 2007h
             jsr do_crc
             iny
             bne qck_loop
             dec temp1_lo
             bne qck_loop   ;do all 8K
             
             jsr finish_crc
             ldx #3

qld_crc:      lda crc0,x
             sta temp_crc,x
             dex
             bpl qld_crc     ;store CRC
             jsr init_crc   ;crc for next block
             
             
             lda #002h       ;get CRC of 3rd bank
             jsr wr_bank
             lda #0
             jsr wr_ppu
             jsr init_crc  ;init crc
             lda 2007h

             lda #020h     ;8K worth of data
             sta temp1_lo
             ldy #0

qck_loop2:    lda 2007h
             jsr do_crc
             iny
             bne qck_loop2
             dec temp1_lo
             bne qck_loop2   ;do all 8K
             jsr finish_crc
             
             ldy #080h
             ldx #3

qchk_crc:     lda crc0,x             
             cmp temp_crc,x
             bne qcrc_fail
             dex
             bpl qchk_crc
             ldy #040h
             bne qcrc_dne

qcrc_fail:    ldx #03        ;if it thinks it's 32K check for signature of
             
qcrc_fl:      lda crc0,x    ;open PPU bus
             cmp magic,x
             bne qcrc_dne
             dex
             bpl qcrc_fl
             ldy #040h

qcrc_dne:     tya
             jsr send_byte
             lda #0
             jsr send_byte
             lda #02h
             jsr send_byte   ;send our header

             ; 80,40 -> 4,2

             tya
             lsr a
             lsr a
             lsr a
             lsr a
             lsr a
             tax
             lda #0
             sta temp2_lo

qsend_bank:   lda temp2_lo
             jsr wr_bank      ;set bank
             inc temp2_lo
             lda #0
             jsr wr_ppu
             lda 2007h
             lda #020h
             sta temp1_hi
             ldy #0

qsend_blk:    lda 2007h
             jsr send_byte
             iny
             bne qsend_blk
             jsr baton
             dec temp1_hi
             bne qsend_blk   ;send 32K
             dex
             bne qsend_bank
             
             
             
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte  ;send end block
             rts

wr_bank:     stx x_temp
             sty y_temp
             sta temp4_lo   ;store desired bank
             lda #0
             sta temp5_lo
             lda #080h
             sta temp5_hi   ;start addr
             ldx #080h      ;# iterations
             ldy #0

wrb_loop:    lda (temp5),y
             and #033h
             cmp temp4_lo   ;check current byte
             beq gotit
             iny
             bne wrb_loop
             inc temp5_hi
             bne wrb_loop   ;keep checking
             lda temp4_lo
             sta 08000h     ;can't be found? try anyways
             ldx x_temp
             ldy y_temp
             rts            ;if it wasn't found, bag it
             
gotit:       lda (temp5),y             
             sta (temp5),y  ;if we found it, do the switch
             ldx x_temp
             ldy y_temp
             rts

magic:       .db 007h,053h,067h,0b6h

             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
