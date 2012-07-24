             .title         "MWC Reader Plugin"


;03/02/01
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
             
             .db "NWC cart"

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             lda #04h
             jsr send_byte   ;send byte
             
             lda #080h
             sta 0ffffh      ;reset MMC1

             lda #000h
             jsr wr_mmc0     ;8K CHR, 32K PRG

             lda #000h
             jsr wr_mmc1     ;reset lockout
             lda #000h
             jsr wr_mmc2
             lda #010h
             jsr wr_mmc1
             lda #010h
             jsr wr_mmc2
             
             lda #000h
             jsr send_byte
             lda #004h
             jsr send_byte  ;send size
             lda #001h
             jsr send_byte

             lda #4
             sta temp2_lo
             ldy #0
             sty temp2_hi
                         
sp_loop1:    lda #0
             sta temp1_lo
             tay
             lda #080h
             sta temp1_hi
             lda temp2_hi
             asl a
             ora #010h
             pha
             jsr wr_mmc1
             pla
             jsr wr_mmc2   ;select a ROM bank


sp_loop2:    lda (temp1),y
             jsr send_byte
             iny
             bne sp_loop2
             inc temp1_hi
             bne sp_loop2
             inc temp2_hi
             dec temp2_lo
             bne sp_loop1
             lda #018h
             jsr wr_mmc1
             lda #018h
             jsr wr_mmc2

             lda #4
             sta temp2_lo
             ldy #0
             sty temp2_hi
                         
sp_loop1x:   lda #0
             sta temp1_lo
             tay
             lda #080h
             sta temp1_hi
             lda temp2_hi
             asl a
             jsr wr_mmc3

sp_loop2x:   lda (temp1),y
             jsr send_byte
             iny
             bne sp_loop2x
             inc temp1_hi
             bne sp_loop2x
             inc temp2_hi
             dec temp2_lo
             bne sp_loop1x


try_wram:

no_chr:      lda #000h
             jsr wr_mmc3     ;turn RAM enable on (note: MMC1B/C only!!)
             lda #000h
             jsr wr_mmc1     ;set output bit to 0 to turn WRAM on
             jsr chk_wram
             beq yes_wram
             jmp no_wram

yes_wram:    lda 6000h
             sta temp1_lo
             lda #00h
             sta 6000h
             lda #018h
             jsr wr_mmc1
             lda 6000h
             sta temp1_hi
             lda #00h
             sta 6000h
             lda #00h
             jsr wr_mmc1
             lda #069h
             sta 6000h
             lda #018h
             jsr wr_mmc1
             ldy 6000h
             lda temp1_hi
             sta 6000h
             lda #00h
             jsr wr_mmc1
             lda temp1_lo
             sta 6000h
             cpy #069h
             beq ram_8k
             lda #018h
             jsr wr_mmc1
             jsr chk_wram
             bne ram_8k
             
             lda #040h
             jsr send_byte
             lda #0
             jsr send_byte
             lda #3
             jsr send_byte
             lda #00h
             jsr wr_mmc1
             jsr send_ram
             lda #018h
             jsr wr_mmc1
             jsr send_ram
             jmp no_wram
             
ram_8k:      lda #000h
             jsr wr_mmc1
             lda #020h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #003h
             jsr send_byte
             jsr send_ram
             lda #018h
             jsr wr_mmc1

no_wram:     lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte

             rts



send_ram:    ldx #020h
             lda #0
             sta temp1_lo
             tay
             lda #060h
             sta temp1_hi

bw_loop:     lda (temp1),y
             jsr send_byte
             iny
             bne bw_loop
             inc temp1_hi
             dex
             bne bw_loop
             rts


;if CRC of temp_crc matches CRC of current bank, return 0 else return !0             

do_crc2:     jsr wr_mmc3             
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


do_crc3:     jsr wr_mmc1
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
             


wr_mmc0:     sta 09fffh             
             lsr a
             sta 09fffh
             lsr a
             sta 09fffh
             lsr a
             sta 09fffh
             lsr a
             sta 09fffh
             rts
             
wr_mmc1:     pha
             jsr wr_mmc2
             pla
             sta 0bfffh
             lsr a
             sta 0bfffh
             lsr a
             sta 0bfffh
             lsr a
             sta 0bfffh
             lsr a
             sta 0bfffh
             rts
             
wr_mmc2:     sta 0dfffh
             lsr a
             sta 0dfffh
             lsr a
             sta 0dfffh
             lsr a
             sta 0dfffh
             lsr a
             sta 0dfffh
             rts
             
wr_mmc3:     sta 0ffffh             
             lsr a
             sta 0ffffh
             lsr a
             sta 0ffffh
             lsr a
             sta 0ffffh
             lsr a
             sta 0ffffh
             rts
             


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
