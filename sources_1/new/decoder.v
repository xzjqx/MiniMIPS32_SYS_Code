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
	output	reg [7:0]	num_csn;
	output	reg [6:0]	num_a_g;
    input   [7:0] 		switch;
    output  [3:0] 		btn_key_col;
    input	[3:0]		btn_key_row;
    input	[1:0] 		btn_step;
    
    assign wb_ack_o = wb_cyc_i & wb_stb_i;
    ////////////////////////////
    wire [31:0] switch_data = {24'b0, switch};
    wire [31:0] btn_key_data = {28'b0, btn_key_row};
    wire [31:0] btn_step_data = {30'b0, btn_step};
	wire [31:0] addr = wb_adr_i;
	
	assign wb_dat_o = `AddrIsSwitch(addr) ? switch_data :
					  `AddrIsBtnKey(addr) ? btn_key_data :
					  `AddrIsBtnStep(addr) ? btn_step_data : 32'h00000000;
	
	wire led_we = wb_we_i && `AddrIsLed(addr);
	wire led_rg0_we = wb_we_i && `AddrIsLedRg0(addr); 
	wire led_rg1_we = wb_we_i && `AddrIsLedRg1(addr); 
	wire num_we = wb_we_i && `AddrIsNum(addr); 
	
	reg [31:0] led_data;
	assign led = led_data[15:0];
	reg [31:0] led_rg0_data;
	assign led_rg0 = led_rg0_data[1:0];
	reg [31:0] led_rg1_data;
	assign led_rg1 = led_rg1_data[1:0];
	reg [31:0] num_data;
	
	always @(posedge wb_clk_i or negedge wb_rst_i) begin
		if(wb_rst_i == `RstEnable) begin
			led_data <= `ZeroWord;
			led_rg0_data <= `ZeroWord;
			led_rg1_data <= `ZeroWord;
			num_data <= `ZeroWord;
		end
		else begin
			case({led_we,led_rg0_we,led_rg1_we,num_we})
				4'b1000: led_data <= wb_dat_i;
				4'b0100: led_rg0_data <= wb_dat_i;
				4'b0010: led_rg1_data <= wb_dat_i;
				4'b0001: num_data <= wb_dat_i;
			endcase
		end
	end 
	
	reg [19:0] div_counter;
	always @(posedge wb_clk_i or negedge wb_rst_i) begin 
	    if(wb_rst_i == `RstEnable) begin
	       div_counter <= 0;
	    end
		else begin
			div_counter <= div_counter + 1;
		end
	end
	
    parameter[2:0] SEG1 = 3'b000,
	               SEG2 = 3'b001,
	               SEG3 = 3'b010,
	               SEG4 = 3'b011,
	               SEG5 = 3'b100,
	               SEG6 = 3'b101,
	               SEG7 = 3'b110,
	               SEG8 = 3'b111;
	                
	reg [2:0] state;
	reg [3:0] value;
    always @(posedge wb_clk_i or negedge wb_rst_i) begin
	    if(wb_rst_i == `RstEnable) begin
	        num_csn <= 8'b11111111;
	        value <= 4'b0;
	    end else begin
	        case(div_counter[19:17])
	            SEG1: begin
	                value <= num_data[31:28];
	                num_csn <= 8'b01111111;
	            end
	            SEG2: begin
	                value <= num_data[27:24];
	                num_csn <= 8'b10111111;
	            end
	            SEG3: begin
	                value <= num_data[23:20];
	                num_csn <= 8'b11011111;
	            end
	            SEG4: begin
	                value <= num_data[19:16];
	                num_csn <= 8'b11101111;
	            end
	            SEG5: begin
	                value <= num_data[15:12];
	                num_csn <= 8'b11110111;
	            end
	            SEG6: begin
	                value <= num_data[11:8];
	                num_csn <= 8'b11111011;
	            end
	            SEG7: begin
	                value <= num_data[7:4];
	                num_csn <= 8'b11111101;
	            end
	            SEG8: begin
	                value <= num_data[3:0];
	                num_csn <= 8'b11111110;
	            end
	            default: begin
	            end
	        endcase
	     end
	end
	
    always @(posedge wb_clk_i or negedge wb_rst_i) begin
    	if(wb_rst_i == `RstEnable)
    		num_a_g <= 7'b0000000;
    	else begin
			case(value)
				4'd0 : num_a_g <= 7'b1111110;   //0
				4'd1 : num_a_g <= 7'b0110000;   //1
				4'd2 : num_a_g <= 7'b1101101;   //2
				4'd3 : num_a_g <= 7'b1111001;   //3
				4'd4 : num_a_g <= 7'b0110011;   //4
				4'd5 : num_a_g <= 7'b1011011;   //5
				4'd6 : num_a_g <= 7'b1011111;   //6
				4'd7 : num_a_g <= 7'b1110000;   //7
				4'd8 : num_a_g <= 7'b1111111;   //8
				4'd9 : num_a_g <= 7'b1111011;   //9
				4'd10: num_a_g <= 7'b1110111;   //a
				4'd11: num_a_g <= 7'b0011111;   //b
				4'd12: num_a_g <= 7'b1001110;   //c
				4'd13: num_a_g <= 7'b0111101;   //d
				4'd14: num_a_g <= 7'b1001111;   //e
				4'd15: num_a_g <= 7'b1000111;   //f
				default : num_a_g <= 7'b1111111;
			endcase
		end
	end
    
endmodule
