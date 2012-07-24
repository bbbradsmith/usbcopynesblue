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

;Board name: UNL-SA-0036
;
;Writes to 8000h-ffffh determine CHR bank.
;
;7       0
;---------
;Cxxx xxxx
;
;C - select an 8K CHR bank.  Mirroring is fixed.
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
             
        ;     jsr do_crc2
        ;     php
        ;     lda #002h
        ;     plp
        ;     beq got_prg
        ;     
        ;     lda #004h

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

;CHR reading             
             
             lda #0
             jsr do_crc3
             ldx #3

sto_crc2:    lda crc0,x
             sta temp_crc,x
             dex
             bpl sto_crc2     ;store CRC

             lda #002h
             jsr do_crc3
             php
             lda #01h
             plp
             beq got_chr
             lda #004h
             jsr do_crc3
             php
             lda #02h
             plp
             beq got_chr
        ;     lda #008h
        ;     jsr do_crc3
        ;     php
             lda #04h
        ;     plp
        ;     beq got_chr
        ;     lda #08h

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
             jsr baton
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
             


wr_cbank:    ror a
             ror a
             and #080h
             sta temp4_lo
             lda #080h
             sta type
             bne wr_bank

;no PRG banks

wr_pbank:    rts
             asl a
             asl a
             asl a
             sta temp4_lo
             lda #008h
             sta type

wr_bank:     stx x_temp
             sty y_temp
             lda #0
             sta temp5_lo
             lda #080h
             sta temp5_hi   ;start addr
             ldy #0

wrb_loop:    lda (temp5),y
             and type
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
