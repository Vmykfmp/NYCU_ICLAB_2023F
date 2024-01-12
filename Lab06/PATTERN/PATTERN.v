`ifdef RTL
    `define CYCLE_TIME 20.0
`endif
`ifdef GATE
    `define CYCLE_TIME 7.8
`endif

`define PAT_NUM 1
module PATTERN(
    // Output signals
    clk,
	rst_n,
	in_valid,
    in_weight, 
	out_mode,
    // Input signals
    out_valid, 
	out_code
);

// ========================================
// Input & Output
// ========================================
output reg clk, rst_n, in_valid, out_mode;
output reg [2:0] in_weight;

input out_valid, out_code;

// ========================================
// Parameter
// ========================================

reg mode_read;
reg [2:0] in_weight_read;
reg [4:0] golden_bitnum;
reg [31:0] golden;
reg [31:0] out_save;
integer latency;
integer total_latency;
integer i, i_pat, a, t;
real CYCLE = `CYCLE_TIME;
integer pat_read, out_read;
reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";

//================================================================
// design
//================================================================

/* define clock cycle */
always #(CYCLE/2.0) clk = ~clk;

/*out_data_reset_check_*/
always @ (negedge clk) begin
    if((out_valid === 'b0) && (out_code !== 'd0))begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                      FAIL!                                                               ");
        $display ("                                                   out_data should be reset when out_valid low                                            ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
        repeat(9)@(negedge clk);
        $finish;
    end
end

always@(*)begin
	if(in_valid && out_valid)begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                      FAIL!                                                               ");
        $display ("                                                   The out_valid cannot overlap with in_valid                                            ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		repeat(9)@(negedge clk);
		$finish;			
	end	
end


initial begin
  pat_read  = $fopen("../00_TESTBED/input_huff.txt", "r");
  out_read = $fopen("../00_TESTBED/output_huff.txt", "r");

  reset_task;
    for (i_pat = 0; i_pat < `PAT_NUM; i_pat = i_pat+1)
  	  begin
  		input_task;
        wait_out_valid_task;
        check_ans_task;
        $display("%0sPASS PATTERN NO.%4d, %0sCycles: %3d%0s",txt_blue_prefix, i_pat, txt_green_prefix, latency, reset_color);
        //$display("PASS PATTERN NO.%4d", i_pat);
      end
    $fclose(pat_read);
    $fclose(out_read);
    YOU_PASS_task;
end

task reset_task; begin 
    rst_n = 'b1;
    in_valid = 'b0;
    in_weight = 'bx;
    out_mode = 'bx;
    total_latency = 0;

    force clk = 0;

    #CYCLE; rst_n = 0; 
    #CYCLE; rst_n = 1;
    
    if(out_valid !== 1'b0 || out_code !== 'b0) begin //out!==0
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                   FAIL!                                                            ");
        $display ("                                          Output signal should be 0 after initial RESET  at %8t                                     ",$time);
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
        repeat(2) #CYCLE;
        $finish;
    end
	#CYCLE; release clk;
end endtask


task input_task; begin
    t = $urandom_range(2, 4);
	repeat(t) @(negedge clk);

    in_valid = 1'b1;
    a = $fscanf(pat_read, "%h ", mode_read);
    out_mode = mode_read;
    a = $fscanf(pat_read, "%h ", in_weight_read);
    in_weight = in_weight_read;
    for(i=1; i < 8; i = i+1)begin
        @(negedge clk);
        out_mode = 'bx;
        a = $fscanf(pat_read, "%h ", in_weight_read);
        in_weight = in_weight_read;
    end
    @(negedge clk);
    in_valid = 1'b0;	
	in_weight = 'bx;
    out_mode = 'bx;
end endtask 

task wait_out_valid_task; begin
    latency = 0;
    while(out_valid !== 1'b1) begin
	    latency = latency + 1;
        if( latency == 2000) begin
            $display ("------------------------------------------------------------------------------------------------------------------------------------");
	        $display ("                                                                   FAIL!                                                            ");
            $display ("                                            The execution latency are over 2000 cycles  at %8t                                      ",$time);
            $display ("------------------------------------------------------------------------------------------------------------------------------------");
	        repeat(2)@(negedge clk);
	        $finish;
        end
    @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
    
    a = $fscanf(out_read, "%h", golden_bitnum);
    a = $fscanf(out_read, "%b", golden);
    out_save = 'd0;
    for(i=0; i < golden_bitnum; i=i+1)begin
        if(out_valid == 0)begin
            $display ("-----------------------------------------------------------------------------------------------------------------------------------");
		    $display ("                                                                  FAIL!                                                            ");
            $display ("                                             output signal must be delivered for %d cycle                                    ",golden_bitnum);
		    $display ("-----------------------------------------------------------------------------------------------------------------------------------");
		    repeat(9)@(negedge clk);
            $finish;
        end
        out_save = {out_save[30:0], out_code};
        @(negedge clk);
    end
    if(out_save !== golden)begin
	    $display ("------------------------------------------------------------------------------------------------------------------------------------");
	    $display ("                                                                   FAIL!                                                               ");
	    $display ("                                                              Golden ans :    %b                                           ",golden); 
	    $display ("                                                              Your ans :      %b                                              ",out_save);
	    $display ("------------------------------------------------------------------------------------------------------------------------------------");
	    repeat(9)@(negedge clk);
        $finish;		
	end
    if(out_valid == 1)begin
        $display ("-----------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                  FAIL!                                                            ");
        $display ("                                             output signal must be delivered for %d cycle                                    ",golden_bitnum);
		$display ("-----------------------------------------------------------------------------------------------------------------------------------");
		repeat(9)@(negedge clk);
        $finish;
    end
end endtask

task YOU_PASS_task; begin
    $display ("----------------------------------------------------------------------------------------------------------------------");
    $display ("                                                  Congratulations!                                                                       ");
    $display ("                                           You have passed all patterns!                                                                 ");
    $display ("                                           Your execution cycles = %5d cycles                                                            ", total_latency);
    $display ("                                           Your clock period = %.1f ns                                                               ", CYCLE);
    $display ("                                           Total Latency = %.1f ns                                                               ", total_latency*CYCLE);
    $display ("----------------------------------------------------------------------------------------------------------------------");     
    repeat(2)@(negedge clk);
    $finish;
end endtask

endmodule