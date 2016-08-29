             .title        "Cheapocabra GT-ROM Reader Plugin"


;08/28/2016 
;Written by rainwarrior
;Version 1.0
             
             ;vectors for standard system calls

send_byte:   .equ 0200h

temp1:       .equ 00e0h
temp1_lo:    .equ 00e0h
temp1_hi:    .equ 00e1h

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "Cheapocabra GR-ROM 512K" 
             .db " carts w/ VRAM",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

; mirroring
             lda #4
             jsr send_byte   ; mirror under mapper control
             
; size
             lda #0
             jsr send_byte
             lda #8 ; 512k = 8 x 64k
             jsr send_byte

; dump
             lda #1
             jsr send_byte ; 1 = send PRG command
             ldx #0 ; bank counter
dump_bank:
             stx 05000h ; select bank
             txa
             pha ; preserve X (bank counter)
             lda #000h
             sta temp1_lo
             lda #080h
             sta temp1_hi
             ldx #0
             ldy #0
dump_loop:
             lda (temp1),y
             jsr send_byte
             iny
             bne dump_loop ; 256 byte loop
             inx
             cpx #128 ; 128 x 256 bytes = 32k
             bcs dump_done
             inc temp1_hi
             jmp dump_loop
dump_done:   pla
             tax
             inx ; increment bank counter
             cpx #16 ; 16 x 32k = 512k
             bcc dump_bank

             lda #0
             jsr send_byte
             lda #0
             jsr send_byte
             lda #0
             jsr send_byte  ;send end block
             rts

             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
