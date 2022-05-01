`timescale 1ns / 1ps

// flatoric module - Copyright (c) 2003, 2022 Gordon Mills
//
// A flat panel display for Oric-1/Atmos microcomputers.

module flatoric(
    input CLK,                  // 27.0 MHz input clock.

    input RED,                  // Red video input.
    input GREEN,                // Green video input.
    input BLUE,                 // Blue videoinput.
    input SYNC,                 // Composite sync input.

    input BTN1,                 // Push button input.

    inout  [7:0] DATA,          // External SRAM data.
    output [14:0] ADDR,         // External SRAM address.
    output NOE,                 // External SRAM output enable.
    output NWE,                 // External SRAM write strobe.
    output NCE,                 // External SRAM chip enable.

    output FLM,                 // LCD first line marker output.
    output CL1,                 // LCD line clock output.
    output CL2,                 // LCD byte clock output.
    output [7:0] LCD_D,         // LCD data output.
    output NDOFF,               // LCD display on/off output.
    output VCON,                // LCD contrast voltage output.

    output LD2,                 // LED output.
    output CFL                  // Backlight control.
  );

reg red_ck = 1'b0;
reg green_ck = 1'b0;
reg blue_ck = 1'b0;
reg sync_ck = 1'b0;
reg btn1_ck = 1'b0;

wire frm, ena, pwon;
wire rd_req, wr_req;
wire rd_ack, wr_ack;
wire [14:0] rd_addr;
wire [14:0] wr_addr;
wire [7:0] rd_data = DATA;
wire [7:0] wr_data;

assign NDOFF = pwon;
assign CFL = pwon;
assign LD2 = ~pwon;
assign NCE = ~pwon;
assign DATA = ena ? wr_data : 8'hzz;

  always @(posedge CLK)
  begin
    red_ck <= RED;
    green_ck <= GREEN;
    blue_ck <= BLUE;
    sync_ck <= SYNC;
    btn1_ck <= BTN1;
  end

  rgbcapture u1 (
    .clk(CLK),
    .red(red_ck),
    .green(green_ck),
    .blue(blue_ck),
    .sync(sync_ck),
    .req(wr_req),
    .ack(wr_ack),
    .addr(wr_addr),
    .data(wr_data),
    .frm(frm)
  );

  lcdcontrol u2 (
    .clk(CLK),
    .flm(FLM),
    .cl1(CL1),
    .cl2(CL2),
    .lcd_d(LCD_D),
    .req(rd_req),
    .ack(rd_ack),
    .addr(rd_addr),
    .data(rd_data),
    .frm(frm)
  );

  ramcontrol u3 (
    .clk(CLK),
    .addr(ADDR),
    .noe(NOE),
    .nwe(NWE),
    .ena(ena),
    .rd_addr(rd_addr),
    .rd_req(rd_req),
    .rd_ack(rd_ack),
    .wr_addr(wr_addr),
    .wr_req(wr_req),
    .wr_ack(wr_ack)
  );

  pwrmanage u4 (
    .clk(CLK),
    .btn(btn1_ck),
    .pwon(pwon),
    .vcon(VCON)
  );

endmodule
