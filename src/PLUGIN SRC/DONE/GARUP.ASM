             .title        "GAR Upload Plugin"


;06/16/00 
;Written by KH
;Version 1.0
             
;protocol for reading:             
;
;send out size of PRG ROM (two bytes, LSB first) # of 256 byte pages
;indicate PRG ROM (01h = PRG)
;send out bytes for PRG
;send out size of CHR ROM (two bytes, LSB first) # of 256 byte pages
;indicate CHR ROM (02h = CHR)
;send out stop (00h)


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

             .org 0280h

load:        .block 2
init:        .block 2
play:        .block 2
len:         .block 3

banks:       .block 8
initsng:     .block 1
numsng:      .block 1


in_mode:     .equ 0304bh



             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "GAR Upload Plugin" 
             .db 0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             lda #0
             sta 04803h
             
             lda #0
             sta temp1_lo
             
             ldx #008h
             lda #050h
             sta temp1_hi
             ldy #0

lgar_loop:   jsr read_byte
             sta (temp1),y
             iny
             bne lgar_loop
             inc temp1_hi
             dex
             bne lgar_loop

gdone:       jmp gdone

             .fill 0800h-*,0ffh   ;fill rest to get 1K of data



             .end
