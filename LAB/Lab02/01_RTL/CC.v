module CC(
    //Input Port
    clk,
    rst_n,
	in_valid,
	mode,
    xi,
    yi,

    //Output Port
    out_valid,
	xo,
	yo
    );

input               clk, rst_n, in_valid;
input       [1:0]   mode;
input       [7:0]   xi, yi;  

output reg          out_valid;
output reg  [7:0]   xo, yo;
//==============================================//
//             Parameter and Integer            //
//==============================================//
parameter IDLE = 2'd0;
parameter IN   = 2'd1;
parameter OUT  = 2'd2;

parameter PREDICT_LEFT  = 2'd1;
parameter PREDICT_RIGHT = 2'd2;
integer i;
//==============================================//
//            FSM State Declaration             //
//==============================================//
reg [1:0] state;
reg [1:0] state_next;
reg [1:0] input_cnt;
reg [1:0] input_cnt_next;
reg [2:0] predict_state;
reg [2:0] predict_state_next;
reg [1:0] mode_reg;
reg [1:0] mode_next;
//==============================================//
//                 reg declaration              //
//==============================================//
// input
reg signed[7:0] x [0:3];
reg signed[7:0] y [0:3];
reg signed[7:0] x_next [0:3];
reg signed[7:0] y_next [0:3];
// mode 0
wire signed[8:0] left_edge [0:1];
wire signed[8:0] right_edge [0:1];
reg signed[7:0] left_point [0:1];
reg signed[7:0] right_point [0:1];
reg signed[7:0] left_point_next [0:1];
reg signed[7:0] right_point_next [0:1];
reg signed[8:0] left_slope;
reg signed[8:0] right_slope;
reg signed[7:0] horizon_point;
reg signed[7:0] vertical_point;
reg signed[7:0] horizon_point_next;
reg signed[7:0] vertical_point_next;
reg signed[9:0] left_point_tmp;
reg signed[9:0] right_point_tmp;

reg signed[1:0] delta [0:1];
reg signed[7:0] sub[0:1];
reg signed[9:0] point_tmp;
// mode 1
wire signed[6:0] a;
wire signed[6:0] b;
wire signed[6:0] r1;
wire signed[6:0] r2;
// sharing
reg signed[8:0]    num_1 [0:7];
reg signed[13:0]   num_2 [0:1];
reg signed[15:0]   cal_1 [0:1];
reg unsigned[23:0] cal_2;
reg signed[25:0] sum;
reg signed[25:0] sum_next;
reg signed[15:0] out;
reg signed[25:0] out_tmp;
//==============================================//
//             Current State Block              //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        state <= 2'd0;
        input_cnt <= 2'd0;
        predict_state <= 2'd0;
    end
    else begin
        state <= state_next;
        input_cnt <= input_cnt_next;
        predict_state <= predict_state_next;
    end
end
//==============================================//
//              Next State Block                //
//==============================================//
always @(*) begin
    case (state)
        IDLE: begin
            if(in_valid) state_next = IN;
            else         state_next = IDLE;    
        end
        IN: begin
            if(input_cnt == 2'd3) state_next = OUT;
            else                  state_next = IN;
        end
        OUT: begin
            if(mode_reg == 2'd0 & (horizon_point !== x[1] | vertical_point !== y[1])) state_next = OUT;
            else                                                                      state_next = IDLE;
        end
        default: begin
            state_next = IDLE;
        end 
    endcase
end

always @(*) begin
    case (state)
        IN: begin
            predict_state_next = PREDICT_LEFT;
        end
        OUT: begin
            if(predict_state == PREDICT_LEFT) predict_state_next = PREDICT_RIGHT;
            else                              predict_state_next = IDLE;

            if(horizon_point == right_point[0]) predict_state_next = PREDICT_LEFT;
        end
        default: predict_state_next = predict_state;
    endcase
end

always @(*) begin
    case (state)
        IN:      input_cnt_next = input_cnt + 1;
        default: input_cnt_next = 2'd0;
    endcase
end
//==============================================//
//                  Input Block                 //
//==============================================//
always @(*) begin
    for(i = 0; i < 4; i = i + 1) begin
        x_next[i] = x[i];
        y_next[i] = y[i];
    end
    mode_next = mode_reg;

    case (state)
        IDLE: begin
            if(in_valid) begin
                x_next[0] = xi;
                y_next[0] = yi;
                mode_next = mode;
            end
            else begin
            end
        end 
        IN: begin
            case (input_cnt)
                2'd0: begin
                    x_next[1] = xi;
                    y_next[1] = yi;
                end 
                2'd1: begin
                    x_next[2] = xi;
                    y_next[2] = yi;
                end 
                2'd2: begin
                    x_next[3] = xi;
                    y_next[3] = yi;
                end
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
        for(i = 0; i < 4; i = i + 1) begin
            x[i] <= 0;
            y[i] <= 0;
        end
        mode_reg <= 0;
    end
    else begin
        for(i = 0; i < 4; i = i + 1) begin
            x[i] <= x_next[i];
            y[i] <= y_next[i];
        end
        mode_reg <= mode_next;     
    end
end
//==============================================//
//              Calculation Block               //
//==============================================//
assign left_edge[0]  = x[0] - x[2];
assign left_edge[1]  = y[0] - y[2];
assign right_edge[0] = x[1] - x[3];
assign right_edge[1] = y[1] - y[3];
assign a = y[1] - y[0];
assign b = x[0] - x[1];
assign r1 = x[2] - x[3];
assign r2 = y[2] - y[3];

always @(*) begin
    for(i = 0; i < 8; i = i + 1) begin
        num_1[i] = 0;
    end
    for(i = 0; i < 2; i = i + 1) begin
        num_2[i] = 0;
    end
    for(i = 0; i < 2; i = i + 1) begin
        left_point_next[i]  = left_point[i];
        right_point_next[i] = right_point[i];
        delta[i] = 0;
        sub[i] = 0;
    end
    horizon_point_next  = horizon_point;
    vertical_point_next = vertical_point;
    point_tmp = 0;
    out_tmp = 0;
    out = 0;

    // mode 0 points block
    case (state)
        IN: begin
            case (input_cnt)
                2'd3: begin
                    horizon_point_next  = x[2];
                    vertical_point_next = y[2];

                    left_point_next[0]  = x[2];
                    left_point_next[1]  = x[2];
                    right_point_next[0] = x[3];
                    right_point_next[1] = x[3];
                end
                default: begin
                end
            endcase
        end
        OUT: begin
            if(horizon_point == right_point[0]) begin
                horizon_point_next  = left_point[1];
                vertical_point_next = vertical_point + 1;

                left_point_next[0]  = left_point[1];
                right_point_next[0] = right_point[1];
            end
            else begin
                horizon_point_next  = horizon_point + 1;
                vertical_point_next = vertical_point;
            end
        end
        default: begin
        end
    endcase

    // first stage multiplier
    case (state)
        IN: begin
          case (input_cnt)
            2'd0: begin
                num_1[0] = 0;
                num_1[1] = 0;
                num_1[2] = 0;
                num_1[3] = 0;
            end
            2'd1: begin
                num_1[0] = x[0];
                num_1[1] = y[1];
                num_1[2] = y[0];
                num_1[3] = x[1];                
            end 
            2'd2: begin
                if(mode_reg == 2'd1) begin
                    num_1[0] = - b;
                    num_1[1] = y[1];
                    num_1[2] = a;
                    num_1[3] = x[1];
                    num_1[4] = a;
                    num_1[5] = x[2];
                    num_1[6] = - b;
                    num_1[7] = y[2];                     
                end
                else begin
                    num_1[0] = x[1];
                    num_1[1] = y[2];
                    num_1[2] = y[1];
                    num_1[3] = x[2];                    
                end
            end
            2'd3: begin
                if(mode_reg == 2'd1) begin
                    num_1[0] = a;
                    num_1[1] = a;
                    num_1[2] = -b;
                    num_1[3] = b;
                    num_1[4] = r1;
                    num_1[5] = r1;
                    num_1[6] = -r2;
                    num_1[7] = r2;                    
                end
                else begin
                    num_1[0] = x[2];
                    num_1[1] = y[3];
                    num_1[2] = y[2];
                    num_1[3] = x[3];
                    num_1[4] = x[3];
                    num_1[5] = y[0];
                    num_1[6] = y[3];
                    num_1[7] = x[0];                    
                end
            end
            default: begin
            end
          endcase
        end
        OUT: begin
            case (predict_state)
                PREDICT_LEFT: begin
                    sub[0] = y[2];
                    sub[1] = x[2];
                    num_1[0] = left_edge[0];
                    num_1[4] = left_edge[0];
                    num_1[2] = left_edge[1];
                    num_1[6] = left_edge[1];

                    if(x[0] < x[2]) begin
                        delta[0] = -1;
                        delta[1] = 0;  
                    end
                    else begin
                        delta[0] = 0;
                        delta[1] = 1;                
                    end
                    point_tmp = left_point[0] + left_slope;
                end
                PREDICT_RIGHT: begin
                    sub[0] = y[3];
                    sub[1] = x[3];
                    num_1[0] = right_edge[0];
                    num_1[4] = right_edge[0];
                    num_1[2] = right_edge[1];
                    num_1[6] = right_edge[1];    

                    if(x[1] < x[3]) begin
                        delta[0] = -1;
                        delta[1] = 0;  
                    end
                    else begin
                        delta[0] = 0;
                        delta[1] = 1;                
                    end
                    point_tmp = right_point[0] + right_slope;
                end                    
                default: begin
                end
            endcase 
            num_1[1] = vertical_point + 1 - sub[0];
            num_1[5] = vertical_point + 1 - sub[0];            
            num_1[3] = point_tmp + delta[0] - sub[1];
            num_1[7] = point_tmp + delta[1] - sub[1];
        end 
        default: begin
        end
    endcase

    cal_1[0] = (num_1[0] * num_1[1]) - (num_1[2] * num_1[3]);
    cal_1[1] = (num_1[4] * num_1[5]) - (num_1[6] * num_1[7]);

    case (predict_state)
        PREDICT_LEFT: begin
                
            if(!cal_1[0][15]) begin
                if(!cal_1[1][15]) left_point_next[1] = num_1[7] + x[2];
                else             left_point_next[1] = num_1[3] + x[2];
            end
            else                 left_point_next[1] = num_1[3] + x[2];  
        end
        PREDICT_RIGHT : begin
            if(!cal_1[0][15]) begin
                if(!cal_1[1][15]) right_point_next[1] = num_1[7] + x[3];
                else             right_point_next[1] = num_1[3] + x[3];
            end
            else                 right_point_next[1] = num_1[3] + x[3];           
        end
        default: begin
        end
    endcase
    // corner condition 
    if(horizon_point == right_point[0] && predict_state == PREDICT_RIGHT) right_point_next[0] = right_point_next[1];
    
    // second stage multipliter
    case (state)
        IN: begin
            case (input_cnt)
                2'd2: begin
                    num_2[0] = cal_1[0] + cal_1[1];
                    num_2[1] = cal_1[0] + cal_1[1];
                    // num_1[8] = cal_1[0] + cal_1[1];
                    // num_1[9] = cal_1[0] + cal_1[1];
                end
                2'd3: begin
                    num_2[0] = cal_1[0];
                    num_2[1] = cal_1[1];
                    // num_1[8] = cal_1[0];
                    // num_1[9] = cal_1[1];                    
                end
                default: begin
                end
            endcase
        end 
        default: begin
        end
    endcase

    cal_2 = num_2[0] * num_2[1];
    // second stage multiple result register
    case (state)
        IDLE: begin
           sum_next = 0; 
        end 
        default: begin
            case (mode_reg)
            2'd1: begin
                sum_next = cal_2;
            end
            2'd2: begin
                sum_next = sum + cal_1[0] + cal_1[1];
            end 
            default: sum_next = 0;
        endcase   
        end 
    endcase

    // output selector
    case (mode_reg)
        2'd0: begin
            out[15:8] = horizon_point_next;
            out[7:0]  = vertical_point_next; 
        end
        2'd1: begin
            if(sum_next == sum)      out = 2'd2;
            else if (sum_next > sum) out = 2'd1;
            else                     out = 2'd0;
        end
        2'd2: begin
            if(sum_next[25]) out_tmp = - sum_next;
            else             out_tmp = sum_next;
            out = out_tmp >> 1;
        end 
        default: begin
            out_tmp = 0;
            out = 0;
        end
    endcase
end

reg signed[7:0] div_num [0:3];
reg signed[8:0] div_cal;
always @(*) begin
    case (state)
        IN: begin
            if(input_cnt == 2'd3) begin
                div_num[0] = x[0];
                div_num[1] = x[2];
                div_num[2] = y[0];
                div_num[3] = y[2];
            end
            else begin
                div_num[0] = x[1];
                div_num[1] = x[3];
                div_num[2] = y[1];
                div_num[3] = y[3];                
            end
        end 
        default: begin
            div_num[0] = x[1];
            div_num[1] = x[3];
            div_num[2] = y[1];
            div_num[3] = y[3];
        end
    endcase
    div_cal = ((div_num[0] - div_num[1]) / (div_num[2] - div_num[3]));
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        left_slope <= 0;
        right_slope <= 0;
    end
    else begin
        case (state)
            IN: begin
                if(input_cnt == 2'd3) begin
                    left_slope <= div_cal;
                    right_slope <= right_slope;  
                end
                else begin
                    left_slope <= left_slope;
                    right_slope <= div_cal;               
                end
            end 
            default: begin
                left_slope <= left_slope;
                right_slope <= div_cal;  
            end
        endcase
    end 
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 2; i = i + 1) begin
            left_point[i] <= 0;
            right_point[i] <= 0;
        end
        horizon_point <= 0;
        vertical_point <= 0;
    end
    else begin
        for(i = 0; i < 2; i = i + 1) begin
            left_point[i] <= left_point_next[i];
            right_point[i] <= right_point_next[i];
        end
        horizon_point <= horizon_point_next;
        vertical_point <= vertical_point_next;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sum <= 0; 
    end
    else begin
        sum <= sum_next;
    end
end
//==============================================//
//                Output Block                  //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin 
        xo <= 0;
        yo <= 0;      
        out_valid <= 0;
    end
    else begin
        xo <= out[15:8];
        yo <= out[7:0];
        out_valid <= (state_next == OUT);
    end
end
endmodule 
