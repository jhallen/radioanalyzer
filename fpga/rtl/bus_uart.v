// Simple UART
//   ADDR + 0 is baud divider register
//   ADDR + 4 is data register
//
// reads from data register: all 1s if no data available, otherwise return byte read.
// writes to data register: holds up bus until we can transmit

module bus_uart
  (
  bus_in,
  bus_out,

  testit,

  ser_tx,
  ser_rx
  );

parameter ADDR = 0;
parameter SIZE = 8;

`include "bus_params.v"

input [BUS_IN_WIDTH-1:0] bus_in;
output [BUS_OUT_WIDTH-1:0] bus_out;

input testit;

output ser_tx;
input ser_rx;

`include "bus_decl.v"

wire decode_div = ({ bus_addr[BUS_ADDR_WIDTH-1:2], 2'd0 } == ADDR);
wire decode_dat = ({ bus_addr[BUS_ADDR_WIDTH-1:2], 2'd0 } == (ADDR + 4));

wire [31:0] div_rd_data;
wire [31:0] dat_rd_data;
wire dat_ack;

reg div_rd_ack;
reg dat_rd_ack;

always @(posedge bus_clk)
  if (!bus_reset_l)
    begin
      div_rd_ack <= 0;
      dat_rd_ack <= 0;
    end
  else
    begin
      div_rd_ack <= (decode_div && bus_re);
      dat_rd_ack <= (decode_dat && bus_re);
    end

assign bus_out[BUS_RD_DATA_END-1:BUS_RD_DATA_START] = div_rd_ack ? div_rd_data : (dat_rd_ack ? dat_rd_data : 0);
assign bus_out[BUS_FIELD_RD_ACK] = div_rd_ack | dat_rd_ack;
assign bus_out[BUS_FIELD_WR_ACK] = (decode_div & |bus_we) | dat_ack;
assign bus_out[BUS_FIELD_IRQ] = 0;

simpleuart raw_uart
  (
  .clk (bus_clk),
  .resetn (bus_reset_l),

  .ser_tx (ser_tx),
  .ser_rx (ser_rx),

  .reg_div_we (bus_we & { 4 { decode_div } }),
  .reg_div_di (bus_wr_data),
  .reg_div_do (div_rd_data),

  .reg_dat_we ((decode_dat & |bus_we) | testit),
  .reg_dat_re (decode_dat & bus_re),
  .reg_dat_di (testit ? 32'h41 : bus_wr_data),
  .reg_dat_do (dat_rd_data),
  .reg_dat_ack (dat_ack)
  );

endmodule
