// Single address port 32-bit wide RAM with byte-enables

module ram_sp_be
  (
  clk,
  we,
  addr,
  wr_data,
  rd_data
  );

parameter ADDRWIDTH=8;
parameter WORDS = (1 << ADDRWIDTH);

input clk;
input [3:0] we;
input [ADDRWIDTH-1:0] addr;
input [31:0] wr_data;
output [31:0] rd_data;
reg [31:0] rd_data;

reg [31:0] mem[0:WORDS-1];

always @(posedge clk)
  begin
    rd_data <= mem[addr];
    if (we[0]) mem[addr][7:0] <= wr_data[7:0];
    if (we[1]) mem[addr][15:8] <= wr_data[15:8];
    if (we[2]) mem[addr][23:16] <= wr_data[23:16];
    if (we[3]) mem[addr][31:24] <= wr_data[31:24];
  end

endmodule
