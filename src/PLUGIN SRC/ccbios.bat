cd BIOS
..\cc65\bin\ca65 bios.s -o ..\TEMP\bios.o -g
..\cc65\bin\ld65 -C bios.cfg ..\TEMP\bios.o
cd ..