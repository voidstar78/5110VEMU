# 5110VEMU
voidstar's IBM 5110 Wintel Compatible Emulator (VERSION2)

Word and PDF overview orientation documentation in the DOCS folder.

Currently only Microsoft Visual Studio 2010 solution file.  Those easily update to 2015, 2017, 2019 version (if opened by those versions).

Pre-built binary in the BIN folder has been updated (or see RELEASE folder).

ROS/ROM required to be in same folder as the executable.

This is a utility to explore the PALM opcodes and instruction set, which includes a STEP-MODE and integrated DISASSEMBLER.  As such, this emulator
doesn't have a lot of bells and whistles luxury features.

New for this VERSION2:

- added WHITE/YELLOW alternating color for the registers, to make it easier to see one register value from another
- extended the DISASSEMBLER to be multi-line instead of "next instruction" only (there is a quirk during startup, if a breakpoint is set the instruction at the breakpoint has been executed yet)
- added some vertical lines to the memory monitor to make it easier to see groups of addresses



