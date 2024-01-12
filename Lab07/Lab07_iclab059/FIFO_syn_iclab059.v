module FIFO_syn #(parameter WIDTH=32, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
input clk2_fifo_flag1;
input clk2_fifo_flag2;
output clk2_fifo_flag3;
output clk2_fifo_flag4;

input fifo_clk3_flag1;
input fifo_clk3_flag2;
output fifo_clk3_flag3;
output fifo_clk3_flag4;

wire [WIDTH-1:0] rdata_q;

// Remember: 
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;

reg wen_w;
reg wen_r;

reg rinc_delay_1;

// reg [6:0] addr_w;
// reg [6:0] addr_w_next;
reg [8:0] addr_w;
reg [8:0] addr_w_next;
reg [6:0] wptr_next;
wire [6:0] wptr_syn;

reg [6:0] addr_r;
reg [6:0] addr_r_next;
reg [6:0] rptr_next;
wire [6:0] rptr_syn;

assign clk2_fifo_flag3 = addr_w[8];

// rdata
//  Add one more register stage to rdata
always @(posedge rclk) begin
    if (rinc_delay_1)
        rdata <= rdata_q;
end

always @(posedge rclk or negedge rst_n) begin
    if(!rst_n) rinc_delay_1 <= 'b0;
    else       rinc_delay_1 <= rinc;
end

// SRAM write domain
// address
always @(*) begin
    if(winc & ~wfull) addr_w_next = addr_w + 1'd1;
    // if(winc & ~wfull & addr_w != 8'd255)
        // if(wptr == rptr_syn & addr_w == 9'd256) addr_w_next = 'b0;
        // else                 addr_w_next = addr_w + 1'd1;

    else if(wptr == rptr_syn & addr_w[8]) addr_w_next = 'b0;
    // else if(wptr == rptr_syn & addr_w == 9'd256) addr_w_next = 'b0;


    else addr_w_next = addr_w;
end
always @(posedge wclk or negedge rst_n) begin
    if(!rst_n) addr_w <= 'b0;
    else       addr_w <= addr_w_next;
end
// enable
always @(*) begin
    wen_w = ~(winc && ~wfull);
end
// pointer
always @(*) begin
    wptr_next = binary_to_gray(addr_w_next[6:0]);
end
always @(posedge wclk or negedge rst_n) begin
    if(!rst_n) wptr <= 'b0;
    else       wptr <= wptr_next;
end
// full
always @(*) begin
    if(clk2_fifo_flag1) wfull = ({~wptr[6:5], wptr[4:0]} == rptr_syn);
    else                wfull = 'b0;
    // wfull = ({~wptr[6:5], wptr[4:0]} == rptr_syn);
end
    

// SRAM read domain
// address
always @(*) begin
    // addr_r_next = addr_w;
    if(rinc & ~rempty) addr_r_next = addr_r + 1'd1;
    else               addr_r_next = addr_r;
end
always @(posedge rclk or negedge rst_n) begin
    if(!rst_n) addr_r <= 'b0;
    else       addr_r <= addr_r_next;
end
// pointer
always @(*) begin
    rptr_next = binary_to_gray(addr_r_next);
end
always @(posedge rclk or negedge rst_n) begin
    if(!rst_n) rptr <= 'b0;
    else       rptr <= rptr_next;
end
// empty
always @(*) begin
    rempty = (rptr == wptr_syn);
end
// enable
NDFF_BUS_syn #(.WIDTH(7)) NDFF_BUS_W (
    .D(wptr), .Q(wptr_syn), .clk(rclk), .rst_n(rst_n)
);

NDFF_BUS_syn #(.WIDTH(7)) NDFF_BUS_R (
    .D(rptr), .Q(rptr_syn), .clk(wclk), .rst_n(rst_n)
);
DUAL_64X32X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(wen_w),
    .WEBN(1'b1),
    .CSA(1'b1),
    .CSB(1'b1),
    .OEA(1'b1),
    .OEB(1'b1),
    .A0(addr_w[0]),
    .A1(addr_w[1]),
    .A2(addr_w[2]),
    .A3(addr_w[3]),
    .A4(addr_w[4]),
    .A5(addr_w[5]),
    .B0(addr_r[0]),
    .B1(addr_r[1]),
    .B2(addr_r[2]),
    .B3(addr_r[3]),
    .B4(addr_r[4]),
    .B5(addr_r[5]),
    .DIA0(wdata[0]),
    .DIA1(wdata[1]),
    .DIA2(wdata[2]),
    .DIA3(wdata[3]),
    .DIA4(wdata[4]),
    .DIA5(wdata[5]),
    .DIA6(wdata[6]),
    .DIA7(wdata[7]),
    .DIA8(wdata[8]),
    .DIA9(wdata[9]),
    .DIA10(wdata[10]),
    .DIA11(wdata[11]),
    .DIA12(wdata[12]),
    .DIA13(wdata[13]),
    .DIA14(wdata[14]),
    .DIA15(wdata[15]),
    .DIA16(wdata[16]),
    .DIA17(wdata[17]),
    .DIA18(wdata[18]),
    .DIA19(wdata[19]),
    .DIA20(wdata[20]),
    .DIA21(wdata[21]),
    .DIA22(wdata[22]),
    .DIA23(wdata[23]),
    .DIA24(wdata[24]),
    .DIA25(wdata[25]),
    .DIA26(wdata[26]),
    .DIA27(wdata[27]),
    .DIA28(wdata[28]),
    .DIA29(wdata[29]),
    .DIA30(wdata[30]),
    .DIA31(wdata[31]),
    .DIB0('b0),
    .DIB1('b0),
    .DIB2('b0),
    .DIB3('b0),
    .DIB4('b0),
    .DIB5('b0),
    .DIB6('b0),
    .DIB7('b0),
    .DIB8('b0),
    .DIB9('b0),
    .DIB10('b0),
    .DIB11('b0),
    .DIB12('b0),
    .DIB13('b0),
    .DIB14('b0),
    .DIB15('b0),
    .DIB16('b0),
    .DIB17('b0),
    .DIB18('b0),
    .DIB19('b0),
    .DIB20('b0),
    .DIB21('b0),
    .DIB22('b0),
    .DIB23('b0),
    .DIB24('b0),
    .DIB25('b0),
    .DIB26('b0),
    .DIB27('b0),
    .DIB28('b0),
    .DIB29('b0),
    .DIB30('b0),
    .DIB31('b0),
    .DOB0(rdata_q[0]),
    .DOB1(rdata_q[1]),
    .DOB2(rdata_q[2]),
    .DOB3(rdata_q[3]),
    .DOB4(rdata_q[4]),
    .DOB5(rdata_q[5]),
    .DOB6(rdata_q[6]),
    .DOB7(rdata_q[7]),
    .DOB8(rdata_q[8]),
    .DOB9(rdata_q[9]),
    .DOB10(rdata_q[10]),
    .DOB11(rdata_q[11]),
    .DOB12(rdata_q[12]),
    .DOB13(rdata_q[13]),
    .DOB14(rdata_q[14]),
    .DOB15(rdata_q[15]),
    .DOB16(rdata_q[16]),
    .DOB17(rdata_q[17]),
    .DOB18(rdata_q[18]),
    .DOB19(rdata_q[19]),
    .DOB20(rdata_q[20]),
    .DOB21(rdata_q[21]),
    .DOB22(rdata_q[22]),
    .DOB23(rdata_q[23]),
    .DOB24(rdata_q[24]),
    .DOB25(rdata_q[25]),
    .DOB26(rdata_q[26]),
    .DOB27(rdata_q[27]),
    .DOB28(rdata_q[28]),
    .DOB29(rdata_q[29]),
    .DOB30(rdata_q[30]),
    .DOB31(rdata_q[31])
);
function [6:0] binary_to_gray;
    input [6:0] binary;
    integer i;

    binary_to_gray[6] = binary[6];
    for(i = 0; i < 6; i = i + 1)
        binary_to_gray[i] = binary[i] ^ binary[i + 1];
endfunction
endmodule
