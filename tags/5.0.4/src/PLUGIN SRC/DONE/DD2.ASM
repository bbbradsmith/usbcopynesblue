             .title        "dildodragon 2 pirate Reader Plugin"


;12/21/04 
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

             
             
             lda #04h
             jsr send_byte   ;send byte
             


next_part:   lda #000h       ;size is in 256 byte banks (max 65536 banks, 16Mbyte)
             jsr send_byte
             lda #002h       ;send size 128K
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
             ldx #010h       ;16 banks of 8K
             lda #000h
             sta temp2_lo    ;start on bank 0

dloop1:      lda temp2_lo
             sta 08000h      ;select an 8K bank
             
             ldy #000h
             sty temp1_lo
             lda #080h
             sta temp1_hi    ;point to 8000h

dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it     ;dump 256 bytes
             inc temp1_hi
             lda temp1_hi
             cmp #0a0h       ;if we get to a000h, we're done
             bne dump_it
             inc temp2_lo    ;go to next bank
             dex             ;decrement # of banks
             bne dloop1
             
             ;PRG is done
             
             lda #000h
             jsr send_byte
             lda #002h      ;128K worth of CHR
             jsr send_byte
             lda #002h
             jsr send_byte  ;send CHR header
             
             ldx #080h       ;128 banks of 1K
             lda #000h
             sta temp2_lo    ;start on bank 0

dloop2:      lda temp2_lo
             sta 08010h      ;select an 1K CHR bank
             
             
             ldy #000h
             lda 02002h      ;reset PPU thingy
             sty 02006h      ;set PPU address to 0000h
             sty 02006h
             lda 02007h      ;garbage read
             lda #004h
             sta temp1_hi    ;4 passes of 256 bytes = 1K
             
dump_it2:    lda 02007h
             jsr send_byte
             iny
             bne dump_it2     ;dump 256 bytes
             dec temp1_hi
             bne dump_it2    ;do all 4 blocks, 1K total
             inc temp2_lo    ;go to next bank
             dex             ;decrement # of banks
             bne dloop2
             
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             rts            ;done 


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
