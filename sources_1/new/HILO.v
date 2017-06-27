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
	input wire clk,
	input wire rst,
	input wire we,
	input wire [31:0] hi_i,
	input wire [31:0] lo_i,
	
	output reg [31:0] hi_o,
	output reg [31:0] lo_o
    );

	always @(posedge clk or negedge rst) begin
		if (rst == `RstEnable) begin
			hi_o <= 32'b0;
			lo_o <= 32'b0;
		end
		else if (we == `WriteEnable)begin
			hi_o <= hi_i;
			lo_o <= lo_i;
		end
	end

endmodule