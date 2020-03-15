// Bus accessible SPI Flash

module bus_spiflash
  (
  bus_in,
  bus_out,

  flash_cs_l,
//  flash_sclk,
  flash_d0,
  flash_d1,
  flash_d2,
  flash_d3
  );

parameter BUS_ADDR_CFG = 0; // Config register I/O address
parameter SIZE_CFG = 4;

parameter BUS_ADDR_MEM = 32'h0000_0000; // Where memory is located on the bus
parameter SIZE_MEM = 32'h0010_0000; // How much bus space allocated for the memory
parameter MEM_OFFSET = 32'h00F0_0000; // Offset within flash to our memory

`include "bus_params.v"

input [BUS_IN_WIDTH-1:0] bus_in;
output [BUS_OUT_WIDTH-1:0] bus_out;

output flash_cs_l;
// output flash_sclk;
inout flash_d0;
inout flash_d1;
inout flash_d2;
inout flash_d3;

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

assign bus_out[BUS_RD_DATA_END-1:BUS_RD_DATA_START] = spimem_ready ? spimem_rdata : (cfg_rd_ack_reg ? cfgreg_do : 32'd0);
assign bus_out[BUS_FIELD_RD_ACK] = cfg_rd_ack_reg | spimem_ready;
assign bus_out[BUS_FIELD_WR_ACK] = cfg_wr_ack_reg;
assign bus_out[BUS_FIELD_IRQ] = 0;

// Flash data bit drivers

wire flash_oe0;
wire flash_oe1;
wire flash_oe2;
wire flash_oe3;

wire flash_do0;
wire flash_do1;
wire flash_do2;
wire flash_do3;

assign flash_d0 = flash_oe0 ? flash_do0 : 1'bz;
assign flash_d1 = flash_oe1 ? flash_do1 : 1'bz;
assign flash_d2 = flash_oe2 ? flash_do2 : 1'bz;
assign flash_d3 = flash_oe3 ? flash_do3 : 1'bz;

`ifdef junk
module USRMCLK (USRMCLKI, USRMCLKTS);
input USRMCLKI, USRMCLKTS;
endmodule
`endif

reg mclk_oe;
reg mclk_oe_1;

// Lattice way of accessing spi_sclk pin
USRMCLK u1 (.USRMCLKI(flash_clk), .USRMCLKTS(mclk_oe)) /* synthesis syn_noprune=1 */;

always @(posedge bus_clk)
  if (!bus_reset_l)
    begin
      mclk_oe_1 <= 1;
      mclk_oe <= 1;
    end
  else
    begin
      mclk_oe_1 <= 0;
      mclk_oe <= mclk_oe_1;
    end

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

  .flash_io0_oe (flash_oe0),
  .flash_io1_oe (flash_oe1),
  .flash_io2_oe (flash_oe2),
  .flash_io3_oe (flash_oe3),

  .flash_io0_do (flash_do0),
  .flash_io1_do (flash_do1),
  .flash_io2_do (flash_do2),
  .flash_io3_do (flash_do3),

  .flash_io0_di (flash_d0),
  .flash_io1_di (flash_d1),
  .flash_io2_di (flash_d2),
  .flash_io3_di (flash_d3),

  .cfgreg_we (cfgreg_we),
  .cfgreg_di (bus_wr_data),
  .cfgreg_do (cfgreg_do)
  );

endmodule
