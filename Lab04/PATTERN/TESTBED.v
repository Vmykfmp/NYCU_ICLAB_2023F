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

`include "/RAID2/COURSE/iclab/iclab059/Lab04/Exercise/00_TESTBED/PATTERN.vp"
`ifdef RTL
  `include "SNN.v"
`endif
`ifdef GATE
  `include "SNN_SYN.v"
`endif

	  		  	
module TESTBED;

wire          clk, rst_n, in_valid;
wire  [31:0]  Img;
wire  [31:0]  Kernel;
wire  [31:0]  Weight;
wire  [ 1:0]  Opt;
wire          out_valid;
wire  [31:0]  out;


initial begin
  `ifdef RTL
    $fsdbDumpfile("SNN.fsdb");
	$fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
  `endif
  `ifdef GATE
    $sdf_annotate("SNN_SYN.sdf", u_SNN);
    $fsdbDumpfile("SNN_SYN.fsdb");
    $fsdbDumpvars();    
  `endif
end

`ifdef RTL
SNN u_SNN(
    .clk(clk),
    .rst_n(rst_n),
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
    .in_valid(in_valid),
    .Img(Img),
    .Kernel(Kernel),
    .Weight(Weight),
    .Opt(Opt),
    .out_valid(out_valid),
    .out(out)
    );
  
 
endmodule
