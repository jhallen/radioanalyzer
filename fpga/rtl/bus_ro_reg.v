// Read-only bus register

module bus_ro_reg
  (
  bus_in,
  bus_out,

  in,
  rd_pulse
  );

parameter DATAWIDTH = 32; // No. bits (1..32)
parameter OFFSET = 0; // Bit position (0..31)
parameter ADDR = 0; // Address
parameter REG = 0; // Flag that this is a register
parameter SIZE = 4;

`include "bus_params.v"

input [BUS_IN_WIDTH-1:0] bus_in;
output [BUS_OUT_WIDTH-1:0] bus_out;

output rd_pulse;
reg rd_pulse;

input [DATAWIDTH-1:0] in;

`include "bus_decl.v"

wire reg_rd_ack = (bus_rd_addr == ADDR && bus_re);

wire [BUS_DATA_WIDTH-1:0] shift_data = ({ { BUS_DATA_WIDTH - DATAWIDTH { 1'd0 } }, in } << OFFSET);

assign bus_out[BUS_RD_DATA_END-1:BUS_RD_DATA_START] = reg_rd_ack ? shift_data : { BUS_DATA_WIDTH { 1'd0 } };
assign bus_out[BUS_FIELD_RD_ACK] = reg_rd_ack;
assign bus_out[BUS_FIELD_WR_ACK] = 0;
assign bus_out[BUS_FIELD_IRQ] = 0;

always @(posedge bus_clk)
  if (!bus_reset_l)
    rd_pulse <= 0;
  else
    rd_pulse <= reg_rd_ack;

endmodule
