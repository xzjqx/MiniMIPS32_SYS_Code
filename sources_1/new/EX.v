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
	input  wire 					cpu_rst_n,

	// 译码阶段送到执行阶段的信息
	input  wire [`AluSelBus		] 	ex_alusel_i,
	input  wire [`AluOpBus	    ] 	ex_aluop_i,
	input  wire [`InstAddrBus 	]   ex_pc_i,
	output wire [`InstAddrBus 	]  	ex_pc_o,
	input  wire [`RegBus 		] 	ex_src1_i,
	input  wire [`RegBus 		] 	ex_src2_i,
	input  wire [`RegAddrBus 	] 	ex_wd_i,
	input  wire 					ex_wreg_i,
	
	// HILO模块给出的HI、LO寄存器的值 
	input  wire [`RegBus 		] 	hi_i,
	inout  wire [`RegBus 		] 	lo_i,

	// 访存阶段的指令是否要写HI、LO，用于检测HI、LO寄存器带来的数据相关问题
	input  wire 					mem_whilo_i,
	input  wire [`RegBus 		] 	mem_hi_i,
	input  wire [`RegBus 		] 	mem_lo_i,

	// 回写阶段的指令是否要写HI、LO，用于检测HI、LO寄存器带来的数据相关问题 
	input  wire 					wb_whilo_i,
	input  wire [`RegBus 		] 	wb_hi_i,
	input  wire [`RegBus 		] 	wb_lo_i,
	
	// 当前执行阶段的指令是否位于延迟槽
	input  wire 					in_delay_i,
	output wire						in_delay_o,

	// 处于执行阶段的转移指令要保存的返回地址
	input  wire [`InstAddrBus 	] 	link_addr_i,
	
	//新增输入接口ex_inst_i，其值就是当前处于执行阶段的指令
	input  wire [`InstAddrBus 	] 	ex_inst_i,

	input  wire [`RegBus 		]   cp0_reg_read_data_i,
	output wire [`RegAddrBus 	]   ex_cp0_reg_read_addr_o,

	output wire          			ex_cp0_reg_we_o,
	output wire [`RegAddrBus 	]   ex_cp0_reg_write_addr_o,
	output wire [`RegBus 		] 	ex_cp0_reg_data_o,

	// 执行的结果
	output wire [`RegAddrBus 	] 	ex_wd_o,
	output wire 					ex_wreg_o,
	output wire [`RegBus 		] 	ex_wdata_o,
	
	// 处于执行阶段的指令对HI、LO寄存器的写操作请求
	output wire 					ex_whilo_o,
	output wire [`RegBus 		] 	ex_hi_o,
	output wire [`RegBus 		] 	ex_lo_o,
	
	//为加载、存储指令准备的输出接口
	output wire [`AluOpBus 		] 	ex_aluop_o,
	output wire [`InstAddrBus 	] 	mem_addr_o,
	output wire [`RegBus 		] 	ex_reg2_o,
	
	input  wire [`EXC_CODE_WIDTH-1:0]ex_exc_code_i,
	input  wire [`InstAddrBus 	] 	ex_exc_epc_i,
	input  wire [`InstAddrBus  	] 	ex_exc_badvaddr_i,
	
	output wire [`EXC_CODE_WIDTH-1:0]ex_exc_code_o,
	output wire [`InstAddrBus 	] 	ex_exc_epc_o,
	output wire [`InstAddrBus 	] 	ex_exc_badvaddr_o,
	
	output wire 					cp0_reg_read_o,
	
	
	// 来自除法模块的输入
	input  wire[`DoubleRegBus 	]   div_result_i,
    input  wire                     div_ready_i,

    // 到除法模块的输出
    output wire [`RegBus 		]   div_opdata1_o,
    output wire [`RegBus 		]   div_opdata2_o,
    output wire                     div_start_o,
    output wire                    	signed_div_o,
    output 							stop_from_ex
    );
    
    assign in_delay_o = in_delay_i;
    assign ex_pc_o 	  = ex_pc_i;
	
	wire [`InstAddrBus] signed_low16_inst;
	assign signed_low16_inst = { {16{ex_inst_i[15]}}, ex_inst_i[15:0] };

	wire [`RegBus] 			logicout;		// 保存逻辑运算的结果
	wire [`RegBus] 			shiftout;		// 保存移位运算结果
	wire [`RegBus] 			moveout;		// 移动操作的结果
	wire [`RegBus] 			hi_t;			// 保存HI寄存器的最新值
	wire [`RegBus] 			lo_t;			// 保存LO寄存器的最新值
	reg  [`DoubleRegBus] 	arithout;
	wire [`RegBus] 			cp0out;
	
	wire stallreq_for_div;	 // 是否由于除法运算导致流水线暂停 
	assign stop_from_ex = stallreq_for_div;

	//ex_aluop_o会传递到访存阶段，届时将利用其确定加载、存储类型
	assign ex_aluop_o   = ex_aluop_i;
	assign ex_reg2_o    = ex_src2_i;

	assign ex_exc_badvaddr_o = (cpu_rst_n==`RstEnable) ? 0 : ex_exc_badvaddr_i;

	assign ex_cp0_reg_we_o = (cpu_rst_n == `RstEnable) ? 1'b0 : 
						  (ex_aluop_i == `MFC0)  	   ? 1'b0 :
						  (ex_aluop_i == `MTC0)        ? 1'b1 : 1'b0;

	assign ex_cp0_reg_data_o = (cpu_rst_n == `RstEnable) ? 32'h00000000 : 
						  (ex_aluop_i == `MFC0)  ? 32'h00000000 :
						  (ex_aluop_i == `MTC0)  ? ex_src1_i  : 32'h00000000;

    assign ex_cp0_reg_write_addr_o = (cpu_rst_n == `RstEnable) ? 5'b00000 : 
						  (ex_aluop_i == `MFC0)  ? 5'b00000   :
						  (ex_aluop_i == `MTC0)  ? ex_inst_i[15:11] : 5'b00000;

	assign ex_cp0_reg_read_addr_o = (cpu_rst_n == `RstEnable) ? 5'b00000 : 
						  (ex_aluop_i == `MFC0)  ? ex_inst_i[15:11] :
						  (ex_aluop_i == `MTC0)  ? 5'b00000    : 5'b00000;

	assign cp0_reg_read_o = (cpu_rst_n == `RstEnable) ? 1'b0 : 
						  (ex_aluop_i == `MFC0)  ? 1'b1      :
						  (ex_aluop_i == `MTC0)  ? 1'b0      : 1'b0;

	assign cp0out = (cpu_rst_n == `RstEnable) ? `ZeroWord    : 
						  (ex_aluop_i == `MFC0)  ? cp0_reg_read_data_i :
						  (ex_aluop_i == `MTC0)  ? `ZeroWord : `ZeroWord;

	
	// 8/8 logic instructions=====================================================
	assign logicout = (cpu_rst_n == `RstEnable)  ? `ZeroWord : 
						  (ex_aluop_i == `AND )  ? (ex_src1_i & ex_src2_i) :
						  (ex_aluop_i == `ANDI)  ? (ex_src1_i & ex_src2_i) :
						  (ex_aluop_i == `LUI )  ? ({ex_src1_i[15:0], 16'b0}) :
						  (ex_aluop_i == `NOR )  ? (~(ex_src1_i | ex_src2_i)) :
						  (ex_aluop_i == `OR  )  ? (ex_src1_i | ex_src2_i) :
						  (ex_aluop_i == `ORI )  ? (ex_src1_i | ex_src2_i) :
						  (ex_aluop_i == `XOR )  ? (ex_src1_i ^ ex_src2_i) :
						  (ex_aluop_i == `XORI)  ? (ex_src1_i ^ ex_src2_i) : `ZeroWord;
	

	// 6/6 shift word instructions================================================
	assign shiftout = (cpu_rst_n == `RstEnable) ? `ZeroWord : 
					  (ex_aluop_i == `SLL )  ? (ex_src1_i <<  ex_src2_i) :
					  (ex_aluop_i == `SLLV)  ? (ex_src1_i <<  ex_src2_i) :
					  (ex_aluop_i == `SRA )  ? (({32{ex_src1_i[31]}} << (6'd32-{1'b0, ex_src2_i[4:0]})) | ex_src1_i >> ex_src2_i[4:0])   :
					  (ex_aluop_i == `SRAV)  ? (({32{ex_src1_i[31]}} << (6'd32-{1'b0, ex_src2_i[4:0]})) | ex_src1_i >> ex_src2_i[4:0])   :
					  (ex_aluop_i == `SRL )  ? (ex_src1_i >> ex_src2_i)  :
					  (ex_aluop_i == `SRLV)  ? (ex_src1_i >> ex_src2_i)  : `ZeroWord;
	
	// 4/6 move instructions======================================================
	//得到最新的HI、LO寄存器的值，此处要解决数据相关问题
	assign hi_t 	= (cpu_rst_n == `RstEnable) ? `ZeroWord : 
					  (mem_whilo_i == 1'b1) ? mem_hi_i :
              		  (wb_whilo_i == 1'b1 ) ? wb_hi_i  : hi_i;
	assign lo_t 	= (cpu_rst_n == `RstEnable) ? `ZeroWord : 
					  (mem_whilo_i == 1'b1) ? mem_lo_i :
              		  (wb_whilo_i == 1'b1 ) ? wb_lo_i  : lo_i;
    
	assign moveout  = (cpu_rst_n == `RstEnable) ? `ZeroWord : 
					  (ex_aluop_i == `MFHI) ? hi_t :
					  (ex_aluop_i == `MFLO) ? lo_t : `ZeroWord;
	
	// 8/21 arithmetic instructions===============================================
	reg  [32:0] tmp;
	wire [32:0] tmp_1;
	wire [32:0] tmp_2;
	wire [ 5:0] exc_code_tmp;
	wire [31:0] exc_epc_tmp;

	
	always @ (*) begin
		if (cpu_rst_n == `RstEnable) begin
			arithout <= 64'b0;
		end else begin
			case (ex_aluop_i)
				`ADD: begin
					tmp <= {ex_src1_i[31],ex_src1_i} + {ex_src2_i[31],ex_src2_i};
					if(tmp[32] != tmp[31]) begin
					end
					else arithout <= tmp[31:0];
				end
				`ADDI: begin
					tmp <= {ex_src1_i[31],ex_src1_i} + {ex_src2_i[31],ex_src2_i};
					if(tmp[32] != tmp[31]) begin
					end
					else arithout <= tmp[31:0];
				end
				`ADDIU: begin              // immdiate should be load to ex_src2_i
					arithout <= ex_src1_i + ex_src2_i;
				end
				`ADDU: begin
					arithout <= ex_src1_i + ex_src2_i;
				end
				`SLT: begin
					arithout <= ($signed(ex_src1_i) < $signed(ex_src2_i)) ? 64'b1 : 64'b0;
				end
				`SLTI: begin               // immdiate should be load to ex_src2_i
					arithout <= ($signed(ex_src1_i) < $signed(ex_src2_i)) ? 64'b1 : 64'b0;
				end
				`SLTU: begin
					arithout <= (ex_src1_i < ex_src2_i) ? 64'b1 : 64'b0;
				end
				`SLTIU: begin              // immdiate should be load to ex_src2_i
					arithout <= (ex_src1_i < ex_src2_i) ? 64'b1 : 64'b0;
				end
				`SUB: begin
					tmp <= {ex_src1_i[31],ex_src1_i} - {ex_src2_i[31],ex_src2_i};
					if(tmp[32] != tmp[31]) begin
					end
					else arithout <= tmp[31:0];
				end
				`SUBU: begin
					arithout <= ex_src1_i - ex_src2_i;
				end
				`MULT: begin
					arithout <= $signed(ex_src1_i) * $signed(ex_src2_i);
				end
				`MULTU: begin
					arithout <= {1'b0,ex_src1_i} * {1'b0,ex_src2_i};
				end
				default: begin
					arithout <= 64'b0;
				end
			endcase
		end
	end
	
	
	assign tmp_1 	= {ex_src1_i[31],ex_src1_i} + {ex_src2_i[31],ex_src2_i};
	assign tmp_2 	= {ex_src1_i[31],ex_src1_i} - {ex_src2_i[31],ex_src2_i};
	/*
	assign arithout = (cpu_rst_n   == `RstEnable) ? 64'b0 : 
					  ((ex_aluop_i == `ADD  )  && (tmp_1[32] == tmp_1[31]))  ? tmp_1[31:0] :
					  ((ex_aluop_i == `ADDI )  && (tmp_1[32] == tmp_1[31]))  ? tmp_1[31:0] :
					  (ex_aluop_i  == `ADDIU)  ? (ex_src1_i + ex_src2_i) :
					  (ex_aluop_i  == `ADDU )  ? (ex_src1_i + ex_src2_i) :
					  ((ex_aluop_i == `SLT  )  && ($signed(ex_src1_i) < $signed(ex_src2_i))) ? 64'b1 :
				      ((ex_aluop_i == `SLT  )  && (!($signed(ex_src1_i) < $signed(ex_src2_i)))) ? 64'b0 :				  
					  ((ex_aluop_i == `SLTI )  && ($signed(ex_src1_i) < $signed(ex_src2_i))) ? 64'b1 :
					  ((ex_aluop_i == `SLTI )  && (!($signed(ex_src1_i) < $signed(ex_src2_i)))) ? 64'b0 :
					  ((ex_aluop_i == `SLTU )  && (ex_src1_i < ex_src2_i)) ? 64'b1 :
					  ((ex_aluop_i == `SLTU )  && (!(ex_src1_i < ex_src2_i))) ? 64'b0 :
					  ((ex_aluop_i == `SLTIU)  && (ex_src1_i < ex_src2_i)) ? 64'b1 :
					  ((ex_aluop_i == `SLTIU)  && (!(ex_src1_i < ex_src2_i))) ? 64'b0 :
					  ((ex_aluop_i == `SUB  )  && (tmp_2[32] == tmp_2[31]))  ? tmp_2[31:0] :
					  (ex_aluop_i  == `SUBU )  ? (ex_src1_i - ex_src2_i) :
					  (ex_aluop_i  == `MULT )  ? ($signed(ex_src1_i) * $signed(ex_src2_i)) :
					  (ex_aluop_i  == `MULTU)  ? ({1'b0,ex_src1_i} * {1'b0,ex_src2_i}) : 64'b0;
	*/			  
	assign exc_code_tmp = (cpu_rst_n == `RstEnable) ? `EC_None : 
					  ((ex_aluop_i == `ADD ) && (tmp_1[32] != tmp_1[31]))  ? `EC_Ov :
					  ((ex_aluop_i == `ADDI) && (tmp_1[32] != tmp_1[31]))  ? `EC_Ov :
					  ((ex_aluop_i == `SUB ) && (tmp_2[32] != tmp_2[31]))  ? `EC_Ov : ex_exc_code_i;
	assign exc_epc_tmp = (cpu_rst_n == `RstEnable) ? `ZeroWord : 
					  ((ex_aluop_i == `ADD ) && (tmp_1[32] != tmp_1[31]) && (in_delay_i))    ? (ex_pc_i -4) :
					  ((ex_aluop_i == `ADD ) && (tmp_1[32] != tmp_1[31]) && (!in_delay_i))  ? ex_pc_i :
					  ((ex_aluop_i == `ADDI) && (tmp_1[32] != tmp_1[31]) && (in_delay_i))    ? (ex_pc_i -4) :
					  ((ex_aluop_i == `ADDI) && (tmp_1[32] != tmp_1[31]) && (!in_delay_i))  ? ex_pc_i :
					  ((ex_aluop_i == `SUB ) && (tmp_2[32] != tmp_2[31]) && (in_delay_i))    ? (ex_pc_i -4) :
					  ((ex_aluop_i == `SUB ) && (tmp_2[32] != tmp_2[31]) && (!in_delay_i))  ? ex_pc_i : ex_exc_epc_i;			
			  
					  
	//div 
	//输出DIV模块控制信息，获取DIV模块给出的结果

	assign stallreq_for_div = (cpu_rst_n == `RstEnable) ? `NoStop : 
					  ((ex_aluop_i == `DIV ) && (div_ready_i == `DivResultNotReady))  ? `Stop :
					  ((ex_aluop_i == `DIV ) && (div_ready_i == `DivResultReady))  ? `NoStop :
					  (ex_aluop_i  == `DIV ) ? `NoStop :
					  ((ex_aluop_i == `DIVU) && (div_ready_i == `DivResultNotReady))  ? `Stop :
					  ((ex_aluop_i == `DIVU) && (div_ready_i == `DivResultReady))  ? `NoStop :
					  (ex_aluop_i  == `DIVU) ? `NoStop : `NoStop;

	assign div_opdata1_o = (cpu_rst_n == `RstEnable) ? `ZeroWord : 
					  ((ex_aluop_i == `DIV ) && (div_ready_i == `DivResultNotReady))  ? ex_src1_i :
					  ((ex_aluop_i == `DIV ) && (div_ready_i == `DivResultReady))  ? ex_src1_i :
					  (ex_aluop_i  == `DIV ) ? `ZeroWord :
					  ((ex_aluop_i == `DIVU) && (div_ready_i == `DivResultNotReady))  ? ex_src1_i :
					  ((ex_aluop_i == `DIVU) && (div_ready_i == `DivResultReady))  ? ex_src1_i :
					  (ex_aluop_i  == `DIVU) ? `ZeroWord : `ZeroWord;

	assign div_opdata2_o = (cpu_rst_n == `RstEnable) ? `ZeroWord : 
					  ((ex_aluop_i == `DIV ) && (div_ready_i == `DivResultNotReady))  ? ex_src2_i :
					  ((ex_aluop_i == `DIV ) && (div_ready_i == `DivResultReady))  ? ex_src2_i :
					  (ex_aluop_i  == `DIV ) ? `ZeroWord :
					  ((ex_aluop_i == `DIVU) && (div_ready_i == `DivResultNotReady))  ? ex_src2_i :
					  ((ex_aluop_i == `DIVU) && (div_ready_i == `DivResultReady))  ? ex_src2_i :
					  (ex_aluop_i  == `DIVU) ? `ZeroWord : `ZeroWord;					  			  
	assign div_start_o = (cpu_rst_n == `RstEnable) ? `DivStop : 
					  ((ex_aluop_i == `DIV ) && (div_ready_i == `DivResultNotReady))  ? `DivStart :
					  ((ex_aluop_i == `DIV ) && (div_ready_i == `DivResultReady))  ? `DivStop :
					  (ex_aluop_i  == `DIV ) ? `DivStop :
					  ((ex_aluop_i == `DIVU) && (div_ready_i == `DivResultNotReady))  ? `DivStart :
					  ((ex_aluop_i == `DIVU) && (div_ready_i == `DivResultReady))  ? `DivStop :
					  (ex_aluop_i  == `DIVU) ? `DivStop : `DivStop; 

	assign signed_div_o = (cpu_rst_n == `RstEnable) ? 1'b0 : 
					  ((ex_aluop_i == `DIV ) && (div_ready_i == `DivResultNotReady))  ? 1'b1 :
					  ((ex_aluop_i == `DIV ) && (div_ready_i == `DivResultReady))  ? 1'b1 :
					  (ex_aluop_i  == `DIV ) ? 1'b0 :
					  ((ex_aluop_i == `DIVU) && (div_ready_i == `DivResultNotReady))  ? 1'b0 :
					  ((ex_aluop_i == `DIVU) && (div_ready_i == `DivResultReady))  ? 1'b0 :
					  (ex_aluop_i  == `DIVU) ? 1'b0: 1'b0; 					  
	
	// output general
	// 如果是mflo指令，那么将LO的值作为移动操作的结果

	assign ex_wd_o  	 = (cpu_rst_n   == `RstEnable ) ? 5'b0 	 : ex_wd_i;
	assign ex_wreg_o	 = (cpu_rst_n   == `RstEnable ) ? 1'b0 	 : ex_wreg_i;
	assign ex_exc_code_o = (cpu_rst_n   == `RstEnable ) ? `EC_None  : exc_code_tmp;
	assign ex_exc_epc_o  = (cpu_rst_n   == `RstEnable ) ? `ZeroWord : exc_epc_tmp;
	assign ex_wdata_o    = (cpu_rst_n   == `RstEnable ) ? `ZeroWord : 
						   (ex_alusel_i == `Logic     ) ? logicout  :
						   (ex_alusel_i == `Shift     ) ? shiftout  :
						   (ex_alusel_i == `Move      ) ? moveout   :
						   (ex_alusel_i == `Arithmetic) ? arithout[31:0] :
						   (ex_alusel_i == `BranchJump) ? link_addr_i :
						   (ex_alusel_i == `Privilege ) ? cp0out    : `ZeroWord;


	// output hi lo

	assign ex_lo_o =  (cpu_rst_n == `RstEnable) ? `ZeroWord : 
					  (ex_aluop_i == `MULT )  ? arithout[31:0] :
					  (ex_aluop_i == `MULTU)  ? arithout[31:0] :
					  (ex_aluop_i == `MTHI )  ? lo_t :
					  (ex_aluop_i == `MTLO )  ? ex_src1_i :
					  (ex_aluop_i == `DIV  )  ? div_result_i[31:0] :
					  (ex_aluop_i == `DIVU )  ? div_result_i[31:0] : `ZeroWord;	

	assign ex_hi_o =  (cpu_rst_n == `RstEnable) ? `ZeroWord : 
					  (ex_aluop_i == `MULT )  ? arithout[63:32] :
					  (ex_aluop_i == `MULTU)  ? arithout[63:32] :
					  (ex_aluop_i == `MTHI )  ? ex_src1_i :
					  (ex_aluop_i == `MTLO )  ? hi_t :
					  (ex_aluop_i == `DIV  )  ? div_result_i[63:32] :
					  (ex_aluop_i == `DIVU )  ? div_result_i[63:32] : `ZeroWord;

	assign ex_whilo_o = (cpu_rst_n == `RstEnable) ? 1'b0 : 
					  (ex_aluop_i == `MULT )  ? 1'b1 :
					  (ex_aluop_i == `MULTU)  ? 1'b1 :
					  (ex_aluop_i == `MTHI )  ? 1'b1 :
					  (ex_aluop_i == `MTLO )  ? 1'b1 :
					  (ex_aluop_i == `DIV  )  ? 1'b1 :
					  (ex_aluop_i == `DIVU )  ? 1'b1 : 1'b0;						  

	// output mem addr
	assign mem_addr_o = (cpu_rst_n == `RstEnable) ? `ZeroWord : 
					  (ex_alusel_i == `Mem)   ? (ex_src1_i + signed_low16_inst) : `ZeroWord;

endmodule