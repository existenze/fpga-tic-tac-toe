`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2025 12:20:47 AM
// Design Name: 
// Module Name: gameLogic
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module gameLogic(
    // Video / clock
    input  wire       clk,
    input  wire       Reset,

    // Control (first 9 switches)
    input  wire [8:0] In,

    // VGA out
    output wire       hsync,
    output wire       vsync,
    output wire [11:0] rgb,

    // Status LED (winner)
    output wire       winState,

    // Seven-seg display
    output wire [6:0] seg,
    output wire [3:0] an,
    output wire       dp
);

    reg [8:0]  sqrSel;
    wire [17:0] Cells;
    reg [8:0]  prevIn;
    reg [8:0]  myIn;
    reg        Turn;      // 0 = X, 1 = O

    wire [8:0] Color;
    wire       winState_int;

    assign winState = winState_int;

    // Input decoding (same logic, just pure Verilog always @(*))
    always @(*) begin
        if (!winState_int) begin
            if      (In[6] && !Cells[16]) sqrSel = 9'b100000000;
            else if (In[7] && !Cells[14]) sqrSel = 9'b010000000;
            else if (In[8] && !Cells[12]) sqrSel = 9'b001000000;

            else if (In[3] && !Cells[10]) sqrSel = 9'b000100000;
            else if (In[4] && !Cells[8])  sqrSel = 9'b000010000;
            else if (In[5] && !Cells[6])  sqrSel = 9'b000001000;

            else if (In[0] && !Cells[4])  sqrSel = 9'b000000100;
            else if (In[1] && !Cells[2])  sqrSel = 9'b000000010;
            else if (In[2] && !Cells[0])  sqrSel = 9'b000000001;

            else                          sqrSel = 9'b000000000;
        end else begin
            sqrSel = 9'b000000000;
        end
    end

    // Turn toggling based on input edge
    always @(negedge clk or posedge Reset) begin
        if (Reset) begin
            Turn   <= 1'b0;       // X starts
            prevIn <= 9'b0;
            myIn   <= 9'b0;
        end else begin
            if (prevIn != myIn && myIn != 9'b0)
                Turn <= ~Turn;

            prevIn <= myIn;
            myIn   <= In;
        end
    end

    // Win checking
    gameState state_inst (
        .clk      (clk),
        .Reset    (Reset),
        .Cells    (Cells),
        .winState (winState_int),
        .Color    (Color)
    );

    // Video generator (grid + X/O + highlighting)
    videoElements VGA_inst (
        .clk   (clk),
        .reset (Reset),
        .Cells (Cells),
        .Color (Color),
        .Turn  (Turn),
        .hsync (hsync),
        .vsync (vsync),
        .rgb   (rgb)
    );

    // Board cells (9 instances)
    Cell cell1 (
        .clk  (clk), .Sel(sqrSel[0]), .Turn(Turn), .Reset(Reset),
        .State(Cells[1:0])
    );

    Cell cell2 (
        .clk  (clk), .Sel(sqrSel[1]), .Turn(Turn), .Reset(Reset),
        .State(Cells[3:2])
    );

    Cell cell3 (
        .clk  (clk), .Sel(sqrSel[2]), .Turn(Turn), .Reset(Reset),
        .State(Cells[5:4])
    );

    Cell cell4 (
        .clk  (clk), .Sel(sqrSel[3]), .Turn(Turn), .Reset(Reset),
        .State(Cells[7:6])
    );

    Cell cell5 (
        .clk  (clk), .Sel(sqrSel[4]), .Turn(Turn), .Reset(Reset),
        .State(Cells[9:8])
    );

    Cell cell6 (
        .clk  (clk), .Sel(sqrSel[5]), .Turn(Turn), .Reset(Reset),
        .State(Cells[11:10])
    );

    Cell cell7 (
        .clk  (clk), .Sel(sqrSel[6]), .Turn(Turn), .Reset(Reset),
        .State(Cells[13:12])
    );

    Cell cell8 (
        .clk  (clk), .Sel(sqrSel[7]), .Turn(Turn), .Reset(Reset),
        .State(Cells[15:14])
    );

    Cell cell9 (
        .clk  (clk), .Sel(sqrSel[8]), .Turn(Turn), .Reset(Reset),
        .State(Cells[17:16])
    );

    // Seven segment turn indicator (X/O)
    sevenseg_turn turnDisplay (
        .clk  (clk),
        .turn (Turn),
        .seg  (seg),
        .an   (an),
        .dp   (dp)
    );

endmodule
