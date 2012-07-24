             .title      "Cheetahmen 2 Reader Plugin"


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
             
             .db "Cheetahmen 2 "
             .db "- 256K PRG, 128K CHR",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             

             lda #04h
             jsr send_byte   ;send byte
             
             lda #000h
             jsr send_byte
             lda #004h       ;send size
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
             lda #0
             sta temp2_lo    ;bankswitch ctr
             ldx #8         

dump_it2:    lda temp2_lo
             jsr wr_pbank
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
             inc temp2_lo
             dex
             bne dump_it2


;determine CHR ROM size (128K)

chronly:             
             lda #000h
             jsr send_byte
             lda #002h
             jsr send_byte
             lda #002h
             jsr send_byte  ;send chr block

             lda #0
             sta temp2_lo    ;bankswitch ctr
             ldx #010h

dump_it3:    lda temp2_lo
             jsr wr_cbank
             lda #020h
             sta temp1_hi
             ldy #0
             sty 2006h
             sty 2006h
             lda 2007h

dump_it4:    lda 2007h
             jsr send_byte
             iny
             bne dump_it4
             jsr baton
             dec temp1_hi
             bne dump_it4
             inc temp2_lo
             dex
             bne dump_it3
             
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte  ;send end block
             rts

;6000h - a0-a2 = prg, a3/a4 = chr 2,3
;8000h wr d0,1 = chr 0,1


wr_pbank:    sta temp4_hi
             lda #020h
             bit temp4_hi    ;test upper bit
             beq no_mod
             lda temp4_hi
             ora #010h
             sta temp4_hi

no_mod:      lda #0h
             sta temp4_lo
             sec
             ror temp4_hi
             ror temp4_lo     ;fix up bank bits
             ldy #0
             sta (temp4),y
             rts

wr_cbank:    pha
             lsr a
             lsr a
             sta temp4_lo
             lda #080h
             sta temp4_hi
             pla
             ldy #0
             sta (temp4),y
             rts





             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
