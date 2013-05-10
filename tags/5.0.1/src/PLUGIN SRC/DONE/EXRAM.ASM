             .title        "ExROM WRAM Writer Plugin"


;10/23/00 
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

romsiz:      .equ 00f0h
curr_bank:   .equ 0084h

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "ELROM, ETROM, EWROM" 
             .db "\n\r 8K-64K WRAM" 

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             lda #000h
             sta 04803h   ;input mode
             
             jsr read_byte
             

             lda #03h
             sta 05100h      ;PRG page size 8K
             sta 05101h      ;CHR page size 1K
             

;check for save-game RAM and back it up if it exists             

;5113 bits:

;
;0 - bank bit 0            (8K and 16K, these don't do anything)
;1 - bank bit 1
;2 - RAM (0=RAM0, 1=RAM1)  (single RAMs use RAM0 slot only)


try_wram:    lda #00h
             sta 5113h      ;try to see if RAM exists
             lda #02h
             sta 5102h
             lda #01h
             sta 5103h      ;enable RAM writing

             jsr chk_wram
             beq got_ram
             jmp no_ram2

got_ram:     ldy #1
             
cg_loop:     ldx #3
             
cg_ram:      tya
             asl a
             asl a
             sta temp2
             txa
             adc temp2
             sta 5113h      ;store current bank
             lda 6000h
             sta temp3,x
             lda #0h
             sta 6000h      ;clear bytes
             dex
             bpl cg_ram     ;save all 8 bytes
             
             lda #069h
             sta 6000h      ;already at bank 0... store marker
             lda 6000h
             cmp #069h
             php
             lda #000h
             plp
             bne got_32k    ;if no RAM, then set to 0
             lda #1
             clc
             adc temp2
             sta 5113h      ;check for 8K of RAM
             lda 6000h
             cmp #069h
             beq got_8k
             lda #2
             clc
             adc temp2
             sta 5113h
             lda 6000h
             cmp #069h
             beq got_16k
             lda #080h      ;32K
             bne got_32k

got_8k:      lda #020h
             bne got_32k

got_16k:     lda #040h

got_32k:     sta temp1,y
             ldx #3

cg_ram2:     tya
             asl a
             asl a
             sta temp2
             txa
             adc temp2
             sta 5113h
             lda temp3,x
             sta 6000h
             dex
             bpl cg_ram2    ;fix the damage we did to RAM
             dey
             bpl cg_loop

;temp1_lo = # of bytes for lower RAM
;temp1_hi = # of bytes for upper RAM
             
             lda temp1_lo
             clc
             adc temp1_hi   ;get total # of RAM bytes
             php
      ;       jsr send_byte
             lda #0
             plp
             rol a
      ;       jsr send_byte  ;upper bit
             lda #03h
      ;       jsr send_byte
             
             
             lsr temp1_lo
             lsr temp1_lo
             lsr temp1_lo
             lsr temp1_lo
             lsr temp1_lo   ;get raw # of pages
             
             lsr temp1_hi
             lsr temp1_hi
             lsr temp1_hi
             lsr temp1_hi
             lsr temp1_hi   ;get raw # of pages
             ldx #0

s1_loop:     dec temp1,x
             lda #0ffh
             cmp temp1,x
             beq r_done
             txa
             asl a
             asl a
             adc temp1,x
             sta 5113h      ;get current bank
             lda #0
             sta temp2_lo
             tay
             lda #060h
             sta temp2_hi

s2_loop:     txa
             pha
             jsr read_byte
             sta (temp2),y
             pla
             tax
             iny
             bne s2_loop
             inc temp2_hi
             lda #080h
             cmp temp2_hi
             bne s2_loop
             beq s1_loop
             
r_done:      inx
             cpx #2
             bne s1_loop




no_ram2:     lda #0
             sta 5102h
             sta 5103h  ;disable RAM writing


             
             lda #0ffh
             sta 04803h   ;output mode


             lda #069h
             jsr send_byte
             
             rts

             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
