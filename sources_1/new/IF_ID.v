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


	//来自取指阶段的信号，其中宏定义InstBus表示指令宽度，为32  
	input  wire [`InstAddrBus       ] 	if_pc,
	input  wire [`InstBus      	    ] 	if_inst,
	
	input  wire [`Stall 		    ] 	stall,
	
	//对应译码阶段的信号  
	output reg  [`InstAddrBus  	    ] 	id_pc,
	output reg  [`InstBus           ] 	id_inst,
	
	input  wire 						flush,
	
	input  wire [`EXC_CODE_WIDTH-1:0] 	exc_code_i,
	input  wire [`InstAddrBus 		] 	exc_badvaddr_i,
	output reg  [`EXC_CODE_WIDTH-1:0] 	exc_code_o,
	output reg  [`InstAddrBus 		] 	exc_badvaddr_o
    );

    //（1）当stall[1]为Stop，stall[2]为NoStop时，表示取指阶段暂停，  
    //     而译码阶段继续，所以使用空指令作为下一个周期进入译码阶段的指令。  
    //（2）当stall[1]为NoStop时，取指阶段继续，取得的指令进入译码阶段。  
    //（3）其余情况下，保持译码阶段的寄存器id_pc、id_inst不变。  
	always @(posedge cpu_clk_75M or negedge cpu_rst_n) begin
		if (cpu_rst_n == `RstEnable || flush == `Flush) begin
			id_pc 			<= `ZeroWord; 	// 复位的时候pc为0
			id_inst 		<= `ZeroWord; 	// 复位的时候指令也为0，实际就是空指令
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
			id_pc		 	<= if_pc         ;	// 其余时刻向下传递取指阶段的值
			id_inst 		<= if_inst       ;
			exc_code_o 		<= exc_code_i    ;
			exc_badvaddr_o 	<= exc_badvaddr_i;
		end
	end
	
endmodule

