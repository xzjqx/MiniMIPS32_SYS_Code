`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 16:44:12
// Design Name: 
// Module Name: ID_EX
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

module ID_EX(
	input wire clk,
	input wire rst,
	input wire [2:0] id_alusel,
	input wire [7:0] id_aluop,
	input wire [31:0] id_reg1,
	input wire [31:0] id_reg2,
	input wire [4:0] id_wd,
	input wire id_wreg,
	
	input wire id_is_in_delayslot,
	input wire [31:0] id_link_address,
	input wire next_inst_in_delayslot_i,
	
	input wire [31:0] id_inst,
	input wire [31:0] id_pc,
	
	output reg [2:0] ex_alusel,
	output reg [7:0] ex_aluop,
	output reg [31:0] ex_reg1,
	output reg [31:0] ex_reg2,
	output reg [4:0] ex_wd,
	output reg ex_wreg,
	
	output reg ex_is_in_delayslot,
	output reg [31:0] ex_link_address,
	output reg is_in_delayslot_o,
	
	output reg [31:0] ex_inst,
	output reg [31:0] ex_pc,
	
	input wire [5:0] stall,
	
	input wire flush,
	
	input wire [`EXC_CODE_WIDTH-1:0] exc_code_i,
	input wire [31:0] exc_epc_i,
	input wire [31:0] exc_badvaddr_i,
	
	output reg [`EXC_CODE_WIDTH-1:0] exc_code_o,
	output reg [31:0] exc_epc_o,
	output reg [31:0] exc_badvaddr_o
    );

	always @(posedge clk or negedge rst) begin
		if (rst == `RstEnable || flush == 1'b1) begin
			ex_alusel <= 3'b0;
			ex_aluop <= `SLL;
			ex_reg1 <= 32'b0;
			ex_reg2 <= 32'b0;
			ex_wd <= 5'b0;
			ex_wreg <= 1'b0;
			ex_is_in_delayslot <= 1'b0;
			ex_link_address <= 1'b0;
			is_in_delayslot_o <= 1'b0;
			ex_inst <= `ZeroWord;
			ex_pc <= `ZeroWord;
			exc_code_o <= `EC_None;
			exc_epc_o <= `ZeroWord;
			exc_badvaddr_o <= `ZeroWord;
		end
		else if (stall[2] == `Stop && stall[3] == `NoStop) begin
			ex_alusel <= 3'b0;
			ex_aluop <= `SLL;
			ex_reg1 <= 32'b0;
			ex_reg2 <= 32'b0;
			ex_wd <= 5'b0;
			ex_wreg <= 1'b0;
			ex_is_in_delayslot <= 1'b0;
			ex_link_address <= 1'b0;
			ex_inst <= 32'b0;
			ex_pc <= `ZeroWord;
			exc_code_o <= `EC_None;
			exc_epc_o <= `ZeroWord;
			exc_badvaddr_o <= `ZeroWord;
		end
		else if (stall[2] == `NoStop) begin
			ex_alusel <= id_alusel;
			ex_aluop <= id_aluop;
			ex_reg1 <= id_reg1;
			ex_reg2 <= id_reg2;
			ex_wd <= id_wd;
			ex_wreg <= id_wreg;
			ex_is_in_delayslot <= id_is_in_delayslot;
			ex_link_address <= id_link_address;
			is_in_delayslot_o <= next_inst_in_delayslot_i;
			ex_inst <= id_inst;
			ex_pc <= id_pc;
			exc_code_o <= exc_code_i;
			exc_epc_o <= exc_epc_i;
			exc_badvaddr_o <= exc_badvaddr_i;
		end
	end

endmodule