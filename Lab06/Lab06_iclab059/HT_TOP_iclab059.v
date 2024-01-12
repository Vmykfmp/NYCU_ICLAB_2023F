//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : HT_TOP.v
//   	Module Name : HT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "SORT_IP.v"
//synopsys translate_on

module HT_TOP(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_weight, 
	out_mode,
    // Output signals
    out_valid, 
	out_code
);
parameter IDLE  = 4'd0;
parameter INPUT = 4'd1;
parameter STEP1 = 4'd2;
parameter STEP2 = 4'd3;
parameter STEP3 = 4'd4;
parameter STEP4 = 4'd5;
parameter STEP5 = 4'd6;
parameter STEP6 = 4'd7;
parameter STEP7 = 4'd8;
parameter OUT1  = 4'd9;
parameter OUT2  = 4'd10;
parameter OUT3  = 4'd11;
parameter OUT4  = 4'd12;
parameter OUT5  = 4'd13;

parameter IP_WIDTH = 8;

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid, out_mode;
input [2:0] in_weight;

output reg out_valid, out_code;

// ===============================================================
// Reg & Wire Declaration
// ===============================================================
reg [3:0] state;
reg [3:0] state_next;
reg [4:0] cnt;
reg [4:0] cnt_next;

reg mode_reg;
reg mode_next;
reg [4:0] weight_reg  [0:15];
reg [4:0] weight_next [0:15];
reg [7:0] tree      [0:15];
reg [7:0] tree_next [0:15];
reg [6:0] code      [0:7];
reg [6:0] code_next [0:7];
reg [2:0] cnt_bit      [0:7];
reg [2:0] cnt_bit_next [0:7];

reg [31:0] in_character_SORT;
reg [39:0] in_weight_SORT;
reg [31:0] out_character_reg;
reg [31:0] out_character_next;
wire [31:0] out_character;

integer i, j;
// ===============================================================
// Design
// ===============================================================
// FSM
always @(*) begin
    case (state)
        IDLE: begin
            if(in_valid) state_next = INPUT;
            else         state_next = IDLE;
        end 
        INPUT: begin
            // if(cnt == 5'd7) state_next = OUTPUT;
            if(cnt == 5'd7) state_next = STEP1;
            else            state_next = INPUT;
        end
        STEP1: state_next = STEP2;
        STEP2: state_next = STEP3;
        STEP3: state_next = STEP4;
        STEP4: state_next = STEP5;
        STEP5: state_next = STEP6;
        STEP6: state_next = STEP7;
        STEP7: state_next = OUT1;
        OUT1: begin
            if(cnt == cnt_bit[3]) state_next = OUT2;
            else                  state_next = OUT1;
        end
        OUT2: begin
            if     (!mode_reg && cnt == cnt_bit[2]) state_next = OUT3;
            else if( mode_reg && cnt == cnt_bit[5]) state_next = OUT3;
            else                                    state_next = OUT2;
        end
        OUT3: begin
            if     (!mode_reg && cnt == cnt_bit[1]) state_next = OUT4;
            else if( mode_reg && cnt == cnt_bit[2]) state_next = OUT4;
            else                                    state_next = OUT3;
        end
        OUT4: begin
            if     (!mode_reg && cnt == cnt_bit[0]) state_next = OUT5;
            else if( mode_reg && cnt == cnt_bit[7]) state_next = OUT5;
            else                                    state_next = OUT4;
        end
        OUT5: begin
            if     (!mode_reg && cnt == cnt_bit[4]) state_next = IDLE;
            else if( mode_reg && cnt == cnt_bit[6]) state_next = IDLE;
            else                                    state_next = OUT5;
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
            if(in_valid) cnt_next = cnt + 1;
            else         cnt_next = 'b0;
        end 
        INPUT: begin
            if(cnt == 5'd7) cnt_next = 'b0;
            else            cnt_next = cnt + 1;
        end
        OUT1: begin
            if(cnt == cnt_bit[3]) cnt_next = 'b0;
            else                  cnt_next = cnt + 1;
        end
        OUT2: begin
            if     (!mode_reg && cnt == cnt_bit[2]) cnt_next = 'b0;
            else if( mode_reg && cnt == cnt_bit[5]) cnt_next = 'b0;
            else                                    cnt_next = cnt + 1;
        end
        OUT3: begin
            if     (!mode_reg && cnt == cnt_bit[1]) cnt_next = 'b0;
            else if( mode_reg && cnt == cnt_bit[2]) cnt_next = 'b0;
            else                                    cnt_next = cnt + 1;
        end
        OUT4: begin
            if     (!mode_reg && cnt == cnt_bit[0]) cnt_next = 'b0;
            else if( mode_reg && cnt == cnt_bit[7]) cnt_next = 'b0;
            else                                    cnt_next = cnt + 1;
        end
        OUT5: begin
            if     (!mode_reg && cnt == cnt_bit[4]) cnt_next = 'b0;
            else if( mode_reg && cnt == cnt_bit[6]) cnt_next = 'b0;
            else                                    cnt_next = cnt + 1;
        end
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt <= 'b0;
    else       cnt <= cnt_next;
end
//==============================================//
//                 Input Block                  //
//==============================================//
// mode_reg input
always @(*) begin
    mode_next = mode_reg;
    case (state)
        IDLE: begin
            if(in_valid) mode_next = out_mode;
        end
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) mode_reg <= 'b0;
    else       mode_reg <= mode_next;
end
// weight input
always @(*) begin
    for(i = 0; i < 16; i = i + 1) weight_next[i] = weight_reg[i];
    case (state)
        IDLE: begin
            if(in_valid) begin
                weight_next[15] = in_weight;
            end
        end 
        INPUT: begin
            case (cnt)
                // 0: weight_next[15] = in_weight; 
                1: weight_next[14] = in_weight;
                2: weight_next[13] = in_weight;
                3: weight_next[12] = in_weight;
                4: weight_next[11] = in_weight;
                5: weight_next[10] = in_weight;
                6: weight_next[9]  = in_weight;
                7: weight_next[8]  = in_weight;                   
                default: begin end
            endcase         
        end
        STEP1: begin
            weight_next[7] = weight_reg[out_character[7:4]] + weight_reg[out_character[3:0]];
        end
        STEP2: begin
            weight_next[6] = weight_reg[out_character[7:4]] + weight_reg[out_character[3:0]];
        end
        STEP3: begin
            weight_next[5] = weight_reg[out_character[7:4]] + weight_reg[out_character[3:0]];
        end
        STEP4: begin
            weight_next[4] = weight_reg[out_character[7:4]] + weight_reg[out_character[3:0]];
        end
        STEP5: begin
            weight_next[3] = weight_reg[out_character[7:4]] + weight_reg[out_character[3:0]];
        end
        STEP6: begin
            weight_next[2] = weight_reg[out_character[7:4]] + weight_reg[out_character[3:0]];
        end
        STEP7: begin
            weight_next[1] = weight_reg[out_character[7:4]] + weight_reg[out_character[3:0]];
        end 
        default: begin end 
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            weight_reg[i] <= 'b0;
        end
    end
    else begin
        for(i = 0; i < 16; i = i + 1) begin
            weight_reg[i] <= weight_next[i];
        end
    end
end
//==============================================//
//               Compute Block                  //
//==============================================//
always @(*) begin
    in_character_SORT = 'b0;
    in_weight_SORT    = 40'b1111_1111_1111_1111_1111_1111_1111_1111_1111_1111;
    case (state)
        STEP1: begin
            // in_character_SORT = {CHAR_A, CHAR_B, CHAR_C, CHAR_E, CHAR_I, CHAR_L, CHAR_O, CHAR_V};
            in_character_SORT = {4'd15, 4'd14, 4'd13, 4'd12, 4'd11, 4'd10, 4'd9, 4'd8};
            in_weight_SORT    = {weight_reg[15], weight_reg[14], weight_reg[13], weight_reg[12], 
                                 weight_reg[11], weight_reg[10], weight_reg[9],  weight_reg[8]};
        end
        STEP2: begin
            in_character_SORT   = {4'b1111, out_character_reg[31:8], 4'd7};
            in_weight_SORT[4:0] = weight_reg[out_character_reg[7:4]] + weight_reg[out_character_reg[3:0]]; 
            for(i = 0; i < 6; i = i + 1) begin
                in_weight_SORT[(i * 5 + 5) +:5] = weight_reg[out_character_reg[(i * 4 + 8) +:4]];
            end
        end
        STEP3: begin
            in_character_SORT   = {8'b1111_1111, out_character_reg[27:8], 4'd6};
            in_weight_SORT[4:0] = weight_reg[out_character_reg[7:4]] + weight_reg[out_character_reg[3:0]]; 
            for(i = 0; i < 5; i = i + 1) begin
                in_weight_SORT[(i * 5 + 5) +:5] = weight_reg[out_character_reg[(i * 4 + 8) +:4]];
            end            
        end
        STEP4: begin
            in_character_SORT   = {12'b1111_1111_1111, out_character_reg[23:8], 4'd5};
            in_weight_SORT[4:0] = weight_reg[out_character_reg[7:4]] + weight_reg[out_character_reg[3:0]]; 
            for(i = 0; i < 4; i = i + 1) begin
                in_weight_SORT[(i * 5 + 5) +:5] = weight_reg[out_character_reg[(i * 4 + 8) +:4]];
            end            
        end
        STEP5: begin
            in_character_SORT   = {16'b1111_1111_1111_1111, out_character_reg[19:8], 4'd4};
            in_weight_SORT[4:0] = weight_reg[out_character_reg[7:4]] + weight_reg[out_character_reg[3:0]]; 
            for(i = 0; i < 3; i = i + 1) begin
                in_weight_SORT[(i * 5 + 5) +:5] = weight_reg[out_character_reg[(i * 4 + 8) +:4]];
            end           
        end
        STEP6: begin
            in_character_SORT   = {20'b1111_1111_1111_1111_1111, out_character_reg[15:8], 4'd3};
            in_weight_SORT[4:0] = weight_reg[out_character_reg[7:4]] + weight_reg[out_character_reg[3:0]]; 
            for(i = 0; i < 2; i = i + 1) begin
                in_weight_SORT[(i * 5 + 5) +:5] = weight_reg[out_character_reg[(i * 4 + 8) +:4]];
            end          
        end
        STEP7: begin
            in_character_SORT   = {24'd0, out_character_reg[11:8], 4'd2};
            in_weight_SORT[4:0] = weight_reg[out_character_reg[7:4]] + weight_reg[out_character_reg[3:0]]; 
            for(i = 0; i < 1; i = i + 1) begin
                in_weight_SORT[(i * 5 + 5) +:5] = weight_reg[out_character_reg[(i * 4 + 8) +:4]];
            end             
        end
        default: begin end
    endcase
end

SORT_IP #(.IP_WIDTH(IP_WIDTH)) 
SORT_U0(.IN_character(in_character_SORT), 
        .IN_weight(in_weight_SORT), 
        .OUT_character(out_character));

always @(*)begin
    out_character_next = 'b0;
    case (state)
        STEP1, STEP2, STEP3, STEP4, STEP5, STEP6, STEP7: out_character_next = out_character; 
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_character_reg <= 'b0;
    else       out_character_reg <= out_character_next;
end
// tree
always @(*) begin
    for(i = 0; i < 16; i = i + 1) begin
        tree_next[i] = tree[i];
        // for(j = 0; j < 8; j = j + 1) begin
        //     tree_next[i][j] = tree[i][j];
        // end
    end

    case (state)
        IDLE: begin
            for(i = 8; i < 16; i = i + 1) begin
                tree_next[i] = 'b0;
            end
        end
        INPUT: begin
            for(i = 8; i < 16; i = i + 1) begin
                tree_next[i][i - 8] = 1;
            end
        end
        STEP1: begin
            tree_next[7] = tree[out_character[7:4]] | tree[out_character[3:0]];
        end
        STEP2: begin
            tree_next[6] = tree[out_character[7:4]] | tree[out_character[3:0]];
        end
        STEP3: begin
            tree_next[5] = tree[out_character[7:4]] | tree[out_character[3:0]];
        end
        STEP4: begin
            tree_next[4] = tree[out_character[7:4]] | tree[out_character[3:0]];
        end
        STEP5: begin
            tree_next[3] = tree[out_character[7:4]] | tree[out_character[3:0]];
        end
        STEP6: begin
            tree_next[2] = tree[out_character[7:4]] | tree[out_character[3:0]];
        end
        STEP7: begin
            tree_next[1] = tree[out_character[7:4]] | tree[out_character[3:0]];
        end 
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            tree[i] <= 'b0;
            // for(j = 0; j < 8; j = j + 1) begin
            //     tree[i][j] <= 'b0;
            // end
        end
    end
    else begin
        for(i = 0; i < 16; i = i + 1) begin
            tree[i] <= tree_next[i];
            // for(j = 0; j < 8; j = j + 1) begin
            //     tree[i][j] <= tree_next[i][j];
            // end
        end        
    end
end
// code
always @(*) begin
    for(i = 0; i < 8; i = i + 1) begin
        code_next[i] = code[i]; 
    end

    case (state)
        IDLE: begin
            for(i = 0; i < 8; i = i + 1) code_next[i] = code[i];          
        end
        STEP1, STEP2, STEP3, STEP4, STEP5, STEP6, STEP7: begin
            for(i = 0; i < 8; i = i + 1) begin
                if(tree[out_character[7:4]][i]) code_next[i][6:0] = {code[i][6:0], 1'b0}; 
            end
            for(i = 0; i < 8; i = i + 1) begin
                if(tree[out_character[3:0]][i]) code_next[i][6:0] = {code[i][6:0], 1'b1}; 
            end
        end 
        // STEP2: begin
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[7:4]][i]) code_next[i][6:0] = {code[i][6:0], 1'b0}; 
        //     end
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[3:0]][i]) code_next[i][6:0] = {code[i][6:0], 1'b1}; 
        //     end          
        // end
        // STEP3: begin
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[7:4]][i]) code_next[i][6:0] = {code[i][6:0], 1'b0}; 
        //     end
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[3:0]][i]) code_next[i][6:0] = {code[i][6:0], 1'b1}; 
        //     end          
        // end
        // STEP4: begin
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[7:4]][i]) code_next[i][6:0] = {code[i][6:0], 1'b0}; 
        //     end
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[3:0]][i]) code_next[i][6:0] = {code[i][6:0], 1'b1}; 
        //     end        
        // end
        // STEP5: begin
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[7:4]][i]) code_next[i][6:0] = {code[i][6:0], 1'b0}; 
        //     end
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[3:0]][i]) code_next[i][6:0] = {code[i][6:0], 1'b1}; 
        //     end         
        // end
        // STEP6: begin
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[7:4]][i]) code_next[i][6:0] = {code[i][6:0], 1'b0}; 
        //     end
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[3:0]][i]) code_next[i][6:0] = {code[i][6:0], 1'b1}; 
        //     end        
        // end
        // STEP7: begin
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[7:4]][i]) code_next[i][6:0] = {code[i][6:0], 1'b0}; 
        //     end
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[3:0]][i]) code_next[i][6:0] = {code[i][6:0], 1'b1}; 
        //     end            
        // end
        default: begin end 
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 8; i = i + 1) begin
            code[i] <= 'b0; 
        end
    end
    else begin
        for(i = 0; i < 8; i = i + 1) begin
            code[i] <= code_next[i]; 
        end        
    end
end
// cnt
always @(*) begin
    for(i = 0; i < 8; i = i + 1) cnt_bit_next[i] = cnt_bit[i];

    case (state)
        IDLE: begin
            for(i = 0; i < 8; i = i + 1) cnt_bit_next[i] = -1;
            // for(i = 0; i < 8; i = i + 1) cnt_bit_next[i] = 'b0;
        end
        STEP1, STEP2, STEP3, STEP4, STEP5, STEP6, STEP7: begin
            for(i = 0; i < 8; i = i + 1) begin
                if(tree[out_character[7:4]][i]) cnt_bit_next[i] = cnt_bit[i] + 1; 
            end
            for(i = 0; i < 8; i = i + 1) begin
                if(tree[out_character[3:0]][i]) cnt_bit_next[i] = cnt_bit[i] + 1; 
            end
        end 
        // STEP2: begin
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[7:4]][i]) cnt_bit_next[i] = cnt_bit[i] + 1; 
        //     end
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[3:0]][i]) cnt_bit_next[i] = cnt_bit[i] + 1; 
        //     end            
        // end
        // STEP3: begin
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[7:4]][i]) cnt_bit_next[i] = cnt_bit[i] + 1; 
        //     end
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[3:0]][i]) cnt_bit_next[i] = cnt_bit[i] + 1; 
        //     end           
        // end
        // STEP4: begin
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[7:4]][i]) cnt_bit_next[i] = cnt_bit[i] + 1; 
        //     end
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[3:0]][i]) cnt_bit_next[i] = cnt_bit[i] + 1; 
        //     end         
        // end
        // STEP5: begin
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[7:4]][i]) cnt_bit_next[i] = cnt_bit[i] + 1; 
        //     end
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[3:0]][i]) cnt_bit_next[i] = cnt_bit[i] + 1; 
        //     end        
        // end
        // STEP6: begin
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[7:4]][i]) cnt_bit_next[i] = cnt_bit[i] + 1; 
        //     end
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[3:0]][i]) cnt_bit_next[i] = cnt_bit[i] + 1; 
        //     end       
        // end
        // STEP7: begin
        //     for(i = 0; i < 8; i = i + 1) begin  
        //         if(tree[out_character[7:4]][i]) cnt_bit_next[i] = cnt_bit[i] + 1; 
        //     end
        //     for(i = 0; i < 8; i = i + 1) begin
        //         if(tree[out_character[3:0]][i]) cnt_bit_next[i] = cnt_bit[i] + 1; 
        //     end          
        // end
        default: begin end
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 8; i = i + 1) cnt_bit[i] <= 'b0;
    end
    else begin
        for(i = 0; i < 8; i = i + 1) cnt_bit[i] <= cnt_bit_next[i];
    end
end
//==============================================//
//                Output Block                  //
//==============================================//
always @(*) begin
    if(!rst_n) begin
        out_valid = 'b0;
        out_code  = 'b0;
    end
    else begin
        case (state)
        OUT1: begin
            out_valid = 1;
            out_code  = code[3][cnt];
        end 
        OUT2: begin
            out_valid = 1;
            if(!mode_reg) out_code  = code[2][cnt];
            else          out_code  = code[5][cnt];
        end
        OUT3: begin
            out_valid = 1;
            if(!mode_reg) out_code  = code[1][cnt];
            else          out_code  = code[2][cnt];
        end
        OUT4: begin
            out_valid = 1;
            if(!mode_reg) out_code  = code[0][cnt];
            else          out_code  = code[7][cnt];
        end
        OUT5: begin
            out_valid = 1;
            if(!mode_reg) out_code  = code[4][cnt];
            else          out_code  = code[6][cnt];
        end
        default: begin 
            out_valid = 'b0;
            out_code  = 'b0;
        end
    endcase       
    end
end
endmodule