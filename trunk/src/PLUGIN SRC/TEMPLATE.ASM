             .title        "NROM Reader Plugin"


;06/10/00 
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


             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "Template plugin file " 
             .db "KH",0

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
             
             
;dump 32K of PRG data

             lda #080h
             jsr send_byte
             lda #000h       ;send size
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
             ldy #0
             sty temp1_lo
             lda #080h
             sta temp1_hi    ;set pointer to 08000h
             
             ldx #080h       ;080h pages
             
dump_it:     lda (temp1),y   ;dump 1 byte to the PC
             jsr send_byte
             iny
             bne dump_it
             inc temp1_hi    ;dump 1 page
             dex
             bne dump_it
                             ;all pages dumped

; dump 8K of CHR data             

             lda #020h      ;020h pages (8K bytes)
             tax
             jsr send_byte
             lda #000h
             jsr send_byte  ;send size
             lda #002h
             jsr send_byte  ;send CHR header
             
             lda #000h
             sta 02006h
             lda #000h
             sta 02006h     ;set PPU address to 0000h
             lda 02007h     ;read garbage byte
             ldy #0
             
dump_chr:    lda 02007h     ;send 1 byte to the PC
             jsr send_byte
             iny
             bne dump_chr
             jsr baton      ;send 1 page
             dex
             bne dump_chr   ;dump 8K of CHR
             
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             rts            ;done 


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
