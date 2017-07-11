`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 16:47:10
// Design Name: 
// Module Name: EX_MEM
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

module EX_MEM(
	input wire clk,
	input wire rst,
	input wire [4:0] ex_wd,
	input wire ex_wreg,
	input wire [31:0] ex_wdata,
	
	input wire ex_whilo,
	input wire [31:0] ex_hi,
	input wire [31:0] ex_lo,
	
	input wire [7:0] ex_aluop,
	input wire [31:0] ex_mem_addr,
	input wire [31:0] ex_reg2,

	input wire ex_cp0_reg_we,
	input wire [4:0] ex_cp0_reg_write_addr,
	input wire [31:0] ex_cp0_reg_data,

	output reg mem_cp0_reg_we,
	output reg [4:0] mem_cp0_reg_write_addr,
	output reg [31:0] mem_cp0_reg_data,
	
	output reg [4:0] mem_wd,
	output reg mem_wreg,
	output reg [31:0] mem_wdata,
	
	output reg mem_whilo,
	output reg [31:0] mem_hi,
	output reg [31:0] mem_lo,
	
	output reg [7:0] mem_aluop,
	output reg [31:0] mem_mem_addr,
	output reg [31:0] mem_reg2,
	
	input wire [5:0] stall,
	
	input wire flush,
	
	input wire [`EXC_CODE_WIDTH-1:0]exc_code_i,
	input wire [31:0] exc_epc_i,
	input wire [31:0] exc_badvaddr_i,
	
	output reg [`EXC_CODE_WIDTH-1:0] exc_code_o,
	output reg [31:0] exc_epc_o,
	output reg [31:0] exc_badvaddr_o,
	
	input wire ex_in_delay,
	output reg mem_in_delay,
	input wire [31:0] ex_pc,
	output reg [31:0] mem_pc
    );

	always @(posedge clk or negedge rst) begin
		if (rst == `RstEnable || flush) begin
			mem_wd <= 5'b0;
			mem_wreg <= 1'b0;
			mem_wdata <= 32'b0;
			mem_whilo <= 1'b0;
			mem_hi <= 32'b0;
			mem_lo <= 32'b0;
			mem_aluop <= `SLL;
			mem_mem_addr <= 32'b0;
			mem_reg2 <= 32'b0;
			mem_cp0_reg_we <= 1'b0;
			mem_cp0_reg_write_addr <= 5'b0;
			mem_cp0_reg_data <= 32'b0;
			mem_in_delay <= 1'b0;
			mem_pc <= `ZeroWord;
			
			exc_code_o <= `EC_None;
			exc_epc_o <= `ZeroWord;
			exc_badvaddr_o <= `ZeroWord;
		end
		else if (stall[3] == `Stop && stall[4] == `NoStop) begin
			mem_wd <= 5'b0;
			mem_wreg <= 1'b0;
			mem_wdata <= 32'b0;
			mem_whilo <= 1'b0;
			mem_hi <= 32'b0;
			mem_lo <= 32'b0;
			mem_aluop <= `SLL;
			mem_mem_addr <= 32'b0;
			mem_reg2 <= 32'b0;
			mem_cp0_reg_we <= 1'b0;
			mem_cp0_reg_write_addr <= 5'b0;
			mem_cp0_reg_data <= 32'b0;
			mem_in_delay <= 1'b0;
			mem_pc <= `ZeroWord;
			
			exc_code_o <= `EC_None;
			exc_epc_o <= `ZeroWord;
			exc_badvaddr_o <= `ZeroWord;
		end
		else if (stall[3] == `NoStop) begin
			mem_wd <= ex_wd;
			mem_wreg <= ex_wreg;
			mem_wdata <= ex_wdata;
			mem_whilo <= ex_whilo;
			mem_hi <= ex_hi;
			mem_lo <= ex_lo;
			mem_aluop <= ex_aluop;
			mem_mem_addr <= ex_mem_addr;
			mem_reg2 <= ex_reg2;
			mem_cp0_reg_we <= ex_cp0_reg_we;
			mem_cp0_reg_write_addr <= ex_cp0_reg_write_addr;
			mem_cp0_reg_data <= ex_cp0_reg_data;
			mem_in_delay <= ex_in_delay;
			mem_pc <= ex_pc;
			
			exc_code_o <= exc_code_i;
			exc_epc_o <= exc_epc_i;
			exc_badvaddr_o <= exc_badvaddr_i;
		end
	end
	
endmodule