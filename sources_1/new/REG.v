`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 16:43:11
// Design Name: 
// Module Name: REG
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

module REG(
	input wire 			cpu_clk_75M,
	input wire 			cpu_rst_n,
	
	// 写端口
	input wire  [ 4:0] 	waddr,
	input wire  [31:0] 	wdata,
	input wire 			we,
	
	// 读端口1
	input wire  [ 4:0] 	reg1_addr,
	output reg  [31:0] 	reg1_data,
	input wire 			reg1_read,
	
	// 读端口2 
	input wire  [ 4:0] 	reg2_addr,
	output reg  [31:0] 	reg2_data,
	input wire 			reg2_read,
	
	input wire  [ 4:0] 	debug_addr,
	output wire [31:0] 	debug_data
    );
	
	//定义32个32位寄存器
	reg [31:0] regs[0:31];
	
	always @(posedge cpu_clk_75M) begin
		if (cpu_rst_n == `RstEnable) begin
			regs[ 0] <= 32'h00000000;
			regs[ 1] <= 32'h00000000;
			regs[ 2] <= 32'h00000000;
			regs[ 3] <= 32'h00000000;
			regs[ 4] <= 32'h00000000;
			regs[ 5] <= 32'h00000000;
			regs[ 6] <= 32'h00000000;
			regs[ 7] <= 32'h00000000;
			regs[ 8] <= 32'h00000000;
			regs[ 9] <= 32'h00000000;
			regs[10] <= 32'h00000000;
			regs[11] <= 32'h00000000;
			regs[12] <= 32'h00000000;
			regs[13] <= 32'h00000000;
			regs[14] <= 32'h00000000;
			regs[15] <= 32'h00000000;
			regs[16] <= 32'h00000000;
			regs[17] <= 32'h00000000;
			regs[18] <= 32'h00000000;
			regs[19] <= 32'h00000000;
			regs[20] <= 32'h00000000;
			regs[21] <= 32'h00000000;
			regs[22] <= 32'h00000000;
			regs[23] <= 32'h00000000;
			regs[24] <= 32'h00000000;
			regs[25] <= 32'h00000000;
			regs[26] <= 32'h00000000;
			regs[27] <= 32'h00000000;
			regs[28] <= 32'h00000000;
			regs[29] <= 32'h00000000;
			regs[30] <= 32'h00000000;
			regs[31] <= 32'h00000000;
		end
		else begin
			if ((we == `WriteEnable) && (waddr != 5'h0))	//0�żĴ���Ҫһֱ����Ϊȫ0
				regs[waddr] <= wdata;
		end
	end
	
	//读端口1的读操作 
	// reg1_addr是读地址、waddr是写地址、we是写使能、wdata是要写入的数据 
	always @(*) begin
		if (cpu_rst_n == `RstEnable)
			reg1_data <= 32'b0;
		else if (reg1_addr == 5'b0)
			reg1_data <= 32'b0;
		else if ((reg1_read == `ReadEnable) && (we == `WriteEnable) && (waddr == reg1_addr))
			reg1_data <= wdata;
		else if (reg1_read == `ReadEnable)
			reg1_data <= regs[reg1_addr];
		else
			reg1_data <= 32'b0;
	end
	
	//读端口2的读操作 
	// reg2_addr是读地址、waddr是写地址、we是写使能、wdata是要写入的数据 
	always @(*) begin
		if (cpu_rst_n == `RstEnable)
			reg2_data <= 32'b0;
		else if (reg2_addr == 5'b0)
			reg2_data <= 32'b0;
		else if ((reg2_read == `ReadEnable) && (we == `WriteEnable) && (waddr == reg2_addr))
			reg2_data <= wdata;
		else if (reg2_read == `ReadEnable)
			reg2_data <= regs[reg2_addr];
		else
			reg2_data <= 32'b0;
	end
	
    assign debug_data = regs[debug_addr];
	
endmodule
