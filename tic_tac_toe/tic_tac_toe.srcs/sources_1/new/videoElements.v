module videoElements(
    input  wire        clk,
    input  wire        reset,
    input  wire [17:0] Cells,
    input  wire [8:0]  Color,
    input  wire        Turn,    // not used but kept for compatibility

    output wire        hsync,
    output wire        vsync,
    output wire [11:0] rgb
);

    // VGA timing constants from original design
    localparam hRes = 640;
    localparam vRes = 480;

    localparam hBorder = 100;
    localparam vBorder = 20;

    localparam hLinePos1 = vBorder + 147;
    localparam hLinePos2 = (vRes - 20) - 147;

    localparam vLinePos1 = hBorder + 147;
    localparam vLinePos2 = (hRes - 100) - 147;

    localparam sqBorder  = 40;
    localparam [4:0] plsBorder = 30;

    localparam lineWeight = 2;

    reg [1:0] pDisp;

    wire [9:0] hPos, vPos;
    wire       p_tick;
    wire       video_on;

    // VGA timing generator
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

    // helper variables for shape drawing
    integer cellX1, cellX2, cellY1, cellY2;
    integer cx, cy;
    integer dx, dy;

    // MAIN PIXEL LOGIC
    always @(posedge p_tick or posedge reset) begin
        if (reset) begin
            pDisp <= 2'b00;
        end
        else if (!video_on) begin
            pDisp <= 2'b00;
        end
        else begin
            
            // ===========================
            // GRID LINES (unchanged)
            // ===========================

            // Horizontal lines
            if (hPos > hBorder && hPos < (hRes - hBorder) &&
               ((vPos > hLinePos1 - lineWeight && vPos < hLinePos1 + lineWeight) ||
                (vPos > hLinePos2 - lineWeight && vPos < hLinePos2 + lineWeight))) begin
                pDisp <= 2'b01;
            end

            // Vertical lines
            else if (vPos > vBorder && vPos < (vRes - vBorder) &&
                    ((hPos > vLinePos1 - lineWeight && hPos < vLinePos1 + lineWeight) ||
                     (hPos > vLinePos2 - lineWeight && hPos < vLinePos2 + lineWeight))) begin
                pDisp <= 2'b01;
            end


            // =====================================================
            // NOW EACH CELL BLOCK IS PATCHED TO DRAW:
            //   X = diagonal X
            //   O = hollow rectangle
            // =====================================================


            // -----------------------
            //  CELL 1  (Cells[1:0])
            // -----------------------
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
            ) begin
                // compute bounds
                cellX1 = hBorder + sqBorder;
                cellX2 = vLinePos1 - sqBorder;
                cellY1 = vBorder + sqBorder;
                cellY2 = hLinePos1 - sqBorder;

                // center
                cx = (cellX1 + cellX2) >>> 1;
                cy = (cellY1 + cellY2) >>> 1;

                dx = hPos - cx;
                dy = vPos - cy;

                // X or O?
                case (Cells[1:0])
                    // --- X ---
                    2'b01: begin
                        if (dx == dy || dx == -dy)
                            pDisp <= {Color[0], 1'b1};
                        else
                            pDisp <= 2'b00;
                    end

                    // --- O (hollow) ---
                    2'b11: begin
                        if ( (hPos - cellX1 < 3) || (cellX2 - hPos < 3) ||
                             (vPos - cellY1 < 3) || (cellY2 - vPos < 3) )
                            pDisp <= {Color[0],1'b1};
                        else
                            pDisp <= 2'b00;
                    end

                    default: pDisp <= 2'b00;
                endcase
            end


            // -----------------------
            //  CELL 2  (Cells[3:2])
            // -----------------------
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
            ) begin
                cellX1 = vLinePos1 + sqBorder;
                cellX2 = vLinePos2 - sqBorder;
                cellY1 = vBorder + sqBorder;
                cellY2 = hLinePos1 - sqBorder;

                cx = (cellX1 + cellX2) >>> 1;
                cy = (cellY1 + cellY2) >>> 1;

                dx = hPos - cx;
                dy = vPos - cy;

                case (Cells[3:2])
                    2'b01: begin
                        if (dx == dy || dx == -dy)
                            pDisp <= {Color[1],1'b1};
                        else
                            pDisp <= 2'b00;
                    end
                    2'b11: begin
                        if ( (hPos - cellX1 < 3) || (cellX2 - hPos < 3) ||
                             (vPos - cellY1 < 3) || (cellY2 - vPos < 3) )
                            pDisp <= {Color[1],1'b1};
                        else
                            pDisp <= 2'b00;
                    end
                    default: pDisp <= 2'b00;
                endcase
            end


            // -----------------------
            //  CELL 3  (Cells[5:4])
            // -----------------------
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
            ) begin
                cellX1 = vLinePos2 + sqBorder;
                cellX2 = (hRes - hBorder) - sqBorder;
                cellY1 = vBorder + sqBorder;
                cellY2 = hLinePos1 - sqBorder;

                cx = (cellX1 + cellX2) >>> 1;
                cy = (cellY1 + cellY2) >>> 1;

                dx = hPos - cx;
                dy = vPos - cy;

                case (Cells[5:4])
                    2'b01: begin
                        if (dx == dy || dx == -dy)
                            pDisp <= {Color[2],1'b1};
                        else
                            pDisp <= 2'b00;
                    end
                    2'b11: begin
                        if ( (hPos - cellX1 < 3) || (cellX2 - hPos < 3) ||
                             (vPos - cellY1 < 3) || (cellY2 - vPos < 3) )
                            pDisp <= {Color[2],1'b1};
                        else
                            pDisp <= 2'b00;
                    end
                    default: pDisp <= 2'b00;
                endcase
            end


            // -----------------------
            //  CELL 4  (Cells[7:6])
            // -----------------------
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
            ) begin
                cellX1 = hBorder + sqBorder;
                cellX2 = vLinePos1 - sqBorder;
                cellY1 = hLinePos1 + sqBorder;
                cellY2 = hLinePos2 - sqBorder;

                cx = (cellX1 + cellX2) >>> 1;
                cy = (cellY1 + cellY2) >>> 1;

                dx = hPos - cx;
                dy = vPos - cy;

                case (Cells[7:6])
                    2'b01: begin
                        if (dx == dy || dx == -dy)
                            pDisp <= {Color[3],1'b1};
                        else
                            pDisp <= 2'b00;
                    end
                    2'b11: begin
                        if ( (hPos - cellX1 < 3) || (cellX2 - hPos < 3) ||
                             (vPos - cellY1 < 3) || (cellY2 - vPos < 3) )
                            pDisp <= {Color[3],1'b1};
                        else
                            pDisp <= 2'b00;
                    end
                    default: pDisp <= 2'b00;
                endcase
            end


            // -----------------------
            //  CELL 5  (Cells[9:8])
            // -----------------------
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
            ) begin
                cellX1 = vLinePos1 + sqBorder;
                cellX2 = vLinePos2 - sqBorder;
                cellY1 = hLinePos1 + sqBorder;
                cellY2 = hLinePos2 - sqBorder;

                cx = (cellX1 + cellX2) >>> 1;
                cy = (cellY1 + cellY2) >>> 1;

                dx = hPos - cx;
                dy = vPos - cy;

                case (Cells[9:8])
                    2'b01: begin
                        if (dx == dy || dx == -dy)
                            pDisp <= {Color[4],1'b1};
                        else
                            pDisp <= 2'b00;
                    end
                    2'b11: begin
                        if ( (hPos - cellX1 < 3) || (cellX2 - hPos < 3) ||
                             (vPos - cellY1 < 3) || (cellY2 - vPos < 3) )
                            pDisp <= {Color[4],1'b1};
                        else
                            pDisp <= 2'b00;
                    end
                    default: pDisp <= 2'b00;
                endcase
            end


            // -----------------------
            //  CELL 6  (Cells[11:10])
            // -----------------------
            else if (
                ((hPos > vLinePos2 + sqBorder + (Cells[11] ? 0 : plsBorder) &&
                  hPos < (hRes-hBorder) - sqBorder - (Cells[11] ? 0 : plsBorder) &&
                  vPos > hLinePos1 + sqBorder &&
                  vPos < hLinePos2 - sqBorder)
                ||
                 (hPos > vLinePos2 + sqBorder &&
                  hPos < (hRes-hBorder) - sqBorder &&
                  vPos > hLinePos1 + sqBorder + (Cells[11] ? 0 : plsBorder) &&
                  vPos < hLinePos2 - sqBorder - (Cells[11] ? 0 : plsBorder)))
            ) begin
                cellX1 = vLinePos2 + sqBorder;
                cellX2 = (hRes - hBorder) - sqBorder;
                cellY1 = hLinePos1 + sqBorder;
                cellY2 = hLinePos2 - sqBorder;

                cx = (cellX1 + cellX2) >>> 1;
                cy = (cellY1 + cellY2) >>> 1;

                dx = hPos - cx;
                dy = vPos - cy;

                case (Cells[11:10])
                    2'b01: begin
                        if (dx == dy || dx == -dy)
                            pDisp <= {Color[5],1'b1};
                        else
                            pDisp <= 2'b00;
                    end
                    2'b11: begin
                        if ( (hPos - cellX1 < 3) || (cellX2 - hPos < 3) ||
                             (vPos - cellY1 < 3) || (cellY2 - vPos < 3) )
                            pDisp <= {Color[5],1'b1};
                        else
                            pDisp <= 2'b00;
                    end
                    default: pDisp <= 2'b00;
                endcase
            end


            // -----------------------
            //  CELL 7  (Cells[13:12])
            // -----------------------
            else if (
                ((hPos > hBorder + sqBorder + (Cells[13] ? 0 : plsBorder) &&
                  hPos < vLinePos1 - sqBorder    - (Cells[13] ? 0 : plsBorder) &&
                  vPos > hLinePos2 + sqBorder &&
                  vPos < (vRes-vBorder) - sqBorder)
                ||
                 (hPos > hBorder + sqBorder &&
                  hPos < vLinePos1 - sqBorder &&
                  vPos > hLinePos2 + sqBorder + (Cells[13] ? 0 : plsBorder) &&
                  vPos < (vRes-vBorder) - sqBorder - (Cells[13] ? 0 : plsBorder)))
            ) begin
                cellX1 = hBorder + sqBorder;
                cellX2 = vLinePos1 - sqBorder;
                cellY1 = hLinePos2 + sqBorder;
                cellY2 = (vRes-vBorder) - sqBorder;

                cx = (cellX1 + cellX2) >>> 1;
                cy = (cellY1 + cellY2) >>> 1;

                dx = hPos - cx;
                dy = vPos - cy;

                case (Cells[13:12])
                    2'b01: begin
                        if (dx == dy || dx == -dy)
                            pDisp <= {Color[6],1'b1};
                        else
                            pDisp <= 2'b00;
                    end
                    2'b11: begin
                        if ( (hPos - cellX1 < 3) || (cellX2 - hPos < 3) ||
                             (vPos - cellY1 < 3) || (cellY2 - vPos < 3) )
                            pDisp <= {Color[6],1'b1};
                        else
                            pDisp <= 2'b00;
                    end
                    default: pDisp <= 2'b00;
                endcase
            end


            // -----------------------
            //  CELL 8  (Cells[15:14])
            // -----------------------
            else if (
                ((hPos > vLinePos1 + sqBorder + (Cells[15] ? 0 : plsBorder) &&
                  hPos < vLinePos2 - sqBorder    - (Cells[15] ? 0 : plsBorder) &&
                  vPos > hLinePos2 + sqBorder &&
                  vPos < (vRes-vBorder) - sqBorder)
                ||
                 (hPos > vLinePos1 + sqBorder &&
                  hPos < vLinePos2 - sqBorder &&
                  vPos > hLinePos2 + sqBorder + (Cells[15] ? 0 : plsBorder) &&
                  vPos < (vRes-vBorder) - sqBorder - (Cells[15] ? 0 : plsBorder)))
            ) begin
                cellX1 = vLinePos1 + sqBorder;
                cellX2 = vLinePos2 - sqBorder;
                cellY1 = hLinePos2 + sqBorder;
                cellY2 = (vRes-vBorder) - sqBorder;

                cx = (cellX1 + cellX2) >>> 1;
                cy = (cellY1 + cellY2) >>> 1;

                dx = hPos - cx;
                dy = vPos - cy;

                case (Cells[15:14])
                    2'b01: begin
                        if (dx == dy || dx == -dy)
                            pDisp <= {Color[7],1'b1};
                        else
                            pDisp <= 2'b00;
                    end
                    2'b11: begin
                        if ( (hPos - cellX1 < 3) || (cellX2 - hPos < 3) ||
                             (vPos - cellY1 < 3) || (cellY2 - vPos < 3) )
                            pDisp <= {Color[7],1'b1};
                        else
                            pDisp <= 2'b00;
                    end
                    default: pDisp <= 2'b00;
                endcase
            end


            // -----------------------
            //  CELL 9  (Cells[17:16])
            // -----------------------
            else if (
                ((hPos > vLinePos2 + sqBorder + (Cells[17] ? 0 : plsBorder) &&
                  hPos < (hRes-hBorder) - sqBorder - (Cells[17] ? 0 : plsBorder) &&
                  vPos > hLinePos2 + sqBorder &&
                  vPos < (vRes-vBorder) - sqBorder)
                ||
                 (hPos > vLinePos2 + sqBorder &&
                  hPos < (hRes-hBorder) - sqBorder &&
                  vPos > hLinePos2 + sqBorder + (Cells[17] ? 0 : plsBorder) &&
                  vPos < (vRes-vBorder) - sqBorder - (Cells[17] ? 0 : plsBorder)))
            ) begin
                cellX1 = vLinePos2 + sqBorder;
                cellX2 = (hRes-hBorder) - sqBorder;
                cellY1 = hLinePos2 + sqBorder;
                cellY2 = (vRes-vBorder) - sqBorder;

                cx = (cellX1 + cellX2) >>> 1;
                cy = (cellY1 + cellY2) >>> 1;

                dx = hPos - cx;
                dy = vPos - cy;

                case (Cells[17:16])
                    2'b01: begin
                        if (dx == dy || dx == -dy)
                            pDisp <= {Color[8],1'b1};
                        else
                            pDisp <= 2'b00;
                    end
                    2'b11: begin
                        if ( (hPos - cellX1 < 3) || (cellX2 - hPos < 3) ||
                             (vPos - cellY1 < 3) || (cellY2 - vPos < 3) )
                            pDisp <= {Color[8],1'b1};
                        else
                            pDisp <= 2'b00;
                    end
                    default: pDisp <= 2'b00;
                endcase
            end

            else begin
                pDisp <= 2'b00;
            end
        end
    end

    // FINAL COLOR OUTPUT
    assign rgb = (pDisp[0]) 
                 ? (pDisp[1] ? 12'hF00 : 12'hFFF)
                 : 12'h000;

endmodule