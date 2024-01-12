/*
============================================================================

Date   : 2023/11/09
Author : EECS Lab

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

TODO:

============================================================================
*/

`ifdef RTL
	`define CYCLE_TIME_clk1 14.1
	`define CYCLE_TIME_clk2 3.9
    `define CYCLE_TIME_clk3 20.7
	// `define CYCLE_TIME_clk3 20.7
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

//======================================
//      PARAMETERS & VARIABLES
//======================================
// User modification
parameter PATNUM            = 30;
parameter SIMPLE_PATNUM     = 10;
integer   SEED              = 587;
// PATTERN operation
parameter CYCLE1            = `CYCLE_TIME_clk1;
parameter CYCLE2            = `CYCLE_TIME_clk2;
parameter CYCLE3            = `CYCLE_TIME_clk3;
parameter DELAY             = 2000;
parameter MAX_INPUT_DELAY   = 3;
parameter OUTPUT_PER_PAT    = 256;

// PATTERN CONTROL
integer       i;
integer       j;
integer       k;
integer       m;
integer    stop;
integer     pat;
integer exe_lat;
integer out_lat;
integer out_check_idx;
integer tot_lat;
integer input_delay;
integer each_delay;

// FILE CONTROL
integer file;
integer file_out;

// String control
// Should use %0s
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
//      DATA MODEL
//======================================
parameter SHIFT_PARAM_A = 13;
parameter SHIFT_PARAM_B = 17;
parameter SHIFT_PARAM_C = 5;
parameter SIMPLE_SEED   = 2**(SHIFT_PARAM_B - SHIFT_PARAM_A);
reg unsigned [31:0] _seed;
reg unsigned [31:0] _inputNums[1:OUTPUT_PER_PAT];
reg unsigned [31:0] _shiftNums1[1:OUTPUT_PER_PAT];
reg unsigned [31:0] _shiftNums2[1:OUTPUT_PER_PAT];
reg unsigned [31:0] _shiftNums3[1:OUTPUT_PER_PAT];
reg unsigned [31:0] _outputNums[1:OUTPUT_PER_PAT];

task _clearModel;
    integer _idx;
begin
    _seed = 'dx;
    for(_idx=1 ; _idx<=OUTPUT_PER_PAT ; _idx=_idx+1) begin
        _inputNums [_idx] = 'dx;
        _shiftNums1[_idx] = 'dx;
        _shiftNums2[_idx] = 'dx;
        _shiftNums3[_idx] = 'dx;
        _outputNums[_idx] = 'dx;
    end
end endtask

task _randSeed;
    input integer _pat;
begin
    if(_pat < SIMPLE_PATNUM) _seed = {$random(SEED)} % SIMPLE_SEED;
    else _seed = {$random(SEED)};
end endtask

task _runRandom;
    integer _idx;
begin
    _inputNums [1] = _seed;
    _shiftNums1[1] = _inputNums [1] ^ (_inputNums [1] << SHIFT_PARAM_A);
    _shiftNums2[1] = _shiftNums1[1] ^ (_shiftNums1[1] >> SHIFT_PARAM_B);
    _shiftNums3[1] = _shiftNums2[1] ^ (_shiftNums2[1] << SHIFT_PARAM_C);
    _outputNums[1] = _shiftNums3[1];
    for(_idx=2 ; _idx<=OUTPUT_PER_PAT ; _idx=_idx+1) begin
        _inputNums [_idx] = _outputNums[_idx-1];
        _shiftNums1[_idx] = _inputNums [_idx] ^ (_inputNums [_idx] << SHIFT_PARAM_A);
        _shiftNums2[_idx] = _shiftNums1[_idx] ^ (_shiftNums1[_idx] >> SHIFT_PARAM_B);
        _shiftNums3[_idx] = _shiftNums2[_idx] ^ (_shiftNums2[_idx] << SHIFT_PARAM_C);
        _outputNums[_idx] = _shiftNums3[_idx];
    end
end endtask

task _displayOutput;
    input integer _pat;
    input integer _idx;
begin
    $display("[ Pat  ] : No.%-1d \n", pat);
    $display("[ Seed ] : %10d / %8h \n", _seed, _seed);
    if(_idx > 1) begin
        $display("[ Previous output ] %10d / %8h\n", _outputNums[_idx-1], _outputNums[_idx-1]);
    end
    $display("[ Idx %3d ]\n", _idx);
    $display("    *1. : %10d / %8h",   _inputNums [_idx], _inputNums [_idx]);
    $display("    *2. : %10d / %8h",   _shiftNums1[_idx], _shiftNums1[_idx]);
    $display("    *3. : %10d / %8h",   _shiftNums2[_idx], _shiftNums2[_idx]);
    $display("    *4. : %10d / %8h",   _shiftNums3[_idx], _shiftNums3[_idx]);
    $display("    *5. : %10d / %8h\n", _outputNums[_idx], _outputNums[_idx]);
end endtask

task _dumpResult;
    input integer isHex;
    integer _idx;
begin
    if(isHex) begin
        file_out = $fopen("rng_result_hex.txt", "w");
        $fwrite(file_out, "[ Pat  ] : No.%-1d \n\n", pat);
        $fwrite(file_out, "[ Seed ] : %8h \n\n", _seed);
    end
    else begin
        file_out = $fopen("rng_result_dec.txt", "w");
        $fwrite(file_out, "[ Pat  ] : Np.%-1d \n\n", pat);
        $fwrite(file_out, "[ Seed ] : %10d \n\n", _seed);
    end

    for(_idx=1 ; _idx<=OUTPUT_PER_PAT ; _idx=_idx+1) begin
        $fwrite(file_out, "[ Idx %3d ]\n", _idx);
        if(isHex) begin
            $fwrite(file_out, "    *1. : %8h\n", _inputNums [_idx]);
            $fwrite(file_out, "    *2. : %8h\n", _shiftNums1[_idx]);
            $fwrite(file_out, "    *3. : %8h\n", _shiftNums2[_idx]);
            $fwrite(file_out, "    *4. : %8h\n", _shiftNums3[_idx]);
            $fwrite(file_out, "    *5. : %8h\n\n", _outputNums[_idx]);
        end
        else begin
            $fwrite(file_out, "    *1. : %10d\n", _inputNums [_idx]);
            $fwrite(file_out, "    *2. : %10d\n", _shiftNums1[_idx]);
            $fwrite(file_out, "    *3. : %10d\n", _shiftNums2[_idx]);
            $fwrite(file_out, "    *4. : %10d\n", _shiftNums3[_idx]);
            $fwrite(file_out, "    *5. : %10d\n\n", _outputNums[_idx]);
        end
    end

    $fclose(file_out);
end endtask


//======================================
//              MAIN
//======================================
initial exe_task;

//======================================
//              Clock
//======================================
initial clk1 = 0;
always #(CYCLE1/2.0) clk1 = ~clk1;

initial clk2 = 0;
always #(CYCLE2/2.0) clk2 = ~clk2;

initial clk3 = 0;
always #(CYCLE3/2.0) clk3 = ~clk3;

//======================================
//              TASKS
//======================================
task exe_task; begin
    reset_task;
    for (pat=0 ; pat<PATNUM ; pat=pat+1) begin
        input_task;
        cal_task;
        wait_task;
        check_task;
        // Print Pass Info and accumulate the total latency
        $display("%0sPASS PATTERN NO.%4d, %0sCycles: %4d%0s",txt_blue_prefix, pat, txt_green_prefix, exe_lat, reset_color);
    end
    pass_task;
end endtask

//**************************************
//      Reset Task
//**************************************
task reset_task; begin

    force clk1 = 0;
    force clk2 = 0;
    force clk3 = 0;
    rst_n = 1;
    in_valid = 0;
    seed = 'dx;

    tot_lat = 0;

    #(CYCLE1/2.0) rst_n = 0;
    #(CYCLE1/2.0) rst_n = 1;
    if (out_valid !== 0 || rand_num !== 0) begin
        $display("==========================================================================");
        $display("    Output signal should be 0 at %-12d ps  ", $time*1000);
        $display("==========================================================================");
        repeat(5) #(CYCLE1);
        $finish;
    end

    #(CYCLE1/2.0);
    release clk1;
    release clk2;
    release clk3;
end endtask

//**************************************
//      Input Task
//**************************************
task input_task; begin
    repeat(({$random(SEED)} % 3 + 1)) @(negedge clk1);
    _randSeed(pat);
    in_valid = 1;
    seed = _seed;
    @(negedge clk1);
    in_valid = 0;
    seed = 'bx;
end endtask

//**************************************
//      Wait Task
//**************************************
task wait_task; begin
    exe_lat = -1;
    while (out_valid !== 1) begin
        if (rand_num !== 0) begin
            $display("==========================================================================");
            $display("    Output signal should be 0 at %-12d ps  ", $time*1000);
            $display("==========================================================================");
            repeat(5) @(negedge clk3);
            $finish;
        end
        if (exe_lat == DELAY) begin
            $display("==========================================================================");
            $display("    The execution latency at %-12d ps is over %5d cycles  ", $time*1000, DELAY);
            $display("==========================================================================");
            repeat(5) @(negedge clk3);
            $finish; 
        end
        exe_lat = exe_lat + 1;
        @(negedge clk3);
    end
end endtask

//**************************************
//      Calculate Task
//**************************************
task cal_task; begin
    _runRandom;
    _dumpResult(1); // hex
    _dumpResult(0); // dec
end endtask

//**************************************
//      Check Task
//**************************************
task check_task;
    integer _idx;
begin
    _idx = 1;
    while(_idx<=OUTPUT_PER_PAT) begin
        if (exe_lat===DELAY) begin
            $display("==========================================================================");
            $display("    The execution latency at %-12d ps is over %5d cycles  ", $time*1000, DELAY);
            $display("==========================================================================");
            repeat(5) @(negedge clk3);
            $finish;
        end
        if (out_valid===1) begin
            if(rand_num!==_outputNums[_idx]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("==========================================================================");
                repeat(5) @(negedge clk3);
                _displayOutput(pat, _idx);
                $finish;
            end
            _idx = _idx + 1;
        end
        exe_lat = exe_lat + 1;
        @(negedge clk3);
    end
    if (out_valid===1) begin
        $display("==========================================================================");
        $display("    Output is over %3d at %-12d ps", OUTPUT_PER_PAT, $time*1000);
        $display("==========================================================================");
        repeat(5) @(negedge clk3);
        $finish;
    end
    tot_lat = tot_lat + exe_lat;
end endtask

//**************************************
//      PASS Task
//**************************************
task pass_task; begin
    $display("\033[1;33m                `oo+oy+`                            \033[1;35m Congratulation!!! \033[1;0m                                   ");
    $display("\033[1;33m               /h/----+y        `+++++:             \033[1;35m PASS This Lab........Maybe \033[1;0m                          ");
    $display("\033[1;33m             .y------:m/+ydoo+:y:---:+o             \033[1;35m Total Latency : %-10d\033[1;0m                                ", tot_lat);
    $display("\033[1;33m              o+------/y--::::::+oso+:/y                                                                                     ");
    $display("\033[1;33m              s/-----:/:----------:+ooy+-                                                                                    ");
    $display("\033[1;33m             /o----------------/yhyo/::/o+/:-.`                                                                              ");
    $display("\033[1;33m            `ys----------------:::--------:::+yyo+                                                                           ");
    $display("\033[1;33m            .d/:-------------------:--------/--/hos/                                                                         ");
    $display("\033[1;33m            y/-------------------::ds------:s:/-:sy-                                                                         ");
    $display("\033[1;33m           +y--------------------::os:-----:ssm/o+`                                                                          ");
    $display("\033[1;33m          `d:-----------------------:-----/+o++yNNmms                                                                        ");
    $display("\033[1;33m           /y-----------------------------------hMMMMN.                                                                      ");
    $display("\033[1;33m           o+---------------------://:----------:odmdy/+.                                                                    ");
    $display("\033[1;33m           o+---------------------::y:------------::+o-/h                                                                    ");
    $display("\033[1;33m           :y-----------------------+s:------------/h:-:d                                                                    ");
    $display("\033[1;33m           `m/-----------------------+y/---------:oy:--/y                                                                    ");
    $display("\033[1;33m            /h------------------------:os++/:::/+o/:--:h-                                                                    ");
    $display("\033[1;33m         `:+ym--------------------------://++++o/:---:h/                                                                     ");
    $display("\033[1;31m        `hhhhhoooo++oo+/:\033[1;33m--------------------:oo----\033[1;31m+dd+                                                 ");
    $display("\033[1;31m         shyyyhhhhhhhhhhhso/:\033[1;33m---------------:+/---\033[1;31m/ydyyhs:`                                              ");
    $display("\033[1;31m         .mhyyyyyyhhhdddhhhhhs+:\033[1;33m----------------\033[1;31m:sdmhyyyyyyo:                                            ");
    $display("\033[1;31m        `hhdhhyyyyhhhhhddddhyyyyyo++/:\033[1;33m--------\033[1;31m:odmyhmhhyyyyhy                                            ");
    $display("\033[1;31m        -dyyhhyyyyyyhdhyhhddhhyyyyyhhhs+/::\033[1;33m-\033[1;31m:ohdmhdhhhdmdhdmy:                                           ");
    $display("\033[1;31m         hhdhyyyyyyyyyddyyyyhdddhhyyyyyhhhyyhdhdyyhyys+ossyhssy:-`                                                           ");
    $display("\033[1;31m         `Ndyyyyyyyyyyymdyyyyyyyhddddhhhyhhhhhhhhy+/:\033[1;33m-------::/+o++++-`                                            ");
    $display("\033[1;31m          dyyyyyyyyyyyyhNyydyyyyyyyyyyhhhhyyhhy+/\033[1;33m------------------:/ooo:`                                         ");
    $display("\033[1;31m         :myyyyyyyyyyyyyNyhmhhhyyyyyhdhyyyhho/\033[1;33m-------------------------:+o/`                                       ");
    $display("\033[1;31m        /dyyyyyyyyyyyyyyddmmhyyyyyyhhyyyhh+:\033[1;33m-----------------------------:+s-                                      ");
    $display("\033[1;31m      +dyyyyyyyyyyyyyyydmyyyyyyyyyyyyyds:\033[1;33m---------------------------------:s+                                      ");
    $display("\033[1;31m      -ddhhyyyyyyyyyyyyyddyyyyyyyyyyyhd+\033[1;33m------------------------------------:oo              `-++o+:.`             ");
    $display("\033[1;31m       `/dhshdhyyyyyyyyyhdyyyyyyyyyydh:\033[1;33m---------------------------------------s/            -o/://:/+s             ");
    $display("\033[1;31m         os-:/oyhhhhyyyydhyyyyyyyyyds:\033[1;33m----------------------------------------:h:--.`      `y:------+os            ");
    $display("\033[1;33m         h+-----\033[1;31m:/+oosshdyyyyyyyyhds\033[1;33m-------------------------------------------+h//o+s+-.` :o-------s/y  ");
    $display("\033[1;33m         m:------------\033[1;31mdyyyyyyyyymo\033[1;33m--------------------------------------------oh----:://++oo------:s/d  ");
    $display("\033[1;33m        `N/-----------+\033[1;31mmyyyyyyyydo\033[1;33m---------------------------------------------sy---------:/s------+o/d  ");
    $display("\033[1;33m        .m-----------:d\033[1;31mhhyyyyyyd+\033[1;33m----------------------------------------------y+-----------+:-----oo/h  ");
    $display("\033[1;33m        +s-----------+N\033[1;31mhmyyyyhd/\033[1;33m----------------------------------------------:h:-----------::-----+o/m  ");
    $display("\033[1;33m        h/----------:d/\033[1;31mmmhyyhh:\033[1;33m-----------------------------------------------oo-------------------+o/h  ");
    $display("\033[1;33m       `y-----------so /\033[1;31mNhydh:\033[1;33m-----------------------------------------------/h:-------------------:soo  ");
    $display("\033[1;33m    `.:+o:---------+h   \033[1;31mmddhhh/:\033[1;33m---------------:/osssssoo+/::---------------+d+//++///::+++//::::::/y+`  ");
    $display("\033[1;33m   -s+/::/--------+d.   \033[1;31mohso+/+y/:\033[1;33m-----------:yo+/:-----:/oooo/:----------:+s//::-.....--:://////+/:`    ");
    $display("\033[1;33m   s/------------/y`           `/oo:--------:y/-------------:/oo+:------:/s:                                                 ");
    $display("\033[1;33m   o+:--------::++`              `:so/:-----s+-----------------:oy+:--:+s/``````                                             ");
    $display("\033[1;33m    :+o++///+oo/.                   .+o+::--os-------------------:oy+oo:`/o+++++o-                                           ");
    $display("\033[1;33m       .---.`                          -+oo/:yo:-------------------:oy-:h/:---:+oyo                                          ");
    $display("\033[1;33m                                          `:+omy/---------------------+h:----:y+//so                                         ");
    $display("\033[1;33m                                              `-ys:-------------------+s-----+s///om                                         ");
    $display("\033[1;33m                                                 -os+::---------------/y-----ho///om                                         ");
    $display("\033[1;33m                                                    -+oo//:-----------:h-----h+///+d                                         ");
    $display("\033[1;33m                                                       `-oyy+:---------s:----s/////y                                         ");
    $display("\033[1;33m                                                           `-/o+::-----:+----oo///+s                                         ");
    $display("\033[1;33m                                                               ./+o+::-------:y///s:                                         ");
    $display("\033[1;33m                                                                   ./+oo/-----oo/+h                                          ");
    $display("\033[1;33m                                                                       `://++++syo`                                          ");
    $display("\033[1;0m"); 
    repeat(5) @(negedge clk3);
    $finish;
end endtask

endmodule
