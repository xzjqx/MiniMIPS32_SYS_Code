`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 16:58:33
// Design Name: 
// Module Name: HILO
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

module HILO(
	input wire cpu_clk_75M,
	input wire cpu_rst_n,

	// 写端口 
	input wire we,
	input wire [31:0] hi_i,
	input wire [31:0] lo_i,
	
	// 读端口 
	output reg [31:0] hi_o,
	output reg [31:0] lo_o
    );

	always @(posedge cpu_clk_75M or negedge cpu_rst_n) begin
		if (cpu_rst_n == `RstEnable) begin
			hi_o <= 32'b0;
			lo_o <= 32'b0;
		end
		else if (we == `WriteEnable)begin
			hi_o <= hi_i;
			lo_o <= lo_i;
		end
	end

endmodule