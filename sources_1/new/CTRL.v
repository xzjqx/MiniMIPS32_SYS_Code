`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 17:21:43
// Design Name: 
// Module Name: CTRL
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

module CTRL(
	input wire clk,
	input wire rst,
	input wire stop_from_id,
	input wire stop_from_ex,
	input wire stop_from_mem, 
	input wire stop_from_pc,
	input wire stop_from_if,
	input wire flush_i, 
	output reg[5:0] stall,
	output reg flush_o
    );

	reg flush_delay;
	
	always @ (posedge clk or negedge rst) begin
		if (rst == `RstEnable) begin
			flush_delay <= 1'b0;
		end else begin
			flush_delay <= flush_i;
		end
	
	end

	always @ (*) begin
		if (rst == `RstEnable) begin
			stall <= 6'b000000;
			flush_o<=0;
		end else if (flush_i || flush_delay) begin
			stall <= 6'b000000;
			flush_o<=1;
		end else if (stop_from_pc == `Stop) begin
			stall <= 6'b111111;
			flush_o<=0;
		end else if (stop_from_mem == `Stop) begin
			stall <= 6'b011111;
			flush_o<=0;
		end else if (stop_from_ex == `Stop) begin
			stall <= 6'b001111;
			flush_o<=0;
		end else if (stop_from_id == `Stop) begin
			stall <= 6'b000111;
			flush_o<=0;
		end else if (stop_from_if == `Stop) begin
			stall <= 6'b000011;
			flush_o<=0;
		end else begin
			stall <= 6'b000000;
			flush_o<=0;
		end
	end
	
endmodule