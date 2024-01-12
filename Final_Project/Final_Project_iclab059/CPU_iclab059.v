//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Tse-Chun Hsu
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/



// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;


//###########################################
//
// Wrtie down your design below
//
//###########################################

//####################################################
//               reg & wire
//####################################################

//==============================================//
//                  Parameter                   //
//==============================================//
// FSM states
parameter IDLE  = 4'd0;
parameter LOAD  = 4'd1;
parameter STORE = 4'd2;
parameter INS_F = 4'd3;
parameter INS_D = 4'd4;
parameter EXE   = 4'd5;
parameter MEM   = 4'd6;
parameter WB    = 4'd7;
parameter EXE2  = 4'd8;


// AXI states
parameter ADDR = 2'd0;
parameter DATA = 2'd1;
parameter DONE = 2'd2;
// AXI parameter
parameter ID    = 4'd0;
parameter BURST = 2'b01;
parameter SIZE  = 3'b001;
parameter LEN_R = 7'd127;
parameter LEN_W = 7'd0;


//==============================================//
//                  Register                    //
//==============================================//
// FSM register
reg [3:0] state;
reg [3:0] state_next;
reg [1:0] hand_shake_ins;
reg [1:0] hand_shake_ins_next;
reg [1:0] hand_shake_data;
reg [1:0] hand_shake_data_next;
// Flag register
reg flag_store;
reg flag_hit;
reg flag_overflow;

// instruction counter
// reg [3:0] ins_cnt; 
reg [9:0] ins_cnt; 

// global counter
reg [10:0] addr_ins;
reg [10:0] addr_ins_next;
reg [10:0] addr_data;
reg [10:0] addr_data_next;

// instruction register
reg [DATA_WIDTH-1:0] ins;

// index register
reg [3:0] rs;
reg [3:0] rt;
reg [3:0] rd;

// immediate register
reg signed [4:0] imd;

// tag register
reg [3:0] tag_ins;
reg [3:0] tag_data;

// ALU register
reg signed [DATA_WIDTH-1:0] num1;
reg signed [DATA_WIDTH-1:0] num2;
reg signed [DATA_WIDTH-1:0] add_res;
reg signed [DATA_WIDTH-1:0] mul_res;
reg                         cmp_res;
reg signed [DATA_WIDTH-1:0] wb_data;

reg signed [DATA_WIDTH-1:0] num3;
reg signed [DATA_WIDTH-1:0] num4;
reg                         equ_res;

// DRAM_data read channel register
reg [ADDR_WIDTH-1:0] dram_raddr_data;
reg                  dram_rvalid_data;
reg                  dram_rready_data;
// DRAM_ins read channel register
reg [ADDR_WIDTH-1:0] dram_raddr_ins;
reg                  dram_rvalid_ins;
reg                  dram_rready_ins;

// DRAM write channel register
reg [ADDR_WIDTH-1:0] dram_waddr;
reg                  dram_wavalid;
reg [DATA_WIDTH-1:0] dram_wdata;
reg                  dram_wdvalid;
reg                  dram_wlast;
reg                  dram_bready;

reg [DATA_WIDTH-1:0] dram_wdata_d1;
reg                  dram_wdvalid_d1;
reg                  dram_wlast_d1;

// SRAM_ins register
reg [6:0]            sram_addr_ins;
reg [DATA_WIDTH-1:0] sram_dout_ins;
reg [DATA_WIDTH-1:0] sram_din_ins;
reg                  sram_wen_ins;
reg [6:0]            sram_cnt_ins;

// SRAM_data register
reg [6:0]            sram_addr_data;
reg [DATA_WIDTH-1:0] sram_dout_data;
reg [DATA_WIDTH-1:0] sram_din_data;
reg                  sram_wen_data;
reg [6:0]            sram_cnt_data;

// output register
reg IO_stall_next;

//==============================================//
//                    DEBUG                     //
//==============================================//
wire [4:0] ins_type;
assign ins_type = {1'b1, ins[15:13], ins[0]};

//==============================================//
//                  FSM BLOCK                   //
//==============================================//
always @(*) begin
  case (state)
    IDLE:  state_next = LOAD;
    LOAD:  begin
      if(hand_shake_data == DONE & hand_shake_ins == DONE) begin
        if(flag_overflow) state_next = EXE;
        else if(ins[15:13] == 3'b010 | ins[15:13] == 3'b100) begin
          state_next = MEM;
        end
        else state_next = INS_F;
      end
      else  state_next = LOAD;
    end
    STORE: begin
      if(hand_shake_data == DONE) state_next = INS_F;
      else                        state_next = STORE;
    end
    INS_F: state_next = INS_D;
    INS_D: begin
      if(ins[15:13] == 3'b101) state_next = MEM;
      else if(flag_overflow)   state_next = LOAD;
      else state_next = EXE;
    end
    EXE:   begin
      state_next = EXE2;
      // if(ins[15:14] == 2'b00) state_next = WB;
      // else                    state_next = MEM;              
    end
    EXE2: begin
      if(ins[15:14] == 2'b00) state_next = WB;
      else                    state_next = MEM;        
    end
    MEM:   begin
      if(ins[14:13] == 2'b11)       state_next = STORE;
      else if(~flag_hit)            state_next = LOAD;
      else if(ins[15:13] == 3'b101) state_next = INS_F;
      else                          state_next = WB;
    end
    WB:    state_next = INS_F;
    default: state_next = IDLE;
  endcase
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) state <= IDLE;
  else       state <= state_next;
end

//==============================================//
//                CONTROL BLOCK                 //
//==============================================//
// data load/store address
always @(*) begin
  case (state)
    EXE:     addr_data_next = (ins[14]) ? num1 + num2 : addr_data;
    // EXE:     addr_data_next = (ins[14]) ? add_res : addr_data;
    default: addr_data_next = addr_data;
  endcase
    // addr_data_next = addr_data;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) addr_data <= 'b0;
  else       addr_data <= addr_data_next;
end

// promgramming counter
always @(*) begin
  case (state)
    // INS_F: addr_ins_next = addr_ins + 1'b1;
    // INS_D: addr_ins_next = (ins[15:13] == 3'b101) ? ins[11:1] : addr_ins;
    // INS_F: addr_ins_next = (sram_dout_ins[15:13] == 3'b101) ? sram_dout_ins[11:1] : addr_ins + 1'b1;
    INS_F: addr_ins_next = addr_ins + 1'b1;
    INS_D: addr_ins_next = (ins[15:13] == 3'b101) ? sram_dout_ins[11:1] : addr_ins;
    // MEM:   addr_ins_next = (equ_res) ? add_res : addr_ins;
    
    // EXE:   addr_ins_next = (equ_res) ? num1 + num2 : addr_ins;
    EXE2:   addr_ins_next = (equ_res) ? add_res : addr_ins;
    default: addr_ins_next = addr_ins;
  endcase
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) addr_ins <= 'b0;
  else       addr_ins <= addr_ins_next;
end

// instruction counter
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) ins_cnt <= 'b0;
  else begin
    if(state == INS_F & ~(ins == 16'd0)) begin
      ins_cnt <= ins_cnt + 1'b1;
      // if(ins_cnt == 4'd10) ins_cnt <= 1'b1;
      // if(ins_cnt == 4'd10) ins_cnt <= 10'd1;
      // else                 ins_cnt <= ins_cnt + 1'b1;
    end
    else      ins_cnt <= ins_cnt;
  end      
end

// flag control
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) flag_store <= 'b0;
  else begin
      case (state)
        INS_D: begin
          if(ins[15:13] == 3'b011) flag_store <= 1'b1;
          else                     flag_store <= flag_store;
        end
        STORE: flag_store <= 1'b0;
        default: begin end
      endcase
  end
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) flag_overflow <= 'b0;
  else begin
      case (state)
        INS_F: begin
          if(addr_ins[6:0] == 7'd127) flag_overflow <= 1'b1;
          else                        flag_overflow <= flag_store;
        end
        EXE: flag_overflow <= 1'b0;
        default: begin end
      endcase
  end
end
always @(*) begin
  flag_hit = (addr_ins[10:7] == tag_ins & addr_data[10:7] == tag_data);
end


// DRAM_data AXI hand shake FSM
always @(*) begin
	case (state)
    LOAD, STORE: begin
			case (hand_shake_data)
				ADDR: begin
					if(arready_m_inf[0] | awready_m_inf) hand_shake_data_next = DATA;
					else                                 hand_shake_data_next = ADDR;
				end  
				DATA: begin
					if(rlast_m_inf[0] | bvalid_m_inf) hand_shake_data_next = DONE;
					else                              hand_shake_data_next = DATA;
				end
        DONE: begin
          if(hand_shake_ins == DONE | state == STORE) hand_shake_data_next = ADDR;
          else                                        hand_shake_data_next = DONE;
        end
				default: hand_shake_data_next = hand_shake_data;
			endcase		  
		end
		default: hand_shake_data_next = hand_shake_data;
	endcase
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) hand_shake_data <= IDLE;
  else       hand_shake_data <= hand_shake_data_next;
end
// DRAM_ins AXI hand shake FSM
always @(*) begin
	case (state)
    LOAD: begin
			case (hand_shake_ins)
				ADDR: begin
					if(arready_m_inf[1]) hand_shake_ins_next = DATA;
					else                 hand_shake_ins_next = ADDR;
				end  
				DATA: begin
					if(rlast_m_inf[1]) hand_shake_ins_next = DONE;
					else               hand_shake_ins_next = DATA;
				end
        DONE: begin
          if(hand_shake_data == DONE) hand_shake_ins_next = ADDR;
          else                        hand_shake_ins_next = DONE;
        end
				default: hand_shake_ins_next = hand_shake_ins;
			endcase		  
		end
		default: hand_shake_ins_next = hand_shake_ins;
	endcase
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) hand_shake_ins <= IDLE;
  else       hand_shake_ins <= hand_shake_ins_next;
end

//==============================================//
//            DATA REGISTERS BLOCK              //
//==============================================//
// Instruction register
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) ins <= 'b0;
  else begin
    case (state)
      INS_F: ins <= sram_dout_ins; 
      default: ins <= ins;
    endcase
  end
end

// Index register
always @(*) begin
  rs  = ins[12:9];
  rt  = ins[8:5];
  rd  = ins[4:1];
  imd = ins[4:0];
end

// Write back data register
always @(posedge clk) begin
  case (state)
    
    EXE2: if(ins[15:14] == 2'b0)  wb_data <= (ins[13]) ? ((ins[0]) ? mul_res : cmp_res) : add_res;
    MEM:  if(ins[14:13] == 2'b10) wb_data <= sram_dout_data;  
    // begin
    //   if(ins[15:14] == 2'b0)       wb_data <= (ins[13]) ? ((ins[0]) ? mul_res : cmp_res) : add_res;
    //   else if(ins[14:13] == 2'b10) wb_data <= sram_dout_data;          
    // end 
    default: begin end
  endcase
end

// tag register
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) tag_ins <= 'b0;
  else begin
    case (state)
      LOAD: tag_ins <= addr_ins[10:7];
      default: begin end
    endcase
  end
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) tag_data <= 'b0;
  else begin
    case (state)
      LOAD: tag_data <= addr_data[10:7];
      default: begin end
    endcase
  end
end


//==============================================//
//            CORE REGISTERS BLOCK              //
//==============================================//
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    core_r0  <= 'b0;
    core_r1  <= 'b0;
    core_r2  <= 'b0;
    core_r3  <= 'b0;
    core_r4  <= 'b0;
    core_r5  <= 'b0;
    core_r6  <= 'b0;
    core_r7  <= 'b0;
    core_r8  <= 'b0;
    core_r9  <= 'b0;
    core_r10 <= 'b0;
    core_r11 <= 'b0;
    core_r12 <= 'b0;
    core_r13 <= 'b0;
    core_r14 <= 'b0;
    core_r15 <= 'b0;
  end
  else begin
    case (state)
      WB: begin
        if(ins[15:14] == 2'b0) begin
          case (rd)
              4'd0 : core_r0  <= wb_data;
              4'd1 : core_r1  <= wb_data;
              4'd2 : core_r2  <= wb_data;
              4'd3 : core_r3  <= wb_data;
              4'd4 : core_r4  <= wb_data;
              4'd5 : core_r5  <= wb_data;
              4'd6 : core_r6  <= wb_data;
              4'd7 : core_r7  <= wb_data;
              4'd8 : core_r8  <= wb_data;
              4'd9 : core_r9  <= wb_data;
              4'd10: core_r10 <= wb_data;
              4'd11: core_r11 <= wb_data;
              4'd12: core_r12 <= wb_data;
              4'd13: core_r13 <= wb_data;
              4'd14: core_r14 <= wb_data;
              4'd15: core_r15 <= wb_data;
              default: begin end
          endcase
        end
        else if(ins[14:13] == 2'b10) begin
          case (rt)
              4'd0 : core_r0  <= wb_data;
              4'd1 : core_r1  <= wb_data;
              4'd2 : core_r2  <= wb_data;
              4'd3 : core_r3  <= wb_data;
              4'd4 : core_r4  <= wb_data;
              4'd5 : core_r5  <= wb_data;
              4'd6 : core_r6  <= wb_data;
              4'd7 : core_r7  <= wb_data;
              4'd8 : core_r8  <= wb_data;
              4'd9 : core_r9  <= wb_data;
              4'd10: core_r10 <= wb_data;
              4'd11: core_r11 <= wb_data;
              4'd12: core_r12 <= wb_data;
              4'd13: core_r13 <= wb_data;
              4'd14: core_r14 <= wb_data;
              4'd15: core_r15 <= wb_data;
              default: begin end
          endcase          
        end
      end 
      default: begin end
    endcase
  end
end


//==============================================//
//               EXEACUTE BLOCK                 //
//==============================================//
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) num1 <= 'b0;
  else begin
    case (state)
      INS_D: begin
        if(ins[15:13] == 3'b100) num1 <= addr_ins;
        else begin
          case (rs)
            4'd0 : num1 <= core_r0;
            4'd1 : num1 <= core_r1;
            4'd2 : num1 <= core_r2;
            4'd3 : num1 <= core_r3;
            4'd4 : num1 <= core_r4;
            4'd5 : num1 <= core_r5;
            4'd6 : num1 <= core_r6;
            4'd7 : num1 <= core_r7;
            4'd8 : num1 <= core_r8;
            4'd9 : num1 <= core_r9;
            4'd10: num1 <= core_r10;
            4'd11: num1 <= core_r11;
            4'd12: num1 <= core_r12;
            4'd13: num1 <= core_r13;
            4'd14: num1 <= core_r14;
            4'd15: num1 <= core_r15;
            default: num1 <= 'b0;
          endcase
        end
      end 
      EXE: num1 <= 'b0;
      default: num1 <= num1;
      // default: num1 <= 'b0;
    endcase
  end
end

always @(posedge clk or negedge rst_n) begin
  if(!rst_n) num2 <= 'b0;
  else begin
    case (state)
      INS_D: begin
        if(ins[15:14] == 2'b00) begin
          case (rt)
            4'd0 : num2 <= (!ins[13] & ins[0]) ? -core_r0  : core_r0;
            4'd1 : num2 <= (!ins[13] & ins[0]) ? -core_r1  : core_r1;
            4'd2 : num2 <= (!ins[13] & ins[0]) ? -core_r2  : core_r2;
            4'd3 : num2 <= (!ins[13] & ins[0]) ? -core_r3  : core_r3;
            4'd4 : num2 <= (!ins[13] & ins[0]) ? -core_r4  : core_r4;
            4'd5 : num2 <= (!ins[13] & ins[0]) ? -core_r5  : core_r5;
            4'd6 : num2 <= (!ins[13] & ins[0]) ? -core_r6  : core_r6;
            4'd7 : num2 <= (!ins[13] & ins[0]) ? -core_r7  : core_r7;
            4'd8 : num2 <= (!ins[13] & ins[0]) ? -core_r8  : core_r8;
            4'd9 : num2 <= (!ins[13] & ins[0]) ? -core_r9  : core_r9;
            4'd10: num2 <= (!ins[13] & ins[0]) ? -core_r10 : core_r10;
            4'd11: num2 <= (!ins[13] & ins[0]) ? -core_r11 : core_r11;
            4'd12: num2 <= (!ins[13] & ins[0]) ? -core_r12 : core_r12;
            4'd13: num2 <= (!ins[13] & ins[0]) ? -core_r13 : core_r13;
            4'd14: num2 <= (!ins[13] & ins[0]) ? -core_r14 : core_r14;
            4'd15: num2 <= (!ins[13] & ins[0]) ? -core_r15 : core_r15;
            default: num2 <= 'b0;
          endcase          
        end
        else begin
          num2 <= imd;
        end
      end 
      EXE: num2 <= 'b0;
      default: num2 <= num2;
      // default: num2 <= 'b0;
    endcase
  end
  
end

// ALU 
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) add_res <= 'b0;
  else if(state == EXE) add_res <= num1 + num2;
  // else       add_res <= num1 + num2;

end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) mul_res <= 'b0;
  else       mul_res <= num1 * num2;
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) cmp_res <= 'b0;
  else       cmp_res <= (num1 < num2);
end

always @(*) begin
  case (rs)
    4'd0 : num3 = core_r0;
    4'd1 : num3 = core_r1;
    4'd2 : num3 = core_r2;
    4'd3 : num3 = core_r3;
    4'd4 : num3 = core_r4;
    4'd5 : num3 = core_r5;
    4'd6 : num3 = core_r6;
    4'd7 : num3 = core_r7;
    4'd8 : num3 = core_r8;
    4'd9 : num3 = core_r9;
    4'd10: num3 = core_r10;
    4'd11: num3 = core_r11;
    4'd12: num3 = core_r12;
    4'd13: num3 = core_r13;
    4'd14: num3 = core_r14;
    4'd15: num3 = core_r15;
    default: num3 = 'b0;
  endcase
    case (rt)
    4'd0 : num4 = core_r0;
    4'd1 : num4 = core_r1;
    4'd2 : num4 = core_r2;
    4'd3 : num4 = core_r3;
    4'd4 : num4 = core_r4;
    4'd5 : num4 = core_r5;
    4'd6 : num4 = core_r6;
    4'd7 : num4 = core_r7;
    4'd8 : num4 = core_r8;
    4'd9 : num4 = core_r9;
    4'd10: num4 = core_r10;
    4'd11: num4 = core_r11;
    4'd12: num4 = core_r12;
    4'd13: num4 = core_r13;
    4'd14: num4 = core_r14;
    4'd15: num4 = core_r15;
    default: num4 = 'b0;
  endcase
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) equ_res <= 'b0;
  else begin
    if(ins[15:13] == 3'b100) equ_res <= (num3 == num4);
    else                     equ_res <= 'b0;
  end
end
//==============================================//
//                  AXI4 BLOCK                  //
//==============================================//
// DRAM_data read channel
assign arid_m_inf[3:0]    = ID;
assign arburst_m_inf[1:0] = BURST;
assign arsize_m_inf[2:0]  = SIZE;
assign arlen_m_inf[6:0]   = LEN_R;

assign araddr_m_inf[31:0] = dram_raddr_data;
always @(*) begin
	case (state)
		LOAD: dram_raddr_data = {{20'h00001}, addr_data[10:7], {8'd0}};
		default: dram_raddr_data = 'b0;
	endcase
end

assign arvalid_m_inf[0] = dram_rvalid_data;
always @(*) begin
	case (state)
		LOAD: dram_rvalid_data = (hand_shake_data == ADDR);
    default: dram_rvalid_data = 'b0;
	endcase
end

assign rready_m_inf[0] = dram_rready_data;
always @(*) begin
	case (state)
    LOAD: dram_rready_data = (hand_shake_data == DATA);
		default: dram_rready_data = 'b0;
	endcase
end

// DRAM_data write channel
assign awid_m_inf    = ID;
assign awburst_m_inf = BURST;
assign awsize_m_inf  = SIZE;
assign awlen_m_inf   = LEN_W;
assign bid_m_inf     = ID;

assign awaddr_m_inf = dram_waddr;
always @(*) begin
	case (state)
    STORE:   dram_waddr = {{20'h00001}, addr_data, {1'd0}};
		default: dram_waddr = 'b0;
	endcase
end

assign awvalid_m_inf = dram_wavalid;
always @(*) begin
	case (state)
		STORE:   dram_wavalid = (hand_shake_data == ADDR);
		default: dram_wavalid = 'b0;
	endcase
end

// assign wvalid_m_inf = dram_wdvalid;
assign wvalid_m_inf = dram_wdvalid_d1;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) dram_wdvalid <= 'b0;
	else begin
		case (state)
      // STORE:   dram_wdvalid <= (hand_shake_data == DATA && !(sram_cnt_data == 7'd1));
      STORE:   dram_wdvalid <= (wready_m_inf) ?  'b0 : (hand_shake_data == DATA);
      default: dram_wdvalid <= 'b0;
	  endcase	  
	end
end

// assign wdata_m_inf = dram_wdata;
assign wdata_m_inf = dram_wdata_d1;
always @(*) begin
	case (state)
    // STORE:   dram_wdata = sram_dout_data; 
    // STORE:   dram_wdata = sram_din_data; 
    STORE: begin
      case (rt)
          4'd0 : dram_wdata= core_r0;
          4'd1 : dram_wdata= core_r1;
          4'd2 : dram_wdata= core_r2;
          4'd3 : dram_wdata= core_r3;
          4'd4 : dram_wdata= core_r4;
          4'd5 : dram_wdata= core_r5;
          4'd6 : dram_wdata= core_r6;
          4'd7 : dram_wdata= core_r7;
          4'd8 : dram_wdata= core_r8;
          4'd9 : dram_wdata= core_r9;
          4'd10: dram_wdata= core_r10;
          4'd11: dram_wdata= core_r11;
          4'd12: dram_wdata= core_r12;
          4'd13: dram_wdata= core_r13;
          4'd14: dram_wdata= core_r14;
          4'd15: dram_wdata= core_r15;
          default: dram_wdata = 'b0;
        endcase
    end
		default: dram_wdata = 'b0;
	endcase
end

// assign wlast_m_inf = dram_wlast;
assign wlast_m_inf = dram_wlast_d1;
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) dram_wlast <= 'b0;
  else begin
    case (state)
      STORE:   dram_wlast <= (wready_m_inf) ?  'b0 : (hand_shake_data == DATA);
      // STORE:   dram_wlast <= (wready_m_inf) ? 1'b1 : 'b0;
      default: dram_wlast <= 'b0;
    endcase    
  end

end
// always @(*) begin
// 	case (state)
//     STORE:   dram_wlast = (hand_shake_data == DATA);
// 		default: dram_wlast = 'b0;
// 	endcase
// end

assign bready_m_inf = dram_bready;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) dram_bready <= 'b0;
	else begin
    case (state)
      STORE: begin
        if(bvalid_m_inf) dram_bready <= 1'b0;
        else             dram_bready <= 1'b1;
      end
      default: dram_bready <= 'b0;
    endcase
		// if(state == STORE && hand_shake_data == DATA) begin
		// 	if(bvalid_m_inf) dram_bready <= 1'b0;
		// 	else             dram_bready <= 1'b1;
		// end
	end
end

// delay register
always @(posedge clk) begin
  dram_wdata_d1   <= dram_wdata;
  dram_wdvalid_d1 <= dram_wdvalid;
  dram_wlast_d1   <= dram_wlast;
end


// DRAM_ins read channel
assign arid_m_inf[7:4]    = ID;
assign arburst_m_inf[3:2] = BURST;
assign arsize_m_inf[5:3]  = SIZE;
assign arlen_m_inf[13:7]  = LEN_R;

assign araddr_m_inf[63:32] = dram_raddr_ins;
always @(*) begin
	case (state)
    LOAD: dram_raddr_ins = {{20'h00001}, addr_ins[10:7], {8'd0}};
    default: dram_raddr_ins = 'b0;
	endcase
end

assign arvalid_m_inf[1] = dram_rvalid_ins;
always @(*) begin
	case (state)
		LOAD: dram_rvalid_ins = (hand_shake_ins == ADDR);
    default: dram_rvalid_ins = 'b0;
	endcase
end

assign rready_m_inf[1] = dram_rready_ins;
always @(*) begin
	case (state)
    LOAD: dram_rready_ins = (hand_shake_ins == DATA);
		default: dram_rready_ins = 'b0;
	endcase
end

//==============================================//
//                  SRAM BLOCK                  //
//==============================================//
// SRAM_data channel
always @(*) begin
  if(hand_shake_data == DATA) sram_addr_data = (state == STORE) ? addr_data : ((wready_m_inf) ? (sram_cnt_data + 1) : sram_cnt_data);
  // if(hand_shake_data == DATA) sram_addr_data = ((wready_m_inf) ? (sram_cnt_data + 1) : sram_cnt_data);
  else                        sram_addr_data = addr_data;
end
always @(*) begin
    case (state)
      LOAD: begin
        if(hand_shake_data == DATA) sram_din_data = rdata_m_inf[15:0];
        else                        sram_din_data = 'b0;
      end
      STORE: begin
        if(flag_hit) begin
          case (rt)
            4'd0 : sram_din_data = core_r0;
            4'd1 : sram_din_data = core_r1;
            4'd2 : sram_din_data = core_r2;
            4'd3 : sram_din_data = core_r3;
            4'd4 : sram_din_data = core_r4;
            4'd5 : sram_din_data = core_r5;
            4'd6 : sram_din_data = core_r6;
            4'd7 : sram_din_data = core_r7;
            4'd8 : sram_din_data = core_r8;
            4'd9 : sram_din_data = core_r9;
            4'd10: sram_din_data = core_r10;
            4'd11: sram_din_data = core_r11;
            4'd12: sram_din_data = core_r12;
            4'd13: sram_din_data = core_r13;
            4'd14: sram_din_data = core_r14;
            4'd15: sram_din_data = core_r15;
            default: sram_din_data = 'b0;
          endcase 
        end
        else sram_din_data = 'b0;
      end
      default: sram_din_data = 'b0;
    endcase
end
always @(*) begin
	case (state)
    LOAD: begin
      if(hand_shake_data == DATA) sram_wen_data = 0;
      else                        sram_wen_data = 1;
    end
    STORE: begin
      if(flag_hit) sram_wen_data = 0;
      else         sram_wen_data = 1;
      // sram_wen_data = 0;
    end
    // MEM: begin
    //   if(ins[14:13] == 2'b11) sram_wen_data = 0;
    //   else                    sram_wen_data = 1;
    // end
		default: sram_wen_data = 1;
	endcase	
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) sram_cnt_data <= 'b0;
  else begin
    // if(state == STORE) begin
    //   sram_cnt_data <= addr_data;
    // end
    // else begin
    //   if(rvalid_m_inf[0] | wready_m_inf) sram_cnt_data <= sram_cnt_data + 1'b1;
    //   else                               sram_cnt_data <= 'b0; 
    // end
    if(rvalid_m_inf[0] | wready_m_inf) begin
      if(sram_cnt_data == 7'd127) sram_cnt_data <= sram_cnt_data;
      else                        sram_cnt_data <= sram_cnt_data + 1'b1;
    end
    else                          sram_cnt_data <= 'b0; 
  end
end

// SRAM_ins channel
always @(*) begin
  if(hand_shake_ins == DATA) sram_addr_ins = sram_cnt_ins;
  else sram_addr_ins = addr_ins;
  // case (hand_shake_ins)
  //   ADDR:    sram_addr_ins = addr_ins;
  //   DATA:    sram_addr_ins = sram_cnt_ins;
  //   default: sram_addr_ins = addr_ins;
  // endcase
end
always @(*) begin
  case (state)
    LOAD: begin
      if(hand_shake_ins == DATA) sram_din_ins = rdata_m_inf[31:16];
      else                       sram_din_ins = 'b0;      
    end 
    STORE: begin
      if(flag_hit) sram_din_ins = ins;
      else         sram_din_ins = 'b0;
    end
    default: sram_din_ins = 'b0;
  endcase
  // if(state == LOAD) begin
  //   if(hand_shake_ins == DATA) sram_din_ins = rdata_m_inf[31:16];
  //   else                       sram_din_ins = 'b0;
  // end
  // else sram_din_ins = 'b0;
end
always @(*) begin
	case (hand_shake_ins)
    DATA: sram_wen_ins = 0;
		default: sram_wen_ins = 1;
	endcase	
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) sram_cnt_ins <= 'b0;
  else begin
    if(rvalid_m_inf[1]) sram_cnt_ins <= sram_cnt_ins + 1'b1;
    else                sram_cnt_ins <= 'b0; 
  end
end

SRAM_16x128 SRAM_INS_U0(
	.A0  (sram_addr_ins[0]), .A1  (sram_addr_ins[1]), .A2  (sram_addr_ins[2]),  .A3  (sram_addr_ins[3]),  .A4  (sram_addr_ins[4]),  .A5  (sram_addr_ins[5]),  .A6  (sram_addr_ins[6]),
	.DO0 (sram_dout_ins[0]), .DO1 (sram_dout_ins[1]), .DO2 (sram_dout_ins[2]),  .DO3 (sram_dout_ins[3]),  .DO4 (sram_dout_ins[4]),  .DO5 (sram_dout_ins[5]),  .DO6 (sram_dout_ins[6]),   .DO7 (sram_dout_ins[7]),
	.DO8 (sram_dout_ins[8]), .DO9 (sram_dout_ins[9]), .DO10(sram_dout_ins[10]), .DO11(sram_dout_ins[11]), .DO12(sram_dout_ins[12]), .DO13(sram_dout_ins[13]), .DO14(sram_dout_ins[14]),  .DO15(sram_dout_ins[15]),
	.DI0 (sram_din_ins[0]),  .DI1 (sram_din_ins[1]),  .DI2 (sram_din_ins[2]),   .DI3 (sram_din_ins[3]),   .DI4 (sram_din_ins[4]),   .DI5 (sram_din_ins[5]),   .DI6 (sram_din_ins[6]),   .DI7 (sram_din_ins[7]),
	.DI8 (sram_din_ins[8]),  .DI9 (sram_din_ins[9]),  .DI10(sram_din_ins[10]),  .DI11(sram_din_ins[11]),  .DI12(sram_din_ins[12]),  .DI13(sram_din_ins[13]),  .DI14(sram_din_ins[14]),  .DI15(sram_din_ins[15]),
	.CK(clk), .WEB(sram_wen_ins), .OE(1'b1), .CS(1'b1));

SRAM_16x128 SRAM_DATA_U0(
    .A0  (sram_addr_data[0]), .A1  (sram_addr_data[1]), .A2  (sram_addr_data[2]),  .A3  (sram_addr_data[3]),  .A4  (sram_addr_data[4]),  .A5  (sram_addr_data[5]),  .A6  (sram_addr_data[6]),
    .DO0 (sram_dout_data[0]), .DO1 (sram_dout_data[1]), .DO2 (sram_dout_data[2]),  .DO3 (sram_dout_data[3]),  .DO4 (sram_dout_data[4]),  .DO5 (sram_dout_data[5]),  .DO6 (sram_dout_data[6]),   .DO7 (sram_dout_data[7]),
    .DO8 (sram_dout_data[8]), .DO9 (sram_dout_data[9]), .DO10(sram_dout_data[10]), .DO11(sram_dout_data[11]), .DO12(sram_dout_data[12]), .DO13(sram_dout_data[13]), .DO14(sram_dout_data[14]),  .DO15(sram_dout_data[15]),
    .DI0 (sram_din_data[0]),  .DI1 (sram_din_data[1]),  .DI2 (sram_din_data[2]),   .DI3 (sram_din_data[3]),   .DI4 (sram_din_data[4]),   .DI5 (sram_din_data[5]),   .DI6 (sram_din_data[6]),   .DI7 (sram_din_data[7]),
    .DI8 (sram_din_data[8]),  .DI9 (sram_din_data[9]),  .DI10(sram_din_data[10]),  .DI11(sram_din_data[11]),  .DI12(sram_din_data[12]),  .DI13(sram_din_data[13]),  .DI14(sram_din_data[14]),  .DI15(sram_din_data[15]),
    .CK(clk), .WEB(sram_wen_data), .OE(1'b1), .CS(1'b1));

//==============================================//
//                 OUTPUT BLOCK                 //
//==============================================//

always @(posedge clk or negedge rst_n) begin
  if(!rst_n) IO_stall <= 1'b1;
  else       IO_stall <= ~(state == INS_F & ~(ins == 16'd0));
  // else       IO_stall <= ~(state == WB | (state == INS_D & ins[15:13] == 3'b101));
end
endmodule



















