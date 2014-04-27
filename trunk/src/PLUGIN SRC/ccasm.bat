cd temp
del /q *.*
cd ..
cc65\bin\ca65 pluginlib\bioscalls.s -o temp\bioscalls.o -g
cc65\bin\ca65 %1.s -o temp\%1.o -g
cc65\bin\ld65 -o %1.bin -C pluginlib\plugin.cfg temp\%1.o temp\bioscalls.o
