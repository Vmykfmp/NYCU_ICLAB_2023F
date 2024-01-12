`timescale 1ns/1ps
`include "PATTERN.v"

`ifdef RTL
`include "PRGN_TOP.v"
`elsif GATE
`include "PRGN_TOP_SYN.v"
`endif

module TESTBED();


wire	    clk1, clk2, clk3;
wire        rst_n;
wire        in_valid;
wire [31:0] seed;
wire 	    out_valid;
wire [31:0] rand_num;

initial begin
  `ifdef RTL
    $fsdbDumpfile("PRGN_TOP.fsdb");
	$fsdbDumpvars(0,"+mda");
  `elsif GATE
	// $sdf_annotate("PRGN_TOP_SYN.sdf",I_PRGN); 
    $fsdbDumpfile("PRGN_TOP.fsdb");
	$sdf_annotate("PRGN_TOP_SYN_pt.sdf",I_PRGN,,,"maximum");      
	$fsdbDumpvars(0,"+mda");
  `endif
end

PRGN_TOP I_PRGN
(
  // Input signals
	.clk1(clk1),
	.clk2(clk2),
	.clk3(clk3),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.seed(seed),
  // Output signals
	.out_valid(out_valid),
	.rand_num(rand_num)
);


PATTERN I_PATTERN
(
  // Output signals
	.clk1(clk1),
	.clk2(clk2),
	.clk3(clk3),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.seed(seed),
  // Input signals
	.out_valid(out_valid),
	.rand_num(rand_num)
);

endmodule