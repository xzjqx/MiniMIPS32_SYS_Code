`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/25 17:21:34
// Design Name: 
// Module Name: MiniMIPS32_SYS_tb
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


module MiniMIPS32_SYS_tb;

	// Inputs
	reg clk_init;
	reg rst_init;
	reg [7:0] switch;
	
	MiniMIPS32_SYS SoC (
		.clk_init(clk_init),
		.rst_init(rst_init),
		
		.switch(switch)
	);
	
	initial begin
		// Initialize Inputs
		clk_init = 0;
		rst_init = 0;
		switch = 8'h3d;
		
		rst_init = 1'b0;
		#50 
		#1000
		rst_init = 1'b1;
		
		#100000 $stop;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
	
	initial begin
	  clk_init = 1'b0;
	  forever #5 clk_init  = ~clk_init ;
	end

endmodule
