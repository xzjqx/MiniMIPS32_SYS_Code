`timescale 1ns / 1ps    // 时间单位是1ns，精度是1ps 
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
	reg [3:0] btn_key_row;
	
	//outputs
	wire [3:0] btn_key_col;
	
	MiniMIPS32_SYS SoC (
		.clk_init(clk_init),
		.rst_init(rst_init),
		
		.switch(switch),
		.btn_key_row(btn_key_row),
		.btn_key_col(btn_key_col)
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
		
		#5000
		btn_key_row = 4'b1110;
		
		#10000
		btn_key_row = 4'b0111;
		
		#100000 $stop;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
	
	initial begin
	  clk_init = 1'b0;                 // 每隔5ns，clk_init信号翻转一次，所以一个周期是10ns，对应100MHz
	  forever #5 clk_init  = ~clk_init ;
	end

endmodule
