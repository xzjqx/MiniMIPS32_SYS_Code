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

	// ������׶δ��ݹ�������Ϣ
	input  wire [`AluSelBus  ]  id_alusel,
	input  wire [`AluOpBus	 ]  id_aluop,
	input  wire [`RegBus 	 ]  id_src1,
	input  wire [`RegBus 	 ]  id_src2,
	input  wire [`RegAddrBus ]  id_wd,
	input  wire 				id_wreg,
	
	input  wire 				id_is_in_delayslot,
	input  wire [`InstAddrBus] 	id_link_address,
	input  wire 				next_inst_in_delayslot_i,
	
	input  wire [`InstBus 	 ] 	id_inst,	// ����IDģ����ź�
	input  wire [`InstAddrBus] 	id_pc,
	
	// ���ݵ�ִ�н׶ε���Ϣ
	output reg  [`AluSelBus  ] 	ex_alusel,
	output reg  [`AluOpBus 	 ] 	ex_aluop,
	output reg  [`RegBus 	 ] 	ex_src1,
	output reg  [`RegBus 	 ] 	ex_src2,
	output reg  [`RegAddrBus ] 	ex_wd,
	output reg 					ex_wreg,
	
	output reg 					ex_is_in_delayslot,
	output reg  [`InstAddrBus] 	ex_link_address,
	output reg 					is_in_delayslot_o,
	
	output reg  [`InstBus 	 ] 	ex_inst,	// ���ݵ�EXģ��
	output reg  [`InstAddrBus] 	ex_pc,
	
	//���Կ���ģ�����Ϣ
	input  wire [`Stall 	 ] 	stall,
	
	input  wire 				flush,
	
	input  wire [`EXC_CODE_WIDTH-1:0] exc_code_i,
	input  wire [`InstAddrBus] 	exc_epc_i,
	input  wire [`InstAddrBus] 	exc_badvaddr_i,
	
	output reg  [`EXC_CODE_WIDTH-1:0] exc_code_o,
	output reg  [`InstAddrBus] 	exc_epc_o,
	output reg  [`InstAddrBus] 	exc_badvaddr_o
    );

    //��1����stall[2]ΪStop��stall[3]ΪNoStopʱ����ʾ����׶���ͣ��  
    //     ��ִ�н׶μ���������ʹ�ÿ�ָ����Ϊ��һ�����ڽ���ִ�н׶ε�ָ�  
    //��2����stall[2]ΪNoStopʱ������׶μ�����������ָ�����ִ�н׶Ρ�  
    //��3����������£�����ִ�н׶εļĴ���ex_aluop��ex_alusel��ex_src1��  
    //    ex_src2��ex_wd��ex_wreg����  ?
	always @(posedge cpu_clk_75M or negedge cpu_rst_n) begin
		if (cpu_rst_n == `RstEnable || flush == 1'b1) begin
			ex_alusel 		   <= `NopAlusel;
			ex_aluop 		   <= `SLL;
			ex_src1 		   <= `ZeroWord;
			ex_src2 		   <= `ZeroWord;
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
			ex_src1 		   <= `ZeroWord;
			ex_src2 		   <= `ZeroWord;
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
			ex_src1 		   <= id_src1;
			ex_src2 		   <= id_src2;
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