`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 16:12:44
// Design Name: 
// Module Name: CPU
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


module CPU(
	input wire clk_init,
	input wire rst_init,
	output wire clk5mhz,
	output wire rst,
	output wire rstn,
	output wire clk20mhz,
	output wire clk100mhz
    );

	assign rst = rst_init;
	assign rstn = ~rst_init;
	
	clk_wiz_0 clocking
	 (
	  // Clock out ports
	  .clk_out1(clk5mhz),     // output clk_out1
	  .clk_out2(clk20mhz),     // output clk_out2
	  .clk_out3(clk100mhz),     // output clk_out3
	 // Clock in ports
	  .clk_in1(clk_init));      // input clk_in1

endmodule

