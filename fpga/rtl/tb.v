`timescale 1ns / 1ns

module tb;

reg clk;
reg reset_l;
wire ser_rx = 1;
wire ser_tx;
wire [7:0] leds;

wire flash_clk;
wire flash_cs_l;
wire flash_d0;
wire flash_d1;
wire flash_d2;
wire flash_d3;

spiflash spiflash
  (
  .csb (flash_cs_l),
  .clk (flash_clk),
  .io0 (flash_d0), // MOSI
  .io1 (flash_d1), // MISO
  .io2 (flash_d2),
  .io3 (flash_d3)
  );


ra_top ra_top
  (
  .clk (clk),
  .reset_l_in (reset_l),
  .ser_tx (ser_tx),
  .ser_rx (ser_rx),
  .leds (leds),
  .flash_clk (flash_clk),
  .flash_cs_l (flash_cs_l),
  .flash_d0 (flash_d0),
  .flash_d1 (flash_d1),
  .flash_d2 (flash_d2),
  .flash_d3 (flash_d3)
  );

always
  #5 clk <= !clk;

integer x;

initial
  begin
    $dumpvars(0);
    $dumpon;
    $display("Hi there!\n");
    clk <= 0;
    reset_l <= 1;

    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    reset_l <= 0;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    reset_l <= 1;
    @(posedge clk);
    @(posedge clk);
    for (x = 0; x != 200000; x = x + 1)
      @(posedge clk);

    $finish;
  end

endmodule
