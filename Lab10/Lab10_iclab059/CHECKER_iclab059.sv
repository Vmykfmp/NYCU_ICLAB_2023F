/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Nov-2023)
Author : Tse-Chun Hsu
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

/*
    Coverage Part
*/

/*
class BEV;
    Bev_Type bev_type;
    Bev_Size bev_size;
endclass

BEV bev_info = new();

always_ff @(posedge clk) begin
    if (inf.type_valid) begin
        bev_info.bev_type = inf.D.d_type[0];
    end
end
*/

integer PAT_NUM = 4500;
integer i_pat;

Order_Info order;
Error_Msg  err_msg;
Action     act;
ING        ing;

always_ff @(posedge clk) begin : TYPE_FETCH_SEQ
    if (inf.type_valid) order.Bev_Type_O = inf.D.d_type[0];
end
always_ff @(posedge clk) begin : SIZE_FETCH_SEQ
    if (inf.size_valid) order.Bev_Size_O = inf.D.d_size[0];
end
always_ff @(posedge clk) begin : ERR_MSG_FETCH_SEQ
    if (inf.out_valid) err_msg = inf.err_msg;
end
always_ff @(posedge clk) begin : ACTION_FETCH_SEQ
    if (inf.sel_action_valid) act = inf.D.d_act[0];
end
always_ff @(posedge clk) begin : INGREDIENT_FETCH_SEQ
    if (inf.box_sup_valid) ing = inf.D.d_ing[0];
end
/*
1. Each case of Beverage_Type should be select at least 100 times.
*/

/*
covergroup Spec1 @(posedge clk);
    option.per_instance = 1;
    option.at_least = 100;
    btype:coverpoint bev_info.bev_type{
        bins b_bev_type [] = {[Black_Tea:Super_Pineapple_Milk_Tea]};
    }
endgroup
*/
covergroup cov_group_1 @(posedge clk iff(inf.type_valid === 1'b1));
    option.name = "Bev_type_cov";
    option.per_instance = 1;
    option.at_least = 100;
    Bev_type_point : coverpoint order.Bev_Type_O{
        bins bev_type_bin [] = {[Black_Tea:Super_Pineapple_Milk_Tea]};
    }
endgroup
/*
2.	Each case of Bererage_Size should be select at least 100 times.
*/
covergroup cov_group_2 @(posedge clk iff(inf.size_valid === 1'b1));
    option.name = "Bev_size_cov";
    option.per_instance = 1;
    option.at_least = 100;
    Bev_size_point : coverpoint order.Bev_Size_O{
        bins bev_size_bin [] = {[L:S]};
    }
endgroup
/*
3.	Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 times. 
(Black Tea, Milk Tea, Extra Milk Tea, Green Tea, Green Milk Tea, Pineapple Juice, Super Pineapple Tea, Super Pineapple Tea) x (L, M, S)
*/
covergroup cov_group_3 @(posedge clk iff(inf.size_valid === 1'b1));
    option.name = "Bev_order_cov";
    option.per_instance = 1;
    option.at_least = 100;
    // Bev_type : coverpoint order.Bev_Type_O{
    //     bins bev_type_bin [] = {[Black_Tea:Super_Pineapple_Milk_Tea]};
    // }
    // Bev_size : coverpoint order.Bev_Size_O{
    //     bins bev_size_bin [] = {[L:S]};
    // }
    Bev_order_point : cross order.Bev_Type_O, order.Bev_Size_O;
endgroup
/*
4.	Output signal inf.err_msg should be No_Err, No_Exp, No_Ing and Ing_OF, each at least 20 times. (Sample the value when inf.out_valid is high)
*/
covergroup cov_group_4 @(posedge clk iff(inf.out_valid === 1'b1));
    option.name = "Err_msg_cov";
    option.per_instance = 1;
    option.at_least = 20;
    Err_msg_point : coverpoint err_msg{
        bins err_msg_bin [] = {[No_Err:Ing_OF]};
    }
endgroup
/*
5.	Create the transitions bin for the inf.D.act[0] signal from [0:2] to [0:2]. Each transition should be hit at least 200 times. (sample the value at posedge clk iff inf.sel_action_valid)
*/
covergroup cov_group_5 @(posedge clk iff(inf.sel_action_valid === 1'b1));
    option.name = "Act_cov";
    option.per_instance = 1;
    option.at_least = 200;
    Act_point : coverpoint act{
        bins action_bin [] = ([Make_drink:Check_Valid_Date] => [Make_drink:Check_Valid_Date]);
    }
endgroup
/*
6.	Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.
*/
covergroup cov_group_6 @(posedge clk iff(inf.box_sup_valid === 1'b1));
    option.name = "Ing_cov";
    option.per_instance = 1;
    option.at_least = 1;
    Ing_point : coverpoint ing{
        option.auto_bin_max = 32;
        // bins ing_bin [] = {[0:4095]};    
    }
endgroup
/*
    Create instances of Spec1, Spec2, Spec3, Spec4, Spec5, and Spec6
*/
// Spec1_2_3 cov_inst_1_2_3 = new();
// cov_group_1 cov_spec_1 = new(); 
// always_ff @(negedge clk) begin
//     if(inf.type_valid === 1) cov_spec_1.sample();
// end 
// cov_group_2 cov_spec_2 = new();
// always_ff @(negedge clk) begin
//     if(inf.size_valid === 1) cov_spec_2.sample();
// end
// cov_group_3 cov_spec_3 = new();
// always_ff @(negedge clk) begin
//     if(inf.size_valid === 1'b1) cov_spec_3.sample();
// end
// cov_group_4 cov_spec_4 = new();
// always_ff @(negedge clk) begin
//     if(inf.out_valid === 1'b1) cov_spec_4.sample();
// end
// cov_group_5 cov_spec_5 = new();
// always_ff @(negedge clk) begin
//     if(inf.out_valid === 1'b1) cov_spec_5.sample();
// end
// cov_group_6 cov_spec_6 = new();
// always_ff @(negedge clk) begin
//     if(inf.box_sup_valid === 1'b1) cov_spec_6.sample();
// end

initial begin
    for(i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1) begin
        while (inf.out_valid !== 1'b1) begin
            @(negedge clk);
        end
        @(negedge clk);
    end
    // cov_spec_1.close();
    @(negedge clk);
    $display("COVERAGE TABLE");
    $display("cov_spec_1 = %f %", cov_spec_1.get_coverage());
    $display("cov_spec_2 = %f %", cov_spec_2.get_coverage());
    $display("cov_spec_3 = %f %", cov_spec_3.get_coverage());
    $display("cov_spec_4 = %f %", cov_spec_4.get_coverage());
    $display("cov_spec_5 = %f %", cov_spec_5.get_coverage());
    $display("cov_spec_6 = %f %", cov_spec_6.get_coverage());
    $display("");
end

/*
    Asseration
*/

/*
    If you need, you can declare some FSM, logic, flag, and etc. here.
*/

logic rst_done;
always_comb begin : RST_DONE_COMB
    rst_done = (inf.out_valid  === 1'b0) &&
               (inf.err_msg  === 2'b0) &&
               (inf.complete  === 1'b0) &&
               (inf.C_addr  === 8'b0) &&
               (inf.C_data_w  === 64'b0) &&
               (inf.C_in_valid  === 1'b0) &&
               (inf.C_r_wb  === 1'b0) &&

               (inf.C_out_valid  === 1'b0) &&
               (inf.C_data_r  === 64'b0) &&
               (inf.AR_VALID  === 1'b0) &&
               (inf.AR_ADDR  === 17'b0) &&
               (inf.R_READY  === 1'b0) &&
               (inf.AW_VALID  === 1'b0) &&
               (inf.AW_ADDR  === 17'b0) &&
               (inf.W_VALID  === 1'b0) &&  
               (inf.W_DATA  === 64'b0) &&
               (inf.B_READY  === 1'b0);    
end
logic [5:0] all_valid;
always_comb begin : ALL_VALID_COMB
    all_valid = {inf.sel_action_valid,
                 inf.type_valid,
                 inf.size_valid,
                 inf.date_valid,
                 inf.box_no_valid,
                 inf.box_sup_valid};
end
logic all_valid_or;
always_comb begin : ALL_VALID_OR_COMB
    all_valid_or = |all_valid;
end
logic all_valid_clk;
always_comb begin : ALL_VALID_CLK_COMB
    all_valid_clk = all_valid_or && clk;
end
logic all_valid_nor;
always_comb begin : ALL_VALID_NOR_COMB
    all_valid_nor = ~(|all_valid);
end
logic [1:0] ing_cnt;
always_ff @(posedge clk or negedge inf.rst_n) begin : ING_CNT_SEQ
   if(!inf.rst_n) ing_cnt <= 2'b0;
   else if(inf.box_sup_valid) ing_cnt <= ing_cnt + 2'd1;
end

logic box_sup_valid_1;
always_ff @(posedge clk or negedge inf.rst_n) begin : BOX_SUP_VALID_1_COMB
    if(!inf.rst_n) box_sup_valid_1 <= 'b0;
    else           box_sup_valid_1 = inf.box_sup_valid && (ing_cnt == 2'd0);
end
logic box_sup_valid_2;
always_ff @(posedge clk or negedge inf.rst_n) begin : BOX_SUP_VALID_2_COMB
    if(!inf.rst_n) box_sup_valid_2 <= 'b0;
    else           box_sup_valid_2 <= inf.box_sup_valid && (ing_cnt == 2'd1);
end
logic box_sup_valid_3;
always_ff @(posedge clk or negedge inf.rst_n) begin : BOX_SUP_VALID_3_COMB
    if(!inf.rst_n) box_sup_valid_3 <= 'b0;
    else           box_sup_valid_3 <= inf.box_sup_valid && (ing_cnt == 2'd2);
end
logic box_sup_valid_4;
always_ff @(posedge clk or negedge inf.rst_n) begin : BOX_SUP_VALID_4_COMB
    if(!inf.rst_n) box_sup_valid_4 <= 'b0;
    else           box_sup_valid_4 <= inf.box_sup_valid && (ing_cnt == 2'd3);
end
logic [4:0] cnt;

initial cnt <= 'b0;

// Month M;
// Day D;
// always_ff @(posedge clk) begin : blockName
//     if(inf.date_valid)
// end

/*
    1. All outputs signals (including BEV.sv and bridge.sv) should be zero after reset.
*/
// always_comb begin
//     ast_spec_1: assert property (property_1) 
//     else   $fatal(0, "\nAssertion 1 is violated\n");  
// end
always @(negedge inf.rst_n) begin
    @(posedge clk);
    ast_spec_1: assert property (property_1) 
    else   $fatal(0, "\nAssertion 1 is violated\n");  
end
property property_1;
    @(negedge clk) !inf.rst_n ##1 rst_done;
endproperty: property_1
/*
    2.	Latency should be less than 1000 cycles for each operation.
*/
// always @(posedge all_valid_clk) begin
always @(posedge inf.box_no_valid) begin
    ast_spec_2: assert property (property_2)
    else $fatal(0, "\nAssertion 2 is violated\n");
end
property property_2;
    // @(negedge clk) all_valid_or ##[1:1000] inf.out_valid;
@(posedge clk) inf.box_no_valid ##[1:1000] inf.out_valid;
endproperty: property_2
/*
    3. If out_valid does not pull up, complete should be 0.
*/
always @(posedge inf.complete) begin
    ast_spec_3: assert (inf.err_msg == No_Err) 
    else   $fatal(0, "\nAssertion 3 is violated\n");  
end
/*
    4. Next input valid will be valid 1-4 cycles after previous input valid fall.
*/
always @(posedge inf.type_valid) begin
    ast_spec_4_1: assert property (property_4_1) 
    else @(posedge clk) $fatal(0, "\nAssertion 4 is violated\n");    
end
always @(posedge inf.box_no_valid) begin
    if(act == Supply) begin
        ast_spec_4_2: assert property (property_4_2) 
        else @(posedge clk) $fatal(0, "\nAssertion 4 is violated\n");          
    end
end
always @(posedge inf.date_valid) begin
    ast_spec_4_3: assert property (property_4_3) 
    else @(posedge clk) $fatal(0, "\nAssertion 4 is violated\n");    
end
always @(posedge box_sup_valid_1) begin
    if(act == Supply) begin
        ast_spec_4_4_1: assert property (property_4_4_1) 
        else @(posedge clk) $fatal(0, "\nAssertion 4 is violated\n");          
    end
end
always @(posedge box_sup_valid_2) begin
    if(act == Supply) begin
        ast_spec_4_4_2: assert property (property_4_4_2) 
        else @(posedge clk) $fatal(0, "\nAssertion 4 is violated\n");          
    end
end
always @(posedge box_sup_valid_3) begin
    if(act == Supply) begin
        ast_spec_4_4_3: assert property (property_4_4_3) 
        else @(posedge clk) $fatal(0, "\nAssertion 4 is violated\n");          
    end
end
property property_4_1;
    @(posedge clk) inf.type_valid |-> ##[0:4] inf.size_valid;
endproperty: property_4_1
property property_4_2;
    @(posedge clk) inf.box_no_valid |-> ##[0:4] inf.box_sup_valid;
endproperty: property_4_2
property property_4_3;
    @(posedge clk) inf.date_valid |-> ##[0:4] inf.box_no_valid;
endproperty: property_4_3
property property_4_4_1;
    @(negedge clk) box_sup_valid_1 |-> ##[0:4] box_sup_valid_2;
endproperty: property_4_4_1
property property_4_4_2;
    @(negedge clk) box_sup_valid_2 |-> ##[0:4] box_sup_valid_3;
endproperty: property_4_4_2
property property_4_4_3;
    @(negedge clk) box_sup_valid_3 |-> ##[0:4] box_sup_valid_4;
endproperty: property_4_4_3

/*
    5. All input valid signals won't overlap with each other. 
*/
always @(posedge all_valid_clk) begin
    ast_spec_5: assert ($onehot(all_valid)) 
    else begin
        $fatal(0, "\nAssertion 5 is violated\n");
    end
end
/*
    6. Out_valid can only be high for exactly one cycle.
*/
always @(posedge inf.out_valid) begin
    ast_spec_6: assert property (property_6) 
    else $fatal(0, "\nAssertion 6 is violated\n");
end
property property_6;
    @(negedge clk) inf.out_valid ##1 !inf.out_valid;
endproperty: property_6
/*
    7. Next operation will be valid 1-4 cycles after out_valid fall.
*/
always @(posedge inf.out_valid) begin
    ast_spec_7: assert property (property_7) 
    else $fatal(0, "\nAssertion 7 is violated\n");
end
property property_7;
    @(negedge clk) inf.out_valid ##[1:5] inf.sel_action_valid;
endproperty: property_7
/*
    8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
*/
always @(posedge inf.date_valid) begin
    ast_spec_8_0: 
        assert (inf.D.d_date[0][4:0] !== 5'd0) 
    else $fatal(0, "\nAssertion 8 is violated\n");

    ast_spec_8_1: 
        assert (inf.D.d_date[0][8:5] === 4'd1  && inf.D.d_date[0][4:0] <= 5'd31 ||
                inf.D.d_date[0][8:5] === 4'd2  && inf.D.d_date[0][4:0] <= 5'd28 ||
                inf.D.d_date[0][8:5] === 4'd3  && inf.D.d_date[0][4:0] <= 5'd31 ||
                inf.D.d_date[0][8:5] === 4'd4  && inf.D.d_date[0][4:0] <= 5'd30 ||
                inf.D.d_date[0][8:5] === 4'd5  && inf.D.d_date[0][4:0] <= 5'd31 ||
                inf.D.d_date[0][8:5] === 4'd6  && inf.D.d_date[0][4:0] <= 5'd30 ||
                inf.D.d_date[0][8:5] === 4'd7  && inf.D.d_date[0][4:0] <= 5'd31 ||
                inf.D.d_date[0][8:5] === 4'd8  && inf.D.d_date[0][4:0] <= 5'd31 ||
                inf.D.d_date[0][8:5] === 4'd9  && inf.D.d_date[0][4:0] <= 5'd30 ||
                inf.D.d_date[0][8:5] === 4'd10 && inf.D.d_date[0][4:0] <= 5'd31 ||
                inf.D.d_date[0][8:5] === 4'd11 && inf.D.d_date[0][4:0] <= 5'd30 ||
                inf.D.d_date[0][8:5] === 4'd12 && inf.D.d_date[0][4:0] <= 5'd31) 
    else $fatal(0, "\nAssertion 8 is violated\n");
end
/*
    9. C_in_valid can only be high for one cycle and can't be pulled high again before C_out_valid
*/
always @(posedge inf.C_in_valid) begin
    ast_spec_9_1: assert property (property_9_1) 
    else $fatal(0, "\nAssertion 9 is violated\n");

    ast_spec_9_2: assert property (property_9_2) 
    else $fatal(0, "\nAssertion 9 is violated\n");
end
property property_9_1;
    @(negedge clk) inf.C_in_valid ##1 !inf.C_in_valid ;
endproperty: property_9_1
property property_9_2;
    @(negedge inf.C_out_valid) inf.C_in_valid |-> inf.C_in_valid;
endproperty: property_9_2
endmodule
