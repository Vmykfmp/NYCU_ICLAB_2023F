//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2018 Fall
//   Lab02 Practice		: Complex Number Calculater
//   Author     		: Ping-Yuan Tsai (bubblegame@si2lab.org)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESETBED.v
//   Module Name : TESETBED
//   Release version : V1.0 (Release Date: 2018-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`timescale 1ns/10ps
`ifdef RTL
	`ifdef NCG
  `include "/RAID2/COURSE/iclab/iclab059/Lab08/EXERCISE/00_TESTBED/PATTERN.vp"
	// `include "PATTERN.vp"
	`endif
	`ifdef CG
  `include "/RAID2/COURSE/iclab/iclab059/Lab08/EXERCISE/00_TESTBED/PATTERN_CG.vp"
	// `include "PATTERN_CG.v"
	`endif
`endif
`ifdef GATE
	`ifdef NCG
  `include "/RAID2/COURSE/iclab/iclab059/Lab08/EXERCISE/00_TESTBED/PATTERN.vp"
	// `include "PATTERN.v"
	`endif
	`ifdef CG
  `include "/RAID2/COURSE/iclab/iclab059/Lab08/EXERCISE/00_TESTBED/PATTERN_CG.vp"
	// `include "PATTERN_CG.v"
	`endif
`endif

`ifdef RTL
  `include "SNN.v"
`endif
`ifdef GATE
  `include "SNN_SYN.v"
`endif

	  		  	
module TESTBED;

wire          clk, rst_n, in_valid;
wire          cg_en;
wire  [31:0]  Img;
wire  [31:0]  Kernel;
wire  [31:0]  Weight;
wire  [ 1:0]  Opt;
wire          out_valid;
wire  [31:0]  out;


initial begin
  `ifdef RTL
    `ifdef NCG
    $fsdbDumpfile("SNN.fsdb");
	$fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
    `endif

    `ifdef CG
    $fsdbDumpfile("SNN_CG.fsdb");
	$fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
    `endif
  `endif
  `ifdef GATE
	`ifdef NCG
    		$sdf_annotate("SNN_SYN.sdf", u_SNN);
    		$fsdbDumpfile("SNN_SYN.fsdb");
    		$fsdbDumpvars();    
	`endif
	`ifdef CG	
    		$sdf_annotate("SNN_SYN.sdf", u_SNN);
    		$fsdbDumpfile("SNN_SYN_CG.fsdb");
    		$fsdbDumpvars();    
	`endif

  `endif
end

`ifdef RTL
SNN u_SNN(
    .clk(clk),
    .rst_n(rst_n),
    .cg_en(cg_en),
    .in_valid(in_valid),
    .Img(Img),
    .Kernel(Kernel),
    .Weight(Weight),
    .Opt(Opt),
    .out_valid(out_valid),
    .out(out)
    );
`endif

`ifdef GATE
SNN u_SNN(
    .clk(clk),
    .rst_n(rst_n),
    .cg_en(cg_en),
    .in_valid(in_valid),
    .Img(Img),
    .Kernel(Kernel),
    .Weight(Weight),
    .Opt(Opt),
    .out_valid(out_valid),
    .out(out)
    );
`endif

PATTERN u_PATTERN(
    .clk(clk),
    .rst_n(rst_n),
    .cg_en(cg_en),
    .in_valid(in_valid),
    .Img(Img),
    .Kernel(Kernel),
    .Weight(Weight),
    .Opt(Opt),
    .out_valid(out_valid),
    .out(out)
    );
  
 
endmodule
