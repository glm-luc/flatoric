`timescale 1ns / 1ps

// lcdcontrol module - Copyright (c) 2003, 2022 Gordon Mills
//
// Controller for Toshiba SX14Q001 QVGA STN display. The controller reads and
// writes three frames of data when a frame pulse is received, then waits.
// Each output frame has 240 (+1 blanking) lines and each output line 120
// (+4 blanking) bytes clocked at 2.25 MHz. This results in a 75.291 Hz output
// frame rate, giving an upper bound for the input frame rate of 25.097 Hz.

module lcdcontrol(
    input clk,
    output flm,
    output cl1,
    output cl2,
    output [7:0] lcd_d,
    output req,
    input ack,
    output [14:0] addr,
    input [7:0] data,
    input frm
  );

localparam BYTE_DIV = 12 - 1;         // 27 MHz / 12 = 2.25 MHz.
localparam LINE_DIV = 120 + 4 - 1;    // 2.25 MHz / 124 = 18.145.. kHz.
localparam FRAME_DIV = 240 + 1;       // 18.145.. kHz / 241 = 75.291.. Hz.

reg frm_z1 = 1'b0;
reg flm_reg = 1'b0;
reg cl1_reg = 1'b0;
reg cl2_reg = 1'b0;
reg req_reg = 1'b0;
reg [7:0] lcd_data = 8'd0;
reg [3:0] clk_ctr = 4'd0;
reg [6:0] byte_ctr = 7'd0;
reg [9:0] line_ctr = 10'd0;
reg [14:0] addr_ctr = 15'd0;

wire f_top = (line_ctr == 0 * FRAME_DIV || line_ctr == 1 * FRAME_DIV || line_ctr == 2 * FRAME_DIV);
wire f_end = (line_ctr == 3 * FRAME_DIV);
wire h_act = (byte_ctr < 7'd120);
wire h_clk = (byte_ctr == 7'd120);
wire h_end = (byte_ctr == LINE_DIV);
wire b_end = (clk_ctr == BYTE_DIV);

assign flm = flm_reg;
assign cl1 = cl1_reg;
assign cl2 = cl2_reg;
assign req = req_reg;
assign lcd_d = lcd_data;
assign addr = addr_ctr;

  always @(posedge clk)
  begin
    frm_z1 <= frm;

    // Clock, byte, and line counters.
    if (~frm_z1 && frm)
      begin
        clk_ctr <= 4'd0;
        byte_ctr <= 7'd0;
        line_ctr <= 10'd0;
      end
    else if (~f_end)
      if (b_end)
        begin
          clk_ctr <= 4'd0;
          if (h_end)
            begin
              byte_ctr <= 7'd0;
              line_ctr <= line_ctr + 1'b1;
            end
          else
            byte_ctr <= byte_ctr + 1'b1;
        end
      else
        clk_ctr <= clk_ctr + 1'b1;

    // Clock output registers.
    flm_reg <= f_top;
    cl1_reg <= h_clk;
    cl2_reg <= h_act ? clk_ctr[3] : 1'b0;

    // Address counter.
    if (f_top && ~|byte_ctr && ~|clk_ctr)
      addr_ctr <= 15'd0;
    else if (ack)
      addr_ctr <= addr_ctr + 1'b1;

    // Data register.
    if (ack)
      lcd_data <= data;

    // Request register.
    if (ack)
      req_reg <= 1'b0;
    else if (~f_end && h_act && ~|clk_ctr)
      req_reg <= 1'b1;
  end

endmodule
