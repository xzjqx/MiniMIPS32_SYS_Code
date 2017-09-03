`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 16:18:02
// Design Name: 
// Module Name: IF_ID
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

module IF_ID(
	input  wire 						cpu_clk_75M,
	input  wire 						cpu_rst_n,


	//����ȡָ�׶ε��źţ����к궨��InstBus��ʾָ���ȣ�Ϊ32  
	input  wire [`InstAddrBus       ] 	if_pc,
	input  wire [`InstBus      	    ] 	if_inst,
	
	input  wire [`Stall 		    ] 	stall,
	
	//��Ӧ����׶ε��ź�  
	output reg  [`InstAddrBus  	    ] 	id_pc,
	output reg  [`InstBus           ] 	id_inst,
	
	input  wire 						flush,
	
	input  wire [`EXC_CODE_WIDTH-1:0] 	exc_code_i,
	input  wire [`InstAddrBus 		] 	exc_badvaddr_i,
	output reg  [`EXC_CODE_WIDTH-1:0] 	exc_code_o,
	output reg  [`InstAddrBus 		] 	exc_badvaddr_o
    );

    //��1����stall[1]ΪStop��stall[2]ΪNoStopʱ����ʾȡָ�׶���ͣ��  
    //     ������׶μ���������ʹ�ÿ�ָ����Ϊ��һ�����ڽ�������׶ε�ָ�  
    //��2����stall[1]ΪNoStopʱ��ȡָ�׶μ�����ȡ�õ�ָ���������׶Ρ�  
    //��3����������£���������׶εļĴ���id_pc��id_inst���䡣  
	always @(posedge cpu_clk_75M or negedge cpu_rst_n) begin
		if (cpu_rst_n == `RstEnable || flush == `Flush) begin
			id_pc 			<= `ZeroWord; 	// ��λ��ʱ��pcΪ0
			id_inst 		<= `ZeroWord; 	// ��λ��ʱ��ָ��ҲΪ0��ʵ�ʾ��ǿ�ָ��
			exc_code_o 		<= `EC_None ;
			exc_badvaddr_o 	<= `ZeroWord;
		end
		else if (stall[1] == `Stop && stall[2] == `NoStop) begin
			id_pc 			<= `ZeroWord;
			id_inst 		<= `ZeroWord;
			exc_code_o 		<= `EC_None ;
			exc_badvaddr_o 	<= `ZeroWord;
		end
		else if (stall[1] == `NoStop) begin
			id_pc		 	<= if_pc         ;	// ����ʱ�����´���ȡָ�׶ε�ֵ
			id_inst 		<= if_inst       ;
			exc_code_o 		<= exc_code_i    ;
			exc_badvaddr_o 	<= exc_badvaddr_i;
		end
	end
	
endmodule

