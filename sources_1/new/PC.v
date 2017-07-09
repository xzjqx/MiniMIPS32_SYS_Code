`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/22 12:57:16
// Design Name: 
// Module Name: PC
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

module PC(
	input wire clk,
	input wire rst,
	
	input wire branch_flag_i,
	input wire [31:0] branch_target_address_i,
	
	input wire [5:0] stall,
	
	output reg [31:0] pc,
	
	input wire cp0_branch_flag,
	input wire[31:0] cp0_branch_addr,
	
	output reg ce
    );

	wire[31:0] pc_next;
	assign pc_next = (branch_flag_i == 1'b1) ? branch_target_address_i : pc + 4'h4;

	always @(posedge clk) begin
		if (ce == `ChipDisable)
			pc <= 32'hBFC00000;			
		else if (cp0_branch_flag == `Branch)
			pc <= cp0_branch_addr;
		else if (stall[0] == `NoStop)
			pc <= pc_next;
	end
	
	always @(posedge clk) begin
		if (rst == `RstEnable) begin
			ce <= `ChipDisable;
		end else begin
			ce <= `ChipEnable;
		end
	end

endmodule

