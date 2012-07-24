             .title        "NROM Reader Plugin"


;06/10/00 
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

;bits for all 4 nametables:
;
;12
;48
;

;0 1-screen (using screen 1)
;1 4-screen mirroring
;2
;3 Horiz mirroring
;4
;5 Vertical mirroring
;6
;7 3/4th screen 
;8
;9
;a
;b
;c
;d
;e
;f 1-screen (using screen 0)


             ;plugin header that describes what it does
             
             .org 0380h
             

             .db "Mirroring tester"
             
             .fill 0400h-*,00h    ;all plugins must reside at 400h

             
;check mirroring             

             lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte
             lda #01h
             jsr send_byte
             lda #01h
             jsr send_byte
             
             lda #00h
             sta temp2
             
cm_k:        lda temp2




















;mirroring test code starts here             
             
             ldx #007
             stx 04100h
             sta 04101h
             
;mirroring test code ends here             
             
             jsr chk_mirr
             jsr send_byte
             
             inc temp2
             bne cm_k
             
             ldx #03fh
             ldy #0
             
             lda #01h
             sta temp1_hi
             sty temp1_lo

cm_j:        lda (temp1),y
             jsr send_byte
             iny
             bne cm_j
             inc temp1_hi
             bne cm_j
             
             lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte

             rts


chk_mirr:    lda #00h
             sta temp1
             lda #020h
             jsr wr_ppu
             lda #000h
             sta 02007h
             lda #024h
             jsr wr_ppu
             lda #000h
             sta 02007h
             lda #028h
             jsr wr_ppu
             lda #000h
             sta 02007h
             lda #02ch
             jsr wr_ppu
             lda #000h
             sta 02007h   ;clear all 4 nametable positions
             
             lda #020h
             jsr wr_ppu
             lda #0ffh
             sta 02007h   ;write to first nametable location only

             lda #02ch
             jsr cm_y
             lda #028h
             jsr cm_y
             lda #024h
             jsr cm_y
             lda #020h
             jsr cm_y
             lda temp1
             rts

cm_y:        jsr wr_ppu
             lda 02007h
             lda 02007h
             cmp #0ffh
             clc
             bne cm_x
             sec

cm_x:        rol temp1
             rts
             
             
             
;             ldx #00h
;             
;             lda #020h
;             jsr wr_ppu
;             lda #055h
;             sta 2007h
;             lda #0aah
;             sta 2007h
;             lda #024h
;             jsr wr_ppu
;             lda 2007h
;             lda 2007h
;             cmp #055h
;             bne horz_mir
;             lda 2007h
;             cmp #0aah
;             bne horz_mir
;             lda #020h
;             jsr wr_ppu
;             lda #0aah
;             sta 2007h
;             lda #024h
;             jsr wr_ppu
;             lda 2007h
;             lda 2007h
;             cmp #0aah
;             bne horz_mir
;             inx
;
;horz_mir:    txa


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
