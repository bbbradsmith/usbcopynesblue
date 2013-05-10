             .title        "Camerica Reader Plugin"


;06/20/00 
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
             
             .db "Camerica - 64K to 256K "
             .db "w/ VRAM",0

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
             
             lda #0
             jsr do_crc2

             ldx #3

sto_crc:     lda crc0,x
             sta temp_crc,x
             dex
             bpl sto_crc     ;store CRC

             lda #4
             jsr do_crc2
             php
             lda #001h
             plp
             beq got_prg     ;64K
             lda #8
             jsr do_crc2
             php
             lda #002h
             plp
             beq got_prg     ;128K
             lda #004h       ;256K


got_prg:     tay
             lda #0
             jsr send_byte
             tya
             jsr send_byte  ;send size
             lda #001h
             jsr send_byte

             tya
             asl a
             asl a
             sta temp2_lo
             lda #0
             sta temp2_hi


sp_loop1:    lda #0
             sta temp1_lo
             tay
             lda #080h
             sta temp1_hi
             lda temp2_hi
             jsr wr_bank

sp_loop2:    lda (temp1),y
             jsr send_byte
             iny
             bne sp_loop2
             jsr baton
             inc temp1_hi
             lda #0c0h
             cmp temp1_hi
             bne sp_loop2
             inc temp2_hi
             dec temp2_lo
             bne sp_loop1
             

             lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte

             rts

;if CRC of temp_crc matches CRC of current bank, return 0 else return !0             

do_crc2:     jsr wr_bank
             lda #0
             tay
             sta temp1_lo
             lda #080h
             sta temp1_hi
             jsr init_crc

gr_loop:     lda (temp1),y
             jsr do_crc
             iny
             bne gr_loop
             inc temp1_hi
             bne gr_loop
             jsr finish_crc
             ldx #3

gd_loop:     lda crc0,x
             cmp temp_crc,x
             bne no_comp
             dex
             bpl gd_loop
             lda #0

no_comp:     rts


wr_bank:     sta 0c000h
             rts

             stx x_temp
             sty y_temp
             sta temp4_lo   ;store desired bank
             lda #0
             sta temp5_lo
             lda #0c0h
             sta temp5_hi   ;start addr
             ldx #040h      ;# iterations
             ldy #0

wrb_loop:    lda (temp5),y
             and #0fh
             cmp temp4_lo   ;check current byte
             beq gotit
             iny
             bne wrb_loop
             inc temp5_hi
             bne wrb_loop   ;keep checking
             lda temp4_lo
             sta 0c000h
             ldx x_temp
             ldy y_temp
             rts            ;if it wasn't found, bag it
             
gotit:       lda (temp5),y             
             sta (temp5),y  ;if we found it, do the switch
             ldx x_temp
             ldy y_temp
             rts
             


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end

