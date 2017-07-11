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
	input wire clk,
	input wire rst,
	input wire we_i,
	input wire re,/////////////////////////////////
	input wire[4:0] waddr_i,
	input wire[4:0] raddr_i,
	input wire[31:0] wdata_i,
	input wire[5:0] int_i,
	
	input wire [4:0] exc_code_i,
	input wire [31:0] exc_epc_i,
	input wire [31:0] exc_badvaddr_i,
	 
	output reg flush_req,
	output reg exc_jump_flag,
	output reg [31:0] exc_jump_addr,

	output reg[31:0] data_o,
	
	output reg[31:0] badvaddr_o,
	output reg[31:0] count_o,
	output reg[31:0] compare_o,
	output reg[31:0] status_o,
	output reg[31:0] cause_o,
	output reg[31:0] epc_o,
	
	output reg int_time_o,
	
	input wire in_delay_i
    );
	 
	/*reg[31:0] regs[0:31];
   	assign badvaddr_o = regs[`Cp0_BadVAddr];
   	assign count_o = regs[`Cp0_Count];
   	assign compare_o = regs[`Cp0_Compare];
   	assign status_o = regs[`Cp0_Status];
   	assign cause_o = regs[`Cp0_Cause];
   	assign epc_o = regs[`Cp0_EPC];*/
	
	//reg int_time_o;
	 
	// wire [7:0] int_actual = { int_time_o, 1'b0, 1'b0, int_com, 4'b0	};
	//wire [7:0] int_actual;
	//assign int_actual = { int_time_o, 1'b0, 1'b0, int_com, 4'b0	};
	//assign has_int = (int_actual & regs[`Cp0_Status][15:8]) !=0  && regs[`Cp0_Status][0] && !regs[`Cp0_Status][1];
	 
	always @(*) begin
		if (rst == `RstEnable) begin
			flush_req <= 1'b0;
		end else begin
			if (exc_code_i != `EC_None)
				flush_req <= 1'b1;
			else
				flush_req <= 1'b0;
		end
	end
	 
	task doit_exec; begin
		exc_jump_flag <= 1;
		exc_jump_addr <= 32'hBFC00380;
		
		if (status_o[1] == 0) begin
			epc_o <= exc_epc_i;
			badvaddr_o <= exc_badvaddr_i;
			if(in_delay_i) cause_o[31] <= 1;
			else cause_o[31] <= 0;
		end
		status_o[1] = 1'b1;
		cause_o[6:2] <= exc_code_i;
	end
	endtask

	task doit_eret; begin
		status_o[1] <= 0;
		exc_jump_flag <= 1;
		exc_jump_addr <= epc_o;
	end
	endtask

   always @ (posedge clk  or negedge rst) begin
		if(rst == `RstEnable) begin
			
            badvaddr_o <= `ZeroWord;
            count_o <= `ZeroWord;
            compare_o <= `ZeroWord;
            status_o <= 32'h80000000;
            cause_o <= `ZeroWord;
            epc_o <= `ZeroWord;
				
            int_time_o <= 0;
			exc_jump_flag <= 0;
			exc_jump_addr <= `ZeroWord;
		end 
      else begin

			cause_o[15:10] <= int_i;
            count_o <= count_o + 1;

			   if (compare_o == count_o && compare_o != 0)
				    int_time_o <= 1;
				
				exc_jump_flag <= 0;
				exc_jump_addr <= `ZeroWord;
				
				case (exc_code_i)
					`EC_None:
						if (we_i == `WriteEnable) begin
							 case(waddr_i)
							 	`Cp0_BadVAddr: badvaddr_o <= wdata_i;
							 	`Cp0_Count: count_o <= wdata_i;
							 	`Cp0_Compare: begin
							 		compare_o <= wdata_i;
							 		int_time_o <= 0;
							 	end
							 	`Cp0_Status: status_o <= wdata_i;
							 	`Cp0_Cause: cause_o <= wdata_i;
							 	`Cp0_EPC: epc_o <= wdata_i;
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
    	if(rst == `RstEnable) begin
    		data_o <= `ZeroWord;
    	end
		else if (re == `ReadEnable) begin
			case(raddr_i)
				`Cp0_BadVAddr: data_o <= badvaddr_o;
				`Cp0_Count: data_o <= count_o;
				`Cp0_Compare: data_o <= compare_o;
				`Cp0_Status: data_o <= status_o;
				`Cp0_Cause: data_o <= {16'b0, int_i, cause_o[9:0]};
				`Cp0_EPC: data_o <= epc_o;
			endcase
      end 
		else begin
         data_o <= `ZeroWord;
      end
    end

endmodule