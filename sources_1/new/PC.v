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
	
	input wire break_flag,
	input wire [31:0] break_addr,
	input wire stop_flag,
	
	output reg has_break,
	output reg stop_o,
	
	output reg ce
    );

	wire[31:0] pc_next;
	assign pc_next = (branch_flag_i == 1'b1) ? branch_target_address_i : pc + 4'h4;

	always @(posedge clk or negedge rst) begin
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
	
	always @ (*) begin
		has_break <= 0;
		stop_o <= 0;
		if (break_flag) begin
			/*if (pc_break_index == 2'b00 && pc[7:0] == pc_break_addr)
				stop_o <= 1;
			if (pc_break_index == 2'b01 && pc[15:8] == pc_break_addr)
				stop_o <= 1;
			if (pc_break_index == 2'b10 && pc[23:16] == pc_break_addr)
				stop_o <= 1;
			if (pc_break_index == 2'b11 && pc[31:24] == pc_break_addr)
				stop_o <= 1;*/
		end
		else if (stop_flag) begin
			has_break <= 1;
			stop_o <= 1;
		end
	end

endmodule

