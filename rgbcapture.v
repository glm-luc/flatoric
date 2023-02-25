`timescale 1ns / 1ps

// rgbcapture module
//
// Samples Oric RGB video and packs pixels into bytes for writing to a frame
// buffer, every 8 pixels generate 3 bytes of data. 240 of 312.5 lines per
// field, and 320 of 384 pixels per line are sampled at 6 MHz. Synchronisation
// occurs at the start of each line, loss is detected if the 15.625 kHz nominal
// sync drops below 15.584 kHz and a colour bar test pattern is output to the
// frame buffer. A frame pulse is generated at half the 50 Hz nominal input
// field rate, or at 24.831 Hz on sync loss.

module rgbcapture(
    input clk,
    input red,
    input green,
    input blue,
    input sync,
    input ack,
    output req,
    output [14:0] addr,
    output [7:0] data,
    output frm
  );

localparam LINE_START = 47;
localparam PIX_START = 48;
localparam PIX_PHASE = 3;

reg sync_z1 = 1'b0;
reg sync_ok = 1'b0;
reg field = 1'b0;
reg divsel = 1'b0;
reg [2:0] clk_ctr = 3'd0;
reg [8:0] pix_ctr = 9'd0;
reg [8:0] line_ctr = 9'd0;
reg [2:0] pix_rdy = 3'b000;
reg [7:0] pix_buff [0:2];
reg [7:0] pix_we;
reg [14:0] addr_ctr = 15'd0;
reg [2:0] tpg;

wire [2:0] clk_div = divsel ? 3'd4 : 3'd3;    // 27 MHz / 4.5 = 6 MHz.

wire sync_fe = ~sync && sync_z1;
wire sync_to = (pix_ctr == 384 + 1);
wire h_sync = sync_fe || sync_to;
wire v_sync = sync_ok && sync_to || ~sync_ok && (line_ctr == 312);

wire v_actv = (line_ctr >= LINE_START && line_ctr < LINE_START + 240);
wire h_actv = (pix_ctr >= PIX_START && pix_ctr < PIX_START + 320);
wire p_samp = (clk_ctr == PIX_PHASE);

wire red_pix = sync_ok ? red : tpg[1];
wire green_pix = sync_ok ? green : tpg[2];
wire blue_pix = sync_ok ? blue : tpg[0];

assign addr = addr_ctr;
assign req = |pix_rdy;
assign data = pix_rdy[0] ? pix_buff[0] : pix_rdy[1] ? pix_buff[1] : pix_buff[2];
assign frm = field && v_sync;

  always @(posedge clk)
  begin
    // Synchronisation state.
    sync_z1 <= sync;
    if (sync_fe)
      sync_ok <= 1'b1;
    else if (sync_to)
      sync_ok <= 1'b0;

    // Fractional pixel clock divider.
    if (h_sync)
      begin
        clk_ctr <= 3'd4;
        divsel <= 1'b0;
      end
    else if (~|clk_ctr)
      begin
        clk_ctr <= clk_div;
        divsel <= ~divsel;
      end
    else
      clk_ctr <= clk_ctr - 1'b1;

    // Pixel and line counters.
    if (h_sync)
      begin
        pix_ctr <= 9'd0;
        if (v_sync)
          begin
            line_ctr <= 9'd0;
            field <= ~field;
          end
        else
          line_ctr <= line_ctr + 1'b1;
      end
    else if (~|clk_ctr)
      pix_ctr <= pix_ctr + 1'b1;

    // Pixel buffers, 8 pixels into 3 bytes.
    if (pix_we[0])
      begin
        pix_buff[0][7] <= red_pix;
        pix_buff[0][6] <= green_pix;
        pix_buff[0][5] <= blue_pix;
      end
    if (pix_we[1])
      begin
        pix_buff[0][4] <= red_pix;
        pix_buff[0][3] <= green_pix;
        pix_buff[0][2] <= blue_pix;
      end
    if (pix_we[2])
      begin
        pix_buff[0][1] <= red_pix;
        pix_buff[0][0] <= green_pix;
        pix_buff[1][7] <= blue_pix;
      end
    if (pix_we[3])
      begin
        pix_buff[1][6] <= red_pix;
        pix_buff[1][5] <= green_pix;
        pix_buff[1][4] <= blue_pix;
      end
    if (pix_we[4])
      begin
        pix_buff[1][3] <= red_pix;
        pix_buff[1][2] <= green_pix;
        pix_buff[1][1] <= blue_pix;
      end
    if (pix_we[5])
      begin
        pix_buff[1][0] <= red_pix;
        pix_buff[2][7] <= green_pix;
        pix_buff[2][6] <= blue_pix;
      end
    if (pix_we[6])
      begin
        pix_buff[2][5] <= red_pix;
        pix_buff[2][4] <= green_pix;
        pix_buff[2][3] <= blue_pix;
      end
    if (pix_we[7])
      begin
        pix_buff[2][2] <= red_pix;
        pix_buff[2][1] <= green_pix;
        pix_buff[2][0] <= blue_pix;
      end

    // Byte ready flags.
    if (pix_we[2])
      pix_rdy[0] <= 1'b1;
    else if (ack)
      pix_rdy[0] <= 1'b0;

    if (pix_we[5])
      pix_rdy[1] <= 1'b1;
    else if (ack)
      pix_rdy[1] <= 1'b0;

    if (pix_we[7])
      pix_rdy[2] <= 1'b1;
    else if (ack)
      pix_rdy[2] <= 1'b0;

    // Address counter.
    if (v_sync)
       addr_ctr <= 15'd0;
    else if (ack)
       addr_ctr <= addr_ctr + 1'b1;
  end

  always @(*)
    // Pixel buffer write enable decoder.
    if (v_actv && h_actv && p_samp)
      case (pix_ctr[2:0])
        3'd0: pix_we = 8'b00000001;
        3'd1: pix_we = 8'b00000010;
        3'd2: pix_we = 8'b00000100;
        3'd3: pix_we = 8'b00001000;
        3'd4: pix_we = 8'b00010000;
        3'd5: pix_we = 8'b00100000;
        3'd6: pix_we = 8'b01000000;
        3'd7: pix_we = 8'b10000000;
      endcase
    else
      pix_we = 8'b00000000;

  always @(*)
    // Test pattern generator.
    casez (pix_ctr[8:5])
      4'b000?: tpg = 3'b000;
      4'b0010: tpg = 3'b000;
      4'b0011: tpg = 3'b001;
      4'b0100: tpg = 3'b010;
      4'b0101: tpg = 3'b011;
      4'b0110: tpg = 3'b100;
      4'b0111: tpg = 3'b101;
      4'b1000: tpg = 3'b110;
      4'b1001: tpg = 3'b111;
      4'b101?: tpg = 3'b000;
      4'b11??: tpg = 3'b000;
    endcase

endmodule
