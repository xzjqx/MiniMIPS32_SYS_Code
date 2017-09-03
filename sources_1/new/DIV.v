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

	input  wire					    cpu_clk_75M,
	input  wire						cpu_rst_n,
	
	input  wire                     signed_div_i,
	input  wire [`RegBus 	  ]     div_opdata1,
	input  wire [`RegBus 	  ]		div_opdata2,
	input  wire                     div_start,	
	output reg  [`DoubleRegBus]     div_result,
	output reg			            div_ready
);

	wire   [34:0] 					div_temp;
	wire   [34:0] 					div_temp0;
	wire   [34:0]			 		div_temp1;
	wire   [34:0] 					div_temp2;
	wire   [34:0] 					div_temp3;
	wire   [ 1:0] 					mul_cnt;

	//记录试商法进行了几轮，当等于16时，表示试商法结束
	reg    [ 5:0] 					cnt;

	reg    [65:0] 					dividend;
	reg    [ 1:0] 					state;
	reg    [33:0] 					divisor;
	reg    [31:0] 					temp_op1;
	reg    [31:0] 					temp_op2;
	
	wire   [33:0] 					divisor_temp;	
	wire   [33:0] 					divisor2;
	wire   [33:0] 					divisor3;
	
	assign divisor_temp = temp_op2;                   
	assign divisor2     = divisor_temp << 1;       //除数的两倍，替代乘法；
	assign divisor3     = divisor2 + divisor;      //除数的三倍；
	
	//dividend的低32位保存的是被除数、中间结果，第k次迭代结束的时候dividend[k:0]  
	//保存的就是当前得到的中间结果，dividend[32:k+1]保存的就是被除数中还没有参与运算  
	//的数据，dividend高32位是每次迭代时的被减数
	assign div_temp0 = {1'b000,dividend[63:32]} - {1'b000,`ZeroWord};  //部分余数与被除数的 0 倍相减；
	assign div_temp1 = {1'b000,dividend[63:32]} - {1'b0,divisor};      //部分余数与被除数的 1 倍相减；
	assign div_temp2 = {1'b000,dividend[63:32]} - {1'b0,divisor2};     //部分余数与被除数的 2 倍相减；
	assign div_temp3 = {1'b000,dividend[63:32]} - {1'b0,divisor3};     //部分余数与被除数的 3 倍相减；
	
	assign div_temp  = (div_temp3[34] == 1'b0 ) ? div_temp3 : 
	                   (div_temp2[34] == 1'b0 ) ? div_temp2 : div_temp1;
	                  
	assign mul_cnt   = (div_temp3[34] == 1'b0 ) ? 2'b11 : 
	                   (div_temp2[34] == 1'b0 ) ? 2'b10 : 2'b01;
	
	always @ (posedge cpu_clk_75M) begin
		if (cpu_rst_n == `RstEnable) begin
			state 		<= `DivFree;
			div_ready 	<= `DivResultNotReady;
			div_result 	<= {`ZeroWord,`ZeroWord};
		end else begin
		  case (state)
	//*******************   DivFree状态    ***********************  
    //分三种情况：  
    //（1）开始除法运算，但除数为0，那么进入DivByZero状态  
    //（2）开始除法运算，且除数不为0，那么进入DivOn状态，初始化cnt为0，如  
    //     果是有符号除法，且被除数或者除数为负，那么对被除数或者除数取补码。  
    //     除数保存到divisor中，将被除数的最高位保存到dividend的第32位，  
    //     准备进行第一次迭代  
    //（3）没有开始除法运算，保持div_ready为DivResultNotReady，保持  
    //    div_result为0  
    //*********************************************************** 
		  	`DivFree:			begin               		//DivFree
		  		if(div_start == `DivStart) begin
		  			if(div_opdata2 == `ZeroWord) begin		// 除数为0
		  				state <= `DivByZero;
		  			end else begin							// 除数为0
		  				state <= `DivOn;
		  				cnt   <= 6'b000000;
		  				if(signed_div_i == 1'b1 && div_opdata1[31] == 1'b1 ) begin
		  					temp_op1 = ~div_opdata1 + 1;	// 被除数取补码
		  				end else begin
		  					temp_op1 = div_opdata1;
		  				end
		  				if(signed_div_i == 1'b1 && div_opdata2[31] == 1'b1 ) begin
		  					temp_op2 = ~div_opdata2 + 1;	// 除数取补码
		  				end else begin
		  					temp_op2 = div_opdata2;
		  				end
		  				dividend <= {`ZeroWord,`ZeroWord};
              dividend[31:0] <= temp_op1;
              divisor 		 <= temp_op2;
             end
          end else begin	 // 没有开始除法运算
						div_ready  <= `DivResultNotReady;
						div_result <= {`ZeroWord,`ZeroWord};
				  end          	
		  	end

	//*******************   DivByZero状态    ********************  
    //如果进入DivByZero状态，那么直接进入DivEnd状态，除法结束，且结果为0  
    //*********************************************************** 
		  	`DivByZero:		begin               //DivByZero
         		dividend <= {`ZeroWord,`ZeroWord};
          		state    <= `DivEnd;		 		
		  	end

    //*******************   DivOn状态      ***********************  
    //（1）如果cnt不为16，那么表示试商法还没有结束，此时  
    //    如果减法结果div_temp为负，那么此次迭代结果是0；如  
    //    果减法结果div_temp为正，那么此次迭代结果是1，dividend  
	//    的最低位保存每次的迭代结果。同时保持DivOn状态，cnt加1。  
	//（2）如果cnt为16，那么表示试商法结束，如果是有符号  
	//    除法，且被除数、除数一正一负，那么将试商法的结果取补码，得到最终的  
	//    结果，此处的商、余数都要取补码。商保存在dividend的低32位，余数  
	//    保存在dividend的高32位。同时进入DivEnd状态。  
	//***********************************************************
		  	`DivOn:				begin               //DivOn
		  		if(cnt != 6'b100010) begin	//cnt不为16，表示试商法还没有结束
                        if(div_temp[34] == 1'b1) begin
                        //如果div_temp[32]为1，表示（minuend-n）结果小于0，  
              			//将dividend向左移一位，这样就将被除数还没有参与运算的  
              			//最高位加入到下一次迭代的被减数中，同时将0追加到中间结果
                        dividend <= {dividend[63:0] , 2'b00};
                        end else begin
                        //如果div_temp[32]为0，表示（minuend-n）结果大于等  
		              	//于0，将减法的结果与被除数还没有参运算的最高位加入到下  
		              	//一次迭代的被减数中，同时将1追加到中间结果 
                        dividend <= {div_temp[31:0] , dividend[31:0] , mul_cnt};
                        end
                    cnt <= cnt + 2;
                end else begin	//试商法结束
                if((signed_div_i == 1'b1) && ((div_opdata1[31] ^ div_opdata2[31]) == 1'b1)) begin
                    dividend[31:0] <= (~dividend[31:0] + 1);	//求补码
                end
                if((signed_div_i == 1'b1) && ((div_opdata1[31] ^ dividend[65]) == 1'b1)) begin              
                    dividend[65:34] <= (~dividend[65:34] + 1);	//求补码
                end
                state <= `DivEnd;		//进入DivEnd状态 
                cnt   <= 6'b000000;       //cnt清零     	
               end
		  	end

	 //*******************   DivEnd状态    ***********************  
     //除法运算结束，div_result的宽度是64位，其高32位存储余数，低32位存储商，  
     //设置输出信号div_ready为DivResultReady，表示除法结束，然后等待EX模块  
     //送来DivStop信号，当EX模块送来DivStop信号时，DIV模块回到DivFree  
     //状态  
     //********************************************************** 
		  	`DivEnd:			begin               //DivEnd
        	   div_result <= {dividend[65:34], dividend[31:0]};  
               div_ready  <= `DivResultReady;
               if(div_start == `DivStop) begin
          	         state 		<= `DivFree;
					 div_ready 	<= `DivResultNotReady;
					 div_result <= {`ZeroWord,`ZeroWord};       	
               end		  	
		  	end
		  endcase
		end
	end

endmodule

