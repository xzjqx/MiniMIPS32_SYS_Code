`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/22 12:58:34
// Design Name: 
// Module Name: defines
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

//全局
//*************		Global	*******************//
`define RstEnable 		1'b0 			   //复位信号有效  RSTENABLE
`define RstDisable 		1'b1 			   //复位信号无效
`define ZeroWord 		32'h00000000	   //32位的数值0
`define WriteEnable 	1'b1 			   //使能写
`define WriteDisable 	1'b0 			   //禁止写
`define ReadEnable 		1'b1 			   //使能读
`define ReadDisable 	1'b0 			   //禁止读
`define AluOpBus        7: 0               //译码阶段的输出aluop_o的宽度  
`define AluSelBus       2: 0               //译码阶段的输出alusel_o的宽度  
`define InstValid       1'b0               //指令有效  
`define InstInvalid     1'b1               //指令无效  
`define True_v          1'b1               //逻辑“真”  
`define False_v         1'b0               //逻辑“假”  
`define ChipEnable      1'b1               //芯片使能  
`define ChipDisable     1'b0               //芯片禁止  
`define Branch     		1'b1               //转移  
`define NotBranch  		1'b0               //不转移 
`define InDelaySlot     1'b1               //在延迟槽中  
`define NotInDelaySlot  1'b0               //不在延迟槽中
`define Flush  			1'b1 
`define NoFlush  		1'b0 

`define Stop 			1'b1 			
`define NoStop 			1'b0
`define Init_pc			32'hBFC00000
`define ByteSelect      3:0
`define RamAddr 		17:0
`define Cp0Int 			5:0
`define ExcCode 		4:0
`define Stall 			5:0
`define NopAlusel 		3'b0

//指令
//*************		alusel 	*******************//
`define Arithmetic 		3'b000
`define BranchJump 		3'b001
`define Mem 			3'b010
`define Logic 			3'b011
`define Shift 			3'b100
`define Move 			3'b101
`define Trap 			3'b110
`define Privilege 		3'b111

//指令
//************* 	aluop 	*******************//
`define ADDIU 			8'h00

`define ADDU 			8'h01

`define SLT 			8'h02

`define SLTI 			8'h03

`define SLTIU 			8'h04

`define SLTU 			8'h05

`define SUBU 			8'h06

`define MULT 			8'h07

`define BEQ 			8'h08

`define BGEZ 			8'h09

`define BGTZ 			8'h0a

`define BLEZ 			8'h0b

`define BLTZ 			8'h0c

`define BNE 			8'h0d

`define J 				8'h0e

`define JR 				8'h0f

`define JAL 			8'h10

`define JALR 			8'h11

`define LW 				8'h12

`define SW 				8'h13

`define LB 				8'h14

`define SB 				8'h15

`define LBU 			8'h16

`define LHU 			8'h17

`define AND 			8'h18		// and指令的功能码

`define ANDI 			8'h19

`define LUI 			8'h1a

`define NOR 			8'h1b

`define OR 				8'h1c		//  or指令的功能码

`define ORI 			8'h1d

`define XOR 			8'h1e

`define XORI 			8'h1f

`define MFHI 			8'h20

`define MFLO 			8'h21

`define MTHI 			8'h22

`define MTLO 			8'h23

`define SLL 			8'h24

`define SLLV 			8'h25

`define SRA 			8'h26

`define SRAV 			8'h27

`define SRL 			8'h28

`define SRLV 			8'h29

`define SYSCALL 		8'h2a

`define ERET 			8'h2b

`define MFC0 			8'h2c

`define MTC0 			8'h2d

//************* 	New  	*******************//
`define TLBWI			8'h2e

`define DIV     		8'h2f   	//div

`define DIVU    		8'h30    	//div

`define ADD				8'h31		//add

`define ADDI			8'h32		//addi

`define SUB				8'h33		//sub

`define MULTU			8'h34		//multu

`define BLTZAL			8'h35		//bltzal

`define BGEZAL			8'h36		//bgezal

`define BREAK			8'h37		//break

`define LH				8'h38		//lh

`define SH				8'h39		//sh

`define DivFree 			2'b00
`define DivByZero 			2'b01
`define DivOn 				2'b10
`define DivEnd 				2'b11
`define DivResultReady 		1'b1
`define DivResultNotReady 	1'b0
`define DivStart 			1'b1
`define DivStop 			1'b0

//************** Inst.[31:26] -> OP field ********//
`define SPECIAL_OP 			6'b000000
`define ADDI_OP				6'b001000 
`define ADDIU_OP			6'b001001 
`define SLTI_OP 			6'b001010
`define SLTIU_OP 			6'b001011
`define COP0_OP				6'b010000 
`define LH_OP				6'b100001
`define LHU_OP				6'b100101
`define LW_OP				6'b100011
`define SB_OP				6'b101000
`define SH_OP				6'b101001
`define SW_OP				6'b101011

//************** Inst.[ 5: 0] -> func field *********//
`define ADD_OP2				6'b100000
`define ADDU_OP2 			6'b100001
`define SLT_OP2				6'b101010
`define SLTU_OP2 			6'b101011
`define SUB_OP2				6'b100010
`define SUBU_OP2			6'b100011 
`define MULT_OP2			6'b011000
`define MULTU_OP2			6'b011001 
`define DIV_OP2				6'b011010
`define DIVU_OP2			6'b011011
`define AND_OP2 			6'b100100
`define ERET_OP2			6'b011000 
`define TLBWI_OP2	 		6'b000010 
`define BREAK_OP2			6'b001101
`define SYSCALL_OP2			6'b001100
//************ Inst.[25:21] -> func field ************//
`define CP0_OP4				5'b10000
`define MFC0_OP4			5'b00000 
`define MTC0_OP4			5'b00100 


//*********************   与指令存储器ROM有关的宏定义   **********************  
`define InstAddrBus         31:0               //ROM的地址总线宽度  
`define InstBus             31:0               //ROM的数据总线宽度  
`define InstMemNum          131071             //ROM的实际大小为128KB  
`define InstMemNumLog2      17                 //ROM实际使用的地址线宽度  
  
//数据存储器data_ram
`define DataAddrBus 		31:0
`define DataBus 			31:0
`define DataMemNum 			131071
`define DataMemNumLog2 		17
`define ByteWidth 			7:0

//*********************  与通用寄存器Regfile有关的宏定义   *******************  
`define RegAddrBus          4:0                //Regfile模块的地址线宽度  
`define RegBus              31:0               //Regfile模块的数据线宽度  
`define RegWidth            32                 //通用寄存器的宽度  
`define DoubleRegWidth      64                 //两倍的通用寄存器的宽度  
`define DoubleRegBus        63:0               //两倍的通用寄存器的数据线宽度  
`define RegNum              32                 //通用寄存器的数量  
`define RegNumLog2          5                  //寻址通用寄存器使用的地址位数  
`define NOPRegAddr          5'b00000  

//除法div
`define DivFree 			2'b00
`define DivByZero 			2'b01
`define DivOn 				2'b10
`define DivEnd 				2'b11
`define DivResultReady 		1'b1
`define DivResultNotReady 	1'b0
`define DivStart 			1'b1
`define DivStop 			1'b0
// exc code definitions
`define EXC_CODE_WIDTH		5

`define EC_Int				5'h00	// interrupt
`define EC_AdEL				5'h04	// AdEL Address error exception (load or instruction fetch)
`define EC_AdES				5'h05	// AdES Address error exception (store)
`define EC_Sys				5'h08	// Syscall exception
`define EC_Bp				5'h09	// Break exception
`define EC_RI				5'h0a	// reserved instruction
`define EC_Ov				5'h0c	// Integer overflow exception

`define EC_None				5'h10	// dummy value for no exception
`define EC_Eret				5'h11	// dummy value to implement ERET

//CP0寄存器地址
`define Cp0_BadVAddr 		8
`define Cp0_Count	 		9
`define Cp0_Compare 		11
`define Cp0_Status 			12
`define Cp0_Cause 			13
`define Cp0_EPC 			14

`define WB_IDLE 				2'b00
`define WB_BUSY 				2'b01
`define WB_WAIT_FOR_FLUSHING 	2'b10
`define WB_WAIT_FOR_STALL 		2'b11

`define ORDER_REG_ADDR 16'h1160   //32'hbfd0_1160
`define LED_ADDR       16'hf000   //32'hbfd0_f000 
`define LED_RG0_ADDR   16'hf004   //32'hbfd0_f004 
`define LED_RG1_ADDR   16'hf008   //32'hbfd0_f008 
`define NUM_ADDR       16'hf010   //32'hbfd0_f010 
`define SWITCH_ADDR    16'hf020   //32'hbfd0_f020 
`define BTN_KEY_ADDR   16'hf024   //32'hbfd0_f024
`define BTN_STEP_ADDR  16'hf028   //32'hbfd0_f028
`define TIMER_ADDR     16'he000   //32'hbfd0_e000 