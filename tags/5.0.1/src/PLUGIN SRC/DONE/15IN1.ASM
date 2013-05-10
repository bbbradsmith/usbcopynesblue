             .title        "15 in 1 Reader Plugin"


;02/11/01 
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
             
             .db "15 in 1"

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             
             lda #04h
             jsr send_byte   ;send byte
             
             lda #00h
             sta temp2_lo

             lda #000h
             jsr send_byte
             lda #004h       ;send size
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
             sta 08000h
             nop
             sta 0bc14h      ;get us into the first bank
             
             lda #080h
             sta temp1_hi
             jsr di2         ;dump first 32K bank
             lda #02h
             sta temp2_hi
             lda #08dh
             sta 0f2d5h      ;get us into a 16K bank

di_2:        ldx temp2_hi
             txa
             sta 0bc13h,x
             jsr di
             inc temp2_hi
             lda #010h
             bit temp2_hi
             beq di_2

             lda #000h
             jsr send_byte
             lda #002h       ;send size
             jsr send_byte
             lda #002h
             jsr send_byte   ;send CHR
             lda #000h
             sta temp2_hi
             
di_3:        ldx temp2_hi
             dex
             txa
             and #0eh
             bne no_blah
             lda #08dh
             sta 0f2d5h

no_blah:     inx
             txa
             sta 0bc13h,x
             lda #000h
             sta 02006h
             sta 02006h
             lda 02007h
             ldx #020h
             ldy #00h

di_4:        lda 02007h
             jsr send_byte
             iny
             bne di_4
             dex
             bne di_4
             inc temp2_hi
             lda #010h
             bit temp2_hi
             beq di_3


             
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             rts            ;done 


di:          lda #0c0h
             sta temp1_hi

di2:         ldy #000h
             sty temp1_lo

dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             inc temp1_hi
             bne dump_it
             rts


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data
             .end
