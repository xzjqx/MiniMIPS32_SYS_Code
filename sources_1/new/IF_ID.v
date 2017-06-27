`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 16:18:02
// Design Name: 
// Module Name: IF_ID
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "defines.v"

module IF_ID(
	input wire clk,
	input wire rst,
	input wire [31:0] if_pc,
	input wire [31:0] if_inst,
	
	input wire [5:0] stall,
	
	output reg [31:0] id_pc,
	output reg [31:0] id_inst,
	
	input wire flush,
	
	input wire [`EXC_CODE_WIDTH-1:0] exc_code_i,
	input wire [31:0] exc_badvaddr_i,
	output reg [`EXC_CODE_WIDTH-1:0] exc_code_o,
	output reg [31:0] exc_badvaddr_o
    );

	always @(posedge clk or negedge rst) begin
		if (rst == `RstEnable || flush == 1'b1) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
			exc_code_o <= `EC_None;
			exc_badvaddr_o <= `ZeroWord;
		end
		else if (stall[1] == `Stop && stall[2] == `NoStop) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
			exc_code_o <= `EC_None;
			exc_badvaddr_o <= `ZeroWord;
		end
		else if (stall[2] == `NoStop) begin
			id_pc <= if_pc;
			id_inst <= if_inst;
			exc_code_o <= exc_code_i;
			exc_badvaddr_o <= exc_badvaddr_i;
		end
	end
	
endmodule

