`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/07/08 14:59:45
// Design Name: 
// Module Name: decoder
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

`define AddrIsOrder(addr) (addr[15:0] == 16'h1160)
`define AddrIsLed(addr) (addr[15:0] == 16'hf000)
`define AddrIsLedRg0(addr) (addr[15:0] == 16'hf004)
`define AddrIsLedRg1(addr) (addr[15:0] == 16'hf008)
`define AddrIsNum(addr) (addr[15:0] == 16'hf010)
`define AddrIsSwitch(addr) (addr[15:0] == 16'hf020)
`define AddrIsBtnKey(addr) (addr[15:0] == 16'hf024)
`define AddrIsBtnStep(addr) (addr[15:0] == 16'hf028)
`define AddrIsTimer(addr) (addr[15:0] == 16'he000)

module decoder(
	wb_clk_i, wb_rst_i, wb_cyc_i, wb_adr_i, wb_dat_i, wb_sel_i, wb_we_i, wb_stb_i,
	wb_dat_o, wb_ack_o,

	led, led_rg0, led_rg1, num_csn, num_a_g, switch, btn_key_col, btn_key_row, btn_step
    );
    
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
    
    output 	[15:0]		led;
	output  [1:0] 		led_rg0;
	output  [1:0] 		led_rg1;
	output	[7:0]		num_csn;
	output	[6:0]		num_a_g;
    input   [7:0] 		switch;
    output  [3:0] 		btn_key_col;
    input	[3:0]		btn_key_row;
    input	[1:0] 		btn_step;
    
    ////////////////////////////
	wire [31:0] addr = wb_adr_i;
	
	wire led_we = wb_we_i && `AddrIsLed(addr);
	wire led_rg0_we = wb_we_i && `AddrIsLedRg0(addr); 
	wire led_rg1_we = wb_we_i && `AddrIsLedRg1(addr); 
	
	reg [31:0] led_data;
	assign led = led_data[15:0];
	reg [31:0] led_rg0_data;
	assign led_rg0 = led_rg0_data[1:0];
	reg [31:0] led_rg1_data;
	assign led_rg1 = led_rg1_data[1:0];
	
	assign wb_ack_o = wb_cyc_i & wb_stb_i;
	always @(posedge wb_clk_i or negedge wb_rst_i) begin
		if(wb_rst_i == `RstEnable) begin
			led_data <= `ZeroWord;
			led_rg0_data <= `ZeroWord;
			led_rg1_data <= `ZeroWord;
		end
		else begin
			case({led_we,led_rg0_we,led_rg1_we})
				3'b100: led_data <= wb_dat_i;
				3'b010: led_rg0_data <= wb_dat_i;
				3'b001: led_rg1_data <= wb_dat_i;
			endcase
		end
	end 
    
endmodule
