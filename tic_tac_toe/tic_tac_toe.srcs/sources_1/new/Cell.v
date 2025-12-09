module Cell(
    input  wire       clk,
    input  wire       Sel,
    input  wire       Turn,   // 0 = X, 1 = O
    input  wire       Reset,
    output reg  [1:0] State   // 00 = N, 01 = X, 11 = O
);

    // enum replacement
    localparam N = 2'b00;
    localparam X = 2'b01;
    localparam O = 2'b11;

    reg [1:0] PS, NS;

    // state register
    always @(posedge clk) begin
        if (Reset)
            PS <= N;
        else
            PS <= NS;
    end

    // next-state and output logic
    always @(*) begin
        case (PS)
            N: begin
                State = 2'b00;
                if (Sel && ~Turn)
                    NS = X;
                else if (Sel && Turn)
                    NS = O;
                else
                    NS = N;
            end

            X: begin
                State = 2'b01;
                NS    = X;
            end

            O: begin
                State = 2'b11;
                NS    = O;
            end

            default: begin
                State = 2'b00;
                NS    = N;
            end
        endcase
    end

endmodule
