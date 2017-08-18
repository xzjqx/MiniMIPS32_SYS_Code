`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 16:44:12
// Design Name: 
// Module Name: ID_EX
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

module ID_EX(
	input  wire 				cpu_clk_75M,
	input  wire 				cpu_rst_n,

	// 从译码阶段传递过来的信息
	input  wire [`AluSelBus  ]  id_alusel,
	input  wire [`AluOpBus	 ]  id_aluop,
	input  wire [`RegBus 	 ]  id_reg1,
	input  wire [`RegBus 	 ]  id_reg2,
	input  wire [`RegAddrBus ]  id_wd,
	input  wire 				id_wreg,
	
	input  wire 				id_is_in_delayslot,
	input  wire [`InstAddrBus] 	id_link_address,
	input  wire 				next_inst_in_delayslot_i,
	
	input  wire [`InstBus 	 ] 	id_inst,	// 来自ID模块的信号
	input  wire [`InstAddrBus] 	id_pc,
	
	// 传递到执行阶段的信息
	output reg  [`AluSelBus  ] 	ex_alusel,
	output reg  [`AluOpBus 	 ] 	ex_aluop,
	output reg  [`RegBus 	 ] 	ex_reg1,
	output reg  [`RegBus 	 ] 	ex_reg2,
	output reg  [`RegAddrBus ] 	ex_wd,
	output reg 					ex_wreg,
	
	output reg 					ex_is_in_delayslot,
	output reg  [`InstAddrBus] 	ex_link_address,
	output reg 					is_in_delayslot_o,
	
	output reg  [`InstBus 	 ] 	ex_inst,	// 传递到EX模块
	output reg  [`InstAddrBus] 	ex_pc,
	
	//来自控制模块的信息
	input  wire [`Stall 	 ] 	stall,
	
	input  wire 				flush,
	
	input  wire [`EXC_CODE_WIDTH-1:0] exc_code_i,
	input  wire [`InstAddrBus] 	exc_epc_i,
	input  wire [`InstAddrBus] 	exc_badvaddr_i,
	
	output reg  [`EXC_CODE_WIDTH-1:0] exc_code_o,
	output reg  [`InstAddrBus] 	exc_epc_o,
	output reg  [`InstAddrBus] 	exc_badvaddr_o
    );

    //（1）当stall[2]为Stop，stall[3]为NoStop时，表示译码阶段暂停，  
    //     而执行阶段继续，所以使用空指令作为下一个周期进入执行阶段的指令。  
    //（2）当stall[2]为NoStop时，译码阶段继续，译码后的指令进入执行阶段。  
    //（3）其余情况下，保持执行阶段的寄存器ex_aluop、ex_alusel、ex_reg1、  
    //    ex_reg2、ex_wd、ex_wreg不变  ?
	always @(posedge cpu_clk_75M or negedge cpu_rst_n) begin
		if (cpu_rst_n == `RstEnable || flush == 1'b1) begin
			ex_alusel 		   <= `NopAlusel;
			ex_aluop 		   <= `SLL;
			ex_reg1 		   <= `ZeroWord;
			ex_reg2 		   <= `ZeroWord;
			ex_wd 			   <= `NOPRegAddr;
			ex_wreg 		   <= `WriteDisable;
			ex_is_in_delayslot <= `NotInDelaySlot;
			ex_link_address    <= `ZeroWord;
			is_in_delayslot_o  <= `NotInDelaySlot;
			ex_inst  		   <= `ZeroWord;
			ex_pc 	           <= `ZeroWord;
			exc_code_o 	       <= `EC_None;
			exc_epc_o 		   <= `ZeroWord;
			exc_badvaddr_o 	   <= `ZeroWord;
		end
		else if (stall[2] == `Stop && stall[3] == `NoStop) begin
			ex_alusel 		   <= `NopAlusel;
			ex_aluop 		   <= `SLL;
			ex_reg1 		   <= `ZeroWord;
			ex_reg2 		   <= `ZeroWord;
			ex_wd 			   <= `NOPRegAddr;
			ex_wreg 		   <= `WriteDisable;
			ex_is_in_delayslot <= `NotInDelaySlot;
			ex_link_address    <= `ZeroWord;
			ex_inst 		   <= `ZeroWord;
			ex_pc 			   <= `ZeroWord;
			exc_code_o 	       <= `EC_None;
			exc_epc_o 	       <= `ZeroWord;
			exc_badvaddr_o 	   <= `ZeroWord;
		end
		else if (stall[2] == `NoStop) begin
			ex_alusel 		   <= id_alusel;
			ex_aluop 		   <= id_aluop;
			ex_reg1 		   <= id_reg1;
			ex_reg2 		   <= id_reg2;
			ex_wd 			   <= id_wd;
			ex_wreg 		   <= id_wreg;
			ex_is_in_delayslot <= id_is_in_delayslot;
			ex_link_address    <= id_link_address;
			is_in_delayslot_o  <= next_inst_in_delayslot_i;
			ex_inst 		   <= id_inst;	
			ex_pc 			   <= id_pc;
			exc_code_o 		   <= exc_code_i;
			exc_epc_o 		   <= exc_epc_i;
			exc_badvaddr_o 	   <= exc_badvaddr_i;
		end
	end

endmodule