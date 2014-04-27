.export crc0
crc0		:= $80

.export crc1
crc1		:= $81

.export crc2
crc2		:= $82

.export crc3
crc3		:= $83

.export send_byte
send_byte	:= $0200

.export baton
baton		:= $0203

.export chk_vram
chk_vram	:= $0206

.export chk_wram
chk_wram	:= $0209

.export wr_ppu
wr_ppu		:= $020c

.export read_byte
read_byte	:= $020f

.export init_crc
init_crc	:= $0212

.export do_crc
do_crc		:= $0215

.export finish_crc
finish_crc	:= $0218