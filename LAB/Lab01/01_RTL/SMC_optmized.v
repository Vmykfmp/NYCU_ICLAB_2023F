//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab01 Exercise		: Supper MOSFET Calculator
//   Author     		: Tse-Chun Hsu
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SMC.v
//   Module Name : SMC
//   Release version : V1.0 (Release Date: 2023-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


module SMC(
  // Input signals
    mode,
    W_0, V_GS_0, V_DS_0,
    W_1, V_GS_1, V_DS_1,
    W_2, V_GS_2, V_DS_2,
    W_3, V_GS_3, V_DS_3,
    W_4, V_GS_4, V_DS_4,
    W_5, V_GS_5, V_DS_5,   
  // Output signals
    out_n
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [2:0] W_0, V_GS_0, V_DS_0;
input [2:0] W_1, V_GS_1, V_DS_1;
input [2:0] W_2, V_GS_2, V_DS_2;
input [2:0] W_3, V_GS_3, V_DS_3;
input [2:0] W_4, V_GS_4, V_DS_4;
input [2:0] W_5, V_GS_5, V_DS_5;
input [1:0] mode;
//output [7:0] out_n;         					// use this if using continuous assignment for out_n  // Ex: assign out_n = XXX;
output reg [7:0] out_n; 								// use this if using procedure assignment for out_n   // Ex: always@(*) begin out_n = XXX; end

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment
wire [2:0] W [0:5];
wire [2:0] V_GS [0:5];
wire [2:0] V_DS [0:5];
wire [2:0] V_DSS [0:5]; // V_DSS = V_GS - V_th

reg [7:0] cal [0:5];
reg [3:0] cal_mul_0 [0:5];
reg [3:0] cal_mul_1 [0:5];

reg [2:0] i, j;
reg [2:0] l, r;
reg [7:0] sort [0:2];
reg [2:0] order [0:5];

// reg [9:0] out_num [0:2];
reg [9:0] out_num [0:4];
reg [2:0] out_mul [0:2];
reg [1:0] out_shf;
//================================================================
//    DESIGN
//================================================================

// --------------------------------------------------
// write your design here
// --------------------------------------------------

/*Calculate Id or gm*/
// assign W[0] = W_0;
// assign W[1] = W_1;
// assign W[2] = W_2;
// assign W[3] = W_3;
// assign W[4] = W_4;
// assign W[5] = W_5;

// assign V_GS[0] = V_GS_0;
// assign V_GS[1] = V_GS_1;
// assign V_GS[2] = V_GS_2;
// assign V_GS[3] = V_GS_3;
// assign V_GS[4] = V_GS_4;
// assign V_GS[5] = V_GS_5;

// assign V_DS[0] = V_DS_0;
// assign V_DS[1] = V_DS_1;
// assign V_DS[2] = V_DS_2;
// assign V_DS[3] = V_DS_3;
// assign V_DS[4] = V_DS_4;
// assign V_DS[5] = V_DS_5;

// assign V_DSS[0] = V_GS_0 - 1;
// assign V_DSS[1] = V_GS_1 - 1;
// assign V_DSS[2] = V_GS_2 - 1;
// assign V_DSS[3] = V_GS_3 - 1;
// assign V_DSS[4] = V_GS_4 - 1;
// assign V_DSS[5] = V_GS_5 - 1;

Calculator cal_0(mode, V_GS_0, V_DS_0, W_0, cal[0]);
Calculator cal_1(mode, V_GS_1, V_DS_1, W_1, cal[1]);
Calculator cal_2(mode, V_GS_2, V_DS_2, W_2, cal[2]);
Calculator cal_3(mode, V_GS_3, V_DS_3, W_3, cal[3]);
Calculator cal_4(mode, V_GS_4, V_DS_4, W_4, cal[4]);
Calculator cal_5(mode, V_GS_5, V_DS_5, W_5, cal[5]);

// always@* begin
//   for(i = 0; i < 6; i = i + 1) begin
//     if((V_DSS[i]) > V_DS[i]) begin // 
//       cal_mul_0[i] = V_DS[i];
//       if(mode[0]) cal_mul_1[i] = (V_DSS[i] << 1) - V_DS[i];
//       else        cal_mul_1[i] = 4'd2;
//     end
//     else begin
//       cal_mul_0[i] = V_DSS[i];
//       if(mode[0]) cal_mul_1[i] = V_DSS[i];
//       else        cal_mul_1[i] = 4'd2;
//     end
//     cal[i] = (W[i] * cal_mul_0[i] * cal_mul_1[i]);
//   end
// end
/*Sort*/
always @* begin
  for(i = 0; i < 6; i = i + 1) begin
    if(mode[1]) order[i] = 0;
    else        order[i] = -3;
  end

  for(i = 0; i < 6; i = i + 1) begin
    for(j = i + 1; j < 6; j = j + 1) begin
      if(cal[i] > cal[j]) order[j] = order[j] + 1;
      else                order[i] = order[i] + 1;
    end    
  end

  for(i = 0; i < 3; i = i + 1) begin
    case(i)
      order[0]: sort[i] = cal[0];
      order[1]: sort[i] = cal[1];
      order[2]: sort[i] = cal[2];
      order[3]: sort[i] = cal[3];
      order[4]: sort[i] = cal[4];
      default:  sort[i] = cal[5]; //order[5]: sort[i] = cal[5];
    endcase
    out_num[i] = sort[i] / 2'd3;
  end
end
/*Select according to mode*/
always @* begin
  if(mode[0]) begin
    out_num[3] = out_num[0];
    out_num[4] = out_num[2];
  end
  else begin
    out_num[3] = 0;
    out_num[4] = 0;
  end
end
/*Output*/
always @* begin
  out_n = ((((out_num[0] + out_num[1] + out_num[2]) << 2'd2) -  out_num[3] +  out_num[4]) >> 2'd2) / 2'd3;
end
endmodule

module Calculator(mode, V_GS, V_DS, W, out);
	input [1:0] mode;
	input [2:0] V_GS, V_DS, W;
	output reg [7:0] out;

	reg [5:0] cal_result;

	always @* begin
		// MUX for caculation of Id or gm (not divide by 3 and multiply by W)
		// same result of below
		/*
		V_GS_TH = V_GS - 1;
		
		if (V_GS_TH > V_DS) begin
			if (mode[0])
				multi_1 = 2 * V_GS_TH - V_DS;
			else
				multi_1 = 2;
			multi_2 = V_DS;
    	end
		else begin
			if (mode[0])
				multi_1 = V_GS_TH;
			else
				multi_1 = 2;
			multi_2 = V_GS_TH;
		end
		
		cal_result = multi_1 * multi_2;
		*/

		case({mode[0], V_GS, V_DS})
			// I_D
			{1'b1, 3'd1, 3'd1}: cal_result = 0;  // 0*0
			{1'b1, 3'd2, 3'd1}: cal_result = 1;  // 1*1
			{1'b1, 3'd3, 3'd1}: cal_result = 3;  // 1*(2*2-1)
			{1'b1, 3'd4, 3'd1}: cal_result = 5;  // 1*(2*3-1)
			{1'b1, 3'd5, 3'd1}: cal_result = 7;  // 1*(2*4-1)
			{1'b1, 3'd6, 3'd1}: cal_result = 9;  // 1*(2*5-1)
			{1'b1, 3'd7, 3'd1}: cal_result = 11; // 1*(2*6-1)
			{1'b1, 3'd1, 3'd2}: cal_result = 0;  // 0*0
			{1'b1, 3'd2, 3'd2}: cal_result = 1;  // 1*1
			{1'b1, 3'd3, 3'd2}: cal_result = 4;  // 2*2
			{1'b1, 3'd4, 3'd2}: cal_result = 8;  // 2*(2*3-2)
			{1'b1, 3'd5, 3'd2}: cal_result = 12; // 2*(2*4-2)
			{1'b1, 3'd6, 3'd2}: cal_result = 16; // 2*(2*5-2)
			{1'b1, 3'd7, 3'd2}: cal_result = 20; // 2*(2*6-2)
			{1'b1, 3'd1, 3'd3}: cal_result = 0;  // 0*0
			{1'b1, 3'd2, 3'd3}: cal_result = 1;  // 1*1
			{1'b1, 3'd3, 3'd3}: cal_result = 4;  // 2*2
			{1'b1, 3'd4, 3'd3}: cal_result = 9;  // 3*3
			{1'b1, 3'd5, 3'd3}: cal_result = 15; // 3*(2*4-3)
			{1'b1, 3'd6, 3'd3}: cal_result = 21; // 3*(2*5-3)
			{1'b1, 3'd7, 3'd3}: cal_result = 27; // 3*(2*6-3)
			{1'b1, 3'd1, 3'd4}: cal_result = 0;  // 0*0
			{1'b1, 3'd2, 3'd4}: cal_result = 1;  // 1*1
			{1'b1, 3'd3, 3'd4}: cal_result = 4;  // 2*2
			{1'b1, 3'd4, 3'd4}: cal_result = 9;  // 3*3
			{1'b1, 3'd5, 3'd4}: cal_result = 16; // 4*4
			{1'b1, 3'd6, 3'd4}: cal_result = 24; // 4*(2*5-4)
			{1'b1, 3'd7, 3'd4}: cal_result = 32; // 4*(2*6-4)
			{1'b1, 3'd1, 3'd5}: cal_result = 0;  // 0*0
			{1'b1, 3'd2, 3'd5}: cal_result = 1;  // 1*1
			{1'b1, 3'd3, 3'd5}: cal_result = 4;  // 2*2
			{1'b1, 3'd4, 3'd5}: cal_result = 9;  // 3*3
			{1'b1, 3'd5, 3'd5}: cal_result = 16; // 4*4
			{1'b1, 3'd6, 3'd5}: cal_result = 25; // 5*5
			{1'b1, 3'd7, 3'd5}: cal_result = 35; // 5*(2*6-5)
			{1'b1, 3'd1, 3'd6}: cal_result = 0;  // 0*0
			{1'b1, 3'd2, 3'd6}: cal_result = 1;  // 1*1
			{1'b1, 3'd3, 3'd6}: cal_result = 4;  // 2*2
			{1'b1, 3'd4, 3'd6}: cal_result = 9;  // 3*3
			{1'b1, 3'd5, 3'd6}: cal_result = 16; // 4*4
			{1'b1, 3'd6, 3'd6}: cal_result = 25; // 5*5
			{1'b1, 3'd7, 3'd6}: cal_result = 36; // 6*6
			{1'b1, 3'd1, 3'd7}: cal_result = 0;  // 0*0
			{1'b1, 3'd2, 3'd7}: cal_result = 1;  // 1*1
			{1'b1, 3'd3, 3'd7}: cal_result = 4;  // 2*2
			{1'b1, 3'd4, 3'd7}: cal_result = 9;  // 3*3
			{1'b1, 3'd5, 3'd7}: cal_result = 16; // 4*4
			{1'b1, 3'd6, 3'd7}: cal_result = 25; // 5*5
			{1'b1, 3'd7, 3'd7}: cal_result = 36; // 6*6
			// g_m
			{1'b0, 3'd1, 3'd1}: cal_result = 0;  // 2*0
			{1'b0, 3'd2, 3'd1}: cal_result = 2;  // 2*1
			{1'b0, 3'd3, 3'd1}: cal_result = 2;  // 2*1
			{1'b0, 3'd4, 3'd1}: cal_result = 2;  // 2*1
			{1'b0, 3'd5, 3'd1}: cal_result = 2;  // 2*1
			{1'b0, 3'd6, 3'd1}: cal_result = 2;  // 2*1
			{1'b0, 3'd7, 3'd1}: cal_result = 2;  // 2*1
			{1'b0, 3'd1, 3'd2}: cal_result = 0;  // 2*0
			{1'b0, 3'd2, 3'd2}: cal_result = 2;  // 2*1
			{1'b0, 3'd3, 3'd2}: cal_result = 4;  // 2*2
			{1'b0, 3'd4, 3'd2}: cal_result = 4;  // 2*2
			{1'b0, 3'd5, 3'd2}: cal_result = 4;  // 2*2
			{1'b0, 3'd6, 3'd2}: cal_result = 4;  // 2*2
			{1'b0, 3'd7, 3'd2}: cal_result = 4;  // 2*2
			{1'b0, 3'd1, 3'd3}: cal_result = 0;  // 2*0
			{1'b0, 3'd2, 3'd3}: cal_result = 2;  // 2*1
			{1'b0, 3'd3, 3'd3}: cal_result = 4;  // 2*2
			{1'b0, 3'd4, 3'd3}: cal_result = 6;  // 2*3
			{1'b0, 3'd5, 3'd3}: cal_result = 6;  // 2*3
			{1'b0, 3'd6, 3'd3}: cal_result = 6;  // 2*3
			{1'b0, 3'd7, 3'd3}: cal_result = 6;  // 2*3
			{1'b0, 3'd1, 3'd4}: cal_result = 0;  // 2*0
			{1'b0, 3'd2, 3'd4}: cal_result = 2;  // 2*1
			{1'b0, 3'd3, 3'd4}: cal_result = 4;  // 2*2
			{1'b0, 3'd4, 3'd4}: cal_result = 6;  // 2*3
			{1'b0, 3'd5, 3'd4}: cal_result = 8;  // 2*4
			{1'b0, 3'd6, 3'd4}: cal_result = 8;  // 2*4
			{1'b0, 3'd7, 3'd4}: cal_result = 8;  // 2*4
			{1'b0, 3'd1, 3'd5}: cal_result = 0;  // 2*0
			{1'b0, 3'd2, 3'd5}: cal_result = 2;  // 2*1
			{1'b0, 3'd3, 3'd5}: cal_result = 4;  // 2*2
			{1'b0, 3'd4, 3'd5}: cal_result = 6;  // 2*3
			{1'b0, 3'd5, 3'd5}: cal_result = 8;  // 2*4
			{1'b0, 3'd6, 3'd5}: cal_result = 10; // 2*5
			{1'b0, 3'd7, 3'd5}: cal_result = 10; // 2*5
			{1'b0, 3'd1, 3'd6}: cal_result = 0;  // 2*0
			{1'b0, 3'd2, 3'd6}: cal_result = 2;  // 2*1
			{1'b0, 3'd3, 3'd6}: cal_result = 4;  // 2*2
			{1'b0, 3'd4, 3'd6}: cal_result = 6;  // 2*3
			{1'b0, 3'd5, 3'd6}: cal_result = 8;  // 2*4
			{1'b0, 3'd6, 3'd6}: cal_result = 10; // 2*5
			{1'b0, 3'd7, 3'd6}: cal_result = 12; // 2*6
			{1'b0, 3'd1, 3'd7}: cal_result = 0;  // 2*0
			{1'b0, 3'd2, 3'd7}: cal_result = 2;  // 2*1
			{1'b0, 3'd3, 3'd7}: cal_result = 4;  // 2*2
			{1'b0, 3'd4, 3'd7}: cal_result = 6;  // 2*3
			{1'b0, 3'd5, 3'd7}: cal_result = 8;  // 2*4
			{1'b0, 3'd6, 3'd7}: cal_result = 10; // 2*5
			{1'b0, 3'd7, 3'd7}: cal_result = 12; // 2*6
			default: cal_result = 5'bxxxxx; // don't care
		endcase

		// multiply MUX's result by W
		out = W * cal_result;
	end
endmodule

//================================================================
//   SUB MODULE
//================================================================

// module BBQ (meat,vagetable,water,cost);
// input XXX;
// output XXX;
// 
// endmodule

// --------------------------------------------------
// Example for using submodule 
// BBQ bbq0(.meat(meat_0), .vagetable(vagetable_0), .water(water_0),.cost(cost[0]));
// --------------------------------------------------
// Example for continuous assignment
// assign out_n = XXX;
// --------------------------------------------------
// Example for procedure assignment
// always@(*) begin 
// 	out_n = XXX; 
// end
// --------------------------------------------------
// Example for case statement
// always @(*) begin
// 	case(op)
// 		2'b00: output_reg = a + b;
// 		2'b10: output_reg = a - b;
// 		2'b01: output_reg = a * b;
// 		2'b11: output_reg = a / b;
// 		default: output_reg = 0;
// 	endcase
// end
// --------------------------------------------------
