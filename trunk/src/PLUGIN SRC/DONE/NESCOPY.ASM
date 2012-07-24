             .title           "NES Cart Copier"


;protocol:   
;
;3ah  : read CPU space
;xxxx : start address
;yy   : # pages
;a3h  : confirm
;<sends data>

;4bh  : write CPU space
;xxxx : start address
;yyyy : # pages
;b4h  : confirm
;<store data bytes>

;5ch  : read PPU space
;xxxx : start address
;yyyy : # of pages
;c5h  : confirm
;<sends data>

;6dh  : write PPU space
;xxxx : start address
;yyyy : # of pages
;d6h  : confirm
;<stores data bytes>

;7eh  : execute code
;xxxx : start address
;e7h  : confirm

;from above code, NES can send its own data packets.  format:

;8fh    : incoming data packet
;nn     : bitwise:
;    0 - 0 = Horiz mirror, 1 = Vert mirror
;    1 - 0 = no WRAM, 1= WRAM
;    2 - 0 = no 4 screen, 1 = 4 screen
;    3 - 0 = normal, 1 = CPU ROM only
;mm     : Mapper #
;xxxxxx : # of bytes of CPU
;xxxxxx : # of bytes of PPU
;f8h    : confirm
;nn...  : data sent


             .org 001h   ;ZP regs


bc:
c:           .block 1
b:           .block 1
             
joy_pad:     .block 1
;80 = A
;40 = B
;20 = select
;10 = start
;08 = U 
;04 = D
;02 = L
;01 = R

old_but:     .block 1

char_ctr:    .block 1

temp:        .block 1

baton_c:     .block 1

tempbank:    .block 1

mtype:       .block 1

addl:        .block 1

addh:        .block 1

npage:      .block 1

mtype2:      .block 1

temp_x:      .block 1

temp1:       
temp1_lo:    .block 1
temp1_hi:    .block 1
temp2:
temp2_lo:    .block 1
temp2_hi:    .block 1

temp_byt:    .block 1

type_4016:   .block 1

;nsf header info:

load:        .block 2
init:        .block 2
play:        .block 2
len:         .block 3
banks:       .block 8
initsng:     .block 2


crc0:        .equ 080h
crc1:        .equ 081h
crc2:        .equ 082h
crc3:        .equ 083h


s_init:      .equ 01fch
s_play:      .equ 01feh

port:        .equ 04a00h  ;was 4800


             .org 01000h
             rts

start:       sei
             cld
             ldx #0fbh
             txs
             
             jmp load_ram

back_here:   jsr set_in         ;input mode
             
             ldx #00h
             stx type_4016
             stx 04016h
             
             lda #020h
             bit port+01h
             beq got_4016       ;if bit clear, use lower mode

try_2:       lda #02h
             sta type_4016
             sta 04016h

got_4016:    jsr init_port
             lda port+00h
             sta temp_byt
             jsr init_lcd
             jsr load_chars
             jsr init_ppu
             jsr lcd_clr
             
             ldx #0
             ldy #0

lv_lp:       lda #04ch
             sta 0200h,x
             inx
             lda vec_tab,y
             iny
             sta 0200h,x
             inx
             lda vec_tab,y
             iny
             sta 0200h,x
             inx
             cmp #0ffh
             bne lv_lp

             lda #0         ;message 0: "welcome message"
             jsr sho_msg
             
             bit port+00h
             bvc no_play       ;if bit clear, we're going to copy

             lda #3        ;message 3: "Playing Game"
             jsr sho_msg
             jmp 0700h

no_play:     

main:        jsr set_out
             jsr lcd_clr
             lda #04
             jsr sho_msg   ;message 4: "Waiting for Host"

             jsr set_in    ;input mode

             jsr read_byte ;get mode byte
             cmp #03ah 
             beq mode_1    ;read CPU space
             cmp #04bh
             beq mode_2    ;write CPU space
             cmp #05ch
             beq mde_3    ;read PPU space
             cmp #06dh
             beq mde_4    ;write PPU space
             cmp #07eh
             beq mde_5    ;execute code
             cmp #08eh
             beq mde_6
             cmp #09fh
             beq mde_7
             
             jmp main

mde_3:       jmp mode_3
mde_4:       jmp mode_4
mde_5:       jmp mode_5
mde_6:       jmp loadnsf
mde_7:       jmp runnsf

;read CPU space
mode_1:      jsr read_pack 
             lda mtype2
             cmp #0a3h
             bne main
             jsr set_out
             lda #05h
             jsr sho_msg   ;message 5: "Transferring..."
             
             ldy #0

rd_lp:       lda (addl),y
             jsr write_byte
             iny
             bne rd_lp
             inc addh
             jsr baton
             dec npage
             bne rd_lp
             
             lda #06h     ;message 6: "Transfer Done!"
             jsr sho_msg
             lda #120
             jsr wait_vbl
             jmp main

;write CPU space
mode_2:      jsr read_pack
             lda mtype2
             cmp #0b4h
             beq s_ok2

j_main:      jmp main
             
s_ok2:       
          ;   lda #05h
          ;   jsr sho_msg
             ldy #0

wr_lp:       jsr read_byte
             sta (addl),y
             iny
             bne wr_lp
             inc addh
          ;   jsr baton
             dec npage
             bne wr_lp
             jsr set_out
             lda #080h
             jsr lcd_ins
             lda 0400h
             jsr sho_hex
             lda 0401h
             jsr sho_hex
             
;             lda #06h
;             jsr sho_msg
              lda #6
             jsr wait_vbl
             jmp main

;run code
mode_5:      jsr read_pack
             lda mtype2
             cmp #0e7h
             bne j_main
             jsr set_out
             lda #05h
             jsr sho_msg
             lda #((back_rd-1) >> 8)
             pha
             lda #((back_rd-1) & 0ffh)
             pha
             jmp (addl)

back_rd:     lda #06h
             jsr sho_msg
             lda #60
             jsr wait_vbl
             jmp main
             


mode_3:
mode_4:      jmp main




;---------------------------------------
;NSF player stuff


loadnsf:     

             lda #01fh
             sta temp2         ;# banks

df_lp1:      ldx #010h
             lda #0
             sta temp1_lo
             lda #080h
             sta temp1_hi
             lda temp2
             sta 5ff8h
             ldy #0            ;init bank # and pointers
             tya

df_lp2:      sta (temp1),y
             iny
             bne df_lp2
             inc temp1_hi
             dex
             bne df_lp2        ;clear all NSF RAM
             dec temp2
             bpl df_lp1        ;all banks
             
             ldy #0

cm_loop:     jsr read_byte
             sta load,y
             iny
             cpy #19
             bne cm_loop       ;read header
             jsr work_bank

             lda load
             sta temp1_lo
             lda load+1
             and #0fh
             ora #080h
             sta temp1_hi      ;adjust to get offset into bank
             ldy #0
             
ld_lp1:      jsr read_byte
             sta (temp1),y
             inc temp1_lo
             bne do_next       ;load 256 bytes
             inc temp1_hi
             lda #090h
             cmp temp1_hi      ;load 4K banks
             bne do_next
             inc temp2
             lda temp2
             sta 5ff8h
             lda #080h
             sta temp1_hi      ;inc bank and reset pointers

do_next:     dec len
             lda #0ffh
             cmp len
             bne ld_lp1
             dec len+1
             cmp len+1
             bne ld_lp1
             dec len+2
             cmp len+2
             bne ld_lp1        ;dec length counter
             
             ldx #3

ld_vect:     lda init,x
             sta s_init,x
             dex
             bpl ld_vect       ;save vectors


replaynsf:   lda banks
             sta 5ff8h         ;fix first bank we messed with
             lda #060h
             sta temp1_hi
             ldx #020h
             lda #0
             sta temp1_lo
             tay

cd_lk:       sta (temp1),y
             iny
             bne cd_lk
             inc temp1_hi
             dex
             bne cd_lk         ;clear RAM at 6000-7FFF

             ldx #0h
             
ld_def:      lda init_sound,x
             sta 04000h,x      ;init sound regs
             inx
             cpx #14h
             bne ld_def

             lda #00fh
             sta 04015h        ;turn all chans on


             jsr set_out
             lda #07h
             jsr sho_msg
             lda initsng+1
             jsr sho_hex
             lda #08h
             jsr sho_msg
             lda initsng
             jsr sho_hex

             ldy initsng+1     ;gets overwritten so save it
             
             ldx #0
             txa

gb_clr:      .db 09dh,001h,000h  ; don't overwrite byte 00h 
             .db 09dh,0fch,000h  ; sta 000fch,x (absolute!!! ZP does not work)
             sta 0200h,x
             sta 0300h,x
             sta 0400h,x  ;clear all RAM except saved vectors
             sta 0500h,x
             sta 0600h,x
             sta 0700h,x
             dex
             bne gb_clr     ;clear zeropage
             
             lda #((back_rd2-1) >> 8)
             pha
             lda #((back_rd2-1) & 0ffh)
             pha
             tya
             clc
             sbc #0
             tax
             tay
             jmp (s_init)

back_rd2:    lda #085h
             sta port+04h
             lda #074h
             sta port+05h  ;timer value
             lda #040h
             sta port+0bh  ;timer interrupts continuous
             sta port+0eh  ;enable interrupts 

waitit:      bit port+0dh
             bvc waitit     ;wait for timer 1
             lda #((back_rd3-1) >> 8)
             pha
             lda #((back_rd3-1) & 0ffh)
             pha
             jmp (s_play)   ;JSR play routine

back_rd3:    lda port+04h
             jmp waitit

init_sound:  .db 0,0,0,0
             .db 0,0,0,0
             .db 0,0,0,0
             .db 010h,0,0,0
             .db 0,0,0,0
             
runnsf:      ldy #0

cm_loop2:    jsr read_byte
             sta banks,y
             iny
             cpy #10
             bne cm_loop2       ;read header
             jsr work_bank
             lda banks
             sta 5ff8h
             jmp replaynsf


work_bank:   ldx #7
             lda #0
             sta 5ff7h
             
lb_loop:     ora banks,x       ;check to see if all bank bytes are 00h
             pha
             txa
             sta 5ff8h,x       ;and set banks up to 0,1,2,3,4,5,6,7
             pla
             dex
             bpl lb_loop
             cmp #0
             beq got_bank
             
             ldx #7

lb_loop2:    lda banks,x
             sta 5ff8h,x
             dex
             bpl lb_loop2
             lda #0
             sta 5ff8h
             sta temp2
             rts               ;if the banks were non-zero, load them up

got_bank:    lda load+1
             lsr a
             lsr a
             lsr a
             lsr a
             and #07h
             sta 5ff8h
             sta temp2         ;start loading at proper bank if non-banked
             rts

;---------------------------------------



             .fill 02000h-*,0ffh


             .org 03000h


;---------------------------------------------------------
;Subroutines
;---------------------------------------------------------


ram_dat:     lda #0fch
             sta port+00h  ;disable decoder totally
             jmp (0fffch)   ;reset vector


but_wait:    jsr read_it
             beq but_wait
             rts

read_it:     ldx #09
             stx 04016h
             dex
             stx 04016h

r_bit:       lda 04016h
             ror a
             rol joy_pad
             dex
             bne r_bit
             lda joy_pad
             cmp old_but
             beq no_chg
             sta old_but
             ora #0
             rts

no_chg:      lda #0
             rts

wait_vbl:    tay
             
wait_vbld:   lda 02002h
             bpl wait_vbld
             jsr read_it
             bne break_out
             dey
             bne wait_vbld
             
break_out:   rts


read_pack:   ldy #0

rp_loop:     jsr read_byte
             sta addl,y
             iny
             cpy #4
             bne rp_loop
             rts

read_byte: ;  lda port+00h
           ;  sta temp
             
rb_wait:     lda port+00h
             tax
             eor temp_byt
             and #040h
             beq rb_wait   ;wait for state change
             stx temp_byt
             ldx port+01h
             lda port+00h
             eor #010h
             sta port+00h  ;write "got byte"
             txa
             rts

write_byte:  stx temp_x
             sta port+01h
             jsr set_out
             lda port+00h
             sta temp
             eor #020h
             sta port+00h  ;toggle "byte ready"
             ldx #0

wb_wait:     lda port+00h
             eor temp
             and #080h
             beq wb_wait2   ;wait for state change
             ldx temp_x
             rts

wb_wait2:    dex
             bne wb_wait
             beq wb_wait
             ldx temp_x
             rts



init_port:   lda #000h
             sta port+0bh
             lda #0ffh
             sta port+0ch
             sta port+01h
             lda #0feh
             sta port+00h
             lda #03fh
             sta port+02h
             lda #0ffh
             sta port+03h
             rts

cart_on:     lda #0feh
             sta port+00h
             rts

cart_off:    lda #0ffh
             sta port+00h
             rts


init_ppu:    lda #0h
             sta 02000h
             sta 02001h     ;turn off PPU
             
wait_1:      lda 02002h             
             bpl wait_1

wait_2:      lda 02002h
             bpl wait_2     ;wait 2 screens
             rts

sho_hex:     pha
             lsr a
             lsr a
             lsr a
             lsr a
             jsr sho_nyb
             pla

sho_nyb:     and #00fh
             tax
             lda hex_tab,x
             jmp lcd_char

hex_tab:     .db "0123456789ABCDEF"

baton:     ;  rts

             stx temp_x
             inc baton_c
             lda #03h
             and baton_c
             tax
             lda #0c7h
             jsr lcd_ins
             lda baton_d,x
             jsr lcd_dat
             ldx temp_x
             rts

baton_d:     .db "|/-",08h

set_in:      lda #000h
             sta port+03h
             rts

set_out:     lda #0ffh
             sta port+03h
             rts

load_ram:    ldx #0

lr_loop:     lda #0
             sta 0,x
             sta 00fch,x
             sta 0200h,x
             sta 0300h,x
             sta 0400h,x
             sta 0500h,x
             sta 0600h,x
             lda ram_dat,x
             sta 0700h,x
             dex
             bne lr_loop
             jmp back_here

init_lcd:    lda #038h
             jsr lcd_ins
             lda #00ch
             jmp lcd_ins
             
lcd_clr:     lda #0
             sta char_ctr
             lda #01h
             jsr lcd_ins
             jsr ld_loop
             jsr ld_loop
             jsr ld_loop
             jmp ld_loop   ;extra delay for screen clearing

lcd_char:    pha
             inc char_ctr
             lda char_ctr
             cmp #009h
             bne no_charw
             lda #0c0h
             jsr lcd_ins
             jmp no_charx
             
no_charw:    cmp #011h
             bne no_charx
             lda #0
             sta char_ctr
             lda #080h
             jsr lcd_ins

no_charx:    pla
             
lcd_dat:     sta port+01h
             lda port+00h
             ora #008h
             sta port+00h
             and #0fbh
             sta port+00h
             ora #004h
             sta port+00h
             bne l_dlay

lcd_ins:     sta port+01h
             lda port+00h
             and #0f7h
             sta port+00h
             and #0fbh
             sta port+00h
             ora #004h
             sta port+00h
             
l_dlay:      lda #40
             sec

ld_loop:     sbc #1
             bcs ld_loop
             rts

sho_msg:     asl a
             tax
             lda msgs,x
             sta c
             inx
             lda msgs,x
             sta b          ;get message pointer
             ldy #0

sm_lp:       lda (bc),y
             bne no_ret
             rts

no_ret:      cmp #'~'
             bne no_clr
             jsr lcd_clr
             jmp no_char
             
no_clr:      jsr lcd_char
             
no_char:     iny
             bne sm_lp      ;do max 256 chars 
             rts

int_err:     lda #2
             jsr sho_msg
             lda #0
             sta 02000h
             sta 02001h
             sta 04015h
             
ie_lp:       jmp ie_lp


load_chars:  ldx #0
             lda #040h
             jsr lcd_ins

lc_l:        lda cchar,x
             jsr lcd_dat
             inx
             cpx #8
             bne lc_l
             lda #080h
             jsr lcd_ins
             rts


msgs:        .dw msg_0,msg_1,msg_2,msg_3,msg_4,msg_5,msg_6
             .dw msg_7,msg_8

                 ;0123456789ABCDEF
msg_0:      .db "~CopyNES by K.H. ",0

msg_1:      .db "~ A-Copy, B-Play ",0

msg_2:      .db "~INTERRUPT!",0

msg_3:      .db "~  Playing Cart",0

msg_4:      .db "~Waiting for Host",0

msg_5:      .db "~Transferring...",0                 
                 
msg_6:      .db "~Transfer Done!",0

msg_7:      .db "~Playing ",0

msg_8:      .db " of ",0

                 ;0123456789ABCDEF

chk_vram:    lda #0
             jsr wr_ppu
             lda #055h
             sta 2007h
             lda #0aah
             sta 2007h
             lda #0
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #55h
             bne no_ram5
             lda 2007h
             cmp #0aah
             bne no_ram5
             lda #0
             jsr wr_ppu
             lda #0aah
             sta 2007h
             lda #0
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #0aah
             
no_ram5:     rts


wr_ppu:      sta 2006h
             lda #0
             sta 2006h
             rts


chk_wram:    lda 6000h
             sta temp1_hi
             lda 6080h
             sta temp1_lo
             lda #055h
             sta 6000h
             eor #0ffh
             sta 6080h

             ldy 6000h
             ldx 6080h
             lda temp1_hi
             sta 6000h
             lda temp1_lo
             sta 6080h
             cpy #055h
             bne no_ram
             cpx #0aah
             bne no_ram
             
             lda #0aah
             sta 6000h
             eor #0ffh
             sta 6080h
             ldy 6000h
             ldx 6080h
             lda temp1_hi
             sta 6000h
             lda temp1_lo
             sta 6080h
             cpy #0aah
             bne no_ram
             cpx #055h
             bne no_ram

no_ram:      rts

vec_tab:     .dw write_byte,baton,chk_vram,chk_wram
             .dw wr_ppu,read_byte,init_crc,do_crc
             .dw finish_crc
             .dw 0ffffh

            
cchar:       .db 00h,010h,008h,004h,002h,001h,00h,00h


init_crc:    lda #0ffh
             sta crc0
             sta crc1
             sta crc2
             sta crc3
             rts

do_crc:      eor crc0        ;xor with first CRC
             tax             ;to get table entry
             lda crc_tab,x
             eor crc1
             sta crc0
             lda crc_tab+256,x
             eor crc2
             sta crc1
             lda crc_tab+512,x
             eor crc3
             sta crc2
             lda crc_tab+768,x
             sta crc3
             rts

             
finish_crc:  ldx #3
             
fin_loop:    lda #0ffh
             eor crc0,x
             sta crc0,x
             dex
             bpl fin_loop
             rts
             



crc_tab:     .db 000h,096h,02Ch,0BAh,019h,08Fh,035h,0A3h
             .db 032h,0A4h,01Eh,088h,02Bh,0BDh,007h,091h
             .db 064h,0F2h,048h,0DEh,07Dh,0EBh,051h,0C7h
             .db 056h,0C0h,07Ah,0ECh,04Fh,0D9h,063h,0F5h
             .db 0C8h,05Eh,0E4h,072h,0D1h,047h,0FDh,06Bh
             .db 0FAh,06Ch,0D6h,040h,0E3h,075h,0CFh,059h
             .db 0ACh,03Ah,080h,016h,0B5h,023h,099h,00Fh
             .db 09Eh,008h,0B2h,024h,087h,011h,0ABh,03Dh
             .db 090h,006h,0BCh,02Ah,089h,01Fh,0A5h,033h
             .db 0A2h,034h,08Eh,018h,0BBh,02Dh,097h,001h
             .db 0F4h,062h,0D8h,04Eh,0EDh,07Bh,0C1h,057h
             .db 0C6h,050h,0EAh,07Ch,0DFh,049h,0F3h,065h
             .db 058h,0CEh,074h,0E2h,041h,0D7h,06Dh,0FBh
             .db 06Ah,0FCh,046h,0D0h,073h,0E5h,05Fh,0C9h
             .db 03Ch,0AAh,010h,086h,025h,0B3h,009h,09Fh
             .db 00Eh,098h,022h,0B4h,017h,081h,03Bh,0ADh
             .db 020h,0B6h,00Ch,09Ah,039h,0AFh,015h,083h
             .db 012h,084h,03Eh,0A8h,00Bh,09Dh,027h,0B1h
             .db 044h,0D2h,068h,0FEh,05Dh,0CBh,071h,0E7h
             .db 076h,0E0h,05Ah,0CCh,06Fh,0F9h,043h,0D5h
             .db 0E8h,07Eh,0C4h,052h,0F1h,067h,0DDh,04Bh
             .db 0DAh,04Ch,0F6h,060h,0C3h,055h,0EFh,079h
             .db 08Ch,01Ah,0A0h,036h,095h,003h,0B9h,02Fh
             .db 0BEh,028h,092h,004h,0A7h,031h,08Bh,01Dh
             .db 0B0h,026h,09Ch,00Ah,0A9h,03Fh,085h,013h
             .db 082h,014h,0AEh,038h,09Bh,00Dh,0B7h,021h
             .db 0D4h,042h,0F8h,06Eh,0CDh,05Bh,0E1h,077h
             .db 0E6h,070h,0CAh,05Ch,0FFh,069h,0D3h,045h
             .db 078h,0EEh,054h,0C2h,061h,0F7h,04Dh,0DBh
             .db 04Ah,0DCh,066h,0F0h,053h,0C5h,07Fh,0E9h
             .db 01Ch,08Ah,030h,0A6h,005h,093h,029h,0BFh
             .db 02Eh,0B8h,002h,094h,037h,0A1h,01Bh,08Dh
             .db 000h,030h,061h,051h,0C4h,0F4h,0A5h,095h
             .db 088h,0B8h,0E9h,0D9h,04Ch,07Ch,02Dh,01Dh
             .db 010h,020h,071h,041h,0D4h,0E4h,0B5h,085h
             .db 098h,0A8h,0F9h,0C9h,05Ch,06Ch,03Dh,00Dh
             .db 020h,010h,041h,071h,0E4h,0D4h,085h,0B5h
             .db 0A8h,098h,0C9h,0F9h,06Ch,05Ch,00Dh,03Dh
             .db 030h,000h,051h,061h,0F4h,0C4h,095h,0A5h
             .db 0B8h,088h,0D9h,0E9h,07Ch,04Ch,01Dh,02Dh
             .db 041h,071h,020h,010h,085h,0B5h,0E4h,0D4h
             .db 0C9h,0F9h,0A8h,098h,00Dh,03Dh,06Ch,05Ch
             .db 051h,061h,030h,000h,095h,0A5h,0F4h,0C4h
             .db 0D9h,0E9h,0B8h,088h,01Dh,02Dh,07Ch,04Ch
             .db 061h,051h,000h,030h,0A5h,095h,0C4h,0F4h
             .db 0E9h,0D9h,088h,0B8h,02Dh,01Dh,04Ch,07Ch
             .db 071h,041h,010h,020h,0B5h,085h,0D4h,0E4h
             .db 0F9h,0C9h,098h,0A8h,03Dh,00Dh,05Ch,06Ch
             .db 083h,0B3h,0E2h,0D2h,047h,077h,026h,016h
             .db 00Bh,03Bh,06Ah,05Ah,0CFh,0FFh,0AEh,09Eh
             .db 093h,0A3h,0F2h,0C2h,057h,067h,036h,006h
             .db 01Bh,02Bh,07Ah,04Ah,0DFh,0EFh,0BEh,08Eh
             .db 0A3h,093h,0C2h,0F2h,067h,057h,006h,036h
             .db 02Bh,01Bh,04Ah,07Ah,0EFh,0DFh,08Eh,0BEh
             .db 0B3h,083h,0D2h,0E2h,077h,047h,016h,026h
             .db 03Bh,00Bh,05Ah,06Ah,0FFh,0CFh,09Eh,0AEh
             .db 0C2h,0F2h,0A3h,093h,006h,036h,067h,057h
             .db 04Ah,07Ah,02Bh,01Bh,08Eh,0BEh,0EFh,0DFh
             .db 0D2h,0E2h,0B3h,083h,016h,026h,077h,047h
             .db 05Ah,06Ah,03Bh,00Bh,09Eh,0AEh,0FFh,0CFh
             .db 0E2h,0D2h,083h,0B3h,026h,016h,047h,077h
             .db 06Ah,05Ah,00Bh,03Bh,0AEh,09Eh,0CFh,0FFh
             .db 0F2h,0C2h,093h,0A3h,036h,006h,057h,067h
             .db 07Ah,04Ah,01Bh,02Bh,0BEh,08Eh,0DFh,0EFh
             .db 000h,007h,00Eh,009h,06Dh,06Ah,063h,064h
             .db 0DBh,0DCh,0D5h,0D2h,0B6h,0B1h,0B8h,0BFh
             .db 0B7h,0B0h,0B9h,0BEh,0DAh,0DDh,0D4h,0D3h
             .db 06Ch,06Bh,062h,065h,001h,006h,00Fh,008h
             .db 06Eh,069h,060h,067h,003h,004h,00Dh,00Ah
             .db 0B5h,0B2h,0BBh,0BCh,0D8h,0DFh,0D6h,0D1h
             .db 0D9h,0DEh,0D7h,0D0h,0B4h,0B3h,0BAh,0BDh
             .db 002h,005h,00Ch,00Bh,06Fh,068h,061h,066h
             .db 0DCh,0DBh,0D2h,0D5h,0B1h,0B6h,0BFh,0B8h
             .db 007h,000h,009h,00Eh,06Ah,06Dh,064h,063h
             .db 06Bh,06Ch,065h,062h,006h,001h,008h,00Fh
             .db 0B0h,0B7h,0BEh,0B9h,0DDh,0DAh,0D3h,0D4h
             .db 0B2h,0B5h,0BCh,0BBh,0DFh,0D8h,0D1h,0D6h
             .db 069h,06Eh,067h,060h,004h,003h,00Ah,00Dh
             .db 005h,002h,00Bh,00Ch,068h,06Fh,066h,061h
             .db 0DEh,0D9h,0D0h,0D7h,0B3h,0B4h,0BDh,0BAh
             .db 0B8h,0BFh,0B6h,0B1h,0D5h,0D2h,0DBh,0DCh
             .db 063h,064h,06Dh,06Ah,00Eh,009h,000h,007h
             .db 00Fh,008h,001h,006h,062h,065h,06Ch,06Bh
             .db 0D4h,0D3h,0DAh,0DDh,0B9h,0BEh,0B7h,0B0h
             .db 0D6h,0D1h,0D8h,0DFh,0BBh,0BCh,0B5h,0B2h
             .db 00Dh,00Ah,003h,004h,060h,067h,06Eh,069h
             .db 061h,066h,06Fh,068h,00Ch,00Bh,002h,005h
             .db 0BAh,0BDh,0B4h,0B3h,0D7h,0D0h,0D9h,0DEh
             .db 064h,063h,06Ah,06Dh,009h,00Eh,007h,000h
             .db 0BFh,0B8h,0B1h,0B6h,0D2h,0D5h,0DCh,0DBh
             .db 0D3h,0D4h,0DDh,0DAh,0BEh,0B9h,0B0h,0B7h
             .db 008h,00Fh,006h,001h,065h,062h,06Bh,06Ch
             .db 00Ah,00Dh,004h,003h,067h,060h,069h,06Eh
             .db 0D1h,0D6h,0DFh,0D8h,0BCh,0BBh,0B2h,0B5h
             .db 0BDh,0BAh,0B3h,0B4h,0D0h,0D7h,0DEh,0D9h
             .db 066h,061h,068h,06Fh,00Bh,00Ch,005h,002h
             .db 000h,077h,0EEh,099h,007h,070h,0E9h,09Eh
             .db 00Eh,079h,0E0h,097h,009h,07Eh,0E7h,090h
             .db 01Dh,06Ah,0F3h,084h,01Ah,06Dh,0F4h,083h
             .db 013h,064h,0FDh,08Ah,014h,063h,0FAh,08Dh
             .db 03Bh,04Ch,0D5h,0A2h,03Ch,04Bh,0D2h,0A5h
             .db 035h,042h,0DBh,0ACh,032h,045h,0DCh,0ABh
             .db 026h,051h,0C8h,0BFh,021h,056h,0CFh,0B8h
             .db 028h,05Fh,0C6h,0B1h,02Fh,058h,0C1h,0B6h
             .db 076h,001h,098h,0EFh,071h,006h,09Fh,0E8h
             .db 078h,00Fh,096h,0E1h,07Fh,008h,091h,0E6h
             .db 06Bh,01Ch,085h,0F2h,06Ch,01Bh,082h,0F5h
             .db 065h,012h,08Bh,0FCh,062h,015h,08Ch,0FBh
             .db 04Dh,03Ah,0A3h,0D4h,04Ah,03Dh,0A4h,0D3h
             .db 043h,034h,0ADh,0DAh,044h,033h,0AAh,0DDh
             .db 050h,027h,0BEh,0C9h,057h,020h,0B9h,0CEh
             .db 05Eh,029h,0B0h,0C7h,059h,02Eh,0B7h,0C0h
             .db 0EDh,09Ah,003h,074h,0EAh,09Dh,004h,073h
             .db 0E3h,094h,00Dh,07Ah,0E4h,093h,00Ah,07Dh
             .db 0F0h,087h,01Eh,069h,0F7h,080h,019h,06Eh
             .db 0FEh,089h,010h,067h,0F9h,08Eh,017h,060h
             .db 0D6h,0A1h,038h,04Fh,0D1h,0A6h,03Fh,048h
             .db 0D8h,0AFh,036h,041h,0DFh,0A8h,031h,046h
             .db 0CBh,0BCh,025h,052h,0CCh,0BBh,022h,055h
             .db 0C5h,0B2h,02Bh,05Ch,0C2h,0B5h,02Ch,05Bh
             .db 09Bh,0ECh,075h,002h,09Ch,0EBh,072h,005h
             .db 095h,0E2h,07Bh,00Ch,092h,0E5h,07Ch,00Bh
             .db 086h,0F1h,068h,01Fh,081h,0F6h,06Fh,018h
             .db 088h,0FFh,066h,011h,08Fh,0F8h,061h,016h
             .db 0A0h,0D7h,04Eh,039h,0A7h,0D0h,049h,03Eh
             .db 0AEh,0D9h,040h,037h,0A9h,0DEh,047h,030h
             .db 0BDh,0CAh,053h,024h,0BAh,0CDh,054h,023h
             .db 0B3h,0C4h,05Dh,02Ah,0B4h,0C3h,05Ah,02Dh

             .fill 03ffah-*,0ffh
             
             .dw int_err
             .dw start
             .dw int_err
             
             .end
