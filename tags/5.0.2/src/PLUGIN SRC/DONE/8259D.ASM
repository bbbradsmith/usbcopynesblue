             .title    "Colour Dreams, etc Reader Plugin"


;06/17/00 
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

type:        .equ 0088h

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

;Board name: great wall
;
;


             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "Colour Dreams, "
             .db "Bunch Games, AGCI, "
             .db "Wisdom Tree "
             .db "16K-128K PRG/CHR",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             
;check mirroring             

             lda #02h
             jsr send_byte
             
             lda #080h
             jsr send_byte
             lda #00h
             jsr send_byte  ;send size (32K)
             lda #001h
             jsr send_byte

             ldy #0
             sty temp1_lo
             lda #080h
             sta temp1_hi

sp_loop2:    lda (temp1),y
             jsr send_byte
             iny
             bne sp_loop2
             inc temp1_hi
             bmi sp_loop2

             
             lda #080h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #02h
             jsr send_byte
             
             ldx #000h   ;32 1K pages
             stx temp2_lo
             

gc_lp1:      lda temp2_lo
             jsr wr_cbank
             ldx #004h
             ldy #00h
             lda 02002h
             lda #00ch
             sta 2006h
             sty 2006h          ;read from 0c00h-0fffh
             lda 2007h

gc_lp2:      lda 2007h
             jsr send_byte
             iny
             bne gc_lp2
             jsr baton
             dex
             bne gc_lp2
             inc temp2_lo
             lda #020h
             cmp temp2_lo
             bne gc_lp1

endit:       
             lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte

             rts


;if CRC of temp_crc matches CRC of current bank, return 0 else return !0             

do_crc2:     jsr wr_pbank
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


do_crc3:     jsr wr_cbank
             lda #0
             tay
             sta 2006h
             sta 2006h
             lda #020h
             sta temp1_hi
             jsr init_crc
             lda 2007h

gr_loop2:    lda 2007h
             jsr do_crc
             iny
             bne gr_loop2
             dec temp1_hi
             bne gr_loop2
             jsr finish_crc
             ldx #3

gd_loop2:    lda crc0,x
             cmp temp_crc,x
             bne no_comp2
             dex
             bpl gd_loop2
             lda #0

no_comp2:    rts
             
wr_pbank:    asl a
             asl a
             asl a
             
wr_cbank:    ldx #003h
             stx 04100h
             sta 04101h    ;select lower 3 bits
             lsr a
             lsr a
             ldx #004h
             stx 04100h    ;select upper bit
             sta 04101h
             lsr a
             ldx #006h
             stx 04100h    ;select middle bit
             sta 04101h
             rts


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
