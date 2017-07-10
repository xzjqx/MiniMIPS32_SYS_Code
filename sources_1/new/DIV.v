`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/07/09 16:52:50
// Design Name: 
// Module Name: DIV
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

module DIV(

	input wire					    clk,
	input wire						rst,
	
	input wire                      signed_div_i,
	input wire[31:0]                opdata1_i,
	input wire[31:0]		   		opdata2_i,
	input wire                      start_i,	
	output reg[63:0]                result_o,
	output reg			            ready_o
);

	wire[34:0] div_temp;
	wire[34:0] div_temp0;
	wire[34:0] div_temp1;
	wire[34:0] div_temp2;
	wire[34:0] div_temp3;
	wire[1:0]  mul_cnt;
	reg[5:0] cnt;
	reg[65:0] dividend;
	reg[1:0] state;
	reg[33:0] divisor;
	reg[31:0] temp_op1;
	reg[31:0] temp_op2;
	
	wire[33:0] divisor_temp;	
	wire[33:0] divisor2;
	wire[33:0] divisor3;
	
	assign divisor_temp = temp_op2;                   
	assign divisor2     = divisor_temp << 1;       //除数的两倍，替代乘法；
	assign divisor3     = divisor2 + divisor;      //除数的三倍；
	
	assign div_temp0 = {1'b000,dividend[63:32]} - {1'b000,`ZeroWord};  //部分余数与被除数的 0 倍相减；
	assign div_temp1 = {1'b000,dividend[63:32]} - {1'b0,divisor};      //部分余数与被除数的 1 倍相减；
	assign div_temp2 = {1'b000,dividend[63:32]} - {1'b0,divisor2};     //部分余数与被除数的 2 倍相减；
	assign div_temp3 = {1'b000,dividend[63:32]} - {1'b0,divisor3};     //部分余数与被除数的 3 倍相减；
	
	assign div_temp  = (div_temp3[34] == 1'b0 ) ? div_temp3 : 
	                   (div_temp2[34] == 1'b0 ) ? div_temp2 : div_temp1;
	                  
	assign mul_cnt   = (div_temp3[34] == 1'b0 ) ? 2'b11 : 
	                   (div_temp2[34] == 1'b0 ) ? 2'b10 : 2'b01;
	
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			state <= `DivFree;
			ready_o <= `DivResultNotReady;
			result_o <= {`ZeroWord,`ZeroWord};
		end else begin
		  case (state)
		  	`DivFree:			begin               //DivFree
		  		if(start_i == `DivStart) begin
		  			if(opdata2_i == `ZeroWord) begin
		  				state <= `DivByZero;
		  			end else begin
		  				state <= `DivOn;
		  				cnt <= 6'b000000;
		  				if(signed_div_i == 1'b1 && opdata1_i[31] == 1'b1 ) begin
		  					temp_op1 = ~opdata1_i + 1;
		  				end else begin
		  					temp_op1 = opdata1_i;
		  				end
		  				if(signed_div_i == 1'b1 && opdata2_i[31] == 1'b1 ) begin
		  					temp_op2 = ~opdata2_i + 1;
		  				end else begin
		  					temp_op2 = opdata2_i;
		  				end
		  				dividend <= {`ZeroWord,`ZeroWord};
              dividend[31:0] <= temp_op1;
              divisor <= temp_op2;
             end
          end else begin
						ready_o <= `DivResultNotReady;
						result_o <= {`ZeroWord,`ZeroWord};
				  end          	
		  	end
		  	`DivByZero:		begin               //DivByZero
         	dividend <= {`ZeroWord,`ZeroWord};
          state <= `DivEnd;		 		
		  	end
		  	`DivOn:				begin               //DivOn
		  		if(cnt != 6'b100010) begin
                        if(div_temp[34] == 1'b1) begin
                        dividend <= {dividend[63:0] , 2'b00};
                        end else begin
                        dividend <= {div_temp[31:0] , dividend[31:0] , mul_cnt};
                        end
                    cnt <= cnt + 2;
                end else begin
                if((signed_div_i == 1'b1) && ((opdata1_i[31] ^ opdata2_i[31]) == 1'b1)) begin
                    dividend[31:0] <= (~dividend[31:0] + 1);
                end
                if((signed_div_i == 1'b1) && ((opdata1_i[31] ^ dividend[64]) == 1'b1)) begin              
                    dividend[65:34] <= (~dividend[65:34] + 1);
                end
                state <= `DivEnd;
                cnt <= 6'b000000;            	
               end
		  	end
		  	`DivEnd:			begin               //DivEnd
        	   result_o <= {dividend[65:34], dividend[31:0]};  
               ready_o <= `DivResultReady;
               if(start_i == `DivStop) begin
          	         state <= `DivFree;
					 ready_o <= `DivResultNotReady;
					 result_o <= {`ZeroWord,`ZeroWord};       	
               end		  	
		  	end
		  endcase
		end
	end

endmodule

