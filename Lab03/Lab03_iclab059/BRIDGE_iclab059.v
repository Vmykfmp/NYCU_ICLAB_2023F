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
//   File Name   : BRIDGE_encrypted.v
//   Module Name : BRIDGE
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module BRIDGE(
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

// Input Signals
input clk, rst_n;
input in_valid;
input direction;
input [12:0] addr_dram;
input [15:0] addr_sd;

// Output Signals
output reg out_valid;
output reg [7:0] out_data;

// DRAM Signals
// write address channel
output reg [31:0] AW_ADDR;
output reg AW_VALID;
input AW_READY;
// write data channel
output reg W_VALID;
output reg [63:0] W_DATA;
input W_READY;
// write response channel
input B_VALID;
input [1:0] B_RESP;
output reg B_READY;
// read address channel
output reg [31:0] AR_ADDR;
output reg AR_VALID;
input AR_READY;
// read data channel
input [63:0] R_DATA;
input R_VALID;
input [1:0] R_RESP;
output reg R_READY;

// SD Signals
input MISO;
output reg MOSI;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
integer i;
// FSM 
parameter IDLE  = 4'd0;
parameter DRAM_RADDR = 4'd1;
parameter DRAM_RDATA = 4'd2;

parameter DRAM_WADDR = 4'd3;
parameter DRAM_WDATA = 4'd4;
parameter DRAM_BRESP = 4'd5;

parameter SD_CMD   = 4'd6;
parameter SD_RESP  = 4'd7;
parameter SD_DATA  = 4'd8;
parameter SD_DRESP = 4'd9;
// parameter READ  = 4'd1;
// parameter WRITE = 4'd2;
// parameter OUT   = 4'd3;
parameter OUT      = 4'd10;

// SD
parameter START_BIT = 2'b01;
parameter CMD_READ  = 6'd17;
parameter CMD_WRITE = 6'd24;
parameter START_TOKEN = 8'hFE;

//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [3:0] state;
reg [3:0] state_next;
reg [7:0] cnt;
reg [7:0] cnt_next;
// input reg
reg direction_reg;
reg direction_next;
reg [12:0] addr_dram_reg;
reg [12:0] addr_dram_next;
reg [15:0] addr_sd_reg;
reg [15:0] addr_sd_next;
// transfer data
reg [63:0] data;
reg [63:0] data_next;
// DRAM read channel output next 
reg [31:0] AR_ADDR_next;
reg        AR_VALID_next;
reg        R_READY_next;
// DRAM write channel output next
reg [31:0] AW_ADDR_next;
reg        AW_VALID_next;
reg        W_VALID_next;
reg [63:0] W_DATA_next;
reg        B_READY_next;
// SD output next
reg MOSI_next;
wire [47:0] MOSI_command;
wire [87:0] MOSI_data_block;
wire [1:0]  start;
wire [5:0]  command;
wire [31:0] address;
wire [6:0]  crc7;
wire [7:0]  response;
wire [7:0]  start_token;
wire [15:0] crc16;
// output next
reg [7:0] out_data_next;
reg       out_valid_next;
//==============================================//
//                  design                      //
//==============================================//

// FSM
always @(*) begin
    case (state)
        IDLE: begin
            if(in_valid) begin
                if(!direction) state_next = DRAM_RADDR;
                else           state_next = SD_CMD;
            end
            else         state_next = IDLE;
        end
        // DRAM read channel
        DRAM_RADDR: begin
            if(AR_READY) state_next = DRAM_RDATA;
            else         state_next = DRAM_RADDR;
        end
        DRAM_RDATA: begin
            if(R_VALID) state_next = SD_CMD;
            else        state_next = DRAM_RDATA;
        end
        // DRAM write channel
        DRAM_WADDR: begin
            if(AW_READY) state_next = DRAM_WDATA;
            else         state_next = DRAM_WADDR;
        end
        DRAM_WDATA: begin
            if(W_READY) state_next = DRAM_BRESP;
            else             state_next = DRAM_WDATA;
        end
        DRAM_BRESP: begin
            if(B_RESP === 2'b0 & B_VALID) state_next = OUT;
            else                         state_next = DRAM_BRESP;
        end
        // SD
        SD_CMD: begin
            if(cnt == 8'd47) state_next = SD_RESP;
            else             state_next = SD_CMD;
        end
        SD_RESP: begin
            // if(cnt == 8'd15) state_next = SD_DATA;
            if(cnt == 8'd14) state_next = SD_DATA;
            else             state_next = SD_RESP; 
        end
        SD_DATA: begin
            if(cnt == 8'd88) begin
                if(!direction_reg) state_next = SD_DRESP;    
                else           state_next = DRAM_WADDR;
            end
            else               state_next = SD_DATA;
        end
        SD_DRESP: begin
            if(cnt > 8'd8 && MISO) state_next = OUT;
            else                   state_next = SD_DRESP;
        end
        OUT: begin
            if(cnt === 8'd7) state_next = IDLE;
            else             state_next = OUT;
        end
        default: state_next = IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state <= 0;
    else       state <= state_next;
end

always @(*) begin
    cnt_next = cnt;
    case (state)
        SD_CMD: begin
            if(cnt === 47) cnt_next = 0;
            else           cnt_next = cnt + 1;
        end
        SD_RESP: begin
            if     (MISO === 0) cnt_next = cnt + 1;
            else if(cnt === 8'd14) cnt_next = 0;
            else if(cnt > 8'd7)    cnt_next = cnt + 1;   
        end
        SD_DATA: begin
            if(!direction_reg) begin
                if(cnt === 8'd88) cnt_next = 0;
                else              cnt_next = cnt + 1;
            end
            else begin
                if(cnt === 8'd88) cnt_next = 0;
                else if(cnt > 1)  cnt_next = cnt + 1;
                else if(cnt === 0 && MISO === 0) cnt_next = 9;
            end
        end
        SD_DRESP: begin
            if(MISO === 0)      cnt_next = cnt + 1;
            else if(cnt < 8'd9) cnt_next = cnt + 1;
            else                cnt_next = 0;
        end
        OUT: begin
            if(cnt === 4'd7) cnt_next = 0;
            else             cnt_next = cnt + 1;
        end
        default: begin
        end 
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt <= 0;
    else       cnt <= cnt_next;
end
// Input block
always @(*) begin
    case (state)
        IDLE: begin
            if(in_valid) begin
                direction_next = direction;
                addr_dram_next = addr_dram;
                addr_sd_next   = addr_sd;    
            end
            else begin
                direction_next = direction_reg;
                addr_dram_next = addr_dram_reg;
                addr_sd_next   = addr_sd_reg; 
            end
        end 
        default: begin
            direction_next = direction_reg;
            addr_dram_next = addr_dram_reg;
            addr_sd_next   = addr_sd_reg; 
        end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        direction_reg <= 0;
        addr_dram_reg <= 0;
        addr_sd_reg   <= 0;
    end
    else begin
        direction_reg <= direction_next;
        addr_dram_reg <= addr_dram_next;
        addr_sd_reg   <= addr_sd_next;        
    end
end
// transfer data block
always @(*) begin
    data_next = data;
    case (state)
        DRAM_RDATA: begin
            if(R_VALID) data_next = R_DATA;
        end 
        SD_DATA: begin
            if(direction_reg) begin
                for(i = 0; i < 64; i = i + 1) begin
                    if(i === (cnt - 9)) data_next[63 - i] = MISO;
                end
            end
        end
        default: begin
        end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) data <= 0;
    else       data <= data_next;
end
// DRAM read channel block
always @(*) begin
    AR_ADDR_next  = AR_ADDR;
    AR_VALID_next = AR_VALID;
    R_READY_next  = R_READY; 
    case (state)
        IDLE: begin
            if(in_valid) begin
                if(!direction) begin
                    AR_ADDR_next  = addr_dram;
                    AR_VALID_next = 1;
                    R_READY_next  = 0;                
                end
            end
            else begin
            end
        end
        DRAM_RADDR: begin
            if(AR_READY) begin
                AR_ADDR_next  = 0;
                AR_VALID_next = 0;
                R_READY_next  = 1; 
            end
            else begin
            end
        end
        DRAM_RDATA: begin
            if(R_VALID) begin
                AR_ADDR_next  = 0;
                AR_VALID_next = 0;
                R_READY_next  = 0;
            end
            else begin
            end
        end 
        default: begin
        end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        AR_ADDR  <= 0;
        AR_VALID <= 0;
        R_READY  <= 0;        
    end
    else begin
        AR_ADDR  <= AR_ADDR_next;
        AR_VALID <= AR_VALID_next;
        R_READY  <= R_READY_next;         
    end
end
// DRAM wirte channel block
always @(*) begin
    AW_ADDR_next  = AW_ADDR;
    AW_VALID_next = AW_VALID;
    W_VALID_next  = W_VALID;
    W_DATA_next   = W_DATA;
    B_READY_next  = B_READY;
    case (state)
        DRAM_WADDR: begin
            AW_ADDR_next  = addr_dram_reg;
            AW_VALID_next = 1;
            W_VALID_next  = 0;
            W_DATA_next   = 0;
            B_READY_next  = 0;
        end
        DRAM_WDATA: begin
            AW_ADDR_next  = 0;
            AW_VALID_next = 0;
            W_VALID_next  = 1;
            W_DATA_next   = data; 
            B_READY_next  = 1;            
        end
        DRAM_BRESP: begin
            AW_ADDR_next  = 0;
            AW_VALID_next = 0;
            W_VALID_next  = 0;
            W_DATA_next   = 0;
            B_READY_next  = 1; 
        end
        default: begin
        end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        AW_ADDR  <= 0;
        AW_VALID <= 0;
        W_VALID  <= 0;
        W_DATA   <= 0;
        B_READY  <= 0;
    end
    else begin
        AW_ADDR  <= AW_ADDR_next;
        AW_VALID <= AW_VALID_next;
        // if(W_READY) begin
        //     W_VALID  <= 1;
        //     W_DATA   <= data;            
        // end
        // else begin
        //     W_VALID  <= 0;
        //     W_DATA   <= 0;
        // end
        W_VALID  <= W_VALID_next;
        W_DATA   <= W_DATA_next;
        B_READY  <= B_READY_next;       
    end
end

// MOSI block
assign start = START_BIT;
assign command = (!direction_reg) ? CMD_WRITE : CMD_READ;
assign address = addr_sd_reg;
assign crc7 = CRC7({start, command, address});

assign MOSI_command[47:46] = start;
assign MOSI_command[45:40] = command;
assign MOSI_command[39:8] = address;
assign MOSI_command[7:1] = crc7;
assign MOSI_command[0] = 1;
assign start_token = START_TOKEN;
assign crc16 = CRC16_CCITT(data);
assign MOSI_data_block[87:80] = start_token;
assign MOSI_data_block[79:16] = data;
assign MOSI_data_block[15:0]  = crc16;

always @(*) begin
    MOSI_next = 1;
    case (state)
        SD_CMD: begin
            for(i = 0; i < 48; i = i + 1) begin
                if(i == cnt) MOSI_next = MOSI_command[47 - i];
            end
        end
        SD_RESP: begin
        end
        SD_DATA: begin
            if(!direction_reg) begin
                
                for(i = 0; i < 88; i = i + 1) begin
                    if(i == cnt) MOSI_next = MOSI_data_block[87 - i];
                end                
            end
        end
        default: begin
        end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) MOSI <= 1;
    else       MOSI <= MOSI_next;
end
// OUTPUT block
always @(*) begin
    out_data_next  = 0;
    out_valid_next = 0;
    case (state)
        OUT: begin
            out_valid_next = 1;
            case (cnt)
                8'd0: out_data_next = data[63:56];
                8'd1: out_data_next = data[55:48];
                8'd2: out_data_next = data[47:40];
                8'd3: out_data_next = data[39:32];
                8'd4: out_data_next = data[31:24];
                8'd5: out_data_next = data[23:16];
                8'd6: out_data_next = data[15:8];
                8'd7: out_data_next = data[7:0];
                default: begin
                end
            endcase
        end 
        default: begin
        end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_data  <= 0;
        out_valid <= 0;
    end
    else begin
        out_data  <= out_data_next;
        out_valid <= out_valid_next;
    end
end

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

