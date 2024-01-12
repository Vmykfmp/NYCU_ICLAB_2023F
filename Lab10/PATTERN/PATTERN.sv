/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : PATTERN.sv
Module Name : PATTERN
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/
// `define PAT_NUM 10
`include "Usertype_BEV.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";

integer PAT_NUM = 4500;
integer i_pat, latency, total_latency, i;

//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 256 box

// input data
Action     _act;
Order_Info _order;
Date       _date;
Barrel_No  _box_no;
ING        _black_tea;
ING        _green_tea;
ING        _milk;
ING        _pineapple_juice;

// golden answer
Error_Msg err_msg_golden;
logic     complete_golden;

ING cost;
ING BT_cost;
ING GT_cost;
ING MK_cost;
ING PJ_cost;

ING BT_dram;
ING GT_dram;
ING MK_dram;
ING PJ_dram;
Month M_dram;
Day   D_dram;

//================================================================
// class random
//================================================================
class random_act;
    rand Action act_rand;
    constraint range{
        // act_rand inside{Supply};
        act_rand inside{Make_drink, Supply, Check_Valid_Date};
        }
endclass
class random_order;
    randc Order_Info order_rand;
    constraint range{
        order_rand.Bev_Size_O inside{L, M, S};    
        order_rand.Bev_Type_O inside{Black_Tea, Milk_Tea, Extra_Milk_Tea, Green_Tea, 
                                     Green_Milk_Tea, Pineapple_Juice, Super_Pineapple_Tea, Super_Pineapple_Milk_Tea};
    }
endclass
class random_date;
    randc Date date_rand;
    constraint M_range{
        date_rand.M inside{[1:12]};
    }
    constraint D_range{
        if(date_rand.M == 1)  date_rand.D inside{[1:31]};    
        if(date_rand.M == 2)  date_rand.D inside{[1:28]};
        if(date_rand.M == 3)  date_rand.D inside{[1:31]};
        if(date_rand.M == 4)  date_rand.D inside{[1:30]};    
        if(date_rand.M == 5)  date_rand.D inside{[1:31]};
        if(date_rand.M == 6)  date_rand.D inside{[1:30]};
        if(date_rand.M == 7)  date_rand.D inside{[1:31]};    
        if(date_rand.M == 8)  date_rand.D inside{[1:31]};
        if(date_rand.M == 9)  date_rand.D inside{[1:30]};
        if(date_rand.M == 10) date_rand.D inside{[1:31]};    
        if(date_rand.M == 11) date_rand.D inside{[1:30]};
        if(date_rand.M == 12) date_rand.D inside{[1:31]};
    }
endclass
class random_box_no;
    randc Action box_no_rand;
    constraint range{
        box_no_rand inside{[0:255]};
    }
endclass
class random_ing;
    randc ING ing_rand;
    constraint range{
        // ing_rand inside{[0:4095]};
        ing_rand inside{0, 128, 256 ,384, 512, 640, 768, 896, 
                        1024, 1152, 1280, 1408, 1536, 1664, 1792, 1920, 
                        2048, 2176, 2304, 2432, 2560, 2688, 2816, 2994, 
                        3072, 3200, 3328, 3456, 3584, 3712, 3840, 3968};
        // ing_rand inside{[0:63]};
    }
endclass

//================================================================
// initial
//================================================================
initial $readmemh(DRAM_p_r, golden_DRAM); 

initial begin
    reset_signal_task;

    for(i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1) begin
        golden_task;
        input_task;
        
        wait_out_valid_task;
        check_ans_task;
    end
    pass_task;
end

task reset_signal_task; begin
    inf.rst_n            = 'b1;
    inf.sel_action_valid = 'b0;
    inf.type_valid       = 'b0;
    inf.size_valid       = 'b0;
    inf.date_valid       = 'b0;
    inf.box_no_valid     = 'b0;
    inf.box_sup_valid    = 'b0;
    inf.D                = 'bx;

    latency = 0;
    total_latency = 0;

    #10; inf.rst_n = 0;
    #50; inf.rst_n = 1;

    if(inf.out_valid !== 'b0 || inf.err_msg !== 'b0 || inf.complete !== 'b0 ) begin
        $display("\nAssertion 1 is violated\n");
        repeat(1) #10;
        $finish;
    end
    @(negedge clk);
end endtask

task golden_task; begin
    // Random generate action & box_no
    random_act    act    = new();
    random_box_no box_no = new();
    i = act.randomize();
    i = box_no.randomize();
    if(i_pat < 2000) _act = act.act_rand;
    else             _act = Make_drink;
    // _box_no = box_no.box_no_rand;
    _box_no = 0;

    // Read DRAM data
    D_dram        = golden_DRAM[65536 + _box_no * 8];
    PJ_dram[7:0]  = golden_DRAM[65536 + _box_no * 8 + 1];
    PJ_dram[11:8] = golden_DRAM[65536 + _box_no * 8 + 2][3:0];
    MK_dram[3:0]  = golden_DRAM[65536 + _box_no * 8 + 2][7:4];
    MK_dram[11:4] = golden_DRAM[65536 + _box_no * 8 + 3];
    M_dram        = golden_DRAM[65536 + _box_no * 8 + 4];
    GT_dram[7:0]  = golden_DRAM[65536 + _box_no * 8 + 5];
    GT_dram[11:8] = golden_DRAM[65536 + _box_no * 8 + 6][3:0];
    BT_dram[3:0]  = golden_DRAM[65536 + _box_no * 8 + 6][7:4];
    BT_dram[11:4] = golden_DRAM[65536 + _box_no * 8 + 7];

    if(_act === Make_drink) begin
        // Random generate order & date
        random_order order = new();
        random_date  date  = new();
        i = order.randomize();
        i = date.randomize();
        _order = order.order_rand;
        _date  = date.date_rand;

        // Calculate ingredient cost
        case (_order.Bev_Size_O)
            L: cost = 12'd960;
            M: cost = 12'd720;
            S: cost = 12'd480; 
            default: cost = 12'd0;
        endcase
        case (_order.Bev_Type_O)
            Black_Tea                : begin BT_cost = cost;           GT_cost = 12'd0;          MK_cost = 12'd0;          PJ_cost = 12'd0;         end  	        
            Milk_Tea	             : begin BT_cost = 3 * (cost / 4); GT_cost = 12'd0;          MK_cost = 1 * (cost / 4); PJ_cost = 12'd0;         end
            Extra_Milk_Tea           : begin BT_cost = 2 * (cost / 4); GT_cost = 12'd0;          MK_cost = 2 * (cost / 4); PJ_cost = 12'd0;         end
            Green_Tea 	             : begin BT_cost = 12'd0;          GT_cost = cost;           MK_cost = 12'd0;          PJ_cost = 12'd0;         end
            Green_Milk_Tea           : begin BT_cost = 12'd0;          GT_cost = 2 * (cost / 4); MK_cost = 2 * (cost / 4); PJ_cost = 12'd0;         end
            Pineapple_Juice          : begin BT_cost = 12'd0;          GT_cost = 12'd0;          MK_cost = 12'd0;          PJ_cost = cost;          end
            Super_Pineapple_Tea      : begin BT_cost = 2 * (cost / 4); GT_cost = 12'd0;          MK_cost = 12'd0;          PJ_cost = 2 * (cost / 4); end
            Super_Pineapple_Milk_Tea : begin BT_cost = 2 * (cost / 4); GT_cost = 12'd0;          MK_cost = 1 * (cost / 4); PJ_cost = 1 * (cost / 4); end
            default: begin BT_cost = 12'd0; GT_cost = 12'd0; MK_cost = 12'd0; PJ_cost = 12'd0;        end
        endcase
        
        // Generate err_msg and complete 
        if(_date.M > M_dram  || (_date.M == M_dram && _date.D > D_dram)) begin
            complete_golden = 1'b0;
            err_msg_golden = No_Exp;
        end
        else if(BT_cost > BT_dram || GT_cost > GT_dram || MK_cost > MK_dram || PJ_cost > PJ_dram) begin
            complete_golden = 1'b0;
            err_msg_golden = No_Ing;        
        end
        else begin
            complete_golden = 1'b1;
            err_msg_golden = No_Err;
            
            BT_dram = BT_dram - BT_cost;
            GT_dram = GT_dram - GT_cost;
            MK_dram = MK_dram - MK_cost;
            PJ_dram = PJ_dram - PJ_cost;

            golden_DRAM[65536 + _box_no * 8 + 1]      = PJ_dram[7:0] ;
            golden_DRAM[65536 + _box_no * 8 + 2][3:0] = PJ_dram[11:8];
            golden_DRAM[65536 + _box_no * 8 + 2][7:4] = MK_dram[3:0] ;
            golden_DRAM[65536 + _box_no * 8 + 3]      = MK_dram[11:4];
            golden_DRAM[65536 + _box_no * 8 + 5]      = GT_dram[7:0] ;
            golden_DRAM[65536 + _box_no * 8 + 6][3:0] = GT_dram[11:8];
            golden_DRAM[65536 + _box_no * 8 + 6][7:4] = BT_dram[3:0] ;
            golden_DRAM[65536 + _box_no * 8 + 7]      = BT_dram[11:4];
        end
    end
    else if(_act === Supply) begin
        // Random generate date & ingredient
        random_date date = new();
        // random_ing black_tea       = new();
        // random_ing green_tea       = new();
        // random_ing milk            = new();
        // random_ing pineapple_juice = new();
        i = date.randomize();
        // i = black_tea.randomize();
        // i = green_tea.randomize();
        // i = milk.randomize();
        // i = pineapple_juice.randomize();
        _date = date.date_rand;
        // _black_tea       = black_tea.ing_rand;
        // _green_tea       = green_tea.ing_rand;
        // _milk            = milk.ing_rand;
        // _pineapple_juice = pineapple_juice.ing_rand;

        if(i_pat < 100) begin
            _black_tea       = 12'd0;
            _green_tea       = 12'd0;
            _milk            = 12'd0;
            _pineapple_juice = 12'd0;            
        end
        else begin
            random_ing black_tea       = new();
            random_ing green_tea       = new();
            random_ing milk            = new();
            random_ing pineapple_juice = new();
            i = black_tea.randomize();
            i = green_tea.randomize();
            i = milk.randomize();
            i = pineapple_juice.randomize();
            _black_tea       = black_tea.ing_rand;
            _green_tea       = green_tea.ing_rand;
            _milk            = milk.ing_rand;
            _pineapple_juice = pineapple_juice.ing_rand;
        end

        // Generate err_msg and complete
        complete_golden = 1'b1;
        err_msg_golden = No_Err;
        if(_black_tea > 12'd4095 - BT_dram) begin
            complete_golden = 1'b0;
            err_msg_golden = Ing_OF;
            BT_dram = 12'd4095;
        end
        else BT_dram = BT_dram + _black_tea;
        if(_green_tea > 12'd4095 - GT_dram) begin
            complete_golden = 1'b0;
            err_msg_golden = Ing_OF;
            GT_dram = 12'd4095;
        end
        else GT_dram = GT_dram + _green_tea;
        if(_milk > 12'd4095 - MK_dram) begin
            complete_golden = 1'b0;
            err_msg_golden = Ing_OF;
            MK_dram = 12'd4095;
        end
        else MK_dram = MK_dram + _milk;
        if(_pineapple_juice > 12'd4095 - PJ_dram) begin
            complete_golden = 1'b0;
            err_msg_golden = Ing_OF;
            PJ_dram = 12'd4095;
        end
        else PJ_dram = PJ_dram + _pineapple_juice;

        // Update DRAM data
        golden_DRAM[65536 + _box_no * 8]          = _date.D;
        golden_DRAM[65536 + _box_no * 8 + 1]      = PJ_dram[7:0] ;
        golden_DRAM[65536 + _box_no * 8 + 2][3:0] = PJ_dram[11:8];
        golden_DRAM[65536 + _box_no * 8 + 2][7:4] = MK_dram[3:0] ;
        golden_DRAM[65536 + _box_no * 8 + 3]      = MK_dram[11:4];
        golden_DRAM[65536 + _box_no * 8 + 4]      = _date.M;
        golden_DRAM[65536 + _box_no * 8 + 5]      = GT_dram[7:0] ;
        golden_DRAM[65536 + _box_no * 8 + 6][3:0] = GT_dram[11:8];
        golden_DRAM[65536 + _box_no * 8 + 6][7:4] = BT_dram[3:0] ;
        golden_DRAM[65536 + _box_no * 8 + 7]      = BT_dram[11:4];    
    end
    else if(_act === Check_Valid_Date) begin
        // Random generate date
        random_date date = new();
        i = date.randomize();
        _date = date.date_rand;

        if(_date.M > M_dram  || (_date.M == M_dram && _date.D > D_dram)) begin
            complete_golden = 1'b0;
            err_msg_golden = No_Exp;
        end
        else begin
            complete_golden = 1'b1;
            err_msg_golden = No_Err;
        end
    end
end endtask

task input_task; begin
    // Action
    repeat($urandom_range(0,0)) @(negedge clk);
    inf.sel_action_valid = 'b1;
    inf.D.d_act[0] = _act;
    @(negedge clk);
    inf.sel_action_valid = 'b0;
    inf.D = 'bx;

    if     (_act === Make_drink)       make_drink_task();
    else if(_act === Supply)           supply_task();
    else if(_act === Check_Valid_Date) check_date_task();
end endtask

task make_drink_task; begin
    // Order
    repeat($urandom_range(0,0)) @(negedge clk);
    inf.type_valid = 'b1;
    inf.D.d_type[0] = _order.Bev_Type_O;
    @(negedge clk);
    inf.type_valid = 'b0;
    inf.D = 'bx;

    repeat($urandom_range(0,0)) @(negedge clk);
    inf.size_valid = 'b1;
    inf.D.d_size[0] = _order.Bev_Size_O;
    @(negedge clk);
    inf.size_valid = 'b0;
    inf.D = 'bx;

    // Date
    repeat($urandom_range(0,0)) @(negedge clk);
    inf.date_valid = 'b1;
    inf.D.d_date[0] = _date;
    @(negedge clk);
    inf.date_valid = 'b0;
    inf.D = 'bx;

    // Box No
    repeat($urandom_range(0,0)) @(negedge clk);
    inf.box_no_valid = 'b1;
    inf.D.d_box_no[0] = _box_no;
    @(negedge clk);
    inf.box_no_valid = 'b0;
    inf.D = 'bx;
end endtask

task supply_task; begin
    // Date
    repeat($urandom_range(0,0)) @(negedge clk);
    inf.date_valid = 'b1;
    inf.D.d_date[0] = _date;
    @(negedge clk);
    inf.date_valid = 'b0;
    inf.D = 'bx;

    // Box No
    repeat($urandom_range(0,0)) @(negedge clk);
    inf.box_no_valid = 'b1;
    inf.D.d_box_no[0] = _box_no;
    @(negedge clk);
    inf.box_no_valid = 'b0;
    inf.D = 'bx;

    // ingredient
    repeat($urandom_range(0,0)) @(negedge clk);
    inf.box_sup_valid = 'b1;
    inf.D.d_ing[0] = _black_tea;
    @(negedge clk);
    inf.box_sup_valid = 'b0;
    inf.D = 'bx;

    repeat($urandom_range(0,0)) @(negedge clk);
    inf.box_sup_valid = 'b1;
    inf.D.d_ing[0] = _green_tea;
    @(negedge clk);
    inf.box_sup_valid = 'b0;
    inf.D = 'bx;

    repeat($urandom_range(0,0)) @(negedge clk);
    inf.box_sup_valid = 'b1;
    inf.D.d_ing[0] = _milk;
    @(negedge clk);
    inf.box_sup_valid = 'b0;
    inf.D = 'bx;

    repeat($urandom_range(0,0)) @(negedge clk);
    inf.box_sup_valid = 'b1;
    inf.D.d_ing[0] = _pineapple_juice;
    @(negedge clk);
    inf.box_sup_valid = 'b0;
    inf.D = 'bx;
end endtask

task check_date_task; begin
    // Date
    repeat($urandom_range(0,0)) @(negedge clk);
    inf.date_valid = 'b1;
    inf.D.d_date[0] = _date;
    @(negedge clk);
    inf.date_valid = 'b0;
    inf.D = 'bx;

    // Box No
    repeat($urandom_range(0,0)) @(negedge clk);
    inf.box_no_valid = 'b1;
    inf.D.d_box_no[0] = _box_no;
    @(negedge clk);
    inf.box_no_valid = 'b0;
    inf.D = 'bx; 
end endtask

task wait_out_valid_task; begin
    latency = 0;
    while(inf.out_valid !== 1'b1) begin

	    latency = latency + 1;
        if( latency == 1000) begin
                $display("\nAssertion 2 is violated\n");
                // repeat(2)@(negedge clk);
                $finish;
        end
        
        @(negedge clk);
   end
   total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
    while(inf.out_valid === 1'b1) begin
        if(inf.err_msg !== err_msg_golden || inf.complete !== complete_golden) begin
            $display ("---------------------");
			$display ("       \033[0;31m Wrong Answer! \033[0m       ");
            $display ("   your answer : err_smg: %b, complete: %b ", inf.err_msg, inf.complete);
            $display (" golden answer : err_smg: %b, complete: %b ", err_msg_golden, complete_golden);
			$display ("---------------------");
            repeat(9) @(negedge clk);
			$finish;
        end
        else begin
            $display("\033[0;32m PASS PATTERN NO.%4d \033[0m", i_pat);
            @(negedge clk);
        end
    end
end endtask

task pass_task; begin
    $display("********************************************************************");
    $display("*                        \033[0;32m Congratulations! \033[0m                        *");
    $display("*                total %4d pattern are passed                     *", PAT_NUM);
    $display("********************************************************************");
    repeat(3) @(negedge clk);
    $finish;
end endtask
endprogram
