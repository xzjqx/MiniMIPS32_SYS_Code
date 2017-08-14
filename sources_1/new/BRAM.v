`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/25 15:39:13
// Design Name: 
// Module Name: BRAM
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

module BRAM(
	wb_clk_i, wb_rst_i, wb_cyc_i, wb_adr_i, wb_dat_i, wb_sel_i, wb_we_i, wb_stb_i,
	wb_dat_o, wb_ack_o,
	
	wea, ram_ce, ram_addr, ram_data_i, ram_data_o//, stall
	);
	
	//
	// WISHBONE Interface
	//
	input             	wb_clk_i;	// Clock
	input             	wb_rst_i;	// Reset
	input            	wb_cyc_i;	// cycle valid input
	input   [31:0]		wb_adr_i;	// address bus inputs
	input   [31:0]		wb_dat_i;	// input data bus
	input	[3:0]     	wb_sel_i;	// byte select inputs
	input             	wb_we_i;	// indicates write transfer
	input             	wb_stb_i;	// strobe input
	output  [31:0]		wb_dat_o;	// output data bus
	output 				wb_ack_o;	// normal termination
	
	output 	[3:0]		wea;
	output              ram_ce;
	output  [17:0] 		ram_addr;
	input   [31:0] 		ram_data_i;
	output  [31:0] 		ram_data_o;

	//input	[6:0]		stall;
	
	////////////////////////////
	wire [31:0] addr = wb_adr_i;
	wire [31:0] data_in = wb_dat_i;
	
	////////////////////////////
	assign  wea = (wb_stb_i && wb_we_i) ? wb_sel_i : 4'b0;
	assign  ram_ce = (|wb_sel_i); //& !stall[1];
	assign	ram_data_o = wb_dat_i;
	assign  ram_addr = wb_adr_i[19:2];
	assign  wb_dat_o = ram_data_i;

	/*always @(posedge wb_clk_i) begin
		if (wb_rst_i == `RstEnable) 
			wb_dat_o <= 0;
		else 
			wb_dat_o <= ram_data_i;
	end*/
	
	//assign wb_ack_o = 1'b1;
	//wire wb_ack;
	assign wb_ack_o = wb_cyc_i & wb_stb_i;
	//////////delay outputs//////////////
	/*always @(posedge wb_clk_i or negedge wb_rst_i)
		if (wb_rst_i == `RstEnable)
			wb_ack_o <= #1 1'b0;
		else
			wb_ack_o <= #1 wb_ack & ~wb_ack_o;*/
	/////////////////////////////////////
	//assign wb_ack_o = wb_ack;

endmodule