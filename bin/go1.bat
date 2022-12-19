asw -i ..\include sample1_bounce.asm
p2bin sample1_bounce.p

rem The following still works, but is the SLOW way.  Maybe useful for certain debugging...
rem asbin2vemu_Release_x64 sample1_bounce.bin > sample1_bounce_temp.txt
rem copy /b /y command_input_ASM_header.txt + sample1_bounce_temp.txt + command_input_ASM_footer.txt sample1_bounce.txt
rem emu5110_release_x64 a 0 sample1_bounce.txt

rem Just do this - command line argument 5 to just specify the BIN that will be loaded at 0B00
emu5110_release_x64 a 0 command_input_ASM_BR0B00.txt sample1_bounce.bin