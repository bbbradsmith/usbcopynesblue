
tasm -65 -x %1.asm
del %1.int
ren %1.obj %1.int
ffc %1.int %1.bin
rem move %1.bin ..\plugdone\
