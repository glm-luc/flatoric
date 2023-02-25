`timescale 1ns / 1ps

// ramcontrol module
//
// Provides a dual-port interface to a single-port external SRAM device.
// Read transactions have priority and require a mimimum of 3, maximum of 6
// clock cycles. Write transactions require a minimum of 3 clock cycles.

module ramcontrol(
    input clk,
    output [14:0] addr,
    output noe,
    output nwe,
    output reg ena,
    input [14:0] rd_addr,
    input rd_req,
    output reg rd_ack,
    input [14:0] wr_addr,
    input wr_req,
    output reg wr_ack
    );

localparam ADDR = 0, RD_0 = 1, RD_1 = 2, WR_0 = 3, WR_1 = 4;

reg rnw, oe, we;
reg oe_reg = 1'b0;
reg we_reg = 1'b0;
reg [2:0] curr_state = ADDR;
reg [2:0] next_state;

assign addr = rnw ? rd_addr : wr_addr;
assign noe = ~oe_reg;
assign nwe = ~we_reg;

  always @(posedge clk)
  begin
    curr_state <= next_state;
    oe_reg <= oe;
    we_reg <= we;
  end

  always @(*)
    case (curr_state)
      RD_0:
        begin
          { rd_ack, wr_ack } = 2'b00;
          { ena, rnw, oe, we } = 4'b0110;
          next_state = RD_1;
        end
      RD_1:
        begin
          { rd_ack, wr_ack } = 2'b10;
          { ena, rnw, oe, we } = 4'b0100;
          next_state = ADDR;
        end
      WR_0:
        begin
          { rd_ack, wr_ack } = 2'b00;
          { ena, rnw, oe, we } = 4'b1001;
          next_state = WR_1;
        end
      WR_1:
        begin
          { rd_ack, wr_ack } = 2'b01;
          { ena, rnw, oe, we } = 4'b1000;
          next_state = ADDR;
        end
      default:
        begin
          { rd_ack, wr_ack } = 2'b00;
          if (rd_req)
            begin
              { ena, rnw, oe, we } = 4'b0110;
              next_state = RD_0;
            end
          else if (wr_req)
            begin
              { ena, rnw, oe, we } = 4'b0001;
              next_state = WR_0;
            end
          else
            begin
              { ena, rnw, oe, we } = 4'b0100;
              next_state = ADDR;
            end
        end
    endcase

endmodule
