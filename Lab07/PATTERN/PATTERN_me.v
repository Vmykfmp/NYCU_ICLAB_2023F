`ifdef RTL
	`define CYCLE_TIME_clk1 14.1
	`define CYCLE_TIME_clk2 3.9
	`define CYCLE_TIME_clk3 20.7
`endif
`ifdef GATE
	`define CYCLE_TIME_clk1 14.1
	`define CYCLE_TIME_clk2 3.9
	`define CYCLE_TIME_clk3 20.7
`endif

module PATTERN(
	clk1,
	clk2,
	clk3,
	rst_n,
	in_valid,
	seed,
	out_valid,
	rand_num
);

output reg clk1, clk2, clk3;
output reg rst_n;
output reg in_valid;
output reg [31:0] seed;

input out_valid;
input [31:0] rand_num;


//================================================================
// parameters & integer
//================================================================
real	CYCLE_clk1 = `CYCLE_TIME_clk1;
real	CYCLE_clk2 = `CYCLE_TIME_clk2;
real	CYCLE_clk3 = `CYCLE_TIME_clk3;
integer total_latency;
integer exe_latency;
integer i_pat;

parameter PAT_NUM = 1;
parameter CYCLE = `CYCLE_TIME_clk1;
parameter DELAY = 100;

reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_black_prefix  = "\033[1;30m";
reg[10*8:1] txt_red_prefix    = "\033[1;31m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_yellow_prefix = "\033[1;33m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";

reg[10*8:1] bkg_black_prefix  = "\033[40;1m";
reg[10*8:1] bkg_red_prefix    = "\033[41;1m";
reg[10*8:1] bkg_green_prefix  = "\033[42;1m";
reg[10*8:1] bkg_yellow_prefix = "\033[43;1m";
reg[10*8:1] bkg_blue_prefix   = "\033[44;1m";
reg[10*8:1] bkg_white_prefix  = "\033[47;1m";
//================================================================
// wire & registers 
//================================================================
reg [31:0]  seed_dat;

//================================================================
// clock
//================================================================
initial clk1 = 1'b0;
always #(CYCLE_clk1/2.0) clk1 = ~clk1;

initial clk2 = 1'b0;
always #(CYCLE_clk2/2.0) clk2 = ~clk2;

initial clk3 = 1'b0;
always #(CYCLE_clk3/2.0) clk3 = ~clk3;
//================================================================
// initial
//================================================================

initial begin
    // pat_read = $fopen("../00_TESTBED/Input.txt", "r");
    reset_signal_task;

    i_pat = 0;
    // total_latency = 0;
    // $fscanf(pat_read, "%d", PAT_NUM);
    for (i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1) begin
        input_task;
        // generate_ans_task;

        wait_out_valid_task;
        // check_ans_task;

        // total_latency = total_latency + latency;
        $display("%0sPASS PATTERN NO.%4d Cycles: %3d%0s",txt_blue_prefix, i_pat, exe_latency + 1, reset_color);
    end
    // $fclose(pat_read);
    YOU_PASS_task;
end

//================================================================
// task
//================================================================
task reset_signal_task; begin
    rst_n = 'b1;
    in_valid = 'b0;	
	seed = 'bx;

    force clk1 = 0;
	force clk2 = 0;
	force clk3 = 0;
    #CYCLE_clk1; rst_n = 0;
    #CYCLE_clk1; rst_n = 1;

    if(out_valid !== 'b0 || rand_num !== 'b0) begin //out!==0
        $display("==========================================================================");
        $display("    Output signal should be low after reset at %-12d ps  ", $time*1000);
        $display("==========================================================================");
        repeat(2) #(CYCLE_clk1);
        $finish;
    end
    #CYCLE_clk1; 
	release clk1;
	release clk2;
	release clk3;
end endtask


task input_task; begin
    // a = $fscanf(pat_read, "%d ", in_weight_dat);
	seed_dat = 32'd857;

    @(negedge clk1);
	seed = seed_dat;
	in_valid = 1'b1;
	
	@(negedge clk1);
	seed = 'b0;
    in_valid = 1'b0;
    
	@(negedge clk1);
end endtask

task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles          *", total_latency);
    $display("*                Your clock period = %.1f ns          *", CYCLE_clk3);
    $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE_clk3);
    $display("*************************************************************************");
    $finish;
end endtask

task wait_out_valid_task; begin
    exe_latency = 0;
    while(out_valid !== 1'b1) begin
	    exe_latency = exe_latency + 1;
        if( exe_latency == DELAY) begin
            $display("==========================================================================");
            $display("    The execution latency at %-12d ps is over %5d cycles  ", $time*1000, DELAY);
            $display("==========================================================================");
            repeat(2) @(negedge clk2);
            $finish; 
        end
        @(negedge clk2);
   end
end endtask


endmodule
