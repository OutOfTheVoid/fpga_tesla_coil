# FPGA-Based tesla coil controller
SystemVerilog code for a solid state tesla coil controller running on a Tang Nano 9k FPGA.

Currently just a basic frequency-locked loop with an interrupter.

Video of the coil in action: https://www.youtube.com/watch?v=hA358tcXEGo

# Goals
- 1.2GHz IO-Clock with OSER16/IDES16 primitives (and 75MHz system clock for processing)
- Switching synchronous gate drive enable
- Gate-driver delay-lead compensation
- Over-current detection for DRSSTC operation
- QCW Phase shifting for long sparks
- RV32 softcore for serial control and easy configuration via firmware
