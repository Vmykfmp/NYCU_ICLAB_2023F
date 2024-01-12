//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Siamese Neural Network
//   Author     		: Tse-Chun Hsu
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SNN.v
//   Module Name : SNN
//   Release version : V1.0 (Release Date: 2023-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );


//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel, Weight;
input [1:0] Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;


parameter IDLE = 3'd0;
parameter EXE = 3'd1;
parameter OUT = 3'd2;

integer i, j, k;

// conuter
reg [3:0] cnt;
reg [3:0] cnt_next;
reg [6:0] loop;
reg [6:0] loop_next;

// output 
reg out_valid_next;
reg [inst_sig_width + inst_exp_width:0] out_next;

// convolution
// reg [inst_sig_width + inst_exp_width:0] image_mem [0:15];
// reg [inst_sig_width + inst_exp_width:0] image_mem_next [0:15];
// reg [inst_sig_width + inst_exp_width:0] kernel_mem1 [0:8];
// reg [inst_sig_width + inst_exp_width:0] kernel_mem2 [0:8];
// reg [inst_sig_width + inst_exp_width:0] kernel_mem3 [0:8];
// reg [inst_sig_width + inst_exp_width:0] kernel_mem1_next [0:8];
// reg [inst_sig_width + inst_exp_width:0] kernel_mem2_next [0:8];
// reg [inst_sig_width + inst_exp_width:0] kernel_mem3_next [0:8];
// reg [inst_sig_width + inst_exp_width:0] weight_mem  [0:3];
// reg [inst_sig_width + inst_exp_width:0] weight_mem_next  [0:3];

reg [2:0] state;
reg [2:0] state_next;

reg [1:0] option_reg;
reg [1:0] option_reg_next;
reg [inst_sig_width + inst_exp_width:0] image_mem [0:3][0:3];
reg [inst_sig_width + inst_exp_width:0] image_mem_next [0:3][0:3];
reg [inst_sig_width + inst_exp_width:0] kernel_mem [0:2][0:2][0:2];
reg [inst_sig_width + inst_exp_width:0] kernel_mem_next [0:2][0:2][0:2];
// reg [inst_sig_width + inst_exp_width:0] kernel_mem1 [0:2][0:2];
// reg [inst_sig_width + inst_exp_width:0] kernel_mem2 [0:2][0:2];
// reg [inst_sig_width + inst_exp_width:0] kernel_mem3 [0:2][0:2];
// reg [inst_sig_width + inst_exp_width:0] kernel_mem1_next [0:2][0:2];
// reg [inst_sig_width + inst_exp_width:0] kernel_mem2_next [0:2][0:2];
// reg [inst_sig_width + inst_exp_width:0] kernel_mem3_next [0:2][0:2];
reg [inst_sig_width + inst_exp_width:0] weight_mem  [0:1][0:1];
reg [inst_sig_width + inst_exp_width:0] weight_mem_next  [0:1][0:1];

reg [inst_sig_width + inst_exp_width:0] feature_map [0:1][0:3][0:3];
reg [inst_sig_width + inst_exp_width:0] feature_map_next [0:1][0:3][0:3];

reg [inst_sig_width + inst_exp_width:0] equalization [0:1][0:3][0:3];
reg [inst_sig_width + inst_exp_width:0] equalization_next [0:1][0:3][0:3];

reg [inst_sig_width + inst_exp_width:0] max_pooling [0:1][0:1][0:1];
reg [inst_sig_width + inst_exp_width:0] max_pooling_next [0:1][0:1][0:1];

reg [inst_sig_width + inst_exp_width:0] fully_connect [0:1][0:3];
reg [inst_sig_width + inst_exp_width:0] fully_connect_next [0:1][0:3];

reg [inst_sig_width + inst_exp_width:0] normaliztion [0:1][0:3];
reg [inst_sig_width + inst_exp_width:0] normaliztion_next [0:1][0:3];

// dot3 variables
reg [inst_sig_width + inst_exp_width:0] dot_num [0:8];
reg [inst_sig_width + inst_exp_width:0] dot_ker [0:8];
reg [inst_sig_width + inst_exp_width:0] dot_res [0:2];
reg [inst_sig_width + inst_exp_width:0] dot_res_next [0:2];

// sum4 variables
reg [inst_sig_width + inst_exp_width:0] sum_num;
reg [inst_sig_width + inst_exp_width:0] sum_res;
reg [inst_sig_width + inst_exp_width:0] sum_tmp [0:1];

// cmp variables
reg [inst_sig_width + inst_exp_width:0] cmp_num [0:7];
reg [inst_sig_width + inst_exp_width:0] max;
reg [inst_sig_width + inst_exp_width:0] min;
reg [inst_sig_width + inst_exp_width:0] mid [0:1];
reg [3:0] cmp_res;
reg [3:0] cmp_res_reg [0:1];

// mac variables
reg [inst_sig_width + inst_exp_width:0] mac_num [0:1];
reg [inst_sig_width + inst_exp_width:0] mac_wgt [0:1];
reg [inst_sig_width + inst_exp_width:0] mac_sum [0:1];
reg [inst_sig_width + inst_exp_width:0] mac_res [0:1];

// sub variables
reg [inst_sig_width + inst_exp_width:0] sub_num[0:5];
reg [inst_sig_width + inst_exp_width:0] sub_res[0:2];

// add variables
reg [inst_sig_width + inst_exp_width:0] add_num[0:5];
reg [inst_sig_width + inst_exp_width:0] add_res[0:2];
reg [inst_sig_width + inst_exp_width:0] add_res_reg;

// rec variables
reg [inst_sig_width + inst_exp_width:0] rec_num[0:1];
reg [inst_sig_width + inst_exp_width:0] rec_res[0:1];
reg [inst_sig_width + inst_exp_width:0] rec_res_next[0:1];

// mul variables

// exp variables
reg [inst_sig_width + inst_exp_width:0] exp_num;
reg [inst_sig_width + inst_exp_width:0] exp_res [0:1];
reg [inst_sig_width + inst_exp_width:0] exp_res_next [0:1];

//   state block
always @(*) begin
    state_next = state;
    case (state)
        IDLE: begin
            if(in_valid) state_next = EXE;
            else         state_next = IDLE;
        end 
        EXE: begin
            if(loop ===  7'd68 && cnt === 4'd5) state_next = OUT;
            else                                state_next = EXE;
        end
        OUT: begin
            state_next = IDLE;
        end
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state <= 0;
    else       state <= state_next;
end

// counter block
always @(*) begin
    // if(state === EXE) begin
    //     if(cnt === 8'd15) cnt_next = 0;
    //     else              cnt_next = cnt + 1;
    // end
    // else cnt_next = cnt;
    if(cnt === 8'd15)     cnt_next = 0;
    else if(in_valid)     cnt_next = cnt + 1;
    else if(state == EXE) cnt_next = cnt + 1;
    else                  cnt_next = 0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt <= 'b0;
    else       cnt <= cnt_next;
end
// loop block
always @(*) begin
    // if(cnt === 8'd15) loop_next = loop + 16;
    if(loop === 7'd68 && cnt === 4'd6) loop_next = 0;
    else if(cnt === 4'd8) loop_next = loop + 1;
    else                  loop_next = loop;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) loop <= 'b0;
    else       loop <= loop_next;
end
//==============================================//
//                 Input Block                  //
//==============================================//
// option input block
always @(*) begin
    option_reg_next = option_reg;
    if (in_valid) begin
        if(cnt === 0 && loop === 0) begin
            option_reg_next = Opt;            
        end
    end
    else begin end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) option_reg <= 0;
    else       option_reg <= option_reg_next;
end
// image input block
always @(*) begin
    for(i = 0; i < 4; i = i + 1) begin
        for(j = 0; j < 4; j = j + 1) begin
            image_mem_next[i][j] = image_mem[i][j];
        end
    end

    if(in_valid) begin
        case (cnt)
        0 : image_mem_next[0][0] = Img;
        1 : image_mem_next[0][1] = Img;
        2 : image_mem_next[0][2] = Img;
        3 : image_mem_next[0][3] = Img;
        4 : image_mem_next[1][0] = Img;
        5 : image_mem_next[1][1] = Img;
        6 : image_mem_next[1][2] = Img;
        7 : image_mem_next[1][3] = Img;
        8 : image_mem_next[2][0] = Img;
        9 : image_mem_next[2][1] = Img;
        10: image_mem_next[2][2] = Img;
        11: image_mem_next[2][3] = Img;
        12: image_mem_next[3][0] = Img;
        13: image_mem_next[3][1] = Img;
        14: image_mem_next[3][2] = Img;
        15: image_mem_next[3][3] = Img;
        default: begin end
    endcase        
    end

end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 4; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                image_mem[i][j] <= 'b0;
            end
        end
    end
    else begin
        for(i = 0; i < 4; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                image_mem[i][j] <= image_mem_next[i][j];
            end
        end
    end
end
// kernel input block
always @(*) begin
    for(i = 0; i < 3; i = i + 1) begin
        for(j = 0; j < 3; j = j + 1) begin
            for(k = 0; k < 3; k = k + 1) begin
                kernel_mem_next[i][j][k] = kernel_mem[i][j][k];
            end
        end
        // kernel_mem1_next[i] = kernel_mem1[i];
        // kernel_mem2_next[i] = kernel_mem2[i];
        // kernel_mem3_next[i] = kernel_mem3[i];
    end

    if(in_valid) begin
        if(loop === 0) begin
            case (cnt)
                0 : kernel_mem_next[0][0][0] = Kernel;
                1 : kernel_mem_next[0][0][1] = Kernel;
                2 : kernel_mem_next[0][0][2] = Kernel;
                3 : kernel_mem_next[0][1][0] = Kernel;
                4 : kernel_mem_next[0][1][1] = Kernel;
                5 : kernel_mem_next[0][1][2] = Kernel;
                6 : kernel_mem_next[0][2][0] = Kernel;
                7 : kernel_mem_next[0][2][1] = Kernel;
                8 : kernel_mem_next[0][2][2] = Kernel;
                default: begin end
            endcase
        end
        else if(loop === 1) begin
            case (cnt)
                9 : kernel_mem_next[1][0][0] = Kernel;
                10: kernel_mem_next[1][0][1] = Kernel;
                11: kernel_mem_next[1][0][2] = Kernel;
                12: kernel_mem_next[1][1][0] = Kernel;
                13: kernel_mem_next[1][1][1] = Kernel;
                14: kernel_mem_next[1][1][2] = Kernel;
                15: kernel_mem_next[1][2][0] = Kernel;
                0 : kernel_mem_next[1][2][1] = Kernel;
                1 : kernel_mem_next[1][2][2] = Kernel;
                2 : kernel_mem_next[2][0][0] = Kernel;
                3 : kernel_mem_next[2][0][1] = Kernel;
                4 : kernel_mem_next[2][0][2] = Kernel;
                5 : kernel_mem_next[2][1][0] = Kernel;
                6 : kernel_mem_next[2][1][1] = Kernel;
                7 : kernel_mem_next[2][1][2] = Kernel;
                8 : kernel_mem_next[2][2][0] = Kernel;
                default: begin end
            endcase
        end
        else if(loop === 2) begin
            case (cnt)
                9 : kernel_mem_next[2][2][1] = Kernel;
                10: kernel_mem_next[2][2][2] = Kernel;
                default: begin end
            endcase       
        end
    end
    
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 3; i = i + 1) begin
            for(j = 0; j < 3; j = j + 1) begin
                for(k = 0; k < 3; k = k + 1) begin
                    kernel_mem[i][j][k] <= 'b0;
                end
            end
        end
    end
    else begin
        for(i = 0; i < 3; i = i + 1) begin
            for(j = 0; j < 3; j = j + 1) begin
                for(k = 0; k < 3; k = k + 1) begin
                    kernel_mem[i][j][k] <= kernel_mem_next[i][j][k];
                end
            end
        end
    end
end
// weight input block
always @(*) begin
    for(i = 0; i < 2; i = i + 1) begin
        for(j = 0; j < 2; j = j + 1) begin
            weight_mem_next[i][j] = weight_mem[i][j];
        end
    end

    if(in_valid) begin
        if(loop === 0) begin
            case (cnt)
                0: weight_mem_next[0][0]  = Weight;
                1: weight_mem_next[0][1]  = Weight;
                2: weight_mem_next[1][0]  = Weight;
                3: weight_mem_next[1][1]  = Weight;
                default: begin end
            endcase        
        end        
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 2; i = i + 1) begin
            for(j = 0; j < 2; j = j + 1) begin
                weight_mem[i][j] <= 'b0;
            end
        end
    end
    else begin
        for(i = 0; i < 2; i = i + 1) begin
            for(j = 0; j < 2; j = j + 1) begin
                weight_mem[i][j] <= weight_mem_next[i][j];
            end
        end
    end
end
//==============================================//
//              Designware Block                //
//==============================================//
// dot3
always @(*) begin
    for(i = 0; i < 9; i = i + 1) begin
        dot_num[i] = 'b0;
    end
    case (loop)
        1, 2, 3, 4, 5, 6: begin
            case (cnt)
                9: begin
                    dot_num[0] = (option_reg[0]) ? 0 : image_mem[0][0];
                    dot_num[1] = (option_reg[0]) ? 0 : image_mem[0][0];
                    dot_num[2] = (option_reg[0]) ? 0 : image_mem[0][1];
                    dot_num[3] = (option_reg[0]) ? 0 : image_mem[0][0];
                    dot_num[4] = image_mem[0][0];
                    dot_num[5] = image_mem[0][1];
                    dot_num[6] = (option_reg[0]) ? 0 : image_mem[1][0];
                    dot_num[7] = image_mem[1][0];
                    dot_num[8] = image_mem[1][1];
                end
                10: begin
                    dot_num[0] = (option_reg[0]) ? 0 : image_mem[0][0];
                    dot_num[1] = (option_reg[0]) ? 0 : image_mem[0][1];
                    dot_num[2] = (option_reg[0]) ? 0 : image_mem[0][2];
                    dot_num[3] = image_mem[0][0];
                    dot_num[4] = image_mem[0][1];
                    dot_num[5] = image_mem[0][2];
                    dot_num[6] = image_mem[1][0];
                    dot_num[7] = image_mem[1][1];
                    dot_num[8] = image_mem[1][2];
                end
                11: begin
                    dot_num[0] = (option_reg[0]) ? 0 : image_mem[0][1];
                    dot_num[1] = (option_reg[0]) ? 0 : image_mem[0][2];
                    dot_num[2] = (option_reg[0]) ? 0 : image_mem[0][3];
                    dot_num[3] = image_mem[0][1];
                    dot_num[4] = image_mem[0][2];
                    dot_num[5] = image_mem[0][3];
                    dot_num[6] = image_mem[1][1];
                    dot_num[7] = image_mem[1][2];
                    dot_num[8] = image_mem[1][3];
                end
                12: begin
                    dot_num[0] = (option_reg[0]) ? 0 : image_mem[0][2];
                    dot_num[1] = (option_reg[0]) ? 0 : image_mem[0][3];
                    dot_num[2] = (option_reg[0]) ? 0 : image_mem[0][3];
                    dot_num[3] = image_mem[0][2];
                    dot_num[4] = image_mem[0][3];
                    dot_num[5] = (option_reg[0]) ? 0 : image_mem[0][3];
                    dot_num[6] = image_mem[1][2];
                    dot_num[7] = image_mem[1][3];
                    dot_num[8] = (option_reg[0]) ? 0 : image_mem[1][3];
                end
                13: begin
                    dot_num[0] = (option_reg[0]) ? 0 : image_mem[0][0];
                    dot_num[1] = image_mem[0][0];
                    dot_num[2] = image_mem[0][1];
                    dot_num[3] = (option_reg[0]) ? 0 : image_mem[1][0];
                    dot_num[4] = image_mem[1][0];
                    dot_num[5] = image_mem[1][1];
                    dot_num[6] = (option_reg[0]) ? 0 : image_mem[2][0];
                    dot_num[7] = image_mem[2][0];
                    dot_num[8] = image_mem[2][1];
                end
                14: begin
                    dot_num[0] = image_mem[0][0];
                    dot_num[1] = image_mem[0][1];
                    dot_num[2] = image_mem[0][2];
                    dot_num[3] = image_mem[1][0];
                    dot_num[4] = image_mem[1][1];
                    dot_num[5] = image_mem[1][2];
                    dot_num[6] = image_mem[2][0];
                    dot_num[7] = image_mem[2][1];
                    dot_num[8] = image_mem[2][2];
                end
                15: begin
                    dot_num[0] = image_mem[0][1];
                    dot_num[1] = image_mem[0][2];
                    dot_num[2] = image_mem[0][3];
                    dot_num[3] = image_mem[1][1];
                    dot_num[4] = image_mem[1][2];
                    dot_num[5] = image_mem[1][3];
                    dot_num[6] = image_mem[2][1];
                    dot_num[7] = image_mem[2][2];
                    dot_num[8] = image_mem[2][3];
                end
                0: begin
                    dot_num[0] = image_mem[0][2];
                    dot_num[1] = image_mem[0][3];
                    dot_num[2] = (option_reg[0]) ? 0 : image_mem[0][3];
                    dot_num[3] = image_mem[1][2];
                    dot_num[4] = image_mem[1][3];
                    dot_num[5] = (option_reg[0]) ? 0 : image_mem[1][3];
                    dot_num[6] = image_mem[2][2];
                    dot_num[7] = image_mem[2][3];
                    dot_num[8] = (option_reg[0]) ? 0 : image_mem[2][3];
                end
                1: begin
                    dot_num[0] = (option_reg[0]) ? 0 : image_mem[1][0];
                    dot_num[1] = image_mem[1][0];
                    dot_num[2] = image_mem[1][1];
                    dot_num[3] = (option_reg[0]) ? 0 : image_mem[2][0];
                    dot_num[4] = image_mem[2][0];
                    dot_num[5] = image_mem[2][1];
                    dot_num[6] = (option_reg[0]) ? 0 : image_mem[3][0];
                    dot_num[7] = image_mem[3][0];
                    dot_num[8] = image_mem[3][1];
                end
                2: begin
                    dot_num[0] = image_mem[1][0];
                    dot_num[1] = image_mem[1][1];
                    dot_num[2] = image_mem[1][2];
                    dot_num[3] = image_mem[2][0];
                    dot_num[4] = image_mem[2][1];
                    dot_num[5] = image_mem[2][2];
                    dot_num[6] = image_mem[3][0];
                    dot_num[7] = image_mem[3][1];
                    dot_num[8] = image_mem[3][2];
                end
                3: begin
                    dot_num[0] = image_mem[1][1];
                    dot_num[1] = image_mem[1][2];
                    dot_num[2] = image_mem[1][3];
                    dot_num[3] = image_mem[2][1];
                    dot_num[4] = image_mem[2][2];
                    dot_num[5] = image_mem[2][3];
                    dot_num[6] = image_mem[3][1];
                    dot_num[7] = image_mem[3][2];
                    dot_num[8] = image_mem[3][3];
                end
                4: begin
                    dot_num[0] = image_mem[1][2];
                    dot_num[1] = image_mem[1][3];
                    dot_num[2] = (option_reg[0]) ? 0 : image_mem[1][3];
                    dot_num[3] = image_mem[2][2];
                    dot_num[4] = image_mem[2][3];
                    dot_num[5] = (option_reg[0]) ? 0 : image_mem[2][3];
                    dot_num[6] = image_mem[3][2];
                    dot_num[7] = image_mem[3][3];
                    dot_num[8] = (option_reg[0]) ? 0 : image_mem[3][3];
                end
                5: begin
                    dot_num[0] = (option_reg[0]) ? 0 : image_mem[2][0];
                    dot_num[1] = image_mem[2][0];
                    dot_num[2] = image_mem[2][1];
                    dot_num[3] = (option_reg[0]) ? 0 : image_mem[3][0];
                    dot_num[4] = image_mem[3][0];
                    dot_num[5] = image_mem[3][1];
                    dot_num[6] = (option_reg[0]) ? 0 : image_mem[3][0];
                    dot_num[7] = (option_reg[0]) ? 0 : image_mem[3][0];
                    dot_num[8] = (option_reg[0]) ? 0 : image_mem[3][1];
                end
                6: begin
                    dot_num[0] = image_mem[2][0];
                    dot_num[1] = image_mem[2][1];
                    dot_num[2] = image_mem[2][2];
                    dot_num[3] = image_mem[3][0];
                    dot_num[4] = image_mem[3][1];
                    dot_num[5] = image_mem[3][2];
                    dot_num[6] = (option_reg[0]) ? 0 : image_mem[3][0];
                    dot_num[7] = (option_reg[0]) ? 0 : image_mem[3][1];
                    dot_num[8] = (option_reg[0]) ? 0 : image_mem[3][2];
                end
                7: begin
                    dot_num[0] = image_mem[2][1];
                    dot_num[1] = image_mem[2][2];
                    dot_num[2] = image_mem[2][3];
                    dot_num[3] = image_mem[3][1];
                    dot_num[4] = image_mem[3][2];
                    dot_num[5] = image_mem[3][3];
                    dot_num[6] = (option_reg[0]) ? 0 : image_mem[3][1];
                    dot_num[7] = (option_reg[0]) ? 0 : image_mem[3][2];
                    dot_num[8] = (option_reg[0]) ? 0 : image_mem[3][3];
                end
                8: begin
                    dot_num[0] = image_mem[2][2];
                    dot_num[1] = image_mem[2][3];
                    dot_num[2] = (option_reg[0]) ? 0 : image_mem[2][3];
                    dot_num[3] = image_mem[3][2];
                    dot_num[4] = image_mem[3][3];
                    dot_num[5] = (option_reg[0]) ? 0 : image_mem[3][3];
                    dot_num[6] = (option_reg[0]) ? 0 : image_mem[3][2];
                    dot_num[7] = (option_reg[0]) ? 0 : image_mem[3][3];
                    dot_num[8] = (option_reg[0]) ? 0 : image_mem[3][3];
                end
                default: begin end
            endcase            
        end
        7: begin
            case (cnt)
                9: begin
                    dot_num[0] = (option_reg[0]) ? 0 : feature_map[0][0][0];
                    dot_num[1] = (option_reg[0]) ? 0 : feature_map[0][0][0];
                    dot_num[2] = (option_reg[0]) ? 0 : feature_map[0][0][1];
                    dot_num[3] = (option_reg[0]) ? 0 : feature_map[0][0][0];
                    dot_num[4] = feature_map[0][0][0];
                    dot_num[5] = feature_map[0][0][1];
                    dot_num[6] = (option_reg[0]) ? 0 : feature_map[0][1][0];
                    dot_num[7] = feature_map[0][1][0];
                    dot_num[8] = feature_map[0][1][1];
                end
                10: begin
                    dot_num[0] = (option_reg[0]) ? 0 : feature_map[0][0][0];
                    dot_num[1] = (option_reg[0]) ? 0 : feature_map[0][0][1];
                    dot_num[2] = (option_reg[0]) ? 0 : feature_map[0][0][2];
                    dot_num[3] = feature_map[0][0][0];
                    dot_num[4] = feature_map[0][0][1];
                    dot_num[5] = feature_map[0][0][2];
                    dot_num[6] = feature_map[0][1][0];
                    dot_num[7] = feature_map[0][1][1];
                    dot_num[8] = feature_map[0][1][2];
                end
                11: begin
                    dot_num[0] = (option_reg[0]) ? 0 : feature_map[0][0][1];
                    dot_num[1] = (option_reg[0]) ? 0 : feature_map[0][0][2];
                    dot_num[2] = (option_reg[0]) ? 0 : feature_map[0][0][3];
                    dot_num[3] = feature_map[0][0][1];
                    dot_num[4] = feature_map[0][0][2];
                    dot_num[5] = feature_map[0][0][3];
                    dot_num[6] = feature_map[0][1][1];
                    dot_num[7] = feature_map[0][1][2];
                    dot_num[8] = feature_map[0][1][3];
                end
                12: begin
                    dot_num[0] = (option_reg[0]) ? 0 : feature_map[0][0][2];
                    dot_num[1] = (option_reg[0]) ? 0 : feature_map[0][0][3];
                    dot_num[2] = (option_reg[0]) ? 0 : feature_map[0][0][3];
                    dot_num[3] = feature_map[0][0][2];
                    dot_num[4] = feature_map[0][0][3];
                    dot_num[5] = (option_reg[0]) ? 0 : feature_map[0][0][3];
                    dot_num[6] = feature_map[0][1][2];
                    dot_num[7] = feature_map[0][1][3];
                    dot_num[8] = (option_reg[0]) ? 0 : feature_map[0][1][3];
                end
                13: begin
                    dot_num[0] = (option_reg[0]) ? 0 : feature_map[0][0][0];
                    dot_num[1] = feature_map[0][0][0];
                    dot_num[2] = feature_map[0][0][1];
                    dot_num[3] = (option_reg[0]) ? 0 : feature_map[0][1][0];
                    dot_num[4] = feature_map[0][1][0];
                    dot_num[5] = feature_map[0][1][1];
                    dot_num[6] = (option_reg[0]) ? 0 : feature_map[0][2][0];
                    dot_num[7] = feature_map[0][2][0];
                    dot_num[8] = feature_map[0][2][1];
                end
                14: begin
                    dot_num[0] = feature_map[0][0][0];
                    dot_num[1] = feature_map[0][0][1];
                    dot_num[2] = feature_map[0][0][2];
                    dot_num[3] = feature_map[0][1][0];
                    dot_num[4] = feature_map[0][1][1];
                    dot_num[5] = feature_map[0][1][2];
                    dot_num[6] = feature_map[0][2][0];
                    dot_num[7] = feature_map[0][2][1];
                    dot_num[8] = feature_map[0][2][2];
                end
                15: begin
                    dot_num[0] = feature_map[0][0][1];
                    dot_num[1] = feature_map[0][0][2];
                    dot_num[2] = feature_map[0][0][3];
                    dot_num[3] = feature_map[0][1][1];
                    dot_num[4] = feature_map[0][1][2];
                    dot_num[5] = feature_map[0][1][3];
                    dot_num[6] = feature_map[0][2][1];
                    dot_num[7] = feature_map[0][2][2];
                    dot_num[8] = feature_map[0][2][3];
                end
                0: begin
                    dot_num[0] = feature_map[0][0][2];
                    dot_num[1] = feature_map[0][0][3];
                    dot_num[2] = (option_reg[0]) ? 0 : feature_map[0][0][3];
                    dot_num[3] = feature_map[0][1][2];
                    dot_num[4] = feature_map[0][1][3];
                    dot_num[5] = (option_reg[0]) ? 0 : feature_map[0][1][3];
                    dot_num[6] = feature_map[0][2][2];
                    dot_num[7] = feature_map[0][2][3];
                    dot_num[8] = (option_reg[0]) ? 0 : feature_map[0][2][3];
                end
                1: begin
                    dot_num[0] = (option_reg[0]) ? 0 : feature_map[0][1][0];
                    dot_num[1] = feature_map[0][1][0];
                    dot_num[2] = feature_map[0][1][1];
                    dot_num[3] = (option_reg[0]) ? 0 : feature_map[0][2][0];
                    dot_num[4] = feature_map[0][2][0];
                    dot_num[5] = feature_map[0][2][1];
                    dot_num[6] = (option_reg[0]) ? 0 : feature_map[0][3][0];
                    dot_num[7] = feature_map[0][3][0];
                    dot_num[8] = feature_map[0][3][1];
                end
                2: begin
                    dot_num[0] = feature_map[0][1][0];
                    dot_num[1] = feature_map[0][1][1];
                    dot_num[2] = feature_map[0][1][2];
                    dot_num[3] = feature_map[0][2][0];
                    dot_num[4] = feature_map[0][2][1];
                    dot_num[5] = feature_map[0][2][2];
                    dot_num[6] = feature_map[0][3][0];
                    dot_num[7] = feature_map[0][3][1];
                    dot_num[8] = feature_map[0][3][2];
                end
                3: begin
                    dot_num[0] = feature_map[0][1][1];
                    dot_num[1] = feature_map[0][1][2];
                    dot_num[2] = feature_map[0][1][3];
                    dot_num[3] = feature_map[0][2][1];
                    dot_num[4] = feature_map[0][2][2];
                    dot_num[5] = feature_map[0][2][3];
                    dot_num[6] = feature_map[0][3][1];
                    dot_num[7] = feature_map[0][3][2];
                    dot_num[8] = feature_map[0][3][3];
                end
                4: begin
                    dot_num[0] = feature_map[0][1][2];
                    dot_num[1] = feature_map[0][1][3];
                    dot_num[2] = (option_reg[0]) ? 0 : feature_map[0][1][3];
                    dot_num[3] = feature_map[0][2][2];
                    dot_num[4] = feature_map[0][2][3];
                    dot_num[5] = (option_reg[0]) ? 0 : feature_map[0][2][3];
                    dot_num[6] = feature_map[0][3][2];
                    dot_num[7] = feature_map[0][3][3];
                    dot_num[8] = (option_reg[0]) ? 0 : feature_map[0][3][3];
                end
                5: begin
                    dot_num[0] = (option_reg[0]) ? 0 : feature_map[0][2][0];
                    dot_num[1] = feature_map[0][2][0];
                    dot_num[2] = feature_map[0][2][1];
                    dot_num[3] = (option_reg[0]) ? 0 : feature_map[0][3][0];
                    dot_num[4] = feature_map[0][3][0];
                    dot_num[5] = feature_map[0][3][1];
                    dot_num[6] = (option_reg[0]) ? 0 : feature_map[0][3][0];
                    dot_num[7] = (option_reg[0]) ? 0 : feature_map[0][3][0];
                    dot_num[8] = (option_reg[0]) ? 0 : feature_map[0][3][1];
                end
                6: begin
                    dot_num[0] = feature_map[0][2][0];
                    dot_num[1] = feature_map[0][2][1];
                    dot_num[2] = feature_map[0][2][2];
                    dot_num[3] = feature_map[0][3][0];
                    dot_num[4] = feature_map[0][3][1];
                    dot_num[5] = feature_map[0][3][2];
                    dot_num[6] = (option_reg[0]) ? 0 : feature_map[0][3][0];
                    dot_num[7] = (option_reg[0]) ? 0 : feature_map[0][3][1];
                    dot_num[8] = (option_reg[0]) ? 0 : feature_map[0][3][2];
                end
                7: begin
                    dot_num[0] = feature_map[0][2][1];
                    dot_num[1] = feature_map[0][2][2];
                    dot_num[2] = feature_map[0][2][3];
                    dot_num[3] = feature_map[0][3][1];
                    dot_num[4] = feature_map[0][3][2];
                    dot_num[5] = feature_map[0][3][3];
                    dot_num[6] = (option_reg[0]) ? 0 : feature_map[0][3][1];
                    dot_num[7] = (option_reg[0]) ? 0 : feature_map[0][3][2];
                    dot_num[8] = (option_reg[0]) ? 0 : feature_map[0][3][3];
                end
                8: begin
                    dot_num[0] = feature_map[0][2][2];
                    dot_num[1] = feature_map[0][2][3];
                    dot_num[2] = (option_reg[0]) ? 0 : feature_map[0][2][3];
                    dot_num[3] = feature_map[0][3][2];
                    dot_num[4] = feature_map[0][3][3];
                    dot_num[5] = (option_reg[0]) ? 0 : feature_map[0][3][3];
                    dot_num[6] = (option_reg[0]) ? 0 : feature_map[0][3][2];
                    dot_num[7] = (option_reg[0]) ? 0 : feature_map[0][3][3];
                    dot_num[8] = (option_reg[0]) ? 0 : feature_map[0][3][3];
                end
                default: begin end
            endcase            
        end
        8: begin
            case (cnt)
                9: begin
                    dot_num[0] = (option_reg[0]) ? 0 : feature_map[1][0][0];
                    dot_num[1] = (option_reg[0]) ? 0 : feature_map[1][0][0];
                    dot_num[2] = (option_reg[0]) ? 0 : feature_map[1][0][1];
                    dot_num[3] = (option_reg[0]) ? 0 : feature_map[1][0][0];
                    dot_num[4] = feature_map[1][0][0];
                    dot_num[5] = feature_map[1][0][1];
                    dot_num[6] = (option_reg[0]) ? 0 : feature_map[1][1][0];
                    dot_num[7] = feature_map[1][1][0];
                    dot_num[8] = feature_map[1][1][1];
                end
                10: begin
                    dot_num[0] = (option_reg[0]) ? 0 : feature_map[1][0][0];
                    dot_num[1] = (option_reg[0]) ? 0 : feature_map[1][0][1];
                    dot_num[2] = (option_reg[0]) ? 0 : feature_map[1][0][2];
                    dot_num[3] = feature_map[1][0][0];
                    dot_num[4] = feature_map[1][0][1];
                    dot_num[5] = feature_map[1][0][2];
                    dot_num[6] = feature_map[1][1][0];
                    dot_num[7] = feature_map[1][1][1];
                    dot_num[8] = feature_map[1][1][2];
                end
                11: begin
                    dot_num[0] = (option_reg[0]) ? 0 : feature_map[1][0][1];
                    dot_num[1] = (option_reg[0]) ? 0 : feature_map[1][0][2];
                    dot_num[2] = (option_reg[0]) ? 0 : feature_map[1][0][3];
                    dot_num[3] = feature_map[1][0][1];
                    dot_num[4] = feature_map[1][0][2];
                    dot_num[5] = feature_map[1][0][3];
                    dot_num[6] = feature_map[1][1][1];
                    dot_num[7] = feature_map[1][1][2];
                    dot_num[8] = feature_map[1][1][3];
                end
                12: begin
                    dot_num[0] = (option_reg[0]) ? 0 : feature_map[1][0][2];
                    dot_num[1] = (option_reg[0]) ? 0 : feature_map[1][0][3];
                    dot_num[2] = (option_reg[0]) ? 0 : feature_map[1][0][3];
                    dot_num[3] = feature_map[1][0][2];
                    dot_num[4] = feature_map[1][0][3];
                    dot_num[5] = (option_reg[0]) ? 0 : feature_map[1][0][3];
                    dot_num[6] = feature_map[1][1][2];
                    dot_num[7] = feature_map[1][1][3];
                    dot_num[8] = (option_reg[0]) ? 0 : feature_map[1][1][3];
                end
                13: begin
                    dot_num[0] = (option_reg[0]) ? 0 : feature_map[1][0][0];
                    dot_num[1] = feature_map[1][0][0];
                    dot_num[2] = feature_map[1][0][1];
                    dot_num[3] = (option_reg[0]) ? 0 : feature_map[1][1][0];
                    dot_num[4] = feature_map[1][1][0];
                    dot_num[5] = feature_map[1][1][1];
                    dot_num[6] = (option_reg[0]) ? 0 : feature_map[1][2][0];
                    dot_num[7] = feature_map[1][2][0];
                    dot_num[8] = feature_map[1][2][1];
                end
                14: begin
                    dot_num[0] = feature_map[1][0][0];
                    dot_num[1] = feature_map[1][0][1];
                    dot_num[2] = feature_map[1][0][2];
                    dot_num[3] = feature_map[1][1][0];
                    dot_num[4] = feature_map[1][1][1];
                    dot_num[5] = feature_map[1][1][2];
                    dot_num[6] = feature_map[1][2][0];
                    dot_num[7] = feature_map[1][2][1];
                    dot_num[8] = feature_map[1][2][2];
                end
                15: begin
                    dot_num[0] = feature_map[1][0][1];
                    dot_num[1] = feature_map[1][0][2];
                    dot_num[2] = feature_map[1][0][3];
                    dot_num[3] = feature_map[1][1][1];
                    dot_num[4] = feature_map[1][1][2];
                    dot_num[5] = feature_map[1][1][3];
                    dot_num[6] = feature_map[1][2][1];
                    dot_num[7] = feature_map[1][2][2];
                    dot_num[8] = feature_map[1][2][3];
                end
                0: begin
                    dot_num[0] = feature_map[1][0][2];
                    dot_num[1] = feature_map[1][0][3];
                    dot_num[2] = (option_reg[0]) ? 0 : feature_map[1][0][3];
                    dot_num[3] = feature_map[1][1][2];
                    dot_num[4] = feature_map[1][1][3];
                    dot_num[5] = (option_reg[0]) ? 0 : feature_map[1][1][3];
                    dot_num[6] = feature_map[1][2][2];
                    dot_num[7] = feature_map[1][2][3];
                    dot_num[8] = (option_reg[0]) ? 0 : feature_map[1][2][3];
                end
                1: begin
                    dot_num[0] = (option_reg[0]) ? 0 : feature_map[1][1][0];
                    dot_num[1] = feature_map[1][1][0];
                    dot_num[2] = feature_map[1][1][1];
                    dot_num[3] = (option_reg[0]) ? 0 : feature_map[1][2][0];
                    dot_num[4] = feature_map[1][2][0];
                    dot_num[5] = feature_map[1][2][1];
                    dot_num[6] = (option_reg[0]) ? 0 : feature_map[1][3][0];
                    dot_num[7] = feature_map[1][3][0];
                    dot_num[8] = feature_map[1][3][1];
                end
                2: begin
                    dot_num[0] = feature_map[1][1][0];
                    dot_num[1] = feature_map[1][1][1];
                    dot_num[2] = feature_map[1][1][2];
                    dot_num[3] = feature_map[1][2][0];
                    dot_num[4] = feature_map[1][2][1];
                    dot_num[5] = feature_map[1][2][2];
                    dot_num[6] = feature_map[1][3][0];
                    dot_num[7] = feature_map[1][3][1];
                    dot_num[8] = feature_map[1][3][2];
                end
                3: begin
                    dot_num[0] = feature_map[1][1][1];
                    dot_num[1] = feature_map[1][1][2];
                    dot_num[2] = feature_map[1][1][3];
                    dot_num[3] = feature_map[1][2][1];
                    dot_num[4] = feature_map[1][2][2];
                    dot_num[5] = feature_map[1][2][3];
                    dot_num[6] = feature_map[1][3][1];
                    dot_num[7] = feature_map[1][3][2];
                    dot_num[8] = feature_map[1][3][3];
                end
                4: begin
                    dot_num[0] = feature_map[1][1][2];
                    dot_num[1] = feature_map[1][1][3];
                    dot_num[2] = (option_reg[0]) ? 0 : feature_map[1][1][3];
                    dot_num[3] = feature_map[1][2][2];
                    dot_num[4] = feature_map[1][2][3];
                    dot_num[5] = (option_reg[0]) ? 0 : feature_map[1][2][3];
                    dot_num[6] = feature_map[1][3][2];
                    dot_num[7] = feature_map[1][3][3];
                    dot_num[8] = (option_reg[0]) ? 0 : feature_map[1][3][3];
                end
                5: begin
                    dot_num[0] = (option_reg[0]) ? 0 : feature_map[1][2][0];
                    dot_num[1] = feature_map[1][2][0];
                    dot_num[2] = feature_map[1][2][1];
                    dot_num[3] = (option_reg[0]) ? 0 : feature_map[1][3][0];
                    dot_num[4] = feature_map[1][3][0];
                    dot_num[5] = feature_map[1][3][1];
                    dot_num[6] = (option_reg[0]) ? 0 : feature_map[1][3][0];
                    dot_num[7] = (option_reg[0]) ? 0 : feature_map[1][3][0];
                    dot_num[8] = (option_reg[0]) ? 0 : feature_map[1][3][1];
                end
                6: begin
                    dot_num[0] = feature_map[1][2][0];
                    dot_num[1] = feature_map[1][2][1];
                    dot_num[2] = feature_map[1][2][2];
                    dot_num[3] = feature_map[1][3][0];
                    dot_num[4] = feature_map[1][3][1];
                    dot_num[5] = feature_map[1][3][2];
                    dot_num[6] = (option_reg[0]) ? 0 : feature_map[1][3][0];
                    dot_num[7] = (option_reg[0]) ? 0 : feature_map[1][3][1];
                    dot_num[8] = (option_reg[0]) ? 0 : feature_map[1][3][2];
                end
                7: begin
                    dot_num[0] = feature_map[1][2][1];
                    dot_num[1] = feature_map[1][2][2];
                    dot_num[2] = feature_map[1][2][3];
                    dot_num[3] = feature_map[1][3][1];
                    dot_num[4] = feature_map[1][3][2];
                    dot_num[5] = feature_map[1][3][3];
                    dot_num[6] = (option_reg[0]) ? 0 : feature_map[1][3][1];
                    dot_num[7] = (option_reg[0]) ? 0 : feature_map[1][3][2];
                    dot_num[8] = (option_reg[0]) ? 0 : feature_map[1][3][3];
                end
                8: begin
                    dot_num[0] = feature_map[1][2][2];
                    dot_num[1] = feature_map[1][2][3];
                    dot_num[2] = (option_reg[0]) ? 0 : feature_map[1][2][3];
                    dot_num[3] = feature_map[1][3][2];
                    dot_num[4] = feature_map[1][3][3];
                    dot_num[5] = (option_reg[0]) ? 0 : feature_map[1][3][3];
                    dot_num[6] = (option_reg[0]) ? 0 : feature_map[1][3][2];
                    dot_num[7] = (option_reg[0]) ? 0 : feature_map[1][3][3];
                    dot_num[8] = (option_reg[0]) ? 0 : feature_map[1][3][3];
                end
                default: begin end
            endcase           
        end
        9: begin
            case (cnt)
                9: begin
                    dot_num[0] = max_pooling[0][0][0];
                    dot_num[1] = max_pooling[0][0][1];
                    dot_num[2] = 'b0;
                    dot_num[3] = max_pooling[0][0][0];
                    dot_num[4] = max_pooling[0][0][1];
                    dot_num[5] = 'b0;
                    dot_num[6] = 'b0;
                    dot_num[7] = 'b0;
                    dot_num[8] = 'b0;                    
                end
                10: begin
                    dot_num[0] = max_pooling[0][1][0];
                    dot_num[1] = max_pooling[0][1][1];
                    dot_num[2] = 'b0;
                    dot_num[3] = max_pooling[0][1][0];
                    dot_num[4] = max_pooling[0][1][1];
                    dot_num[5] = 'b0;
                    dot_num[6] = 'b0;
                    dot_num[7] = 'b0;
                    dot_num[8] = 'b0;                    
                end
                11: begin
                    dot_num[0] = max_pooling[1][0][0];
                    dot_num[1] = max_pooling[1][0][1];
                    dot_num[2] = 'b0;
                    dot_num[3] = max_pooling[1][0][0];
                    dot_num[4] = max_pooling[1][0][1];
                    dot_num[5] = 'b0;
                    dot_num[6] = 'b0;
                    dot_num[7] = 'b0;
                    dot_num[8] = 'b0;          
                end
                12: begin
                    dot_num[0] = max_pooling[1][1][0];
                    dot_num[1] = max_pooling[1][1][1];
                    dot_num[2] = 'b0;
                    dot_num[3] = max_pooling[1][1][0];
                    dot_num[4] = max_pooling[1][1][1];
                    dot_num[5] = 'b0;
                    dot_num[6] = 'b0;
                    dot_num[7] = 'b0;
                    dot_num[8] = 'b0;                    
                end
                13: begin
                    dot_num[0] = mid[0];
                    dot_num[1] = {~min[31],min[30:0]};
                    dot_num[3] = mid[1];
                    dot_num[4] = {~min[31],min[30:0]};              
                end
                15: begin
                    dot_num[0] = mid[0];
                    dot_num[1] = {~min[31],min[30:0]};
                    dot_num[3] = mid[1];
                    dot_num[4] = {~min[31],min[30:0]};                
                end
                0, 1, 2, 3: begin
                    dot_num[0] = (option_reg[1]) ? add_res_reg : 32'h3f800000;
                end 
                4: begin
                    dot_num[0] = normaliztion[0][0];
                    dot_num[1] = {~normaliztion[1][0][31], normaliztion[1][0][30:0]};
                    dot_num[3] = normaliztion[0][1];
                    dot_num[4] = {~normaliztion[1][1][31], normaliztion[1][1][30:0]};
                    dot_num[6] = normaliztion[0][2];
                    dot_num[7] = {~normaliztion[1][2][31], normaliztion[1][2][30:0]};
                end               
                default: begin end
            endcase
        end
        default: begin end
    endcase
    
end
always @(*) begin
    for(i = 0; i < 9; i = i + 1) begin
        dot_ker[i] = 'b0;
    end
    case (loop)
        1, 4: begin
            dot_ker[0] = kernel_mem[0][0][0];
            dot_ker[1] = kernel_mem[0][0][1];
            dot_ker[2] = kernel_mem[0][0][2];
            dot_ker[3] = kernel_mem[0][1][0];
            dot_ker[4] = kernel_mem[0][1][1];
            dot_ker[5] = kernel_mem[0][1][2];
            dot_ker[6] = kernel_mem[0][2][0];
            dot_ker[7] = kernel_mem[0][2][1];
            dot_ker[8] = kernel_mem[0][2][2]; 
        end
        2, 5: begin
            dot_ker[0] = kernel_mem[1][0][0];
            dot_ker[1] = kernel_mem[1][0][1];
            dot_ker[2] = kernel_mem[1][0][2];
            dot_ker[3] = kernel_mem[1][1][0];
            dot_ker[4] = kernel_mem[1][1][1];
            dot_ker[5] = kernel_mem[1][1][2];
            dot_ker[6] = kernel_mem[1][2][0];
            dot_ker[7] = kernel_mem[1][2][1];
            dot_ker[8] = kernel_mem[1][2][2];             
        end
        3, 6: begin
            dot_ker[0] = kernel_mem[2][0][0];
            dot_ker[1] = kernel_mem[2][0][1];
            dot_ker[2] = kernel_mem[2][0][2];
            dot_ker[3] = kernel_mem[2][1][0];
            dot_ker[4] = kernel_mem[2][1][1];
            dot_ker[5] = kernel_mem[2][1][2];
            dot_ker[6] = kernel_mem[2][2][0];
            dot_ker[7] = kernel_mem[2][2][1];
            dot_ker[8] = kernel_mem[2][2][2];            
        end
        7, 8: begin
            for(i = 0; i < 9; i = i + 1) begin
                dot_ker[i] = 32'h3DE38E39;
            end
        end 
        9: begin
            case (cnt)
                9, 11: begin
                    dot_ker[0] = weight_mem[0][0];
                    dot_ker[1] = weight_mem[1][0];
                    dot_ker[3] = weight_mem[0][1];
                    dot_ker[4] = weight_mem[1][1];                   
                end
                10, 12: begin
                    dot_ker[0] = weight_mem[0][0];
                    dot_ker[1] = weight_mem[1][0];
                    dot_ker[3] = weight_mem[0][1];
                    dot_ker[4] = weight_mem[1][1];                   
                end
                13, 15: begin
                    dot_ker[0] = rec_res[0];
                    dot_ker[1] = rec_res[0];
                    dot_ker[3] = rec_res[0];
                    dot_ker[4] = rec_res[0];                     
                end
                0, 1, 2, 3: begin
                    dot_ker[0] = rec_res[0];
                end
                4: begin
                    dot_ker[0] = 32'h3f800000;
                    dot_ker[1] = 32'h3f800000;
                    dot_ker[3] = 32'h3f800000;
                    dot_ker[4] = 32'h3f800000;
                    dot_ker[6] = 32'h3f800000;
                    dot_ker[7] = 32'h3f800000;                    
                end
                default: begin end 
            endcase
        end 
        default: begin end
    endcase
end
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) U_dp3_1(
    .a(dot_num[0]),
    .b(dot_ker[0]),
    .c(dot_num[1]),
    .d(dot_ker[1]),
    .e(dot_num[2]),
    .f(dot_ker[2]),
    .rnd(3'b0),
    .z(dot_res_next[0]));
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) U_dp3_2(
    .a(dot_num[3]),
    .b(dot_ker[3]),
    .c(dot_num[4]),
    .d(dot_ker[4]),
    .e(dot_num[5]),
    .f(dot_ker[5]),
    .rnd(3'b0),
    .z(dot_res_next[1]));
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) U_dp3_3(
    .a(dot_num[6]),
    .b(dot_ker[6]),
    .c(dot_num[7]),
    .d(dot_ker[7]),
    .e(dot_num[8]),
    .f(dot_ker[8]),
    .rnd(3'b0),
    .z(dot_res_next[2]));


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 3; i = i + 1) dot_res[i] <= 'b0;
    end
    else begin
        for(i = 0; i < 3; i = i + 1) dot_res[i] <= dot_res_next[i];
    end
end
// add 4
always @(*) begin
    for (i = 0; i < 4; i = i + 1) add_num[i] = 'b0;

    case (loop)
        1: begin
            case (cnt)
                10: add_num[0] = feature_map[0][0][0];
                11: add_num[0] = feature_map[0][0][1];
                12: add_num[0] = feature_map[0][0][2];
                13: add_num[0] = feature_map[0][0][3];
                14: add_num[0] = feature_map[0][1][0];
                15: add_num[0] = feature_map[0][1][1];
                0 : add_num[0] = feature_map[0][1][2];
                1 : add_num[0] = feature_map[0][1][3];
                2 : add_num[0] = feature_map[0][2][0];
                3 : add_num[0] = feature_map[0][2][1];
                4 : add_num[0] = feature_map[0][2][2];
                5 : add_num[0] = feature_map[0][2][3];
                6 : add_num[0] = feature_map[0][3][0];
                7 : add_num[0] = feature_map[0][3][1];
                8 : add_num[0] = feature_map[0][3][2];
                default: begin end
            endcase
            add_num[1] = dot_res[0];
            add_num[2] = dot_res[1];
            add_num[3] = dot_res[2];            
        end
        2, 3: begin
            case (cnt)
                10: add_num[0] = feature_map[0][0][0];
                11: add_num[0] = feature_map[0][0][1];
                12: add_num[0] = feature_map[0][0][2];
                13: add_num[0] = feature_map[0][0][3];
                14: add_num[0] = feature_map[0][1][0];
                15: add_num[0] = feature_map[0][1][1];
                0 : add_num[0] = feature_map[0][1][2];
                1 : add_num[0] = feature_map[0][1][3];
                2 : add_num[0] = feature_map[0][2][0];
                3 : add_num[0] = feature_map[0][2][1];
                4 : add_num[0] = feature_map[0][2][2];
                5 : add_num[0] = feature_map[0][2][3];
                6 : add_num[0] = feature_map[0][3][0];
                7 : add_num[0] = feature_map[0][3][1];
                8 : add_num[0] = feature_map[0][3][2];
                9 : add_num[0] = feature_map[0][3][3];
                default: begin end
            endcase
            add_num[1] = dot_res[0];
            add_num[2] = dot_res[1];
            add_num[3] = dot_res[2];              
        end 
        4: begin
            case (cnt)
                10: add_num[0] = feature_map[1][0][0];
                11: add_num[0] = feature_map[1][0][1];
                12: add_num[0] = feature_map[1][0][2];
                13: add_num[0] = feature_map[1][0][3];
                14: add_num[0] = feature_map[1][1][0];
                15: add_num[0] = feature_map[1][1][1];
                0 : add_num[0] = feature_map[1][1][2];
                1 : add_num[0] = feature_map[1][1][3];
                2 : add_num[0] = feature_map[1][2][0];
                3 : add_num[0] = feature_map[1][2][1];
                4 : add_num[0] = feature_map[1][2][2];
                5 : add_num[0] = feature_map[1][2][3];
                6 : add_num[0] = feature_map[1][3][0];
                7 : add_num[0] = feature_map[1][3][1];
                8 : add_num[0] = feature_map[1][3][2];
                9 : add_num[0] = feature_map[0][3][3];
                default: begin end
            endcase
            add_num[1] = dot_res[0];
            add_num[2] = dot_res[1];
            add_num[3] = dot_res[2];               
        end
        5, 6: begin
            case (cnt)
                10: add_num[0] = feature_map[1][0][0];
                11: add_num[0] = feature_map[1][0][1];
                12: add_num[0] = feature_map[1][0][2];
                13: add_num[0] = feature_map[1][0][3];
                14: add_num[0] = feature_map[1][1][0];
                15: add_num[0] = feature_map[1][1][1];
                0 : add_num[0] = feature_map[1][1][2];
                1 : add_num[0] = feature_map[1][1][3];
                2 : add_num[0] = feature_map[1][2][0];
                3 : add_num[0] = feature_map[1][2][1];
                4 : add_num[0] = feature_map[1][2][2];
                5 : add_num[0] = feature_map[1][2][3];
                6 : add_num[0] = feature_map[1][3][0];
                7 : add_num[0] = feature_map[1][3][1];
                8 : add_num[0] = feature_map[1][3][2];
                9 : add_num[0] = feature_map[1][3][3];
                default: begin end
            endcase
            add_num[1] = dot_res[0];
            add_num[2] = dot_res[1];
            add_num[3] = dot_res[2];              
        end
        7: begin
            if(cnt == 9) begin
                add_num[0] = feature_map[1][3][3];
                add_num[1] = dot_res[0];
                add_num[2] = dot_res[1];
                add_num[3] = dot_res[2];               
            end
            else begin
                add_num[0] = 'b0;
                add_num[1] = dot_res[0];
                add_num[2] = dot_res[1];
                add_num[3] = dot_res[2];              
            end
        end
        8: begin
            add_num[0] = 'b0;
            add_num[1] = dot_res[0];
            add_num[2] = dot_res[1];
            add_num[3] = dot_res[2];           
        end
        9: begin
            case (cnt)
                9 : begin
                    add_num[0] = 'b0;
                    add_num[1] = dot_res[0];
                    add_num[2] = dot_res[1];
                    add_num[3] = dot_res[2];
                    // add_num[0] = feature_map[1][3][3];
                    // add_num[1] = dot_res[0];
                    // add_num[2] = dot_res[1];
                    // add_num[3] = dot_res[2];  
                end 
                15, 0, 1, 2: begin
                    add_num[0] = exp_res[1];
                    add_num[1] = (option_reg[1]) ? exp_res[0] : 32'h3f800000;
                    add_num[2] = exp_res[0];
                    add_num[3] = {~exp_res[1][31], exp_res[1][30:0]};                     
                end
                4: begin
                    add_num[2] = normaliztion[0][3];
                    add_num[3] = {~normaliztion[1][3][31], normaliztion[1][3][30:0]};
                end
                5: begin
                    add_num[0] = {1'b0,dot_res[0][30:0]};
                    add_num[1] = {1'b0,dot_res[1][30:0]};
                    add_num[2] = {1'b0,dot_res[2][30:0]};
                    add_num[3] = {1'b0,add_res_reg[30:0]};                    
                end
                default: begin end
            endcase
        end
        default: begin end 
    endcase
end
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_add_1 (
    .a(add_num[0]), 
    .b(add_num[1]), 
    .rnd(3'b0), 
    .z(add_res[0]));

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_add_2 (
    .a(add_num[2]), 
    .b(add_num[3]), 
    .rnd(3'b0), 
    .z(add_res[1]));

always @(*) begin
    for (i = 4; i < 6; i = i + 1) add_num[i] = 'b0; 

    case (loop)
        1, 2, 3, 4, 5, 6, 7, 8: begin
            add_num[4] = add_res[0];
            add_num[5] = add_res[1];
        end
        9: begin
            case (cnt)
                9: begin
                    add_num[4] = add_res[0];
                    add_num[5] = add_res[1];                    
                end 
                12, 14: begin
                    add_num[4] = max;
                    add_num[5] = {~min[31],min[30:0]};                    
                end
                5: begin
                    add_num[4] = add_res[0];
                    add_num[5] = add_res[1];                    
                end
                default: begin end
            endcase

        end
        default: begin end
    endcase
end
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_add_3 (
    .a(add_num[4]), 
    .b(add_num[5]), 
    .rnd(3'b0), 
    .z(add_res[2])); 

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) add_res_reg <= 'b0;
    else       add_res_reg <= add_res[1];
end
// cmp
always @(*) begin
    for(i = 0; i < 4; i = i + 1) begin
        cmp_num[i] = 'b0;
    end

    case (loop)
        7: begin
            case (cnt)
                0: begin
                    cmp_num[0] = equalization[0][0][0];
                    cmp_num[1] = equalization[0][0][1];
                    cmp_num[2] = equalization[0][1][0];
                    cmp_num[3] = equalization[0][1][1];
                end
                2: begin
                    cmp_num[0] = equalization[0][0][2];
                    cmp_num[1] = equalization[0][0][3];
                    cmp_num[2] = equalization[0][1][2];
                    cmp_num[3] = equalization[0][1][3];                    
                end
                8: begin
                    cmp_num[0] = equalization[0][2][0];
                    cmp_num[1] = equalization[0][2][1];
                    cmp_num[2] = equalization[0][3][0];
                    cmp_num[3] = equalization[0][3][1];                    
                end
                default: begin end
            endcase
        end 
        8: begin
            case (cnt)
                10: begin
                    cmp_num[0] = equalization[0][2][2];
                    cmp_num[1] = equalization[0][2][3];
                    cmp_num[2] = equalization[0][3][2];
                    cmp_num[3] = equalization[0][3][3];                    
                end
                0: begin
                    cmp_num[0] = equalization[1][0][0];
                    cmp_num[1] = equalization[1][0][1];
                    cmp_num[2] = equalization[1][1][0];
                    cmp_num[3] = equalization[1][1][1];
                end
                2: begin
                    cmp_num[0] = equalization[1][0][2];
                    cmp_num[1] = equalization[1][0][3];
                    cmp_num[2] = equalization[1][1][2];
                    cmp_num[3] = equalization[1][1][3];                    
                end
                8: begin
                    cmp_num[0] = equalization[1][2][0];
                    cmp_num[1] = equalization[1][2][1];
                    cmp_num[2] = equalization[1][3][0];
                    cmp_num[3] = equalization[1][3][1];                    
                end
                default: begin end
            endcase
        end
        9: begin
            case (cnt)
                10: begin
                    cmp_num[0] = equalization[1][2][2];
                    cmp_num[1] = equalization[1][2][3];
                    cmp_num[2] = equalization[1][3][2];
                    cmp_num[3] = equalization[1][3][3]; 
                end
                // 12, 13, 0, 1: begin
                12, 13: begin
                    cmp_num[0] = fully_connect[0][0];
                    cmp_num[1] = fully_connect[0][1];
                    cmp_num[2] = fully_connect[0][2];
                    cmp_num[3] = fully_connect[0][3];                     
                end
                // 14, 15, 2, 3, 4, 5: begin
                14, 15: begin
                    cmp_num[0] = fully_connect[1][0];
                    cmp_num[1] = fully_connect[1][1];
                    cmp_num[2] = fully_connect[1][2];
                    cmp_num[3] = fully_connect[1][3];                     
                end
                default: begin end
            endcase
        end
        default: begin end
    endcase
end
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_cmp_1 ( 
    .a(cmp_num[0]), 
    .b(cmp_num[1]), 
    .zctr(1'b1),
    .agtb(cmp_res[0]),
    .z0(cmp_num[4]), 
    .z1(cmp_num[5]));

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_cmp_2 ( 
    .a(cmp_num[2]), 
    .b(cmp_num[3]), 
    .zctr(1'b1), 
    .agtb(cmp_res[1]),
    .z0(cmp_num[6]), 
    .z1(cmp_num[7]));
    
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_cmp_3 ( 
    .a(cmp_num[4]), 
    .b(cmp_num[6]), 
    .zctr(1'b1), 
    .agtb(cmp_res[2]),
    .z0(max),
    .z1(mid[1]));

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_cmp_4 ( 
    .a(cmp_num[5]), 
    .b(cmp_num[7]), 
    .zctr(1'b1), 
    .agtb(cmp_res[3]),
    .z0(mid[0]),
    .z1(min));

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 2; i = i + 1) cmp_res_reg[i] <= 'b0;
    end
    else begin
        case (loop)
            9: begin
                case (cnt)
                    12, 13: begin
                        cmp_res_reg[0] <= cmp_res;
                        cmp_res_reg[1] <= cmp_res_reg[1];                        
                    end
                    14, 15: begin
                        cmp_res_reg[0] <= cmp_res_reg[0];
                        cmp_res_reg[1] <= cmp_res;                        
                    end
                    default: begin end
                endcase
            end 
            default: begin end 
        endcase
        // if(cnt === 0) begin
        //     cmp_res_reg[0] <= cmp_res;
        //     cmp_res_reg[1] <= cmp_res_reg[1];
        // end
        // else begin
        //     cmp_res_reg[0] <= cmp_res_reg[0];
        //     cmp_res_reg[1] <= cmp_res;            
        // end
    end
end

// rec    
always @(*) begin
    for(i = 0; i < 2; i = i + 1) rec_num[i] = 'b0;

    case (loop)
        9: begin
            case (cnt)
                12, 14: begin
                    rec_num[0] = add_res[2];
                end 
                15, 0, 1, 2: begin
                    rec_num[0] = add_res[0];                 
                end
                default: begin end
            endcase
        end 
        default: begin end
    endcase
end
DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) U_recip_1 (
    .a(rec_num[0]),
    .rnd(3'b0),
    .z(rec_res_next[0]));
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 2; i = i + 1) rec_res[i] <= 'b0;
    end
    else begin
        for(i = 0; i < 2; i = i + 1) rec_res[i] <= rec_res_next[i];
    end
end

// exp
always @(*) begin
    exp_num = 'b0;
    
    case (loop)
        9: begin
            case (cnt)
                14: begin
                    case (cmp_res_reg[0])
                        1, 3, 8, 9, 10, 11, 12, 14: exp_num = normaliztion[0][0];
                        0, 2, 13, 15: exp_num = normaliztion[0][1];
                        4, 5, 6, 7: exp_num = normaliztion[0][2];
                        default: begin end
                    endcase                    
                end
                15: begin 
                    case (cmp_res_reg[0])
                        8, 9, 10, 11: exp_num = normaliztion[0][1];
                        0, 1, 14, 15: exp_num = normaliztion[0][2];
                        2, 3, 4, 5, 6, 7, 12, 13: exp_num = normaliztion[0][3]; 
                        default: begin end
                    endcase
                end
                0: begin 
                    case (cmp_res_reg[1])
                        1, 3, 8, 9, 10, 11, 12, 14: exp_num = normaliztion[1][0];
                        0, 2, 13, 15: exp_num = normaliztion[1][1];
                        4, 5, 6, 7: exp_num = normaliztion[1][2];
                        default: begin end
                    endcase   
                end
                1: begin 
                    case (cmp_res_reg[1])
                        8, 9, 10, 11: exp_num = normaliztion[1][1];
                        0, 1, 14, 15: exp_num = normaliztion[1][2];
                        2, 3, 4, 5, 6, 7, 12, 13: exp_num = normaliztion[1][3]; 
                        default: begin end
                    endcase
                end
                default: begin end
            endcase 
        end 
        default: begin end 
    endcase
end
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U_exp_1 (
    .a(exp_num),
    .z(exp_res_next[0]));
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U_exp_2 (
    .a({~exp_num[31],exp_num[30:0]}),
    .z(exp_res_next[1]));
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 2; i = i + 1) exp_res[i] <= 'b0;
    end
    else begin
        for(i = 0; i < 2; i = i + 1) exp_res[i] <= exp_res_next[i];
    end       
end
// feature map
always @(*) begin
    for(i = 0; i < 2; i = i + 1) begin
        for(j = 0; j < 4; j = j + 1) begin
            for(k = 0; k < 4; k = k + 1) begin
                feature_map_next[i][j][k] = feature_map[i][j][k]; 
            end
        end
    end
    
    case (loop)
        1: begin
            case (cnt)
                10: feature_map_next[0][0][0] = add_res[2];
                11: feature_map_next[0][0][1] = add_res[2];
                12: feature_map_next[0][0][2] = add_res[2];
                13: feature_map_next[0][0][3] = add_res[2];
                14: feature_map_next[0][1][0] = add_res[2];
                15: feature_map_next[0][1][1] = add_res[2];
                0 : feature_map_next[0][1][2] = add_res[2];
                1 : feature_map_next[0][1][3] = add_res[2];
                2 : feature_map_next[0][2][0] = add_res[2];
                3 : feature_map_next[0][2][1] = add_res[2];
                4 : feature_map_next[0][2][2] = add_res[2];
                5 : feature_map_next[0][2][3] = add_res[2];
                6 : feature_map_next[0][3][0] = add_res[2];
                7 : feature_map_next[0][3][1] = add_res[2];
                8 : feature_map_next[0][3][2] = add_res[2];
                // 9 : feature_map_next[1][3][3] = add_res[2];
                default: begin end
            endcase            
        end
        2, 3: begin
            case (cnt)
                10: feature_map_next[0][0][0] = add_res[2];
                11: feature_map_next[0][0][1] = add_res[2];
                12: feature_map_next[0][0][2] = add_res[2];
                13: feature_map_next[0][0][3] = add_res[2];
                14: feature_map_next[0][1][0] = add_res[2];
                15: feature_map_next[0][1][1] = add_res[2];
                0 : feature_map_next[0][1][2] = add_res[2];
                1 : feature_map_next[0][1][3] = add_res[2];
                2 : feature_map_next[0][2][0] = add_res[2];
                3 : feature_map_next[0][2][1] = add_res[2];
                4 : feature_map_next[0][2][2] = add_res[2];
                5 : feature_map_next[0][2][3] = add_res[2];
                6 : feature_map_next[0][3][0] = add_res[2];
                7 : feature_map_next[0][3][1] = add_res[2];
                8 : feature_map_next[0][3][2] = add_res[2];
                9 : feature_map_next[0][3][3] = add_res[2];
                default: begin end
            endcase            
        end 
        4: begin
            case (cnt)
                10: feature_map_next[1][0][0] = add_res[2];
                11: feature_map_next[1][0][1] = add_res[2];
                12: feature_map_next[1][0][2] = add_res[2];
                13: feature_map_next[1][0][3] = add_res[2];
                14: feature_map_next[1][1][0] = add_res[2];
                15: feature_map_next[1][1][1] = add_res[2];
                0 : feature_map_next[1][1][2] = add_res[2];
                1 : feature_map_next[1][1][3] = add_res[2];
                2 : feature_map_next[1][2][0] = add_res[2];
                3 : feature_map_next[1][2][1] = add_res[2];
                4 : feature_map_next[1][2][2] = add_res[2];
                5 : feature_map_next[1][2][3] = add_res[2];
                6 : feature_map_next[1][3][0] = add_res[2];
                7 : feature_map_next[1][3][1] = add_res[2];
                8 : feature_map_next[1][3][2] = add_res[2];
                9 : feature_map_next[0][3][3] = add_res[2];
                default: begin end
            endcase             
        end
        5, 6: begin
            case (cnt)
                10: feature_map_next[1][0][0] = add_res[2];
                11: feature_map_next[1][0][1] = add_res[2];
                12: feature_map_next[1][0][2] = add_res[2];
                13: feature_map_next[1][0][3] = add_res[2];
                14: feature_map_next[1][1][0] = add_res[2];
                15: feature_map_next[1][1][1] = add_res[2];
                0 : feature_map_next[1][1][2] = add_res[2];
                1 : feature_map_next[1][1][3] = add_res[2];
                2 : feature_map_next[1][2][0] = add_res[2];
                3 : feature_map_next[1][2][1] = add_res[2];
                4 : feature_map_next[1][2][2] = add_res[2];
                5 : feature_map_next[1][2][3] = add_res[2];
                6 : feature_map_next[1][3][0] = add_res[2];
                7 : feature_map_next[1][3][1] = add_res[2];
                8 : feature_map_next[1][3][2] = add_res[2];
                9 : feature_map_next[1][3][3] = add_res[2];
                default: begin end
            endcase            
        end
        7: begin
            case (cnt)
                9 : feature_map_next[1][3][3] = add_res[2];
                default: begin end
            endcase           
        end
        default: begin end 
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 2; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                for(k = 0; k < 4; k = k + 1) begin
                    feature_map[i][j][k] <= 'b0;
                end
            end
        end
    end
    else begin
        if(state === IDLE) begin
            for(i = 0; i < 2; i = i + 1) begin
                for(j = 0; j < 4; j = j + 1) begin
                    for(k = 0; k < 4; k = k + 1) begin
                        feature_map[i][j][k] <= 'b0;
                    end
                end
            end            
        end
        else begin
            for(i = 0; i < 2; i = i + 1) begin
                for(j = 0; j < 4; j = j + 1) begin
                    for(k = 0; k < 4; k = k + 1) begin
                        feature_map[i][j][k] <= feature_map_next[i][j][k];
                    end
                end
            end            
        end
    end
end

// equalization
always @(*) begin
    for(i = 0; i < 2; i = i + 1) begin
        for(j = 0; j < 4; j = j + 1) begin
            for(k = 0; k < 4; k = k + 1) begin
                equalization_next[i][j][k] = equalization[i][j][k]; 
            end
        end
    end
    
    case (loop)
        7: begin
            case (cnt)
                10: equalization_next[0][0][0] = add_res[2];
                11: equalization_next[0][0][1] = add_res[2];
                12: equalization_next[0][0][2] = add_res[2];
                13: equalization_next[0][0][3] = add_res[2];
                14: equalization_next[0][1][0] = add_res[2];
                15: equalization_next[0][1][1] = add_res[2];
                0 : equalization_next[0][1][2] = add_res[2];
                1 : equalization_next[0][1][3] = add_res[2];
                2 : equalization_next[0][2][0] = add_res[2];
                3 : equalization_next[0][2][1] = add_res[2];
                4 : equalization_next[0][2][2] = add_res[2];
                5 : equalization_next[0][2][3] = add_res[2];
                6 : equalization_next[0][3][0] = add_res[2];
                7 : equalization_next[0][3][1] = add_res[2];
                8 : equalization_next[0][3][2] = add_res[2];
                // 9 : equalization_next[1][3][3] = add_res[2];
                default: begin end
            endcase            
        end
        8: begin
            case (cnt)
                10: equalization_next[1][0][0] = add_res[2];
                11: equalization_next[1][0][1] = add_res[2];
                12: equalization_next[1][0][2] = add_res[2];
                13: equalization_next[1][0][3] = add_res[2];
                14: equalization_next[1][1][0] = add_res[2];
                15: equalization_next[1][1][1] = add_res[2];
                0 : equalization_next[1][1][2] = add_res[2];
                1 : equalization_next[1][1][3] = add_res[2];
                2 : equalization_next[1][2][0] = add_res[2];
                3 : equalization_next[1][2][1] = add_res[2];
                4 : equalization_next[1][2][2] = add_res[2];
                5 : equalization_next[1][2][3] = add_res[2];
                6 : equalization_next[1][3][0] = add_res[2];
                7 : equalization_next[1][3][1] = add_res[2];
                8 : equalization_next[1][3][2] = add_res[2];
                9 : equalization_next[0][3][3] = add_res[2];
                default: begin end
            endcase             
        end
        9: begin
            case (cnt)
                9 : equalization_next[1][3][3] = add_res[2];
                default: begin end
            endcase           
        end
        default: begin end 
    endcase  
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 2; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                for(k = 0; k < 4; k = k + 1) begin
                    equalization[i][j][k] <= 'b0;
                end
            end
        end
    end
    else begin
        if(state === IDLE) begin
            for(i = 0; i < 2; i = i + 1) begin
                for(j = 0; j < 4; j = j + 1) begin
                    for(k = 0; k < 4; k = k + 1) begin
                        equalization[i][j][k] <= 'b0;
                    end
                end
            end            
        end
        else begin
            for(i = 0; i < 2; i = i + 1) begin
                for(j = 0; j < 4; j = j + 1) begin
                    for(k = 0; k < 4; k = k + 1) begin
                        equalization[i][j][k] <= equalization_next[i][j][k];
                    end
                end
            end            
        end
    end    
end

// max pooling block       
always @(*) begin
    for(i = 0; i < 2; i = i + 1) begin
        for(j = 0; j < 2; j = j + 1) begin
            for(k = 0; k < 2; k = k + 1) begin
                max_pooling_next[i][j][k] = max_pooling[i][j][k];
            end
        end
    end

    case (loop)
        7: begin
            case (cnt)
                0: begin
                    max_pooling_next[0][0][0] = max;
                end
                2: begin
                    max_pooling_next[0][0][1] = max;                    
                end
                8:begin
                    max_pooling_next[0][1][0] = max;                   
                end
                // 9:begin
                //     max_pooling_next[0][1][1] = max;                    
                // end
                default: begin end
            endcase
        end 
        8: begin
            case (cnt)
                10:begin
                    max_pooling_next[0][1][1] = max;
                end
                0: begin
                    max_pooling_next[1][0][0] = max;
                end
                2: begin
                    max_pooling_next[1][0][1] = max;                    
                end
                8:begin
                    max_pooling_next[1][1][0] = max;                   
                end                    
                default: begin end
            endcase            
        end
        9: begin
            case (cnt)
                10:begin
                    max_pooling_next[1][1][1] = max;                    
                end
                default: begin end
            endcase            
        end
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 2; i = i + 1) begin
            for(j = 0; j < 2; j = j + 1) begin
                for(k = 0; k < 2; k = k + 1) begin
                    max_pooling[i][j][k] <= 'b0;
                end
            end
        end
    end
    else begin
        if(state === IDLE) begin
            for(i = 0; i < 2; i = i + 1) begin
                for(j = 0; j < 2; j = j + 1) begin
                    for(k = 0; k < 2; k = k + 1) begin
                        max_pooling[i][j][k] <= 'b0;
                    end
                end
            end
        end
        else begin
            for(i = 0; i < 2; i = i + 1) begin
                for(j = 0; j < 2; j = j + 1) begin
                    for(k = 0; k < 2; k = k + 1) begin
                        max_pooling[i][j][k] <= max_pooling_next[i][j][k];
                    end
                end
            end            
        end
    end
end

// fully connect block
always @(*) begin
    for(i = 0; i < 2; i = i + 1) begin
        for(j = 0; j < 4; j = j + 1) begin
            fully_connect_next[i][j] = fully_connect[i][j];
        end
    end
    case (loop)
        9: begin
            case (cnt)
                9 : begin
                    fully_connect_next[0][0] = dot_res_next[0];
                    fully_connect_next[0][1] = dot_res_next[1];
                end
                10: begin
                    fully_connect_next[0][2] = dot_res_next[0];
                    fully_connect_next[0][3] = dot_res_next[1];
                end
                11: begin
                    fully_connect_next[1][0] = dot_res_next[0];
                    fully_connect_next[1][1] = dot_res_next[1];
                end
                12: begin
                    fully_connect_next[1][2] = dot_res_next[0];
                    fully_connect_next[1][3] = dot_res_next[1];
                end
                default: begin end
            endcase
        end
        default: begin end
    endcase    
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 2; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                fully_connect[i][j] <= 'b0;
            end
        end
    end
    else begin
        if(state === IDLE) begin
            for(i = 0; i < 2; i = i + 1) begin
                for(j = 0; j < 4; j = j + 1) begin
                    fully_connect[i][j] <= 'b0;
                end
            end             
        end
        else begin
            for(i = 0; i < 2; i = i + 1) begin
                for(j = 0; j < 4; j = j + 1) begin
                    fully_connect[i][j] <= fully_connect_next[i][j];
                end
            end             
        end
    end
end

// normalization block
always @(*) begin
    for(i = 0; i < 2; i = i + 1) begin
        for(j = 0; j < 4; j = j + 1) begin
            normaliztion_next[i][j] = normaliztion[i][j];
        end
    end
    case (loop)
        9: begin
            case (cnt)
                13: begin
                    case (cmp_res_reg[0])
                        0: begin
                            normaliztion_next[0][0] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[0][1] = dot_res_next[1];
                            normaliztion_next[0][2] = dot_res_next[0];
                            normaliztion_next[0][3] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                        end
                        1: begin
                            normaliztion_next[0][0] = dot_res_next[1];
                            normaliztion_next[0][1] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[0][2] = dot_res_next[0];
                            normaliztion_next[0][3] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;                    
                        end
                        2: begin
                            normaliztion_next[0][0] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[0][1] = dot_res_next[1];
                            normaliztion_next[0][2] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[0][3] = dot_res_next[0];                    
                        end
                        3: begin
                            normaliztion_next[0][0] = dot_res_next[1];
                            normaliztion_next[0][1] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[0][2] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[0][3] = dot_res_next[0];                    
                        end
                        4: begin
                            normaliztion_next[0][0] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[0][1] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[0][2] = dot_res_next[0];
                            normaliztion_next[0][3] = dot_res_next[1];
                        end
                        5: begin
                            normaliztion_next[0][0] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[0][1] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[0][2] = dot_res_next[0];
                            normaliztion_next[0][3] = dot_res_next[1];
                        end
                        6: begin
                            normaliztion_next[0][0] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[0][1] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[0][2] = dot_res_next[1];
                            normaliztion_next[0][3] = dot_res_next[0];                    
                        end
                        7: begin
                            normaliztion_next[0][0] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[0][1] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[0][2] = dot_res_next[1];
                            normaliztion_next[0][3] = dot_res_next[0];                    
                        end
                        8: begin
                            normaliztion_next[0][0] = dot_res_next[0];
                            normaliztion_next[0][1] = dot_res_next[1];
                            normaliztion_next[0][2] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[0][3] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                        end
                        9: begin
                            normaliztion_next[0][0] = dot_res_next[1];
                            normaliztion_next[0][1] = dot_res_next[0];
                            normaliztion_next[0][2] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[0][3] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;                    
                        end
                        10: begin
                            normaliztion_next[0][0] = dot_res_next[0];
                            normaliztion_next[0][1] = dot_res_next[1];
                            normaliztion_next[0][2] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[0][3] = (option_reg[1]) ? 0 : 36'h3f000000;                    
                        end
                        11: begin
                            normaliztion_next[0][0] = dot_res_next[1];
                            normaliztion_next[0][1] = dot_res_next[0];
                            normaliztion_next[0][2] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[0][3] = (option_reg[1]) ? 0 : 36'h3f000000;
                        end
                        12: begin
                            normaliztion_next[0][0] = dot_res_next[0];
                            normaliztion_next[0][1] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[0][2] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[0][3] = dot_res_next[1];
                        end
                        13: begin
                            normaliztion_next[0][0] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[0][1] = dot_res_next[0];
                            normaliztion_next[0][2] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[0][3] = dot_res_next[1];
                        end
                        14: begin
                            normaliztion_next[0][0] = dot_res_next[0];
                            normaliztion_next[0][1] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[0][2] = dot_res_next[1];
                            normaliztion_next[0][3] = (option_reg[1]) ? 0 : 36'h3f000000;                    
                        end
                        15: begin
                            normaliztion_next[0][0] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[0][1] = dot_res_next[0];
                            normaliztion_next[0][2] = dot_res_next[1];
                            normaliztion_next[0][3] = (option_reg[1]) ? 0 : 36'h3f000000;                    
                        end
                        default: begin end
                    endcase
                end 
                15: begin
                    case (cmp_res_reg[1])
                        0: begin
                            normaliztion_next[1][0] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[1][1] = dot_res_next[1];
                            normaliztion_next[1][2] = dot_res_next[0];
                            normaliztion_next[1][3] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                        end
                        1: begin
                            normaliztion_next[1][0] = dot_res_next[1];
                            normaliztion_next[1][1] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[1][2] = dot_res_next[0];
                            normaliztion_next[1][3] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;                    
                        end
                        2: begin
                            normaliztion_next[1][0] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[1][1] = dot_res_next[1];
                            normaliztion_next[1][2] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[1][3] = dot_res_next[0];                    
                        end
                        3: begin
                            normaliztion_next[1][0] = dot_res_next[1];
                            normaliztion_next[1][1] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[1][2] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[1][3] = dot_res_next[0];                    
                        end
                        4: begin
                            normaliztion_next[1][0] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[1][1] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[1][2] = dot_res_next[0];
                            normaliztion_next[1][3] = dot_res_next[1];
                        end
                        5: begin
                            normaliztion_next[1][0] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[1][1] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[1][2] = dot_res_next[0];
                            normaliztion_next[1][3] = dot_res_next[1];
                        end
                        6: begin
                            normaliztion_next[1][0] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[1][1] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[1][2] = dot_res_next[1];
                            normaliztion_next[1][3] = dot_res_next[0];                    
                        end
                        7: begin
                            normaliztion_next[1][0] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[1][1] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[1][2] = dot_res_next[1];
                            normaliztion_next[1][3] = dot_res_next[0];                    
                        end
                        8: begin
                            normaliztion_next[1][0] = dot_res_next[0];
                            normaliztion_next[1][1] = dot_res_next[1];
                            normaliztion_next[1][2] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[1][3] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                        end
                        9: begin
                            normaliztion_next[1][0] = dot_res_next[1];
                            normaliztion_next[1][1] = dot_res_next[0];
                            normaliztion_next[1][2] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[1][3] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;                    
                        end
                        10: begin
                            normaliztion_next[1][0] = dot_res_next[0];
                            normaliztion_next[1][1] = dot_res_next[1];
                            normaliztion_next[1][2] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[1][3] = (option_reg[1]) ? 0 : 36'h3f000000;                    
                        end
                        11: begin
                            normaliztion_next[1][0] = dot_res_next[1];
                            normaliztion_next[1][1] = dot_res_next[0];
                            normaliztion_next[1][2] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[1][3] = (option_reg[1]) ? 0 : 36'h3f000000;
                        end
                        12: begin
                            normaliztion_next[1][0] = dot_res_next[0];
                            normaliztion_next[1][1] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[1][2] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[1][3] = dot_res_next[1];
                        end
                        13: begin
                            normaliztion_next[1][0] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[1][1] = dot_res_next[0];
                            normaliztion_next[1][2] = (option_reg[1]) ? 0 : 36'h3f000000;
                            normaliztion_next[1][3] = dot_res_next[1];
                        end
                        14: begin
                            normaliztion_next[1][0] = dot_res_next[0];
                            normaliztion_next[1][1] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[1][2] = dot_res_next[1];
                            normaliztion_next[1][3] = (option_reg[1]) ? 0 : 36'h3f000000;                    
                        end
                        15: begin
                            normaliztion_next[1][0] = (option_reg[1]) ? 36'h3f42f7d6 : 36'h3f3b26a8;
                            normaliztion_next[1][1] = dot_res_next[0];
                            normaliztion_next[1][2] = dot_res_next[1];
                            normaliztion_next[1][3] = (option_reg[1]) ? 0 : 36'h3f000000;                    
                        end
                        default: begin end
                    endcase
                end 
                0: begin
                    case (cmp_res_reg[0])
                        1, 3, 8, 9, 10, 11, 12, 14: normaliztion_next[0][0] = dot_res_next[0];
                        0, 2, 13, 15: normaliztion_next[0][1] = dot_res_next[0];
                        4, 5, 6, 7: normaliztion_next[0][2] = dot_res_next[0];
                        default: begin end
                    endcase                    
                end
                1: begin
                    case (cmp_res_reg[0])
                        8, 9, 10, 11: normaliztion_next[0][1] = dot_res_next[0];
                        0, 1, 14, 15: normaliztion_next[0][2] = dot_res_next[0];
                        2, 3, 4, 5, 6, 7, 12, 13: normaliztion_next[0][3] = dot_res_next[0]; 
                        default: begin end
                    endcase                    
                end
                2: begin 
                    case (cmp_res_reg[1])
                        1, 3, 8, 9, 10, 11, 12, 14: normaliztion_next[1][0] = dot_res_next[0];
                        0, 2, 13, 15: normaliztion_next[1][1] = dot_res_next[0];
                        4, 5, 6, 7: normaliztion_next[1][2] = dot_res_next[0];
                        default: begin end
                    endcase 
                end
                3: begin
                    case (cmp_res_reg[1])
                        8, 9, 10, 11: normaliztion_next[1][1] = dot_res_next[0];
                        0, 1, 14, 15: normaliztion_next[1][2] = dot_res_next[0];
                        2, 3, 4, 5, 6, 7, 12, 13: normaliztion_next[1][3] = dot_res_next[0]; 
                        default: begin end
                    endcase                    
                end
                default: begin end
            endcase            
        end 
        default: begin end
    endcase   
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 2; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                normaliztion[i][j] <= 'b0;
            end
        end
    end
    else begin
        if(state === IDLE) begin
            for(i = 0; i < 2; i = i + 1) begin
                for(j = 0; j < 4; j = j + 1) begin
                    normaliztion[i][j] <= 'b0;
                end
            end            
        end
        else begin
            for(i = 0; i < 2; i = i + 1) begin
                for(j = 0; j < 4; j = j + 1) begin
                    normaliztion[i][j] <= normaliztion_next[i][j];
                end
            end            
        end

    end
end

//==============================================//
//                Output Block                  //
//==============================================//
always @(*) begin
    out_next = out;
    case (loop)
        9: begin
            case (cnt)
                5: begin
                    out_next = add_res[2];
                end
                default: begin end
            endcase
        end
        default: begin end 
    endcase
end
always @(*) begin
    out_valid_next = 0;
    case (loop)
        68: begin
            case (cnt)
            5: begin
                out_valid_next = 1;
            end
            default: begin end
        endcase
        end
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out <= 'b0;
    end
    else begin
        out_valid <= out_valid_next;
        out <= out_next;
    end
end

endmodule
