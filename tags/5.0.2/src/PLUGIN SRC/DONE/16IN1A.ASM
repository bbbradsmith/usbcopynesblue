             .title      "BMC- 16 in 1 A Reader Plugin"


;01/2/01 
;Written by KH
;Version 1.0
             
             ;vectors for standard system calls

send_byte:   .equ 0200h
baton:       .equ 0203h
chk_vram:    .equ 0206h
chk_wram:    .equ 0209h
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
temp4:       .equ 00e6h
temp4_lo:    .equ 00e6h
temp4_hi     .equ 00e7h
temp5:       .equ 00e8h
temp5_lo:    .equ 00e8h
temp5_hi     .equ 00e9h
romsiz:      .equ 00eah
curr_bank:   .equ 00ebh
x_temp:      .equ 00ech
y_temp:      .equ 00edh

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "BMC-16in1A"
             .db "\n\r",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             
             lda 01fch
             cmp #'K'         ;K
             bne firstinit
             lda 01fdh
             cmp #'H'
             bne firstinit
             lda 01feh
             cmp #'!'
             bne firstinit
             
             inc 01ffh
             lda 01ffh
             cmp #010h
             bne secondrun
             jmp endit

firstinit:   lda #04h
             jsr send_byte
             
             lda #'K'
             sta 01fch
             lda #'H'
             sta 01fdh
             lda #'!'
             sta 01feh
             lda #000h
             sta 01ffh
             
             lda #080h
             jsr send_byte
             lda #002h
             jsr send_byte
             lda #004h
             jsr send_byte     ;reset at 128K+32K
             
             lda #080h
             jsr send_byte
             lda #020h
             jsr send_byte
             lda #001h
             jsr send_byte     ;2mbyte+32K
             
             lda #00h
             sta 06000h        ;reset bank control & turn the 32K ROM on
             sta temp1_lo
             tay
             lda #080h
             sta temp1_hi

send_loop:   lda (temp1),y
             jsr send_byte
             iny
             bne send_loop
             inc temp1_hi
             bne send_loop     ;send the menu 32K shitz
             jmp secondru2
             
secondrun:   lda #000h
             jsr send_byte
             lda #002h
             jsr send_byte     ;reset every 128K

secondru2:   lda #00h
             sta 0a000h
             lda 01ffh
             ora #010h
             sta 06000h        ;set bank
             
             lda #00h
             sta temp2_lo
             
sl2:         lda temp2_lo
             jsr wr_bank        ;set banks
             jsr send_16K
             inc temp2_lo
             lda temp2_lo
             cmp #08h
             bne sl2
             
dead:        jmp dead          ;wait for PC to reset us


endit:       lda #000h
             jsr send_byte
             lda #002h
             jsr send_byte     ;send bullshit reset to keep PC happy
             
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte     ;done
             rts


send_16K:    lda #080h
             sta temp1_hi
             lda #000h
             sta temp1_lo
             tay

s16_loop:    lda (temp1),y
             jsr send_byte
             iny
             bne s16_loop
             inc temp1_hi
             lda temp1_hi
             cmp #0c0h
             bne s16_loop
             rts

wr_bank:     stx x_temp
             sty y_temp
             sta temp4_lo   ;store desired bank
             lda #0
             sta temp5_lo
             lda #080h
             sta temp5_hi   ;start addr
             ldx #080h      ;# iterations
             ldy #0

wrb_loop:    lda (temp5),y
             and #07h
             cmp temp4_lo   ;check current byte
             beq gotit
             iny
             bne wrb_loop
             inc temp5_hi
             bne wrb_loop   ;keep checking
             lda temp4_lo
             sta 08000h
             ldx x_temp
             ldy y_temp
             rts            ;if it wasn't found, bag it
             
gotit:       lda (temp5),y             
             sta (temp5),y  ;if we found it, do the switch
             ldx x_temp
             ldy y_temp
             rts

             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .db "P40080"
             .db "P00800"
             .db "P10800"
             .db "P20800"
             .db "P30800"

             .end

