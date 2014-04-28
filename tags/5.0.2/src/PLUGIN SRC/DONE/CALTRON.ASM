             .title        "Caltron Reader Plugin"


;10/29/00 
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
             
             .db "Caltron 6 in 1" 
             .db " single multicart only",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h
             
             lda #04h
             jsr send_byte
             
             
             lda #00h
             jsr send_byte
             lda #04h
             jsr send_byte    ;256K PRG
             lda #01h
             jsr send_byte    ;send header
             
             
             lda #8
             sta temp2_hi
             lda #0
             sta temp2_lo
             
dl_loop:     lda #00h
             sta temp1_lo
             lda #080h
             sta temp1_hi     ;set to 080h
             ldy #0
             ldx temp2_lo
             sta 06000h,x

dl_loop2:    lda (temp1),y 
             jsr send_byte
             iny
             bne dl_loop2
             inc temp1_hi
             bne dl_loop2
             inc temp2_lo
             dec temp2_hi
             bne dl_loop


             lda #000h
             jsr send_byte
             lda #002h
             jsr send_byte
             lda #002h
             jsr send_byte

             
             lda #0
             sta temp2_lo
             lda #010h
             sta temp2_hi
             
             
dc_x:        lda temp2_lo
             jsr wr_bank
             ldx #20h
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
             jsr baton
             dex
             bne dump_chr   ;dump 8K of CHR
             inc temp2_lo
             dec temp2_hi
             bne dc_x
             
             lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte
             rts





wr_bank:     stx x_temp
             sty y_temp
             pha
             and #03h
             sta temp4_lo   ;store desired bank
             pla
             asl a
             ora #04h
             tax
             sta 06000h,x
             lda #0
             sta temp5_lo
             lda #080h
             sta temp5_hi   ;start addr
             ldx #080h      ;# iterations
             ldy #0

wrb_loop:    lda (temp5),y
             and #03h
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
             

