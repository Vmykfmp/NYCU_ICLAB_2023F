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

module bridge(input clk, INF.bridge_inf inf);

//================================================================
// logic 
//================================================================

//================================================================
// state 
//================================================================

//==============================================//
//                DECLARE Block                 //
//==============================================//
typedef enum logic [1:0]{
    IDLE,
    ADDR,
    DATA,
    RESP
} AXI_state_t;

logic wb_reg; 
logic [7:0] addr_reg;

AXI_state_t state, state_next;

//==============================================//
//                  FSM Block                   //
//==============================================//
always_ff @(posedge clk or negedge inf.rst_n) begin : TOP_FSM_SEQ
    if (!inf.rst_n) state <= IDLE;
    else            state <= state_next;
    // else state <= nstate;
end

always_comb begin : TOP_FSM_COMB 
    case (state)
        IDLE: begin
            if(inf.C_in_valid) state_next = ADDR;
            else               state_next = IDLE;
        end 
        ADDR: begin
            if(inf.AR_READY || inf.AW_READY) state_next = DATA;
            else                             state_next = ADDR;
        end
        DATA: begin
            if(inf.R_VALID)      state_next = IDLE;
            else if(inf.W_READY) state_next = RESP;
            else                 state_next = DATA;
        end
        RESP: begin
            if(inf.B_VALID) state_next = IDLE;
            else            state_next = RESP;
        end
        default: state_next = IDLE;
    endcase
end
//==============================================//
//                 INPUT Block                  //
//==============================================//
always_ff @(posedge clk or negedge inf.rst_n) begin : WB_REG_SEQ 
    if(!inf.rst_n)          wb_reg <= 1'b1;
    else if(inf.C_in_valid) wb_reg <= inf.C_r_wb;
    else                    wb_reg <= wb_reg; 
end
always_ff @(posedge clk or negedge inf.rst_n) begin : ADDR_REG_SEQ 
    if(!inf.rst_n)          addr_reg <= 'b0;
    else if(inf.C_in_valid) addr_reg <= inf.C_addr;
end
//==============================================//
//                OUTPUT Block                  //
//==============================================//
// Read channel
always_ff @(posedge clk or negedge inf.rst_n) begin : AR_VALID_SEQ
    if(!inf.rst_n) inf.AR_VALID <= 'b0;
    else           inf.AR_VALID <= (state == ADDR) && wb_reg;
end
always_ff @(posedge clk or negedge inf.rst_n) begin : AR_ADDR_SEQ
    if(!inf.rst_n)                   inf.AR_ADDR <= 'b0;
    else if(state == ADDR && wb_reg) inf.AR_ADDR <= {5'h10, 1'h0, addr_reg, 3'h0};
    // else if(state == ADDR && wb_reg) inf.AR_ADDR <= {5'h10, 1'h0, inf.C_addr, 3'h0};
    else                             inf.AR_ADDR <= 'b0;
end
always_ff @(posedge clk or negedge inf.rst_n) begin : R_READY_SEQ
    if(!inf.rst_n) inf.R_READY <= 'b0;
    else           inf.R_READY <= (state == DATA) && wb_reg;
    // else           inf.R_READY <= (state == DATA) && inf.C_r_wb;
end

// Write channel
always_ff @(posedge clk or negedge inf.rst_n) begin : AW_VALID_SEQ
    if(!inf.rst_n) inf.AW_VALID <= 'b0;
    else           inf.AW_VALID <= (state == ADDR) && !wb_reg;
end
always_ff @(posedge clk or negedge inf.rst_n) begin : AW_ADDR_SEQ
    if(!inf.rst_n)                    inf.AW_ADDR <= 'b0;       
    else if(state == ADDR && !wb_reg) inf.AW_ADDR <= {5'h10, 1'h0, addr_reg, 3'h0};
    // else if(state == ADDR && !wb_reg) inf.AW_ADDR <= {5'h10, 1'h0, inf.C_addr, 3'h0};
    else                              inf.AW_ADDR <= 'b0;
end
always_ff @(posedge clk or negedge inf.rst_n) begin : W_VALID_SEQ
    if(!inf.rst_n) inf.W_VALID <= 'b0;
    else           inf.W_VALID <= (state == DATA) && !wb_reg;
end
always_ff @(posedge clk or negedge inf.rst_n) begin : W_DATA_SEQ
    if(!inf.rst_n)                      inf.W_DATA <= 'b0;
    else if((state == DATA) && !wb_reg) inf.W_DATA <= inf.C_data_w;
    else                                inf.W_DATA <= 'b0;
end
always_ff @(posedge clk or negedge inf.rst_n) begin : B_READY_SEQ
    if(!inf.rst_n) inf.B_READY <= 'b0;
    else           inf.B_READY <= (state == DATA || state == RESP) && !wb_reg;
end


// always_comb begin : AW_VALID_COMB 
//     inf.AW_VALID = (state == ADDR) && !wb_reg;
// end
// always_comb begin : AW_ADDR_COMB 
//     // if(state == ADDR && !inf.C_r_wb) inf.AW_ADDR = {5'h10, 1'h0, inf.C_addr, 3'h0};
//     if(state == ADDR && !wb_reg) inf.AW_ADDR = {5'h10, 1'h0, inf.C_addr, 3'h0};
//     else                         inf.AW_ADDR = 'b0;
// end
// always_comb begin : W_VALID_COMB 
//     // inf.W_VALID = (state == DATA) && !inf.C_r_wb;
//     inf.W_VALID = (state == DATA) && !wb_reg;
// end
// always_comb begin : W_DATA_COMB
//     // if(inf.C_in_valid && !inf.C_r_wb) inf.W_DATA = inf.C_data_w;
//     // if((state == DATA) && !inf.C_r_wb) inf.W_DATA = inf.C_data_w;
//     if((state == DATA) && !wb_reg) inf.W_DATA = inf.C_data_w;
//     else                           inf.W_DATA = 'b0;
// end
// always_comb begin : B_READY_COMB 
//     // inf.B_READY = (state == DATA || state == RESP) && !inf.C_r_wb;
//     inf.B_READY = (state == DATA || state == RESP) && !wb_reg;
// end


// Bev channel
// always_comb begin : C_OUT_VALID_COMB 
//     inf.C_out_valid = inf.R_VALID || inf.B_VALID;
// end
// always_comb begin : C_DATA_R_COMB 
//     if(inf.R_VALID) inf.C_data_r = inf.R_DATA;
//     else            inf.C_data_r = 'b0; 
// end
always_ff @(posedge clk or negedge inf.rst_n) begin : C_OUT_VALID_SEQ
    if(!inf.rst_n) inf.C_out_valid <= 'b0;
    else           inf.C_out_valid <= (inf.R_VALID || inf.B_VALID);
end
always_ff @(posedge clk or negedge inf.rst_n) begin : C_DATA_R_SEQ
    if(!inf.rst_n)       inf.C_data_r <= 'b0;
    else if(inf.R_VALID) inf.C_data_r <= inf.R_DATA;
    else                 inf.C_data_r <= 'b0;
end
endmodule