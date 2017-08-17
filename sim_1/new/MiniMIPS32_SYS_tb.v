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
	reg sys_clk_100M;
	reg sys_rst_n;
	reg [7:0] switch;
	reg [3:0] btn_key_row;
	
	//outputs
	wire [3:0] btn_key_col;
	
	MiniMIPS32_SYS SoC (
		.sys_clk_100M(sys_clk_100M),
		.sys_rst_n(sys_rst_n),
		
		.switch(switch),
		.btn_key_row(btn_key_row),
		.btn_key_col(btn_key_col)
	);
	
	initial begin
		// Initialize Inputs
		sys_clk_100M = 0;
		sys_rst_n = 0;
		switch = 8'h3d;
		
		sys_rst_n = 1'b0;
		#50 
		#1000
		sys_rst_n = 1'b1;
		
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
	  sys_clk_100M = 1'b0;                 // 每隔5ns，sys_clk_100M信号翻转一次，所以一个周期是10ns，对应100MHz
	  forever #5 sys_clk_100M  = ~sys_clk_100M ;
	end

endmodule
