`ifdef RTL
`define CYCLE_TIME 15.0
`endif
`ifdef GATE
`define CYCLE_TIME 15.0
`endif

`ifdef SAMPLE
// write your configuration here

`endif
`ifdef FUNC
// write your configuration here

`endif


`include "../00_TESTBED/MEM_MAP_define.v"
`include "../00_TESTBED/pseudo_DRAM.vp"


module PATTERN #(parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32)(
	// CHIP IO 
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost			,
	busy         	,

	// AXI4 IO
         awid_s_inf,
       awaddr_s_inf,
       awsize_s_inf,
      awburst_s_inf,
        awlen_s_inf,
      awvalid_s_inf,
      awready_s_inf,
                    
        wdata_s_inf,
        wlast_s_inf,
       wvalid_s_inf,
       wready_s_inf,
                    
          bid_s_inf,
        bresp_s_inf,
       bvalid_s_inf,
       bready_s_inf,
                    
         arid_s_inf,
       araddr_s_inf,
        arlen_s_inf,
       arsize_s_inf,
      arburst_s_inf,
      arvalid_s_inf,
                    
      arready_s_inf, 
          rid_s_inf,
        rdata_s_inf,
        rresp_s_inf,
        rlast_s_inf,
       rvalid_s_inf,
       rready_s_inf 
             );

// ===============================================================
//  					Input / Output 
// ===============================================================

// << CHIP io port with system >>
output reg			  	clk,rst_n;
output reg			   	in_valid;
output reg [4:0] 		frame_id;
output reg [3:0]       	net_id;     
output reg [5:0]       	loc_x; 
output reg [5:0]       	loc_y; 
input [13:0]			cost;
input                   busy;       
 
// << AXI Interface wire connecttion for pseudo DRAM read/write >>
// (1) 	axi write address channel 
// 		src master
input wire [ID_WIDTH-1:0]      awid_s_inf;
input wire [ADDR_WIDTH-1:0]  awaddr_s_inf;
input wire [2:0]             awsize_s_inf;
input wire [1:0]            awburst_s_inf;
input wire [7:0]              awlen_s_inf;
input wire                  awvalid_s_inf;
// 		src slave
output wire                 awready_s_inf;
// -----------------------------

// (2)	axi write data channel 
// 		src master
input wire [DATA_WIDTH-1:0]   wdata_s_inf;
input wire                    wlast_s_inf;
input wire                   wvalid_s_inf;
// 		src slave
output wire                  wready_s_inf;

// (3)	axi write response channel 
// 		src slave
output wire  [ID_WIDTH-1:0]     bid_s_inf;
output wire  [1:0]            bresp_s_inf;
output wire                  bvalid_s_inf;
// 		src master 
input wire                   bready_s_inf;
// -----------------------------

// (4)	axi read address channel 
// 		src master
input wire [ID_WIDTH-1:0]      arid_s_inf;
input wire [ADDR_WIDTH-1:0]  araddr_s_inf;
input wire [7:0]              arlen_s_inf;
input wire [2:0]             arsize_s_inf;
input wire [1:0]            arburst_s_inf;
input wire                  arvalid_s_inf;
// 		src slave
output wire                 arready_s_inf;
// -----------------------------

// (5)	axi read data channel 
// 		src slave
output wire [ID_WIDTH-1:0]      rid_s_inf;
output wire [DATA_WIDTH-1:0]  rdata_s_inf;
output wire [1:0]             rresp_s_inf;
output wire                   rlast_s_inf;
output wire                  rvalid_s_inf;
// 		src master
input wire                   rready_s_inf;

// ===============================================================
//  					Your code start here
// ===============================================================




endmodule

