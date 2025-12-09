// Draws grid, X/O shapes, and win highlighting on Basys-3 VGA.
//
// Inputs:
//   clk      - 100 MHz clock
//   reset    - active-high reset
//   Cells    - 18 bits representing 9 cells (each 2 bits: 00=N, 01=X, 11=O)
//   Color    - 9 bits; each '1' marks a cell to be colored red (winning line)
//   Turn     - unused here but kept for compatibility
//
// Outputs:
//   hsync, vsync - VGA sync signals
//   rgb          - 12-bit color (R,G,B)
//
// NOTE: This uses the Instructables coordinate logic exactly.

module videoElements(
    input  wire        clk,
    input  wire        reset,
    input  wire [17:0] Cells,
    input  wire [8:0]  Color,
    input  wire        Turn,    // Not used, but kept for compatibility

    output wire        hsync,
    output wire        vsync,
    output wire [11:0] rgb
);

    // Constants taken straight from the Instructables design
    localparam hRes = 640;
    localparam vRes = 480;

    localparam hBorder = 100;
    localparam vBorder = 20;

    localparam hLinePos1 = vBorder + 147;
    localparam hLinePos2 = (vRes - 20) - 147;

    localparam vLinePos1 = hBorder + 147;
    localparam vLinePos2 = (hRes - 100) - 147;

    localparam sqBorder = 40;
    localparam [4:0] plsBorder = 30;

    localparam lineWeight = 2;

    // internal pixel display selector
    reg [1:0] pDisp;

    // VGA position signals
    wire [9:0] hPos, vPos;
    wire       p_tick;
    wire       video_on;

    // Instantiate the VGA timing generator
    vga_sync vga_sync_unit (
        .clk(clk),
        .reset(reset),
        .hsync(hsync),
        .vsync(vsync),
        .video_on(video_on),
        .p_tick(p_tick),
        .x(hPos),
        .y(vPos)
    );

    // Drawing logic
    always @(posedge p_tick or posedge reset) begin
        if (reset) begin
            pDisp <= 2'b00;
        end
        else if (!video_on) begin
            pDisp <= 2'b00;   // outside visible region = black
        end
        else begin

            // ===========================
            // GRID LINES
            // ===========================

            // Horizontal grid lines
            if (hPos > hBorder && hPos < (hRes - hBorder) &&
               ((vPos > hLinePos1 - lineWeight && vPos < hLinePos1 + lineWeight) ||
                (vPos > hLinePos2 - lineWeight && vPos < hLinePos2 + lineWeight))) begin
                pDisp <= 2'b01;
            end

            // Vertical grid lines
            else if (vPos > vBorder && vPos < (vRes - vBorder) &&
                    ((hPos > vLinePos1 - lineWeight && hPos < vLinePos1 + lineWeight) ||
                     (hPos > vLinePos2 - lineWeight && hPos < vLinePos2 + lineWeight))) begin
                pDisp <= 2'b01;
            end


            // =======================================================
            // =====================  CELL 1  =========================
            // =======================================================
            else if (
                ((hPos > hBorder + sqBorder + (Cells[1] ? 0 : plsBorder) &&
                  hPos < vLinePos1 - sqBorder    - (Cells[1] ? 0 : plsBorder) &&
                  vPos > vBorder + sqBorder &&
                  vPos < hLinePos1 - sqBorder) 
                ||
                 (hPos > hBorder + sqBorder &&
                  hPos < vLinePos1 - sqBorder &&
                  vPos > vBorder + sqBorder + (Cells[1] ? 0 : plsBorder) &&
                  vPos < hLinePos1 - sqBorder - (Cells[1] ? 0 : plsBorder)))
                && Cells[0]
            ) begin
                pDisp <= {Color[0], 1'b1};
            end


            // =====================  CELL 2  =========================
            else if (
                ((hPos > vLinePos1 + sqBorder + (Cells[3] ? 0 : plsBorder) &&
                  hPos < vLinePos2 - sqBorder    - (Cells[3] ? 0 : plsBorder) &&
                  vPos > vBorder + sqBorder &&
                  vPos < hLinePos1 - sqBorder) 
                ||
                 (hPos > vLinePos1 + sqBorder &&
                  hPos < vLinePos2 - sqBorder &&
                  vPos > vBorder + sqBorder + (Cells[3] ? 0 : plsBorder) &&
                  vPos < hLinePos1 - sqBorder - (Cells[3] ? 0 : plsBorder)))
                && Cells[2]
            ) begin
                pDisp <= {Color[1], 1'b1};
            end


            // =====================  CELL 3  =========================
            else if (
                ((hPos > vLinePos2 + sqBorder + (Cells[5] ? 0 : plsBorder) &&
                  hPos < (hRes - hBorder) - sqBorder - (Cells[5] ? 0 : plsBorder) &&
                  vPos > vBorder + sqBorder &&
                  vPos < hLinePos1 - sqBorder) 
                ||
                 (hPos > vLinePos2 + sqBorder &&
                  hPos < (hRes - hBorder) - sqBorder &&
                  vPos > vBorder + sqBorder + (Cells[5] ? 0 : plsBorder) &&
                  vPos < hLinePos1 - sqBorder - (Cells[5] ? 0 : plsBorder)))
                && Cells[4]
            ) begin
                pDisp <= {Color[2], 1'b1};
            end


            // =====================  CELL 4  =========================
            else if (
                ((hPos > hBorder + sqBorder + (Cells[7] ? 0 : plsBorder) &&
                  hPos < vLinePos1 - sqBorder    - (Cells[7] ? 0 : plsBorder) &&
                  vPos > hLinePos1 + sqBorder &&
                  vPos < hLinePos2 - sqBorder) 
                ||
                 (hPos > hBorder + sqBorder &&
                  hPos < vLinePos1 - sqBorder &&
                  vPos > hLinePos1 + sqBorder + (Cells[7] ? 0 : plsBorder) &&
                  vPos < hLinePos2 - sqBorder - (Cells[7] ? 0 : plsBorder)))
                && Cells[6]
            ) begin
                pDisp <= {Color[3], 1'b1};
            end


            // =====================  CELL 5  =========================
            else if (
                ((hPos > vLinePos1 + sqBorder + (Cells[9] ? 0 : plsBorder) &&
                  hPos < vLinePos2 - sqBorder    - (Cells[9] ? 0 : plsBorder) &&
                  vPos > hLinePos1 + sqBorder &&
                  vPos < hLinePos2 - sqBorder) 
                ||
                 (hPos > vLinePos1 + sqBorder &&
                  hPos < vLinePos2 - sqBorder &&
                  vPos > hLinePos1 + sqBorder + (Cells[9] ? 0 : plsBorder) &&
                  vPos < hLinePos2 - sqBorder - (Cells[9] ? 0 : plsBorder)))
                && Cells[8]
            ) begin
                pDisp <= {Color[4], 1'b1};
            end


            // =====================  CELL 6  =========================
            else if (
                ((hPos > vLinePos2 + sqBorder + (Cells[11] ? 0 : plsBorder) &&
                  hPos < (hRes - hBorder) - sqBorder - (Cells[11] ? 0 : plsBorder) &&
                  vPos > hLinePos1 + sqBorder &&
                  vPos < hLinePos2 - sqBorder) 
                ||
                 (hPos > vLinePos2 + sqBorder &&
                  hPos < (hRes - hBorder) - sqBorder &&
                  vPos > hLinePos1 + sqBorder + (Cells[11] ? 0 : plsBorder) &&
                  vPos < hLinePos2 - sqBorder - (Cells[11] ? 0 : plsBorder)))
                && Cells[10]
            ) begin
                pDisp <= {Color[5], 1'b1};
            end


            // =====================  CELL 7  =========================
            else if (
                ((hPos > hBorder + sqBorder + (Cells[13] ? 0 : plsBorder) &&
                  hPos < vLinePos1 - sqBorder    - (Cells[13] ? 0 : plsBorder) &&
                  vPos > hLinePos2 + sqBorder &&
                  vPos < (vRes - vBorder) - sqBorder) 
                ||
                 (hPos > hBorder + sqBorder &&
                  hPos < vLinePos1 - sqBorder &&
                  vPos > hLinePos2 + sqBorder + (Cells[13] ? 0 : plsBorder) &&
                  vPos < (vRes - vBorder) - sqBorder - (Cells[13] ? 0 : plsBorder)))
                && Cells[12]
            ) begin
                pDisp <= {Color[6], 1'b1};
            end


            // =====================  CELL 8  =========================
            else if (
                ((hPos > vLinePos1 + sqBorder + (Cells[15] ? 0 : plsBorder) &&
                  hPos < vLinePos2 - sqBorder    - (Cells[15] ? 0 : plsBorder) &&
                  vPos > hLinePos2 + sqBorder &&
                  vPos < (vRes - vBorder) - sqBorder) 
                ||
                 (hPos > vLinePos1 + sqBorder &&
                  hPos < vLinePos2 - sqBorder &&
                  vPos > hLinePos2 + sqBorder + (Cells[15] ? 0 : plsBorder) &&
                  vPos < (vRes - vBorder) - sqBorder - (Cells[15] ? 0 : plsBorder)))
                && Cells[14]
            ) begin
                pDisp <= {Color[7], 1'b1};
            end


            // =====================  CELL 9  =========================
            else if (
                ((hPos > vLinePos2 + sqBorder + (Cells[17] ? 0 : plsBorder) &&
                  hPos < (hRes - hBorder) - sqBorder - (Cells[17] ? 0 : plsBorder) &&
                  vPos > hLinePos2 + sqBorder &&
                  vPos < (vRes - vBorder) - sqBorder) 
                ||
                 (hPos > vLinePos2 + sqBorder &&
                  hPos < (hRes - hBorder) - sqBorder &&
                  vPos > hLinePos2 + sqBorder + (Cells[17] ? 0 : plsBorder) &&
                  vPos < (vRes - vBorder) - sqBorder - (Cells[17] ? 0 : plsBorder)))
                && Cells[16]
            ) begin
                pDisp <= {Color[8], 1'b1};
            end


            // ===================== BACKGROUND =========================
            else begin
                pDisp <= 2'b00;
            end
        end
    end

    // Final color mapping:
    // pDisp[0] = 1 → draw shape
    // pDisp[1] = 1 → red, 0 → white
    assign rgb = (pDisp[0]) ? (pDisp[1] ? 12'hF00 : 12'hFFF) : 12'h000;

endmodule