             .title          "normal reg dump player"


;07/7/00 
;Written by KH
;Version 1.0
             

             ;vectors for standard system calls

port:        .equ 04800h

send_byte:   .equ 0200h
baton:       .equ 0203h
chk_vram:    .equ 0206h
chk_wram:    .equ 0209h
wr_ppu:      .equ 020ch
read_byte:   .equ 020fh
init_crc:    .equ 0212h
do_crc:      .equ 0215h
finish_crc:  .equ 0218h

inbase:      .equ 01f0h

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


in_mode:     .equ 0304bh



             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "Reg Dump player" 
             .db " (norm)"
             .db 0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             lda #0
             sta 04803h        ;set to input mode


;normal NES reg dump player format:
;
;first byte:
;1y0x xxxx
;
;y = bit 7 of data byte
;x = register (only 00-15 valid)
;
;second byte:
;0yyy yyyy
;
;lower 7 bits of data byte
;



             lda #085h
             sta port+04h
             lda #074h
             sta port+05h  ;timer value
             lda #040h
             sta port+0bh  ;timer interrupts continuous
             sta port+0eh  ;enable interrupts 




cm_loop:     jsr read_byte
             ora #0             ;to make sure flags are set
             bpl cm_loop        ;whoops, a data byte. try again
             sta temp1_lo
             cmp #0ffh
             beq do_wait
             jsr read_byte
             ora #0             ;check sign
             bmi cm_loop        ;if not a data byte, try again
             rol a
             sta temp1_hi
             lda temp1_lo
             rol a
             rol a              ;get bit into carry
             ror temp1_hi       ;put carry in to make byte
             lda temp1_lo
             and #01fh
             tax                ;get desired reg into X
             lda temp1_hi
             sta 04000h,x       ;store byte in desired reg
             jmp cm_loop


do_wait:     bit port+0dh
             bvc do_wait     ;wait for timer 1
             lda port+04h
             jmp cm_loop

             .fill 0800h-*,0ffh   ;fill rest to get 1K of data



             .end
