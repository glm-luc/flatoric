`timescale 1ns / 1ps

// pwrmanage module - Copyright (c) 2003, 2022 Gordon Mills
//
// Provides the recommended sequencing of LCD power signals when starting up or
// entering/exiting standby.

module pwrmanage (
    input clk,
    input btn,
    output pwon,
    output vcon
    );

localparam OFF = 0, UP_0 = 1, UP_1 = 2, ON = 3, DN_0 = 4, DN_1 = 5;

reg tmr_rst;
reg [19:0] timer = 20'd0;
reg [2:0] curr_state = OFF;
reg [2:0] next_state;
reg pw, vc;
reg pw_reg = 1'b0;
reg vc_reg = 1'b0;

wire tmr_tc = (timer == 20'hfffff);

assign pwon = pw_reg;
assign vcon = vc_reg;

  always @(posedge clk)
  begin
    pw_reg <= pw;
    vc_reg <= vc;

    curr_state <= next_state;

    if (tmr_rst)
      timer <= 20'd0;
    else
      timer <= timer + 1'b1;
  end

  always @(*)
    case (curr_state)
      UP_0:     // off, off, wait for > 39 ms button press.
        begin
          { pw, vc } = 2'b00;
          tmr_rst = btn;
          if (tmr_tc)
            next_state = UP_1;
          else
            next_state = UP_0;
        end
      UP_1:     // off, on, wait 39 ms.
        begin
          { pw, vc } = 2'b01;
          tmr_rst = 1'b0;
          if (tmr_tc)
            next_state = ON;
          else
            next_state = UP_1;
        end
      ON:       // on, on, wait for > 39 ms button release.
        begin
          { pw, vc } = 2'b11;
          tmr_rst = ~btn;
          if (tmr_tc)
            next_state = DN_0;
          else
            next_state = ON;
        end
      DN_0:     // on, on, wait for > 39 ms button press.
        begin
          { pw, vc } = 2'b11;
          tmr_rst = btn;
          if (tmr_tc)
            next_state = DN_1;
          else
            next_state = DN_0;
        end
      DN_1:     // off, on, wait 39 ms.
        begin
          { pw, vc } = 2'b01;
          tmr_rst = 1'b0;
          if (tmr_tc)
            next_state = OFF;
          else
            next_state = DN_1;
        end
      default:  // off, off, wait for > 39 ms button release.
        begin
          { pw, vc } = 2'b00;
          tmr_rst = ~btn;
          if (tmr_tc)
            next_state = UP_0;
          else
            next_state = OFF;
        end
    endcase

endmodule
