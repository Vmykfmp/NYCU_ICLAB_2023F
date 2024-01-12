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

`define PAT_NUM 1000
`define SEED_FILE    "../00_TESTBED/seed.txt"
`define GOLDEN_FILE  "../00_TESTBED/golden.txt"

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
integer PATNUM = `PAT_NUM;
integer f_seed, f_golden, pat;
integer total_latency, latency;
integer out_valid_cnt;
integer a, t;

//================================================================
// wire & reg
//================================================================
reg [31:0] fin_seed;
reg [31:0] fin_golden;

//================================================================
// clock
//================================================================
initial clk1 = 'b0;
always #(CYCLE_clk1/2.0) clk1 = ~clk1;
initial clk2 = 'b0;
always #(CYCLE_clk2/2.0) clk2 = ~clk2;
initial clk3 = 'b0;
always #(CYCLE_clk3/2.0) clk3 = ~clk3;

//================================================================
// initial
//================================================================
initial begin
	f_seed   = $fopen(`SEED_FILE, "r");
	f_golden = $fopen(`GOLDEN_FILE, "r");
    reset_signal_task;

    for (pat = 1; pat <= PATNUM; pat = pat + 1) begin
        input_task;
        check_ans_task;
        total_latency = total_latency + latency;
        $display("PASS PATTERN NO.%4d", pat);
    end
	YOU_PASS_task;

	$fclose(f_seed);
	$fclose(f_golden);
end

//================================================================
// task
//================================================================
task reset_signal_task; begin
	rst_n       = 'b1;
    in_valid    = 'b0;
    seed        = 'bx;

    total_latency = 0;



    force clk1 = 0;
    force clk2 = 0;
    force clk3 = 0;

    #CYCLE_clk1; rst_n = 'b0;
    #CYCLE_clk1; rst_n = 'b1;

    if (out_valid !== 'b0 || rand_num !== 'b0) begin
        OUTPUT_NOT_RESET_MSG;
    end

    #CYCLE_clk1;
	release clk1;
	release clk2;
	release clk3;
end endtask


task input_task; begin
    t = $urandom_range(1, 3);
	repeat(t) @(negedge clk1);

    a = $fscanf(f_seed, "%h", fin_seed);
    in_valid = 'b1;
    seed = fin_seed;

    @(negedge clk1);
    in_valid = 'b0;
    seed     = 'b0;

end endtask


task check_ans_task; begin
    out_valid_cnt = 0;
    latency = 0;

    while (out_valid_cnt <= 256) begin
        @(negedge clk3);
        if (latency > 2000) begin
            LATENCY_LIMIT_EXCEED_MSG;
        end

        if (out_valid === 'b1) begin
            out_valid_cnt = out_valid_cnt + 1;

            a = $fscanf(f_golden, "%h", fin_golden);
            if (fin_golden !== rand_num) begin
                PAT_FAIL_MSG;
            end
        end
        else begin
            if (rand_num !== 'b0) begin
                OUT_NOT_ASSERTED_MSG;
            end
        end
        latency = latency + 1;
    end
    total_latency = total_latency + latency;
end endtask




//---------------------------------------------------------------------
//   MESSAGE DISPLAY TASKS
//---------------------------------------------------------------------
task OUTPUT_NOT_RESET_MSG; begin
    $display();
    $display("\033[31m");
    $display("*************************************************************************");
    $display(" All output signals should be reset after the reset signal is asserted.");
    $display(" out_valid = %8d                                               ", out_valid);
    $display(" rand_num  = %8d                                               ", rand_num);
    $display("*************************************************************************");
    $display("\033[39m");
    $finish;
end endtask

task OUT_NOT_ASSERTED_MSG; begin
    $display();
    $display("\033[31m");
    $display("*************************************************************************");
    $display(" Rand_num should be 0 when your out_valid is low at: %10d ps               ", $time);
    $display(" rand_num  = %8d                                               ", rand_num);
    $display("*************************************************************************");
    $display("\033[39m");
    $finish;
end endtask

task LATENCY_LIMIT_EXCEED_MSG; begin
    $display();
    $display("\033[31m");
    $display("**************************************************");
    $display(" The execution latency is limited in 2000 cycles. ");
    $display("**************************************************");
    $display("\033[39m");
    $finish;
end endtask


task PAT_FAIL_MSG; begin
    $display();
    $display("\033[31m");
    $display("*******************************************************");
    $display(" PATTERN NO.%3d ",pat);
    $display(" Expected out = %b ",fin_golden);
    $display("     Your out = %b ",rand_num);
    $display("*******************************************************");
    $display("\033[39m");
    $finish;
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
endmodule
