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
	
	input 	wire [`Stall 	  ] 	stall				    ,	// ���Կ���ģ��CTRL
	
	output 	reg  [`InstAddrBus] 	pc 						,
	
	input 	wire 					cp0_branch_flag 		,
	input 	wire [`InstAddrBus] 	cp0_branch_addr 		,
	
	output 	reg 					ce
    );

	//First Stop, Then Branch
	always @(posedge cpu_clk_75M) begin
		if (ce == `ChipDisable)
			pc <= `Init_pc;			// ָ��洢�����õ�ʱ��PCΪINIT_PC
		else begin
			if (cp0_branch_flag  == `Branch)
				pc <= cp0_branch_addr;
			else if (stall[0]    == `NoStop) begin	// ��stall[0]ΪNoStopʱ��pc��4�����򣬱���pc����
				if(branch_flag_i == `Branch)
					pc <= branch_target_address_i;
				else
					pc <= pc + 4'h4; // ָ��洢��ʹ�ܵ�ʱ��PC��ֵÿʱ�����ڼ�4 
			end		
		end
	end
	
	always @(posedge cpu_clk_75M) begin
		if (cpu_rst_n == `RstEnable) begin
			ce <= `ChipDisable;		// ��λ��ʱ��ָ��洢������  
		end else begin
			ce <= `ChipEnable; 		// ��λ������ָ��洢��ʹ��
		end
	end

endmodule

