/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : BEV.sv
Module Name : BEV
Release version : v1.0 (Release Date: Nov-2023)
Author : Tse-Chun Hsu
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

module BEV(input clk, INF.BEV_inf inf);
import usertype::*;

//==============================================//
//               TYPE DEFINATION                //
//==============================================//
typedef enum logic [2:0]{
    IDLE,
    INPUT,
    SUP_IN,
    DRAM_R,
    ERR_JUG,
    PROCESS,
    DRAM_W,
    OUTPUT
} state_t;

typedef logic [12:0] ING_ext;
//==============================================//
//              LOGIC DECLARATION               //
//==============================================//
// REGISTERS //
// FSM
state_t state, state_next;
logic [1:0] cnt_sup;
// control signal
logic write_skip;
logic first_pat;
logic first_pat_d1;
logic size_valid_d1;
Barrel_No box_no_reg_d1;
// input reg
Action    action_reg;
Bev_Type  type_reg;
Bev_Size  size_reg;
Date      date_reg;
Barrel_No box_no_reg;
Bev_Bal   box_data_reg;
// ING BT;
// ING GT;
// ING MK;
// ING PJ;
ING_ext BT;
ING_ext GT;
ING_ext MK;
ING_ext PJ;
// output reg
Error_Msg err_msg_reg;
logic     complete_reg;
// temp reg
ING_ext BT_next;
ING_ext GT_next;
ING_ext MK_next;
ING_ext PJ_next;
logic [63:0] data_reg;
// ingeger
integer i;
//==============================================//
//                  FSM Block                   //
//==============================================//
// STATE MACHINE
always_ff @(posedge clk or negedge inf.rst_n) begin : TOP_FSM_SEQ
    if (!inf.rst_n) state <= IDLE;
    else            state <= state_next;
    // else state <= nstate;
end
always_comb begin : TOP_FSM_COMB 
    case (state)
        IDLE: begin
            if(inf.sel_action_valid) state_next = INPUT;
            else                     state_next = IDLE;
        end 
        INPUT: begin
            if(inf.box_no_valid) begin
                if(action_reg == Supply)                              state_next = SUP_IN;
                // else state_next = READ_SKIP;
                else if(first_pat && inf.D.d_box_no[0] == box_no_reg) state_next = ERR_JUG;
                else                                                  state_next = DRAM_R;
            end
            else state_next = INPUT;
        end
        // READ_SKIP: begin
        //         if(first_pat && box_no_reg_d1 == box_no_reg) state_next = ERR_JUG;
        //         else                                                  state_next = DRAM_R;            
        // end
        SUP_IN: begin
            if(inf.box_sup_valid && cnt_sup == 2'd3) state_next = DRAM_R;
            else                                     state_next = SUP_IN;
        end
        DRAM_R: begin
            if(inf.C_out_valid) state_next = ERR_JUG;
            else                state_next = DRAM_R;
        end
        ERR_JUG: begin
            state_next = PROCESS;
        end
        PROCESS: begin
            if(write_skip) state_next = OUTPUT;
            else           state_next = DRAM_W;
        end
        DRAM_W: begin
            if(inf.C_out_valid) state_next = OUTPUT;
            else                state_next = DRAM_W;
        end
        OUTPUT: begin
            state_next = IDLE;
        end
        default: state_next = IDLE;
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin : CNT_SUP_SEQ
    if (!inf.rst_n) cnt_sup <= 'b0;
    else begin
        case (state)
            // IDLE: cnt_sup <= 'b0;
            SUP_IN: begin
                if(inf.box_sup_valid) cnt_sup <= cnt_sup + 1'd1;
                else                  cnt_sup <= cnt_sup; 
            end 
            default: cnt_sup <= cnt_sup;
        endcase                 
    end
end
//==============================================//
//                CONTROL Block                 //
//==============================================//
always_comb begin : WRITE_SKIP_COMB
    if(action_reg == Check_Valid_Date)                         write_skip = 1'b1;
    else if(action_reg == Make_drink && err_msg_reg != No_Err) write_skip = 1'b1;
    else                                                       write_skip = 1'b0;
end
always_ff @(posedge clk or negedge inf.rst_n) begin : FIRST_PAT_SEQ
    if (!inf.rst_n)           first_pat <= 1'b0;
    // else if(state == DRAM_R)  first_pat <= 1'b1;
    else if(inf.box_no_valid)  first_pat <= 1'b1;
end
always_ff @(posedge clk or negedge inf.rst_n) begin : SIZE_VALID_D1_SEQ
    if (!inf.rst_n)         size_valid_d1 <= 1'b0;
    else if(inf.size_valid) size_valid_d1 <= 1'b1;
    else                    size_valid_d1 <= 1'b0;
end
//==============================================//
//                 INPUT Block                  //
//==============================================//
always_ff @(posedge clk or negedge inf.rst_n) begin : ACTION_SEQ
    if(!inf.rst_n) action_reg <= 'b0;
    else begin
        if(inf.sel_action_valid) action_reg <= inf.D.d_act[0];
        // case (state)
        //     IDLE: begin
        //         if(inf.sel_action_valid) action_reg <= inf.D.d_act[0];
        //         else                     action_reg <= action_reg;
        //     end 
        //     default: action_reg <= action_reg;
        // endcase
    end
end
always_ff @(posedge clk or negedge inf.rst_n) begin : TYPE_SEQ
    if(!inf.rst_n) type_reg <= 'b0;
    else begin
        if(inf.type_valid) type_reg <= inf.D.d_type[0];
        // case (state)
        //     INPUT: begin
        //         if(inf.type_valid) type_reg <= inf.D.d_type[0];
        //         else               type_reg <= type_reg;
        //     end 
        //     default: type_reg <= type_reg;
        // endcase
    end
end
always_ff @(posedge clk or negedge inf.rst_n) begin : SIZE_SEQ
    if(!inf.rst_n) size_reg <= 'b0;
    else begin
        if(inf.size_valid) size_reg <= inf.D.d_size[0];
        // case (state)
            
            // INPUT: begin
            //     if(inf.size_valid) size_reg <= inf.D.d_size[0];
            //     else               size_reg <= size_reg;
            // end 
            // default: size_reg <= size_reg;
        // endcase
    end
end
always_ff @(posedge clk or negedge inf.rst_n) begin : DATE_SEQ
    if(!inf.rst_n) date_reg <= 'b0;
    else begin
        if(inf.date_valid) date_reg <= inf.D.d_date[0];
        // case (state)
            
            // INPUT: begin
            //     if(inf.date_valid) date_reg <= inf.D.d_date[0];
            //     else               date_reg <= date_reg;
            // end 
            // default: date_reg <= date_reg;
        // endcase
    end
end
always_ff @(posedge clk or negedge inf.rst_n) begin : BOX_NO_SEQ
    if(!inf.rst_n) box_no_reg <= 'b0;
    else begin
        if(inf.box_no_valid) box_no_reg <= inf.D.d_box_no[0];
        // case (state)
        //     INPUT: begin
        //         if(inf.box_no_valid) box_no_reg <= inf.D.d_box_no[0];
        //         else                 box_no_reg <= box_no_reg;
        //     end 
        //     default: box_no_reg <= box_no_reg;
        // endcase
    end
end

// Black tea
always_ff @(posedge clk or negedge inf.rst_n) begin : BT_SEQ
    if(!inf.rst_n) BT <= 'b0;
    else begin
        if(size_valid_d1) begin
            // case (inf.D.d_size[0])
            //     L: begin
            //         if(type_reg == Black_Tea)     BT <= -13'd960;
            //         else if(type_reg == Milk_Tea) BT <= -13'd720;
            //         else if(type_reg == Extra_Milk_Tea || type_reg == Super_Pineapple_Tea || type_reg == Super_Pineapple_Milk_Tea) BT <= -13'd480;  
            //     end
            //     M: begin
            //         if(type_reg == Black_Tea)     BT <= -13'd720;
            //         else if(type_reg == Milk_Tea) BT <= -13'd540;
            //         else if(type_reg == Extra_Milk_Tea || type_reg == Super_Pineapple_Tea || type_reg == Super_Pineapple_Milk_Tea) BT <= -13'd360;
            //     end
            //     S: begin
            //         if(type_reg == Black_Tea)     BT <= -13'd480;
            //         else if(type_reg == Milk_Tea) BT <= -13'd360;
            //         else if(type_reg == Extra_Milk_Tea || type_reg == Super_Pineapple_Tea || type_reg == Super_Pineapple_Milk_Tea) BT <= -13'd240;
            //     end
            //     default: begin end
            // endcase           
            if(size_reg == L) begin
                if(type_reg == Black_Tea)     BT <= -13'd960;
                else if(type_reg == Milk_Tea) BT <= -13'd720;
                else if(type_reg == Extra_Milk_Tea || type_reg == Super_Pineapple_Tea || type_reg == Super_Pineapple_Milk_Tea) BT <= -13'd480;  
            end
            if(size_reg == M) begin
                if(type_reg == Black_Tea)     BT <= -13'd720;
                else if(type_reg == Milk_Tea) BT <= -13'd540;
                else if(type_reg == Extra_Milk_Tea || type_reg == Super_Pineapple_Tea || type_reg == Super_Pineapple_Milk_Tea) BT <= -13'd360;
            end
            if(size_reg == S) begin
                if(type_reg == Black_Tea)     BT <= -13'd480;
                else if(type_reg == Milk_Tea) BT <= -13'd360;
                else if(type_reg == Extra_Milk_Tea || type_reg == Super_Pineapple_Tea || type_reg == Super_Pineapple_Milk_Tea) BT <= -13'd240;
            end
        end
        // if(inf.size_valid) begin
        //     // case (inf.D.d_size[0])
        //     //     L: begin
        //     //         if(type_reg == Black_Tea)     BT <= -13'd960;
        //     //         else if(type_reg == Milk_Tea) BT <= -13'd720;
        //     //         else if(type_reg == Extra_Milk_Tea || type_reg == Super_Pineapple_Tea || type_reg == Super_Pineapple_Milk_Tea) BT <= -13'd480;  
        //     //     end
        //     //     M: begin
        //     //         if(type_reg == Black_Tea)     BT <= -13'd720;
        //     //         else if(type_reg == Milk_Tea) BT <= -13'd540;
        //     //         else if(type_reg == Extra_Milk_Tea || type_reg == Super_Pineapple_Tea || type_reg == Super_Pineapple_Milk_Tea) BT <= -13'd360;
        //     //     end
        //     //     S: begin
        //     //         if(type_reg == Black_Tea)     BT <= -13'd480;
        //     //         else if(type_reg == Milk_Tea) BT <= -13'd360;
        //     //         else if(type_reg == Extra_Milk_Tea || type_reg == Super_Pineapple_Tea || type_reg == Super_Pineapple_Milk_Tea) BT <= -13'd240;
        //     //     end
        //     //     default: begin end
        //     // endcase           
        //     if(inf.D.d_size[0] == L) begin
        //         if(type_reg == Black_Tea)     BT <= -13'd960;
        //         else if(type_reg == Milk_Tea) BT <= -13'd720;
        //         else if(type_reg == Extra_Milk_Tea || type_reg == Super_Pineapple_Tea || type_reg == Super_Pineapple_Milk_Tea) BT <= -13'd480;  
        //     end
        //     if(inf.D.d_size[0] == M) begin
        //         if(type_reg == Black_Tea)     BT <= -13'd720;
        //         else if(type_reg == Milk_Tea) BT <= -13'd540;
        //         else if(type_reg == Extra_Milk_Tea || type_reg == Super_Pineapple_Tea || type_reg == Super_Pineapple_Milk_Tea) BT <= -13'd360;
        //     end
        //     if(inf.D.d_size[0] == S) begin
        //         if(type_reg == Black_Tea)     BT <= -13'd480;
        //         else if(type_reg == Milk_Tea) BT <= -13'd360;
        //         else if(type_reg == Extra_Milk_Tea || type_reg == Super_Pineapple_Tea || type_reg == Super_Pineapple_Milk_Tea) BT <= -13'd240;
        //     end
        // end
        else if(inf.box_sup_valid && cnt_sup == 2'd0) BT <= inf.D.d_ing[0];
        else if(state == IDLE) BT <= 'b0;
    end
end
// Green tea
always_ff @(posedge clk or negedge inf.rst_n) begin : GT_SEQ
    if(!inf.rst_n) GT <= 'b0;
    else begin
        case (state)
            IDLE: begin
                GT <= 'b0;
            end
            INPUT: begin
                if(size_valid_d1) begin
                    case (size_reg)
                        L: begin
                            if(type_reg == Green_Tea)           GT <= -13'd960;
                            else if(type_reg == Green_Milk_Tea) GT <= -13'd480;
                        end
                        M: begin
                            if(type_reg == Green_Tea)           GT <= -13'd720;
                            else if(type_reg == Green_Milk_Tea) GT <= -13'd360;
                        end
                        S: begin
                            if(type_reg == Green_Tea)           GT <= -13'd480;
                            else if(type_reg == Green_Milk_Tea) GT <= -13'd240;
                        end
                        default: begin end
                    endcase

                    // if(inf.D.d_size[0] == L) begin
                    //     if(type_reg == Green_Tea)           GT <= -13'd960;
                    //     else if(type_reg == Green_Milk_Tea) GT <= -13'd480;
                    // end
                    // if(inf.D.d_size[0] == M) begin
                    //     if(type_reg == Green_Tea)           GT <= -13'd720;
                    //     else if(type_reg == Green_Milk_Tea) GT <= -13'd360;
                    // end
                    // if(inf.D.d_size[0] == S) begin
                    //     if(type_reg == Green_Tea)           GT <= -13'd480;
                    //     else if(type_reg == Green_Milk_Tea) GT <= -13'd240;
                    // end
                end
                // if(inf.size_valid) begin
                //     case (inf.D.d_size[0])
                //         L: begin
                //             if(type_reg == Green_Tea)           GT <= -13'd960;
                //             else if(type_reg == Green_Milk_Tea) GT <= -13'd480;
                //         end
                //         M: begin
                //             if(type_reg == Green_Tea)           GT <= -13'd720;
                //             else if(type_reg == Green_Milk_Tea) GT <= -13'd360;
                //         end
                //         S: begin
                //             if(type_reg == Green_Tea)           GT <= -13'd480;
                //             else if(type_reg == Green_Milk_Tea) GT <= -13'd240;
                //         end
                //         default: begin end
                //     endcase

                //     // if(inf.D.d_size[0] == L) begin
                //     //     if(type_reg == Green_Tea)           GT <= -13'd960;
                //     //     else if(type_reg == Green_Milk_Tea) GT <= -13'd480;
                //     // end
                //     // if(inf.D.d_size[0] == M) begin
                //     //     if(type_reg == Green_Tea)           GT <= -13'd720;
                //     //     else if(type_reg == Green_Milk_Tea) GT <= -13'd360;
                //     // end
                //     // if(inf.D.d_size[0] == S) begin
                //     //     if(type_reg == Green_Tea)           GT <= -13'd480;
                //     //     else if(type_reg == Green_Milk_Tea) GT <= -13'd240;
                //     // end
                // end
            end
            SUP_IN: begin
                if(inf.box_sup_valid && cnt_sup == 2'd1) GT <= inf.D.d_ing[0];
            end 
            default: begin end
        endcase
    end
end
// Milk
always_ff @(posedge clk or negedge inf.rst_n) begin : MK_SEQ
    if(!inf.rst_n) MK <= 'b0;
    else begin
        case (state)
            IDLE: begin
                MK <= 'b0;
            end
            INPUT: begin
                if(size_valid_d1) begin
                    case (size_reg)
                        L: begin
                            if(type_reg == Milk_Tea || type_reg == Super_Pineapple_Milk_Tea)  MK <= -13'd240;
                            else if(type_reg == Extra_Milk_Tea || type_reg == Green_Milk_Tea) MK <= -13'd480;
                        end
                        M: begin
                            if(type_reg == Milk_Tea || type_reg == Super_Pineapple_Milk_Tea)  MK <= -13'd180;
                            else if(type_reg == Extra_Milk_Tea || type_reg == Green_Milk_Tea) MK <= -13'd360;
                        end
                        S: begin
                            if(type_reg == Milk_Tea || type_reg == Super_Pineapple_Milk_Tea)  MK <= -13'd120;
                            else if(type_reg == Extra_Milk_Tea || type_reg == Green_Milk_Tea) MK <= -13'd240;
                        end
                        default: begin end
                    endcase

                    // if(inf.D.d_size[0] == L) begin
                    //     if(type_reg == Milk_Tea || type_reg == Super_Pineapple_Milk_Tea)  MK <= -13'd240;
                    //     else if(type_reg == Extra_Milk_Tea || type_reg == Green_Milk_Tea) MK <= -13'd480;
                    // end
                    // if(inf.D.d_size[0] == M) begin
                    //     if(type_reg == Milk_Tea || type_reg == Super_Pineapple_Milk_Tea)  MK <= -13'd180;
                    //     else if(type_reg == Extra_Milk_Tea || type_reg == Green_Milk_Tea) MK <= -13'd360;
                    // end
                    // if(inf.D.d_size[0] == S) begin
                    //     if(type_reg == Milk_Tea || type_reg == Super_Pineapple_Milk_Tea)  MK <= -13'd120;
                    //     else if(type_reg == Extra_Milk_Tea || type_reg == Green_Milk_Tea) MK <= -13'd240;
                    // end
                end
                // if(inf.size_valid) begin
                //     case (inf.D.d_size[0])
                //         L: begin
                //             if(type_reg == Milk_Tea || type_reg == Super_Pineapple_Milk_Tea)  MK <= -13'd240;
                //             else if(type_reg == Extra_Milk_Tea || type_reg == Green_Milk_Tea) MK <= -13'd480;
                //         end
                //         M: begin
                //             if(type_reg == Milk_Tea || type_reg == Super_Pineapple_Milk_Tea)  MK <= -13'd180;
                //             else if(type_reg == Extra_Milk_Tea || type_reg == Green_Milk_Tea) MK <= -13'd360;
                //         end
                //         S: begin
                //             if(type_reg == Milk_Tea || type_reg == Super_Pineapple_Milk_Tea)  MK <= -13'd120;
                //             else if(type_reg == Extra_Milk_Tea || type_reg == Green_Milk_Tea) MK <= -13'd240;
                //         end
                //         default: begin end
                //     endcase

                //     // if(inf.D.d_size[0] == L) begin
                //     //     if(type_reg == Milk_Tea || type_reg == Super_Pineapple_Milk_Tea)  MK <= -13'd240;
                //     //     else if(type_reg == Extra_Milk_Tea || type_reg == Green_Milk_Tea) MK <= -13'd480;
                //     // end
                //     // if(inf.D.d_size[0] == M) begin
                //     //     if(type_reg == Milk_Tea || type_reg == Super_Pineapple_Milk_Tea)  MK <= -13'd180;
                //     //     else if(type_reg == Extra_Milk_Tea || type_reg == Green_Milk_Tea) MK <= -13'd360;
                //     // end
                //     // if(inf.D.d_size[0] == S) begin
                //     //     if(type_reg == Milk_Tea || type_reg == Super_Pineapple_Milk_Tea)  MK <= -13'd120;
                //     //     else if(type_reg == Extra_Milk_Tea || type_reg == Green_Milk_Tea) MK <= -13'd240;
                //     // end
                // end
            end
            SUP_IN: begin
                if(inf.box_sup_valid && cnt_sup == 2'd2) MK <= inf.D.d_ing[0];
            end 
            default: begin end
        endcase
    end
end
// Pineapple juice
always_ff @(posedge clk or negedge inf.rst_n) begin : PJ_SEQ
    if(!inf.rst_n) PJ <= 'b0;
    else begin
        case (state)
            IDLE: begin
                PJ <= 'b0;
            end
            INPUT: begin
                if(size_valid_d1) begin
                    case (size_reg)
                        L: begin
                            if(type_reg == Pineapple_Juice)               PJ <= -13'd960;
                            else if(type_reg == Super_Pineapple_Tea)      PJ <= -13'd480;
                            else if(type_reg == Super_Pineapple_Milk_Tea) PJ <= -13'd240;
                        end
                        M: begin
                            if(type_reg == Pineapple_Juice)               PJ <= -13'd720;
                            else if(type_reg == Super_Pineapple_Tea)      PJ <= -13'd360;
                            else if(type_reg == Super_Pineapple_Milk_Tea) PJ <= -13'd180;
                        end
                        S: begin
                            if(type_reg == Pineapple_Juice)               PJ <= -13'd480;
                            else if(type_reg == Super_Pineapple_Tea)      PJ <= -13'd240;
                            else if(type_reg == Super_Pineapple_Milk_Tea) PJ <= -13'd120;
                        end
                        default: begin end
                    endcase

                    // if(inf.D.d_size[0] == L) begin
                    //     if(type_reg == Pineapple_Juice)               PJ <= -13'd960;
                    //     else if(type_reg == Super_Pineapple_Tea)      PJ <= -13'd480;
                    //     else if(type_reg == Super_Pineapple_Milk_Tea) PJ <= -13'd240;
                    // end
                    // if(inf.D.d_size[0] == M) begin
                    //     if(type_reg == Pineapple_Juice)               PJ <= -13'd720;
                    //     else if(type_reg == Super_Pineapple_Tea)      PJ <= -13'd360;
                    //     else if(type_reg == Super_Pineapple_Milk_Tea) PJ <= -13'd180;
                    // end
                    // if(inf.D.d_size[0] == S) begin
                    //     if(type_reg == Pineapple_Juice)               PJ <= -13'd480;
                    //     else if(type_reg == Super_Pineapple_Tea)      PJ <= -13'd240;
                    //     else if(type_reg == Super_Pineapple_Milk_Tea) PJ <= -13'd120;
                    // end
                end

                // if(inf.size_valid) begin
                //     case (inf.D.d_size[0])
                //         L: begin
                //             if(type_reg == Pineapple_Juice)               PJ <= -13'd960;
                //             else if(type_reg == Super_Pineapple_Tea)      PJ <= -13'd480;
                //             else if(type_reg == Super_Pineapple_Milk_Tea) PJ <= -13'd240;
                //         end
                //         M: begin
                //             if(type_reg == Pineapple_Juice)               PJ <= -13'd720;
                //             else if(type_reg == Super_Pineapple_Tea)      PJ <= -13'd360;
                //             else if(type_reg == Super_Pineapple_Milk_Tea) PJ <= -13'd180;
                //         end
                //         S: begin
                //             if(type_reg == Pineapple_Juice)               PJ <= -13'd480;
                //             else if(type_reg == Super_Pineapple_Tea)      PJ <= -13'd240;
                //             else if(type_reg == Super_Pineapple_Milk_Tea) PJ <= -13'd120;
                //         end
                //         default: begin end
                //     endcase

                //     // if(inf.D.d_size[0] == L) begin
                //     //     if(type_reg == Pineapple_Juice)               PJ <= -13'd960;
                //     //     else if(type_reg == Super_Pineapple_Tea)      PJ <= -13'd480;
                //     //     else if(type_reg == Super_Pineapple_Milk_Tea) PJ <= -13'd240;
                //     // end
                //     // if(inf.D.d_size[0] == M) begin
                //     //     if(type_reg == Pineapple_Juice)               PJ <= -13'd720;
                //     //     else if(type_reg == Super_Pineapple_Tea)      PJ <= -13'd360;
                //     //     else if(type_reg == Super_Pineapple_Milk_Tea) PJ <= -13'd180;
                //     // end
                //     // if(inf.D.d_size[0] == S) begin
                //     //     if(type_reg == Pineapple_Juice)               PJ <= -13'd480;
                //     //     else if(type_reg == Super_Pineapple_Tea)      PJ <= -13'd240;
                //     //     else if(type_reg == Super_Pineapple_Milk_Tea) PJ <= -13'd120;
                //     // end
                // end
            end
            SUP_IN: begin
                if(inf.box_sup_valid && cnt_sup == 2'd3) PJ <= inf.D.d_ing[0];
            end 
            default: begin end
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin : DATA_SEQ
    if(!inf.rst_n) box_data_reg <= 'b0;
    else begin
        case (state)
            // INPUT: begin
            //     if(inf.date_valid) begin
            //         box_data_reg.M <= inf.D.d_date[0][8:5];
            //         box_data_reg.D <= inf.D.d_date[0][4:0];                    
            //     end
            // end
            DRAM_R: begin
                if(inf.C_out_valid) begin
                    box_data_reg.black_tea       <= inf.C_data_r[63:52];
                    box_data_reg.green_tea       <= inf.C_data_r[51:40];
                    box_data_reg.milk            <= inf.C_data_r[31:20];
                    box_data_reg.pineapple_juice <= inf.C_data_r[19:8];
                    if(action_reg != Supply) box_data_reg.M <= inf.C_data_r[35:32];
                    if(action_reg != Supply) box_data_reg.D <= inf.C_data_r[4:0];
                    // box_data_reg.M               <= inf.C_data_r[39:32];
                    // box_data_reg.D               <= inf.C_data_r[7:0];
                end
                else box_data_reg <= box_data_reg;
            end
            PROCESS: begin
                // box_data_reg.black_tea       <= (BT_next[12]) ? 12'hFFF : BT_next[11:0];
                // box_data_reg.green_tea       <= (GT_next[12]) ? 12'hFFF : GT_next[11:0];
                // box_data_reg.milk            <= (MK_next[12]) ? 12'hFFF : MK_next[11:0];
                // box_data_reg.pineapple_juice <= (PJ_next[12]) ? 12'hFFF : PJ_next[11:0];
                box_data_reg.black_tea       <= (^err_msg_reg) ? box_data_reg.black_tea       : (BT_next[12]) ? 12'hFFF : BT_next[11:0];
                box_data_reg.green_tea       <= (^err_msg_reg) ? box_data_reg.green_tea       : (GT_next[12]) ? 12'hFFF : GT_next[11:0];
                box_data_reg.milk            <= (^err_msg_reg) ? box_data_reg.milk            : (MK_next[12]) ? 12'hFFF : MK_next[11:0];
                box_data_reg.pineapple_juice <= (^err_msg_reg) ? box_data_reg.pineapple_juice : (PJ_next[12]) ? 12'hFFF : PJ_next[11:0];                
                box_data_reg.M <= (action_reg == Supply) ? date_reg[8:5] : box_data_reg.M;
                box_data_reg.D <= (action_reg == Supply) ? date_reg[4:0] : box_data_reg.D;        
             end
            default: box_data_reg <= box_data_reg;
        endcase
    end
end

always_comb begin : ING_COMB
    BT_next = box_data_reg.black_tea       + BT;
    GT_next = box_data_reg.green_tea       + GT;
    MK_next = box_data_reg.milk            + MK;
    PJ_next = box_data_reg.pineapple_juice + PJ; 

    // if(err_msg_reg != No_Exp && err_msg_reg != No_Ing) begin
    //     BT_next = box_data_reg.black_tea       + BT;
    //     GT_next = box_data_reg.green_tea       + GT;
    //     MK_next = box_data_reg.milk            + MK;
    //     PJ_next = box_data_reg.pineapple_juice + PJ;         
    // end
    // else begin
    //     BT_next = box_data_reg.black_tea;
    //     GT_next = box_data_reg.green_tea;
    //     MK_next = box_data_reg.milk;
    //     PJ_next = box_data_reg.pineapple_juice;          
    // end

    // if(action_reg != Check_Valid_Date) begin
    //     BT_next = box_data_reg.black_tea       + BT;
    //     GT_next = box_data_reg.green_tea       + GT;
    //     MK_next = box_data_reg.milk            + MK;
    //     PJ_next = box_data_reg.pineapple_juice + PJ;        
    // end
    // else begin
    //     BT_next = box_data_reg.black_tea;
    //     GT_next = box_data_reg.green_tea;
    //     MK_next = box_data_reg.milk;
    //     PJ_next = box_data_reg.pineapple_juice;        
    // end

    // if(action_reg == Make_drink && err_msg_reg == No_Err) begin
    //     BT_next = box_data_reg.black_tea       - BT;
    //     GT_next = box_data_reg.green_tea       - GT;
    //     MK_next = box_data_reg.milk            - MK;
    //     PJ_next = box_data_reg.pineapple_juice - PJ;        
    // end
    // else if(action_reg == Supply) begin
    //     BT_next = box_data_reg.black_tea       + BT;
    //     GT_next = box_data_reg.green_tea       + GT;
    //     MK_next = box_data_reg.milk            + MK;
    //     PJ_next = box_data_reg.pineapple_juice + PJ;        
    // end
    // else begin
    //     BT_next = box_data_reg.black_tea;
    //     GT_next = box_data_reg.green_tea;
    //     MK_next = box_data_reg.milk;
    //     PJ_next = box_data_reg.pineapple_juice;        
    // end
end
//==============================================//
//                OUTPUT Block                  //
//==============================================//
always_comb begin : C_ADDR_COMB
    inf.C_addr = box_no_reg;
end
always_comb begin : C_R_WB_COMB
    inf.C_r_wb = !(state == DRAM_W) && inf.rst_n;
end
always_ff @(posedge clk or negedge inf.rst_n) begin : C_IN_VALID_SEQ
    if(!inf.rst_n) inf.C_in_valid <= 1'b0;
    else           inf.C_in_valid <= (state != DRAM_R && state_next == DRAM_R) || (state != DRAM_W && state_next == DRAM_W);
end
always_comb begin : C_DATA_W_COMB
    inf.C_data_w[63:52] = box_data_reg.black_tea;      
    inf.C_data_w[51:40] = box_data_reg.green_tea;       
    inf.C_data_w[31:20] = box_data_reg.milk;
    inf.C_data_w[19:8]  = box_data_reg.pineapple_juice; 
    inf.C_data_w[39:32] = box_data_reg.M;              
    inf.C_data_w[7:0]   = box_data_reg.D;               
end
always_ff @(posedge clk or negedge inf.rst_n) begin : C_ERR_MSG_SEQ
    if(!inf.rst_n) err_msg_reg <= 'b0;
    else begin
        // if(state == DRAM_W && err_msg_reg == No_Err && ~complete_reg) begin
        if(state == ERR_JUG) begin
            // if(action_reg != Supply && ((date_reg[8:5] > box_data_reg.M) || (date_reg[8:5] == box_data_reg.M && date_reg[4:0] > box_data_reg.D))) begin
            //     err_msg_reg <= No_Exp;
            // end
            // else if(BT_next[12] || GT_next[12] || MK_next[12] || PJ_next[12]) begin
            //     err_msg_reg <= {2'b1, action_reg[0]};
            // end
            case (action_reg)
                Make_drink: begin
                    // if((date_reg[8:5] > box_data_reg.M) || (date_reg[8:5] == box_data_reg.M && date_reg[4:0] > box_data_reg.D)) begin
                    if(date_reg > {box_data_reg.M, box_data_reg.D}) begin
                        err_msg_reg <= No_Exp;
                    end
                    // else if(BT > box_data_reg.black_tea || GT > box_data_reg.green_tea || MK > box_data_reg.milk || PJ > box_data_reg.pineapple_juice) begin
                    else if(BT_next[12] || GT_next[12] || MK_next[12] || PJ_next[12]) begin
                        err_msg_reg <= No_Ing;
                    end
                end
                Supply: begin
                    // if(BT > 12'hFFF - box_data_reg.black_tea || GT > 12'hFFF - box_data_reg.green_tea || MK > 12'hFFF - box_data_reg.milk || PJ > 12'hFFF - box_data_reg.pineapple_juice) begin
                    if(BT_next[12] || GT_next[12] || MK_next[12] || PJ_next[12]) begin
                        err_msg_reg <= Ing_OF;
                    end
                end
                Check_Valid_Date: begin
                    // if((date_reg[8:5] > box_data_reg.M) || (date_reg[8:5] == box_data_reg.M && date_reg[4:0] > box_data_reg.D)) begin
                    if(date_reg > {box_data_reg.M, box_data_reg.D}) begin
                        err_msg_reg <= No_Exp;
                    end
                end
                default: begin end
            endcase
        end
        else if(state == IDLE) err_msg_reg <= 'b0;
    end
end
always_comb begin : C_ERR_MSG_COMB
    // if(state == DRAM_W && inf.C_out_valid) inf.err_msg = err_msg_reg;
    if(state == OUTPUT) inf.err_msg = err_msg_reg;
    else                inf.err_msg = 2'b0;
    // inf.err_msg = err_msg_reg;
end
always_comb begin : C_COMPLETE_COMB
    if(state == OUTPUT) inf.complete = (err_msg_reg == No_Err);
    else                inf.complete = 1'b0;
    // inf.complete = complete_reg;
end
always_comb begin : C_OUT_VALID_SEQ
    // if(state == DRAM_W && inf.C_out_valid) inf.out_valid = 1'b1;
    if(state == OUTPUT) inf.out_valid = 1'b1;
    else                inf.out_valid = 1'b0;             
end

endmodule