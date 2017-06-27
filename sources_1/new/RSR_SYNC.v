`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 16:14:31
// Design Name: 
// Module Name: RSR_SYNC
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


module RST_SYNC(
	input wire clk_sys,
	input wire rst_in,
	output wire rst
	);

	reg rst_nr1,rst_nr2;
	assign rst = rst_nr2;

	always@(posedge clk_sys or negedge rst_in)
	begin
		if(!rst_in) begin
			rst_nr1 <=1'b0;
			rst_nr2 <=1'b0;
		end else begin
			rst_nr1 <=1'b1;
			rst_nr2 <= rst_nr1;
		end
	end

endmodule

