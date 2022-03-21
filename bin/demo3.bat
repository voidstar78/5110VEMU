@echo off
echo
echo Wait for the short BASIC program to be entered.
echo type "RUN" once it is ready.
echo Use F5 to activate STEP MODE and explore the state changes.
echo Especially observe that at end of BASIC statements, the machine swaps back to EXECUTIVE.
echo
emu5110_Release_x64.exe b 0 command_input_simple_BAS.txt


