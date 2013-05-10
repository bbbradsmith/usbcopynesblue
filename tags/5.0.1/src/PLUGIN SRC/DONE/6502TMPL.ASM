;standard NES/misc. 6502 template file
;for use with TASM (NOT turbo assembler) using the 6502 table.
;
;written by Kevin Horton on 07/25/02
;

             .org  00000h  ;zeropage start


;zeropage variables- often-used things, zeropage addressing.  only 256 bytes

adr1:        .block 1
adr2:        .block 1
adr3:        .block 1


; 0100h-01ffh = stack area.  not usable unless it's an emergency :-)

             .org 00200h   ;normal variables go here (not zero page)

;"normal" variables- not used very often
adr4:        .block 1
adr5:        .block 1




             .org 08000h    ;start of the code space on the NES and many 
                            ;other 6502 systems

;start of data space


;NMI interrupt
nmi:         pha  ;save acc, X, and Y. (P saved automagically)
             txa
             pha
             tya
             pha
             
          ;   nmi routine goes here

             pla  ;load acc, X, and Y
             tay
             pla
             tax
             pla
             rti  ;return from interrupt

;IRQ interrupt
irq:         pha  ;save acc, X, and Y. (P saved automagically)
             txa
             pha
             tya
             pha
             
          ;   irq routine goes here

             pla  ;load acc, X, and Y
             tay
             pla
             tax
             pla
             rti  ;return from interrupt

;start of code (pointed to by reset vector)
start:       sei            ;stop interrupts
             cld            ;clear decimal mode
             ldx #0ffh
             txs            ;init stack


          ;main program code goes here

             lda adr1      ;demo code
             adc adr2      ;zeropage
             sta adr3      ;zeropage

             lda #0        ;immediate
             sta 02000h    ;absolute
             sta 02001h    ;absolute
             
             asl adr4      ;absolute
             dec adr5      ;absolute


loop:        jmp loop      ;get stuck in endless loop



             .fill 0fffah-*,0ffh      ;fill empty space up to vectors

             .dw  nmi,start,irq       ;vectors


             .end
