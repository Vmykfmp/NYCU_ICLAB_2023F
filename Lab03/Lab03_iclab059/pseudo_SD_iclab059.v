//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Tse-Chun Hsu
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : pseudo_SD.v
//   Module Name : pseudo_SD
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module pseudo_SD (
    clk,
    MOSI,
    MISO
);

input clk;
input MOSI;
output reg MISO;

parameter IDLE = 3'd0;
parameter COMM = 3'd1;
parameter ADDR = 3'd2;
// parameter CRC7 = 3'd3;

parameter START_BIT = 2'b01;
parameter CMD_READ  = 6'd17;
parameter CMD_WRITE = 6'd24;
parameter START_TOKEN = 8'hFE;

reg [1:0]  start;
reg [5:0]  command;
reg mode;
reg [31:0] address;
reg [6:0]  crc7;

reg [7:0] response;

reg [7:0]  start_token;
reg [63:0] data;
reg [15:0] crc16;

reg [9:0] cnt;

integer i, j, i_pat;

parameter SD_p_r = "../00_TESTBED/SD_init.dat";

reg [63:0] SD [0:65535];
initial $readmemh(SD_p_r, SD);
//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////
initial begin
    MISO = 1;
    for(i_pat = 0; i_pat < 1000; i_pat = i_pat + 1) begin
        // command
        wait_start_bit_task;
        check_command_task;
        check_address_task;
        check_CRC7_task;
        repeat($urandom_range(0,8)) wait_1_unit_cycle_task;
        // response
        response_task;
        
        // data
        if(!mode) begin
            repeat($urandom_range(1,32)) wait_1_unit_cycle_task;
            read_data_task;
        end
        else begin
            write_data_task;
            data_response_task;  
        end
        // clean register
        reg_clean_task;
    end
    // $finish;
end

//////////////////////////////////////////////////////////////////////
task wait_start_bit_task; begin
    while(start !== START_BIT) begin
        start[0] <= MOSI;
        start[1] <= start[0];
        @(posedge clk);
    end
end endtask

task check_command_task; begin
    for(i = 0; i < 6; i = i + 1) begin
        command[5 - i] = MOSI;
        @(posedge clk);
    end
    
    if(command === CMD_READ) begin
        mode = 0;
    end
    else if(command === CMD_WRITE) begin
        mode = 1;
    end 
    else begin
        $display("\nSPEC SD-1 FAIL\n");
        $finish;
    end
end endtask

task check_address_task; begin
    for(i = 0; i < 32; i = i + 1) begin
        address[31 - i] = MOSI;
        // address[0] <= MOSI;
        // for(j = 0; j < 31; j = j + 1) begin
        //     address[j + 1] <= address[j];
        // end
        @(posedge clk);
    end

    // $display("\naddress : %6d\n", address);
    if(address > 32'd65535) begin
        $display("\nSPEC SD-2 FAIL\n");
        $finish;
    end
end endtask

task check_CRC7_task; begin
    for(i = 0; i < 7; i = i + 1) begin
        crc7[6 - i] = MOSI;
        @(posedge clk);
    end
    if(crc7 !== CRC7({start,command,address})) begin
        $display("\nSPEC SD-3 FAIL\n");
        $finish;
    end
    
    if(!MOSI) begin
        $display("\nSPEC SD-1 FAIL\n");
        $finish;        
    end
    // @(posedge clk);
end endtask

task wait_1_unit_cycle_task; begin
    MISO = 1;
    for(i = 0; i < 8; i = i + 1) @(posedge clk);
end endtask

task response_task; begin
    response = 8'd0;
    for(i = 0; i < 8; i = i + 1) begin
        MISO = response[7 - i];
        @(posedge clk);
    end
    MISO = 1;
end endtask

task read_data_task; begin
    start_token = START_TOKEN;
    for(i = 0; i < 8; i = i + 1) begin
        MISO = start_token[7 - i];
        @(posedge clk);
    end

    data = SD[address];
    // $display("data: %16h\n", SD[26858]);
    // $display("data0: %2h\n", data[63:56]);
    for(i = 0; i < 64; i = i + 1) begin
        MISO = data[63 - i];
        @(posedge clk);
    end

    crc16 = CRC16_CCITT(data);
    for(i = 0; i < 16; i = i + 1) begin
        MISO = crc16[15 - i];
        @(posedge clk);
        if(i == 15) MISO = 0;
        else        MISO = 1;
    end
    MISO = 1;
end endtask;

task write_data_task; begin
    cnt = 0;
    while(start_token !== START_TOKEN) begin
        start_token[0] <= MOSI;
        for(j = 0; j < 7; j = j + 1) begin
            start_token[j + 1] <= start_token[j];
        end

        // if(cnt > 257) begin
            // $display("\ncnt0 = %4d\n", cnt);
            // $display("\nSPEC SD-5 FAIL\n");
            // $finish;
        // end
        // else cnt = cnt + 1; 
        cnt = cnt + 1; 
        @(posedge clk);
    end

    // $display("\ncnt = %4d\n", cnt);
    // if(cnt > 266) $finish;
    if((cnt - 1) < 9) begin
        $display("\nSPEC SD-5 FAIL\n");
        $finish;        
    end
    else if((cnt - 1) % 8 !== 0) begin
        $display("\nSPEC SD-5 FAIL\n");
        $finish;        
    end
    
    for(i = 0; i < 64; i = i + 1) begin
        data[63 - i] = MOSI;
        @(posedge clk);
    end
    // $display("\ndata0 : %2h\n", data[63:56]);
    for(i = 0; i < 16; i = i + 1) begin
        crc16[15 - i] = MOSI;
        if(i == 15) MISO = 0;
        else        MISO = 1;
        @(posedge clk);
    end

    if(crc16 !== CRC16_CCITT(data)) begin
        $display("\nSPEC SD-4 FAIL\n");
        $finish;
    end
    else begin
    end
end endtask

task data_response_task; begin
    // $display("\nresponse start!!!\n");
    response = 8'd5;
    for(i = 0; i < 7; i = i + 1) begin
        MISO = response[6 - i];
        @(posedge clk);
    end
    MISO = 0;
    // $display("\nresponse end!!!\n");
    // SD[address] = data;
    for(i = 0; i < 7; i = i + 1) @(posedge clk); // busy
    SD[address] = data;
    @(posedge clk);
    
    MISO = 1;
    // $display("\nbusy end!!!\n");
end endtask

task reg_clean_task; begin
    // @(posedge clk);
    mode  <= 'b0;
    data  <= 'b0;
    crc7  <= 'b0;
    crc16 <= 'b0;    
    command  <= 'b0;
    address  <= 'b0;
    response <= 'b0;
    start       <= 'b11;
    start_token <= 'h00;
    @(posedge clk);
end endtask

task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                 Error message from pseudo_SD.v                        *");
end endtask

function automatic [6:0] CRC7;  // Return 7-bit result
    input [39:0] data;  // 40-bit data input
    reg [6:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 7'h9;  // x^7 + x^3 + 1

    begin
        crc = 7'd0;
        for (i = 0; i < 40; i = i + 1) begin
            data_in = data[39-i];
            data_out = crc[6];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC7 = crc;
    end
endfunction

function automatic [15:0] CRC16_CCITT;
    // Try to implement CRC-16-CCITT function by yourself.
    input [63:0] data;  // 40-bit data input
    reg [15:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 16'h1021;  // x^7 + x^3 + 1

    begin
        crc = 16'd0;
        for (i = 0; i < 64; i = i + 1) begin
            data_in = data[63-i];
            data_out = crc[15];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC16_CCITT = crc;
    end

endfunction

endmodule