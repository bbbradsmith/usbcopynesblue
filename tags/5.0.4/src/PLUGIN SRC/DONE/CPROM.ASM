             .title        "CPROM Reader Plugin"


;06/12/00 
;Written by KH
;Version 1.0
             
             ;vectors for standard system calls

send_byte:   .equ 0200h
baton:       .equ 0203h

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
             
             .db "CPROM -- 16K and 32K" 
             .db " carts w/ 16K VRAM",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             
;check mirroring             

             
             
             ldx #00h
             
             lda #020h
             jsr load_str
             lda #055h
             sta 2007h
             lda #0aah
             sta 2007h
             lda #024h
             jsr load_str
             lda 2007h
             lda 2007h
             cmp #055h
             bne horz_mir
             lda 2007h
             cmp #0aah
             bne horz_mir
             lda #020h
             jsr load_str
             lda #0aah
             sta 2007h
             lda #024h
             jsr load_str
             lda 2007h
             lda 2007h
             cmp #0aah
             bne horz_mir
             inx

horz_mir:    txa
             jsr send_byte   ;send byte
             
             lda #000h       ;determine if this is a 16K or 32K game
             sta temp1_lo
             sta temp2_lo
             lda #080h
             sta temp1_hi
             lda #0c0h
             sta temp2_hi
             
             ldx #040h
             ldy #0

chk_loop:    lda (temp1),y
             cmp (temp2),y
             bne not_16k
             iny
             bne chk_loop
             inc temp1_hi
             inc temp2_hi
             dex
             bne chk_loop

;this is a 16K game

             lda #040h
             tax
             bne next_part

not_16k:     lda #080h
             tax

next_part:   jsr send_byte
             lda #000h       ;send size
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             ldy #0
             sty temp1_lo
             lda #080h
             sta temp1_hi

dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             jsr baton
             inc temp1_hi
             dex
             bne dump_it
             
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             rts            ;done 


load_str:    sta 2006h
             lda #0
             sta 2006h
             rts
             


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
