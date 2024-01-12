`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 40.0
`endif

`include "../00_TESTBED/pseudo_DRAM.v"
`include "../00_TESTBED/pseudo_SD.v"

module PATTERN(
    // Input Signals
    clk,
    rst_n,
    in_valid,
    direction,
    addr_dram,
    addr_sd,
    // Output Signals
    out_valid,
    out_data,
    // DRAM Signals
    AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
    // SD Signals
    MISO,
    MOSI
);

/* Input for design */
output reg        clk, rst_n;
output reg        in_valid;
output reg        direction;
output reg [12:0] addr_dram;
output reg [15:0] addr_sd;

/* Output for pattern */
input        out_valid;
input  [7:0] out_data; 

// DRAM Signals
// write address channel
input [31:0] AW_ADDR;
input AW_VALID;
output AW_READY;
// write data channel
input W_VALID;
input [63:0] W_DATA;
output W_READY;
// write response channel
output B_VALID;
output [1:0] B_RESP;
input B_READY;
// read address channel
input [31:0] AR_ADDR;
input AR_VALID;
output AR_READY;
// read data channel
output [63:0] R_DATA;
output R_VALID;
output [1:0] R_RESP;
input R_READY;

// SD Signals
output MISO;
input MOSI;

real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;



integer pat_read;
integer PAT_NUM;
integer total_latency, latency;
integer bit_num;
// integer i_pat;
integer i_pat, a, i;
reg [7:0]  resp;
reg [63:0] check_data;

parameter SD_p_r = "../00_TESTBED/SD_init.dat";
reg [63:0] SD [0:65535];
initial $readmemh(SD_p_r, SD);

parameter DRAM_p_r = "../00_TESTBED/DRAM_init.dat";
reg [63:0] DRAM [0:8191];
initial $readmemh(DRAM_p_r, DRAM);

reg [63:0] moving_data;
reg [7:0]  golden_ans [0:7];
initial begin
    pat_read = $fopen("../00_TESTBED/Input.txt", "r");
    reset_signal_task;

    i_pat = 0;
    total_latency = 0;
    $fscanf(pat_read, "%d", PAT_NUM);
    for (i_pat = 1; i_pat <= 1; i_pat = i_pat + 1) begin
        input_task;
        generate_ans_task;

        wait_out_valid_task;
        check_ans_task;

        total_latency = total_latency + latency;
        // \033[32;42m Hello pass!\033[0m
        $display("\033[0;32m PASS PATTERN NO.%4d \033[0m", i_pat);
    end
    $fclose(pat_read);

    $writememh("../00_TESTBED/DRAM_final.dat", u_DRAM.DRAM);
    $writememh("../00_TESTBED/SD_final.dat", u_SD.SD);
    YOU_PASS_task;
end

always @(negedge clk) begin
    if(out_valid === 0 && out_data !== 0) begin
        $display("\nSPEC MAIN-2 FAIL\n");
        $finish;
    end
end

always @(negedge clk) begin
    if(R_VALID) begin
        check_data = R_DATA;
    end

    if(W_VALID) begin
        check_data = W_DATA;
    end
end

//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////
reg        direction_dat;
reg [12:0] addr_dram_dat;
reg [15:0] addr_sd_dat;

task reset_signal_task; begin
    rst_n = 'b1;
    in_valid = 'b0;
    direction = 'bx;		
	addr_dram = 'bx;
	addr_sd   = 'bx;
    total_latency = 0;

    force clk = 0;

    #CYCLE; rst_n = 0;
    #CYCLE; rst_n = 1;

    if(out_valid !== 'b0 || 
       out_data  !== 'b0 || 
       AW_ADDR   !== 'b0 ||
       AW_VALID  !== 'b0 ||
       W_VALID   !== 'b0 ||
       W_DATA    !== 'b0 ||
       B_READY   !== 'b0 ||
       AR_ADDR   !== 'b0 ||
       AR_VALID  !== 'b0 ||
       R_READY   !== 'b0 ||
       MOSI      !==  1'b1 ) begin //out!==0
        $display("\nSPEC MAIN-1 FAIL\n");
        repeat(1) #CYCLE;
        $finish;
    end
    #CYCLE; release clk;
end endtask

task output_valid_task; begin
    if(out_valid === 0 && out_data !== 0) begin
        $display("\nSPEC MAIN-2 FAIL\n");
        $finish;
    end
end endtask

task input_task; begin
    a = $fscanf(pat_read, "%d ", direction_dat);
    a = $fscanf(pat_read, "%d ", addr_dram_dat);
	a = $fscanf(pat_read, "%d ", addr_sd_dat);
    @(negedge clk);
	in_valid = 1'b1;
	direction = direction_dat;
	addr_dram = addr_dram_dat;
	addr_sd   = addr_sd_dat;
	
    // $display("\ndata unknown\n");
    // $finish;
end endtask

task generate_ans_task; begin
    if(!direction) begin
        moving_data = DRAM[addr_dram];
        SD[addr_sd] = moving_data;
    end
    else begin
        moving_data = SD[addr_sd];
        DRAM[addr_dram] = moving_data;
    end

    golden_ans[0] = moving_data[63:56];
    golden_ans[1] = moving_data[55:48];
    golden_ans[2] = moving_data[47:40];
    golden_ans[3] = moving_data[39:32];
    golden_ans[4] = moving_data[31:24];
    golden_ans[5] = moving_data[23:16];
    golden_ans[6] = moving_data[15:8];
    golden_ans[7] = moving_data[7:0];

    @(negedge clk);
    in_valid = 1'b0;
    direction = 'bx;
	addr_dram = 'bx;
	addr_sd   = 'bx;
end endtask

task wait_out_valid_task; begin
    latency = 0;
    // check_memory_state_task;
    while(out_valid !== 1'b1) begin
        // output_valid_task;

	    latency = latency + 1;
        if( latency == 10000) begin
                $display("\nSPEC MAIN-3 FAIL\n");
                // repeat(2)@(negedge clk);
                $finish;
        end
        
        @(negedge clk);
        if(out_valid === 1) check_memory_state_task;
   end
   total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
    latency = 0;
    bit_num = 0;
    resp = 0;
    check_memory_state_task;
    while(out_valid === 1)begin
        if(latency > 7) begin
            $display("\nSPEC MAIN-4 FAIL\n");
            $finish;
        end
		if(out_data !== golden_ans[latency])begin
			$display ("---------------------");
			$display ("       \033[0;31m FAIL! \033[0m       ");
            $display ("  %2d byte worng!    ", latency);
            $display ("   your answer : %2h ", out_data);
            $display (" golden answer : %2h ", golden_ans[latency]);
			$display ("---------------------");
			$display ("\nSPEC MAIN-5 FAIL\n");
            repeat(9) @(negedge clk);
			$finish;		
		end
		else begin
            latency = latency + 1;
            bit_num = bit_num + 8;
			@(negedge clk);
		end
	end	
    if(latency !== 8) begin
        $display("\nSPEC MAIN-4 FAIL\n");
        $finish;
    end

end endtask

task check_memory_state_task; begin  
    // $display("SD = %b ,DRAM = %b",u_SD.SD[addr_sd_dat] , u_DRAM.DRAM[addr_dram_dat]);
    if(u_SD.SD[addr_sd_dat] !== u_DRAM.DRAM[addr_dram_dat]) begin
        $display("\nSPEC MAIN-6 FAIL\n");
        $finish;
    end
end endtask
//////////////////////////////////////////////////////////////////////

task YOU_PASS_task; begin
    $display("\033[0;32m                   ,l||||||||||||||||||||||||||||\033[0m|||l*\"\"'\"\"f|*\"``\"-.   \"||||||||||||||||||||||||||||L ");
    $display("\033[0;32m                 ,l||||||||||||||||||||||||||\033[0m||l*\"   ,-^;e~<|L~; :~   ` 4|||||||||||||||||||||||||||||L,");
    $display("\033[0;32m               ,l||||||||||||||||||||||||||\033[0m||\"      /.'`!    ! L- . \      *||||||||||||||||||||||||||||L");
    $display("\033[0;32m              i||||||||||||||||||||||||||\033[0m|l`    :^'      `   \"*L.,\",   --    `l|||||||||||||||||||||||||||L");
    $display("\033[0;32m            ;||||||||||||||||||||||||||\033[0ml\"      /  .~||| |          |\"~T\">       '*l||||||||||||||||||||||||l,");
    $display("\033[0;32m          ,l||||||||||||||||||||||||'`\033[0m       .`=`       L      |        `,`       \ 'l|||||||||||||||||||||||L");
    $display("\033[0;32m         ||||||||||||||||||||||||F`\033[0m        ,`*    '     L     ||          \",\"       \ 'l||||||||||||||||||||||l");
    $display("\033[0;32m        ;||||||||||||||||||||||'\033[0m  .       ^/      |    >L      L,M          + .       .  *||||||||||||||||||||||L");
    $display("\033[0;32m       j|||||||||||||||||||||'\033[0m  ,^        {         .<\" L      }j '\"-,      '\" \       `,  l|||||||||||||||||||||L");
    $display("      |||||||||||||||||||||l`  /       ' |       +` r   !       F   | `       ' '        L   l||||||||||||||||||||L");
    $display("     ,||||||||||||||||||||L   '          `        >        F    L    \         L          r   l||||||||||||||||||||L");
    $display("     ||||||||||||||||||||L            L }      L,\"       \?  >, |     ',       | ,             l||||||||||||||||||||");
    $display("    l|||||||||||||||||||L     '         j      r     ,gw        *Nmgg,  \F    L!.        L      }|||||||||||||||||||L");
    $display("   ,|||||||||||||||||||L       \        u      L-mM**`               \"75     / y        /        l|||||||||||||||||||");
    $display("   l||||||||||||||||||l        $L       }L \".  j          ,,,,          j  ,'  L        L |       |||||||||||||||||||L");
    $display("   |||||||||||||||||||`       $||       j ,C \"><     ,c| |||||||||~     L~'            L|L        }|||||||||||||||||||");
    $display("   |||||||||||||||||||       (||||      ] '  \"      ,|||||||||||||||      -    -      ||||         |||||||||||||||||||");
    $display("  }||||||||||||||||||L       $|||||     `  L  +     [|||||||||||||||F   ,|    |!     {||||L        |||||||||||||||||||");
    $display("  |||||||||||||||||||L       h||||||,  {        |y. '||||||||||||||| . ]C     L \   {|||||`        |||||||||||||||||||");
    $display("  }||||||||||||||||||L       }'||||||L'     |    \" 'L]g|||||||||||\"`   @     7   ',|||||||         |||||||||||||||||||");
    $display("   |||||||||||||||||||        L |||||\"       ,    \ | \"V`\"*+~-*\"      /            L|||||l         |||||||||||||||||||");
    $display("   |||||||||||||||||||        ]  |||[        }     \YL   .           /      C       |||||F         |||||||||||||||||||");
    $display("   l|||||||||||||||||lL           ||L         \     \"|     -       ,|      (        \|||{         l||||||||||||||||||L");
    $display("    ||||||||||||||||||l         x Y|L          L    , l,      ''\"'T ,\"    ?|         L||\",       ||||||||||||||||||||");
    $display("    l|||||||||||||||||||     ,+  |;|l          '    | b~l,     ,;=\" L      |         ]|-  ', |  |l|||||l||||||||||||L");
    $display("     |||||||||||||||||||| ,<`   >\"'\".           L    L'L          .}     ` '        .^` ,    '.,lllllll|||||||||||||");
    $display("     \"||||||||||||||ll*\"'`  .-' ,   ||>,        |  j jLl         ' L    {       ,=||||   *|     \"\"|l|||||||||||||||`");
    $display("      l|||||||||||||TsxsT|lL   /   ||||||r.     }  [\" llXllL=,,,,   || j     -'|||||||||  '. l>,,, | -||L|||||||||L");
    $display("       l|||||||||||||||||||||L/   |||||||L      | ) }|LllW|||||||lj}|| |       ||||||||,||  '!|||||||||||||||||||T");
    $display("        l||||||||||||||||||||l   |/||||||L      W*|Ll|,'l|L `'''|L ',,`L      |||||||||''L||,  i||||||||||||||||l");
    $display("         l|||||||||||||||||||`  |/j|||||||       '  '*lll|||||l||  l||||      L|||||||||||||,||  i|||||||||||||l");
    $display("        | '|||||||||||||||||L  |/||||||||j      '         '\"|||||l==,,||     ]||||||||||||||||||| \"|||||||||||'");
    $display("            l|||||||||||||||  ||||||||||||     '                 `'\"'''`     L|||||||||||||||||||L,'||||||||l`");
    $display("             '||||||||||||||  ||||||||||l`   -                              |L}|||||||||||L|||||||||j||||||'");
    $display("               l|||||||||||| ||||||L|||\"   '                   .           ,|  }|||||||||||||||||||||||||L");
    $display("                '************\"******''`                         *         -''   *''''**'''**************");

    $display("********************************************************************");
    $display("*                        \033[0;32m Congratulations! \033[0m                        *");
    $display("*                total %4d pattern are passed                     *", PAT_NUM);
    $display("********************************************************************");
    $finish;
end endtask

task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                    Error message from PATTERN.v                       *");
end endtask

pseudo_DRAM u_DRAM (
    .clk(clk),
    .rst_n(rst_n),
    // write address channel
    .AW_ADDR(AW_ADDR),
    .AW_VALID(AW_VALID),
    .AW_READY(AW_READY),
    // write data channel
    .W_VALID(W_VALID),
    .W_DATA(W_DATA),
    .W_READY(W_READY),
    // write response channel
    .B_VALID(B_VALID),
    .B_RESP(B_RESP),
    .B_READY(B_READY),
    // read address channel
    .AR_ADDR(AR_ADDR),
    .AR_VALID(AR_VALID),
    .AR_READY(AR_READY),
    // read data channel
    .R_DATA(R_DATA),
    .R_VALID(R_VALID),
    .R_RESP(R_RESP),
    .R_READY(R_READY)
);

pseudo_SD u_SD (
    .clk(clk),
    .MOSI(MOSI),
    .MISO(MISO)
);

endmodule