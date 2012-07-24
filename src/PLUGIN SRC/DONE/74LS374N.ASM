             .title        "Sachen Reader Plugin"


;01/24/02 
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


;Board Name: SA-015
;Poker 3 version
;
;compat:         TC-0719
;                
;
;It uses a two write method identical to 74LS374N so read up on it there.
;
;Registers:
;(select at 4100h, data at 4101h)
;
;0 - xxxx xxxx not used
;1 - xxxx xxxx not used
;2 - xxxx xxxx not used
;3 - xxxx xxxx not used
;4 - xxxx xBBB 32K CHR bank for reg 6
;5 - xxxx xPPP 32K PRG bank
;6 - xxxx xxCC 8K CHR bank (of the 32K bank selected by reg 4)
;7 - xxxx xMMx Mirroring:
;           0 - 7
;           1 - 3
;           2 - 5
;           3 - F



             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "Sachen 74LS374N mapper"
             .db " boards"
             .fill 0400h-*,00h    ;all plugins must reside at 400h

             
;check mirroring             

             lda #04h
             jsr send_byte   ;send byte
             
             lda #0
             jsr do_crc2     ;get CRC of first 32K of PRG
             ldx #3

sto_crc:     lda crc0,x
             sta temp_crc,x
             dex
             bpl sto_crc     ;store CRC

             lda #1
             jsr do_crc2
             php
             lda #001h
             plp
             beq got_prg
             lda #2
             
             jsr do_crc2
             php
             lda #002h
             plp
             beq got_prg
             
             lda #4
             jsr do_crc2
             php
             lda #002h
             plp
             beq got_prg
           
             lda #008h

got_prg:     cmp #01h
             beq chk4_16k
             tay
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
             jsr wr_pbank

sp_loop2:    lda (temp1),y
             jsr send_byte
             iny
             bne sp_loop2
             jsr baton
             inc temp1_hi
             bne sp_loop2
             inc temp2_hi
             dec temp2_lo
             bne sp_loop1
             beq do_chrnow

chk4_16k:    lda #000h
             sta temp1_lo
             sta temp2_lo
             tay
             lda #080h
             sta temp1_hi
             lda #0c0h
             sta temp2_hi

cc1:         lda (temp1),y
             cmp (temp2),y
             bne ccx
             iny
             bne cc1
             inc temp1_hi
             inc temp2_hi
             bne cc1
             ldx #040h
             bne ccy

ccx:         ldx #080h

ccy:         txa
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #001h
             jsr send_byte
             lda #080h
             sta temp1_hi
             lda #000h
             sta temp1_lo
             sta temp2_lo
             tay

cc2:         lda (temp1),y
             jsr send_byte 
             iny
             bne cc2
             inc temp1_hi
             dex
             bne cc2             ;send data

;CHR reading             
do_chrnow:   lda #07h         ;mapper CHR mode
             sta 04100h
             lda #01h
             sta 04101h
             
             lda #0
             jsr do_crc3
             ldx #3

sto_crc2:    lda crc0,x
             sta temp_crc,x
             dex
             bpl sto_crc2     ;store CRC

             lda #002h
             jsr do_crc3      ;16K banks
             php
             lda #01h         ;we got 16K 00 40
             plp
             beq got_chr
             
             lda #004h
             jsr do_crc3      ;32K banks
             php
             lda #02h         ;we got 32K 00 80
             plp
             beq got_chr      
             
             lda #008h
             jsr do_crc3      ;64K banks
             php
             lda #04h         ;we got 64K 01 00
             plp
             beq got_chr      
             
             lda #08h         ;we got 128K 02 00

got_chr:     pha
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
             pla
             asl a     ; # 8K pages

             sta temp2_hi
             lda #0
             sta temp2_lo
             
gc_lp1:      lda temp2_lo
             jsr wr_cbank
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
             dex
             bne gc_lp2
             inc temp2_lo
             dec temp2_hi
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
             

;selects a 32K PRG bank

wr_pbank:    pha
             lda #05h
             sta 04100h
             pla
             sta 04101h
             rts

;selects an 8K CHR bank

wr_cbank:    and #0fh
             ldx #04h
             stx 04100h
             pha
             and #0ch
             lsr a
             lsr a
             pha
             and #01h
             sta 04101h   ;middle bit
             ldx #02h
             stx 04100h
             pla
             lsr a
             and #01h
             sta 04101h
             ldx #06h
             stx 04100h
             pla
             and #03h
             sta 04101h   ;lower 2 bits
             rts


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
