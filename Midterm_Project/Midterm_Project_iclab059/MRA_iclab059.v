//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Midterm Proejct            : MRA  
//   Author                     : Tse-Chun Hsu
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//   Release version : V2.0 (Release Date: 2023-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA(
	// CHIP IO
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost	 		,		
	busy         	,

    // AXI4 IO
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
	   rready_m_inf,
	
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
	   bready_m_inf 
);
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 128;
// ===============================================================
//  					Input / Output 
// ===============================================================

// << CHIP io port with system >>
input 			  	clk,rst_n;
input 			   	in_valid;
input  [4:0] 		frame_id;
input  [3:0]       	net_id;     
input  [5:0]       	loc_x; 
input  [5:0]       	loc_y; 
output reg [13:0] 	cost;
output reg          busy;       
  
// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...);
*/

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;
output wire                  arvalid_m_inf;
input  wire                  arready_m_inf;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output wire                   rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output wire                  awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output wire                   wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output wire                    wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output wire                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------

//==============================================//
//                  Parameter                   //
//==============================================//

parameter IDLE    = 4'd0;
parameter DRAM_R  = 4'd1;
// parameter FILLING = 4'd2;
// parameter RETRACE = 4'd3;
// parameter DRAM_W  = 4'd4;
parameter FILL_1  = 4'd2;
parameter FILL_2  = 4'd3;
parameter FILLING = 4'd4;
parameter RETRACE = 4'd5;
parameter CLEAN   = 4'd6;
parameter DRAM_W  = 4'd7;

// parameter IDLE    = 2'd0;
parameter ADDR   = 2'd0;
parameter DATA   = 2'd1;

integer i, j;
//==============================================//
//                  Register                    //
//==============================================//
// FSM register
reg [3:0] state;
reg [3:0] state_next;
reg [1:0] hand_shake;
reg [1:0] hand_shake_next;
reg [6:0] cnt;
reg [6:0] cnt_next;
reg [6:0] cnt_dram_data;
reg [6:0] cnt_dram_data_next;
reg [3:0] cnt_net;
reg [3:0] cnt_net_next;
reg [3:0] num_net_reg;

reg read_source_flag;

// input register
reg [4:0] frame_id_reg;
reg [4:0] frame_id_next;
reg [3:0] net_id_reg    [0:14];
reg [3:0] net_id_next   [0:14];
reg [5:0] source_x_reg  [0:14];
reg [5:0] source_x_next [0:14]; 
reg [5:0] sink_x_reg    [0:14];
reg [5:0] sink_x_next   [0:14];
reg [5:0] source_y_reg  [0:14];
reg [5:0] source_y_next [0:14];
reg [5:0] sink_y_reg    [0:14];
reg [5:0] sink_y_next   [0:14];

reg [5:0] source_x_current;
reg [5:0] source_y_current;
reg [5:0] sink_x_current;
reg [5:0] sink_y_current;


// SRAM register
reg [6:0]            sram_addr_map;
reg [DATA_WIDTH-1:0] sram_dout_map;
reg [DATA_WIDTH-1:0] sram_din_map;
reg                  sram_wen_map;
reg [6:0]            sram_addr_weight;
reg [DATA_WIDTH-1:0] sram_dout_weight;
reg [DATA_WIDTH-1:0] sram_din_weight;
reg                  sram_wen_weight;


// DRAM read channel register
reg [ADDR_WIDTH-1:0] dram_raddr;
reg                  dram_rvalid;
reg                  dram_rready;

// DRAM write channel register
reg [ADDR_WIDTH-1:0] dram_waddr;
reg                  dram_wavalid;
reg [DATA_WIDTH-1:0] dram_wdata;
reg                  dram_wdvalid;
reg                  dram_wlast;
reg                  dram_bready;


// filling map
reg [1:0] map      [0:63][0:63];
reg [1:0] map_next [0:63][0:63];
wire filling_done;
reg [1:0] filling_value;


// retrace 
reg [5:0] retrace_x;
reg [5:0] retrace_x_next;
reg [5:0] retrace_y;
reg [5:0] retrace_y_next;
wire retrace_done;

reg [3:0] map_data [0:31];

// cost
reg [13:0] cost_reg;
reg [13:0] cost_next;
reg [3:0]  weight_data [0:31];

//==============================================//
//                     Wire                     //
//==============================================//
// assign filling_done = (map[sink_y_reg[cnt_net]][sink_x_reg[cnt_net] + 1][1] | map[sink_y_reg[cnt_net]][sink_x_reg[cnt_net] - 1][1] | map[sink_y_reg[cnt_net] + 1][sink_x_reg[cnt_net]][1] | map[sink_y_reg[cnt_net] - 1][sink_x_reg[cnt_net]][1]);
// assign filling_done = (map_next[sink_y_reg[cnt_net]][sink_x_reg[cnt_net] + 1][1] | map_next[sink_y_reg[cnt_net]][sink_x_reg[cnt_net] - 1][1] | map_next[sink_y_reg[cnt_net] + 1][sink_x_reg[cnt_net]][1] | map_next[sink_y_reg[cnt_net] - 1][sink_x_reg[cnt_net]][1]);

// assign filling_done = map_next[sink_y_reg[cnt_net]][sink_x_reg[cnt_net]][1];
assign filling_done = map[sink_y_current][sink_x_current][1];

// assign retrace_done = (retrace_x_next == source_x_reg[cnt_net] && retrace_y_next == source_y_reg[cnt_net]);
assign retrace_done = (retrace_x == source_x_current && retrace_y == source_y_current);

// assign filling_value = (map[sink_y_reg[cnt_net]][sink_x_reg[cnt_net]][1]) ? 2'd0 : {1'b1, cnt[2]};

//==============================================//
//                  FSM Block                   //
//==============================================//
// main FSM
always @(*) begin
	case (state)
		IDLE: begin
			if(in_valid) state_next = DRAM_R;
			else         state_next = IDLE;
		end 
		DRAM_R: begin
			if(rlast_m_inf) state_next = FILL_1;
			else            state_next = DRAM_R;
		end
		FILL_1: begin
			state_next = FILL_2;
		end
		FILL_2: begin
			state_next = FILLING;
		end
		FILLING: begin
			if(filling_done && ((rlast_m_inf && rvalid_m_inf && rready_m_inf) || cnt_net !== 0)) 
			     state_next = RETRACE;
			else state_next = FILLING;
		end
		RETRACE: begin
			if(retrace_done) begin
				if(cnt_net == num_net_reg - 1) state_next = DRAM_W;
				else                           state_next = CLEAN;
			end 
			else                           state_next = RETRACE;
		end
		CLEAN: begin
			state_next = FILL_1;
		end
		DRAM_W: begin
			if(bvalid_m_inf) state_next = IDLE;
			else             state_next = DRAM_W;
		end
		default: state_next = IDLE;
	endcase
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) state <= 'b0;
	else       state <= state_next;
end
// DRAM AXI FSM
always @(*) begin
	case (state)
		DRAM_R, FILLING, DRAM_W: begin
			case (hand_shake)
				ADDR: begin
					if(arready_m_inf | awready_m_inf) hand_shake_next = DATA;
					else                              hand_shake_next = ADDR;
				end  
				DATA: begin
					// if(state == RETRACE) hand_shake_next = ADDR;
					if(rlast_m_inf | bvalid_m_inf) hand_shake_next = ADDR;
					else                           hand_shake_next = DATA;
				end
				default: hand_shake_next = hand_shake;
			endcase		  
		end
		default: hand_shake_next = hand_shake;
	endcase
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) hand_shake <= 'b0;
	else       hand_shake <= hand_shake_next;
end
// read flag
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) read_source_flag <= 'b0;
	else	begin
		if(in_valid) read_source_flag <= ~read_source_flag;
		else         read_source_flag <= read_source_flag; 
	end
end
// global cnt
always @(*) begin
	cnt_next = cnt;
	case (state)
		IDLE, DRAM_R: begin
			if(in_valid) begin
				if(read_source_flag) cnt_next = cnt + 1;
				else                 cnt_next = cnt;
			end 
			else cnt_next = 'b0;
		end 
		FILL_2, FILLING: begin
			if(filling_done) begin
				if(cnt_net == 0 & !(rlast_m_inf && rvalid_m_inf && rready_m_inf)) cnt_next = cnt;
				else                                                              cnt_next = cnt - 1'd1;
				// if(cnt_net == 0) begin
				// 	if(rlast_m_inf && rvalid_m_inf && rready_m_inf) cnt_next = cnt - 1'd1;
				// 	else                                            cnt_next = cnt;
				// end
				// else cnt_next = cnt - 1'd1;
			end
			else if(cnt == 7'd6) cnt_next = 'b0;
			else                 cnt_next = cnt + 2'd2;
		end
		RETRACE: begin
			if(cnt == 7'd0) cnt_next = 7'd7;
			else            cnt_next = cnt - 1;
		end
		default: begin end
	endcase
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) cnt <= 'b0;
	else       cnt <= cnt_next;
end
// DRAM data cnt
always @(*) begin
	if     (arready_m_inf | awready_m_inf) cnt_dram_data_next = 'b0;
	else if(rvalid_m_inf | wready_m_inf)   cnt_dram_data_next = cnt_dram_data + 1;
	else                                   cnt_dram_data_next = cnt_dram_data;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) cnt_dram_data <= 'b0;
	else       cnt_dram_data <= cnt_dram_data_next;
end
// net cnt
always @(*) begin
	cnt_net_next = cnt_net;
	if(state == IDLE) cnt_net_next = 'b0;
	if(state == RETRACE && retrace_done) cnt_net_next = cnt_net + 1;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) cnt_net <= 'b0;
	else       cnt_net <= cnt_net_next;
end
//==============================================//
//                 Input Block                  //
//==============================================//
// frame id
always @(*) begin
	frame_id_next = frame_id_reg;
	case (state)
		IDLE: begin
			if(in_valid) frame_id_next = frame_id;
		end 
		default: begin end
	endcase
	// if(in_valid) frame_id_next = frame_id;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) frame_id_reg <= 'b0;
	else       frame_id_reg <= frame_id_next;
end
// net id
always @(*) begin
	for(i = 0; i < 15; i = i + 1) net_id_next[i] = net_id_reg[i];
	if((state == IDLE | state == DRAM_R) & in_valid) net_id_next[cnt] = net_id;
	// if(in_valid) net_id_next[cnt] = net_id;



	// case (state)
	// 	IDLE, DRAM_R: begin
	// 		if(in_valid) net_id_next[cnt] = net_id;
	// 	end
	// 	default: begin end
	// endcase
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 15; i = i + 1) net_id_reg[i] <= 'b0;
	end
	else begin
		for(i = 0; i < 15; i = i + 1) net_id_reg[i] <= net_id_next[i];
		// for(i = 0; i < 15; i = i + 1) begin
		// 	if((state == IDLE | state == DRAM_R) & i == cnt)
		// 		net_id_reg[i] <= net_id;
		// 	else 
		// 		net_id_reg[i] <= net_id_reg[i];
		// 		// net_id_reg[i] <= net_id_next[i];
		// end
	end
end
always @(*) begin
	for(i = 0; i < 15; i = i + 1) begin
		source_x_next[i] = source_x_reg[i];	
		sink_x_next[i]   = sink_x_reg[i];
		source_y_next[i] = source_y_reg[i];	
		sink_y_next[i]   = sink_y_reg[i];
	end

	if((state == IDLE | state == DRAM_R) & in_valid) begin
		if(!read_source_flag) begin
			source_x_next[cnt] = loc_x;
			source_y_next[cnt] = loc_y;
		end
		else begin
			sink_x_next[cnt] = loc_x;
			sink_y_next[cnt] = loc_y;			  
		end	  
	end
	// case (state)
	// 	IDLE, DRAM_R: begin
	// 		if(in_valid) begin
	// 			if(!read_source_flag) begin
	// 				source_x_next[cnt] = loc_x;
	// 				source_y_next[cnt] = loc_y;
	// 			end
	// 			else begin
	// 				sink_x_next[cnt] = loc_x;
	// 				sink_y_next[cnt] = loc_y;			  
	// 			end
	// 		end
	// 	end
	// 	default: begin end
	// endcase
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 15; i = i + 1) begin
			source_x_reg[i] <= 'b0;	
			sink_x_reg[i]   <= 'b0;
			source_y_reg[i] <= 'b0;	
			sink_y_reg[i]   <= 'b0;
		end
	end
	else begin
		for(i = 0; i < 15; i = i + 1) begin
			source_x_reg[i] <= source_x_next[i];	
			sink_x_reg[i]   <= sink_x_next[i];
			source_y_reg[i] <= source_y_next[i];	
			sink_y_reg[i]   <= sink_y_next[i];
		end
	end
end
// number of net
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) num_net_reg <= 'b0;
	else begin
		case (state)
			IDLE:   num_net_reg <='b0;
			DRAM_R: begin
				if(in_valid && read_source_flag) num_net_reg <= num_net_reg + 1;
				else                             num_net_reg <= num_net_reg;			  
			end
			default: num_net_reg <= num_net_reg;
		endcase
	end
end
//==============================================//
//                  AXI4 Block                  //
//==============================================//
// DRAM read channel
assign arid_m_inf    = 4'd0;
assign arburst_m_inf = 2'b01;
assign arsize_m_inf  = 3'b100;
assign arlen_m_inf   = 8'd127;

assign araddr_m_inf = dram_raddr;
always @(*) begin
	case (state)
		DRAM_R:  dram_raddr = {{16'h 0001}, frame_id_reg , 11'h0};
		FILLING: dram_raddr = {{16'h 0002}, frame_id_reg , 11'h0};
		default: dram_raddr = 'b0;
	endcase
end

assign arvalid_m_inf = dram_rvalid;
always @(*) begin
	case (state)
		DRAM_R:  dram_rvalid = (hand_shake == ADDR);
		FILLING: dram_rvalid = (hand_shake == ADDR && cnt_net == 0);
		default: dram_rvalid = 'b0;
	endcase
end

assign rready_m_inf = dram_rready;
always @(*) begin
	case (state)
		DRAM_R, FILLING: dram_rready = (hand_shake == DATA);
		default: dram_rready = 'b0;
	endcase
end

// DRAM write channel
assign awid_m_inf    = 4'd0;
assign awburst_m_inf = 2'b01;
assign awsize_m_inf  = 3'b100;
assign awlen_m_inf   = 8'd127;
assign bid_m_inf     = 4'd0;

assign awaddr_m_inf = dram_waddr;
always @(*) begin
	case (state)
		DRAM_W:  dram_waddr = {{16'h 0001}, frame_id_reg , 11'h0};
		default: dram_waddr = 'b0;
	endcase
end

assign awvalid_m_inf = dram_wavalid;
always @(*) begin
	case (state)
		DRAM_W:  dram_wavalid = (hand_shake == ADDR);
		default: dram_wavalid = 'b0;
	endcase
end

assign wvalid_m_inf = dram_wdvalid;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		dram_wdvalid <= 'b0;
	end
	else begin
		case (state)
		DRAM_W:  dram_wdvalid <= (hand_shake == DATA && !(cnt_dram_data == 7'd127));
		default: dram_wdvalid <= 'b0;
	endcase	  
	end
end

assign wdata_m_inf = dram_wdata;
always @(*) begin
	case (state)
		DRAM_W:  dram_wdata = sram_dout_map; 
		default: dram_wdata = 'b0;
	endcase
end

assign wlast_m_inf = dram_wlast;
always @(*) begin
	case (state)
		DRAM_W:  dram_wlast = (cnt_dram_data == 7'd127);
		default: dram_wlast = 'b0;
	endcase
end

assign bready_m_inf = dram_bready;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) dram_bready <= 'b0;
	else begin
		if(state == DRAM_W && hand_shake == DATA) begin
			if(bvalid_m_inf) dram_bready <= 1'b0;
			else             dram_bready <= 1'b1;
		end
	end
end
//==============================================//
//                  SRAM Block                  //
//==============================================//
// sram map channel
always @(*) begin
	case (state)
		DRAM_R:  sram_addr_map = cnt_dram_data;
		RETRACE: sram_addr_map = (retrace_y << 1) + retrace_x[5];
		DRAM_W:  begin
			if(wready_m_inf) sram_addr_map = cnt_dram_data + 1;
			else             sram_addr_map = cnt_dram_data;
		end
		default: sram_addr_map = 'b0;
	endcase
end
always @(*) begin
	case (state)
		RETRACE: begin
			for(i = 0; i < 32; i = i + 1) begin
				if(i == retrace_x[4:0]) sram_din_map[i * 4 +: 4] = net_id_reg[cnt_net];
				else                    sram_din_map[i * 4 +: 4] = map_data[i];
			end
		end	
		default: sram_din_map  = rdata_m_inf;
	endcase
end
always @(*) begin
	case (state)
		DRAM_R:  sram_wen_map = 0; 
		RETRACE: sram_wen_map = (retrace_x == sink_x_current && retrace_y == sink_y_current) || cnt[0];
		default: sram_wen_map = 1;
	endcase
end
always @(*) begin
	for(i = 0; i < 32; i = i + 1) map_data[i] <= sram_dout_map[i * 4 +: 4];	
end
// SRAM weight channel
always @(*) begin
	case (state)
		FILLING: sram_addr_weight = cnt_dram_data;
		RETRACE: sram_addr_weight = (retrace_y << 1) + retrace_x[5];
		default: sram_addr_weight = 'b0;
	endcase
end
always @(*) begin
	for(i = 0; i < 32; i = i + 1) begin
		if(state == RETRACE) begin
			if(i == retrace_x[4:0]) sram_din_weight[i * 4 +: 4] = net_id_reg[cnt_net];
			else                    sram_din_weight[i * 4 +: 4] = map_data[i];		  
		end
		else sram_din_weight  = rdata_m_inf;
	end
	// case (state)
	// 	RETRACE: begin
	// 		for(i = 0; i < 32; i = i + 1) begin
	// 			if(i == retrace_x[4:0]) sram_din_weight[i * 4 +: 4] = net_id_reg[cnt_net];
	// 			else                    sram_din_weight[i * 4 +: 4] = map_data[i];
	// 		end
	// 	end	
	// 	default: sram_din_weight  = rdata_m_inf;
	// endcase
end
always @(*) begin
	case (state)
		FILLING: sram_wen_weight = ~(cnt_net == 4'd0);
		// FILLING: sram_wen_weight = 0;
		default: sram_wen_weight = 1;
	endcase	
end
always @(*) begin
	if(state == RETRACE & (retrace_x != sink_x_current || retrace_y != sink_y_current)) begin
		for(i = 0; i < 32; i = i + 1) weight_data[i] = sram_dout_weight[i * 4 +: 4];
	end
	else begin
		for(i = 0; i < 32; i = i + 1) weight_data[i] = 'b0;
	end
	
end

SRAM_128x128 SRAM_MAP_U0(
	.A0  (sram_addr_map[0]),   .A1  (sram_addr_map[1]),   .A2  (sram_addr_map[2]),   .A3  (sram_addr_map[3]),   .A4  (sram_addr_map[4]),   .A5  (sram_addr_map[5]),   .A6  (sram_addr_map[6]),
	.DO0 (sram_dout_map[0]),   .DO1 (sram_dout_map[1]),   .DO2 (sram_dout_map[2]),   .DO3 (sram_dout_map[3]),   .DO4 (sram_dout_map[4]),   .DO5 (sram_dout_map[5]),   .DO6 (sram_dout_map[6]),   .DO7 (sram_dout_map[7]),
	.DO8 (sram_dout_map[8]),   .DO9 (sram_dout_map[9]),   .DO10(sram_dout_map[10]),  .DO11(sram_dout_map[11]),  .DO12(sram_dout_map[12]),  .DO13(sram_dout_map[13]),  .DO14(sram_dout_map[14]),  .DO15(sram_dout_map[15]),
	.DO16(sram_dout_map[16]),  .DO17(sram_dout_map[17]),  .DO18(sram_dout_map[18]),  .DO19(sram_dout_map[19]),  .DO20(sram_dout_map[20]),  .DO21(sram_dout_map[21]),  .DO22(sram_dout_map[22]),  .DO23(sram_dout_map[23]),
	.DO24(sram_dout_map[24]),  .DO25(sram_dout_map[25]),  .DO26(sram_dout_map[26]),  .DO27(sram_dout_map[27]),  .DO28(sram_dout_map[28]),  .DO29(sram_dout_map[29]),  .DO30(sram_dout_map[30]),  .DO31(sram_dout_map[31]),
	.DO32(sram_dout_map[32]),  .DO33(sram_dout_map[33]),  .DO34(sram_dout_map[34]),  .DO35(sram_dout_map[35]),  .DO36(sram_dout_map[36]),  .DO37(sram_dout_map[37]),  .DO38(sram_dout_map[38]),  .DO39(sram_dout_map[39]),
	.DO40(sram_dout_map[40]),  .DO41(sram_dout_map[41]),  .DO42(sram_dout_map[42]),  .DO43(sram_dout_map[43]),  .DO44(sram_dout_map[44]),  .DO45(sram_dout_map[45]),  .DO46(sram_dout_map[46]),  .DO47(sram_dout_map[47]),
	.DO48(sram_dout_map[48]),  .DO49(sram_dout_map[49]),  .DO50(sram_dout_map[50]),  .DO51(sram_dout_map[51]),  .DO52(sram_dout_map[52]),  .DO53(sram_dout_map[53]),  .DO54(sram_dout_map[54]),  .DO55(sram_dout_map[55]),
	.DO56(sram_dout_map[56]),  .DO57(sram_dout_map[57]),  .DO58(sram_dout_map[58]),  .DO59(sram_dout_map[59]),  .DO60(sram_dout_map[60]),  .DO61(sram_dout_map[61]),  .DO62(sram_dout_map[62]),  .DO63(sram_dout_map[63]),
	.DO64(sram_dout_map[64]),  .DO65(sram_dout_map[65]),  .DO66(sram_dout_map[66]),  .DO67(sram_dout_map[67]),  .DO68(sram_dout_map[68]),  .DO69(sram_dout_map[69]),  .DO70(sram_dout_map[70]),  .DO71(sram_dout_map[71]),
	.DO72(sram_dout_map[72]),  .DO73(sram_dout_map[73]),  .DO74(sram_dout_map[74]),  .DO75(sram_dout_map[75]),  .DO76(sram_dout_map[76]),  .DO77(sram_dout_map[77]),  .DO78(sram_dout_map[78]),  .DO79(sram_dout_map[79]),
	.DO80(sram_dout_map[80]),  .DO81(sram_dout_map[81]),  .DO82(sram_dout_map[82]),  .DO83(sram_dout_map[83]),  .DO84(sram_dout_map[84]),  .DO85(sram_dout_map[85]),  .DO86(sram_dout_map[86]),  .DO87(sram_dout_map[87]),
	.DO88(sram_dout_map[88]),  .DO89(sram_dout_map[89]),  .DO90(sram_dout_map[90]),  .DO91(sram_dout_map[91]),  .DO92(sram_dout_map[92]),  .DO93(sram_dout_map[93]),  .DO94(sram_dout_map[94]),  .DO95(sram_dout_map[95]),
	.DO96(sram_dout_map[96]),  .DO97(sram_dout_map[97]),  .DO98(sram_dout_map[98]),  .DO99(sram_dout_map[99]),  .DO100(sram_dout_map[100]),.DO101(sram_dout_map[101]),.DO102(sram_dout_map[102]),.DO103(sram_dout_map[103]),
	.DO104(sram_dout_map[104]),.DO105(sram_dout_map[105]),.DO106(sram_dout_map[106]),.DO107(sram_dout_map[107]),.DO108(sram_dout_map[108]),.DO109(sram_dout_map[109]),.DO110(sram_dout_map[110]),.DO111(sram_dout_map[111]),
	.DO112(sram_dout_map[112]),.DO113(sram_dout_map[113]),.DO114(sram_dout_map[114]),.DO115(sram_dout_map[115]),.DO116(sram_dout_map[116]),.DO117(sram_dout_map[117]),.DO118(sram_dout_map[118]),.DO119(sram_dout_map[119]),
	.DO120(sram_dout_map[120]),.DO121(sram_dout_map[121]),.DO122(sram_dout_map[122]),.DO123(sram_dout_map[123]),.DO124(sram_dout_map[124]),.DO125(sram_dout_map[125]),.DO126(sram_dout_map[126]),.DO127(sram_dout_map[127]),
	.DI0 (sram_din_map[0]),   .DI1 (sram_din_map[1]),   .DI2 (sram_din_map[2]),   .DI3 (sram_din_map[3]),   .DI4 (sram_din_map[4]),   .DI5 (sram_din_map[5]),   .DI6 (sram_din_map[6]),   .DI7 (sram_din_map[7]),
	.DI8 (sram_din_map[8]),   .DI9 (sram_din_map[9]),   .DI10(sram_din_map[10]),  .DI11(sram_din_map[11]),  .DI12(sram_din_map[12]),  .DI13(sram_din_map[13]),  .DI14(sram_din_map[14]),  .DI15(sram_din_map[15]),
	.DI16(sram_din_map[16]),  .DI17(sram_din_map[17]),  .DI18(sram_din_map[18]),  .DI19(sram_din_map[19]),  .DI20(sram_din_map[20]),  .DI21(sram_din_map[21]),  .DI22(sram_din_map[22]),  .DI23(sram_din_map[23]),
	.DI24(sram_din_map[24]),  .DI25(sram_din_map[25]),  .DI26(sram_din_map[26]),  .DI27(sram_din_map[27]),  .DI28(sram_din_map[28]),  .DI29(sram_din_map[29]),  .DI30(sram_din_map[30]),  .DI31(sram_din_map[31]),
	.DI32(sram_din_map[32]),  .DI33(sram_din_map[33]),  .DI34(sram_din_map[34]),  .DI35(sram_din_map[35]),  .DI36(sram_din_map[36]),  .DI37(sram_din_map[37]),  .DI38(sram_din_map[38]),  .DI39(sram_din_map[39]),
	.DI40(sram_din_map[40]),  .DI41(sram_din_map[41]),  .DI42(sram_din_map[42]),  .DI43(sram_din_map[43]),  .DI44(sram_din_map[44]),  .DI45(sram_din_map[45]),  .DI46(sram_din_map[46]),  .DI47(sram_din_map[47]),
	.DI48(sram_din_map[48]),  .DI49(sram_din_map[49]),  .DI50(sram_din_map[50]),  .DI51(sram_din_map[51]),  .DI52(sram_din_map[52]),  .DI53(sram_din_map[53]),  .DI54(sram_din_map[54]),  .DI55(sram_din_map[55]),
	.DI56(sram_din_map[56]),  .DI57(sram_din_map[57]),  .DI58(sram_din_map[58]),  .DI59(sram_din_map[59]),  .DI60(sram_din_map[60]),  .DI61(sram_din_map[61]),  .DI62(sram_din_map[62]),  .DI63(sram_din_map[63]),
	.DI64(sram_din_map[64]),  .DI65(sram_din_map[65]),  .DI66(sram_din_map[66]),  .DI67(sram_din_map[67]),  .DI68(sram_din_map[68]),  .DI69(sram_din_map[69]),  .DI70(sram_din_map[70]),  .DI71(sram_din_map[71]),
	.DI72(sram_din_map[72]),  .DI73(sram_din_map[73]),  .DI74(sram_din_map[74]),  .DI75(sram_din_map[75]),  .DI76(sram_din_map[76]),  .DI77(sram_din_map[77]),  .DI78(sram_din_map[78]),  .DI79(sram_din_map[79]),
	.DI80(sram_din_map[80]),  .DI81(sram_din_map[81]),  .DI82(sram_din_map[82]),  .DI83(sram_din_map[83]),  .DI84(sram_din_map[84]),  .DI85(sram_din_map[85]),  .DI86(sram_din_map[86]),  .DI87(sram_din_map[87]),
	.DI88(sram_din_map[88]),  .DI89(sram_din_map[89]),  .DI90(sram_din_map[90]),  .DI91(sram_din_map[91]),  .DI92(sram_din_map[92]),  .DI93(sram_din_map[93]),  .DI94(sram_din_map[94]),  .DI95(sram_din_map[95]),
	.DI96(sram_din_map[96]),  .DI97(sram_din_map[97]),  .DI98(sram_din_map[98]),  .DI99(sram_din_map[99]),  .DI100(sram_din_map[100]),.DI101(sram_din_map[101]),.DI102(sram_din_map[102]),.DI103(sram_din_map[103]),
	.DI104(sram_din_map[104]),.DI105(sram_din_map[105]),.DI106(sram_din_map[106]),.DI107(sram_din_map[107]),.DI108(sram_din_map[108]),.DI109(sram_din_map[109]),.DI110(sram_din_map[110]),.DI111(sram_din_map[111]),
	.DI112(sram_din_map[112]),.DI113(sram_din_map[113]),.DI114(sram_din_map[114]),.DI115(sram_din_map[115]),.DI116(sram_din_map[116]),.DI117(sram_din_map[117]),.DI118(sram_din_map[118]),.DI119(sram_din_map[119]),
	.DI120(sram_din_map[120]),.DI121(sram_din_map[121]),.DI122(sram_din_map[122]),.DI123(sram_din_map[123]),.DI124(sram_din_map[124]),.DI125(sram_din_map[125]),.DI126(sram_din_map[126]),.DI127(sram_din_map[127]),
	.CK(clk), .WEB(sram_wen_map), .OE(1'b1), .CS(1'b1));



SRAM_128x128 SRAM_WEIGHT_U0(
	.A0  (sram_addr_weight[0]),   .A1  (sram_addr_weight[1]),   .A2  (sram_addr_weight[2]),   .A3  (sram_addr_weight[3]),   .A4  (sram_addr_weight[4]),   .A5  (sram_addr_weight[5]),   .A6  (sram_addr_weight[6]),
	.DO0 (sram_dout_weight[0]),   .DO1 (sram_dout_weight[1]),   .DO2 (sram_dout_weight[2]),   .DO3 (sram_dout_weight[3]),   .DO4 (sram_dout_weight[4]),   .DO5 (sram_dout_weight[5]),   .DO6 (sram_dout_weight[6]),   .DO7 (sram_dout_weight[7]),
	.DO8 (sram_dout_weight[8]),   .DO9 (sram_dout_weight[9]),   .DO10(sram_dout_weight[10]),  .DO11(sram_dout_weight[11]),  .DO12(sram_dout_weight[12]),  .DO13(sram_dout_weight[13]),  .DO14(sram_dout_weight[14]),  .DO15(sram_dout_weight[15]),
	.DO16(sram_dout_weight[16]),  .DO17(sram_dout_weight[17]),  .DO18(sram_dout_weight[18]),  .DO19(sram_dout_weight[19]),  .DO20(sram_dout_weight[20]),  .DO21(sram_dout_weight[21]),  .DO22(sram_dout_weight[22]),  .DO23(sram_dout_weight[23]),
	.DO24(sram_dout_weight[24]),  .DO25(sram_dout_weight[25]),  .DO26(sram_dout_weight[26]),  .DO27(sram_dout_weight[27]),  .DO28(sram_dout_weight[28]),  .DO29(sram_dout_weight[29]),  .DO30(sram_dout_weight[30]),  .DO31(sram_dout_weight[31]),
	.DO32(sram_dout_weight[32]),  .DO33(sram_dout_weight[33]),  .DO34(sram_dout_weight[34]),  .DO35(sram_dout_weight[35]),  .DO36(sram_dout_weight[36]),  .DO37(sram_dout_weight[37]),  .DO38(sram_dout_weight[38]),  .DO39(sram_dout_weight[39]),
	.DO40(sram_dout_weight[40]),  .DO41(sram_dout_weight[41]),  .DO42(sram_dout_weight[42]),  .DO43(sram_dout_weight[43]),  .DO44(sram_dout_weight[44]),  .DO45(sram_dout_weight[45]),  .DO46(sram_dout_weight[46]),  .DO47(sram_dout_weight[47]),
	.DO48(sram_dout_weight[48]),  .DO49(sram_dout_weight[49]),  .DO50(sram_dout_weight[50]),  .DO51(sram_dout_weight[51]),  .DO52(sram_dout_weight[52]),  .DO53(sram_dout_weight[53]),  .DO54(sram_dout_weight[54]),  .DO55(sram_dout_weight[55]),
	.DO56(sram_dout_weight[56]),  .DO57(sram_dout_weight[57]),  .DO58(sram_dout_weight[58]),  .DO59(sram_dout_weight[59]),  .DO60(sram_dout_weight[60]),  .DO61(sram_dout_weight[61]),  .DO62(sram_dout_weight[62]),  .DO63(sram_dout_weight[63]),
	.DO64(sram_dout_weight[64]),  .DO65(sram_dout_weight[65]),  .DO66(sram_dout_weight[66]),  .DO67(sram_dout_weight[67]),  .DO68(sram_dout_weight[68]),  .DO69(sram_dout_weight[69]),  .DO70(sram_dout_weight[70]),  .DO71(sram_dout_weight[71]),
	.DO72(sram_dout_weight[72]),  .DO73(sram_dout_weight[73]),  .DO74(sram_dout_weight[74]),  .DO75(sram_dout_weight[75]),  .DO76(sram_dout_weight[76]),  .DO77(sram_dout_weight[77]),  .DO78(sram_dout_weight[78]),  .DO79(sram_dout_weight[79]),
	.DO80(sram_dout_weight[80]),  .DO81(sram_dout_weight[81]),  .DO82(sram_dout_weight[82]),  .DO83(sram_dout_weight[83]),  .DO84(sram_dout_weight[84]),  .DO85(sram_dout_weight[85]),  .DO86(sram_dout_weight[86]),  .DO87(sram_dout_weight[87]),
	.DO88(sram_dout_weight[88]),  .DO89(sram_dout_weight[89]),  .DO90(sram_dout_weight[90]),  .DO91(sram_dout_weight[91]),  .DO92(sram_dout_weight[92]),  .DO93(sram_dout_weight[93]),  .DO94(sram_dout_weight[94]),  .DO95(sram_dout_weight[95]),
	.DO96(sram_dout_weight[96]),  .DO97(sram_dout_weight[97]),  .DO98(sram_dout_weight[98]),  .DO99(sram_dout_weight[99]),  .DO100(sram_dout_weight[100]),.DO101(sram_dout_weight[101]),.DO102(sram_dout_weight[102]),.DO103(sram_dout_weight[103]),
	.DO104(sram_dout_weight[104]),.DO105(sram_dout_weight[105]),.DO106(sram_dout_weight[106]),.DO107(sram_dout_weight[107]),.DO108(sram_dout_weight[108]),.DO109(sram_dout_weight[109]),.DO110(sram_dout_weight[110]),.DO111(sram_dout_weight[111]),
	.DO112(sram_dout_weight[112]),.DO113(sram_dout_weight[113]),.DO114(sram_dout_weight[114]),.DO115(sram_dout_weight[115]),.DO116(sram_dout_weight[116]),.DO117(sram_dout_weight[117]),.DO118(sram_dout_weight[118]),.DO119(sram_dout_weight[119]),
	.DO120(sram_dout_weight[120]),.DO121(sram_dout_weight[121]),.DO122(sram_dout_weight[122]),.DO123(sram_dout_weight[123]),.DO124(sram_dout_weight[124]),.DO125(sram_dout_weight[125]),.DO126(sram_dout_weight[126]),.DO127(sram_dout_weight[127]),
	.DI0 (sram_din_weight[0]),   .DI1 (sram_din_weight[1]),   .DI2 (sram_din_weight[2]),   .DI3 (sram_din_weight[3]),   .DI4 (sram_din_weight[4]),   .DI5 (sram_din_weight[5]),   .DI6 (sram_din_weight[6]),   .DI7 (sram_din_weight[7]),
	.DI8 (sram_din_weight[8]),   .DI9 (sram_din_weight[9]),   .DI10(sram_din_weight[10]),  .DI11(sram_din_weight[11]),  .DI12(sram_din_weight[12]),  .DI13(sram_din_weight[13]),  .DI14(sram_din_weight[14]),  .DI15(sram_din_weight[15]),
	.DI16(sram_din_weight[16]),  .DI17(sram_din_weight[17]),  .DI18(sram_din_weight[18]),  .DI19(sram_din_weight[19]),  .DI20(sram_din_weight[20]),  .DI21(sram_din_weight[21]),  .DI22(sram_din_weight[22]),  .DI23(sram_din_weight[23]),
	.DI24(sram_din_weight[24]),  .DI25(sram_din_weight[25]),  .DI26(sram_din_weight[26]),  .DI27(sram_din_weight[27]),  .DI28(sram_din_weight[28]),  .DI29(sram_din_weight[29]),  .DI30(sram_din_weight[30]),  .DI31(sram_din_weight[31]),
	.DI32(sram_din_weight[32]),  .DI33(sram_din_weight[33]),  .DI34(sram_din_weight[34]),  .DI35(sram_din_weight[35]),  .DI36(sram_din_weight[36]),  .DI37(sram_din_weight[37]),  .DI38(sram_din_weight[38]),  .DI39(sram_din_weight[39]),
	.DI40(sram_din_weight[40]),  .DI41(sram_din_weight[41]),  .DI42(sram_din_weight[42]),  .DI43(sram_din_weight[43]),  .DI44(sram_din_weight[44]),  .DI45(sram_din_weight[45]),  .DI46(sram_din_weight[46]),  .DI47(sram_din_weight[47]),
	.DI48(sram_din_weight[48]),  .DI49(sram_din_weight[49]),  .DI50(sram_din_weight[50]),  .DI51(sram_din_weight[51]),  .DI52(sram_din_weight[52]),  .DI53(sram_din_weight[53]),  .DI54(sram_din_weight[54]),  .DI55(sram_din_weight[55]),
	.DI56(sram_din_weight[56]),  .DI57(sram_din_weight[57]),  .DI58(sram_din_weight[58]),  .DI59(sram_din_weight[59]),  .DI60(sram_din_weight[60]),  .DI61(sram_din_weight[61]),  .DI62(sram_din_weight[62]),  .DI63(sram_din_weight[63]),
	.DI64(sram_din_weight[64]),  .DI65(sram_din_weight[65]),  .DI66(sram_din_weight[66]),  .DI67(sram_din_weight[67]),  .DI68(sram_din_weight[68]),  .DI69(sram_din_weight[69]),  .DI70(sram_din_weight[70]),  .DI71(sram_din_weight[71]),
	.DI72(sram_din_weight[72]),  .DI73(sram_din_weight[73]),  .DI74(sram_din_weight[74]),  .DI75(sram_din_weight[75]),  .DI76(sram_din_weight[76]),  .DI77(sram_din_weight[77]),  .DI78(sram_din_weight[78]),  .DI79(sram_din_weight[79]),
	.DI80(sram_din_weight[80]),  .DI81(sram_din_weight[81]),  .DI82(sram_din_weight[82]),  .DI83(sram_din_weight[83]),  .DI84(sram_din_weight[84]),  .DI85(sram_din_weight[85]),  .DI86(sram_din_weight[86]),  .DI87(sram_din_weight[87]),
	.DI88(sram_din_weight[88]),  .DI89(sram_din_weight[89]),  .DI90(sram_din_weight[90]),  .DI91(sram_din_weight[91]),  .DI92(sram_din_weight[92]),  .DI93(sram_din_weight[93]),  .DI94(sram_din_weight[94]),  .DI95(sram_din_weight[95]),
	.DI96(sram_din_weight[96]),  .DI97(sram_din_weight[97]),  .DI98(sram_din_weight[98]),  .DI99(sram_din_weight[99]),  .DI100(sram_din_weight[100]),.DI101(sram_din_weight[101]),.DI102(sram_din_weight[102]),.DI103(sram_din_weight[103]),
	.DI104(sram_din_weight[104]),.DI105(sram_din_weight[105]),.DI106(sram_din_weight[106]),.DI107(sram_din_weight[107]),.DI108(sram_din_weight[108]),.DI109(sram_din_weight[109]),.DI110(sram_din_weight[110]),.DI111(sram_din_weight[111]),
	.DI112(sram_din_weight[112]),.DI113(sram_din_weight[113]),.DI114(sram_din_weight[114]),.DI115(sram_din_weight[115]),.DI116(sram_din_weight[116]),.DI117(sram_din_weight[117]),.DI118(sram_din_weight[118]),.DI119(sram_din_weight[119]),
	.DI120(sram_din_weight[120]),.DI121(sram_din_weight[121]),.DI122(sram_din_weight[122]),.DI123(sram_din_weight[123]),.DI124(sram_din_weight[124]),.DI125(sram_din_weight[125]),.DI126(sram_din_weight[126]),.DI127(sram_din_weight[127]),
	.CK(clk), .WEB(sram_wen_weight), .OE(1'b1), .CS(1'b1));


//==============================================//
//                  REGs Block                  //
//==============================================//
// map
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 64; i = i + 1) begin
			for(j = 0; j < 64; j = j + 1) begin
				map[j][i] <= 'b0;
			end 
		end
	end
	else begin
		if(state == DRAM_R) begin
			if(!cnt_dram_data[0]) begin
				for(i = 0; i < 32; i = i + 1) begin
					map[cnt_dram_data[6:1]][i] <= (|rdata_m_inf[i * 4 +: 4]) ? 2'd1 : 2'd0;           
				end
			end
			else begin
				for(i = 0; i < 32; i = i + 1) begin
					map[cnt_dram_data[6:1]][i + 32] <= (|rdata_m_inf[i * 4 +: 4]) ? 2'd1 : 2'd0;
				end  
			end
		end
		else if(state == FILL_1) begin
			for(i = 2; i < 62; i = i + 1) begin
				for(j = 2; j < 62; j = j + 1) begin
					if(map[j][i] == 2'd1 && i == sink_x_current && j == sink_y_current) begin
						map[j][i] <= 'b0;
					end
				end
			end			  
		end
		else if(state == FILL_2) begin
			for(i = 2; i < 62; i = i + 1) begin
				for(j = 2; j < 62; j = j + 1) begin
					if(map[j][i] == 2'd1 && (i == source_x_current && j == source_y_current)) begin
						map[j][i] <= {1'b1, cnt[2]};
					end
				end
			end			  
		end
		else if(state == FILLING) begin
			if(map[0][0] == 2'd0) begin
				if((map[0][1][1] | map[1][0][1])) map[0][0] <= {1'b1, cnt[2]};
			end	
			if(map[0][63] == 2'd0) begin
				if((map[0][63][1] | map[1][63][1])) map[0][63] <= {1'b1, cnt[2]};
			end		
			for(j = 1; j < 63; j = j + 1) begin
				if(map[j][0] == 2'd0) begin
					if((map[j + 1][0][1] | map[j - 1][0][1] | map[j][1][1])) map[j][0] <= {1'b1, cnt[2]};
				end
			end
			for(i = 1; i < 63; i = i + 1) begin
				if(map[0][i] == 2'd0) begin
					if((map[0][i + 1][1] | map[0][i - 1][1] | map[1][i][1])) map[0][i] <= {1'b1, cnt[2]};
				end
				for(j = 1; j < 63; j = j + 1) begin
					if(map[j][i] == 2'd0) begin
						if((map[j][i + 1][1] | map[j][i - 1][1] | map[j + 1][i][1] | map[j - 1][i][1])) map[j][i] <= {1'b1, cnt[2]};
					end
				end 
				if(map[63][i] == 2'd0) begin
					if((map[63][i + 1][1] | map[63][i - 1][1] | map[62][i][1])) map[63][i] <= {1'b1, cnt[2]};
				end
			end
			for(j = 1; j < 63; j = j + 1) begin
				if(map[j][63] == 2'd0) begin
					if((map[j + 1][63][1] | map[j - 1][63][1] | map[j][62][1])) map[j][63] <= {1'b1, cnt[2]};
				end
			end
			if(map[63][0] == 2'd0) begin
				if((map[63][1][1] | map[62][0][1])) map[63][0] <= {1'b1, cnt[2]};
			end	
			if(map[63][63] == 2'd0) begin
				if((map[62][63][1] | map[63][62][1])) map[63][63] <= {1'b1, cnt[2]};
			end	 		  
		end
		else if(state == RETRACE) begin
			map[retrace_y][retrace_x] <= 2'd1;
		end
		else if(state == CLEAN) begin
			for(i = 0; i < 64; i = i + 1) begin
				for(j = 0; j < 64; j = j + 1) begin
					if(map[j][i][1]) map[j][i] <= 'b0;
					else             map[j][i] <= map[j][i];
				end 
			end		  
		end
		else begin
			for(i = 0; i < 64; i = i + 1) begin
				for(j = 0; j < 64; j = j + 1) begin
					map[j][i] <= 'b0;
					// map[j][i] <= 2'd2;
				end 
			end		  
		end

		// case (state)
		// 	DRAM_R: begin
		// 		if(!cnt_dram_data[0]) begin
		// 			for(i = 0; i < 32; i = i + 1) begin
		// 				map[cnt_dram_data[6:1]][i] <= (|rdata_m_inf[i * 4 +: 4]) ? 2'd1 : 2'd0;           
		// 			end
		// 		end
		// 		else begin
		// 			for(i = 0; i < 32; i = i + 1) begin
		// 				map[cnt_dram_data[6:1]][i + 32] <= (|rdata_m_inf[i * 4 +: 4]) ? 2'd1 : 2'd0;
		// 			end  
		// 		end
		// 	end
		// 	FILL_1: begin
		// 		for(i = 2; i < 62; i = i + 1) begin
		// 			for(j = 2; j < 62; j = j + 1) begin
		// 				if(map[j][i] == 2'd1 & i == sink_x_reg[cnt_net] & j == sink_y_reg[cnt_net]) begin
		// 					map[j][i] <= 'b0;
		// 				end
		// 			end
		// 		end			  
		// 	end
		// 	FILL_2: begin
		// 		for(i = 2; i < 62; i = i + 1) begin
		// 			for(j = 2; j < 62; j = j + 1) begin
		// 				if(map[j][i] == 2'd1 & (i == source_x_reg[cnt_net] && j == source_y_reg[cnt_net])) begin
		// 					map[j][i] <= {1'b1, cnt[2]};
		// 				end
		// 			end
		// 		end			  
		// 	end
		// 	FILLING: begin
		// 		// for(i = 2; i < 62; i = i + 1) begin
		// 		// 	for(j = 2; j < 62; j = j + 1) begin
		// 		// 		if(map[j][i] == 2'd1) begin
		// 		// 			if (i == source_x_reg[cnt_net] && j == source_y_reg[cnt_net]) map[j][i] <= {1'b1, cnt[2]};
		// 		// 			else if(i == sink_x_reg[cnt_net] && j == sink_y_reg[cnt_net]) map[j][i] <= 'b0;
		// 		// 		end
		// 		// 	end
		// 		// end
		// 		if(map[0][0] == 2'd0) begin
		// 			if((map[0][1][1] | map[1][0][1])) map[0][0] <= {1'b1, cnt[2]};
		// 		end	
		// 		if(map[0][63] == 2'd0) begin
		// 			if((map[0][63][1] | map[1][63][1])) map[0][63] <= {1'b1, cnt[2]};
		// 		end		
		// 		for(j = 1; j < 63; j = j + 1) begin
		// 			if(map[j][0] == 2'd0) begin
		// 				if((map[j + 1][0][1] | map[j - 1][0][1] | map[j][1][1])) map[j][0] <= {1'b1, cnt[2]};
		// 			end
		// 		end
		// 		for(i = 1; i < 63; i = i + 1) begin
		// 			if(map[0][i] == 2'd0) begin
		// 				if((map[0][i + 1][1] | map[0][i - 1][1] | map[1][i][1])) map[0][i] <= {1'b1, cnt[2]};
		// 			end
		// 			for(j = 1; j < 63; j = j + 1) begin
		// 				if(map[j][i] == 2'd0) begin
		// 					if((map[j][i + 1][1] | map[j][i - 1][1] | map[j + 1][i][1] | map[j - 1][i][1])) map[j][i] <= {1'b1, cnt[2]};
		// 				end
		// 			end 
		// 			if(map[63][i] == 2'd0) begin
		// 				if((map[63][i + 1][1] | map[63][i - 1][1] | map[62][i][1])) map[63][i] <= {1'b1, cnt[2]};
		// 			end
		// 		end
		// 		for(j = 1; j < 63; j = j + 1) begin
		// 			if(map[j][63] == 2'd0) begin
		// 				if((map[j + 1][63][1] | map[j - 1][63][1] | map[j][62][1])) map[j][63] <= {1'b1, cnt[2]};
		// 			end
		// 		end
		// 		if(map[63][0] == 2'd0) begin
		// 			if((map[63][1][1] | map[62][0][1])) map[63][0] <= {1'b1, cnt[2]};
		// 		end	
		// 		if(map[63][63] == 2'd0) begin
		// 			if((map[62][63][1] | map[63][62][1])) map[63][63] <= {1'b1, cnt[2]};
		// 		end	 	
		// 	end
		// 	RETRACE: begin
		// 		if(retrace_done) begin
		// 			for(i = 0; i < 64; i = i + 1) begin
		// 				for(j = 0; j < 64; j = j + 1) begin
		// 					if(map[j][i][1]) map[j][i] <= 'b0;
		// 					else             map[j][i] <= map[j][i];
		// 				end 
		// 			end
		// 		end
		// 		else begin
		// 			map[retrace_y][retrace_x] <= 2'd1;
		// 		end
		// 	end
		// 	default: begin 
		// 		for(i = 0; i < 64; i = i + 1) begin
		// 			for(j = 0; j < 64; j = j + 1) begin
		// 				map[j][i] <= 'b0;
		// 				// map[j][i] <= 2'd2;
		// 			end 
		// 		end
		// 	end 
		// endcase
	end
end
// retrace x, y
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		retrace_x <= 'b0;
		retrace_y <= 'b0;
	end
	else begin
		if(state == RETRACE) begin
			if(~cnt[0]) begin
				if     (retrace_y != 6'd63 && map[retrace_y + 1][retrace_x] == {1'b1, ~(^cnt[2:1])}) retrace_y <= retrace_y + 1;
				else if(retrace_y != 6'd0  && map[retrace_y - 1][retrace_x] == {1'b1, ~(^cnt[2:1])}) retrace_y <= retrace_y - 1;
				else if(retrace_x != 6'd63 && map[retrace_y][retrace_x + 1] == {1'b1, ~(^cnt[2:1])}) retrace_x <= retrace_x + 1;
				else 																				 retrace_x <= retrace_x - 1;
				// else if(retrace_x != 6'd0  && map[retrace_y][retrace_x - 1] == {1'b1, ~(^cnt[2:1])}) retrace_x_next = retrace_x - 1;			  
			end
		end
		else begin
			retrace_x <= sink_x_reg[cnt_net];
			retrace_y <= sink_y_reg[cnt_net];		  
		end
		// if(state == FILLING) begin
		// 	retrace_x <= sink_x_reg[cnt_net];
		// 	retrace_y <= sink_y_reg[cnt_net];		  
		// end


		// case (state)
		// 	FILLING: begin
		// 		retrace_x <= sink_x_reg[cnt_net];
		// 		retrace_y <= sink_y_reg[cnt_net];
		// 	end
		// 	RETRACE: begin
		// 		if(~cnt[0]) begin
		// 			if     (retrace_y != 6'd63 && map[retrace_y + 1][retrace_x] == {1'b1, ~(^cnt[2:1])}) retrace_y <= retrace_y + 1;
		// 			else if(retrace_y != 6'd0  && map[retrace_y - 1][retrace_x] == {1'b1, ~(^cnt[2:1])}) retrace_y <= retrace_y - 1;
		// 			else if(retrace_x != 6'd63 && map[retrace_y][retrace_x + 1] == {1'b1, ~(^cnt[2:1])}) retrace_x <= retrace_x + 1;
		// 			else 																				 retrace_x <= retrace_x - 1;
		// 			// else if(retrace_x != 6'd0  && map[retrace_y][retrace_x - 1] == {1'b1, ~(^cnt[2:1])}) retrace_x_next = retrace_x - 1;			  
		// 		end
		// 	end
		// 	default: begin end
		// endcase	  
	end
end
// cost
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) cost_reg <= 'b0;
	else begin
		case (state)
			DRAM_R: begin
				cost_reg <= 'b0;
			end
			RETRACE: begin
				if(~cnt[0]) cost_reg <= cost_reg + weight_data[retrace_x[4:0]]; 
				else        cost_reg <= cost_reg;
			end
			default: begin end
		endcase 
	end
end
// current source & sink
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		source_x_current <= 'b0;
		source_y_current <= 'b0;
		sink_x_current <= 'b0;
		sink_y_current <= 'b0;
	end
	else begin
		if(state == DRAM_R || state == CLEAN) begin
			source_x_current <= source_x_reg[cnt_net];
			source_y_current <= source_y_reg[cnt_net];
			sink_x_current <= sink_x_reg[cnt_net];
			sink_y_current <= sink_y_reg[cnt_net];			  
		end
	end
end
//==============================================//
//                Output Block                  //
//==============================================//
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) busy <= 'b0;
	else begin
		if(state_next !== IDLE && !in_valid) busy <= 1;
		else                                 busy <= 0;
	end     
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) cost <= 'b0;
	else  begin
		cost <= cost_reg;
		// if(state == IDLE) cost <= 'b0;
		// else              cost <= cost_reg;
	end     
end
endmodule



