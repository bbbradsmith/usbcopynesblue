             .title       "Tekken 2 Reader Plugin"


;06/21/00 
;Written by KH
;Version 1.0
             
             ;vectors for standard system calls

send_byte:   .equ 0200h
baton:       .equ 0203h
wr_ppu:      .equ 020ch

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
             
             .db "NROM -- 16K and 32K" 
             .db " carts w/ 8K CHR ROM",0

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

             lda #000
             sta 0c002h
             ldx #00eh
             stx 08002h
             inx
             stx 08003h
             lda #085h
             sta 0c001h
             lda #01eh
             sta 0d000h
             lda #020h
             sta 0d003h
             lda #08dh
             sta 0b000h
             lda #000h
             sta 0c006h
             sta 0d002h
             sta 0d001h
             
; jmp chr_only             
             
             lda #000h
             jsr send_byte
             lda #002h
             jsr send_byte
             lda #001h
             jsr send_byte

             lda #0
             sta temp2_lo
             ldx #008h
             ldy #0

sb_1:        lda #0
             sta temp1_lo
             lda #080h
             sta temp1_hi
             lda temp2_lo
             sta 08000h
             clc
             adc #001h
             sta 08001h

sb_2:        lda (temp1),y
             jsr send_byte
             iny
             bne sb_2
             inc temp1_hi
             lda #0c0h
             cmp temp1_hi
             bne sb_2
             inc temp2_lo
             inc temp2_lo
             dex
             bne sb_1

;dump CHR

chr_only:    lda #000h
             jsr send_byte
             lda #008h
             jsr send_byte
             lda #002h
             jsr send_byte

             ldx #0
             stx temp2_lo
             inx
             stx temp2_hi
             

sc_1:        ldy #0
             tya
             jsr wr_ppu
             lda #004h
             sta temp1_hi
             lda temp2_lo
             sta 09000h
             lda temp2_hi
             eor #001h
             sta 0a000h
             lda 2007h       ;note: mapper resets on second read!!

sc_2:        lda 2007h
             jsr send_byte
             iny
             bne sc_2
             dec temp1_hi
             bne sc_2
             inc temp2_lo
             bne sc_1
             dec temp2_hi
             bpl sc_1


             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             rts            ;done 


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
