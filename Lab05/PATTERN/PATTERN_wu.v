//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: CAD
//   Author     		: Cheng-Tsang Wu
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : V1.0 (Release Date: 2023-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL
    `timescale 1ns/10ps
    `define CYCLE_TIME 20.0
`endif
`ifdef GATE
    `timescale 1ns/10ps
    `define CYCLE_TIME 20.0
`endif

`define MATRIX_FILE "../00_TESTBED/matrix_8.dat"
`define OPTION_FILE "../00_TESTBED/opt_8.dat"
`define GOLDEN_FILE "../00_TESTBED/golden_8.dat"

module PATTERN(
    clk,
    rst_n,
    in_valid,
    in_valid2,
    matrix_size,
    matrix,
    matrix_idx,
    mode,
    out_valid,
    out_value
);

//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------
output reg         clk, rst_n, in_valid, in_valid2;
output reg  [1:0]  matrix_size;
output reg  [7:0]  matrix;
output reg  [3:0]  matrix_idx;
output reg         mode;
input              out_valid;
input              out_value;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
integer size0_duration = 1424;
integer size1_duration = 4496;
integer size2_duration = 16784;
integer duration;
integer f_matrix, f_option, f_golden;
integer matrix_fin, matrix_size_fin, mode_fin, matrix_idx_fin, golden_fin;
integer latency, total_latency;
integer a, i, j, pat;

reg         [19:0]  golden_ans;
reg                 current_bit;
//---------------------------------------------------------------------
//   MAIN PATTERN
//---------------------------------------------------------------------
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

initial begin
    f_matrix = $fopen(`MATRIX_FILE, "r");
    f_option = $fopen(`OPTION_FILE, "r");
    f_golden = $fopen(`GOLDEN_FILE, "r");

    reset_signal_task;
    for (pat = 0; pat < 1; pat = pat + 1) begin
        input_task;
        for (i = 0; i < 16; i = i + 1) begin
            input_task2;
            wait_out_valid_task;
            check_ans_task;
        end
        $display("\033[94mPASS PATTERN NO.%3d\033[39m", pat);
    end

end

//---------------------------------------------------------------------
//   TASKS
//---------------------------------------------------------------------
task reset_signal_task; begin
    rst_n       = 'b1;
    in_valid    = 'b0;
    in_valid2   = 'b0;
    matrix      = 'bx;
    matrix_size = 'bx;
    matrix_idx  = 'bx;
    mode        = 'bx;
    total_latency = 0;

    force clk = 0;

    #CYCLE; rst_n = 'b0;
    #CYCLE; rst_n = 'b1;

    if (out_valid !== 'b0 || out_value !== 'b0) begin
        OUTPUT_NOT_RESET_MSG;
    end

    #CYCLE; release clk;
end endtask

task input_task; begin
    @(negedge clk);

    a = $fscanf(f_matrix, "%d ", matrix_size_fin);
    a = $fscanf(f_matrix, "%b ", matrix_fin);
    in_valid = 'b1;
    matrix      = matrix_fin;
    matrix_size = matrix_size_fin;
    if (out_valid !== 'b0) begin
        OUT_VALID_OVERLAP_MSG;
    end

    case(matrix_size_fin)
        0: duration = size0_duration;
        1: duration = size1_duration;
        2: duration = size2_duration;
    endcase

    for (i = 1; i < duration; i = i + 1) begin
        @(negedge clk);
        a = $fscanf(f_matrix, "%b ", matrix_fin);
        in_valid    = 'b1;
        matrix      = matrix_fin;
        matrix_size = 'bx;
        if (out_valid !== 'b0) begin
            OUT_VALID_OVERLAP_MSG;
        end
    end

    @(negedge clk);
    in_valid    = 'b0;
    matrix      = 'bx;
    matrix_size = 'bx;

end endtask

task input_task2; begin
    repeat( $urandom_range(1, 3) ) @(negedge clk);

    a = $fscanf(f_option, "%d ", mode_fin);
    a = $fscanf(f_option, "%d ", matrix_idx_fin);

    in_valid2  = 'b1;
    matrix_idx = matrix_idx_fin;
    mode       = mode_fin;
    if (out_valid !== 'b0) begin
        OUT_VALID_OVERLAP2_MSG;
    end
    @(negedge clk);

    a = $fscanf(f_option, "%d ", matrix_idx_fin);
    matrix_idx = matrix_idx_fin;
    mode       = 'bx;
    if (out_valid !== 'b0) begin
        OUT_VALID_OVERLAP2_MSG;
    end
    @(negedge clk);

    in_valid2  = 'b0;
    matrix_idx = 'bx;
    mode       = 'bx;

end endtask

task wait_out_valid_task; begin
    latency = 0;
    while (out_valid !== 'b1) begin
        latency = latency + 1;

        if (out_value !== 'd0) begin
            OUT_NOT_ASSERTED_MSG;
        end
        if (latency == 100000) begin
            LATENCY_LIMIT_EXCEED_MSG;
        end
        @(negedge clk);
    end

end endtask

task check_ans_task; begin
    // Unit: data(20-bit)
    case({mode_fin, matrix_size_fin})
        {32'd0,32'd0}: duration = 4;    // 2*2
        {32'd0,32'd1}: duration = 36;   // 6*6
        {32'd0,32'd2}: duration = 196;  // 14*14
        {32'd1,32'd0}: duration = 144;  // 12*12
        {32'd1,32'd1}: duration = 400;  // 20*20
        {32'd1,32'd2}: duration = 1296; // 36*36
    endcase

    @(negedge clk);

    for (i = 0; i < duration; i = i + 1) begin
        a = $fscanf(f_golden, "%b", golden_fin);
        golden_ans = golden_fin;
        for (j = 0; j < 20; j = j + 1) begin
            current_bit = golden_ans[19-j];
            if (out_value !== current_bit) begin
                PAT_FAIL_MSG;
            end
            @(negedge clk);
        end
    end

end endtask

//---------------------------------------------------------------------
//   MESSAGE DISPLAY TASKS
//---------------------------------------------------------------------
task OUTPUT_NOT_RESET_MSG; begin
    $display();
    $display("\033[31m");
    $display("***********************************************************************");
    $display(" All output signals should be reset after the reset signal is asserted.");
    $display(" out_valid = %8d                                               ", out_valid);
    $display(" out_value = %8d                                               ", out_value);
    $display("***********************************************************************");
    $display("\033[39m");
    $finish;
end endtask

task OUT_NOT_ASSERTED_MSG; begin
    $display();
    $display("\033[31m");
    $display("***********************************************************************");
    $display(" The out should be reset when your out_valid is low.                   ");
    $display(" out_valid = %8d                                               ", out_valid);
    $display(" out_value = %8d                                               ", out_value);
    $display("***********************************************************************");
    $display("\033[39m");
    $finish;
end endtask

task LATENCY_LIMIT_EXCEED_MSG; begin
    $display();
    $display("\033[31m");
    $display("**************************************************");
    $display(" The execution latency is limited in 100000 cycles. ");
    $display("**************************************************");
    $display("\033[39m");
    $finish;
end endtask

task OUT_VALID_OVERLAP_MSG; begin
    $display();
    $display("\033[31m");
    $display("************************************************");
    $display(" Detect in_valid and out_valid overlapped!!");
    $display("************************************************");
    $display("\033[39m");
    $finish;
end endtask

task OUT_VALID_OVERLAP2_MSG; begin
    $display();
    $display("\033[31m");
    $display("************************************************");
    $display(" Detect in_valid2 and out_valid overlapped!!");
    $display("************************************************");
    $display("\033[39m");
    $finish;
end endtask

task PAT_FAIL_MSG; begin
    $display();
    $display("\033[31m");
    $display("*****************************************************");
    $display(" PATTERN NO.%3d ",pat);
    $display(" Expected out = %b ",current_bit);
    $display("     Your out = %b ",out_value);
    $display("*****************************************************");
    $display("\033[39m");
    $finish;
end endtask
endmodule