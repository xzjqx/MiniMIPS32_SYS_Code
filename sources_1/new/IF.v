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
	input  wire [`InstAddrBus] 	if_addr_i,
	input  wire 	     		cpu_rst_n,
	
	output wire [`InstAddrBus] 	if_inst_addr_o,
	output wire [`InstAddrBus] 	if_addr_o,
	output wire [`ExcCode    ] 	if_exc_code_o,
	output wire [`InstAddrBus] 	if_exc_badvaddr_o,
	
	input  wire      			if_ce_i,
	output wire 	 			if_ce_o
);
	assign if_ce_o       = if_ce_i;
	wire wordAlignedFlag = if_addr_i[1:0] == 2'b00;

	assign if_addr_o 			= (if_ce_i == `ChipDisable) ? `ZeroWord : if_addr_i;

	assign if_inst_addr_o 		= (if_ce_i == `ChipDisable) ? `ZeroWord : {3'b0,if_addr_i[28:0]};

	assign if_exc_badvaddr_o 	= (if_ce_i == `ChipDisable) ? `ZeroWord : 
							  	  (!wordAlignedFlag) 	    ? if_addr_i	: `ZeroWord;

	assign if_exc_code_o 		= (if_ce_i == `ChipDisable) ? `EC_None  : 
							  	  (!wordAlignedFlag) 	 	? `EC_AdEL  : `EC_None;

endmodule