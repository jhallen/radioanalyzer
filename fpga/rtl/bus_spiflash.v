// Bus accessible SPI Flash

module bus_spiflash
  (
  bus_in,
  bus_out,

  flash_cs_l,
  flash_clk,

  flash_io0_oe,
  flash_io1_oe,
  flash_io2_oe,
  flash_io3_oe,

  flash_io0_do,
  flash_io1_do,
  flash_io2_do,
  flash_io3_do,

  flash_io0_di,
  flash_io1_di,
  flash_io2_di,
  flash_io3_di
  );

parameter BUS_ADDR_CFG = 0; // Config register I/O address
parameter SIZE_CFG = 4;

parameter BUS_ADDR_MEM = 32'h0000_0000; // Where memory is located on the bus
parameter SIZE_MEM = 32'h0010_0000; // How much bus space allocated for the memory
parameter MEM_OFFSET = 32'h0070_0000; // Offset within flash to our memory

`include "bus_params.v"

input [BUS_IN_WIDTH-1:0] bus_in;
output [BUS_OUT_WIDTH-1:0] bus_out;

output flash_cs_l;
output flash_clk;

output flash_io0_oe;
output flash_io1_oe;
output flash_io2_oe;
output flash_io3_oe;

output flash_io0_do;
output flash_io1_do;
output flash_io2_do;
output flash_io3_do;

input  flash_io0_di;
input  flash_io1_di;
input  flash_io2_di;
input  flash_io3_di;

`include "bus_decl.v"

// Flash config register

wire decode_cfg = ({ bus_addr[BUS_ADDR_WIDTH-1:2], 2'd0 } == BUS_ADDR_CFG);
wire decode_mem = (bus_addr >= BUS_ADDR_MEM && bus_addr < (BUS_ADDR_MEM + SIZE_MEM));

wire mem_rd_req = decode_mem && bus_rd_req;

wire cfg_wr_ack = decode_cfg && bus_wr_req;
wire cfg_rd_ack = decode_cfg && bus_rd_req;

reg cfg_rd_ack_reg;
reg cfg_wr_ack_reg;

wire spimem_ready; // High only when spimem_valid is high
reg spimem_valid;

reg [23:0] spimem_addr;

always @(posedge bus_clk)
  if (!bus_reset_l)
    begin
      cfg_rd_ack_reg <= 0;
      cfg_wr_ack_reg <= 0;
      spimem_valid <= 0;
      spimem_addr <= 0;
    end
  else
    begin
      cfg_rd_ack_reg <= cfg_rd_ack;
      cfg_wr_ack_reg <= cfg_wr_ack;
      spimem_valid <= mem_rd_req || (spimem_valid && !spimem_ready);
      if (mem_rd_req)
        spimem_addr <= bus_addr - BUS_ADDR_MEM + MEM_OFFSET;
    end

wire [3:0] cfgreg_we = (bus_be & { 4 { cfg_wr_ack } });
wire [31:0] cfgreg_do;

wire [31:0] spimem_rdata;

assign bus_out[BUS_RD_DATA_END-1:BUS_RD_DATA_START] = spimem_ready ? spimem_rdata : (cfg_rd_ack_reg ? cfgreg_do : 32'd0);
assign bus_out[BUS_FIELD_RD_ACK] = cfg_rd_ack_reg | spimem_ready;
assign bus_out[BUS_FIELD_WR_ACK] = cfg_wr_ack_reg;
assign bus_out[BUS_FIELD_IRQ] = 0;

spimemio spimemio
  (
  .clk (bus_clk),
  .resetn (bus_reset_l),

  .valid (spimem_valid),
  .ready (spimem_ready),
  .addr (spimem_addr),
  .rdata (spimem_rdata),

  .flash_csb (flash_cs_l),
  .flash_clk (flash_clk),

  .flash_io0_oe (flash_io0_oe),
  .flash_io1_oe (flash_io1_oe),
  .flash_io2_oe (flash_io2_oe),
  .flash_io3_oe (flash_io3_oe),

  .flash_io0_do (flash_io0_do),
  .flash_io1_do (flash_io1_do),
  .flash_io2_do (flash_io2_do),
  .flash_io3_do (flash_io3_do),

  .flash_io0_di (flash_io0_di),
  .flash_io1_di (flash_io1_di),
  .flash_io2_di (flash_io2_di),
  .flash_io3_di (flash_io3_di),

  .cfgreg_we (cfgreg_we),
  .cfgreg_di (bus_wr_data),
  .cfgreg_do (cfgreg_do)
  );

endmodule

