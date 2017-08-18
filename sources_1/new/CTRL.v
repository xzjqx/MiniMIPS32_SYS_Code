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
	input  wire 			cpu_clk_75M,
	input  wire 			cpu_rst_n,
	input  wire 			stop_from_id,	// 来自译码阶段的暂停请求
	input  wire 			stop_from_ex,	// 来自执行阶段的暂停请求
	input  wire 			stop_from_mem, 	// 来自译码阶段的暂停请求   !!
	input  wire 			stop_from_pc,	// 来自译码阶段的暂停请求!!
	input  wire 			stop_from_if,	// 来自译码阶段的暂停请求!!
	input  wire 			ctrl_flush_i, 
	output reg 	[`Stall] 	stall,
	output reg 				flush_o
    );

	reg flush_delay;
	
	always @ (posedge cpu_clk_75M or negedge cpu_rst_n) begin
		if (cpu_rst_n == `RstEnable) begin
			flush_delay <= `NoFlush;
		end else begin
			flush_delay <= ctrl_flush_i;
		end
	
	end

	always @ (*) begin
		if (cpu_rst_n == `RstEnable) begin
			stall   <= 6'b000000;
			flush_o <= `NoFlush;
		end else if (ctrl_flush_i || flush_delay) begin
			stall   <= 6'b000000;
			flush_o <= `Flush;
		end else if (stop_from_pc  == `Stop) begin
			stall   <= 6'b111111;
			flush_o <= `NoFlush;
		end else if (stop_from_mem == `Stop) begin
			stall   <= 6'b011111;
			flush_o <= `NoFlush;
		end else if (stop_from_ex  == `Stop) begin
			stall   <= 6'b001111;
			flush_o <= `NoFlush;
		end else if (stop_from_id  == `Stop) begin
			stall   <= 6'b000111;
			flush_o <= `NoFlush;
		end else if (stop_from_if  == `Stop) begin
			stall   <= 6'b000111;
			flush_o <= `NoFlush;
		end else begin
			stall   <= 6'b000000;
			flush_o <= `NoFlush;
		end
	end
	
endmodule