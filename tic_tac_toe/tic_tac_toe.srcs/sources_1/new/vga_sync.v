`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2025 12:30:25 AM
// Design Name: 
// Module Name: vga_sync
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

// Generates 640x480 @ 60 Hz timing with 25 MHz pixel tick
module vga_sync(
    input wire clk,          // 100 MHz Basys3 clock
    input wire reset,
    output wire hsync,
    output wire vsync,
    output wire video_on,
    output wire p_tick,
    output wire [9:0] x,     // horizontal pixel position
    output wire [9:0] y      // vertical pixel position
);

    // ----------------------------------------------------
    // VGA TIMING CONSTANTS (640x480 @ 60Hz)
    // ----------------------------------------------------
    localparam H_DISPLAY       = 640;
    localparam H_L_BORDER      = 48;
    localparam H_R_BORDER      = 16;
    localparam H_RETRACE       = 96;
    localparam H_MAX           = H_DISPLAY + H_L_BORDER + H_R_BORDER + H_RETRACE - 1;
    localparam START_H_RETRACE = H_DISPLAY + H_R_BORDER;
    localparam END_H_RETRACE   = H_DISPLAY + H_R_BORDER + H_RETRACE - 1;

    localparam V_DISPLAY       = 480;
    localparam V_T_BORDER      = 10;
    localparam V_B_BORDER      = 33;
    localparam V_RETRACE       = 2;
    localparam V_MAX           = V_DISPLAY + V_T_BORDER + V_B_BORDER + V_RETRACE - 1;
    localparam START_V_RETRACE = V_DISPLAY + V_B_BORDER;
    localparam END_V_RETRACE   = V_DISPLAY + V_B_BORDER + V_RETRACE - 1;

    // ----------------------------------------------------
    // PIXEL CLOCK: divide 100 MHz → 25 MHz (mod-4 counter)
    // ----------------------------------------------------
    reg [1:0] pixel_reg;
    wire [1:0] pixel_next;
    wire pixel_tick;

    always @(posedge clk or posedge reset) begin
        if (reset)
            pixel_reg <= 2'b00;
        else
            pixel_reg <= pixel_next;
    end

    assign pixel_next = pixel_reg + 1'b1;
    assign pixel_tick = (pixel_reg == 2'b00);
    assign p_tick     = pixel_tick;

    // ----------------------------------------------------
    // HORIZONTAL & VERTICAL COUNTERS
    // ----------------------------------------------------
    reg [9:0] h_count_reg, h_count_next;
    reg [9:0] v_count_reg, v_count_next;

    reg hsync_reg, vsync_reg;
    wire hsync_next, vsync_next;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            h_count_reg <= 10'd0;
            v_count_reg <= 10'd0;
            hsync_reg   <= 1'b0;
            vsync_reg   <= 1'b0;
        end
        else begin
            h_count_reg <= h_count_next;
            v_count_reg <= v_count_next;
            hsync_reg   <= hsync_next;
            vsync_reg   <= vsync_next;
        end
    end

    // Next-state logic
    always @(*) begin
        // Horizontal counter advances on pixel tick
        h_count_next = pixel_tick
            ? (h_count_reg == H_MAX ? 0 : h_count_reg + 1)
            : h_count_reg;

        // Vertical counter advances only when hcounter wraps
        v_count_next = (pixel_tick && h_count_reg == H_MAX)
            ? (v_count_reg == V_MAX ? 0 : v_count_reg + 1)
            : v_count_reg;
    end

    // ----------------------------------------------------
    // SYNC SIGNALS (active low)
    // ----------------------------------------------------
    assign hsync_next = (h_count_reg >= START_H_RETRACE &&
                         h_count_reg <= END_H_RETRACE);

    assign vsync_next = (v_count_reg >= START_V_RETRACE &&
                         v_count_reg <= END_V_RETRACE);

    // Output sync signals
    assign hsync = ~hsync_reg;   // active low
    assign vsync = ~vsync_reg;   // active low

    // ----------------------------------------------------
    // VIDEO ON/OFF FLAG
    // ----------------------------------------------------
    assign video_on =
        (h_count_reg < H_DISPLAY) &&
        (v_count_reg < V_DISPLAY);

    // Current pixel coordinates
    assign x = h_count_reg;
    assign y = v_count_reg;

endmodule
