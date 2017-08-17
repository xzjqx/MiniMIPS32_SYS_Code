`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 16:45:08
// Design Name: 
// Module Name: EX
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

module EX(
	input wire 			rst,

	// 译码阶段送到执行阶段的信息
	input wire [2:0] 	alusel_i,
	input wire [7:0] 	aluop_i,
	input wire [31:0]   pc_i,
	output wire [31:0]  pc_o,
	input wire [31:0] 	reg1_i,
	input wire [31:0] 	reg2_i,
	input wire [4:0] 	wd_i,
	input wire 			wreg_i,
	
	// HILO模块给出的HI、LO寄存器的值 
	input wire [31:0] 	hi_i,
	inout wire [31:0] 	lo_i,

	// 访存阶段的指令是否要写HI、LO，用于检测HI、LO寄存器带来的数据相关问题
	input wire 			mem_whilo_i,
	input wire [31:0] 	mem_hi_i,
	input wire [31:0] 	mem_lo_i,

	// 回写阶段的指令是否要写HI、LO，用于检测HI、LO寄存器带来的数据相关问题 
	input wire 			wb_whilo_i,
	input wire [31:0] 	wb_hi_i,
	input wire [31:0] 	wb_lo_i,
	
	// 当前执行阶段的指令是否位于延迟槽
	input wire 			in_delay_i,
	output wire			in_delay_o,

	// 处于执行阶段的转移指令要保存的返回地址
	input wire [31:0] 	link_addr_i,
	
	//新增输入接口inst_i，其值就是当前处于执行阶段的指令
	input wire [31:0] 	inst_i,
	
	input wire		  	mem_cp0_we,
	input wire [4:0]	mem_cp0_waddr,
	input wire [31:0]	mem_cp0_wdata,	

	input wire[31:0]    cp0_reg_read_data_i,
	output wire[4:0]     cp0_reg_read_addr_o,

	output wire          cp0_reg_we_o,
	output wire[4:0]     cp0_reg_waddr_o,
	output wire[31:0] 	cp0_reg_wdata_o,

	// 执行的结果
	output wire [4:0] 	wd_o,
	output wire 			wreg_o,
	output wire [31:0] 	wdata_o,
	
	// 处于执行阶段的指令对HI、LO寄存器的写操作请求
	output wire 			whilo_o,
	output wire [31:0] 	hi_o,
	output wire [31:0] 	lo_o,
	
	//为加载、存储指令准备的输出接口
	output wire [7:0] 	aluop_o,
	output wire [31:0] 	mem_addr_o,
	output wire [31:0] 	reg2_o,
	
	input wire [`EXC_CODE_WIDTH-1:0]exc_code_i,
	input wire [31:0] exc_epc_i,
	input wire [31:0] exc_badvaddr_i,
	
	output wire [`EXC_CODE_WIDTH-1:0]exc_code_o,
	output wire [31:0] exc_epc_o,
	output wire [31:0] exc_badvaddr_o,
	
	output wire cp0_reg_read_o,
	
	
	// 来自除法模块的输入
	input wire[`DoubleRegBus]     div_result_i,
    input wire                    div_ready_i,

    // 到除法模块的输出
    output wire[`RegBus]           div_opdata1_o,
    output wire[`RegBus]           div_opdata2_o,
    output wire                    div_start_o,
    output wire                    signed_div_o,
    output stop
    );
    
    assign in_delay_o = in_delay_i;
    assign pc_o = pc_i;
	
	wire[31:0] signed_low16_inst;
	assign signed_low16_inst = { {16{inst_i[15]}}, inst_i[15:0] };

	wire[31:0] logicout;		// 保存逻辑运算的结果
	wire[31:0] shiftout;		// 保存移位运算结果
	wire[31:0] moveout;		// 移动操作的结果
	wire[31:0] hi_t;			// 保存HI寄存器的最新值
	wire[31:0] lo_t;			// 保存LO寄存器的最新值
	reg[63:0] arithout;
	wire[31:0] cp0out;
	
	wire stallreq_for_div;	 // 是否由于除法运算导致流水线暂停 
	assign stop = stallreq_for_div;

	//aluop_o会传递到访存阶段，届时将利用其确定加载、存储类型
	assign aluop_o = aluop_i;
	assign reg2_o = reg2_i;
  
  	/*
	always @(*)begin
		if (rst==`RstEnable) begin
			exc_badvaddr_o <= 0;
		end else begin
			exc_badvaddr_o <= exc_badvaddr_i;
		end
	end
	*/
	assign exc_badvaddr_o = (rst==`RstEnable) ? 0 : exc_badvaddr_i;

	/*
	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_reg_we_o <= 1'b0;
			cp0_reg_wdata_o <= 32'h00000000;
			cp0_reg_waddr_o <= 5'b00000;
			cp0_reg_read_addr_o <= 5'b00000;
			cp0_reg_read_o <= 1'b0;
			cp0out <= `ZeroWord;
		end else begin
			case (aluop_i)
				`MFC0: begin
					cp0_reg_read_o <= 1'b1;
					cp0_reg_read_addr_o <= inst_i[15:11];
					cp0_reg_we_o <= 1'b0;
					cp0_reg_wdata_o <= 32'h00000000;
					cp0_reg_waddr_o <= 5'b00000;
					cp0out <= cp0_reg_read_data_i;
				end
				`MTC0: begin
					cp0_reg_read_o <= 1'b0;
					cp0_reg_read_addr_o <= 5'b00000;
					cp0_reg_we_o <= 1'b1;
					cp0_reg_waddr_o <= inst_i[15:11];
					cp0_reg_wdata_o <= reg1_i;
					cp0out <= `ZeroWord;
				end
				default: begin
					cp0_reg_we_o <= 1'b0;
					cp0_reg_wdata_o <= 32'h00000000;
					cp0_reg_waddr_o <= 5'b00000;
					cp0_reg_read_addr_o <= 5'b00000;
					cp0_reg_read_o <= 1'b0;
					cp0out <= `ZeroWord;
				end
			endcase
		end
	end
	*/
	
	assign cp0_reg_we_o = (rst == `RstEnable) ? 1'b0 : 
						  (aluop_i == `MFC0)  ? 1'b0 :
						  (aluop_i == `MTC0)  ? 1'b1 : 1'b0;

	assign cp0_reg_wdata_o = (rst == `RstEnable) ? 32'h00000000 : 
						  (aluop_i == `MFC0)  ? 32'h00000000 :
						  (aluop_i == `MTC0)  ? reg1_i : 32'h00000000;
    assign cp0_reg_waddr_o = (rst == `RstEnable) ? 5'b00000 : 
						  (aluop_i == `MFC0)  ? 5'b00000 :
						  (aluop_i == `MTC0)  ? inst_i[15:11] : 5'b00000;
	assign cp0_reg_read_addr_o = (rst == `RstEnable) ? 5'b00000 : 
						  (aluop_i == `MFC0)  ? inst_i[15:11] :
						  (aluop_i == `MTC0)  ? 5'b00000 : 5'b00000;
	assign cp0_reg_read_o = (rst == `RstEnable) ? 1'b0 : 
						  (aluop_i == `MFC0)  ? 1'b1 :
						  (aluop_i == `MTC0)  ? 1'b0 : 1'b0;
	assign cp0out = (rst == `RstEnable) ? `ZeroWord : 
						  (aluop_i == `MFC0)  ? cp0_reg_read_data_i :
						  (aluop_i == `MTC0)  ? `ZeroWord : `ZeroWord;

	
	// 8/8 logic instructions=====================================================
	/*
	always @ (*) begin
		if (rst == `RstEnable) begin
			logicout <= `ZeroWord;
		end else begin
			case (aluop_i)
				`AND: begin
					logicout <= reg1_i & reg2_i;
				end
				`ANDI: begin                   // immdiate should be load to reg2_i
					logicout <= reg1_i & reg2_i;
				end
				`LUI: begin                    // immdiate should be load to reg1_i
					logicout <= {reg1_i[15:0], 16'b0};
				end
				`NOR: begin
					logicout <= ~(reg1_i | reg2_i);
				end
				`OR: begin
					logicout <= reg1_i | reg2_i;
				end
				`ORI: begin                    // immdiate should be load to reg2_i
					logicout <= reg1_i | reg2_i;
				end
				`XOR: begin
					logicout <= reg1_i ^ reg2_i;
				end
				`XORI: begin                   // immdiate should be load to reg2_i
					logicout <= reg1_i ^ reg2_i;
				end
				default: begin
					logicout <= `ZeroWord;
				end
			endcase
		end
	end
	*/
	
	assign logicout = (rst == `RstEnable) ? `ZeroWord : 
						  (aluop_i == `AND)  ? (reg1_i & reg2_i) :
						  (aluop_i == `ANDI)  ? (reg1_i & reg2_i) :
						  (aluop_i == `LUI)  ? ({reg1_i[15:0], 16'b0}) :
						  (aluop_i == `NOR)  ? (~(reg1_i | reg2_i)) :
						  (aluop_i == `OR)  ? (reg1_i | reg2_i) :
						  (aluop_i == `ORI)  ? (reg1_i | reg2_i) :
						  (aluop_i == `XOR)  ? (reg1_i ^ reg2_i) :
						  (aluop_i == `XORI)  ? (reg1_i ^ reg2_i) : `ZeroWord;
	

	// 6/6 shift word instructions================================================
	/*
	always @ (*) begin
		if (rst == `RstEnable) begin
			shiftout <= 32'b0;
		end else begin
			case (aluop_i)
				`SLL: begin
					shiftout <= reg1_i << reg2_i;
				end
				`SLLV: begin                 // reg2_i should be 0 at [31:5]
					shiftout <= reg1_i << reg2_i;
				end
				`SRA: begin
					shiftout <= ({32{reg1_i[31]}} << (6'd32-{1'b0, reg2_i[4:0]}))
												| reg1_i >> reg2_i[4:0];
				end
				`SRAV: begin                 // reg2_i should be 0 at [31:5]
					shiftout <= ({32{reg1_i[31]}} << (6'd32-{1'b0, reg2_i[4:0]}))
												| reg1_i >> reg2_i[4:0];
				end
				`SRL: begin
					shiftout <= reg1_i >> reg2_i;
				end
				`SRLV: begin                 // reg2_i should be 0 at [31:5]
					shiftout <= reg1_i >> reg2_i;
				end
				default: begin
					shiftout <= `ZeroWord;
				end
			endcase
		end
	end
	*/
	
	assign shiftout = (rst == `RstEnable) ? `ZeroWord : 
					  (aluop_i == `SLL)  ? (reg1_i <<  reg2_i) :
					  (aluop_i == `SLLV)  ? (reg1_i <<  reg2_i) :
					  (aluop_i == `SRA)  ? (({32{reg1_i[31]}} << (6'd32-{1'b0, reg2_i[4:0]})) | reg1_i >> reg2_i[4:0]) :
					  (aluop_i == `SRAV)  ? (({32{reg1_i[31]}} << (6'd32-{1'b0, reg2_i[4:0]})) | reg1_i >> reg2_i[4:0]) :
					  (aluop_i == `SRL)  ? (reg1_i >> reg2_i) :
					  (aluop_i == `SRLV)  ? (reg1_i >> reg2_i) : `ZeroWord;
	
	// 4/6 move instructions======================================================
	//得到最新的HI、LO寄存器的值，此处要解决数据相关问题
	/*
	always @ (*) begin
		if (rst == `RstEnable) begin
			hi_t <= `ZeroWord;
			lo_t <= `ZeroWord;
		end else begin
			// 访存阶段的指令要写HI、LO寄存器
			hi_t <= (mem_whilo_i == 1'b1) ? mem_hi_i :
              (wb_whilo_i == 1'b1) ? wb_hi_i : hi_i;
			lo_t <= (mem_whilo_i == 1'b1) ? mem_lo_i :
              (wb_whilo_i == 1'b1) ? wb_lo_i : lo_i;
		end
	end
	*/
	
	assign hi_t = 	(rst == `RstEnable) ? `ZeroWord : 
					(mem_whilo_i == 1'b1) ? mem_hi_i :
              		(wb_whilo_i == 1'b1) ? wb_hi_i : hi_i;
	assign lo_t = 	(rst == `RstEnable) ? `ZeroWord : 
					(mem_whilo_i == 1'b1) ? mem_lo_i :
              		(wb_whilo_i == 1'b1) ? wb_lo_i : lo_i;
    
    /*
	always @ (*) begin
		if (rst == `RstEnable) begin
			moveout <= `ZeroWord;
		end else begin
			case (aluop_i)
				`MFHI: begin		// 如果是mfhi指令，那么将HI的值作为移动操作的结果
					moveout <= hi_t;
				end
				`MFLO: begin		// 如果是mflo指令，那么将LO的值作为移动操作的结果
					moveout <= lo_t;
				end
				default: begin
					moveout <= `ZeroWord;
				end
			endcase
		end
	end
	*/
	
	assign moveout = (rst == `RstEnable) ? `ZeroWord : 
					  (aluop_i == `MFHI)  ? hi_t :
					  (aluop_i == `MFLO)  ? lo_t : `ZeroWord;
	
	// 8/21 arithmetic instructions===============================================
	reg [32:0] tmp;
	wire [32:0] tmp_1;
	wire [32:0] tmp_2;
	wire [5:0] exc_code_tmp;
	wire [31:0] exc_epc_tmp;

	
	always @ (*) begin
		if (rst == `RstEnable) begin
			arithout <= 64'b0;
			//exc_code_tmp <= `EC_None;
			//exc_epc_tmp <= `ZeroWord;
			//exc_badvaddr_o <= `ZeroWord;
		end else begin
			//exc_code_tmp <= exc_code_i;
			//exc_epc_tmp <= exc_epc_i;
			//exc_badvaddr_o <= exc_badvaddr_i;
			case (aluop_i)
				`ADD: begin
					tmp <= {reg1_i[31],reg1_i} + {reg2_i[31],reg2_i};
					if(tmp[32] != tmp[31]) begin
						//exc_code_tmp <= `EC_Ov;
						//if(in_delay_i) //exc_epc_tmp <= pc_i -4;
						//else //exc_epc_tmp <= pc_i;
					end
					else arithout <= tmp[31:0];
				end
				`ADDI: begin
					tmp <= {reg1_i[31],reg1_i} + {reg2_i[31],reg2_i};
					if(tmp[32] != tmp[31]) begin
						//exc_code_tmp <= `EC_Ov;
						//if(in_delay_i) //exc_epc_tmp <= pc_i -4;
					    //else //exc_epc_tmp <= pc_i;
					end
					else arithout <= tmp[31:0];
				end
				`ADDIU: begin              // immdiate should be load to reg2_i
					arithout <= reg1_i + reg2_i;
				end
				`ADDU: begin
					arithout <= reg1_i + reg2_i;
				end
				`SLT: begin
					arithout <= ($signed(reg1_i) < $signed(reg2_i)) ? 64'b1 : 64'b0;
				end
				`SLTI: begin               // immdiate should be load to reg2_i
					arithout <= ($signed(reg1_i) < $signed(reg2_i)) ? 64'b1 : 64'b0;
				end
				`SLTU: begin
					arithout <= (reg1_i < reg2_i) ? 64'b1 : 64'b0;
				end
				`SLTIU: begin              // immdiate should be load to reg2_i
					arithout <= (reg1_i < reg2_i) ? 64'b1 : 64'b0;
				end
				`SUB: begin
					tmp <= {reg1_i[31],reg1_i} - {reg2_i[31],reg2_i};
					if(tmp[32] != tmp[31]) begin
						//exc_code_tmp <= `EC_Ov;
						//if(in_delay_i) //exc_epc_tmp <= pc_i -4;
					    //else //exc_epc_tmp <= pc_i;
					end
					else arithout <= tmp[31:0];
				end
				`SUBU: begin
					arithout <= reg1_i - reg2_i;
				end
				`MULT: begin
					arithout <= $signed(reg1_i) * $signed(reg2_i);
				end
				`MULTU: begin
					arithout <= {1'b0,reg1_i} * {1'b0,reg2_i};
				end
				default: begin
					arithout <= 64'b0;
				end
			endcase
		end
	end
	
	
	assign tmp_1 		= {reg1_i[31],reg1_i} + {reg2_i[31],reg2_i};
	assign tmp_2 		= {reg1_i[31],reg1_i} - {reg2_i[31],reg2_i};
	/*
	assign arithout = (rst == `RstEnable) ? 64'b0 : 
					  ((aluop_i == `ADD) && (tmp_1[32] == tmp_1[31]))  ? tmp_1[31:0] :
					  ((aluop_i == `ADDI) && (tmp_1[32] == tmp_1[31]))  ? tmp_1[31:0] :
					  (aluop_i == `ADDIU)  ? (reg1_i + reg2_i) :
					  (aluop_i == `ADDU)  ? (reg1_i + reg2_i) :
					  ((aluop_i == `SLT) && ($signed(reg1_i) < $signed(reg2_i))) ? 64'b1 :
				      ((aluop_i == `SLT) && (!($signed(reg1_i) < $signed(reg2_i)))) ? 64'b0 :					  
					  ((aluop_i == `SLTI) && ($signed(reg1_i) < $signed(reg2_i))) ? 64'b1 :
					  ((aluop_i == `SLTI) && (!($signed(reg1_i) < $signed(reg2_i)))) ? 64'b0 :
					  ((aluop_i == `SLTU)  && (reg1_i < reg2_i)) ? 64'b1 :
					  ((aluop_i == `SLTU)  && (!(reg1_i < reg2_i))) ? 64'b0 :
					  ((aluop_i == `SLTIU) && (reg1_i < reg2_i)) ? 64'b1 :
					  ((aluop_i == `SLTIU)  && (!(reg1_i < reg2_i))) ? 64'b0 :
					  ((aluop_i == `SUB) && (tmp_2[32] == tmp_2[31]))  ? tmp_2[31:0] :
					  (aluop_i == `SUBU)  ? (reg1_i - reg2_i) :
					  (aluop_i == `MULT)  ? ($signed(reg1_i) * $signed(reg2_i)) :
					  (aluop_i == `MULTU)  ? ({1'b0,reg1_i} * {1'b0,reg2_i}) : 64'b0;
	*/			  
	assign exc_code_tmp = (rst == `RstEnable) ? `EC_None : 
					  ((aluop_i == `ADD) && (tmp_1[32] != tmp_1[31]))  ? `EC_Ov :
					  ((aluop_i == `ADDI) && (tmp_1[32] != tmp_1[31]))  ? `EC_Ov :
					  ((aluop_i == `SUB) && (tmp_2[32] != tmp_2[31]))  ? `EC_Ov : exc_code_i;
	assign exc_epc_tmp = (rst == `RstEnable) ? `ZeroWord : 
					  ((aluop_i == `ADD) && (tmp_1[32] != tmp_1[31]) && (in_delay_i))  ? (pc_i -4) :
					  ((aluop_i == `ADD) && (tmp_1[32] != tmp_1[31]) && (!in_delay_i))  ? pc_i :
					  ((aluop_i == `ADDI) && (tmp_1[32] != tmp_1[31]) && (in_delay_i))  ? (pc_i -4) :
					  ((aluop_i == `ADDI) && (tmp_1[32] != tmp_1[31]) && (!in_delay_i))  ? pc_i :
					  ((aluop_i == `SUB) && (tmp_2[32] != tmp_2[31]) && (in_delay_i))  ? (pc_i -4) :
					  ((aluop_i == `SUB) && (tmp_2[32] != tmp_2[31]) && (!in_delay_i))  ? pc_i : exc_epc_i;			
			  
					  
	//div 
	//输出DIV模块控制信息，获取DIV模块给出的结果
	/*
	always @ (*) begin
        if(rst == `RstEnable) begin
            stallreq_for_div <= `NoStop;
        	div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `DivStop;
            signed_div_o <= 1'b0;
        end else begin
            stallreq_for_div <= `NoStop;
        	div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `DivStop;
            signed_div_o <= 1'b0;    
            case (aluop_i) 
                `DIV:        begin
                    if(div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o <= reg1_i;	//被除数
                        div_opdata2_o <= reg2_i;	//除数
                        div_start_o <= `DivStart;	//开始除法运算
                        signed_div_o <= 1'b1;		//有符号除法
                        stallreq_for_div <= `Stop;	//请求流水线暂停
                    end else if(div_ready_i == `DivResultReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStop;	//结束除法运算
                        signed_div_o <= 1'b1;
                        stallreq_for_div <= `NoStop;	//不再请求流水线暂停
                    end else begin                        
                        div_opdata1_o <= `ZeroWord;
                        div_opdata2_o <= `ZeroWord;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end                    
                end
                `DIVU:        begin
                    if(div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStart;
                        signed_div_o <= 1'b0;		//无符号除法
                        stallreq_for_div <= `Stop;
                    end else if(div_ready_i == `DivResultReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end else begin                        
                        div_opdata1_o <= `ZeroWord;
                        div_opdata2_o <= `ZeroWord;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end                    
                end
                default: begin
                end
            endcase
        end
    end 
    */
    
	assign stallreq_for_div = (rst == `RstEnable) ? `NoStop : 
					  ((aluop_i == `DIV) && (div_ready_i == `DivResultNotReady))  ? `Stop :
					  ((aluop_i == `DIV) && (div_ready_i == `DivResultReady))  ? `NoStop :
					  (aluop_i == `DIV)  ? `NoStop :
					  ((aluop_i == `DIVU) && (div_ready_i == `DivResultNotReady))  ? `Stop :
					  ((aluop_i == `DIVU) && (div_ready_i == `DivResultReady))  ? `NoStop :
					  (aluop_i == `DIVU)  ? `NoStop : `NoStop;
	assign div_opdata1_o = (rst == `RstEnable) ? `ZeroWord : 
					  ((aluop_i == `DIV) && (div_ready_i == `DivResultNotReady))  ? reg1_i :
					  ((aluop_i == `DIV) && (div_ready_i == `DivResultReady))  ? reg1_i :
					  (aluop_i == `DIV)  ? `ZeroWord :
					  ((aluop_i == `DIVU) && (div_ready_i == `DivResultNotReady))  ? reg1_i :
					  ((aluop_i == `DIVU) && (div_ready_i == `DivResultReady))  ? reg1_i :
					  (aluop_i == `DIVU)  ? `ZeroWord : `ZeroWord;		
	assign div_opdata2_o = (rst == `RstEnable) ? `ZeroWord : 
					  ((aluop_i == `DIV) && (div_ready_i == `DivResultNotReady))  ? reg2_i :
					  ((aluop_i == `DIV) && (div_ready_i == `DivResultReady))  ? reg2_i :
					  (aluop_i == `DIV)  ? `ZeroWord :
					  ((aluop_i == `DIVU) && (div_ready_i == `DivResultNotReady))  ? reg2_i :
					  ((aluop_i == `DIVU) && (div_ready_i == `DivResultReady))  ? reg2_i :
					  (aluop_i == `DIVU)  ? `ZeroWord : `ZeroWord;					  			  
	assign div_start_o = (rst == `RstEnable) ? `DivStop : 
					  ((aluop_i == `DIV) && (div_ready_i == `DivResultNotReady))  ? `DivStart :
					  ((aluop_i == `DIV) && (div_ready_i == `DivResultReady))  ? `DivStop :
					  (aluop_i == `DIV)  ? `DivStop :
					  ((aluop_i == `DIVU) && (div_ready_i == `DivResultNotReady))  ? `DivStart :
					  ((aluop_i == `DIVU) && (div_ready_i == `DivResultReady))  ? `DivStop :
					  (aluop_i == `DIVU)  ? `DivStop : `DivStop; 
	assign signed_div_o = (rst == `RstEnable) ? 1'b0 : 
					  ((aluop_i == `DIV) && (div_ready_i == `DivResultNotReady))  ? 1'b1 :
					  ((aluop_i == `DIV) && (div_ready_i == `DivResultReady))  ? 1'b1 :
					  (aluop_i == `DIV)  ? 1'b0 :
					  ((aluop_i == `DIVU) && (div_ready_i == `DivResultNotReady))  ? 1'b0 :
					  ((aluop_i == `DIVU) && (div_ready_i == `DivResultReady))  ? 1'b0 :
					  (aluop_i == `DIVU)  ? 1'b0: 1'b0; 					  
	
	// output general
	// 如果是mflo指令，那么将LO的值作为移动操作的结果
	/*
	always @ (*) begin
		if (rst == `RstEnable) begin
			wd_o <= 5'b0;
			wreg_o <= 1'b0;
			wdata_o <= `ZeroWord;
			exc_code_o <= `EC_None;
			exc_epc_o <= `ZeroWord;		
		end
		else begin
			wd_o <= wd_i;
			wreg_o <= wreg_i;
			exc_code_o <= exc_code_tmp;
			exc_epc_o <= exc_epc_tmp;
			case (alusel_i)
				`Logic: begin
					wdata_o <= logicout;
				end
				`Shift: begin
					wdata_o <= shiftout;
				end
				`Move: begin
					wdata_o <= moveout;
				end
				`Arithmetic: begin
					wdata_o <= arithout[31:0];
				end
				`BranchJump: begin
					wdata_o <= link_addr_i;
				end
				`Privilege: begin
					wdata_o <= cp0out;
				end
				default: begin
					wdata_o <= `ZeroWord;
				end
			endcase
		end
	end
	*/
	
	assign wd_o = (rst == `RstEnable) ? 5'b0 : wd_i;
	assign wreg_o = (rst == `RstEnable) ? 1'b0 : wreg_i;
	assign exc_code_o = (rst == `RstEnable) ? `EC_None : exc_code_tmp;
	assign exc_epc_o = (rst == `RstEnable) ? `ZeroWord : exc_epc_tmp;
	assign wdata_o = (rst == `RstEnable) ? `ZeroWord : 
					  (alusel_i == `Logic)  ? logicout :
					  (alusel_i == `Shift)  ? shiftout :
					  (alusel_i == `Move)  ? moveout :
					  (alusel_i == `Arithmetic)  ? arithout[31:0] :
					  (alusel_i == `BranchJump)  ? link_addr_i :
					  (alusel_i == `Privilege)  ? cp0out : `ZeroWord;


	// output hi lo
	/*
	always @ (*) begin
		if (rst == `RstEnable) begin
			lo_o <= `ZeroWord;
			hi_o <= `ZeroWord;
			whilo_o <= 1'b0;
		end else begin
			case (aluop_i)
				`MULT: begin
					{hi_o, lo_o} <= arithout;
					whilo_o <= 1'b1;
				end
				`MULTU: begin
					{hi_o, lo_o} <= arithout;
					whilo_o <= 1'b1;
				end 

				//如果是MTHI、MTLO指令，那么需要给出whilo_o、hi_o、lo_i的值
				`MTHI: begin
					hi_o <= reg1_i;
					lo_o <= lo_t;		// 写HI寄存器，所以LO保持不变 
					whilo_o <= 1'b1;
				end
				`MTLO: begin
					hi_o <= hi_t;		// 写LO寄存器，所以HI保持不变
					lo_o <= reg1_i;
					whilo_o <= 1'b1;
				end
				`DIV: begin
                    hi_o <= div_result_i[63:32];
                    lo_o <= div_result_i[31:0];    
                    whilo_o <= 1'b1;
                end
                `DIVU: begin
                    hi_o <= div_result_i[63:32];
                    lo_o <= div_result_i[31:0];                      
                    whilo_o <= 1'b1;
                end
				default: begin
					lo_o <= `ZeroWord;
					hi_o <= `ZeroWord;
					whilo_o <= 1'b0;
				end
			endcase
		end
	end
	*/
	
	assign lo_o = (rst == `RstEnable) ? `ZeroWord : 
					  (aluop_i == `MULT)  ? arithout[31:0] :
					  (aluop_i == `MULTU)  ? arithout[31:0] :
					  (aluop_i == `MTHI)  ? lo_t :
					  (aluop_i == `MTLO)  ? reg1_i :
					  (aluop_i == `DIV)  ? div_result_i[31:0] :
					  (aluop_i == `DIVU)  ? div_result_i[31:0] : `ZeroWord;	
	assign hi_o = (rst == `RstEnable) ? `ZeroWord : 
					  (aluop_i == `MULT)  ? arithout[63:32] :
					  (aluop_i == `MULTU)  ? arithout[63:32] :
					  (aluop_i == `MTHI)  ? reg1_i :
					  (aluop_i == `MTLO)  ? hi_t :
					  (aluop_i == `DIV)  ? div_result_i[63:32] :
					  (aluop_i == `DIVU)  ? div_result_i[63:32] : `ZeroWord;	
	assign whilo_o = (rst == `RstEnable) ? 1'b0 : 
					  (aluop_i == `MULT)  ? 1'b1 :
					  (aluop_i == `MULTU)  ? 1'b1 :
					  (aluop_i == `MTHI)  ? 1'b1 :
					  (aluop_i == `MTLO)  ? 1'b1 :
					  (aluop_i == `DIV)  ? 1'b1 :
					  (aluop_i == `DIVU)  ? 1'b1 : 1'b0;						  

	// output mem addr
	/*
	always @ (*) begin
		if (rst == `RstEnable) begin
			mem_addr_o <= `ZeroWord;
		end else begin
			case (alusel_i)
				`Mem: begin                      // get offset directly from inst_i
					mem_addr_o <= reg1_i + signed_low16_inst;
				end
				default: begin
					mem_addr_o <= `ZeroWord;
				end
			endcase
		end
	end
	*/
	assign mem_addr_o = (rst == `RstEnable) ? `ZeroWord : 
					  (alusel_i == `Mem)  ? (reg1_i + signed_low16_inst) : `ZeroWord;

endmodule