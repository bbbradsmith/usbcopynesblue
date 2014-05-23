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
;<store data bytes

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



;MAJOR CHANGES FOR USB
;  all lcd code removed
;  handshaking changed, handshaking pinouts changed
;  bios vers 4





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

nmicounter:  .block 1
irqcounter:  .block 1

crc0:        .equ 080h
crc1:        .equ 081h
crc2:        .equ 082h
crc3:        .equ 083h


s_init:      .equ 01fch
s_play:      .equ 01feh

port:        .equ 04a00h  ;was 4800

topostack    .equ 0ech      ;last RAM location that emulated code can use
realstack    .equ 0f4h      ;where our stack really sits

;1 frame = 262 scanlines
;
;a) rendering:
; 1 garbage scanline
; 240 visible
; 1 unusable
;
;b) vblank:
; 20 usable
;

render:      .equ 27507    ;# of cycles during rendering phase
vblank:      .equ 2273     ;# of cycles during vblank phase


; 1ed - instruction counter for vblank
; 1ee - PPU 2005 1st write
; 1ef - PPU 2005 2nd write
;
; 1f0 - emu temp
; 1f1 - cycle count low
; 1f2 - cycle count high
; 1f3 - stack level 1
; 1f4 - stack level 0
; 1f5 - Acc
; 1f6 - X reg
; 1f7 - Y reg
; 1f8 - flags
; 1f9 - stack pointer
; 1fa - pcl
; 1fb - pch
; 1fc - instruction
; 1fd - address low
; 1fe - address high
; 1ff - rts

;ppustat bits:
;
;0 - if we read 2007 before or not
;1 - interrupt enable (when set, NMIs will be performed)
;2 - PPU increment quantity
;3 - rendering enabled
;4 - sprites enabled
;5 - PPU enable (when set, we will worry about the PPU)
;6 - which load of 2005/2006 we are on
;7 - NMI enable (1 = yes, 0 = no)


icount:      .equ 01edh   ;# of instructions to perform in vblank
p2005:       .equ 01eeh   ;PPU scrolling registers
emutemp:     .equ 01f0h
cyclecount:  .equ 01f1h   ;2 bytes to hold the current cycle count
         ;        01f2h   ;stack level 1
         ;        01f3h   ;stack level 0
reg_a        .equ 01f5h
reg_x        .equ 01f6h
reg_y        .equ 01f7h
reg_p        .equ 01f8h
reg_s        .equ 01f9h
reg_pcl      .equ 01fah
reg_pch      .equ 01fbh
ramloc       .equ 01fch


         ;        port+00h   ;port B data
         ;        port+01h   ;port A data
         ;        port+02h   ;port B direction register
         ;        port+03h   ;port A direction register
         ;        port+04h   ;timer 1 low byte
         ;        port+05h   ;timer 1 high byte
brkpt:       .equ port+06h   ;timer 1 period low (store breakpoint lo here!)
         ;        port+07h   ;timer 1 period high (store breakpoint hi here!)
         ;        port+08h   ;timer 2 low byte
         ;        port+09h   ;timer 2 high byte
ppustat:     .equ port+0ah   ;shift register (store PPU status here!)
nothreg1:    .equ port+0bh   ;mode control reg 1 (use bit 6 only!)
p2006lo:     .equ port+0ch   ;mode control reg 2 (2006 low)
         ;        port+0dh   ;IRQ status
p2006hi:     .equ port+0eh   ;use bits 0-6 (2006 high)
         ;        port+0fh   ;port A mirror


             .org 01000h
             rts
             
start:       sei
             cld
             ldx #0fbh
             txs
             
             jmp load_ram
back_here:   
             

got_4016:    jsr init_port     
             lda port+00h       ;read control bus
             sta temp_byt
             jsr init_ppu
             
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
             
             lda port+00h       ;load control port
             and #040h          ;D6 = play/copy mode
             beq no_play        ;if bit6=0 COPY mode

             ;jump to play code
             jmp 0700h

no_play:  

main:      
             jsr set_in    ;set 6522 input mode

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
             cmp #0a0h
             beq mde_8    ;run emulator
             cmp #0a1h
             beq mde_9    ;send identifier string
             cmp #0a2h
             beq mde_10   ;send version #
             jmp main

mde_3:       jmp mode_3
mde_4:       jmp mode_4
mde_5:       jmp mode_5
mde_6:       jmp loadnsf
mde_7:       jmp runnsf
mde_8:       lda temp_byt
             sta emutemp
             jmp main2         ;run the emulator
mde_9:       jmp identify
mde_10:      jmp identify2

;read CPU space
mode_1:      jsr read_pack 
             lda mtype2
             cmp #0a3h
             bne main
             jsr set_out      ;set 6522 output mode
             
             ldy #0
rd_lp:       lda (addl),y
             jsr write_byte
             iny
             bne rd_lp
             inc addh
             dec npage
             bne rd_lp
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
             ldy #0
wr_lp:       jsr read_byte
             sta (addl),y
             iny
             bne wr_lp
             inc addh
             dec npage
             bne wr_lp
             lda #6
             jsr wait_vbl
             jmp main

;run code
mode_5:      jsr read_pack
             lda mtype2
             cmp #0e7h
             bne j_main
             jsr set_out               ;set output mode
             lda #((back_rd-1) >> 8)
             pha
             lda #((back_rd-1) & 0ffh)
             pha
             jmp (addl)

back_rd:     
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
             sta port+04h                               ; timer value
             lda #074h
             sta port+05h  ;timer value                 ; timer value
             lda #040h
             sta port+0bh  ;timer interrupts continuous ; timer mode
             sta port+0eh  ;enable interrupts           ; timer enable

waitit:      bit port+0dh                               ; wait for irq
             bvc waitit     ;wait for timer 1
             lda #((back_rd3-1) >> 8)
             pha
             lda #((back_rd3-1) & 0ffh)
             pha
             jmp (s_play)   ;JSR play routine

back_rd3:    lda port+04h                                ; reset irq flag
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
             
check_play_mode:
             sei
             cld
             ldx #0f8h
             txs
             jsr init_port
             lda port+00h
             sta temp_byt
             jsr init_ppu
             ldx #7
store_copynes_reset:
             lda ram_dat,x
             sta 01f8h,x
             dex
             bpl store_copynes_reset
             lda port+00h
             and #040h
             beq no_play2
             jmp 01f8h
no_play2:
             jmp start

;--------------------------------------------------------------------------
;Main bulk of the emulator code goes here

             .fill 01400h-*,0ffh


             jmp main2

mode_indx:   jsr pcfetch7   ;clear carry here
             adc reg_x
             jsr indydo
             jmp fixaddy

mode_indy:   jsr pcfetch
             jsr indydo
             jmp indycon

mode_zerx:   jsr pcfetch7   ;clear carry here
             adc reg_x
             jmp zpcon
             
mode_zery:   jsr pcfetch7   ;clear carry here
             adc reg_y
             jmp zpcon

mode_zero:   jsr pcfetch
             
zpcon:       sta ramloc+1
             lda #00h
             sta ramloc+2
             jmp idone

mode_absx:   jsr pcfetch4    ;not a whole lot I can do.. only 2 stack levels
             jsr pcfetch5
             jsr pcfetch6
             lda reg_x
             jmp absocon

mode_absy:   jsr pcfetch4
             jsr pcfetch5
             jsr pcfetch6
             
indycon:     lda reg_y
             
absocon:     adc ramloc+1     ;carry cleared in pcfetch6
             sta ramloc+1
             bcc fixaddy
             jsr pagecross
             bcs fixaddy      ;carry will always be set

mode_abso:   jsr pcfetch4
             jsr pcfetch5
             jsr pcfetch6

fixaddy:     jmp fixaddy2
             
mode_immd:   jsr pcfetch
             ldx #060h
             stx ramloc+2
         .db 02ch             ;skip with a BIT

mode_impl:   lda #060h
             sta ramloc+1
             tya
             jmp execute

mode_nop3:   jsr pcfetch
mode_nop2:   jsr pcfetch
             jmp edone

mode_op08:   lda reg_p
             ora #030h
             jmp m08cont
             
mode_op48:   lda reg_a
             
m08cont:     jsr safepush
             jmp edone

mode_op78:   lda #004h
             ora reg_p
             bne m78cont

mode_op58:   lda #0fbh
             and reg_p
             jmp m78cont

mode_op28:   jsr safepop
             ora #030h       ;turn on B and unimplemented flags

m78cont:     sta reg_p
             jmp edone

mode_op68:   jsr safepop
             sta reg_a
             lda #(reg_a & 0ffh)
             sta ramloc+1
             lda #(reg_a >> 8)
             sta ramloc+2
             lda #0adh
             jmp execute

mode_op20:   jsr pcfetch
             tay
             lda reg_pch
             jsr safepush
             lda reg_pcl
             jsr safepush
             jmp m4ccont

mode_op4c:   jsr pcfetch
             tay
             
m4ccont:     jsr pcfetch
             sta reg_pch
             sty reg_pcl
             jmp edone

mode_op00:   jmp op_00
mode_op40:   jmp op_40
mode_op60:   jmp op_60
mode_op6c:   jmp op_6c
mode_op9a:   jmp op_9a
mode_opba:   jmp op_ba
mode_halt:   jmp ehalt

mode_bran:   tya
             
             
;--- end of critical 256 byte code block
             
             rol a
             rol a
             rol a
             and #03h
             tax
             tya
             and #020h
             bne rels

relc:        lda reltab,x
             bit reg_p
             beq dorel 
             bne norel

reltab:      .db 080h,040h,001h,002h

rels:        lda reltab,x
             bit reg_p
             bne dorel

norel:       jsr pcfetch
             jmp edone

dorel:       jsr pagecross2
             jsr pcfetch
             bpl relpos
             clc
             adc reg_pcl
             sta reg_pcl
             bcs reldone
             dec reg_pch
            
reldone:     jmp edone

relpos:      clc
             adc reg_pcl
             sta reg_pcl
             bcc reldone
             inc reg_pch
             jsr pagecross2
             jmp edone

indydo:      tax
             lda 0,x
             sta ramloc+1
             lda 1,x
             sta ramloc+2   ;pull address from zeropage
             clc            ;do this here
             rts

;-------------------------
;opcode routines, one per
op_00:       jsr pcfetch
             lda reg_pch
             jsr safepush
             lda reg_pcl
             jsr safepush
             lda reg_p
             ora #024h        ;set unimplemented and I flag
             and #0efh        ;clear break flag
             jsr safepush
             lda 0fffeh
             sta reg_pcl
             lda 0ffffh
             sta reg_pch
             jmp edone

op_40:       jsr safepop
             ora #030h
             sta reg_p
             jsr safepop
             sta reg_pcl
             jsr safepop
             sta reg_pch
             jmp edone

op_60:       jsr safepop
             sta reg_pcl
             jsr safepop
             sta reg_pch
             jsr pcfetch2   ;do increment
             jmp edone

op_6c:       jsr pcfetch4   ;do address mode
             jsr pcfetch5
             jsr pcfetch6
             jsr ramloc
             sta reg_pcl
             inc ramloc+1
             jsr ramloc
             sta reg_pch
             jmp edone

op_9a:       lda reg_x
             sta reg_s
             lda #topostack
             cmp reg_s
             bcs op9anopro
             lda #topostack
             sta reg_s

op9anopro:   jmp edone
             
op_ba:       lda reg_s
             sta reg_x
             lda #(reg_x & 0ffh)
             sta ramloc+1
             lda #(reg_x >>  8)
             sta ramloc+2
             lda #0aeh
             jmp execute     ;ldx absolute

fixaddy2:    lda ramloc+2     ;filter out bad reads/writes
             bmi idone        ;if in ROM, we're done automatically
             cmp #01h
             beq stackstuff
             and #0f8h
             cmp #048h
             beq portwrite    ;port chip at 4800-4fff
             cmp #040h
             beq chksprite
             and #0e0h
             cmp #020h
             bne idone
             jmp ppuaddy
             
portwrite:   lda #042h        ;force bogus addresses to 4200-42ffh  
             sta ramloc+2
             bne idone

chksprite:   lda ramloc+1
             cmp #014h
             bne idone
             lda ramloc+2
             cmp #040h
             bne idone
             dec cyclecount+1
             dec cyclecount+1  ;subtract 512 cycles for sprites (close 'nuff)
             jsr ppuwait
             bne idone

stackstuff:  lda #topostack
             cmp ramloc+1
             bcs idone
             lda #topostack ^ 0ffh
             adc ramloc+1
             sta ramloc+1   ;wrap in page 1 if needed

idone:       tya
             and #0e3h
             ora #00ch      ;force all opcodes to be absolute

execute:     sta ramloc+0
             lda reg_p
             tax
             ora #004h      ;no IRQs allowed
             pha
             txa
             and #004h
             sta reg_p      ;blow away all the bits in P except I
             ldx reg_x
             ldy reg_y
             lda reg_a
             plp
             jsr ramloc     ;execution formed instruction
             php
             sta reg_a
             sty reg_y
             stx reg_x
             pla
             and #0fbh      ;strip IRQ flag
             ora reg_p
             sta reg_p      ;OR new bits on

edone:       
             ;;OLD was read data      lda port+01h check if byte waiting to be read (/RXE=0)
             ;;OLD was compare to AA  cmp #0aah
             ;;OLD beq ebreak         ;AA = break

             lda port+00h      ;NEW read control bus
             and #20h          ;NEW isolate /RXE D5
             beq ebreak        ;NEW zero = byte waiting to be read

             bit p2006hi       ;p2006hi  bit6->V
             bvc continu       ;if v clear, goto continu      run code was $40 to break
             lda #00h          ;if v set, done send code 0    run code was $C0 once
             beq emul8done

             
continu:     lda reg_pcl   ;see if breakpoint hit
             cmp brkpt+0
             bne continu2
             lda reg_pch
             cmp brkpt+1
             bne continu2
             lda #02h      ;breakpoint hit
             bne emul8done

continu2:    jmp emul8     ;nope, continue executing


ehalt:       lda #01h      ;HLT hit, report same

emul8done:   jsr write_byte
             jmp mainx

;break encountered from the PC
ebreak:      
             jsr read_byte      ;NEW read the break byte that was waiting
             lda #03h
             jsr write_byte
             jmp mainx

;------------------------------------------------------------------
;emulate code

;port chip usage
go2brk:      lda #040h       ;run to breakpoint
             .db 02ch

emulate:     lda #0c0h       ;run 1 instruction
             sta p2006hi
             
emul8:       bit 02002h
             bpl noblank
             lda p2005+0
             sta 02005h       ;reload the scroll registers
             lda p2005+1
             sta 02005h
             lda p2006hi
             sta 02006h
             lda p2006lo
             sta 02006h
             lda icount
             and #03fh
             sta 02000h
             
noblank:     lda #0adh
             sta ramloc+0     ;LDA abs
             lda #060h
             sta ramloc+3     ;RTS
             lda reg_pcl
             sta ramloc+1
             lda reg_pch
             sta ramloc+2         ;current PC
             jsr ramloc           ;get opcode
             tay
             lda cyclecount+0
             sec
             sbc cyctab,y
             sta cyclecount+0
             bcs continuem
             dec cyclecount+1
             
continuem:   bit cyclecount+1
             bmi doppu
             inc reg_pcl
             bne noincx4
             inc reg_pch           ;inc PC

noincx4:     lda amode,y
             sta ramloc+1
             lda #(mode_indx >> 8)
             sta ramloc+2
             jmp (ramloc+1)
             
doppu:       bit nothreg1
             bvs goblank
             lda icount
             and #07fh
             sta icount            ;clear vblank flag
             lda #040h       
             sta nothreg1          ;put us in rendering
             clc
             lda cyclecount+0
             adc #(render & 0ffh)
             sta cyclecount+0
             lda cyclecount+1
             adc #(render >> 8)
             sta cyclecount+1      ;load cycle count for rendering
             bne continuem

goblank:     lda #00h
             sta nothreg1          ; it 6 holds PPU mode (0 = vbl, 1 = rendering)
             lda icount
             ora #080h
             sta icount            ;set vblank flag
             lda cyclecount+0
             adc #(vblank & 0ffh)
             sta cyclecount+0
             lda cyclecount+1
             adc #(vblank >> 8)
             sta cyclecount+1      ;load cycle count for rendering
             lda #02h
             bit ppustat
             bpl continuem         ;do we need an NMI?
             beq continuem         ;if NMIs disabled, don't do them at all
             lda reg_pch
             jsr safepush
             lda reg_pcl
             jsr safepush
             lda reg_p
             ora #030h
             jsr safepush
             lda 0fffah            ;get new address
             sta reg_pcl
             lda 0fffbh
             sta reg_pch
             jmp noblank
             

;PPU is about to be read from / written to             

ppuaddy:     lda ramloc+1     ;PPU at 2000
             and #07h
             cmp #07h
             beq ppu2007
             tax
             beq ppu2000
             dex
             beq ppu2001
             dex
             beq ppu2002
             cpx #03h      ;2005
             beq ppu2005
             cpx #04h      ;2006
             beq ppu2006
             jsr ppuwait   ;for 2003, 2004 wait for PPU to be ready first
             jmp idone
             
ppu2000:     jmp ppu2000x
ppu2001:     jmp ppu2001x
ppu2002:     jmp ppu2002x
ppu2005:     jmp ppu2005x
ppu2006:     jmp ppu2006x
ppu2007:     jmp ppu2007x
           
;----------------------------------------------------------------------
;PPU register 2000h

ppu2000x:    lda #((ramloc+0) & 0ffh)
             sta ramloc+1
             lda #((ramloc+0) >> 8)
             sta ramloc+2
             tya
             and #0e3h
             ora #00ch      ;force all opcodes to be absolute
             sta ramloc+0
             ldx reg_x
             ldy reg_y
             lda reg_a
             jsr ramloc     ;execute formed instruction
             sta reg_a
             sty reg_y
             stx reg_x
             lda ramloc+0 ;get byte written to 2000h
             ldx #07fh
             .db 08fh
             .dw 02000h   ;sax 02000h  write byte to 2000h, without bit 7
             ora #07bh    ;turn the other 6 bits on for the AND coming up
             tax
             lda ppustat
             ora #084h    ;make sure bits ripple thru
             .db 08fh
             .dw ppustat  ;sax ppustat
             lda ramloc+0
             and #03fh
             sta ramloc+0
             lda icount   ;copy 2000h register over
             and #0c0h
             ora ramloc+0
             sta icount
             jmp edone

;----------------------------------------------------------------------
;PPU register 2001h

ppu2001x:    lda #((ramloc+0) & 0ffh)
             sta ramloc+1
             lda #((ramloc+0) >> 8)
             sta ramloc+2
             tya
             and #0e3h
             ora #00ch      ;force all opcodes to be absolute
             sta ramloc+0
             ldx reg_x
             ldy reg_y
             lda reg_a
             jsr ramloc     ;execute formed instruction
             sta reg_a
             sty reg_y
             stx reg_x
             lda ramloc+0
             sta 02001h
             ora #0e7h      ;set all but the 2 bits of interest
             tax
             lda ppustat
             ora #018h
             .db 08fh
             .dw ppustat    ;sax ppustat

p2002w:      jmp edone
             
;----------------------------------------------------------------------
;PPU register 2002h

ppu2002x:    tya
             and #020h
             beq p2002w
             lda #(icount & 0ffh)
             sta ramloc+1
             lda #(icount >> 8)
             sta ramloc+2
             lda #0bfh
             and icount
             sta icount
             .db 0afh
             .dw 02002h         ;lax 02002h
             and #040h
             ora icount
             sta icount         ;copy over sprite 0 hit flag
             txa
             bpl npp
             jsr ppu2002r

npp:         lda ppustat    ;reset 2005/2006 flipflop
             and #0bfh
             sta ppustat
             tya
             and #0e3h
             ora #00ch      ;force all opcodes to be absolute
             sta ramloc+0
             lda reg_p
             tax
             ora #004h      ;no IRQs allowed
             pha
             txa
             and #004h
             sta reg_p      ;blow away all the bits in P except I
             ldx reg_x
             ldy reg_y
             lda reg_a
             plp
             jsr ramloc     ;execution formed instruction
             php
             sta reg_a
             sty reg_y
             stx reg_x
             pla
             and #0fbh      ;strip IRQ flag
             ora reg_p
             sta reg_p      ;OR new bits on
             lda #07fh
             and icount
             sta icount     ;clear that flag
             jmp edone

;----------------------------------------------------------------------
;PPU register 2005h


ppu2005x:    lda #((p2005+0) >> 8)
             sta ramloc+2           ;store upper 8 bits of pointer
             bit ppustat
             bvc p2005l             ;check bit state
             lda #((p2005+1) & 0ffh)
             sta ramloc+1
             lda ppustat
             and #0bfh
             sta ppustat
             jmp idone

p2005l:      lda #((p2005+0) & 0ffh)
             sta ramloc+1
             lda ppustat
             ora #040h
             sta ppustat
             jmp idone

;----------------------------------------------------------------------
;PPU register 2006h


ppu2006x:    bit ppustat
             bvs p2006l             ;check bit state
             
             lda #((ramloc+0) & 0ffh)
             sta ramloc+1
             lda #((ramloc+0) >> 8)
             sta ramloc+2
             tya
             and #0e3h
             ora #00ch      ;force all opcodes to be absolute
             sta ramloc+0
             ldx reg_x
             ldy reg_y
             lda reg_a
             jsr ramloc     ;execute formed instruction
             sta reg_a
             sty reg_y
             stx reg_x
             
             lda #03fh     ;port chip code
             sta p2006hi   ;#
             lda ramloc+0  ;#
             and #03fh     ;#
             ora #080h     ;#
             sta p2006hi   ;#
             
             lda #040h      ;set bit we'll check
             ora ppustat
             sta ppustat
             jmp edone
             
p2006l:      lda #(p2006lo & 0ffh)
             sta ramloc+1
             lda #(p2006lo >> 8)
             sta ramloc+2
             lda ppustat
             and #0bfh
             sta ppustat
             jmp idone

;----------------------------------------------------------------------
;PPU register 2007h

ppu2007x:    lda #018h
             bit ppustat    ;check state of PPU to see if rendering
             beq notrend    ;nope, so we're free to read/write

p2007wt:     bit 02002h     ;wait for PPU to be ready
             bpl p2007wt
             
notrend:     lda p2006hi    ;write new address
             sta 02006h
             lda p2006lo
             sta 02006h
             lda #004h
             bit ppustat
             beq nt_next    ;perform increment (by 1 or by 32)

             lda #020h
             .db 02ch
nt_next:     lda #001h
             clc
             adc p2006lo
             sta p2006lo
             bcs ysi2006
             jmp noi2006

ysi2006:             
             lda p2006hi    ;code for port chip use
             ldx #03fh      ;#
             stx p2006hi    ;# clear lower 6 bits only
             adc #000h      ;# add on upper bit
             and #03fh      ;# strip middle bit
             ora #080h
             sta p2006hi
             
noi2006:     tya
             and #020h      ;check to see if this is a load or store
             beq p2007w     ;store
             lda ppustat    ;see if this is the first load
             lsr a
             bcc fload      ;yep
             ldx 02007h     ;do load, this isn't the first time
             sec
             rol a          ;set bit
             sta ppustat
             bne fload      ;shifted in carry = always nonzero

p2007w:      lda ppustat    ;writing... reset flag
             and #0feh
             sta ppustat
             
fload:       tya            ;do the read/write on 2007
             and #0e3h
             ora #00ch      ;force all opcodes to be absolute
             sta ramloc+0
             lda reg_p
             tax
             ora #004h      ;no IRQs allowed
             pha
             txa
             and #004h
             sta reg_p      ;blow away all the bits in P except I
             ldx reg_x
             ldy reg_y
             lda reg_a
             plp
             jsr ramloc     ;execution formed instruction
             php
             sta reg_a
             sty reg_y
             stx reg_x
             pla
             and #0fbh      ;strip IRQ flag
             ora reg_p
             sta reg_p      ;OR new bits on
             lda p2005+0
             sta 02005h
             lda p2005+1    ;reload 2005/2000
             sta 02005h
             lda icount
             and #03fh
             sta 02000h
             jmp edone

;----------------------------------------------------------------------
;wait for PPU vblank & restore registers


ppuwait:     lda #020h
             bit ppustat
             beq noppuworry   ;if clear, don't worry about PPU waits
             
ppuwait2:    bit 02002h
             bpl ppuwait2
             
ppu2002r:    lda p2005+0
             sta 02005h
             lda p2005+1
             sta 02005h
             lda p2006hi
             sta 02006h
             lda p2006lo
             sta 02006h
             lda icount
             and #03fh
             sta 02000h
             
noppuworry:  rts

;------------------------------
;grab data from PC and inc

;reload LDA opcode and grab byte from RAM and inc PC
pcfetch2:    lda #0adh
             sta ramloc+0
             
;same as below, but clear carry here to save bytes later
pcfetch7:    clc
;grab byte from RAM and inc PC
pcfetch:     lda reg_pcl
             sta ramloc+1
             lda reg_pch
             sta ramloc+2
             inc reg_pcl
             bne noincx
             inc reg_pch

noincx:      jmp ramloc

;PC fetch for absolute stuff
pcfetch4:    lda reg_pcl
             sta ramloc+1
             lda reg_pch
             sta ramloc+2
             jmp ramloc

pcfetch5:    tax
             inc reg_pcl
             inc ramloc+1
             bne noincx8
             inc reg_pch
             inc ramloc+2
             
noincx8:     jmp ramloc
             
pcfetch6:    sta ramloc+2
             stx ramloc+1
             inc reg_pcl
             bne noincx9
             inc reg_pch

noincx9:     clc              ;clear this for later
             rts

;handle page crossings
pagecross:   inc ramloc+2
             
pagecross2:  lda cyclecount+0             
             ora cyclecount+1
             beq nocross
             lda cyclecount+0
             bne nocross2
             dec cyclecount+1
             
nocross2:    dec cyclecount+0
             
nocross:     rts

;---------------------------------
;stack stuff

;push acc onto stack safely
safepush:    ldx reg_s
             sta 0100h,x
             dex
             cpx #0ffh
             bne swrap1
             ldx #topostack

swrap1:      stx reg_s
             rts
             
;----------
;pop acc from stack safely
safepop:     ldx reg_s
             cpx #topostack
             bne swrap2
             ldx #0ffh

swrap2:      inx
             stx reg_s
             lda 0100h,x
             rts



;0  - emulate 1 instruction at the current PC
;1  - load registers
;2  - read registers
;3  - disassemble (no invalid opcodes)
;4  - dump address space
;5  - read back PC
;6  - write new PC
;7  - do disassembly with invalid opcodes
;8  - perform NMI
;9  - perform reset
;A  - perform IRQ
;B  - write byte to address space
;C  - grab bank data
;D  - execute to breakpoint
;E  - set emulation mode flags


             jmp mainx

emustrt:     ldx #realstack
             txs
           
             lda 0fffch
             sta reg_pcl
             lda 0fffdh
             sta reg_pch
            
             
             lda #000h
             sta reg_a
             sta reg_x
             sta reg_y
             sta reg_p
             sta brkpt+0
             sta brkpt+1
             lda #topostack
             sta reg_s        ;load emulator variables
             
             lda #022h
             sta ppustat
             
             lda #07fh        ;make it run continuously
             sta p2006hi

             jmp emul8


main2:       lda 0fffch
             sta reg_pcl
             lda 0fffdh
             sta reg_pch
             
             lda #(vblank & 0ffh)   ;set up cycle count for vblank
             sta cyclecount+0
             lda #(vblank >> 8)
             sta cyclecount+1
             lda #00h
             sta nothreg1   ;bit 6 holds PPU mode (0 = vbl, 1 = rendering)
             lda #022h
             sta ppustat

             lda #000h
             sta reg_a
             sta reg_x
             sta reg_y
             lda #034h
             sta reg_p
             lda #topostack
             sta reg_s        ;load emulator variables
             
             ldx #realstack
             txs

mainx:       jsr read_byte            ;wait for PC to send something
             and #0fh
             asl a
             tax
             lda wheretab+0,x
             sta ramloc+1
             lda wheretab+1,x
             sta ramloc+2
             jmp (ramloc+1)

wheretab:    .dw emulate,loadregs,readregs,dodis       ;0 1 2 3
             .dw dump,rdpc,wrpc,dodis2                 ;4 5 6 7
             .dw donmi,dorst,doirq,wbyte               ;8 9 A B
             .dw gbanks,go2brk,setmode,mainx           ;C D E F

setmode:     jsr read_byte
             and #022h         ;only allow updating 2 bits
             sta ramloc+0
             lda ppustat
             and #0ddh
             ora ramloc+0
             sta ppustat
             jmp mainx

gbanks:      lda #0adh
             sta ramloc+0
             lda #080h
             sta ramloc+1
             sta ramloc+2

             ldy #020h

gbloop:      lda #060h
             sta ramloc+3
             jsr ramloc
             jsr write_byte
             lda #04h
             clc
             adc ramloc+1
             sta ramloc+1
             sta ramloc+2
             dey
             bne gbloop           ;write out 32 bytes of PRG ROM

             ldy #01fh

gbloop2:     sty 02006h
             sty 02006h
             lda 02007h
             lda 02007h
             jsr write_byte      ;write out 32 bytes of CHR ROM
             dey
             bpl gbloop2
             jmp mainx          

wbyte:       jsr read_byte
             sta ramloc+1
             jsr read_byte
             sta ramloc+2
             jsr read_byte
             ldx #08dh
             stx ramloc+0
             ldx #060h
             stx ramloc+3
             jsr ramloc        ;write byte out
             jmp mainx

dorst:       ldy #0fch
             lda #004h
             ora reg_p
             sta reg_p
             bne genirq

doirq:       ldy #0feh
             lda #004h
             ora reg_p
             sta reg_p      ;set I flag
             bne genirq

donmi:       ldy #0fah

genirq:      lda reg_pch
             jsr safepush
             lda reg_pcl
             jsr safepush
             lda reg_p
             ora #030h
             jsr safepush
             lda 0ff00h,y   ;get new address
             sta reg_pcl
             lda 0ff01h,y
             sta reg_pch
             jmp mainx

rdpc:        lda reg_pcl
             jsr write_byte
             lda reg_pch
             jsr write_byte
             jmp mainx

wrpc:        jsr read_byte
             sta reg_pcl
             jsr read_byte
             sta reg_pch
             jmp mainx


dump:        jsr read_byte
             sta ramloc+1
             jsr read_byte
             sta ramloc+2
             jsr read_byte
             tay
             lda #0adh
             sta ramloc+0
             
dumplp:      lda #060h
             sta ramloc+3
             jsr ramloc
             jsr write_byte
             inc ramloc+1
             bne dlpno
             inc ramloc+2
             
dlpno:       dey
             bne dumplp
             jmp mainx


;store register set from PC into emulator
loadregs:    ldy #0

lr_loop2:    jsr read_byte
             sta reg_a,y
             iny
             cpy #07h
             bne lr_loop2
             jsr read_byte
             sta brkpt+0
             jsr read_byte
             sta brkpt+1
             jmp mainx

;read back register set from PC into emulator
readregs:    ldy #0

rr_loop:     lda reg_a,y
             jsr write_byte
             iny
             cpy #07h
             bne rr_loop
             lda brkpt+0
             jsr write_byte
             lda brkpt+1
             jsr write_byte
             lda cyclecount+0   ;write out cycle count
             jsr write_byte
             lda cyclecount+1
             jsr write_byte
             lda nothreg1
             jsr write_byte
             jmp mainx


;figure out where disassembly should start by counting bytes in front of
;current disassembly position
dodis:       lda #0adh         ;LDA abs
             sta ramloc+0
             
             lda reg_pcl
             sec
             sbc #03fh        ;point to PC-40h
             sta ramloc+1
             ldx reg_pch
             bcs nodecw
             dex
             
nodecw:      stx ramloc+2     ;make LDA abs,y instruction

             ldy #000h
             ldx #000h        ;# of entries
            
             
floop1:      lda #060h        ;rts
             sta ramloc+3
             jsr ramloc       ;calculated LDA abs,y : RTS
             stx ramloc+3
             tax
             tya
             sec
             adc insize,x
             tay
             sec
             lda ramloc+1
             adc insize,x
             sta ramloc+1
             bcc noincy
             inc ramloc+2

noincy:      ldx ramloc+3
             inx
             cpy #03fh
             bcc floop1       ;do it until we run out
             txa
             sbc #08h         ;go back 8 entries (note: carry will be set)
             tax
             
             lda reg_pcl
             sec
             sbc #03fh        ;point to PC-40h
             sta ramloc+1
             ldy reg_pch
             bcs nodecq
             dey
             
nodecq:      sty ramloc+2     ;make LDA abs,y instruction

             ldy #000h

floop2:      lda #060h
             sta ramloc+3
             jsr ramloc
             stx ramloc+3
             tax
             tya
             sec
             adc insize,x
             tay
             sec
             lda ramloc+1
             adc insize,x
             sta ramloc+1
             bcc noinch
             inc ramloc+2

noinch:      ldx ramloc+3
             dex
             bne floop2       ;get us where we wanna go
             tya
             eor #0ffh
             clc
             adc #040h        ;-Y+3fh
             jsr write_byte

floop3:      lda #060h
             sta ramloc+3
             jsr ramloc
             jsr write_byte
             inc ramloc+1
             bne noincj
             inc ramloc+2

noincj:      iny
             cpy #03fh
             bcc floop3       ;send out bytes up to current PC

;---  send out data at PC down to 8 instructions

             lda reg_pcl
             sta ramloc+1
             lda reg_pch
             sta ramloc+2     ;get current PC
             ldy #08h
     ;        lda #0adh
     ;        sta ramloc+0     ;change to LDA instruction

floop5:      lda #060h
             sta ramloc+3
             jsr ramloc
             jsr write_byte    ;opcode
             lda #060h
             sta ramloc+3
             jsr ramloc
             tax
             inc ramloc+1
             bne noincx0
             inc ramloc+2
             
noincx0:     lda insize,x
             tax
             inx
             txa
             stx ramloc+0
             jsr write_byte    ;size
             ldx ramloc+0
             lda #0adh
             sta ramloc+0
             dex
             beq idonex
             
floop4:      lda #060h
             sta ramloc+3
             jsr ramloc
             stx ramloc+0
             jsr write_byte    ;byte 1/2 (if used)
             ldx ramloc+0
             lda #0adh
             sta ramloc+0
             inc ramloc+1
             bne noincx1
             inc ramloc+2
             
noincx1:     dex
             bne floop4       ;sent all bytes
             
idonex:      dey
             bne floop5
             lda #069h
             jsr write_byte          
             jmp mainx


;second copy that uses invalid opcodes

dodis2:      lda #0adh         ;LDA abs
             sta ramloc+0
             
             lda reg_pcl
             sec
             sbc #03fh        ;point to PC-40h
             sta ramloc+1
             ldx reg_pch
             bcs nodecw2
             dex
             
nodecw2:     stx ramloc+2     ;make LDA abs,y instruction

             ldy #000h
             ldx #000h        ;# of entries
            
             
floop12:     lda #060h        ;rts
             sta ramloc+3
             jsr ramloc       ;calculated LDA abs,y : RTS
             stx ramloc+3
             tax
             tya
             sec
             adc insize2,x
             tay
             sec
             lda ramloc+1
             adc insize2,x
             sta ramloc+1
             bcc noincy2
             inc ramloc+2

noincy2:     ldx ramloc+3
             inx
             cpy #03fh
             bcc floop12       ;do it until we run out
             txa
             sbc #08h         ;go back 8 entries (note: carry will be set)
             tax
             
             lda reg_pcl
             sec
             sbc #03fh        ;point to PC-40h
             sta ramloc+1
             ldy reg_pch
             bcs nodecq2
             dey
             
nodecq2:     sty ramloc+2     ;make LDA abs,y instruction

             ldy #000h

floop22:     lda #060h
             sta ramloc+3
             jsr ramloc
             stx ramloc+3
             tax
             tya
             sec
             adc insize2,x
             tay
             sec
             lda ramloc+1
             adc insize2,x
             sta ramloc+1
             bcc noinch2
             inc ramloc+2

noinch2:     ldx ramloc+3
             dex
             bne floop22       ;get us where we wanna go
             tya
             eor #0ffh
             clc
             adc #040h        ;-Y+3fh
             jsr write_byte

floop32:     lda #060h
             sta ramloc+3
             jsr ramloc
             jsr write_byte
             inc ramloc+1
             bne noincj2
             inc ramloc+2

noincj2:     iny
             cpy #03fh
             bcc floop32       ;send out bytes up to current PC

;---  send out data at PC down to 8 instructions

             lda reg_pcl
             sta ramloc+1
             lda reg_pch
             sta ramloc+2     ;get current PC
             ldy #08h
     ;        lda #0adh
     ;        sta ramloc+0     ;change to LDA instruction

floop52:     lda #060h
             sta ramloc+3
             jsr ramloc
             jsr write_byte    ;opcode
             lda #060h
             sta ramloc+3
             jsr ramloc
             tax
             inc ramloc+1
             bne noincx02
             inc ramloc+2
             
noincx02:    lda insize2,x
             tax
             inx
             txa
             stx ramloc+0
             jsr write_byte    ;size
             ldx ramloc+0
             lda #0adh
             sta ramloc+0
             dex
             beq idonex2
             
floop42:     lda #060h
             sta ramloc+3
             jsr ramloc
             stx ramloc+0
             jsr write_byte    ;byte 1/2 (if used)
             ldx ramloc+0
             lda #0adh
             sta ramloc+0
             inc ramloc+1
             bne noincx12
             inc ramloc+2
             
noincx12:    dex
             bne floop42       ;sent all bytes
             
idonex2:     dey
             bne floop52
             lda #069h
             jsr write_byte
             jmp mainx


;---------------------
;I/O routines
read_byte:
             lda #000h
             sta port+03h       ;set 6522 data port to input mode
read_byte_rxe:
             lda port+00h       ;load control bus
             and #020h        
             bne read_byte_rxe  ;make sure read enabled /RXE D5 = 0
             
             lda port+00h       ;load control bus
             and #0EFh          ;set read /RD D4 = 0
             sta port+00h       ;store new control bus
             
             ldx port+01h       ;read data bus
             
             lda port+00h       ;load control bus
             ora #010h          ;set read /RD D4 = 1
             sta port+00h       ;store new control bus
             
             txa                ;put new data in a
             rts
             




write_byte:  
             sta port+01h       ;set data bus
             lda #0ffh
             sta port+03h       ;set 6522 data port to output mode
write_byte_txe:
             lda port+00h       ;load control bus
             and #080h       
             bne write_byte_txe ;make sure read enabled /TXE D7 = 0
             
             
             lda port+00h       ;load control bus
             ora #004h
             sta port+00h       ;set write WR D2 = 1
             
             lda port+00h       ;load control bus
             and #0FBh          
             sta port+00h       ;set write WR D2 = 0
             
             lda #000h
             sta port+03h       ;set 6522 data port to input mode
             rts



init_port:   lda #000h   
             sta port+0bh       ;ACR register  timer disabled
             
             lda #0ffh   
             sta port+0ch       ;PCR register
             sta port+01h       ;set data bus
             
             lda #0FAh          ;carten=0, wr=0               1111 1010
             sta port+00h       ;set control port data
             
             lda #01Fh          ;                             7654 3210     0=in  1=out
             sta port+02h       ;set control port DIRECTION   0001 1111
                                                             ;D7 in  = /TXE
                                                             ;D6 in  = PLAY/COPY
                                                             ;D5 in  = /RXE
                                                             ;D4 out = /RD
                                                             ;D3 out = EXP0
                                                             ;D2 out = WR
                                                             ;D1 out = enable/disable bios
                                                             ;D0 out = enable/disable cart
             
             lda #000h
             sta port+03h       ;set data to input mode
             rts



;--------------------------------------------------------------------------




             .fill 02000h-*,0ffh


             .org 03000h


;---------------------------------------------------------
;Subroutines
;---------------------------------------------------------


ram_dat:     lda #0fch
             sta port+00h  ;disable decoder totally     ;turning off bios - control D1=0  D0=0
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
             
init_ppu:    lda #0h
             sta 02000h
             sta 02001h     ;turn off PPU
             
wait_1:      lda 02002h             
             bpl wait_1

wait_2:      lda 02002h
             bpl wait_2     ;wait 2 screens
             rts

baton:       rts            ;removed lcd code

set_in:      lda #000h       ;set data port to all inputs
             sta port+03h
             rts

set_out:     lda #0ffh       ;set data port to all outputs
             sta port+03h
             rts

load_ram:    ldx #0
             txa

lr_loop:     sta 0,x
             .db 09dh,0fch,000h    ;absolute write
             sta 0200h,x
             sta 0300h,x
             sta 0400h,x
             sta 0500h,x
             sta 0600h,x
             sta 0700h,x
             dex
             bne lr_loop
             
             ldx #07h
             
lr2_loop:    lda ram_dat,x
             sta 0700h,x
             dex
             bpl lr2_loop
             
             jmp back_here


;int_err:     sei
;             lda #0
;             sta 02000h
;             sta 02001h
;             sta 04015h
;             sta 04017h
             
;ie_lp:       jmp ie_lp


nmi:         inc nmicounter
             rti

irq:         inc irqcounter
             rti


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

do_crc:      
;             sta load
;             txa
;             pha
;             lda load
             eor crc0        ;xor with first CRC
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
;             pla
;             tax
             rts

             
finish_crc:  ldx #3
             
fin_loop:    lda #0ffh
             eor crc0,x
             sta crc0,x
             dex
             bpl fin_loop
             rts
             

             .fill 03700h-*,0ffh

;----------------------------------------------------------------

;make sure these tables are page-aligned

;make sure it takes up a page on its own to prevent page cross slowdown
;size of each instruction, in bytes
insize:   .db 001h,001h,000h,000h,000h,001h,001h,000h
          .db 000h,001h,000h,000h,000h,002h,002h,000h
          .db 001h,001h,000h,000h,000h,001h,001h,000h
          .db 000h,002h,000h,000h,000h,002h,002h,000h
          .db 002h,001h,000h,000h,001h,001h,001h,000h
          .db 000h,001h,000h,000h,002h,002h,002h,000h
          .db 001h,001h,000h,000h,000h,001h,001h,000h
          .db 000h,002h,000h,000h,000h,002h,002h,000h
          .db 000h,001h,000h,000h,000h,001h,001h,000h
          .db 000h,001h,000h,000h,002h,002h,002h,000h
          .db 001h,001h,000h,000h,000h,001h,001h,000h
          .db 000h,002h,000h,000h,000h,002h,002h,000h
          .db 000h,001h,000h,000h,000h,001h,001h,000h
          .db 000h,001h,000h,000h,002h,002h,002h,000h
          .db 001h,001h,000h,000h,000h,001h,001h,000h
          .db 000h,002h,000h,000h,000h,002h,002h,000h
          .db 000h,001h,000h,000h,001h,001h,001h,000h
          .db 000h,000h,000h,000h,002h,002h,002h,000h
          .db 001h,001h,000h,000h,001h,001h,001h,000h
          .db 000h,002h,000h,000h,000h,002h,000h,000h
          .db 001h,001h,001h,000h,001h,001h,001h,000h
          .db 000h,001h,000h,000h,002h,002h,002h,000h
          .db 001h,001h,000h,000h,001h,001h,001h,000h
          .db 000h,002h,000h,000h,002h,002h,002h,000h
          .db 001h,001h,000h,000h,001h,001h,001h,000h
          .db 000h,001h,000h,000h,002h,002h,002h,000h
          .db 001h,001h,000h,000h,000h,001h,001h,000h
          .db 000h,002h,000h,000h,000h,002h,002h,000h
          .db 001h,001h,000h,000h,001h,001h,001h,000h
          .db 000h,001h,000h,000h,002h,002h,002h,000h
          .db 001h,001h,000h,000h,000h,001h,001h,000h
          .db 000h,002h,000h,000h,000h,002h,002h,000h

;all the invalid opcodes enabled
insize2:  .db 001h,001h,000h,001h,001h,001h,001h,001h
          .db 000h,001h,000h,001h,002h,002h,002h,002h
          .db 001h,001h,000h,001h,001h,001h,001h,001h
          .db 000h,002h,000h,002h,002h,002h,002h,002h
          .db 002h,001h,000h,001h,001h,001h,001h,001h
          .db 000h,001h,000h,001h,002h,002h,002h,002h
          .db 001h,001h,000h,001h,001h,001h,001h,001h
          .db 000h,002h,000h,002h,002h,002h,002h,002h
          .db 000h,001h,000h,001h,001h,001h,001h,001h
          .db 000h,001h,000h,001h,002h,002h,002h,002h
          .db 001h,001h,000h,001h,001h,001h,001h,001h
          .db 000h,002h,000h,002h,002h,002h,002h,002h
          .db 000h,001h,000h,001h,001h,001h,001h,001h
          .db 000h,001h,000h,001h,002h,002h,002h,002h
          .db 001h,001h,000h,001h,001h,001h,001h,001h
          .db 000h,002h,000h,002h,002h,002h,002h,002h
          .db 000h,001h,000h,001h,001h,001h,001h,001h
          .db 000h,000h,000h,001h,002h,002h,002h,002h
          .db 001h,001h,000h,001h,001h,001h,001h,001h
          .db 000h,002h,000h,002h,002h,002h,002h,002h
          .db 001h,001h,001h,001h,001h,001h,001h,001h
          .db 000h,001h,000h,001h,002h,002h,002h,002h
          .db 001h,001h,000h,001h,001h,001h,001h,001h
          .db 000h,002h,000h,002h,002h,002h,002h,002h
          .db 001h,001h,000h,001h,001h,001h,001h,001h
          .db 000h,001h,000h,001h,002h,002h,002h,002h
          .db 001h,001h,000h,001h,001h,001h,001h,001h
          .db 000h,002h,000h,002h,002h,002h,002h,002h
          .db 001h,001h,000h,001h,001h,001h,001h,001h
          .db 000h,001h,000h,001h,002h,002h,002h,002h
          .db 001h,001h,000h,001h,001h,001h,001h,001h
          .db 000h,002h,000h,002h,002h,002h,002h,002h


indx      .equ (mode_indx & 0ffh)
indy      .equ (mode_indy & 0ffh)
halt      .equ (mode_halt & 0ffh)
zero      .equ (mode_zero & 0ffh)
zerx      .equ (mode_zerx & 0ffh)
zery      .equ (mode_zery & 0ffh)
immd      .equ (mode_immd & 0ffh)
impl      .equ (mode_impl & 0ffh)
abso      .equ (mode_abso & 0ffh)
absx      .equ (mode_absx & 0ffh)
absy      .equ (mode_absy & 0ffh)
bran      .equ (mode_bran & 0ffh)
nop2      .equ (mode_nop2 & 0ffh)
nop3      .equ (mode_nop3 & 0ffh)

op00      .equ (mode_op00 & 0ffh)
op08      .equ (mode_op08 & 0ffh)
op20      .equ (mode_op20 & 0ffh)
op28      .equ (mode_op28 & 0ffh)
op40      .equ (mode_op40 & 0ffh)
op48      .equ (mode_op48 & 0ffh)
op4c      .equ (mode_op4c & 0ffh)
op60      .equ (mode_op60 & 0ffh)
op68      .equ (mode_op68 & 0ffh)
op6c      .equ (mode_op6c & 0ffh)
op58      .equ (mode_op58 & 0ffh)
op78      .equ (mode_op78 & 0ffh)
op9a      .equ (mode_op9a & 0ffh)
opba      .equ (mode_opba & 0ffh)


amode:    .db op00,indx,halt,indx,zero,zero,zero,zero
          .db op08,immd,impl,immd,abso,abso,abso,abso
          .db bran,indy,halt,indy,zerx,zerx,zerx,zerx
          .db impl,absy,impl,absy,absx,absx,absx,absx

          .db op20,indx,halt,indx,zero,zero,zero,zero
          .db op28,immd,impl,immd,abso,abso,abso,abso
          .db bran,indy,halt,indy,nop2,zerx,zerx,zerx
          .db impl,absy,impl,absy,nop3,absx,absx,absx

          .db op40,indx,halt,indx,nop2,zero,zero,zero
          .db op48,immd,impl,immd,op4c,abso,abso,abso
          .db bran,indy,halt,indy,nop2,zerx,zerx,zerx
          .db op58,absy,impl,absy,nop3,absx,absx,absx

          .db op60,indx,halt,indx,nop2,zero,zero,zero
          .db op68,immd,impl,immd,op6c,abso,abso,abso
          .db bran,indy,halt,indy,nop2,zerx,zerx,zerx
          .db op78,absy,impl,absy,nop3,absx,absx,absx

          .db immd,indx,halt,indx,zero,zero,zero,zero
          .db impl,immd,impl,immd,abso,abso,abso,abso
          .db bran,indy,halt,indy,zerx,zerx,zery,zery
          .db impl,absy,op9a,absy,absx,absx,absy,absy

          .db immd,indx,immd,indx,zero,zero,zero,zero
          .db impl,immd,impl,immd,abso,abso,abso,abso
          .db bran,indy,halt,indy,zerx,zerx,zery,zery
          .db impl,absy,opba,absy,absx,absx,absy,absy

          .db immd,indx,halt,indx,zero,zero,zero,zero
          .db impl,immd,impl,immd,abso,abso,abso,abso
          .db bran,indy,halt,indy,nop2,zerx,zerx,zerx
          .db impl,absy,impl,absy,nop3,absx,absx,absx

          .db immd,indx,halt,indx,zero,zero,zero,zero
          .db impl,immd,impl,immd,abso,abso,abso,abso
          .db bran,indy,halt,indy,nop2,zerx,zerx,zerx
          .db impl,absy,impl,absy,nop3,absx,absx,absx

;cycle counts for the length of each instruction
cyctab:   .db 7,6,0,8,3,3,5,5
          .db 3,2,2,2,4,4,6,6
          .db 2,5,0,7,4,4,6,6
          .db 2,4,2,4,4,4,7,7

          .db 6,6,0,8,3,3,5,5
          .db 4,2,2,2,4,4,6,6
          .db 2,5,0,7,4,4,6,6
          .db 2,4,2,4,4,4,7,7

          .db 6,6,0,8,3,3,5,5
          .db 3,2,2,2,4,4,6,6
          .db 2,5,0,7,4,4,6,6
          .db 2,4,2,4,4,4,7,7

          .db 6,6,0,8,3,3,5,5
          .db 4,2,2,2,4,4,6,6
          .db 2,5,0,7,4,4,6,6
          .db 2,4,2,4,4,4,7,7

          .db 2,6,0,6,3,3,3,3
          .db 2,2,2,2,4,4,4,4
          .db 2,6,0,5,4,4,4,4
          .db 2,4,2,4,4,4,4,4

          .db 2,6,2,6,3,3,3,3
          .db 2,2,2,2,4,4,4,4
          .db 2,5,0,5,4,4,4,4
          .db 2,4,2,4,4,4,4,4

          .db 2,6,0,8,3,3,5,5
          .db 2,2,2,2,4,4,6,6
          .db 2,5,0,7,4,4,6,6
          .db 2,4,2,6,4,4,7,7

          .db 2,6,0,8,3,3,5,5
          .db 2,2,2,2,4,4,6,6
          .db 2,5,0,7,4,4,6,6
          .db 2,4,2,6,4,4,7,7

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

identify2:   jsr set_out
             lda #04h               ;send version 4
             jsr write_byte
             jmp main

identify:    ldy #00
             jsr set_out
             
identloop:   lda 03fc0h,y
             jsr write_byte
             iny
             cpy #58d
             bne identloop
             jmp main

             .fill 03fc0h-*,023h

             .db "USB CopyNES "          ;11
             .db "V4.00 (c) Kev"        ;13
             .db "in Horton & Brian"    ;17
             .db " Parker 8.16.07",0   ;17

             
             .dw nmi
             ;.dw start
             .dw check_play_mode
             .dw irq
             
             .end


