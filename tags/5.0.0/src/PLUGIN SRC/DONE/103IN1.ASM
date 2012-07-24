             .title        "SID freq reg tester thingus"


;06/10/00 
;Written by KH
;Version 1.0
             
             
             .org 0c000h
             

playit:      inc  temp1
             bne  pi_2
             inc  temp2

pi_2:        lda  temp1
             sta  0d400h
             lda  temp2
             sta  0d401h
             lda  temp1
             eor  #0ffh
             sta  0d408h
             lda  temp2
             eor  #0ffh
             sta  0d409h
             rts

temp1:       db 0             
temp2:       db 0




             .end
