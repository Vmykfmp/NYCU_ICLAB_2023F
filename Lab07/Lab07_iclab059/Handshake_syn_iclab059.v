module Handshake_syn #(parameter WIDTH=32) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;

input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;

parameter IDLE = 2'd0;
parameter REQ  = 2'd1;

reg [1:0] state_src;
reg [1:0] state_src_next;

reg [1:0] state_des;
reg [1:0] state_des_next;

reg [WIDTH-1:0] data_transfer;
reg [WIDTH-1:0] data_transfer_next;

reg [2:0] cnt;
reg [2:0] cnt_next;

reg sreq_next;
reg sreq_reg;

// FSM source (Src Ctrl)
always @(*) begin
    case (state_src)
        IDLE: begin
            if(sready) state_src_next = REQ;
            else       state_src_next = IDLE;
        end
        REQ: begin
            // state_src_next = IDLE;
            if(sack) state_src_next = IDLE;
            else     state_src_next = REQ;
        end
        default: state_src_next = IDLE;
    endcase
end
always @(posedge sclk or negedge rst_n) begin
    if(!rst_n) state_src <= 'b0;
    else       state_src <= state_src_next;
end

// FSM destination (Dest Ctrl)
always @(*) begin
    case (state_des)
        IDLE: begin
            if(dreq) state_des_next = REQ;
            else     state_des_next = IDLE;
        end 
        REQ: begin
            // if(!dbusy) state_des_next = IDLE;
            // else       state_des_next = REQ;            
            if(!dreq) state_des_next = IDLE;
            else      state_des_next = REQ;
        end
        default: state_des_next = IDLE;
    endcase
end
always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) state_des <= 'b0;
    else       state_des <= state_des_next;
end

always @(*) begin
    cnt_next = cnt;
    case (state_des)
        // IDLE: cnt_next = 'b0;
        REQ :begin
            if(dreq) begin
                if(cnt == 3'd3) cnt_next = cnt;
                else            cnt_next = cnt + 1'd1;
            end
            else cnt_next = 'b0;
        //     if(cnt == 3'd5) cnt_next = cnt;
        //     else if(dreq)   cnt_next = cnt + 1'b1;
        //     else            cnt_next = cnt; 
        end
        default: begin end
    endcase
end
always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) cnt <= 'b0;
    else       cnt <= cnt_next;
end

// always @(*) begin
//     data_transfer_next = data_transfer;
// end

always @(posedge sclk or negedge rst_n) begin
    if(!rst_n) data_transfer <= 'b0;
    else begin
        case (state_src)
            IDLE: data_transfer <= din;
            REQ:  data_transfer <= data_transfer; 
            default: data_transfer <= data_transfer; 
        endcase
    end 
end

// always @(posedge dclk or negedge rst_n) begin
//     if(!rst_n) dout <= 'b0;
//     else begin
//         // if(state_des)
//         // // if(dreq & ~dbusy & ~handshake_clk2_flag1) dout <= data_transfer;
//         // // else              dout <= dout;
//         // if(dreq & ~dack) dout <= data_transfer;
//         // else             dout <= 'b0;
//         if(~dreq & dack) dout <= data_transfer;
//         else             dout <= 'b0;
//     end 
// end


always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) dout <= 'b0;
    else begin
        // if(state_des)
        // // if(dreq & ~dbusy & ~handshake_clk2_flag1) dout <= data_transfer;
        // // else              dout <= dout;
        // if(dreq & ~dack) dout <= data_transfer;
        // else             dout <= 'b0;
        if(dack & ~dbusy) dout <= data_transfer;
        else     dout <= 'b0;
    end 
end
assign sidle = (~sreq & ~sack);

// assign sreq = (state_src == REQ & ~dack);

// wire sbusy;
always @(*) begin
    sreq_next = (state_src == REQ);
    // sreq_next = (state_src == REQ & ~dbusy);
end
always @(posedge sclk or negedge rst_n) begin
    if(!rst_n) sreq_reg <= 'b0;
    else       sreq_reg <= sreq_next;
end

assign sreq = sreq_reg;
// assign sreq = (state_src == REQ);


// assign dack = (state_des == REQ);

// always @(posedge dclk or negedge rst_n) begin
//     if(!rst_n) dack <= 'b0;
//     else       dack <= dreq;
// end
always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) dack <= 'b0;
    else       dack <= (dreq & cnt == 3'd3);
end

// always @(*) begin
//     if(dbusy) dvalid = 'b0;
//     // else      dvalid = (state_des == REQ);
//     dvalid = (state_des == REQ & ~dbusy);
// end

always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) dvalid <= 'b0;
    else begin
        if(dack & ~dbusy) dvalid <= 1'b1;
        else     dvalid <= 1'b0;
    end
end
// NDFF_syn NDFF_busy(dbusy, sbusy, sclk, rst_n);
NDFF_syn NDFF_src(sreq, dreq, dclk, rst_n);
NDFF_syn NDFF_des(dack, sack, sclk, rst_n);

endmodule