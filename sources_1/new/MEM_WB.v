`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 16:57:07
// Design Name: 
// Module Name: MEM_WB
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

module MEM_WB(
	input wire clk,
	input wire rst,

	// 访存阶段的结果
	input wire [4:0] mem_wd,
	input wire mem_wreg,
	input wire [31:0] mem_wdata,
	
	input wire mem_whilo,
	input wire [31:0] mem_hi,
	input wire [31:0] mem_lo,

	// 送到回写阶段的信息 
	output reg [4:0] wb_wd,
	output reg wb_wreg,
	output reg [31:0] wb_wdata,
	
	output reg wb_whilo,
	output reg [31:0] wb_hi,
	output reg [31:0] wb_lo,
	
	input wire [5:0] stall,
	
	input wire flush
    );

       //（1）当stall[4]为Stop，stall[5]为NoStop时，表示访存阶段暂停，  
       //     而回写阶段继续，所以使用空指令作为下一个周期进入回写阶段的指令。  
       //（2）当stall[4]为NoStop时，访存阶段继续，访存后的指令进入回写阶段。  
       //（3）其余情况下，保持回写阶段的寄存器wb_wd、wb_wreg、wb_wdata、  
       //     wb_hi、wb_lo、wb_whilo不变。  
	always @(posedge clk or negedge rst) begin
		if (rst == `RstEnable || flush == 1'b1) begin
			wb_wd <= 5'b0;
			wb_wreg <= 1'b0;
			wb_wdata <= 32'b0;
			wb_whilo <= 1'b0;
			wb_hi <= 32'b0;
			wb_lo <= 32'b0;
		end
		else if (stall[4] == `Stop && stall[5] == `NoStop) begin
			wb_wd <= 5'b0;
			wb_wreg <= 1'b0;
			wb_wdata <= 32'b0;
			wb_whilo <= 1'b0;
			wb_hi <= 32'b0;
			wb_lo <= 32'b0;
		end
		else if (stall[4] == `NoStop) begin
			wb_wd <= mem_wd;
			wb_wreg <= mem_wreg;
			wb_wdata <= mem_wdata;
			wb_whilo <= mem_whilo;
			wb_hi <= mem_hi;
			wb_lo <= mem_lo;
		end
	end

endmodule