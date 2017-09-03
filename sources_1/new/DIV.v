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

	//��¼���̷������˼��֣�������16ʱ����ʾ���̷�����
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
	assign divisor2     = divisor_temp << 1;       //����������������˷���
	assign divisor3     = divisor2 + divisor;      //������������
	
	//dividend�ĵ�32λ������Ǳ��������м�������k�ε���������ʱ��dividend[k:0]  
	//����ľ��ǵ�ǰ�õ����м�����dividend[32:k+1]����ľ��Ǳ������л�û�в�������  
	//�����ݣ�dividend��32λ��ÿ�ε���ʱ�ı�����
	assign div_temp0 = {1'b000,dividend[63:32]} - {1'b000,`ZeroWord};  //���������뱻������ 0 �������
	assign div_temp1 = {1'b000,dividend[63:32]} - {1'b0,divisor};      //���������뱻������ 1 �������
	assign div_temp2 = {1'b000,dividend[63:32]} - {1'b0,divisor2};     //���������뱻������ 2 �������
	assign div_temp3 = {1'b000,dividend[63:32]} - {1'b0,divisor3};     //���������뱻������ 3 �������
	
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
	//*******************   DivFree״̬    ***********************  
    //�����������  
    //��1����ʼ�������㣬������Ϊ0����ô����DivByZero״̬  
    //��2����ʼ�������㣬�ҳ�����Ϊ0����ô����DivOn״̬����ʼ��cntΪ0����  
    //     �����з��ų������ұ��������߳���Ϊ������ô�Ա��������߳���ȡ���롣  
    //     �������浽divisor�У��������������λ���浽dividend�ĵ�32λ��  
    //     ׼�����е�һ�ε���  
    //��3��û�п�ʼ�������㣬����div_readyΪDivResultNotReady������  
    //    div_resultΪ0  
    //*********************************************************** 
		  	`DivFree:			begin               		//DivFree
		  		if(div_start == `DivStart) begin
		  			if(div_opdata2 == `ZeroWord) begin		// ����Ϊ0
		  				state <= `DivByZero;
		  			end else begin							// ����Ϊ0
		  				state <= `DivOn;
		  				cnt   <= 6'b000000;
		  				if(signed_div_i == 1'b1 && div_opdata1[31] == 1'b1 ) begin
		  					temp_op1 = ~div_opdata1 + 1;	// ������ȡ����
		  				end else begin
		  					temp_op1 = div_opdata1;
		  				end
		  				if(signed_div_i == 1'b1 && div_opdata2[31] == 1'b1 ) begin
		  					temp_op2 = ~div_opdata2 + 1;	// ����ȡ����
		  				end else begin
		  					temp_op2 = div_opdata2;
		  				end
		  				dividend <= {`ZeroWord,`ZeroWord};
              dividend[31:0] <= temp_op1;
              divisor 		 <= temp_op2;
             end
          end else begin	 // û�п�ʼ��������
						div_ready  <= `DivResultNotReady;
						div_result <= {`ZeroWord,`ZeroWord};
				  end          	
		  	end

	//*******************   DivByZero״̬    ********************  
    //�������DivByZero״̬����ôֱ�ӽ���DivEnd״̬�������������ҽ��Ϊ0  
    //*********************************************************** 
		  	`DivByZero:		begin               //DivByZero
         		dividend <= {`ZeroWord,`ZeroWord};
          		state    <= `DivEnd;		 		
		  	end

    //*******************   DivOn״̬      ***********************  
    //��1�����cnt��Ϊ16����ô��ʾ���̷���û�н�������ʱ  
    //    ����������div_tempΪ������ô�˴ε��������0����  
    //    ���������div_tempΪ������ô�˴ε��������1��dividend  
	//    �����λ����ÿ�εĵ��������ͬʱ����DivOn״̬��cnt��1��  
	//��2�����cntΪ16����ô��ʾ���̷�������������з���  
	//    �������ұ�����������һ��һ������ô�����̷��Ľ��ȡ���룬�õ����յ�  
	//    ������˴����̡�������Ҫȡ���롣�̱�����dividend�ĵ�32λ������  
	//    ������dividend�ĸ�32λ��ͬʱ����DivEnd״̬��  
	//***********************************************************
		  	`DivOn:				begin               //DivOn
		  		if(cnt != 6'b100010) begin	//cnt��Ϊ16����ʾ���̷���û�н���
                        if(div_temp[34] == 1'b1) begin
                        //���div_temp[32]Ϊ1����ʾ��minuend-n�����С��0��  
              			//��dividend������һλ�������ͽ���������û�в��������  
              			//���λ���뵽��һ�ε����ı������У�ͬʱ��0׷�ӵ��м���
                        dividend <= {dividend[63:0] , 2'b00};
                        end else begin
                        //���div_temp[32]Ϊ0����ʾ��minuend-n��������ڵ�  
		              	//��0���������Ľ���뱻������û�в���������λ���뵽��  
		              	//һ�ε����ı������У�ͬʱ��1׷�ӵ��м��� 
                        dividend <= {div_temp[31:0] , dividend[31:0] , mul_cnt};
                        end
                    cnt <= cnt + 2;
                end else begin	//���̷�����
                if((signed_div_i == 1'b1) && ((div_opdata1[31] ^ div_opdata2[31]) == 1'b1)) begin
                    dividend[31:0] <= (~dividend[31:0] + 1);	//����
                end
                if((signed_div_i == 1'b1) && ((div_opdata1[31] ^ dividend[65]) == 1'b1)) begin              
                    dividend[65:34] <= (~dividend[65:34] + 1);	//����
                end
                state <= `DivEnd;		//����DivEnd״̬ 
                cnt   <= 6'b000000;       //cnt����     	
               end
		  	end

	 //*******************   DivEnd״̬    ***********************  
     //�������������div_result�Ŀ����64λ�����32λ�洢��������32λ�洢�̣�  
     //��������ź�div_readyΪDivResultReady����ʾ����������Ȼ��ȴ�EXģ��  
     //����DivStop�źţ���EXģ������DivStop�ź�ʱ��DIVģ��ص�DivFree  
     //״̬  
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

