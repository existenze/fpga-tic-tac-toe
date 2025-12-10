// Shows X when turn = 0, O when turn = 1 on digit 0.
module sevenseg_turn(
    input  wire clk,
    input  wire turn,        // 0 = X, 1 = O
    output reg  [6:0] seg,   // active-low segments CA..CG
    output reg  [3:0] an,    // active-low anodes
    output reg        dp     // decimal point (active-low)
);

    always @(posedge clk) begin
        // enable only rightmost digit (AN0)
        an <= 4'b1110;   // AN0 = 0, AN1-3 = 1
        dp <= 1'b1;      // decimal point off

        if (turn == 1'b0) begin
            // Digit "1"
            seg <= 7'b1111001;  
        end 
        else begin
            // Digit "2"
            seg <= 7'b0100100;
        end
    end

endmodule