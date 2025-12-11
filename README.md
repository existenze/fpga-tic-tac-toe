Introduction
The objective of this final project was to design and implement a fully functional
Tic-Tac-Toe game on the BASYS 3 FPGA using Verilog HDL. Building on the initial proposal, the
system allows two players to alternate placing X’s and O’s on a 3×3 grid displayed in real time
on a VGA monitor. User input is handled through the first nine switches on the board, each
corresponding to a specific cell, while the center push button provides a hardware reset. The
game logic tracks turns, validates moves, updates the board, and determines when a winning
condition has been reached. When a player wins, the game ends and no more inputs can be
placed. To reset the game board, all switches need to be in the off position and then the center
push button is pressed to refresh the VGA output.
This project integrates several design components. These include VGA timing
generation, pixel-level rendering, a finite-state machine for win detection, per-cell state modules,
and a seven-segment display used to show the current player's turn. The design was simulated,
synthesized, and implemented on the BASYS 3 board using Xilinx Vivado, and functionality was
verified through hardware testing. Overall, the project demonstrates the application of
Verilog-based digital design techniques to create an interactive, real-time game system.

Conclusion
This project successfully demonstrated the design and implementation of a complete
Tic-Tac-Toe game system on the BASYS 3 FPGA using Verilog HDL. The system accurately
processed player inputs, displayed the evolving game board on a VGA monitor, and correctly
detected horizontal, vertical, and diagonal win conditions. When a winning pattern occurred, the
remaining empty cells could no longer be filled. The use of a dedicated state machine for win
detection, individual cell modules for move storage, and a VGA drawing pipeline allowed for
clear modularity and reliable hardware behavior. The seven-segment display further enhanced
usability by showing the current player's turn throughout gameplay.
This project reinforced several key concepts from the course, including finite-state
machine design, synchronous logic, clock-driven video generation, and hardware-based input
handling. Completing the implementation on hardware provided valuable experience in
debugging timing-based systems and working with real-time graphical interfaces. Overall, the
Tic-Tac-Toe project served as a comprehensive demonstration of FPGA design principles
learned throughout the semester
