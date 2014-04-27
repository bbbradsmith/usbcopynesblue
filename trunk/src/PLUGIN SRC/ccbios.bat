cd temp
del /q *.*
cd ..\BIOS
..\cc65\bin\ca65 bios.s -o ..\TEMP\bios.o -g
..\cc65\bin\ld65 -C usbbios.cfg ..\TEMP\bios.o
cd ..\temp
del /q *.*
cd ..\BIOS
..\cc65\bin\ca65 bios.s -o ..\TEMP\bios.o -g -D PARALLELPORT
..\cc65\bin\ld65 -C ppbios.cfg ..\TEMP\bios.o
cd ..