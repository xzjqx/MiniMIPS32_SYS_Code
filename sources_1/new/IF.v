`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/22 14:20:29
// Design Name: 
// Module Name: IF
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

module IF(
	input wire[31:0] addr_i,
	input wire rst,
	
	output reg[31:0] inst_addr_o,
	output reg[31:0] addr_o,
	output reg[4:0] exc_code_o,
	output reg[31:0] exc_badvaddr_o,
	
	input wire ce_i,
	output wire ce_o
);
	assign ce_o = ce_i;
	wire wordAlignedFlag = addr_i[1:0] == 2'b00;
	always @ (*) begin
		if (ce_i == `ChipDisable) begin
			addr_o <= `ZeroWord;
			inst_addr_o <= `ZeroWord;
			exc_badvaddr_o <= `ZeroWord;
			exc_code_o <= `EC_None;
		end else begin 
			addr_o <= addr_i;
			inst_addr_o <= {3'b0,addr_i[28:0]};
			if(!wordAlignedFlag) begin
				exc_badvaddr_o = addr_i;
				exc_code_o = `EC_AdEL;
			end
			else begin
				exc_badvaddr_o = `ZeroWord;
				exc_code_o <= `EC_None;
			end
		end
	end
	
endmodule