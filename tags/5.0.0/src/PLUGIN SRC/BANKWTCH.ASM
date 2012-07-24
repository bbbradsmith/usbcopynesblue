             .title        "Bankwatch(tm)"

;Keeping an eye on data
;02/03/02 
;Written by KH
;Version 1.2
             
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

temp4:       .equ 00e6h   ;for wr_bank
temp4_lo:    .equ 00e6h
temp4_hi:    .equ 00e7h
temp5:       .equ 00e8h
temp5_lo:    .equ 00e8h
temp5_hi:    .equ 00e9h
x_temp:      .equ 00eah
y_temp:      .equ 00ebh

temp_crc:    .equ 00ech

port:        .equ 04a00h

;Bankwatch(tm) host plugin
;

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "Bankwatch(tm)" 
             .db 0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             lda #001h
             sta temp2_lo
;             lda port+02h
;             and #0f7h
;             sta port+02h       ;set that bit to input


main:        jsr set_in
             jsr read_byte      ;wait & read byte
           ;  cmp #08h
           ;  bmi main
             asl a
             tax
             lda dotab+1,x
             pha
             lda dotab+0,x
             pha
             rts
             
dotab:       .dw main-1,write_map-1        ;0,1     
             .dw read_map-1,dump_banks-1   ;2,3
             .dw write_big-1,read_cpu-1    ;4,5
             .dw custom1-1,custom2-1       ;6,7
             .dw custom3-1,bselp1-1        ;8,9
             .dw bselp2-1,custsend-1       ;A,B


;bankwatch plugin commands:
;
;0 - do nothing
;1 - write to an address
;2 - read from an address
;3 - read small data segments
;4 - read large data segments
;5 - read a block of data specified
;6 - custom routine #1
;7 - custom routine #2
;8 - custom routine #3
;9 - report # of PRG banks present
;A - select and send desired program bank
;B - custom send routine
;C -
;


;report how many PRG banks present
bselp1:      jsr set_out
             lda #03h          ;128K
             jsr send_byte      ;send byte
             jmp main
             
;actually select a bank of data, then return it
bselp2:      jsr read_byte      ;get bank to use
      ;       ldx #04h
      ;       stx 08000h
      ;       lsr a
      ;       sta 08001h    ;select bank asked for
      ;       php
             jsr set_out
      ;       plp
      ;       bcs goahead
             lda #080h
             .db 02ch
goahead:     lda #090h
             jsr bget
             
          ;   clc
          ;   adc 07ffh
          ;   sta temp1+1
          ;   lda #00h
          ;   sta temp1+0
          ;   ldx #020h
          ;   ldy #00h

bs_dump:  ;   lda (temp1),y
          ;   jsr send_byte
          ;   iny
          ;   dex
          ;   bne bs_dump
             jmp main

             



;-----------------------CUSTOM USER CODE GOES HERE!------------------


custom1:     ldx #00h
             lda 08d00h
             lda 08e00h
             
iii:         lda 08d01h
             lda 08e01h
             sta 0300h,x
             inx
             bne iii
             
             jmp main

             
             lda #00h
             sta 04017h     ;turn on frame IRQs
             lda #04h                          ;3
             sta 04016h                        ;4
             lda 07fch
             sta 07feh
             lda 07fdh
             sta 07ffh
             jsr do_wait
             lda port+00h                      ;4
             and #0f7h                         ;3
             sta port+00h   ;clear this        ;4
             nop
             nop
             nop
             nop
             ora #008h                         ;3  21 total cycles
             sta port+00h   ;start IRQ master
             
i_wait:      lda 04015h
             lda 07feh
             bne i_w2
             dec 07ffh
i_w2:        dec 07feh
             
             ldy #003h
             ldx #000h
i_w3:        dex              
             bne i_w3
             dey
             bne i_w3
             
             jsr do_wait
             pha
             pla                 ;7
             nop
             nop
             nop
             nop
             lda 07ffh           ;4
             ora 07feh           ;4
             ora 07feh           ;4
             bne i_wait          ;2
             lda #00h
             sta 04016h     ;stop IRQ master
             
             jmp main



do_wait:     bit 04015h
             bvc do_wait
             rts

custom2:     lda #18h
             sta 02001h
             jmp main
             
             
             lda port+00h
             ora #008h
             sta 08030h    ;turn IRQs
             sta port+00h

             jmp main


custom3:     lda #00h
             sta 04100h
             lda 07ffh
             sta 0f100h
             jmp main

             lda #000h
             sta 02001h
             lda #000h
             sta 02006h
             sta 02006h
             sta 05105h ;1st nametable

             ldx #020h
             ldy #00h

cx:          sta 02007h
             iny
             bne cx
             dex
             bne cx       ;init nametable 0
             sta 02003h
             
cz:          sta 02004h   
             dex
             bne cz

             lda #018h
             sta 02001h   ;PPU back on

cy:          lda 05204h
             rol a
             rol a
             rol a
             sta 05130h
             sta 05120h
             jmp cy


;--------------------------------------------------------------------

;sends an arbitrary block of data
;first 3 bytes = length
custsend:    jsr set_out
             lda #00h
             jsr send_byte
             lda #08h
             jsr send_byte
             lda #00h       ;size in bytes
             jsr send_byte

             
             lda #000h
             sta rr1+1
             lda #001h     ;8800h first, 8e01h second
             sta rr2+1
             lda #088h
             sta rr1+2
             lda #08eh
             sta rr2+2     ;save pointers
             
             ldy #000h
             ldx #000h        ;64K worth

             lda 08d00h
             lda 08e00h    ;reset
             
rr1:         lda 0ffffh    ;read value
rr2:         lda 0ffffh
             
             jsr send_byte
             inc rr1+1
             bne rr1
             inc rr1+2
             lda rr1+2
             cmp #08eh
             bne rr1
             inc rr1+1  ;skip 8e00h
             cmp #090h
             bne rr1
             jmp main



main2:       jmp main



write_map:   jsr read_byte      ;addr lo   (fall thru)
             sta smod+1
             jsr read_byte
             sta smod+2         ;addr hi
             ora smod+1
             beq main2           ;0 = quit back to main
             jsr read_byte
smod:        sta 0ffffh          ;write value using self-modifying code
             jmp write_map

read_map:    jsr read_byte
             sta smod2+1
             jsr read_byte
             sta smod2+2      ;get pointer
             jsr set_out
smod2:       lda 0ffffh             
             jsr send_byte      ;send byte
             jmp main

write_big:   lda #02h
             .db 02ch

dump_banks:  lda #01h
             sta temp2_lo
             jsr read_byte
             sta temp5
             jsr set_out
             lda #000h
             jsr dchr
             lda #004h
             jsr dchr
             lda #008h
             jsr dchr
             lda #00ch
             jsr dchr
             lda #010h
             jsr dchr
             lda #014h
             jsr dchr
             lda #018h
             jsr dchr
             lda #01ch
             jsr dchr           ;dump 256 bytes of 8 1K CHR banks
             lda #060h
             jsr dprog
             lda #080h
             jsr dprog
             lda #0a0h
             jsr dprog
             lda #0c0h
             jsr dprog
             lda #0e0h
             jsr dprog          ;dump 32 bytes of 4 8K PRG banks
             jsr chk_mirr
             jsr send_byte
             jmp main
             
dchr:        jsr wr_ppu         ;set page
             tay                ;sets acc to 0 :-)
             lda 02007h         ;garbage read
             lda temp2_lo
             sta temp2_hi       ;store counter

dchr_1:      lda 02007h 
             jsr send_byte
             iny
             bne dchr_1         ;dump 256 char blocks
             dec temp2_hi
             bne dchr_1
             rts
             
dprog:       ldx temp5
             beq nocrc
             jmp crc_pbank      ;perform CRC's instead

nocrc:       sta temp1_hi
             ldx #020h
             ldy #00h
             sty temp1_lo
             
db_1:        lda (temp1),y
             jsr send_byte
             iny
             dex
             bne db_1
             ldx temp2_lo
             dex
             beq db_u
             lda #010h
             clc
             adc temp1_hi
             sta temp1_hi      ;add 010h to upper byte of pointer
             ldx #020h
             ldy #000h

db_3:        lda (temp1),y
             jsr send_byte
             iny
             dex
             bne db_3
             
db_u:        rts


set_in:      lda #00h
             sta port+03h
             rts

set_out:     lda #0ffh
             sta port+03h
             rts


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

;reads CPU data from start address to end address

read_cpu:    jsr read_byte
             sta rc_loop+1
             jsr read_byte
             sta rc_loop+2
             jsr read_byte
             sta temp1_lo
             jsr read_byte
             sta temp1_hi
             jsr set_out

rc_loop:     lda 0ffffh     ;use self modifying code, 'cause of picky HW
             jsr send_byte
             inc rc_loop+1
             bne rc_l2
             inc rc_loop+2

rc_l2:       lda temp1_lo
             bne rc_l1
             dec temp1_hi
            
rc_l1:       dec temp1_lo
             lda temp1_lo
             and temp1_hi
             cmp #0ffh
             bne rc_loop
             jmp main


bget:        sta temp1_hi
             lda #010h
             sta temp2_hi
             jmp docrc

crc_pbank:   sta temp1_hi    ;RAM bank #
             ldx temp2_lo
             dex
             beq littlemode
             lda #010h
             sta temp2_hi
             jsr docrc
             lda #010h
             sta temp2_hi
             jmp docrc
             
littlemode:  lda #020h
             sta temp2_hi
             jmp docrc
             
             
docrc:       jsr init_crc
             lda #00h
             sta temp1_lo
             ldy #0

dsw1:        lda (temp1),y
             jsr do_crc
             inc temp1_lo
             bne dsw1
             inc temp1_hi
             dec temp2_hi
             bne dsw1        ;4K
             jsr finish_crc
             ldx #0
             ldy #3

chk_crc:     lda crc0,x
             jsr send_byte
             inx
             dey
             bpl chk_crc
             ldx #01ch

chk_crc2:    lda #0
             jsr send_byte
             dex
             bne chk_crc2
             rts

             
             
             .fill 0800h-*,0ffh

             .end


;for RAMBO-1 interrupts

;custom1:     lda 07ffh
;             sta 0c000h      ;get timer value
;             lda #001h
;             sta 0c001h      ;do M2 IRQ
;             sta 0e000h
;             nop
;             nop
;             nop
;             nop
;             sta 0e001h      ;start and reset IRQ
;             nop
;             nop
;             nop
;             nop
;             nop
;             nop
;             nop
;             nop
;             lda port+00h
;             and #0f7h
;             sta port+00h   ;clear this
;             nop
;             nop
;             nop
;             nop
;             nop
;             nop
;             nop
;             nop
;             ldy #001h
;             sty 0c001h
;             ora #008h
;             sta 0e000h
;             sta port+00h
;             sta 0e001h
;             jmp main
;
;
;

;for FME-07 ints

;custom1:     ldx #00dh
;             lda #000h
;             ldy #080h
;             stx 08000h
;             sta 0a000h
;             sty 0a000h
;             sta 0a000h
;             
;             lda port+00h
;             and #0f7h
;             sta port+00h   ;clear this
;             
;
;custom3:
;cus_x:       lda #00eh
;             sta 08000h
;             lda 07feh
;             sta 0a000h      ;get timer value
;             lda #00fh
;             sta 08000h
;             lda 07ffh
;             sta 0a000h      ;get timer value
;             lda #00dh
;             sta 08000h
;             lda #001h
;             sta 0a000h      ;turn counter part on
;             lda port+00h
;             and #0f7h
;           ;  sta port+00h   ;clear this
;             nop
;             nop
;             nop
;             ora #008h
;             ldy #81h
;             sty 0a000h
;             sta port+00h
;             jmp main
;
;custom2:     ldx #00dh
;             lda #000h
;             ldy #001h
;             stx 08000h
;             sta 0a000h
;             sty 0a000h
;             sta 0a000h
;             bne cus_x
;
;

;for loading nametables with crosshatch pattern
;custom3:     lda #068h
;             sta 05800h
;             lda #037h
;             sta 05801h
;             nop
;             nop
;             nop
;             nop
;             lda 05800h
;             sta 0feh
;             lda 05801h
;             sta 0ffh
;
;             lda #020h
;             sta 02006h
;             lda #000h
;             sta 02006h
;
;             ldx #00h
;             ldy #08h
;
;c3_loop:     lda #055h
;             sta 02007h
;             lda #0aah
;             sta 02007h
;             dex
;             bne c3_loop
;             dey
;             bne c3_loop
;
;
;

;IRQ thingy for mapper 90


;            lda #01h
;            sta 0c000h
;            lda #046h
;            sta 0c001h
;            lda #0ffh
;            sta 0c007h
;
;            lda #00h
;            sta temp1+0
;            sta temp1+1
;
;            lda #80h
;            sta 0c002h
;            sta 0c005h   ;high counter
;            lda #00h
;            sta 0c006h   ;low counter
;            lda #00h
;            sta 0c004h  
;            sta 0c003h
;
;cs_loopx:    lda 02007h
;            lda port+00h
;            and #08h
;            bne cs_loopx   ;make sure to clear out all prior conditions
;
;            
;cs_loop:     
;
;          ;   lda temp1+0   ;A,B
;             lda #0aah     ;C
;             sta 0c006h   
;
;          ;   lda #00h
;          ;   sta 0c000h
;             sta 0c002h
;
;          ;  lda #00h       ;B
;             lda temp1+1   ;A,C
;             sta 0c005h   
;             
;          ;   lda temp1+1   ;B
;          ;   lda #00h      ;A
;             lda temp1+0   ;C
;             sta 0c004h  
;             
;          ;   lda #01h
;          ;   sta 0c000h
;
;             sta 0c003h
;             
;             ldx #01h
;             ldy #00h
;             sty temp1+2
;
;cs_loop2:    lda 02007h    ;clock A12
;
;             lda port+00h
;             and #08h
;             beq gotcs     ;see if IRQ is low
;             
;             inx           ;no, inc counters
;             bne cs_loop2
;             iny
;             bne cs_loop2
;             inc temp1+2
;             lda temp1+2
;             and #0feh
;             beq cs_loop2 ;if 200000h, fall thru
;
;gotcs:       txa
;             jsr send_byte
;             tya
;             jsr send_byte
;             lda temp1+2
;             jsr send_byte
;             lda #000h
;             jsr send_byte
;             inc temp1+0
;             bne cs_loop
;             inc temp1+1
;             bne cs_loop
;             jmp main
;
;

;custom1:     lda 07ffh
;             and #0fh
;             ora #020h
;             sta 07000h
;             ora #010h
;             sta 07000h
;             jmp main
;
;custom2:     inc 07ffh
;             jmp custom1
;
;custom3:     lda #000h
;             sta 07000h
;             jmp main
;
;             bit 02002h
;             bpl custom1
;
;             lda #000h
;             sta 0f000h
;             lda port+00h
;             and #0f7h
;             sta port+00h   ;clear this
;
;             ora #008h
;             ldx 07ffh
;             stx 0f000h
;             sta port+00h
;             
;             jmp main
;             
;
;;custom1:     ldx #0h
;             
;cust_x:      lda #3fh
;             sta 02006h
;             lda #00h
;             sta 02006h
;
;c1_lp:       txa
;             asl a
;             asl a
;             sta 02007h
;             inx
;             txa
;             and #01fh
;             bne c1_lp
;
;             lda #3fh
;             sta 02006h
;             lda #00h
;             sta 02006h
;             ldx #000h
;             stx 02001h
;             
;c1_lp2:      cpx #080h
;             bne c1_lp3
;             lda #01h
;             sta 02001h
;
;c1_lp3:      lda 02007h
;             sta 07000h,x
;             inx
;             bne c1_lp2
;             jmp main
;
;;custom2:     lda #010h
;             sta 02006h
;             lda #000h
;             sta 02006h
;             lda 02007h
;             jmp main
;             
;custom2:    ldx #07h 
;            
;             lda #000h
;             sta 02006h
;             lda #000h
;             sta 02006h
;             lda 02007h
;             jmp main
;             
;;custom3:     
;             sta 0f010h
;             lda port+00h
;             and #0f7h
;             sta port+00h   ;clear this
;
;             ora #008h
;             sta port+00h
;             
;             
;             jmp main
;


;custom1:     lda 07feh    ;write VRC4 IRQ count
;             sta 04100h
;             lda 07ffh
;             sta 04101h
;             jmp main
;             
;             sta 08000h
;             lsr a
;             lsr a
;             lsr a
;             lsr a
;             sta 09000h
;             lda 07ffh
;             sta 0A000h
;             lsr a
;             lsr a
;             lsr a
;             lsr a
;             sta 0B000h
;             jmp main
;
;custom2:     sta 0d000h   ;trigger reload
;             jmp custom1
;
;custom3:     lda #000h
;             sta 0c000h
;             ldx 07fdh
;             
;             
;             lda port+00h
;             and #0f7h
;             sta port+00h   ;clear this
;
;             ora #008h
;             stx 0c000h
;             sta port+00h
;             
;             jmp main
;             
;

;custom1:     lda 07ffh
;             and #0fh
;             ora #020h
;             sta 07000h
;             ora #010h
;             sta 07000h
;             jmp main
;
;custom2:     inc 07ffh
;             jmp custom1
;
;custom3:     lda #000h
;             sta 07000h
;             jmp main
