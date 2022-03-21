@echo off
echo 5110VEMU Demo1 Example
echo .
echo Demonstrate using scripted input to access DSP after startup,
echo then use ALTER commands to input ASM/machine code instructions.
echo .
echo Note that Interrupt Level 0 will enter RWS mode in this example.
echo .
echo Reminder: the emulator interactive mode is not available until
echo the script has been fully input (this is indicated when all the
echo ROS and CPU states are displayed).
echo .
emu5110_Release_x64.exe a 0 command_input_ball_bounce_ASM.txt

