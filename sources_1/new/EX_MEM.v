`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 16:47:10
// Design Name: 
// Module Name: EX_MEM
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

module EX_MEM(
	input  wire 				cpu_clk_75M,
	input  wire 				cpu_rst_n,

	// 来自执行阶段的信息
	input  wire [`RegAddrBus ] 	ex_wd,
	input  wire 				ex_wreg,
	input  wire [`RegBus 	 ] 	ex_wdata,
	
	input  wire 				ex_whilo,
	input  wire [`RegBus 	 ] 	ex_hi,
	input  wire [`RegBus 	 ] 	ex_lo,
	
	input  wire [`AluOpBus 	 ] 	ex_aluop,
	input  wire [`InstAddrBus] 	ex_mem_addr,
	input  wire [`RegBus 	 ] 	ex_reg2,

	input  wire 				ex_cp0_reg_we,
	input  wire [`RegAddrBus ]  ex_cp0_reg_write_addr,
	input  wire [`RegBus 	 ]  ex_cp0_reg_data,

	output reg 					mem_cp0_reg_we,
	output reg  [`RegAddrBus ]  mem_cp0_reg_write_addr,
	output reg  [`RegBus 	 ]  mem_cp0_reg_data,
	
	// 送到访存阶段的信息 
	output reg  [`RegAddrBus ]  mem_wd,
	output reg 					mem_wreg,
	output reg  [`RegBus 	 ]  mem_wdata,
	
	output reg 					mem_whilo,
	output reg  [`RegBus 	 ]  mem_hi,
	output reg  [`RegBus 	 ]  mem_lo,
	
	output reg  [`AluOpBus 	 ]  mem_aluop,
	output reg  [`InstAddrBus]  mem_mem_addr,
	output reg  [`RegBus 	 ]  mem_reg2,
	
	input  wire [`Stall 	 ]  stall,
	
	input  wire 				flush,
	
	input  wire [`EXC_CODE_WIDTH-1:0]exc_code_i,
	input  wire [`InstAddrBus]  exc_epc_i,
	input  wire [`InstAddrBus]  exc_badvaddr_i,
	
	output reg  [`EXC_CODE_WIDTH-1:0] exc_code_o,
	output reg  [`InstAddrBus]  exc_epc_o,
	output reg  [`InstAddrBus]  exc_badvaddr_o,
	
	input  wire 				ex_in_delay,
	output reg 					mem_in_delay,
	input  wire [`InstAddrBus]  ex_pc,
	output reg  [`InstAddrBus]  mem_pc
    );

    //（1）当stall[3]为Stop，stall[4]为NoStop时，表示执行阶段暂停，  
    //     而访存阶段继续，所以使用空指令作为下一个周期进入访存阶段的指令。  
    //（2）当stall[3]为NoStop时，执行阶段继续，执行后的指令进入访存阶段。  
    //（3）其余情况下，保持访存阶段的寄存器mem_wb、mem_wreg、mwm_wdata、  
    //     mem_hi、mem_lo、mem_whilo不变。 ?
	always @(posedge cpu_clk_75M or negedge cpu_rst_n) begin
		if (cpu_rst_n == `RstEnable || flush) begin
			mem_wd 				   <= `NOPRegAddr;
			mem_wreg 			   <= `WriteDisable;
			mem_wdata 			   <= `ZeroWord;
			mem_whilo 			   <= `WriteDisable;
			mem_hi 				   <= `ZeroWord;
			mem_lo 				   <= `ZeroWord;
			mem_aluop 			   <= `SLL;
			mem_mem_addr 		   <= `ZeroWord;
			mem_reg2 			   <= `ZeroWord;
			mem_cp0_reg_we  	   <= `WriteDisable;
			mem_cp0_reg_write_addr <= `NOPRegAddr;
			mem_cp0_reg_data  	   <= `ZeroWord;
			mem_in_delay 		   <= `NotInDelaySlot;
			mem_pc  			   <= `ZeroWord;
			exc_code_o			   <= `EC_None;
			exc_epc_o 			   <= `ZeroWord;
			exc_badvaddr_o 		   <= `ZeroWord;
		end
		else if (stall[3] == `Stop && stall[4] == `NoStop) begin
			mem_wd 				   <= `NOPRegAddr;
			mem_wreg 			   <= `WriteDisable;
			mem_wdata    		   <= `ZeroWord;
			mem_whilo 			   <= `WriteDisable;
			mem_hi 				   <= `ZeroWord;
			mem_lo  			   <= `ZeroWord;
			mem_aluop 			   <= `SLL;
			mem_mem_addr 		   <= `ZeroWord;
			mem_reg2 			   <= `ZeroWord;
			mem_cp0_reg_we 		   <= `WriteDisable;
			mem_cp0_reg_write_addr <= `NOPRegAddr;
			mem_cp0_reg_data 	   <= `ZeroWord;
			mem_in_delay 		   <= `NotInDelaySlot;
			mem_pc 				   <= `ZeroWord;
			exc_code_o 			   <= `EC_None;
			exc_epc_o 			   <= `ZeroWord;
			exc_badvaddr_o 		   <= `ZeroWord;
		end
		else if (stall[3] == `NoStop) begin
			mem_wd 				   <= ex_wd;
			mem_wreg 			   <= ex_wreg;
			mem_wdata 			   <= ex_wdata;
			mem_whilo 			   <= ex_whilo;
			mem_hi 				   <= ex_hi;
			mem_lo 				   <= ex_lo;
			mem_aluop 			   <= ex_aluop;
			mem_mem_addr 		   <= ex_mem_addr;
			mem_reg2 			   <= ex_reg2;
			mem_cp0_reg_we 		   <= ex_cp0_reg_we;
			mem_cp0_reg_write_addr <= ex_cp0_reg_write_addr;
			mem_cp0_reg_data 	   <= ex_cp0_reg_data;
			mem_in_delay 		   <= ex_in_delay;
			mem_pc 				   <= ex_pc;
			exc_code_o 			   <= exc_code_i;
			exc_epc_o 			   <= exc_epc_i;
			exc_badvaddr_o 		   <= exc_badvaddr_i;
		end
	end
	
endmodule