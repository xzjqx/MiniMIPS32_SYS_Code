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
	input  wire 				cpu_clk_75M,
	input  wire 				cpu_rst_n,

	// �ô�׶εĽ��
	input  wire [`RegAddrBus] 	mem_wd,
	input  wire 				mem_wreg,
	input  wire [`RegBus    ] 	mem_wdata,
	
	input  wire 				mem_whilo,
	input  wire [`RegBus    ] 	mem_hi,
	input  wire [`RegBus 	] 	mem_lo,

	// �͵���д�׶ε���Ϣ 
	output reg  [`RegAddrBus] 	wb_wd,
	output reg 					wb_wreg,
	output reg  [`RegBus 	] 	wb_wdata,
	
	output reg wb_whilo,
	output reg  [`RegBus 	] 	wb_hi,
	output reg  [`RegBus 	] 	wb_lo,
	
	input  wire [`Stall 	] 	stall,
	
	input  wire 				flush
    );

    //��1����stall[4]ΪStop��stall[5]ΪNoStopʱ����ʾ�ô�׶���ͣ��  
    //     ����д�׶μ���������ʹ�ÿ�ָ����Ϊ��һ�����ڽ����д�׶ε�ָ�  
    //��2����stall[4]ΪNoStopʱ���ô�׶μ������ô���ָ������д�׶Ρ�  
    //��3����������£����ֻ�д�׶εļĴ���wb_wd��wb_wreg��wb_wdata��  
    //     wb_hi��wb_lo��wb_whilo���䡣  
	always @(posedge cpu_clk_75M or negedge cpu_rst_n) begin
		if (cpu_rst_n == `RstEnable || flush == `Flush) begin
			wb_wd 	 <= `NOPRegAddr;
			wb_wreg  <= `WriteDisable;
			wb_wdata <= `ZeroWord;
			wb_whilo <= `WriteDisable;
			wb_hi    <= `ZeroWord;
			wb_lo 	 <= `ZeroWord;
		end
		else if (stall[4] == `Stop && stall[5] == `NoStop) begin
			wb_wd 	 <= `NOPRegAddr;
			wb_wreg  <= `WriteDisable;
			wb_wdata <= `ZeroWord;
			wb_whilo <= `WriteDisable;
			wb_hi 	 <= `ZeroWord;
			wb_lo 	 <= `ZeroWord;
		end
		else if (stall[4] == `NoStop) begin
			wb_wd 	 <= mem_wd;
			wb_wreg  <= mem_wreg;
			wb_wdata <= mem_wdata;
			wb_whilo <= mem_whilo;
			wb_hi 	 <= mem_hi;
			wb_lo    <= mem_lo;
		end
	end

endmodule