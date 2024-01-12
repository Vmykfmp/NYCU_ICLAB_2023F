//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab05 Exercise		: CAD
//   Author     		: Tse-Chun Hsu
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CAD.v
//   Module Name : CAD
//   Release version : V1.0 (Release Date: 2023-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CAD(
    //Input Port
    clk,
    rst_n,
	in_valid,
    in_valid2,
    matrix,
    matrix_idx,
    matrix_size,
    mode,

    //Output Port
    out_valid,
    out_value
    );

input              clk, rst_n, in_valid, in_valid2, mode;
input signed [1:0] matrix_size;
input signed [3:0] matrix_idx;
input signed [7:0] matrix;  

output reg out_valid;
output reg out_value;
//==============================================//
//             Parameter and Integer            //
//==============================================//
parameter IDLE    = 3'd0;
parameter IN_IMG  = 3'd1;
parameter IN_KER  = 3'd2;
parameter STANDBY = 3'd3;
parameter INPUT_2 = 3'd4;
parameter PREPARE = 3'd5;
parameter COMPUTE = 3'd6;
parameter OUT     = 3'd7;

parameter SIZE_0  = 5'd7;
parameter SIZE_1  = 5'd15;
parameter SIZE_2  = 5'd31;

//==============================================//
//                 reg declaration              //
//==============================================//
reg [2:0] state;
reg [2:0] state_next;

reg [4:0] cnt_i;
reg [4:0] cnt_i_next;
reg [7:0] cnt_word;
reg [7:0] cnt_word_next;
reg [5:0] cnt_num;
reg [5:0] cnt_num_next;
reg [3:0] cnt_set;
reg [3:0] cnt_set_next;
// input register
reg mode_reg;
reg mode_next;
reg [1:0] matrix_size_reg;
reg [1:0] matrix_size_next;
reg [5:0] matrix_end_value_reg  [0:2];
reg [5:0] matrix_end_value_next [0:2];
reg [2:0] matrix_offset_reg  [0:2];
reg [2:0] matrix_offset_next [0:2];
reg [3:0] matrix_idx_reg  [0:1];
reg [3:0] matrix_idx_next [0:1]; 
// buffer register
reg signed [7:0] buffer      [0:7];
reg signed [7:0] buffer_next [0:7];
// sram contral signal
reg [10:0] addr_img;
reg [10:0] addr_img_next;
reg [2:0]  addr_img_i;
reg [10:0] addr_img_j;
reg [2:0]  addr_img_i_next;
reg [10:0] addr_img_j_next;
// reg [63:0] din_img;
// reg [63:0] din_img_next;
reg signed [63:0] dout_img;
reg WEB_img;
reg WEB_img_next;
reg [6:0] addr_ker;
reg [6:0] addr_ker_next;
reg [2:0] addr_ker_i;
reg [6:0] addr_ker_j;
reg [2:0] addr_ker_i_next;
reg [6:0] addr_ker_j_next;
// reg [39:0] din_ker;
// reg [39:0] din_ker_next;
reg signed [39:0] dout_ker;
reg WEB_ker;
reg WEB_ker_next;
// select img
reg signed [7:0] sel_img      [0:5][0:4];
reg signed [7:0] sel_img_next [0:5][0:4]; 
reg signed [7:0] sel_ker      [0:4][0:4];
reg signed [7:0] sel_ker_next [0:4][0:4];
reg signed [7:0] upd_img;

// multiple variables
reg signed [7:0]  mul_num      [0:9];
reg signed [15:0] mul_res      [0:4];
reg signed [15:0] mul_res_next [0:4];

// add variables
reg signed [19:0] add_num [0:5];
reg signed [19:0] add_res      ;

// cmp variables
reg signed [19:0] cmp_tmp [0:1];
reg signed [19:0] cmp_res      ;

// feature map register
reg signed [19:0] feature_map     [0:1][0:1];
reg signed [19:0] feature_map_next[0:1][0:1];

reg signed [19:0] output_value     ;
reg signed [19:0] output_value_next;

// output
reg out_valid_next;
reg out_value_next;

integer i, j;

//==============================================//
//            FSM State Declaration             //
//==============================================//
// FSM
always @(*) begin
    case (state)
        IDLE: begin
            if(in_valid) state_next = IN_IMG;
            else         state_next = IDLE;
        end
        IN_IMG: begin
            if(cnt_i == 3'd7 && cnt_num == 5'd15) begin
                case (matrix_size_reg)
                    0: begin
                        if(cnt_word === 8'd7) state_next = IN_KER;
                        else                  state_next = IN_IMG;
                    end 
                    1: begin
                        if(cnt_word === 8'd31) state_next = IN_KER;
                        else                   state_next = IN_IMG;
                    end
                    2: begin
                        if(cnt_word === 8'd127) state_next = IN_KER;
                        else                    state_next = IN_IMG;
                    end                
                    default: state_next = IN_IMG;
                endcase
            end
            else state_next = IN_IMG;
        end
        IN_KER: begin
            // if(cnt_word = 5'd4) state_next = WAIT;
            if(cnt_i === 3'd4 && cnt_word === 5'd4 && cnt_num === 5'd15) state_next = STANDBY;
            else                                                         state_next = IN_KER;            
        end 
        STANDBY: begin
            if(in_valid2) state_next = INPUT_2;
            else          state_next = STANDBY;
        end
        INPUT_2: begin
            // state_next = COMPUTE;    
            state_next = PREPARE;        
        end
        PREPARE: begin
            if(cnt_i == 4'd6) state_next = COMPUTE;
            else              state_next = PREPARE;
        end
        COMPUTE: begin                                                                                             state_next = COMPUTE;                
            if(!mode_reg) begin
                if(cnt_i === 4'd3 && cnt_word === matrix_end_value_reg[0] && cnt_num === matrix_end_value_reg[0]) state_next = OUT;
                else                                                                                              state_next = COMPUTE;                
            end
            else begin
                if(cnt_i === 4'd3 && cnt_word === matrix_end_value_reg[1] && cnt_num === matrix_end_value_reg[1]) state_next = OUT;
                else                                                                                              state_next = COMPUTE;                 
            end
        end
        OUT: begin
            if(cnt_i == 4'd4 && cnt_word === 8'd1 ) state_next = IDLE;
            if(!mode_reg) begin
                if(cnt_i == 4'd3 && cnt_word[0]) begin
                    if(cnt_set == 4'd15) state_next = IDLE;
                    else                 state_next = STANDBY;
                end 
                else                     state_next = OUT;                
            end
            else begin
                if(cnt_i == 4'd7) begin
                    if(cnt_set == 4'd15) state_next = IDLE;
                    else                 state_next = STANDBY;
                end 
                else                     state_next = OUT;                 
            end
        end
        // default: state_next = IDLE;
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state <= 'b0;
    else       state <= state_next;
end
// global cnt
always @(*) begin
    cnt_i_next = cnt_i;
    case (state)
        IDLE: begin
            if(in_valid) cnt_i_next = cnt_i + 1;
            else         cnt_i_next = 'b0;
        end
        IN_IMG: begin
            if(cnt_i == 3'd7) cnt_i_next = 0;
            else               cnt_i_next = cnt_i + 1;
            // if(in_valid)      cnt_i_next = cnt_i + 1;
        end
        IN_KER: begin
            if(cnt_i === 3'd4) cnt_i_next = 0;
            else              cnt_i_next = cnt_i + 1;
            // if(in_valid)      cnt_i_next = cnt_i + 1;
        end
        STANDBY: begin
            cnt_i_next = 0;
        end
        PREPARE, COMPUTE, OUT: begin
            if(!mode_reg) begin
                if(cnt_i === 4'd9) cnt_i_next = 0;
                else              cnt_i_next = cnt_i + 1;                
            end
            else begin
                if(cnt_i === 5'd19) cnt_i_next = 0;
                else               cnt_i_next = cnt_i + 1;                
            end
        end
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_i <= 'b0;
    else       cnt_i <= cnt_i_next;
end
always @(*) begin
    cnt_word_next = cnt_word;
    case (state)
        IDLE: begin
            cnt_word_next = 'b0; 
        end
        IN_IMG: begin
            if(cnt_i == 3'd7) begin
                cnt_word_next = cnt_word + 1;
                case (matrix_size_reg)
                    0: if(cnt_word == 8'd7)   cnt_word_next = 5'd0;
                    1: if(cnt_word == 8'd31)  cnt_word_next = 5'd0; 
                    2: if(cnt_word == 8'd127) cnt_word_next = 5'd0;  
                    default: begin end
                endcase                
            end
            // else cnt_word_next = cnt_word;
        end 
        IN_KER: begin
            if(cnt_i == 3'd4) begin
                if(cnt_word == 8'd4) cnt_word_next = 5'd0;
                else                 cnt_word_next = cnt_word + 1;             
            end
            // else cnt_word_next = cnt_word;
        end
        STANDBY: begin
            cnt_word_next = 0;
        end
        COMPUTE, OUT: begin
                if(cnt_i == 4'd3) begin
                    if(!mode_reg) begin
                        if(cnt_word === matrix_end_value_reg[0]) cnt_word_next = 5'd0;
                        else                                     cnt_word_next = cnt_word_next + 1;
                    end
                    else begin
                        if(cnt_word === matrix_end_value_reg[1]) cnt_word_next = 5'd0;
                        else                                     cnt_word_next = cnt_word_next + 1;
                    end
                end              
        end
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_word <= 'b0;
    else       cnt_word <= cnt_word_next;
end
always @(*) begin
    cnt_num_next = cnt_num;
    case (state)
        IDLE: begin
            cnt_num_next = 5'd0;
        end
        IN_IMG: begin
            case (matrix_size_reg)
                0: begin
                    if(cnt_word == 8'd7 && cnt_i === 3'd7) begin
                        if(cnt_num == 5'd15) cnt_num_next = 5'd0;
                        else                 cnt_num_next = cnt_num_next + 1;
                    end
                end
                1: begin
                    if(cnt_word == 8'd31 && cnt_i === 3'd7) begin
                        if(cnt_num == 5'd15) cnt_num_next = 5'd0;
                        else                 cnt_num_next = cnt_num_next + 1;
                    end
                end
                2: begin
                    if(cnt_word == 8'd127 && cnt_i === 3'd7) begin
                        if(cnt_num == 5'd15) cnt_num_next = 5'd0;
                        else                 cnt_num_next = cnt_num_next + 1;
                    end
                end                   
                default: begin end
            endcase                
            // else cnt_num_next = cnt_num;
        end 
        IN_KER: begin
            if(cnt_word === 8'd4 && cnt_i === 3'd4) begin
                if(cnt_num === 5'd15) cnt_num_next = 5'd0;
                else                  cnt_num_next = cnt_num + 1;             
            end
            // else cnt_num_next = cnt_num;
        end
        STANDBY: begin
            cnt_num_next = 5'd0;
        end
        PREPARE: begin
            if(!mode_reg) cnt_num_next = 5'd1;
            else          cnt_num_next = 5'd0;
        end
        COMPUTE: begin
            if(!mode_reg) begin
                if(cnt_word === matrix_end_value_reg[0] && cnt_i === 4'd3) begin
                    if(cnt_num === matrix_end_value_reg[0]) cnt_num_next = 5'd0;
                    else                                    cnt_num_next = cnt_num + 2;
                end                
            end
            else begin
                if(cnt_word === matrix_end_value_reg[1] && cnt_i === 4'd3) begin
                    if(cnt_num === matrix_end_value_reg[1]) cnt_num_next = 5'd0;
                    else                                    cnt_num_next = cnt_num + 1;
                end                
            end
        end
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_num <= 'b0;
    else       cnt_num <= cnt_num_next;
end
always @(*) begin
    cnt_set_next = cnt_set;
    case (state)
        IDLE: cnt_set_next = 'b0;
        OUT: begin
            if(!mode_reg) begin
                if(cnt_i == 4'd3 && cnt_word[0]) cnt_set_next = cnt_set + 1;
            end
            else begin
                if(cnt_i == 4'd7)                cnt_set_next = cnt_set + 1;
            end
            // if(!mode_reg && cnt_i == 4'd3 && cnt_word[0]) cnt_set_next = cnt_set + 1;
            // else if(cnt_i == 4'd7)                        cnt_set_next = cnt_set + 1;
        end 
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_set <= 'b0;
    else       cnt_set <= cnt_set_next;
end
//==============================================//
//                  Input Block                 //
//==============================================//
// mode register
always @(*) begin
   mode_next = mode_reg;
   case (state)
    STANDBY: begin
        if(in_valid2) mode_next = mode;
        else          mode_next = mode_reg;
    end 
    default: begin end
   endcase 
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) mode_reg <= 'b0;
    else       mode_reg <= mode_next;
end
// matrix size register
always @(*) begin
    matrix_size_next = matrix_size_reg;
    case (state)
    IDLE: begin
        if(in_valid) matrix_size_next = matrix_size;
        else         matrix_size_next = matrix_size_reg;
    end 
    default: begin end
   endcase 
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) matrix_size_reg <= 'b0;
    else       matrix_size_reg <= matrix_size_next;
end
always @(*) begin
    for(i = 0; i < 3; i = i + 1) matrix_end_value_next[i] = matrix_end_value_reg[i];
    case (state)
        IDLE: begin
            if(in_valid) begin
                case (matrix_size)
                    2'd0: begin
                        matrix_end_value_next[0] = 6'd3;
                        matrix_end_value_next[1] = 6'd11;
                        matrix_end_value_next[2] = 6'd7;
                    end
                    2'd1: begin
                        matrix_end_value_next[0] = 6'd11;
                        matrix_end_value_next[1] = 6'd19;
                        matrix_end_value_next[2] = 6'd15;
                    end
                    2'd2: begin
                        matrix_end_value_next[0] = 6'd27;
                        matrix_end_value_next[1] = 6'd35;
                        matrix_end_value_next[2] = 6'd31;
                    end
                    default: begin end
                endcase                 
            end
        end
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 3; i = i + 1) matrix_end_value_reg[i] <= 'b0;
    end
    else begin
        for(i = 0; i < 3; i = i + 1) matrix_end_value_reg[i] <= matrix_end_value_next[i];
    end
end
always @(*) begin
    for(i = 0; i < 3; i = i + 1) matrix_offset_next[i] = matrix_offset_reg[i];
    case (state)
        IDLE: begin
            if(in_valid) begin
                case (matrix_size)
                    2'd0: begin
                        matrix_offset_next[0] = 3'd1;
                        // matrix_offset_next[1] = 6'd11;
                    end
                    2'd1: begin
                        matrix_offset_next[0] = 3'd2;
                        // matrix_offset_next[1] = 6'd19;
                    end
                    2'd2: begin
                        matrix_offset_next[0] = 3'd4;
                        // matrix_offset_next[1] = 6'd35;
                    end
                    default: begin end
                endcase                
            end
        end 
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 3; i = i + 1) matrix_offset_reg[i] <= 'b0;
    end
    else begin
        for(i = 0; i < 3; i = i + 1) matrix_offset_reg[i] <= matrix_offset_next[i];
    end
end
// matrix idx register
always @(*) begin
    for(i = 0; i < 2; i = i + 1) matrix_idx_next[i] = matrix_idx_reg[i];
    case (state)
    STANDBY: begin
        if(in_valid2) matrix_idx_next[0] = matrix_idx;
        else          matrix_idx_next[0] = matrix_idx_reg[0];
    end
    INPUT_2: begin
        if(in_valid2) matrix_idx_next[1] = matrix_idx;
        else          matrix_idx_next[1] = matrix_idx_reg[1];
    end 
    default: begin end
   endcase 
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 2; i = i + 1) matrix_idx_reg[i] <= 'b0;
    end 
    else begin
        for(i = 0; i < 2; i = i + 1) matrix_idx_reg[i] <= matrix_idx_next[i];
    end
end
// img buffer
always @(*) begin
    for(i = 0; i < 8; i = i + 1) buffer_next[i] = buffer[i];
    case (state)
        IDLE: begin
            if(in_valid) buffer_next[0] = matrix;
            else         buffer_next[0] = buffer[0];
        end 
        IN_IMG: begin
            case (cnt_i)
                0: buffer_next[0] = matrix; 
                1: buffer_next[1] = matrix;
                2: buffer_next[2] = matrix;
                3: buffer_next[3] = matrix;
                4: buffer_next[4] = matrix;
                5: buffer_next[5] = matrix;
                6: buffer_next[6] = matrix;
                7: buffer_next[7] = matrix;
                default: begin end
            endcase
        end
        IN_KER: begin
            case (cnt_i)
                0: buffer_next[0] = matrix; 
                1: buffer_next[1] = matrix;
                2: buffer_next[2] = matrix;
                3: buffer_next[3] = matrix;
                4: buffer_next[4] = matrix;
                default: begin end
            endcase
        end                
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 8; i = i + 1) buffer[i] <= 'b0;
    end
    else begin
        for(i = 0; i < 8; i = i + 1) buffer[i] <= buffer_next[i];
    end
end
//==============================================//
//                  SRAM Block                  //
//==============================================//
// addr image control
// addr image i
always @(*) begin
    addr_img_i_next = addr_img_i;
    case (state)
        IDLE: begin
            addr_img_i_next = 'b0;
        end
        STANDBY: begin
            addr_img_i_next = 'b0;
        end
        PREPARE: begin
            addr_img_i_next = 'b0;
        end
        COMPUTE: begin
            if(!mode_reg) begin
                case (cnt_word)
                    0,  1,  2, 27:                  addr_img_i_next = 3'd0;
                    4,  5,  6,  7,  8,  9,  10:     addr_img_i_next = 3'd1;
                    12, 13, 14, 15, 16, 17, 18:     addr_img_i_next = 3'd2;
                    19, 20, 21, 22, 23, 24, 25, 26: addr_img_i_next = 3'd3;
                    3: begin
                        if(matrix_size_reg == 2'd0) addr_img_i_next = 3'd0;
                        else                        addr_img_i_next = 3'd1;
                    end
                    11: begin
                        if(matrix_size_reg == 2'd1) addr_img_i_next = 3'd0;
                        else                        addr_img_i_next = 3'd2;                    
                    end  
                    default: begin end
                endcase                
            end
            else begin
                case (cnt_word)
                    0,  1,  2,  3,  4,  5,  6:      addr_img_i_next = 3'd0;
                    7,  8,  9,  10, 11, 12, 13, 14: addr_img_i_next = 3'd1;                        
                    15, 16, 17, 18, 19, 20, 21, 22: addr_img_i_next = 3'd2;
                    23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35: addr_img_i_next = 3'd3;
                    default: begin end
                endcase
                if(cnt_word == matrix_end_value_reg[1]) addr_img_i_next = 'b0;
                // if(cnt_word == matrix_end_value_reg[1] && cnt_i == 5'd1) addr_img_i_next = 'b0;
            end
        end
        default: begin end
    endcase
end
// addr image j
always @(*) begin
    addr_img_j_next = addr_img_j;
    case (state)
        IDLE: begin
            addr_img_j_next = 'b0;
        end
        IN_IMG: begin
            if(!WEB_img) begin
                if(cnt_word == 8'd0) begin
                    case (matrix_size_reg)
                        0:       addr_img_j_next = addr_img_j + 121;
                        1:       addr_img_j_next = addr_img_j + 97;                       
                        default: addr_img_j_next = addr_img_j + 1;
                    endcase                    
                end
                else addr_img_j_next = addr_img_j + 1;
            end
            else addr_img_j_next = addr_img_j;
        end
        STANDBY: begin
            addr_img_j_next = 'b0;
        end 
        PREPARE: begin
            case (matrix_idx_reg[0])
                0:  addr_img_j_next = 11'd0;
                1:  addr_img_j_next = 11'd128;
                2:  addr_img_j_next = 11'd256;
                3:  addr_img_j_next = 11'd384;
                4:  addr_img_j_next = 11'd512;
                5:  addr_img_j_next = 11'd640;
                6:  addr_img_j_next = 11'd768;
                7:  addr_img_j_next = 11'd896;
                8:  addr_img_j_next = 11'd1024;
                9:  addr_img_j_next = 11'd1152;
                10: addr_img_j_next = 11'd1280;
                11: addr_img_j_next = 11'd1408;
                12: addr_img_j_next = 11'd1536;
                13: addr_img_j_next = 11'd1664;
                14: addr_img_j_next = 11'd1792;
                15: addr_img_j_next = 11'd1920;
                default: begin end
            endcase
            if(!mode_reg) begin
                case (cnt_i)
                    1, 2, 3, 4, 5: begin
                        case (matrix_size_reg)
                            0: addr_img_j_next = addr_img_j + 1;
                            1: addr_img_j_next = addr_img_j + 2;
                            2: addr_img_j_next = addr_img_j + 4;
                            default: begin end
                        endcase                    
                    end
                    6: begin
                        case (matrix_size_reg)
                            0: addr_img_j_next = addr_img_j - 5;
                            1: addr_img_j_next = addr_img_j - 10;
                            2: addr_img_j_next = addr_img_j - 20;
                            default: begin end
                        endcase                     
                    end 
                    default: begin end
                endcase                
            end
            else begin
                case (cnt_i)
                    1, 2, 3, 4, 5, 6: addr_img_j_next = addr_img_j; 
                    default: begin end
                endcase
            end
        end
        COMPUTE: begin
            if(!mode_reg) begin
                case (cnt_i)
                    7, 8, 9, 0, 1: begin
                        addr_img_j_next = addr_img_j + matrix_offset_reg[0];
                        // case (matrix_size_reg)
                        //     0: addr_img_j_next = addr_img_j + 1;
                        //     1: addr_img_j_next = addr_img_j + 2;
                        //     2: addr_img_j_next = addr_img_j + 4;
                        //     default: begin end
                        // endcase                            
                    end
                    2: begin
                        if(cnt_word === matrix_end_value_reg[0] - 1) begin
                            case (matrix_size_reg)
                                0: addr_img_j_next = addr_img_j - 3;
                                1: addr_img_j_next = addr_img_j - 6;
                                2: addr_img_j_next = addr_img_j - 12;
                                default: begin end
                            endcase                 
                        end
                        else begin
                            case (matrix_size_reg)
                                0: addr_img_j_next = addr_img_j - 5;
                                1: addr_img_j_next = addr_img_j - 10;
                                2: addr_img_j_next = addr_img_j - 20;
                                default: begin end
                            endcase                            
                        end
                    end
                    default: begin end
                endcase 
            end
            else begin
                case (cnt_i)
                    17: begin
                        // if(cnt_word === matrix_end_value_reg[1]) begin
                        //     case (cnt_num)
                        //         0, 1, 2: addr_img_j_next = addr_img_j;
                        //         3:       addr_img_j_next = addr_img_j + matrix_offset_reg[0];
                        //         default: addr_img_j_next = addr_img_j + matrix_offset_reg[0];
                        //     endcase
                        // end
                        // else 
                        // case (cnt_num)
                        case (cnt_num + (cnt_word === matrix_end_value_reg[1]))
                            0, 1, 2, 3: addr_img_j_next = addr_img_j;
                            default:    addr_img_j_next = addr_img_j + matrix_offset_reg[0];
                        endcase
                    end    
                    18: begin
                        // if(cnt_word === matrix_end_value_reg[1]) begin
                        //     case (cnt_num)
                        //         0, 1: addr_img_j_next = addr_img_j;
                        //         2, 3: addr_img_j_next = addr_img_j + matrix_offset_reg[0];
                        //         default: addr_img_j_next = addr_img_j + matrix_offset_reg[0];
                        //     endcase
                        // end
                        // case (cnt_num)
                        case (cnt_num + (cnt_word === matrix_end_value_reg[1]))
                            0, 1, 2: addr_img_j_next = addr_img_j;
                            3:       addr_img_j_next = addr_img_j + matrix_offset_reg[0];
                            default: addr_img_j_next = addr_img_j + matrix_offset_reg[0];
                        endcase
                    end
                    19: begin
                        // if(cnt_word === matrix_end_value_reg[1]) begin
                        //     case (cnt_num)
                        //         0:       addr_img_j_next = addr_img_j;
                        //         1, 2, 3: addr_img_j_next = addr_img_j + matrix_offset_reg[0];
                        //         default: addr_img_j_next = addr_img_j + matrix_offset_reg[0];
                        //     endcase
                        // end
                        // else
                        // case (cnt_num)
                        case (cnt_num + (cnt_word === matrix_end_value_reg[1]))
                            0, 1: addr_img_j_next = addr_img_j;
                            2, 3: addr_img_j_next = addr_img_j + matrix_offset_reg[0];
                            default: addr_img_j_next = addr_img_j + matrix_offset_reg[0];
                        endcase                        
                    end
                    0: begin
                        // if(cnt_word === matrix_end_value_reg[1]) begin
                        //         case (cnt_num)
                        //         // 0: addr_img_j_next = addr_img_j;
                        //         // 1: addr_img_j_next = addr_img_j - matrix_offset_reg[0];
                        //         // 2: addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0];
                        //         // 3: addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0] - matrix_offset_reg[0];
                        //         0: addr_img_j_next = addr_img_j;
                        //         1: addr_img_j_next = addr_img_j - matrix_offset_reg[0];
                        //         2: addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0];
                        //         3: addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0] - matrix_offset_reg[0];
                        //         default: begin
                        //             // addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0] - matrix_offset_reg[0] - matrix_offset_reg[0];
                        //             if(cnt_word === matrix_end_value_reg[1] - 1) addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0] - matrix_offset_reg[0];
                        //             else                                         addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0] - matrix_offset_reg[0] - matrix_offset_reg[0];
                        //         end
                        //     endcase
                        // end
                        // else
                        // case (cnt_num)
                        case (cnt_num + (cnt_word === matrix_end_value_reg[1]))
                            0:       addr_img_j_next = addr_img_j;
                            1, 2, 3: addr_img_j_next = addr_img_j + matrix_offset_reg[0];
                            default: addr_img_j_next = addr_img_j + matrix_offset_reg[0];
                        endcase
                        // if(cnt_word == matrix_size_reg[1]) addr_img_j_next = addr_img_j + matrix_offset_reg[0];                        
                    end
                    1: begin
                        // case (cnt_num)
                        case (cnt_num + (cnt_word === matrix_end_value_reg[1]))
                            
                            0: addr_img_j_next = addr_img_j;
                            1: addr_img_j_next = addr_img_j - matrix_offset_reg[0];
                            2: addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0];
                            3: addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0] - matrix_offset_reg[0];
                            // 3:begin
                            //     if(cnt_word === matrix_end_value_reg[1]) addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0];
                            //     else                                     addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0] - matrix_offset_reg[0];
                            // end
                            
                            // 0: begin
                            //     if(cnt_word == matrix_end_value_reg[1]) addr_img_j_next = addr_img_j + matrix_offset_reg[0];
                            //     else                                    addr_img_j_next = addr_img_j;
                            // end
                            // 1: begin
                            //     if(cnt_word == matrix_end_value_reg[1]) addr_img_j_next = addr_img_j;
                            //     else                                    addr_img_j_next = addr_img_j - matrix_offset_reg[0];
                            // end
                            // 2: begin
                            //     if(cnt_word == matrix_end_value_reg[1]) addr_img_j_next = addr_img_j - matrix_offset_reg[0];
                            //     else                                    addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0];
                            // end
                            // 3: begin
                            //     if(cnt_word == matrix_end_value_reg[1]) addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0];
                            //     else                                    addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0] - matrix_offset_reg[0];
                            // end
                            default: begin
                                // addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0] - matrix_offset_reg[0] - matrix_offset_reg[0];
                                if(cnt_word === matrix_end_value_reg[1] - 1) addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0] - matrix_offset_reg[0];
                                else                                     addr_img_j_next = addr_img_j - matrix_offset_reg[0] - matrix_offset_reg[0] - matrix_offset_reg[0] - matrix_offset_reg[0];
                            end
                        endcase                        
                    end
                    // matrix_end_value_reg[1] - 3:

                    // 7, 8, 9, 0, 1: begin
                    //     case (matrix_size_reg)
                    //         0: addr_img_j_next = addr_img_j + 1;
                    //         1: addr_img_j_next = addr_img_j + 2;
                    //         2: addr_img_j_next = addr_img_j + 4;
                    //         default: begin end
                    //     endcase                            
                    // end
                    // 2: begin
                    //     if(cnt_word === matrix_end_value_reg[0] - 1) begin
                    //         case (matrix_size_reg)
                    //             0: addr_img_j_next = addr_img_j - 3;
                    //             1: addr_img_j_next = addr_img_j - 6;
                    //             2: addr_img_j_next = addr_img_j - 12;
                    //             default: begin end
                    //         endcase                 
                    //     end
                    //     else begin
                    //         case (matrix_size_reg)
                    //             0: addr_img_j_next = addr_img_j - 5;
                    //             1: addr_img_j_next = addr_img_j - 10;
                    //             2: addr_img_j_next = addr_img_j - 20;
                    //             default: begin end
                    //         endcase                            
                    //     end
                    // end
                    default: begin end
                endcase
            end                                    
        end
        default: begin end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_img_i <= 'b0;
        addr_img_j <= 'b0;
    end
    else begin
        addr_img_i <= addr_img_i_next;
        addr_img_j <= addr_img_j_next;
    end
end
always @(*) begin
    addr_img = addr_img_j + addr_img_i;



    // if(mode_reg && cnt_i === 5'd0 && cnt_word === matrix_end_value_reg[1]) begin
    //     case (matrix_size_reg)
    //         0: begin
    //             if(addr_img_i === 3'd1) begin
    //                 addr_img = addr_img_j;
    //                 // $display("132");
    //             end
    //         end 
    //         1: begin
    //             if(addr_img_i === 3'd2) addr_img = addr_img_j;
    //         end
    //         2: begin
    //             if(addr_img_i === 3'd3) addr_img = addr_img_j;
    //         end
    //         default: begin end
    //     endcase
    // end
    
    // if(mode_reg && cnt_word === matrix_end_value_reg[1]) begin
    //     case (cnt_num)
    //         0: begin
    //             case (cnt_i)
    //                 17, 18, 19: begin end
    //                 0: addr_img_mul = ;
    //                 default: 
    //             endcase
    //         end
    //         default: begin end
    //     endcase
    // end

end
// addr kernal control
// addr kernal i
always @(*) begin
    addr_ker_i_next = addr_ker_i;
    case (state)
        IDLE: begin
            addr_ker_i_next = 'b0;
        end
        STANDBY: begin
            addr_ker_i_next = 'b0;
        end
        IN_KER: begin
            addr_ker_i_next = 0;
        end
        PREPARE, COMPUTE: begin
            case (cnt_i)
                0, 1, 2, 3, 4: begin
                    if(!mode_reg) addr_ker_i_next = cnt_i;
                    else          addr_ker_i_next = 4 - cnt_i;
                end
                default: begin end
            endcase
        end
        default: begin end
    endcase
end
// addr kernal j
always @(*) begin
    addr_ker_j_next = addr_ker_j;
    case (state)
        IDLE: begin
            addr_ker_j_next = 'b0;
        end
        IN_KER: begin
            if(!WEB_ker) addr_ker_j_next = addr_ker_j + 1;
            else         addr_ker_j_next = addr_ker_j;
        end
        STANDBY: begin
            addr_ker_j_next = 'b0;
        end
        PREPARE, COMPUTE: begin
            case (matrix_idx_reg[1])
                0:  addr_ker_j_next = 8'd0;
                1:  addr_ker_j_next = 8'd5;
                2:  addr_ker_j_next = 8'd10;
                3:  addr_ker_j_next = 8'd15;
                4:  addr_ker_j_next = 8'd20;
                5:  addr_ker_j_next = 8'd25;
                6:  addr_ker_j_next = 8'd30;
                7:  addr_ker_j_next = 8'd35;
                8:  addr_ker_j_next = 8'd40;
                9:  addr_ker_j_next = 8'd45;
                10: addr_ker_j_next = 8'd50;
                11: addr_ker_j_next = 8'd55;
                12: addr_ker_j_next = 8'd60;
                13: addr_ker_j_next = 8'd65;
                14: addr_ker_j_next = 8'd70;
                15: addr_ker_j_next = 8'd75;
                default: begin end
            endcase            
        end
        default: begin end
    endcase
end
always @(*) begin
    addr_ker = addr_ker_j + addr_ker_i;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_ker_i <= 'b0;
        addr_ker_j <= 'b0;
    end
    else begin
        addr_ker_i <= addr_ker_i_next;
        addr_ker_j <= addr_ker_j_next;
    end
end

wire [63:0] din_img = {buffer[0], buffer[1], buffer[2], buffer[3], buffer[4], buffer[5], buffer[6], buffer[7]};
wire [39:0] din_ker = {buffer[0], buffer[1], buffer[2], buffer[3], buffer[4]};

always @(*) begin
    // din_img = 'b0;
    // din_ker = 'b0;
    WEB_img_next = 1'b1;
    WEB_ker_next = 1'b1;
    case (state)
        IDLE: begin end
        IN_IMG: begin
            if(cnt_i == 4'd7) WEB_img_next = 1'b0;      
        end
        IN_KER: begin
            if(cnt_i == 4'd4) WEB_ker_next = 1'b0; 
        end
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        WEB_img <= 1'b1;
        WEB_ker <= 1'b1;
    end
    else begin
        WEB_img <= WEB_img_next;
        WEB_ker <= WEB_ker_next;        
    end
end

SRAM_2048x64 SRAM_IMG_U0(
    .A0  (addr_img[0]), .A1  (addr_img[1]), .A2  (addr_img[2]), .A3  (addr_img[3]), .A4  (addr_img[4]),
    .A5  (addr_img[5]), .A6  (addr_img[6]), .A7  (addr_img[7]), .A8  (addr_img[8]), .A9  (addr_img[9]), .A10(addr_img[10]),
    .DO0 (dout_img[0]), .DO1 (dout_img[1]), .DO2 (dout_img[2]), .DO3 (dout_img[3]), .DO4 (dout_img[4]), .DO5 (dout_img[5]), .DO6 (dout_img[6]), .DO7 (dout_img[7]),
    .DO8 (dout_img[8]), .DO9 (dout_img[9]), .DO10(dout_img[10]),.DO11(dout_img[11]),.DO12(dout_img[12]),.DO13(dout_img[13]),.DO14(dout_img[14]),.DO15(dout_img[15]),
    .DO16(dout_img[16]),.DO17(dout_img[17]),.DO18(dout_img[18]),.DO19(dout_img[19]),.DO20(dout_img[20]),.DO21(dout_img[21]),.DO22(dout_img[22]),.DO23(dout_img[23]),
    .DO24(dout_img[24]),.DO25(dout_img[25]),.DO26(dout_img[26]),.DO27(dout_img[27]),.DO28(dout_img[28]),.DO29(dout_img[29]),.DO30(dout_img[30]),.DO31(dout_img[31]),
    .DO32(dout_img[32]),.DO33(dout_img[33]),.DO34(dout_img[34]),.DO35(dout_img[35]),.DO36(dout_img[36]),.DO37(dout_img[37]),.DO38(dout_img[38]),.DO39(dout_img[39]),
    .DO40(dout_img[40]),.DO41(dout_img[41]),.DO42(dout_img[42]),.DO43(dout_img[43]),.DO44(dout_img[44]),.DO45(dout_img[45]),.DO46(dout_img[46]),.DO47(dout_img[47]),
    .DO48(dout_img[48]),.DO49(dout_img[49]),.DO50(dout_img[50]),.DO51(dout_img[51]),.DO52(dout_img[52]),.DO53(dout_img[53]),.DO54(dout_img[54]),.DO55(dout_img[55]),
    .DO56(dout_img[56]),.DO57(dout_img[57]),.DO58(dout_img[58]),.DO59(dout_img[59]),.DO60(dout_img[60]),.DO61(dout_img[61]),.DO62(dout_img[62]),.DO63(dout_img[63]),
    .DI0 (din_img[0]), .DI1 (din_img[1]), .DI2 (din_img[2]), .DI3 (din_img[3]), .DI4 (din_img[4]), .DI5 (din_img[5]), .DI6 (din_img[6]), .DI7 (din_img[7]),
    .DI8 (din_img[8]), .DI9 (din_img[9]), .DI10(din_img[10]),.DI11(din_img[11]),.DI12(din_img[12]),.DI13(din_img[13]),.DI14(din_img[14]),.DI15(din_img[15]),
    .DI16(din_img[16]),.DI17(din_img[17]),.DI18(din_img[18]),.DI19(din_img[19]),.DI20(din_img[20]),.DI21(din_img[21]),.DI22(din_img[22]),.DI23(din_img[23]),
    .DI24(din_img[24]),.DI25(din_img[25]),.DI26(din_img[26]),.DI27(din_img[27]),.DI28(din_img[28]),.DI29(din_img[29]),.DI30(din_img[30]),.DI31(din_img[31]),
    .DI32(din_img[32]),.DI33(din_img[33]),.DI34(din_img[34]),.DI35(din_img[35]),.DI36(din_img[36]),.DI37(din_img[37]),.DI38(din_img[38]),.DI39(din_img[39]),
    .DI40(din_img[40]),.DI41(din_img[41]),.DI42(din_img[42]),.DI43(din_img[43]),.DI44(din_img[44]),.DI45(din_img[45]),.DI46(din_img[46]),.DI47(din_img[47]),
    .DI48(din_img[48]),.DI49(din_img[49]),.DI50(din_img[50]),.DI51(din_img[51]),.DI52(din_img[52]),.DI53(din_img[53]),.DI54(din_img[54]),.DI55(din_img[55]),
    .DI56(din_img[56]),.DI57(din_img[57]),.DI58(din_img[58]),.DI59(din_img[59]),.DI60(din_img[60]),.DI61(din_img[61]),.DI62(din_img[62]),.DI63(din_img[63]),
    .CK(clk), .WEB(WEB_img), .OE(1'b1), .CS(1'b1));

SRAM_80x40   SRAM_KER_U0(
    .A0  (addr_ker[0]), .A1  (addr_ker[1]), .A2  (addr_ker[2]), .A3  (addr_ker[3]), .A4  (addr_ker[4]), .A5(addr_ker[5]),   .A6  (addr_ker[6]),
    .DO0 (dout_ker[0]), .DO1 (dout_ker[1]), .DO2 (dout_ker[2]), .DO3 (dout_ker[3]), .DO4 (dout_ker[4]), .DO5 (dout_ker[5]), .DO6 (dout_ker[6]), .DO7 (dout_ker[7]), 
    .DO8 (dout_ker[8]), .DO9 (dout_ker[9]), .DO10(dout_ker[10]),.DO11(dout_ker[11]),.DO12(dout_ker[12]),.DO13(dout_ker[13]),.DO14(dout_ker[14]),.DO15(dout_ker[15]),
    .DO16(dout_ker[16]),.DO17(dout_ker[17]),.DO18(dout_ker[18]),.DO19(dout_ker[19]),.DO20(dout_ker[20]),.DO21(dout_ker[21]),.DO22(dout_ker[22]),.DO23(dout_ker[23]),
    .DO24(dout_ker[24]),.DO25(dout_ker[25]),.DO26(dout_ker[26]),.DO27(dout_ker[27]),.DO28(dout_ker[28]),.DO29(dout_ker[29]),.DO30(dout_ker[30]),.DO31(dout_ker[31]),
    .DO32(dout_ker[32]),.DO33(dout_ker[33]),.DO34(dout_ker[34]),.DO35(dout_ker[35]),.DO36(dout_ker[36]),.DO37(dout_ker[37]),.DO38(dout_ker[38]),.DO39(dout_ker[39]),
    .DI0 (din_ker[0]), .DI1 (din_ker[1]), .DI2 (din_ker[2]), .DI3 (din_ker[3]), .DI4 (din_ker[4]), .DI5 (din_ker[5]), .DI6 (din_ker[6]), .DI7 (din_ker[7]), 
    .DI8 (din_ker[8]), .DI9 (din_ker[9]), .DI10(din_ker[10]),.DI11(din_ker[11]),.DI12(din_ker[12]),.DI13(din_ker[13]),.DI14(din_ker[14]),.DI15(din_ker[15]),
    .DI16(din_ker[16]),.DI17(din_ker[17]),.DI18(din_ker[18]),.DI19(din_ker[19]),.DI20(din_ker[20]),.DI21(din_ker[21]),.DI22(din_ker[22]),.DI23(din_ker[23]),
    .DI24(din_ker[24]),.DI25(din_ker[25]),.DI26(din_ker[26]),.DI27(din_ker[27]),.DI28(din_ker[28]),.DI29(din_ker[29]),.DI30(din_ker[30]),.DI31(din_ker[31]),
    .DI32(din_ker[32]),.DI33(din_ker[33]),.DI34(din_ker[34]),.DI35(din_ker[35]),.DI36(din_ker[36]),.DI37(din_ker[37]),.DI38(din_ker[38]),.DI39(din_ker[39]),
    .CK(clk), .WEB(WEB_ker), .OE(1'b1), .CS(1'b1));


//==============================================//
//                Select Block                  //
//==============================================//
// select image register
always @(*) begin
    case (state)
        COMPUTE: begin
            if(!mode_reg) begin
                case (cnt_word)
                    0, 8,  16, 24: upd_img = dout_img[23:16];
                    1, 9,  17, 25: upd_img = dout_img[15: 8];
                    2, 10, 18, 26: upd_img = dout_img[ 7: 0];
                    3, 11, 19, 27: upd_img = dout_img[63:56];
                    4, 12, 20:     upd_img = dout_img[55:48];
                    5, 13, 21:     upd_img = dout_img[47:40];
                    6, 14, 22:     upd_img = dout_img[39:32];
                    7, 15, 23:     upd_img = dout_img[31:24];
                    default: upd_img ='b0;
                endcase                
            end
            else begin
                if(cnt_word == matrix_end_value_reg[1])      upd_img = dout_img[63:56];     
                else if(cnt_word >= matrix_end_value_reg[2]) upd_img = 'b0;
                else begin
                    case (cnt_word)
                        0, 8,  16, 24: upd_img = dout_img[55:48];
                        1, 9,  17, 25: upd_img = dout_img[47:40];
                        2, 10, 18, 26: upd_img = dout_img[39:32];
                        3, 11, 19, 27: upd_img = dout_img[31:24];
                        4, 12, 20, 28: upd_img = dout_img[23:16];
                        5, 13, 21, 29: upd_img = dout_img[15: 8];
                        6, 14, 22, 30: upd_img = dout_img[ 7: 0];
                        7, 15, 23, 31: upd_img = dout_img[63:56];
                        default: upd_img ='b0;
                    endcase                    
                end

                if(cnt_word == matrix_end_value_reg[1]) begin
                    case (cnt_num)
                        matrix_end_value_reg[2]: begin
                            if(cnt_i === 2) upd_img = 'b0;
                            else            upd_img = dout_img[63:56];
                        end
                        matrix_end_value_reg[1] - 3: begin
                            if(cnt_i === 1) upd_img = 'b0;
                            else            upd_img = dout_img[63:56];                            
                        end
                        matrix_end_value_reg[1] - 2: begin
                            if(cnt_i === 0) upd_img = 'b0;
                            else            upd_img = dout_img[63:56];                            
                        end
                        matrix_end_value_reg[1] - 1: begin
                            if(cnt_i === 19) upd_img = 'b0;
                            else            upd_img = dout_img[63:56];                            
                        end
                        matrix_end_value_reg[1]: begin
                            if(cnt_i === 18) upd_img = 'b0;
                            else             upd_img = dout_img[63:56];                            
                        end
                        default: upd_img = dout_img[63:56];
                    endcase
                    // else upd_img = dout_img[63:56];
                end
                
            end
        end 
        default: upd_img ='b0;
    endcase
end

always @(*) begin
    for(i = 0; i < 6; i = i + 1) begin
        for(j = 0; j < 5; j = j + 1) sel_img_next[i][j] = sel_img[i][j];
    end
    case (state)
        IDLE, STANDBY: begin
            for(i = 0; i < 6; i = i + 1) begin
                for(j = 0; j < 5; j = j + 1) sel_img_next[i][j] = 'b0;
            end            
        end
        PREPARE: begin
            if(!mode_reg) begin
                case (cnt_i)
                    2: {sel_img_next[0][0], sel_img_next[0][1], sel_img_next[0][2], sel_img_next[0][3], sel_img_next[0][4]} = dout_img[63:24];
                    3: {sel_img_next[1][0], sel_img_next[1][1], sel_img_next[1][2], sel_img_next[1][3], sel_img_next[1][4]} = dout_img[63:24];
                    4: {sel_img_next[2][0], sel_img_next[2][1], sel_img_next[2][2], sel_img_next[2][3], sel_img_next[2][4]} = dout_img[63:24];
                    5: {sel_img_next[3][0], sel_img_next[3][1], sel_img_next[3][2], sel_img_next[3][3], sel_img_next[3][4]} = dout_img[63:24];
                    6: {sel_img_next[4][0], sel_img_next[4][1], sel_img_next[4][2], sel_img_next[4][3], sel_img_next[4][4]} = dout_img[63:24];
                    default: begin end
                endcase                 
            end
            else begin
                case (cnt_i)
                    // 2: {sel_img_next[0][0], sel_img_next[0][1], sel_img_next[0][2], sel_img_next[0][3], sel_img_next[0][4]} = dout_img[63:24];
                    // 3: {sel_img_next[1][0], sel_img_next[1][1], sel_img_next[1][2], sel_img_next[1][3], sel_img_next[1][4]} = dout_img[63:24];
                    // 4: {sel_img_next[2][0], sel_img_next[2][1], sel_img_next[2][2], sel_img_next[2][3], sel_img_next[2][4]} = dout_img[63:24];
                    // 5: {sel_img_next[3][0], sel_img_next[3][1], sel_img_next[3][2], sel_img_next[3][3], sel_img_next[3][4]} = dout_img[63:24];
                    // 6: {sel_img_next[4][0], sel_img_next[4][1], sel_img_next[4][2], sel_img_next[4][3], sel_img_next[4][4]} = dout_img[63:24];
                    2, 3, 4, 5, 6: sel_img_next[4][4] = dout_img[63:56];
                    default: begin end
                endcase
                // sel_img_next[4][4] = dout_img[63:56];
            end
        end
        COMPUTE: begin
            if(!mode_reg) begin
                if(cnt_word[4:0] === matrix_end_value_reg[0]) begin
                    case (cnt_i)
                        8: {sel_img_next[0][0], sel_img_next[0][1], sel_img_next[0][2], sel_img_next[0][3], sel_img_next[0][4]} = dout_img[63:24];
                        9: {sel_img_next[1][0], sel_img_next[1][1], sel_img_next[1][2], sel_img_next[1][3], sel_img_next[1][4]} = dout_img[63:24];
                        0: {sel_img_next[2][0], sel_img_next[2][1], sel_img_next[2][2], sel_img_next[2][3], sel_img_next[2][4]} = dout_img[63:24];
                        1: {sel_img_next[3][0], sel_img_next[3][1], sel_img_next[3][2], sel_img_next[3][3], sel_img_next[3][4]} = dout_img[63:24];
                        2: {sel_img_next[4][0], sel_img_next[4][1], sel_img_next[4][2], sel_img_next[4][3], sel_img_next[4][4]} = dout_img[63:24];
                        3: {sel_img_next[5][0], sel_img_next[5][1], sel_img_next[5][2], sel_img_next[5][3], sel_img_next[5][4]} = dout_img[63:24];
                        default: begin end
                    endcase                
                end
                else begin
                    case (cnt_i)
                        7: if(cnt_num === 1 && cnt_word === 11'd0) {sel_img_next[5][0], sel_img_next[5][1], sel_img_next[5][2], sel_img_next[5][3], sel_img_next[5][4]} = dout_img[63:24];
                        8: {sel_img_next[0][0], sel_img_next[0][1], sel_img_next[0][2], sel_img_next[0][3], sel_img_next[0][4]} = {sel_img[0][1], sel_img[0][2], sel_img[0][3], sel_img[0][4], upd_img};
                        9: {sel_img_next[1][0], sel_img_next[1][1], sel_img_next[1][2], sel_img_next[1][3], sel_img_next[1][4]} = {sel_img[1][1], sel_img[1][2], sel_img[1][3], sel_img[1][4], upd_img};
                        0: {sel_img_next[2][0], sel_img_next[2][1], sel_img_next[2][2], sel_img_next[2][3], sel_img_next[2][4]} = {sel_img[2][1], sel_img[2][2], sel_img[2][3], sel_img[2][4], upd_img};
                        1: {sel_img_next[3][0], sel_img_next[3][1], sel_img_next[3][2], sel_img_next[3][3], sel_img_next[3][4]} = {sel_img[3][1], sel_img[3][2], sel_img[3][3], sel_img[3][4], upd_img};
                        2: {sel_img_next[4][0], sel_img_next[4][1], sel_img_next[4][2], sel_img_next[4][3], sel_img_next[4][4]} = {sel_img[4][1], sel_img[4][2], sel_img[4][3], sel_img[4][4], upd_img};
                        3: {sel_img_next[5][0], sel_img_next[5][1], sel_img_next[5][2], sel_img_next[5][3], sel_img_next[5][4]} = {sel_img[5][1], sel_img[5][2], sel_img[5][3], sel_img[5][4], upd_img};
                        default: begin end
                    endcase                 
                end                
            end
            else begin
                case (cnt_num)
                    0: begin
                        case (cnt_i)
                            1: if(cnt_word == matrix_end_value_reg[1])
                               {sel_img_next[3][0], sel_img_next[3][1], sel_img_next[3][2], sel_img_next[3][3], sel_img_next[3][4]} = {sel_img[3][1], sel_img[3][2], sel_img[3][3], sel_img[3][4], upd_img};    
                            2: {sel_img_next[4][0], sel_img_next[4][1], sel_img_next[4][2], sel_img_next[4][3], sel_img_next[4][4]} = {sel_img[4][1], sel_img[4][2], sel_img[4][3], sel_img[4][4], upd_img};
                            default: begin end
                        endcase
                    end
                    1: begin
                        case (cnt_i)
                            0: if(cnt_word == matrix_end_value_reg[1])
                               {sel_img_next[2][0], sel_img_next[2][1], sel_img_next[2][2], sel_img_next[2][3], sel_img_next[2][4]} = {sel_img[2][1], sel_img[2][2], sel_img[2][3], sel_img[2][4], upd_img}; 
                            1: {sel_img_next[3][0], sel_img_next[3][1], sel_img_next[3][2], sel_img_next[3][3], sel_img_next[3][4]} = {sel_img[3][1], sel_img[3][2], sel_img[3][3], sel_img[3][4], upd_img};    
                            2: {sel_img_next[4][0], sel_img_next[4][1], sel_img_next[4][2], sel_img_next[4][3], sel_img_next[4][4]} = {sel_img[4][1], sel_img[4][2], sel_img[4][3], sel_img[4][4], upd_img};
                            default: begin end
                        endcase
                    end                     
                    2: begin
                        case (cnt_i)
                            19: if(cnt_word == matrix_end_value_reg[1])
                               {sel_img_next[1][0], sel_img_next[1][1], sel_img_next[1][2], sel_img_next[1][3], sel_img_next[1][4]} = {sel_img[1][1], sel_img[1][2], sel_img[1][3], sel_img[1][4], upd_img}; 
                            0: {sel_img_next[2][0], sel_img_next[2][1], sel_img_next[2][2], sel_img_next[2][3], sel_img_next[2][4]} = {sel_img[2][1], sel_img[2][2], sel_img[2][3], sel_img[2][4], upd_img}; 
                            1: {sel_img_next[3][0], sel_img_next[3][1], sel_img_next[3][2], sel_img_next[3][3], sel_img_next[3][4]} = {sel_img[3][1], sel_img[3][2], sel_img[3][3], sel_img[3][4], upd_img};    
                            2: {sel_img_next[4][0], sel_img_next[4][1], sel_img_next[4][2], sel_img_next[4][3], sel_img_next[4][4]} = {sel_img[4][1], sel_img[4][2], sel_img[4][3], sel_img[4][4], upd_img};
                            default: begin end
                        endcase
                    end
                    3: begin
                        case (cnt_i)
                            18: if(cnt_word == matrix_end_value_reg[1])
                                {sel_img_next[0][0], sel_img_next[0][1], sel_img_next[0][2], sel_img_next[0][3], sel_img_next[0][4]} = {sel_img[0][1], sel_img[0][2], sel_img[0][3], sel_img[0][4], upd_img};
                            19: {sel_img_next[1][0], sel_img_next[1][1], sel_img_next[1][2], sel_img_next[1][3], sel_img_next[1][4]} = {sel_img[1][1], sel_img[1][2], sel_img[1][3], sel_img[1][4], upd_img}; 
                            0:  {sel_img_next[2][0], sel_img_next[2][1], sel_img_next[2][2], sel_img_next[2][3], sel_img_next[2][4]} = {sel_img[2][1], sel_img[2][2], sel_img[2][3], sel_img[2][4], upd_img}; 
                            1:  {sel_img_next[3][0], sel_img_next[3][1], sel_img_next[3][2], sel_img_next[3][3], sel_img_next[3][4]} = {sel_img[3][1], sel_img[3][2], sel_img[3][3], sel_img[3][4], upd_img};    
                            2:  {sel_img_next[4][0], sel_img_next[4][1], sel_img_next[4][2], sel_img_next[4][3], sel_img_next[4][4]} = {sel_img[4][1], sel_img[4][2], sel_img[4][3], sel_img[4][4], upd_img};
                            default: begin end
                        endcase
                    end
                    matrix_end_value_reg[1] - 3: begin
                        case (cnt_i)
                            18: {sel_img_next[0][0], sel_img_next[0][1], sel_img_next[0][2], sel_img_next[0][3], sel_img_next[0][4]} = {sel_img[0][1], sel_img[0][2], sel_img[0][3], sel_img[0][4], upd_img}; 
                            19: {sel_img_next[1][0], sel_img_next[1][1], sel_img_next[1][2], sel_img_next[1][3], sel_img_next[1][4]} = {sel_img[1][1], sel_img[1][2], sel_img[1][3], sel_img[1][4], upd_img}; 
                            0:  {sel_img_next[2][0], sel_img_next[2][1], sel_img_next[2][2], sel_img_next[2][3], sel_img_next[2][4]} = {sel_img[2][1], sel_img[2][2], sel_img[2][3], sel_img[2][4], upd_img}; 
                            1:  {sel_img_next[3][0], sel_img_next[3][1], sel_img_next[3][2], sel_img_next[3][3], sel_img_next[3][4]} = {sel_img[3][1], sel_img[3][2], sel_img[3][3], sel_img[3][4], upd_img};    
                            2:  {sel_img_next[4][0], sel_img_next[4][1], sel_img_next[4][2], sel_img_next[4][3], sel_img_next[4][4]} = {sel_img[4][1], sel_img[4][2], sel_img[4][3], sel_img[4][4], 'b0};
                            default: begin end
                        endcase                        
                    end
                    matrix_end_value_reg[1] - 2: begin
                        case (cnt_i)
                            18: {sel_img_next[0][0], sel_img_next[0][1], sel_img_next[0][2], sel_img_next[0][3], sel_img_next[0][4]} = {sel_img[0][1], sel_img[0][2], sel_img[0][3], sel_img[0][4], upd_img}; 
                            19: {sel_img_next[1][0], sel_img_next[1][1], sel_img_next[1][2], sel_img_next[1][3], sel_img_next[1][4]} = {sel_img[1][1], sel_img[1][2], sel_img[1][3], sel_img[1][4], upd_img}; 
                            0:  {sel_img_next[2][0], sel_img_next[2][1], sel_img_next[2][2], sel_img_next[2][3], sel_img_next[2][4]} = {sel_img[2][1], sel_img[2][2], sel_img[2][3], sel_img[2][4], upd_img}; 
                            1:  {sel_img_next[3][0], sel_img_next[3][1], sel_img_next[3][2], sel_img_next[3][3], sel_img_next[3][4]} = {sel_img[3][1], sel_img[3][2], sel_img[3][3], sel_img[3][4], 'b0};    
                            2:  {sel_img_next[4][0], sel_img_next[4][1], sel_img_next[4][2], sel_img_next[4][3], sel_img_next[4][4]} = {sel_img[4][1], sel_img[4][2], sel_img[4][3], sel_img[4][4], 'b0};
                        default: begin end
                    endcase
                    end
                    matrix_end_value_reg[1] - 1: begin
                        case (cnt_i)
                            18: {sel_img_next[0][0], sel_img_next[0][1], sel_img_next[0][2], sel_img_next[0][3], sel_img_next[0][4]} = {sel_img[0][1], sel_img[0][2], sel_img[0][3], sel_img[0][4], upd_img}; 
                            19: {sel_img_next[1][0], sel_img_next[1][1], sel_img_next[1][2], sel_img_next[1][3], sel_img_next[1][4]} = {sel_img[1][1], sel_img[1][2], sel_img[1][3], sel_img[1][4], upd_img}; 
                            0:  {sel_img_next[2][0], sel_img_next[2][1], sel_img_next[2][2], sel_img_next[2][3], sel_img_next[2][4]} = {sel_img[2][1], sel_img[2][2], sel_img[2][3], sel_img[2][4], 'b0}; 
                            1:  {sel_img_next[3][0], sel_img_next[3][1], sel_img_next[3][2], sel_img_next[3][3], sel_img_next[3][4]} = {sel_img[3][1], sel_img[3][2], sel_img[3][3], sel_img[3][4], 'b0};    
                            2:  {sel_img_next[4][0], sel_img_next[4][1], sel_img_next[4][2], sel_img_next[4][3], sel_img_next[4][4]} = {sel_img[4][1], sel_img[4][2], sel_img[4][3], sel_img[4][4], 'b0};
                        default: begin end
                    endcase
                    end
                    matrix_end_value_reg[1]: begin
                        case (cnt_i)
                        18: {sel_img_next[0][0], sel_img_next[0][1], sel_img_next[0][2], sel_img_next[0][3], sel_img_next[0][4]} = {sel_img[0][1], sel_img[0][2], sel_img[0][3], sel_img[0][4], upd_img}; 
                        19: {sel_img_next[1][0], sel_img_next[1][1], sel_img_next[1][2], sel_img_next[1][3], sel_img_next[1][4]} = {sel_img[1][1], sel_img[1][2], sel_img[1][3], sel_img[1][4], 'b0}; 
                        0:  {sel_img_next[2][0], sel_img_next[2][1], sel_img_next[2][2], sel_img_next[2][3], sel_img_next[2][4]} = {sel_img[2][1], sel_img[2][2], sel_img[2][3], sel_img[2][4], 'b0}; 
                        1:  {sel_img_next[3][0], sel_img_next[3][1], sel_img_next[3][2], sel_img_next[3][3], sel_img_next[3][4]} = {sel_img[3][1], sel_img[3][2], sel_img[3][3], sel_img[3][4], 'b0};    
                        2:  {sel_img_next[4][0], sel_img_next[4][1], sel_img_next[4][2], sel_img_next[4][3], sel_img_next[4][4]} = {sel_img[4][1], sel_img[4][2], sel_img[4][3], sel_img[4][4], 'b0};
                        default: begin end
                    endcase
                    end
                    // 1: begin
                    //     case (cnt_i)
                    //         1: {sel_img_next[4][0], sel_img_next[4][1], sel_img_next[4][2], sel_img_next[4][3], sel_img_next[4][4]} = {sel_img_next[4][1], sel_img_next[4][2], sel_img_next[4][3], sel_img_next[4][4], dout_img[63:56]};
                    //         default: begin end
                    //     endcase                        
                    // end
                    default: begin 
                        case (cnt_i)
                            18: {sel_img_next[0][0], sel_img_next[0][1], sel_img_next[0][2], sel_img_next[0][3], sel_img_next[0][4]} = {sel_img[0][1], sel_img[0][2], sel_img[0][3], sel_img[0][4], upd_img}; 
                            19: {sel_img_next[1][0], sel_img_next[1][1], sel_img_next[1][2], sel_img_next[1][3], sel_img_next[1][4]} = {sel_img[1][1], sel_img[1][2], sel_img[1][3], sel_img[1][4], upd_img}; 
                            0:  {sel_img_next[2][0], sel_img_next[2][1], sel_img_next[2][2], sel_img_next[2][3], sel_img_next[2][4]} = {sel_img[2][1], sel_img[2][2], sel_img[2][3], sel_img[2][4], upd_img}; 
                            1:  {sel_img_next[3][0], sel_img_next[3][1], sel_img_next[3][2], sel_img_next[3][3], sel_img_next[3][4]} = {sel_img[3][1], sel_img[3][2], sel_img[3][3], sel_img[3][4], upd_img};    
                            2:  begin
                                    if(cnt_word == matrix_end_value_reg[1] && cnt_num == matrix_end_value_reg[2])
                                         {sel_img_next[4][0], sel_img_next[4][1], sel_img_next[4][2], sel_img_next[4][3], sel_img_next[4][4]} = {sel_img[4][1], sel_img[4][2], sel_img[4][3], sel_img[4][4], 'b0};
                                    else {sel_img_next[4][0], sel_img_next[4][1], sel_img_next[4][2], sel_img_next[4][3], sel_img_next[4][4]} = {sel_img[4][1], sel_img[4][2], sel_img[4][3], sel_img[4][4], upd_img};
                                end
                            default: begin end
                        endcase
                    end
                endcase
            end
        end 
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 6; i = i + 1) begin
            for(j = 0; j < 5; j = j + 1) sel_img[i][j] <= 'b0;
        end       
    end
    else begin
        for(i = 0; i < 6; i = i + 1) begin
            for(j = 0; j < 5; j = j + 1) sel_img[i][j] <= sel_img_next[i][j];
        end         
    end
end
// select kernal register
always @(*) begin
    for(i = 0; i < 5; i = i + 1) begin
        for(j = 0; j < 5; j = j + 1) sel_ker_next[i][j] = sel_ker[i][j];
    end
    case (state)
        PREPARE, COMPUTE: begin
            if(!mode_reg) begin
                case (cnt_i)
                    2: {sel_ker_next[0][0], sel_ker_next[0][1], sel_ker_next[0][2], sel_ker_next[0][3], sel_ker_next[0][4]} = dout_ker;
                    3: {sel_ker_next[1][0], sel_ker_next[1][1], sel_ker_next[1][2], sel_ker_next[1][3], sel_ker_next[1][4]} = dout_ker;
                    4: {sel_ker_next[2][0], sel_ker_next[2][1], sel_ker_next[2][2], sel_ker_next[2][3], sel_ker_next[2][4]} = dout_ker;
                    5: {sel_ker_next[3][0], sel_ker_next[3][1], sel_ker_next[3][2], sel_ker_next[3][3], sel_ker_next[3][4]} = dout_ker;
                    6: {sel_ker_next[4][0], sel_ker_next[4][1], sel_ker_next[4][2], sel_ker_next[4][3], sel_ker_next[4][4]} = dout_ker;
                    default: begin end
                endcase                
            end
            else begin
                case (cnt_i)
                    2: {sel_ker_next[0][4], sel_ker_next[0][3], sel_ker_next[0][2], sel_ker_next[0][1], sel_ker_next[0][0]} = dout_ker;
                    3: {sel_ker_next[1][4], sel_ker_next[1][3], sel_ker_next[1][2], sel_ker_next[1][1], sel_ker_next[1][0]} = dout_ker;
                    4: {sel_ker_next[2][4], sel_ker_next[2][3], sel_ker_next[2][2], sel_ker_next[2][1], sel_ker_next[2][0]} = dout_ker;
                    5: {sel_ker_next[3][4], sel_ker_next[3][3], sel_ker_next[3][2], sel_ker_next[3][1], sel_ker_next[3][0]} = dout_ker;
                    6: {sel_ker_next[4][4], sel_ker_next[4][3], sel_ker_next[4][2], sel_ker_next[4][1], sel_ker_next[4][0]} = dout_ker;
                    default: begin end
                endcase                
            end
        end 
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            for(j = 0; j < 5; j = j + 1) sel_ker[i][j] <= 'b0;
        end       
    end
    else begin
        for(i = 0; i < 5; i = i + 1) begin
            for(j = 0; j < 5; j = j + 1) sel_ker[i][j] <= sel_ker_next[i][j];
        end         
    end
end
//==============================================//
//              Calculation Block               //
//==============================================//
// multiple
always @(*) begin
    for(int i = 0; i < 10; i = i + 1) mul_num[i] = 'b0;
    case (state)
        PREPARE ,COMPUTE: begin
            case (cnt_i)
                3: begin
                    mul_num[0] = sel_img[0][0];
                    mul_num[1] = sel_img[0][1];
                    mul_num[2] = sel_img[0][2];
                    mul_num[3] = sel_img[0][3];
                    mul_num[4] = sel_img[0][4];                   
                end 
                4, 8: begin
                    mul_num[0] = sel_img[1][0];
                    mul_num[1] = sel_img[1][1];
                    mul_num[2] = sel_img[1][2];
                    mul_num[3] = sel_img[1][3];
                    mul_num[4] = sel_img[1][4];                   
                end
                5, 9: begin
                    mul_num[0] = sel_img[2][0];
                    mul_num[1] = sel_img[2][1];
                    mul_num[2] = sel_img[2][2];
                    mul_num[3] = sel_img[2][3];
                    mul_num[4] = sel_img[2][4];                   
                end 
                6, 0: begin
                    mul_num[0] = sel_img[3][0];
                    mul_num[1] = sel_img[3][1];
                    mul_num[2] = sel_img[3][2];
                    mul_num[3] = sel_img[3][3];
                    mul_num[4] = sel_img[3][4];                   
                end
                7, 1: begin
                    mul_num[0] = sel_img[4][0];
                    mul_num[1] = sel_img[4][1];
                    mul_num[2] = sel_img[4][2];
                    mul_num[3] = sel_img[4][3];
                    mul_num[4] = sel_img[4][4];                   
                end 
                2: begin
                    mul_num[0] = sel_img[5][0];
                    mul_num[1] = sel_img[5][1];
                    mul_num[2] = sel_img[5][2];
                    mul_num[3] = sel_img[5][3];
                    mul_num[4] = sel_img[5][4];                   
                end
                default: begin end
            endcase
        end 
        default: begin end
    endcase

    case (state)
    PREPARE, COMPUTE: begin
        case (cnt_i)
            3, 8: begin
                mul_num[5] = sel_ker[0][0];
                mul_num[6] = sel_ker[0][1];
                mul_num[7] = sel_ker[0][2];
                mul_num[8] = sel_ker[0][3];
                mul_num[9] = sel_ker[0][4];                    
            end 
            4, 9: begin
                mul_num[5] = sel_ker[1][0];
                mul_num[6] = sel_ker[1][1];
                mul_num[7] = sel_ker[1][2];
                mul_num[8] = sel_ker[1][3];
                mul_num[9] = sel_ker[1][4];                    
            end
            5, 0: begin
                mul_num[5] = sel_ker[2][0];
                mul_num[6] = sel_ker[2][1];
                mul_num[7] = sel_ker[2][2];
                mul_num[8] = sel_ker[2][3];
                mul_num[9] = sel_ker[2][4];                    
            end 
            6, 1: begin
                mul_num[5] = sel_ker[3][0];
                mul_num[6] = sel_ker[3][1];
                mul_num[7] = sel_ker[3][2];
                mul_num[8] = sel_ker[3][3];
                mul_num[9] = sel_ker[3][4];                    
            end
            7, 2: begin
                mul_num[5] = sel_ker[4][0];
                mul_num[6] = sel_ker[4][1];
                mul_num[7] = sel_ker[4][2];
                mul_num[8] = sel_ker[4][3];
                mul_num[9] = sel_ker[4][4];                    
            end 
            default: begin end
        endcase
    end 
    default: begin end
endcase

    mul_res_next[0] = mul_num[0] * mul_num[5];
    mul_res_next[1] = mul_num[1] * mul_num[6];
    mul_res_next[2] = mul_num[2] * mul_num[7];
    mul_res_next[3] = mul_num[3] * mul_num[8];
    mul_res_next[4] = mul_num[4] * mul_num[9];
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 5; i = i + 1) mul_res[i] <= 'b0;
    end
    else begin
        for(i = 0; i < 5; i = i + 1) mul_res[i] <= mul_res_next[i];
    end
end
// adder
always @(*) begin
    for(i = 0; i < 6; i = i + 1) add_num[i] = 'b0;
    case (state)
        PREPARE, COMPUTE: begin
            add_num[0] = mul_res[0];
            add_num[1] = mul_res[1];
            add_num[2] = mul_res[2];
            add_num[3] = mul_res[3];
            add_num[4] = mul_res[4];

            if(!cnt_word[0]) begin
                case (cnt_i)
                    4, 9: add_num[5] = 'b0;
                    5, 6, 7, 8: add_num[5] = feature_map[0][0];
                    0, 1, 2, 3: add_num[5] = feature_map[1][0];
                    default: begin end
                endcase                
            end
            else begin
                case (cnt_i)
                    4, 9: add_num[5] = 'b0;
                    5, 6, 7, 8: add_num[5] = feature_map[0][1];
                    0, 1, 2, 3: add_num[5] = feature_map[1][1];
                    default: begin end
                endcase                
            end
        end 
        default: begin end 
    endcase

    add_res = (add_num[0] + add_num[1]) + (add_num[2] + add_num[3]) + (add_num[4] + add_num[5]);
end
// feature map
always @(*) begin
    for(i = 0; i < 2; i = i + 1) begin
        for(j = 0; j < 2; j = j + 1) feature_map_next[i][j] = feature_map[i][j];
    end

    case (state)
        IDLE: begin
            for(i = 0; i < 2; i = i + 1) begin
                for(j = 0; j < 2; j = j + 1) feature_map_next[i][j] = 'b0;
            end            
        end
        PREPARE, COMPUTE: begin
            if(!cnt_word[0]) begin
                case (cnt_i)
                    4, 5, 6, 7, 8: feature_map_next[0][0] = add_res;
                    9, 0, 1, 2, 3: feature_map_next[1][0] = add_res;
                    default: begin end
                endcase                
            end
            else begin
                case (cnt_i)
                    4, 5, 6, 7, 8: feature_map_next[0][1] = add_res;
                    9, 0, 1, 2, 3: feature_map_next[1][1] = add_res;
                    default: begin end
                endcase                
            end            
        end
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 2; i = i + 1) begin
            for(j = 0; j < 2; j = j + 1) feature_map[i][j] <= 'b0;
        end
    end
    else begin
        for(i = 0; i < 2; i = i + 1) begin
            for(j = 0; j < 2; j = j + 1) feature_map[i][j] <= feature_map_next[i][j];
        end    
    end
end
always @(*) begin
    for(i = 0; i < 2; i = i + 1) cmp_tmp[i] = 'b0;
    cmp_res = 'b0;

    case (state)
        COMPUTE: begin
            if(cnt_i == 5'd3) begin
                cmp_tmp[0] = (feature_map[0][0] > feature_map[1][0]) ? feature_map[0][0] : feature_map[1][0];
                cmp_tmp[1] = (feature_map[0][1] > feature_map_next[1][1]) ? feature_map[0][1] : feature_map_next[1][1];
                cmp_res = (cmp_tmp[0] > cmp_tmp[1]) ? cmp_tmp[0] : cmp_tmp[1];
            end
        end
        default: begin end
    endcase
end
always @(*) begin
    output_value_next = output_value;
    case (state)
        IDLE: begin
            output_value_next = 'b0;
        end
        COMPUTE: begin
            // if(cnt_i == 5'd3 && cnt_word[0]) output_value_next = cmp_res;
            if(!mode_reg) begin
                if(cnt_i == 5'd3 && cnt_word[0]) output_value_next = cmp_res;
            end
            else begin
                if(cnt_i == 5'd8)                output_value_next = add_res;
            end
        end
    default: begin end
endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) output_value <= 'b0;
    else       output_value <= output_value_next;
end
//==============================================//
//                Output Block                  //
//==============================================//
always @(*) begin
    out_valid_next = 'b0;
    out_value_next = 'b0;
    case (state)
        IDLE: begin
            out_valid_next = 'b0;
            out_value_next = 'b0;           
        end
        COMPUTE, OUT: begin
            // out_valid_next = 'b0;
            // out_value_next = 'b0;
            if(!mode_reg) begin
                if(cnt_word[7:1] !== 7'd0 || cnt_num !== 5'd1) begin
                    out_valid_next = 1'd1;
                    if(!cnt_word[0]) begin
                        case (cnt_i)
                            4: out_value_next = output_value[0];
                            5: out_value_next = output_value[1];
                            6: out_value_next = output_value[2];
                            7: out_value_next = output_value[3];
                            8: out_value_next = output_value[4];
                            9: out_value_next = output_value[5];
                            0: out_value_next = output_value[6];
                            1: out_value_next = output_value[7];
                            2: out_value_next = output_value[8];
                            3: out_value_next = output_value[9];
                            default: begin end
                        endcase                
                    end
                    else begin
                        case (cnt_i)
                            4: out_value_next = output_value[10];
                            5: out_value_next = output_value[11];
                            6: out_value_next = output_value[12];
                            7: out_value_next = output_value[13];
                            8: out_value_next = output_value[14];
                            9: out_value_next = output_value[15];
                            0: out_value_next = output_value[16];
                            1: out_value_next = output_value[17];
                            2: out_value_next = output_value[18];
                            3: out_value_next = output_value[19];
                            default: begin end
                        endcase                
                    end                 
                end                
            end
            else begin
                if(state !== COMPUTE || cnt_i !== 8'd7 || cnt_word !== 8'd0 || cnt_num !== 5'd0) begin
                    out_valid_next = 1'd1;
                    case (cnt_i)
                        8:  out_value_next = add_res[0];
                        9:  out_value_next = output_value[1];
                        10: out_value_next = output_value[2];
                        11: out_value_next = output_value[3];
                        12: out_value_next = output_value[4];
                        13: out_value_next = output_value[5];
                        14: out_value_next = output_value[6];
                        15: out_value_next = output_value[7];
                        16: out_value_next = output_value[8];
                        17: out_value_next = output_value[9];
                        18: out_value_next = output_value[10];
                        19: out_value_next = output_value[11];
                        0:  out_value_next = output_value[12];
                        1:  out_value_next = output_value[13];
                        2:  out_value_next = output_value[14];
                        3:  out_value_next = output_value[15];
                        4:  out_value_next = output_value[16];
                        5:  out_value_next = output_value[17];
                        6:  out_value_next = output_value[18];
                        7:  out_value_next = output_value[19]; 
                        default: begin end
                    endcase
                end
            end
        end 
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 'b0;
        out_value <= 'b0;
    end
    else begin
        out_valid <= out_valid_next;
        out_value <= out_value_next;
    end
end

endmodule