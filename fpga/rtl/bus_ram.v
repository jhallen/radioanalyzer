// Bus accessible RAM

module bus_ram
  (
  bus_in,
  bus_out
  );

parameter ADDR = 0;
parameter LOGSIZE = 16; // Log2 of memory size in bytes
parameter SIZE = (1 << LOGSIZE); // Size of this memory in bytes

`include "bus_params.v"

input [BUS_IN_WIDTH-1:0] bus_in;
output [BUS_OUT_WIDTH-1:0] bus_out;

`include "bus_decl.v"

wire decode = (bus_addr >= ADDR && bus_addr < (ADDR + SIZE));
wire wr_ack = (decode && |bus_we);
wire rd_ack = (decode && bus_re);

reg reg_rd_ack;

always @(posedge bus_clk)
  if (!bus_reset_l)
    reg_rd_ack <= 0;
  else
    reg_rd_ack <= rd_ack;

wire [31:0] ram_rd_data;

assign bus_out[BUS_RD_DATA_END-1:BUS_RD_DATA_START] = reg_rd_ack ? ram_rd_data : 32'd0;
assign bus_out[BUS_FIELD_RD_ACK] = reg_rd_ack;
assign bus_out[BUS_FIELD_WR_ACK] = wr_ack;
assign bus_out[BUS_FIELD_IRQ] = 0;

ram_sp_be #(.ADDRWIDTH(LOGSIZE-2)) ram
  (
  .clk (bus_clk),
  .we ({ bus_we[3] & decode, bus_we[2] & decode, bus_we[1] & decode, bus_we[0] & decode }),
  .addr (bus_addr[LOGSIZE-1:2]),
  .wr_data (bus_wr_data),
  .rd_data (ram_rd_data)
  );

endmodule
