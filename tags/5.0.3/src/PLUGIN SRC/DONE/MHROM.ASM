             .title       "NES-MH Reader Plugin"


;06/19/00 
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
             
             .db "MHROM, for SMB/DH" 
             .db " 64K PRG, 16K CHR"
             .db "",0

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
             
             lda #00h
             jsr send_byte
             lda #001h       ;send size
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
             lda #0h
             jsr wr_bank
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
             bne dump_it
             
             lda #010h
             jsr wr_bank
             ldy #0
             sty temp1_lo
             lda #080h
             sta temp1_hi

dump_it2:    lda (temp1),y
             jsr send_byte
             iny
             bne dump_it2
             jsr baton
             inc temp1_hi
             bne dump_it2

;determine CHR ROM size (16K)

             lda #0
             jsr wr_bank   ;first bank of gfx
             lda #0
             jsr wr_ppu

             lda #040h
             jsr send_byte
             lda #0
             jsr send_byte
             lda #02h
             jsr send_byte   ;send our header

             lda #0
             tay
             jsr wr_ppu
             lda 2007h
             ldx #020h

send_blk:    lda 2007h
             jsr send_byte
             iny
             bne send_blk
             jsr baton
             dex
             bne send_blk   ;send 32K
             
             lda #001h
             jsr wr_bank   ;second bank of gfx
             lda #0
             jsr wr_ppu
             
             lda #0
             tay
             jsr wr_ppu
             lda 2007h
             ldx #020h

send_blk2:   lda 2007h
             jsr send_byte
             iny
             bne send_blk2
             jsr baton
             dex
             bne send_blk2   ;send 32K

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


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
