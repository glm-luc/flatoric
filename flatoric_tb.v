`timescale 1ns / 1ps

// flatoric_tb module - Copyright (c) 2003, 2022 Gordon Mills
//
// Debug testbench for the flatoric module.

module flatoric_tb;

  // Inputs.
  reg CLK;
  reg RED;
  reg GREEN;
  reg BLUE;
  reg SYNC;
  reg BTN1;

  // Outputs.
  wire [14:0] ADDR;
  wire NOE;
  wire NWE;
  wire NCE;
  wire FLM;
  wire CL1;
  wire CL2;
  wire [7:0] LCD_D;
  wire NDOFF;
  wire VCON;
  wire LD2;
  wire CFL;

  // Bidirs.
  wire [7:0] DATA;

  // Instantiate the Unit Under Test.
  flatoric uut (
    .CLK(CLK),
    .RED(RED),
    .GREEN(GREEN),
    .BLUE(BLUE),
    .SYNC(SYNC),
    .BTN1(BTN1),
    .DATA(DATA),
    .ADDR(ADDR),
    .NOE(NOE),
    .NWE(NWE),
    .NCE(NCE),
    .FLM(FLM),
    .CL1(CL1),
    .CL2(CL2),
    .LCD_D(LCD_D),
    .NDOFF(NDOFF),
    .VCON(VCON),
    .LD2(LD2),
    .CFL(CFL)
  );

  // RAM model.
  reg [7:0] din, memory[0:2**15-1];
  reg [14:0] a_tAA;
  reg nce_tACS, nce_tCLZ, nce_tCHZ, noe_tOE, noe_tOLZ, noe_tOHZ;

  always @(ADDR, DATA, NCE, NOE)
  begin
    a_tAA <= #70 ADDR;
    din <= #40 DATA;
    nce_tACS <= #70 NCE;
    nce_tCLZ <= #10 NCE;
    nce_tCHZ <= #35 NCE;
    noe_tOE <= #50 NOE;
    noe_tOLZ <= #10 NOE;
    noe_tOHZ <= #30 NOE;
  end

  always @(posedge(NWE))
  if (~nce_tACS)
    memory[a_tAA] <= din;

  wire [7:0] dout = (~nce_tACS && ~noe_tOE) ? memory[a_tAA] : 8'hxx;
  assign DATA = (~nce_tCLZ && ~noe_tOLZ || ~nce_tCHZ && ~noe_tOHZ) ? dout : 8'hzz;

  // Initialize inputs.
  initial begin
    CLK = 1'b0;
    SYNC = 1'b0;
    BTN1 = 1'b1;
    #(40*1e6);
    BTN1 = 1'b0;
    #(40*1e6);
    BTN1 = 1'b1;
  end

  // Generate 27 MHz clock.
  always
    #(0.5e3/27) CLK = ~CLK;

  // Generate video.
  always
  begin
    SYNC = 1'b0;    // vsync, 3.5 lines
    #(64e3*3.5)
    repeat(309)     // 309 field lines.
      begin
        SYNC = 1'b0;  // hsync 4 us, 24 pixels
        #(4e3);
        SYNC = 1'b1;
        repeat(360)   // active line 60 us, 360 pixels
        begin
          { RED, GREEN, BLUE } = 3'bxxx;
          #(100.0/3);
          { RED, GREEN, BLUE } = 3'b010;
          #100;
          { RED, GREEN, BLUE } = 3'bxxx;
          #(100.0/3);
        end
    end
  end

endmodule

