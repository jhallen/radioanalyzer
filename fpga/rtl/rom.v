module rom
  (
  clk,
  rd_addr,
  rd_data
  );

parameter INIT_FILE = "notfound.mem";
parameter ADDRWIDTH=8;
parameter WORDS = (1 << ADDRWIDTH);

input clk;

input [ADDRWIDTH-1:0] rd_addr;

output [31:0] rd_data;
reg [31:0] rd_data;

reg [31:0] mem[0:WORDS-1] /* synthesis syn_romstyle = "EBR" */;

initial
  $readmemh(INIT_FILE, mem);

always @(posedge clk)
  rd_data <= mem[rd_addr];

endmodule
