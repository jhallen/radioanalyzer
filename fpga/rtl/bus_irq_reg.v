// Interrupt register

module bus_irq_reg
  (
  // Internal bus
  bus_in,
  bus_out,

  enable,	// Interrupt enable bits
  trig,		// Interrupt requests
  irq		// Interrupt request output
  );

parameter ADDR=0;
parameter OFFSET=0;
parameter DATAWIDTH=32;
parameter REG=0;
parameter SIZE=4;

`include "bus_params.v"

input [BUS_IN_WIDTH-1:0] bus_in;
output [BUS_OUT_WIDTH-1:0] bus_out;

input [DATAWIDTH-1:0] enable;

input [DATAWIDTH-1:0] trig;

output irq;
reg irq;

`include "bus_decl.v"

// Bus driver

reg [DATAWIDTH-1:0] cur;
reg [DATAWIDTH-1:0] out;

wire decode = ({ bus_addr[BUS_ADDR_WIDTH-1:2], 2'd0 } == ADDR);
wire reg_rd_ack = (decode && bus_re);
wire reg_wr_ack = (decode && bus_we);

assign bus_out[BUS_RD_DATA_END-1:BUS_RD_DATA_START] = reg_rd_ack ? (out << OFFSET) : { BUS_DATA_WIDTH { 1'd0 } };
assign bus_out[BUS_FIELD_RD_ACK] = reg_rd_ack;
assign bus_out[BUS_FIELD_WR_ACK] = reg_wr_ack;
assign bus_out[BUS_FIELD_IRQ] = 0;

reg [3:0] count;

always @(posedge bus_clk)
  if(!bus_reset_l)
    begin
      cur <= 0;
      out <= 0;
      count <= 0;
      irq <= 0;
    end
  else
    begin
      if (count)
        count <= count - 1;

      irq <= (count == 0) && |(out & enable);

      out <= cur;

      if (cur & ~out)
        count <= 15; // New interrupt detected

      if(reg_wr_ack)
        cur <= (cur ^ (bus_wr_data >> OFFSET)) | trig;
      else
        cur <= cur | trig;
    end

endmodule
