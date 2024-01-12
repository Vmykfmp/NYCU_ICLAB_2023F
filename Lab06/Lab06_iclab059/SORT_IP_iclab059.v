//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : SORT_IP.v
//   	Module Name : SORT_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module SORT_IP #(parameter IP_WIDTH = 8) (
    // Input signals
    IN_character, IN_weight,
    // Output signals
    OUT_character
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_WIDTH*4-1:0]  IN_character;
input [IP_WIDTH*5-1:0]  IN_weight;

output reg [IP_WIDTH*4-1:0] OUT_character;

// ===============================================================
// Design
// ===============================================================

reg [2:0] order     [0: IP_WIDTH - 1];
reg [4:0] weight    [0: IP_WIDTH - 1];
reg [3:0] character [0: IP_WIDTH - 1];

reg [31:0] out_tmp;

integer i, j;

// integer j;
genvar k;
generate
    for(k = 0; k < IP_WIDTH; k = k + 1) begin  
        always @(*) begin
            // order[i]     = 'b0;
            // weight[i]    = IN_weight[(i*5)+:5];
            // character[i] = IN_character[(i*4)+:4];
            
            // for(j = 0; j < IP_WIDTH; j = j + 1) begin
            //     if(weight[i] > weight[j]) order[j] = order[j] + 1;
            //     else                      order[i] = order[i] + 1;
            // end

            // out_tmp = 'b0;
            // case (order[k])
            //     0: out_tmp[31:28] = character[k];
            //     1: out_tmp[27:24] = character[k];
            //     2: out_tmp[23:20] = character[k];
            //     3: out_tmp[19:16] = character[k];
            //     4: out_tmp[15:12] = character[k];
            //     5: out_tmp[11:8]  = character[k];
            //     6: out_tmp[7:4]   = character[k];
            //     7: out_tmp[3:0]   = character[k];
            //     default: out_tmp = out_tmp;
            // endcase    

            OUT_character[(k*4)+:4] = out_tmp[(k*4)+((8-IP_WIDTH)*4)+:4]; 
        end 
        
        // always @(*) begin
        //     out_tmp = 'b0;
        //     case (order[i])
        //         0: out_tmp[31:28] = character[i];
        //         1: out_tmp[27:24] = character[i];
        //         2: out_tmp[23:20] = character[i];
        //         3: out_tmp[19:16] = character[i];
        //         4: out_tmp[15:12] = character[i];
        //         5: out_tmp[11:8]  = character[i];
        //         6: out_tmp[7:4]   = character[i];
        //         7: out_tmp[3:0]   = character[i];
        //         default: out_tmp = out_tmp;
        //     endcase                
        // end

        // always @(*) begin
        //     OUT_character[(i*4)+:4] = out_tmp[(i*4)+((8-IP_WIDTH)*4)+:4];               
        // end  
    end
endgenerate


// genvar k;
// generate
// for(k = 0; k < 1; k = k + 1) begin
always @(*) begin
    for(i = 0; i < IP_WIDTH; i = i + 1) begin
        order[i]     = 'b0;
        // weight[i]    = IN_character[i * 4 + 3: i * 4];
        // character[i] = IN_character[i * 3 + 2: i * 3];
        weight[i]    = IN_weight[(i*5)+:5];
        character[i] = IN_character[(i*4)+:4];
    end

    for(i = 0; i < IP_WIDTH; i = i + 1) begin
        for(j = i + 1; j < IP_WIDTH; j = j + 1) begin
            if(weight[i] > weight[j]) order[j] = order[j] + 1;
            else                      order[i] = order[i] + 1;
        end
    end

    out_tmp = 'b0;
    for(i = 0; i < IP_WIDTH; i = i + 1) begin
        case (order[i])
            0: out_tmp[31:28] = character[i];
            1: out_tmp[27:24] = character[i];
            2: out_tmp[23:20] = character[i];
            3: out_tmp[19:16] = character[i];
            4: out_tmp[15:12] = character[i];
            5: out_tmp[11:8]  = character[i];
            6: out_tmp[7:4]   = character[i];
            7: out_tmp[3:0]   = character[i];
            default: out_tmp = out_tmp;
        endcase
    end

    // for(i = 0; i < IP_WIDTH; i = i + 1) begin
    //     OUT_character[(i*4)+:4] = out_tmp[(i*4)+((8-IP_WIDTH)*4)+:4];
    // end

    // case (IP_WIDTH)
    //     3: OUT_character = out_tmp[31:20];
    //     4: OUT_character = out_tmp[31:16];
    //     5: OUT_character = out_tmp[31:12];
    //     6: OUT_character = out_tmp[31:8];
    //     7: OUT_character = out_tmp[31:4];
    //     8: OUT_character = out_tmp[31:0];
    //     default: OUT_character = out_tmp;
    // endcase
end
// end
// endgenerate
















endmodule