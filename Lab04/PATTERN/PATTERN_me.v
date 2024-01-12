//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Siamese Neural Network
//   Author     		: Jia-Yu Lee (maggie8905121@gmail.com)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : V1.0 (Release Date: 2023-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`define CYCLE_TIME      50.0
`define SEED_NUMBER     28825252
`define PATTERN_NUMBER 10000

module PATTERN(
    //Output Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel,
	Weight,
    Opt,
    //Input Port
    out_valid,
    out
    );

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output reg        clk, rst_n, in_valid;
output reg [31:0] Img;
output reg [31:0] Kernel;
output reg [31:0] Weight;
output reg [ 1:0] Opt;
input        out_valid;
input [31:0] out;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------

parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;

integer img_read, kernel_read, weight_read, golden_read, i_pat;
integer img_dat, kernel_dat, weight_dat;
integer option;
integer latency;
integer total_latency;
integer a, t, i;

reg [31:0] golden;

// reg clk;
/* define clock cycle */
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;


always@(*)begin
	if(in_valid && out_valid)begin
        $display("************************************************************");  
        $display("                          FAIL!                             ");    
        $display("*  The out_valid cannot overlap with in_valid   *"           );
        $display("************************************************************");
		//repeat(9)@(negedge clk);
		$finish;
	end
end

initial begin
    img_read    = $fopen("../00_TESTBED/input_img.txt", "r");
    kernel_read = $fopen("../00_TESTBED/input_kernel.txt", "r");
    weight_read = $fopen("../00_TESTBED/input_weight.txt", "r");
    golden_read = $fopen("../00_TESTBED/output.txt", "r");
    reset_signal_task;

    a = $fscanf(img_read, "%b", option);
    for (i_pat = 1; i_pat <= 1; i_pat = i_pat + 1) begin
        input_task;
        wait_out_valid_task;
        check_ans_task;
        total_latency = total_latency + latency;
        // \033[32;42m Hello pass!\033[0m
        $display("\033[0;32m PASS PATTERN NO.%4d \033[0m", i_pat);
    end
    $fclose(img_read);
    $fclose(kernel_read);
    $fclose(weight_read);
    $fclose(golden_read);
    YOU_PASS_task;
end

task reset_signal_task; begin
    rst_n = 'b1;
    in_valid = 'b0;
    Img    = 'bx;
    Kernel = 'bx;
    Weight = 'bx;
    Opt    = 'bx;		
    total_latency = 0;

    force clk = 0;

    #CYCLE; rst_n = 0;
    #CYCLE; rst_n = 1;

    if(out_valid !== 'b0 || out  !== 'b0) begin //out!==0
        $display("************************************************************");  
        $display("                          FAIL!                              ");    
        $display("*  Output signal should be 0 after initial RESET  at %8t   *",$time);
        $display("************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
    #CYCLE; release clk;
end endtask

task output_valid_task; begin
    if(out_valid === 0 && out !== 0) begin
        $display("\nSPEC MAIN-2 FAIL\n");
        $finish;
    end
end endtask

task input_task; begin
    t = $urandom_range(1, 4);
    repeat(t) @(negedge clk);


    Opt = option;
    in_valid = 1'b1;
    for(i = 0; i < 96; i = i + 1) begin
        
        
        a = $fscanf(img_read, "%b ", img_dat);
        Img = img_dat;

        if(i < 27) begin
            a = $fscanf(kernel_read, "%b ", kernel_dat);
            Kernel = kernel_dat;
        end
        else Kernel = 'bx;

        if(i < 4) begin
            a = $fscanf(weight_read, "%b ", weight_dat);
            Weight = weight_dat;
        end
        else Weight = 'bx;
        

        @(negedge clk);
        Opt = 'bx;
    end

    in_valid = 1'b0;
	Img    = 'bx;
	Kernel = 'bx;
	Weight = 'bx;

end endtask

task wait_out_valid_task; begin
    latency = 0;
    while(out_valid !== 1'b1) begin
	latency = latency + 1;
      if( latency == 100) begin
          $display("********************************************************");     
          $display("                          FAIL!                         ");
          $display("*  The execution latency are over 1000 cycles  at %8t  *",$time);//over max
          $display("********************************************************");
	    repeat(2)@(negedge clk);
	    $finish;
      end
     @(negedge clk);
   end
   total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
    while(out_valid === 1)begin
        a = $fscanf(golden_read, "%b", golden);
		if(out !== golden)begin
			$display ("---------------------");
			$display ("       \033[0;31m FAIL! \033[0m       ");
            $display ("   your answer : %2h ", out);
            $display (" golden answer : %2h ", golden);
			$display ("---------------------");
            repeat(9) @(negedge clk);
			$finish;	
		end
		else begin
			@(negedge clk);
		end
	end	

end endtask

//////////////////////////////////////////////////////////////////////

task YOU_PASS_task; begin
    $display("********************************************************************");
    $display("*                        \033[0;32m Congratulations! \033[0m                        *");
    // $display("*                total %4d pattern are passed                     *", PAT_NUM);
    $display("********************************************************************");
    $finish;
end endtask

task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                    Error message from PATTERN.v                       *");
end endtask

endmodule


