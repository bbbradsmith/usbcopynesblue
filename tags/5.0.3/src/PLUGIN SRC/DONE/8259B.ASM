             .title        "Sachen Reader Plugin"


;02/03/01 
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

;Board name: UNL-Sachen-8259B
;iNES:       none
;compat:         TC-025
;                
;
;It uses a two write method identical to 74LS374N so read up on it there.
;
;Registers:
;(select at 4100h, data at 4101h)
;
;0 - xxxx xccc Select a 2K CHR bank at 0000h in PPU space
;1 - xxxx xddd Select a 2K CHR bank at 0800h in PPU space
;2 - xxxx xeee Select a 2K CHR bank at 1000h in PPU space
;3 - xxxx xfff Select a 2K CHR bank at 1800h in PPU space
;4 - xxxx xBBB 32K CHR bank for regs 0-3
;5 - xxxx xPPP 32K PRG bank
;6 - xxxx x??? dunno, not used?
;7 - xxxx xMMx Mirroring:
;           0 - 7
;           1 - 3
;           2 - 5
;           3 - F
;
;CHR banks are somewhat strange. Use this bit order to select a 2K CHR 
;page from the CHR ROM space:
;
; for 0000h: 00BB Bccc
;     0800h: 00BB Bddd
;     1000h: 00BB Beee
;     1800h: 00BB Bfff
;
;thanks to Quietust for code/implementation

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "NROM -- 16K and 32K" 
             .db " carts w/ 8K CHR ROM",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             

             lda #04h
             jsr send_byte   ;send byte
             
             lda #07h
             sta 04100h
             lda #04h
             sta 04101h

   ;jmp skippr

             lda #0
             jsr crc_pbank
             ldx #3

ld_crc:      lda crc0,x
             sta temp_crc,x
             dex
             bpl ld_crc     ;store CRC of 2nd 32K

             lda #0
             sta temp3
             lda #1
             jsr crc_pbank
             beq got_it
             lda #1
             sta temp3
             lda #2
             jsr crc_pbank
             beq got_it
             lda #4
             asl temp3
             jsr crc_pbank
             beq got_it
             asl temp3

got_it:      lda #000h
             ldx temp3
             beq chk4_16k
          ;   bne got_it2     ;if 0, 32K
          ;   lda #080h
          ;   sta temp3

got_it2:     jsr send_byte
             lda temp3       ;send size
             and #07fh
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             lda temp3
             rol a
             rol temp3       ;mul by 2
             lda #00h
             sta temp2_hi

di2:         lda #000h
             sta temp1_lo
             tay
             lda #080h
             sta temp1_hi
             
             lda #05h
             sta 04100h
             lda temp2_hi
             sta 04101h
             
dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             jsr baton
             inc temp1_hi
             bne dump_it
             inc temp2_hi
             lda temp2_hi
             cmp temp3        ;for ROM size
             bne di2
             beq skippr

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


             
skippr:      lda #00h       
             jsr crc_cbank   ;CRC first bank
             ldx #3

ld_crca:     lda crc0,x
             sta temp_crc,x
             dex
             bpl ld_crca     ;store CRC of 2nd 32K
             
             lda #040h
             sta temp2_lo
             
             lda #02h
             jsr crc_cbank
             beq got_itc
             lda temp2_lo
             rol a
             rol temp2_lo
             lda #04h
             jsr crc_cbank
             beq got_itc
             lda temp2_lo
             rol a
             rol temp2_lo
             lda #08h
             jsr crc_cbank
             beq got_itc
         ;    asl temp2_lo
         ;    lda #010h
         ;    jsr crc_cbank
         ;    beq got_itc    max of only 128K on this one
             asl temp2_lo

got_itc:     lda #0c0h
             and temp2_lo
             jsr send_byte
             lda temp2_lo
             and #03fh
             jsr send_byte
             lda #002h
             jsr send_byte  ;send CHR header
             lda temp2_lo
             rol a
             rol temp2_lo
             lda temp2_lo
             rol a
             rol temp2_lo
             asl temp2_lo   ;fix for count loop
             
             ldy #000h
             sty temp2_hi   ;1st bank
             


di3:      ;   ldx #00h
          ;   stx 04100h
          ;   lda temp2_hi
          ;   asl a
          ;   sta 04101h     ;3 bits
          ;   inx
          ;   stx 04100h
          ;   sta 04101h
          ;   inx
          ;   stx 04100h
          ;   ora #01h
          ;   sta 04101h
          ;   inx
          ;   stx 04100h
          ;   sta 04101h
          ;   
          ;   lda temp2_hi
          ;   lsr a
          ;   lsr a
          ;   ldx #04h
          ;   stx 04100h
          ;   sta 04101h
             

             lda temp2_hi
             jsr set_cbank
             
             lda #000h
             sta 02006h
             lda #000h
             sta 02006h     ;set PPU address to 0000h
             lda 02007h     ;read garbage byte
             ldy #0


             ldx #020h
             
dump_chr:    lda 02007h
             jsr send_byte
             iny
             bne dump_chr
             dex
             bne dump_chr   ;dump 8K of CHR
             inc temp2_hi
             lda temp2_hi
             cmp temp2_lo
             bne di3

             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             rts            ;done 


;returns Z flag set if CRC's match, !0 if not

crc_pbank:   ldx #05h
             stx 04100h
             sta 04101h      ;set bank
             jsr init_crc
             lda #00h
             sta temp1_lo
             lda #080h
             sta temp1_hi    ;32K worth
             
dsw1:        ldy #0
             lda (temp1),y
             jsr do_crc
             inc temp1_lo
             bne dsw1
             inc temp1_hi
             bne dsw1        ;32K 
             jsr finish_crc
             ldx #3

chk_crc:     lda crc0,x             
             cmp temp_crc,x
             bne crc_fail
             dex
             bpl chk_crc
             lda #0

crc_fail:    rts


;
; 
;
;
;
;

set_cbank:   pha
             and #01h
             asl a
             asl a
             tay
             ldx #00h
             stx 04100h
             sty 04101h
             inx
             iny
             stx 04100h
             sty 04101h    ;set CHR bank 0
             inx
             iny
             stx 04100h
             sty 04101h
             inx
             iny
             stx 04100h
             sty 04101h    ;set CHR bank 1
             pla
             lsr a
             inx 
             stx 04100h
             sta 04101h    ;set big bank
             rts


;checks bank w/ stored crc
crc_cbank:   sta temp3
             jsr init_crc
             
crc_cc:      lda temp3
             jsr set_cbank
             lda #00h
             sta 02006h
             sta 02006h
             sta temp1_lo
             lda #020h
             sta temp1_hi
             lda 02007h

crcds:       lda 02007h
             jsr do_crc
             inc temp1_lo
             bne crcds
             dec temp1_hi
             bne crcds
             inc temp3
             lda temp3
             and #01h      ;was 3
             bne crc_cc       ;do 32K worth
             jsr finish_crc

             ldx #3

chk_crc2:    lda crc0,x             
             cmp temp_crc,x
             bne crc_fail2
             dex
             bpl chk_crc2
             lda #0

crc_fail2:   rts











             .fill 0800h-*,0ffh   ;fill rest to get 1K of data
             .end
             
