module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
    seed_in,
    out_idle,
    out_valid,
    seed_out,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4
);

input clk;
input rst_n;
input in_valid;
input [31:0] seed_in;
input out_idle;
output reg out_valid;
output reg [31:0] seed_out;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;

parameter IDLE = 2'd0;
// parameter READ = 2'd1;
parameter HOLD = 2'd1;

reg [1:0] state;
reg [1:0] state_next;

reg [31:0] seed_reg;

always @(*) begin
    case (state)
        IDLE: begin
            if(in_valid) state_next = HOLD;
            else         state_next = IDLE;
        end 
        HOLD: begin
            // state_next = IDLE;
            if(out_idle) state_next = IDLE;
            else         state_next = HOLD;
        end
        default: state_next = IDLE;
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state <= 'b0;
    else       state <= state_next;
end

// always @(*) begin
//     if(in_valid & out_idle) seed_out = seed_in;
//     else                    seed_out = 'b0; 
// end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) seed_out <= 'b0;
    else begin
        if(in_valid & out_idle) seed_out <= seed_in;
        else                    seed_out <= seed_out;
    end
end

// always @(*) begin
//     if(in_valid & out_idle) out_valid = 1'b1;
//     else                    out_valid = 1'b0;
// end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n ) out_valid <= 'b0;
    else begin
        if(in_valid & out_idle) out_valid <= 1'b1;
        else                    out_valid <= 1'b0;
    end      
end
endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    seed,
    out_valid,
    rand_num,
    busy,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [31:0] seed;
output out_valid;
output [31:0] rand_num;
output busy;

// You can change the input / output of the custom flag ports
output handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

output clk2_fifo_flag1;
input clk2_fifo_flag2;
input clk2_fifo_flag3;
output clk2_fifo_flag4;

parameter IDLE = 1'd0;
parameter BUSY = 1'd1;

parameter a = 4'd13;
parameter b = 5'd17;
parameter c = 3'd5;

// reg [1:0] state;
// reg [1:0] state_next;

reg state;
// wire state;
// reg state_syn;
reg state_next;

reg [8:0] cnt;
reg [8:0] cnt_next;

reg [31:0] rand_num_tmp1;
reg [31:0] rand_num_tmp2;
reg [31:0] rand_num_next;
reg [31:0] rand_num_reg;

wire flag;
wire flag_syn;

// reg busy_tmp;
// wire in_valid_syn;
// wire state_syn;
// wire fifo_full_syn;
// reg fifo_full_gate;

// reg in_valid_gate;

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) in_valid_gate <= 'b0;
//     else begin
//         if(~fifo_full_syn) in_valid_gate <= in_valid_syn;
//         else               in_valid_gate <= 'b0;
//     end

// end

// always @(*) begin
//     if(in_valid) fifo_full_gate = 1'b1;
//     else         fifo_full_gate = fifo_full;
// end

// wire busy_syn;
// wire [7:0] cnt_syn;
// wire [31:0] rand_num_syn;
// always @(*) begin
//     flag = ~fifo_full & cnt != 8'd255;
// end


// NDFF_BUS_syn #(.WIDTH(8)) NDFF_BUS_U0 (
//     .D(cnt), .Q(cnt_syn), .clk(clk), .rst_n(rst_n)
// );

// NDFF_BUS_syn #(.WIDTH(8)) NDFF_BUS_U1 (
//     .D({in_valid, fifo_full}), .Q({in_valid_syn, fifo_full_syn}), .clk(clk), .rst_n(rst_n)
// );
// NDFF_BUS_syn #(.WIDTH(2)) NDFF_BUS_U0 (
//     .D({in_valid, state}), .Q({in_valid_syn, state_syn}), .clk(clk), .rst_n(rst_n)
// );
NDFF_syn NDFF_flag (state, state_syn, clk, rst_n);
// NDFF_syn NDFF_state (state, state_syn, clk, rst_n);
// NDFF_syn NDFF_busy(busy_tmp, busy_syn, clk, rst_n);

// always @(*) begin
//     case (busy)
//         0: begin
//             if(in_valid) busy_tmp = 1'b1;
//             else         busy_tmp = 1'b0;
//         end
//         1: begin
//             if(cnt == 8'd255 & )
//         end
//         default: 
//     endcase
//     busy_tmp = (state == BUSY && cnt != 8'd255);
// end
// assign busy = busy_syn;
// assign fifo_full_gate = (~in_valid & fifo_full);
// assign in_valid_gate = (~fifo_full & in_valid);
// assign flag =in_valid

always @(*) begin
    // state_next = state;
    // case (state)
    case (state_syn)
        IDLE: begin
            state_next = in_valid;
            // if(in_valid) state_next = BUSY;
            // else         state_next = IDLE;
        end
        BUSY: begin
            if(cnt == 9'd256) state_next = IDLE;
            else              state_next = BUSY;
            // if(cnt == 8'd255 & ~fifo_full) state_next = IDLE;
            // else                           state_next = BUSY;
        end
        default: state_next = IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state <= IDLE;
    else       state <= state_next;
    // else begin
    //     case (state_syn)
    //         IDLE: begin
    //             if(in_valid) state <= BUSY;
    //             else         state <= IDLE;
    //         end
    //         BUSY: begin
    //             // if(cnt == 8'd255) state <= IDLE;
    //             if(cnt_syn == 8'd255) state <= IDLE;
    //             else                           state <= BUSY;
    //         end
    //         default: state <= IDLE;
    //     endcase
        
    // end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt <= 'b0;
    else begin
        // if(state == BUSY) begin
        if(state_syn == BUSY) begin
            if(cnt == 9'd256) cnt <= cnt;
            else if(!fifo_full) cnt <= cnt + 1'd1;
            
            // if(!fifo_full & cnt != 8'd255) begin
            //     cnt <= cnt + 1'd1;
            // end
            // else           cnt <= cnt;
        end
        else               cnt <= 'b0;
    end
end


always @(*) begin
    if(state_syn == IDLE) rand_num_tmp1 = seed ^ (seed << a);
    // if(state_syn == IDLE) rand_num_tmp1 = seed ^ (seed << a);
    // if(in_valid) rand_num_tmp1 = seed ^ (seed << a);
    else              rand_num_tmp1 = rand_num_reg ^ (rand_num_reg << a);
    rand_num_tmp2 = rand_num_tmp1 ^ (rand_num_tmp1 >> b);
    rand_num_next = rand_num_tmp2 ^ (rand_num_tmp2 << c);
end

assign rand_num = rand_num_reg;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) rand_num_reg <= 'b0;
    else begin
        if(!fifo_full & cnt < 9'd255) rand_num_reg <= rand_num_next;
        // if(!fifo_full & cnt_syn != 8'd 255) rand_num_reg <= rand_num_next;
        else                          rand_num_reg <= rand_num_reg;
    end
end
assign clk2_fifo_flag1 = ~in_valid & (state_syn == BUSY);
// assign clk2_fifo_flag1 = (state == BUSY);
assign handshake_clk2_flag1 = fifo_full | (state_syn == BUSY);
assign busy = (state_syn == BUSY);
// assign busy = (state == BUSY && cnt != 8'd255);
// assign busy = (state == BUSY && cnt == 8'd0);

// assign busy = (state_syn == BUSY && cnt_syn != 8'd255);
// assign busy = 'b1;

assign out_valid = (state_syn == BUSY & ~fifo_full & ~clk2_fifo_flag3);
// assign out_valid = (state_syn == BUSY & ~fifo_full);


endmodule

module CLK_3_MODULE (
    clk,
    rst_n,
    fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    rand_num,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input clk;
input rst_n;
input fifo_empty;
input [31:0] fifo_rdata;
output fifo_rinc;
output reg out_valid;
output reg [31:0] rand_num;

// You can change the input / output of the custom flag ports
input fifo_clk3_flag1;
input fifo_clk3_flag2;
output fifo_clk3_flag3;
output fifo_clk3_flag4;

reg fifo_rinc_next;
reg fifo_rinc_reg;

reg        out_valid_delay1;
reg        out_valid_delay2;
reg [31:0] rand_num_next;


// assign fifo_rinc = 1'b1;
assign fifo_rinc = ~fifo_empty;
// assign fifo_rinc = fifo_rinc_reg;
always @(*) begin
    fifo_rinc_next = ~fifo_empty;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) fifo_rinc_reg <= 'b0;
    else       fifo_rinc_reg <= fifo_rinc_next;
end

// assign fifo_rinc = ~fifo_empty;

// always @(*) begin
//     out_valid_next = ~fifo_empty;
// end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_valid_delay1 <= 'b0;
    else       out_valid_delay1 <= ~fifo_empty;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_valid_delay2 <= 'b0;
    else       out_valid_delay2 <= out_valid_delay1;
end

always @(*) begin
    rand_num_next = fifo_rdata;
end

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) rand_num_next <= 'b0;
//     else begin
//         if(~fifo_empty) rand_num_next <= fifo_rdata;
//     end
// end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_valid <= 'b0;
    else       out_valid <= out_valid_delay2;

end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) rand_num <= 'b0;
    else begin
        if(out_valid_delay2) rand_num <= rand_num_next;
        else                 rand_num <= 'b0;
    end
end

endmodule