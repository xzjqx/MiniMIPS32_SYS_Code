`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 17:00:04
// Design Name: 
// Module Name: CP0
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

module CP0(
	input  wire 				cpu_clk_75M,
	input  wire 				cpu_rst_n,
	input  wire 				we_i,
	input  wire 				re,
	input  wire [`RegAddrBus ] 	waddr_i,
	input  wire [`RegAddrBus ] 	raddr_i,
	input  wire [`RegBus     ] 	wdata_i,
	input  wire [`Cp0Int     ]  int_i,
	
	input  wire [`ExcCode  	 ] 	exc_code_i,
	input  wire [`InstAddrBus] 	exc_epc_i,
	input  wire [`RegBus     ] 	exc_badvaddr_i,
	 
	output reg 					flush_req,
	output reg 					exc_jump_flag,
	output reg  [`RegBus     ] 	exc_jump_addr,

	output reg 	[`RegBus     ] 	data_o,
	
	output reg 	[`RegBus     ] 	badvaddr_o,
	output reg 	[`RegBus     ] 	count_o,
	output reg 	[`RegBus     ] 	compare_o,
	output reg 	[`RegBus 	 ] 	status_o,
	output reg 	[`RegBus 	 ] 	cause_o,
	output reg 	[`InstAddrBus] 	epc_o,
	
	output reg 					int_time_o,
	
	input  wire 				in_delay_i
    );
		 
	always @(*) begin
		if (cpu_rst_n == `RstEnable) begin
			flush_req <= `NoFlush;
		end else begin
			if (exc_code_i != `EC_None)
				flush_req  <= `Flush;
			else
				flush_req  <= `NoFlush;
		end
	end
	 
	task doit_exec; begin
		exc_jump_flag <= `Branch;
		exc_jump_addr <= 32'hBFC00380;
		
		if (status_o[1] == 0) begin
			epc_o 		    <= exc_epc_i;
			badvaddr_o      <= exc_badvaddr_i;
			if(in_delay_i) 
				cause_o[31] <= 1;
			else 	
				cause_o[31] <= 0;
		end
		status_o[1]  = 1'b1;
		cause_o[6:2] <= exc_code_i;
	end
	endtask

	task doit_eret; begin
		status_o[1]   <= 0;
		exc_jump_flag <= `Branch;
		exc_jump_addr <= epc_o;
	end
	endtask

   always @ (posedge cpu_clk_75M  or negedge cpu_rst_n) begin
		if(cpu_rst_n == `RstEnable) begin
			
            badvaddr_o 	  <= `ZeroWord;
            count_o 	  <= `ZeroWord;
            compare_o 	  <= `ZeroWord;
            status_o 	  <= 32'h80000000;
            cause_o 	  <= `ZeroWord;
            epc_o 		  <= `ZeroWord;
				
            int_time_o	  <= 0;
			exc_jump_flag <= `NotBranch;
			exc_jump_addr <= `ZeroWord;
		end 
        else begin

			cause_o[15:10] <= int_i;
            count_o 	   <= count_o + 1;

			   if (compare_o == count_o && compare_o != 0)
				    int_time_o <= 1;
				
				exc_jump_flag  <= `NotBranch;
				exc_jump_addr  <= `ZeroWord;
				
				case (exc_code_i)
					`EC_None:
						if (we_i == `WriteEnable) begin
							 case(waddr_i)
							 	`Cp0_BadVAddr: badvaddr_o <= wdata_i;
							 	`Cp0_Count: count_o 	  <= wdata_i;
							 	`Cp0_Compare: begin
							 		compare_o  <= wdata_i;
							 		int_time_o <= 0;
							 	end
							 	`Cp0_Status: status_o <= wdata_i;
							 	`Cp0_Cause: cause_o   <= wdata_i;
							 	`Cp0_EPC: epc_o       <= wdata_i;
							 endcase
					   end
						
					`EC_Eret:
						doit_eret();
						
					default:
						doit_exec();
			  endcase
			  
		end
		
	end

   always @ (*) begin
    	if(cpu_rst_n == `RstEnable) begin
    		data_o   <= `ZeroWord;
    	end
		else if (re == `ReadEnable) begin
			case(raddr_i)
				`Cp0_BadVAddr: data_o <= badvaddr_o;
				`Cp0_Count: data_o    <= count_o;
				`Cp0_Compare: data_o  <= compare_o;
				`Cp0_Status: data_o   <= status_o;
				`Cp0_Cause: data_o    <= cause_o;
				`Cp0_EPC: data_o      <= epc_o;
			endcase
        end 
		else begin
         		data_o <= `ZeroWord;
      end
    end

endmodule