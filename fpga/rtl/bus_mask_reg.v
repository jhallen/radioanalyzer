// Bus register where upper 16 bits are the write mask for the lower 16 bits

module bus_mask_reg
  (
  bus_in,
  bus_out,

  in,
  out,
  wr_pulse
  );

parameter DATAWIDTH = 16; // No. bits (1..16)
parameter IZ = 0; // Initial value
parameter ADDR = 0; // Address
parameter REG = 0; // Flag that this is a register
parameter SIZE = 4;

`include "bus_params.v"

input [BUS_IN_WIDTH-1:0] bus_in;
output [BUS_OUT_WIDTH-1:0] bus_out;

input [DATAWIDTH-1:0] in;

output [DATAWIDTH-1:0] out;
reg [DATAWIDTH-1:0] out;

output wr_pulse;
reg wr_pulse;

`include "bus_decl.v"

wire decode = ({ bus_addr[BUS_ADDR_WIDTH-1:2], 2'd0 } == ADDR);

wire rd_ack = (decode && bus_re);
wire wr_ack = (decode && bus_we);
reg reg_rd_ack;
reg reg_wr_ack;

assign bus_out[BUS_RD_DATA_END-1:BUS_RD_DATA_START] = reg_rd_ack ? in : { BUS_DATA_WIDTH { 1'd0 } };
assign bus_out[BUS_FIELD_RD_ACK] = reg_rd_ack;
assign bus_out[BUS_FIELD_WR_ACK] = reg_wr_ack;
assign bus_out[BUS_FIELD_IRQ] = 0;

always @(posedge bus_clk)
  if (!bus_reset_l)
    begin
      out <= IZ;
      wr_pulse <= 0;
      reg_rd_ack <= 0;
      reg_wr_ack <= 0;
    end
  else
    begin
      reg_rd_ack <= rd_ack;
      reg_wr_ack <= wr_ack;
      wr_pulse <= 0;
      if (wr_ack)
        begin
          out <= (bus_wr_data[16+DATAWIDTH-1:16] & bus_wr_data[DATAWIDTH-1:0]) | (~bus_wr_data[16+DATAWIDTH-1:16] & out);
          wr_pulse <= 1;
        end
    end

endmodule
