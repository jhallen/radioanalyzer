`timescale 1ns / 1ns

module tb;

reg clk;
reg reset_l;
wire ser_rx = 1;
wire ser_tx;
wire [7:0] leds;

ra_top ra_top
  (
  .clk (clk),
  .reset_l_in (reset_l),
  .ser_tx (ser_tx),
  .ser_rx (ser_rx),
  .leds (leds)
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
    for (x = 0; x != 1000000; x = x + 1)
      @(posedge clk);

    $finish;
  end

endmodule
