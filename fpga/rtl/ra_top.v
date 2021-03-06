module ra_top
  (
  clk,
  reset_l_in,

  ser_tx,
  ser_rx,

  leds,

// synthesis translate_off
  flash_clk,
// synthesis translate_on
  flash_cs_l,
  flash_d0,
  flash_d1,
  flash_d2,
  flash_d3
  );

input clk;
input reset_l_in;

output ser_tx;
input ser_rx;

output [7:0] leds;

// synthesis translate_off
output flash_clk;
// synthesis translate_on
wire flash_clk;
output flash_cs_l;
inout flash_d0;
inout flash_d1;
inout flash_d2;
inout flash_d3;

// Reset syncronizer
// Synchronous reset is better in Xilinx for some reason.

reg reset_l = 0;
reg reset_l_1 = 0;
reg reset_l_2 = 0;
reg reset_l_3 = 0;
reg reset_l_4;
reg reset_l_5;
reg reset_l_6;

always @(posedge clk or negedge reset_l_in)
  if (!reset_l_in)
    begin
      reset_l_4 <= 0;
      reset_l_5 <= 0;
      reset_l_6 <= 0;
    end
  else
    begin
      reset_l_4 <= reset_l_5;
      reset_l_5 <= reset_l_6;
      reset_l_6 <= 1;
    end

// This eliminates Vivado complaint that async signals appearing at block RAM inputs can corrupt contents

always @(posedge clk)
  begin
    reset_l <= reset_l_1;
    reset_l_1 <= reset_l_2;
    reset_l_2 <= reset_l_3;
    reset_l_3 <= reset_l_4;
  end

// CPU signals

wire [31:0] mem_wdata;
wire [3:0] mem_be;
wire [31:0] mem_addr;
wire [31:0] irq;
wire [31:0] mem_rdata;
wire mem_read;
wire mem_write;
wire mem_ready;

// Joe's SoC bus

`include "bus_params.v"

wire [BUS_IN_WIDTH-1:0] bus_in;
wire [BUS_OUT_WIDTH-1:0] bus_out;

assign bus_in[BUS_FIELD_RESET_L] = reset_l;
assign bus_in[BUS_FIELD_CLK] = clk;
assign bus_in[BUS_FIELD_BE+3:BUS_FIELD_BE] = mem_be;
assign bus_in[BUS_ADDR_END-1:BUS_ADDR_START] = mem_addr;
assign bus_in[BUS_WR_DATA_END-1:BUS_WR_DATA_START] = mem_wdata;
assign bus_in[BUS_FIELD_RD_REQ] = mem_read;
assign bus_in[BUS_FIELD_WR_REQ] = mem_write;

assign mem_rdata = bus_out[BUS_RD_DATA_END-1:BUS_RD_DATA_START];
assign mem_ready = bus_out[BUS_FIELD_WR_ACK] | bus_out[BUS_FIELD_RD_ACK];

// LEDs

wire [BUS_OUT_WIDTH-1:0] led_reg_bus_out;

wire [31:0] led_reg_out;

// assign leds[6:0] = led_reg_out[6:0];

bus_reg #(.BUS_ADDR(32'h0300_0000)) led_reg
  (
  .bus_in (bus_in),
  .bus_out (led_reg_bus_out),

  .out (led_reg_out)
  );

// Blinking LED

reg [7:0] blink;
reg [23:0] counter;
reg testit;

assign leds = { blink[7], led_reg_out[6:0] };

always @(posedge clk)
  if (!reset_l)
    begin
      counter <= 12000000;
      blink <= 8'h55;
      testit <= 0;
    end
  else
    begin
      testit <= 0;
      if (counter)
        counter <= counter - 1'd1;
      else
        begin
          counter <= 12000000;
          blink <= ~blink;
          testit <= 1;
        end
    end
  

`ifdef junk
// SPI interface config reg

wire [BUS_OUT_WIDTH-1:0] spicfg_bus_out;

wire [31:0] spicfg_out;

bus_reg #(.BUS_ADDR(32'h0200_0000)) spicfg_reg
  (
  .bus_in (bus_in),
  .bus_out (spicfg_bus_out),

  .out (spicfg_out)
  );
`endif

// UART

wire [BUS_OUT_WIDTH-1:0] uart_bus_out;

bus_uart #(.BUS_ADDR(32'h0200_0004)) uart
  (
  .bus_in (bus_in),
  .bus_out (uart_bus_out),
  .testit (1'b0), // (testit),
  .ser_tx (ser_tx),
  .ser_rx (ser_rx)
  );

// Software RAM

wire [BUS_OUT_WIDTH-1:0] cpu_ram_bus_out;

bus_ram #(.BUS_ADDR(32'h0000_0000), .LOGSIZE(16)) cpu_ram
  (
  .bus_in (bus_in),
  .bus_out (cpu_ram_bus_out)
  );

// Software ROM

wire [BUS_OUT_WIDTH-1:0] cpu_rom_bus_out;

`ifdef junk
// Note that path for INIT_FILE is relative to diamond implementation directory.
bus_rom #(.BUS_ADDR(32'h0001_0000), .LOGSIZE(16), .INIT_FILE("../../sw/ra.mem")) cpu_rom
  (
  .bus_in (bus_in),
  .bus_out (cpu_rom_bus_out)
  );
`endif

// SPI Flash

reg mclk_oe;
reg mclk_oe_1;

// Lattice way of accessing spi_sclk pin
USRMCLK u1 (.USRMCLKI(flash_clk), .USRMCLKTS(mclk_oe)) /* synthesis syn_noprune=1 */;

always @(posedge clk)
  if (!reset_l)
    begin
      mclk_oe_1 <= 1;
      mclk_oe <= 1;
    end
  else
    begin
      mclk_oe_1 <= 0;
      mclk_oe <= mclk_oe_1;
    end

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

bus_spiflash #(
  .BUS_ADDR_MEM(32'h0010_0000),
  .SIZE_MEM(32'h0010_0000),
  .BUS_ADDR_CFG(32'h0200_0000),
  .MEM_OFFSET(32'h00F0_0000)
) cpu_rom (
  .bus_in (bus_in),
  .bus_out (cpu_rom_bus_out),

  .flash_cs_l (flash_cs_l),
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
  .flash_io3_di (flash_d3)
  );

// RISC-V CPU

picorv32 #(
  .STACKADDR (32'h0001_0000), // End of RAM, initial SP value
  .PROGADDR_RESET (32'h0010_0000), // Start of ROM, initial PC value
  .PROGADDR_IRQ (32'h0010_0010),
  .BARREL_SHIFTER (1),
  .COMPRESSED_ISA (1),
  .ENABLE_COUNTERS (1),
  .ENABLE_MUL (1),
  .ENABLE_DIV (1),
  .ENABLE_IRQ (1),
  .ENABLE_IRQ_QREGS (0)
) cpu
  (
  .clk (clk),
  .resetn (reset_l),

  .trap (),
  
  .mem_ready (mem_ready),
  .mem_rdata (mem_rdata),

  .mem_valid (),
  .mem_instr (),
  .mem_addr (),
  .mem_wdata (),
  .mem_wstrb (),

  .mem_la_read (mem_read),
  .mem_la_write (mem_write),
  .mem_la_addr (mem_addr),
  .mem_la_wdata (mem_wdata),
  .mem_la_wstrb (mem_be),

  .irq (irq),
  .eoi (),

  .pcpi_valid (),
  .pcpi_insn (),
  .pcpi_rs1 (),
  .pcpi_rs2 (),
  .pcpi_wr (),
  .pcpi_rd (),
  .pcpi_wait (),
  .pcpi_ready (),

  .trace_valid (),
  .trace_data ()
  );

// No Verilog 'wor' support in Vivado! So we need a giant OR gate instead..

assign bus_out =
  cpu_ram_bus_out |
  cpu_rom_bus_out |
  uart_bus_out |
  led_reg_bus_out
  ;

endmodule

// synthesis translate_off
module USRMCLK (USRMCLKI, USRMCLKTS);
input USRMCLKI, USRMCLKTS;
endmodule
// synthesis translate_on
