             .title      "reset 4 in 1 Reader Plugin"


;06/11/00 
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
romsiz:      .equ 00e7h
curr_bank:   .equ 00e8h

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "Pirate "
             .db "4 in 1 multi"
             .db "uses reset\n\r",0

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
             lda #002h
             ldx 01ffh
             beq do_prgz
             lda #004h
             dex
             beq do_prgz
             lda #006h
             dex
             beq do_prgz
             jmp do_chrs
             
do_prgz:     jmp do_prg

firstinit:   ldx #00h
             
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
             

             lda #'K'
             sta 01fch
             lda #'H'
             sta 01fdh
             lda #'!'
             sta 01feh
             lda #0ffh
             sta 01ffh
             
             lda #040h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #004h
             jsr send_byte     ;reset every 16K
             
             lda #000h
             jsr send_byte
             lda #001h
             jsr send_byte
             lda #001h
             jsr send_byte     ;64K PRG

             lda #000h
             beq do_prgx

do_prg:      pha   
             lda #040h
             jsr send_byte
             lda #000h
             jsr send_byte      ;send next reset size
             pla

do_prgx:     lda #000h
             sta temp1_lo
             tay
             lda #0c0h
             sta temp1_hi

send_plp2:   lda (temp1),y
             jsr send_byte
             iny
             bne send_plp2
             inc temp1_hi
             bne send_plp2    ;send 16K bank
             
dead:        jmp dead         ;wait for PC to reset us


do_chrs:     dex
             beq do_chrin
             lda #004h
             dex
             beq do_chr
             lda #020h
             dex
             beq do_chr
             lda #024h
             dex
             beq do_chr
             lda #000h
             jsr send_byte
             lda #000h
             sta 01fch         ;reset counter
             jsr send_byte     ;bullshit write to keep copyNES happy
             jmp no_chr

do_chrin:    lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte     ;bullshit write to keep copyNES happy
             
             lda #020h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #004h
             jsr send_byte     ;reset every 8K
             
             lda #080h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #002h
             jsr send_byte     ;32K CHR

             lda #000h
             beq do_chrx

do_chr:      pha
             lda #020h
             jsr send_byte
             lda #000h
             jsr send_byte      ;send next reset size
             pla

do_chrx:     
             lda #00h
             tay
             jsr wr_ppu
             lda 2007h      ;set up PPU
             ldx #020h

send_plp4:   lda 2007h
             jsr send_byte
             iny
             bne send_plp4
             dex
             bne send_plp4
             
dead2:       jmp dead2        ;wait for PC to reset us

;check for save-game RAM and back it up if it exists             

no_chr:      
             

no_ram2:     lda #0
             jsr send_byte
             lda #0
             jsr send_byte
             lda #0
             jsr send_byte

             rts



             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
