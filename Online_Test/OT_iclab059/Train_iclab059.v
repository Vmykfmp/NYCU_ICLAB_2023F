module Train(
    //Input Port
    clk,
    rst_n,
	in_valid,
	data,

    //Output Port
    out_valid,
	result
);

input        clk;
input 	     in_valid;
input        rst_n;
input  [3:0] data;
output   reg out_valid;
output   reg result; 


parameter IDLE   = 2'd0;
parameter INPUT  = 2'd1;
// parameter COMPUT = 2'd2;
parameter OUTPUT = 2'd3;

reg [1:0] state;
reg [1:0] state_next;

reg [3:0] cnt;
reg [3:0] cnt_next;

reg [3:0] num_train;
reg [3:0] num_train_next;

reg [3:0] order_train      [0:9];
reg [3:0] order_train_next [0:9];

reg [1:0] train      [0:9];
reg [1:0] train_next [0:9];

reg out_valid_next;
reg result_reg;
reg result_next;

integer i;

// FSM
always @(*) begin
    case (state)
        IDLE: begin
            if(in_valid) state_next = INPUT;
            else         state_next = IDLE;
        end 
        INPUT: begin
            if(cnt == num_train - 1) state_next = OUTPUT;
            else                     state_next = INPUT;
        end
        default: state_next = IDLE;
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state <= 'b0;
    else       state <= state_next;
end

// counter
always @(*) begin
    cnt_next = cnt;
    case (state)
        IDLE: begin
            cnt_next = 'b0;
        end 
        INPUT: begin
            if(cnt == num_train - 1) cnt_next = cnt;
            else                     cnt_next = cnt + 1;
        end
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt <= 'b0;
    else       cnt <= cnt_next;
end

// input number
always @(*) begin
    num_train_next = num_train;
    case (state)
        IDLE: begin
            if(in_valid) num_train_next = data;
            else         num_train_next = num_train;
        end 
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) num_train <= 'b0;
    else       num_train <= num_train_next;
end


// compute block
always @(*) begin
    for(i = 0; i < 10; i = i + 1) train_next[i] = train[i];
    case (state)
        IDLE: begin
            for(i = 0; i < 10; i = i + 1) train_next[i] = 'b0;
        end 
        INPUT: begin
            for(i = 0; i < 10; i = i + 1) begin
                if      (i == data - 1) train_next[i] = 2'd2;
                else if (i <  data - 1) begin
                    if(train[i] == 2'd0) train_next[i] = 2'd1;
                    else                 train_next[i] = train[i];
                end
                else begin
                    if(train[i] == 2'd1) train_next[i] = 2'd3;
                    else                 train_next[i] = train[i];
                end
            end
        end
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0; i < 10; i = i + 1) train[i] <= 'b0;
    else       for(i = 0; i < 10; i = i + 1) train[i] <= train_next[i];
end



// output
// assign out_valid = (state == OUTPUT);
always @(*) begin
    out_valid_next = 'b0;
    case (state)
        // INPUT:  out_valid_next = (cnt == num_train);
        OUTPUT: out_valid_next = 1'b1;
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_valid <= 'b0;
    else       out_valid <= out_valid_next;
end

always @(*) begin
    result_next = result;
    case (state)
        IDLE: begin
            result_next = 1'b1;
        end
        INPUT, OUTPUT:  result_next = result && (train[0] != 2'd3) && (train[1] != 2'd3) && (train[2] != 2'd3) && (train[3] != 2'd3) && (train[4] != 2'd3)
                                     && (train[5] != 2'd3) && (train[6] != 2'd3) && (train[7] != 2'd3) && (train[8] != 2'd3) && (train[9] != 2'd3);
        // OUTPUT: result_next = 1'b1;
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) result <= 'b0;
    else       result <= result_next;
end

endmodule