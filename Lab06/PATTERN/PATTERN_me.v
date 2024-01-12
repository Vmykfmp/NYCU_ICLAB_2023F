`ifdef RTL
    `define CYCLE_TIME 20.0
`endif
`ifdef GATE
    `define CYCLE_TIME 7.8
`endif

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
// User modification
parameter PAT_NUM = 2;
parameter CYCLE = `CYCLE_TIME;
parameter DELAY = 100;

reg [2:0]  in_weight_dat [0:7];
reg [16:0] golden_ans;
reg [16:0] your_ans;

integer latency;
integer exe_latency;
integer i_pat, a, i;

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

//======================================
//              Clock
//======================================
initial clk = 1'b0;
always #(CYCLE/2.0) clk = ~clk;

//================================================================
// design
//================================================================

initial begin
    // pat_read = $fopen("../00_TESTBED/Input.txt", "r");
    reset_signal_task;

    i_pat = 0;
    // total_latency = 0;
    // $fscanf(pat_read, "%d", PAT_NUM);
    for (i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1) begin
        input_task;
        generate_ans_task;

        wait_out_valid_task;
        check_ans_task;

        // total_latency = total_latency + latency;
        $display("%0sPASS PATTERN NO.%4d Cycles: %3d%0s",txt_blue_prefix, i_pat, exe_latency + 1, reset_color);
    end
    // $fclose(pat_read);
    YOU_PASS_task;
end

task reset_signal_task; begin
    rst_n = 'b1;
    in_valid = 'b0;
    out_mode = 'bx;		
	in_weight = 'bx;

    force clk = 0;
    #CYCLE; rst_n = 0;
    #CYCLE; rst_n = 1;

    if(out_valid !== 'b0 || out_code !== 'b0) begin //out!==0
        $display("==========================================================================");
        $display("    Output signal should be low after reset at %-12d ps  ", $time*1000);
        $display("==========================================================================");
        repeat(2) #(CYCLE);
        $finish;
    end
    #CYCLE; release clk;
end endtask

task input_task; begin
    // a = $fscanf(pat_read, "%d ", in_weight_dat);
    in_weight_dat[0] = 3'd3; // wight A
    in_weight_dat[1] = 3'd7; // wight B
    in_weight_dat[2] = 3'd6; // wight C
    in_weight_dat[3] = 3'd5; // wight E
    in_weight_dat[4] = 3'd3; // wight I
    in_weight_dat[5] = 3'd3; // wight L
    in_weight_dat[6] = 3'd5; // wight O
    in_weight_dat[7] = 3'd7; // wight V

    @(negedge clk);
	in_valid = 1'b1;
    for(i = 0; i < 8; i = i + 1) begin
        // if(i == 1) out_mode = out_mode_dat;   
        if(i == 0) out_mode = i_pat % 2;
        else       out_mode = 'bx; 
        in_weight = in_weight_dat[i];
        @(negedge clk);
    end
    in_valid = 1'b0;
    out_mode =  'bx;
    in_weight = 'bx;
    @(negedge clk);
end endtask

task generate_ans_task; begin
    // if(i_pat == 0) golden_ans = 17'b01000101100000011;
    // else           golden_ans = 17'b0100001010110111;
    if(i_pat == 0) golden_ans = 17'b11000000110100010;
    else           golden_ans = 17'b1110110101000010;
end endtask

task wait_out_valid_task; begin
    exe_latency = 0;
    while(out_valid !== 1'b1) begin
	    exe_latency = exe_latency + 1;
        if( exe_latency == DELAY) begin
            $display("==========================================================================");
            $display("    The execution latency at %-12d ps is over %5d cycles  ", $time*1000, DELAY);
            $display("==========================================================================");
            repeat(2) @(negedge clk);
            $finish; 
        end
        @(negedge clk);
   end
end endtask

task check_ans_task; begin
    latency = 0;
    your_ans = 'b0;
    while(out_valid === 1)begin
        // if(exe_latency == 0) your_ans[latency + 1] = out_code;
        // else                 your_ans[latency] = out_code;
        your_ans[latency] = out_code;
        latency = latency + 1;
        @(negedge clk);
        if(latency > 17) begin
            $display("==========================================================================");
            $display("    The ouput valid remain high overtime at %-12d ps ", $time*1000);
            $display("==========================================================================");
            repeat(2) @(negedge clk);
            $finish;
        end
	end	
    if(your_ans !== golden_ans)begin
        $display("%0sFAIL PATTERN NO.%4d%0s",txt_red_prefix, i_pat, reset_color);
        // $display ("       \033[0;31m FAIL! \033[0m       ");
        $display("==========================================================================");
        $display("    Out is not correct at %-12d ps ", $time*1000);
        // $display ("   your answer : %17b ", your_ans);
        $write("   your answer  : ");
        for(i = 0; i < latency; i = i + 1) $write("%1b", your_ans[i]);
        $display("");
        // $display (" golden answer : %17b ", {golden_ans});
        $write("  golden answer : ");
        for(i = 0; i < latency; i = i + 1) $write("%1b", golden_ans[i]);
        $display("");
        $display("==========================================================================");
        repeat(2) @(negedge clk);
        $finish;		
    end
end endtask

task YOU_PASS_task; begin
    $display("********************************************************************");
    $display("*                        \033[0;32m Congratulations! \033[0m                        *");
    $display("*                total %4d pattern are passed                     *", PAT_NUM);
    $display("********************************************************************");
    $finish;
end endtask
endmodule