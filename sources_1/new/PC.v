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
	input 	wire 					cpu_clk_75M				,
	input 	wire 					cpu_rst_n 				,
	
	input 	wire 					branch_flag_i 			,
	input 	wire [`InstAddrBus] 	branch_target_address_i ,
	
	input 	wire [`Stall 	  ] 	stall				    ,	// 来自控制模块CTRL
	
	output 	reg  [`InstAddrBus] 	pc 						,
	
	input 	wire 					cp0_branch_flag 		,
	input 	wire [`InstAddrBus] 	cp0_branch_addr 		,
	
	output 	reg 					ce
    );

	//First Stop, Then Branch
	always @(posedge cpu_clk_75M) begin
		if (ce == `ChipDisable)
			pc <= `Init_pc;			// 指令存储器禁用的时候，PC为INIT_PC
		else begin
			if (cp0_branch_flag  == `Branch)
				pc <= cp0_branch_addr;
			else if (stall[0]    == `NoStop) begin	// 当stall[0]为NoStop时，pc加4，否则，保持pc不变
				if(branch_flag_i == `Branch)
					pc <= branch_target_address_i;
				else
					pc <= pc + 4'h4; // 指令存储器使能的时候，PC的值每时钟周期加4 
			end		
		end
	end
	
	always @(posedge cpu_clk_75M) begin
		if (cpu_rst_n == `RstEnable) begin
			ce <= `ChipDisable;		// 复位的时候指令存储器禁用  
		end else begin
			ce <= `ChipEnable; 		// 复位结束后，指令存储器使能
		end
	end

endmodule

