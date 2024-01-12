/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : PATTERN_bridge.sv
Module Name : PATTERN_bridge
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"

program automatic PATTERN_bridge(input clk, INF.PATTERN_bridge inf);
import usertype::*;

logic c_in_flag;

initial begin
	forever@(negedge inf.rst_n)begin
		#(100);
		if((inf.C_addr !== 'b0)||(inf.C_r_wb !== 'b0)||(inf.C_in_valid !== 'b0)||(inf.C_data_w !== 'b0)|| //outputs from pokemon to bridge
		  (inf.C_out_valid !== 'b0)||(inf.C_data_r !== 'b0)|| // outputs from bridge to dram
		  (inf.AR_VALID !== 'b0)||(inf.AR_ADDR !== 'b0)||(inf.R_READY !== 'b0)||(inf.AW_VALID !== 'b0)||
		  (inf.AW_ADDR !== 'b0)||(inf.W_VALID !== 'b0)||(inf.W_DATA !== 'b0)||(inf.B_READY !== 'b0)) begin //outputs from bridge to dram
		if (inf.C_addr !== 'b0)
			$display("C_addr error!");
		if (inf.C_r_wb !== 'b0)
			$display("C_r_wb error!");
		if (inf.C_in_valid!=='b0)
			$display("C_in_valid error!");
		if (inf.C_data_w !== 'b0)
			$display("C_data_w error!");
		if (inf.C_out_valid !== 'b0)
			$display("C_out_valid error!");
		if (inf.C_data_r !== 'b0)
			$display("C_data_r error!");
		if (inf.AR_VALID!== 'b0)
			$display("AR_VALID error!");
		if (inf.AR_ADDR!=='b0)
			$display("AR_ADDR error!");
		if (inf.R_READY !== 'b0)
			$display("R_READY error!");
		if (inf.AW_VALID !== 'b0)
			$display("inf.AW_VALID error!");
		if (inf.AW_ADDR !== 'b0)
			$display("AW_ADDR error!");
		if (inf.W_VALID !== 'b0)
			$display("W_VALID error!");
		if (inf.W_DATA !== 'b0)
			$display("(inf.W_DATA !== 'b0)");
		if (inf.W_DATA !== 'b0)
			$display("(inf.W_DATA !== 'b0)");
		if (inf.B_READY !== 'b0)
			$display("(inf.B_READY !== 'b0)");
		
		$display("************************************************************");
		$display("*                             FAIL                         *");
		$display("*  All Output signal should be 0 after initial RESET at %t *",$time);
		$display("************************************************************");
		$finish;
		end
	end
end

initial begin
	forever@(negedge clk or negedge inf.rst_n) begin
		if(!inf.rst_n)begin
			c_in_flag = 0;
		end
		else begin
			if(inf.C_in_valid)begin
				if(c_in_flag) begin
					$display("************************************************************");
					$display("*                             FAIL                         *");
					$display("*     C_in_valid can only be high for one cycle            *");
					$display("*     And can't be pulled high again before C_out_valid    *");
					$display("************************************************************");
					$finish;
				end
				else begin
					c_in_flag = 1;
				end
			end
			else if(inf.C_out_valid) begin
				c_in_flag = 0;
			end
		end
	end
end

endprogram