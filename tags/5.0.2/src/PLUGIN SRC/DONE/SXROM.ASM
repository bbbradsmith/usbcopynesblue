             .title        "SxROM Reader Plugin"


;06/15/00 
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
             
             .db "SxROM carts"

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             lda #04h
             jsr send_byte   ;send byte
             
             lda #080h
             sta 0ffffh      ;reset MMC1

             lda #000h
             jsr wr_mmc0     ;8K CHR, 32K PRG

             lda #0
             jsr do_crc2

             ldx #3

sto_crc:     lda crc0,x
             sta temp_crc,x
             dex
             bpl sto_crc     ;store CRC

             lda #2
             jsr do_crc2
             php
             lda #001h
             plp
             beq got_prg
             lda #4
             jsr do_crc2
             php
             lda #002h
             plp
             beq got_prg
             lda #8
             jsr do_crc2
             php
             lda #004h
             plp
             beq got_prg
             lda #8

got_prg:     tay
             sta temp1
             lda #0
             lsr temp1
             ror a
             jsr send_byte
             lda temp1
             jsr send_byte  ;send size
             lda #001h
             jsr send_byte

             sty temp2_lo
             lda #0
             sta temp2_hi


sp_loop1:    lda #0
             sta temp1_lo
             tay
             lda #080h
             sta temp1_hi
             lda temp2_hi
             jsr wr_mmc3

sp_loop2:    lda (temp1),y
             jsr send_byte
             iny
             bne sp_loop2
             jsr baton
             inc temp1_hi
             bne sp_loop2
             inc temp2_hi
             inc temp2_hi
             dec temp2_lo
             bne sp_loop1
             

;pin: 7 - A12 CHR
;     8 - A13 CHR
;     9 - A14 CHR
;    10 - A15 CHR
;    11 - A16 CHR


do_chr:     
             jsr chk_vram
             bne no_ram
             jmp no_chr
             
no_ram:      lda #0
             jsr do_crc3
             ldx #3

sto_crc2:    lda crc0,x
             sta temp_crc,x
             dex
             bpl sto_crc2     ;store CRC

             lda #004h
             jsr do_crc3
             php
             lda #01h
             plp
             beq got_chr
             lda #008h
             jsr do_crc3
             php
             lda #02h
             plp
             beq got_chr
             lda #010h
             jsr do_crc3
             php
             lda #04h
             plp
             beq got_chr
             lda #08h

got_chr:     tay
             sta temp1
             lda #0
             lsr temp1
             ror a
             lsr temp1
             ror a
             jsr send_byte
             lda temp1
             jsr send_byte
             lda #02h
             jsr send_byte
             tya
             asl a     ; # 8K pages

             sta temp2_hi
             lda #0
             sta temp2_lo
             
gc_lp1:      lda temp2_lo
             jsr wr_mmc1
             ldx #020h
             lda #00h
             tay
             sta 2006h
             sta 2006h
             lda 2007h

gc_lp2:      lda 2007h
             jsr send_byte
             iny
             bne gc_lp2
             jsr baton
             dex
             bne gc_lp2
             inc temp2_lo
             inc temp2_lo
             dec temp2_hi
             bne gc_lp1

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
