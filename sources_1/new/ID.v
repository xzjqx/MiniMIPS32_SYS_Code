`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/22 14:31:28
// Design Name: 
// Module Name: ID
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

module ID(
      input  wire                   cpu_rst_n,
      input  wire [`InstAddrBus]    id_pc_i,
      input  wire [`InstBus    ]    id_inst_i,

      //读端口2的读操作 
      input  wire [`RegBus     ]    id_reg1_data_i,
      input  wire [`RegBus     ]    id_reg2_data_i,

      //处于执行阶段的指令的运算结果
      input  wire                   ex_wreg,
      input  wire [`RegAddrBus ]    ex_wd,
      input  wire [`RegBus     ]    ex_wdata,

      //处于访存阶段的指令的运算结果
      input  wire                   mem_wreg,
      input  wire[`RegAddrBus  ]    mem_wd,
      input  wire[`RegBus      ]    mem_wdata,

      // 如果上一条指令是转移指令，那么下一条指令进入译码阶段的时候，输入变量  
      // is_in_delayslot_i为true，表示是延迟槽指令，反之，为false 
      input  wire                   id_in_delay_i,
      input  wire[`AluOpBus    ]    ex_aluop,
      
      output wire[`InstAddrBus ]    id_pc_o,
      output wire                   stop_from_id, 
      output wire[`InstBus     ]    id_inst_o,      //current instruction
      
      // 输出到Regfile的信息
      output wire [`AluSelBus  ]    id_alusel_o,    //defined in header.v, 8 types in total
      output wire [`AluOpBus   ]    id_aluop_o,     //defined in header.v, 47 types of instructions in total 

      //送到执行阶段的源操作数1、源操作数2
      output wire [`RegBus     ]    id_src1_o,      //value of register 1
      output wire [`RegBus     ]    id_src2_o,      //value of register 2
      output wire [`RegAddrBus ]    id_wd_o,        //target register if write
      output wire                   id_wreg_o,      //whether write to register or not
      
      // 输出到Regfile的信息
      output wire                   id_reg2_read_o, //nothing to do with ALU
      output wire [`InstAddrBus]    id_reg2_addr_o, //nothing to do with ALU
      output wire                   id_reg1_read_o, //nothing to do with ALU
      output wire [`InstAddrBus]    id_reg1_addr_o, //nothing to do with ALU
      output wire                   id_in_delay_o,  //indicator of delay slot for CURRENT instruction
      output wire [`InstAddrBus]    id_link_addr_o, //link address to be put in 
      output wire                   id_next_delay,  //indicator of delay slot for NEXT instruction
      output wire                   branch_flag,    //whether jump/branch or not
      output wire [`InstAddrBus]    branch_addr,    //target address if jump/branch
      
      input  wire [`ExcCode    ]    id_exc_code_i,
      input  wire [`InstAddrBus]    id_exc_badvaddr_i,
      output wire [`ExcCode    ]    id_exc_code_o,
      output wire [`InstAddrBus]    id_exc_epc_o,
      output wire [`InstAddrBus]    id_exc_badvaddr_o
      );
      
      // 输出到Regfile的信息
      wire[5:0] op  =  id_inst_i[31:26];   // 指令码
      wire[4:0] sa  =  id_inst_i[10: 6];
      wire[5:0] func=  id_inst_i[ 5: 0];   // 功能码
      wire[4:0] rs  =  id_inst_i[25:21];
      wire[4:0] rt  =  id_inst_i[20:16];
      wire[4:0] rd  =  id_inst_i[15:11];

      // 输出到Regfile的信息
      wire[`RegBus]    imm;

      // inst_o的值就是译码阶段的指令
      assign id_inst_o = id_inst_i;
      assign id_pc_o   = id_pc_i;

      //id_src1_o   forwarding
      //1、如果Regfile模块读端口1要读取的寄存器就是执行阶段要写的目的寄存器，  
      //   那么直接把执行阶段的结果ex_wdata 作为id_src1_o的值;  
      //2、如果Regfile模块读端口1要读取的寄存器就是访存阶段要写的目的寄存器，  
      //   那么直接把访存阶段的结果mem_wdata作为id_src1_o的值;  
      assign id_src1_o = (ex_wreg == `WriteEnable && ex_wd == id_reg1_addr_o &&     id_reg1_read_o == `ReadEnable) ? ex_wdata :  
                      (mem_wreg       == `WriteEnable && mem_wd == id_reg1_addr_o && id_reg1_read_o  == `ReadEnable ) ? mem_wdata       :
                      (id_reg1_read_o == `ReadEnable ) ? id_reg1_data_i     :
                      (id_reg1_read_o == `ReadDisable) ? imm : `ZeroWord ;

      //1、如果Regfile模块读端口2要读取的寄存器就是执行阶段要写的目的寄存器，  
      //   那么直接把执行阶段的结果ex_wdata 作为id_src2_o的值;  
      //2、如果Regfile模块读端口2要读取的寄存器就是访存阶段要写的目的寄存器，  
      //   那么直接把访存阶段的结果mem_wdata作为id_src2_o的值; 
      assign id_src2_o = (ex_wreg == `WriteEnable && ex_wd == id_reg2_addr_o && id_reg2_read_o == `ReadEnable) ? ex_wdata :
                      (mem_wreg       == `WriteEnable && mem_wd == id_reg2_addr_o && id_reg2_read_o  == `ReadEnable ) ? mem_wdata       :
                      (id_reg2_read_o == `ReadEnable ) ? id_reg2_data_i     :
                      (id_reg2_read_o == `ReadDisable) ? imm : `ZeroWord ;

      //end
      
      assign id_in_delay_o = id_in_delay_i;

      wire [31:0] pc_4;
      assign pc_4 = id_pc_i+4;     //保存当前译码阶段指令后面紧接着的指令的地址

      wire [31:0] pc_8;
      assign pc_8 = id_pc_i+8;     //保存当前译码阶段指令后面第2条指令的地址

      wire [31:0] jump_addr_26;
      assign jump_addr_26 = {pc_4[31:28], id_inst_i[25:0], 2'b00};

      // jump_addr_16对应分支指令中的offset左移两位，再符号扩展至32位的值 
      wire [31:0] jump_addr_16;
      assign jump_addr_16 = (id_pc_i+4)+{{14{id_inst_i[15]}}, id_inst_i[15:0], 2'b00};
      //sign extented

      wire [31:0] zero_imm;
      assign zero_imm   = { {16{1'b0}}, id_inst_i[15:0]};

      wire [31:0] signed_imm;
      assign signed_imm = { {16{id_inst_i[15]}}, id_inst_i[15:0] };


      wire [63:0] op_d  ;
      wire [31:0] rs_d  ;
      wire [31:0] rt_d  ;
      wire [31:0] rd_d  ;
      wire [31:0] sa_d  ;
      wire [63:0] func_d;


      wire [ 7:0] dec_op            ;
      wire [ 2:0] dec_sel           ;
      wire        dec_wreg_o        ;
      wire [ 4:0] dec_wd_o          ;
      wire        dec_reg1_read_o   ;
      wire        dec_reg2_read_o   ;
      wire [ 4:0] dec_reg1_addr_o   ;
      wire [ 4:0] dec_reg2_addr_o   ;
      wire        dec_next_delay    ;
      wire        dec_branch_flag   ;
      wire [31:0] dec_branch_addr   ;
      wire [31:0] dec_link_addr_o   ;
      wire [ 4:0] dec_exc_code_o    ;
      wire [31:0] dec_exc_badvaddr_o;
      wire [31:0] dec_exc_epc_o     ;
      wire [31:0] dec_imm           ;
      wire        dec_stop          ;

      decoder_6_64 u1_dec6to64(.in(op[5:0]  ), .out(op_d[63:0]  ));
      decoder_5_32 u1_dec5to32(.in(rs[4:0]  ), .out(rs_d[31:0]  ));
      decoder_5_32 u2_dec5to32(.in(rt[4:0]  ), .out(rt_d[31:0]  ));
      decoder_5_32 u3_dec5to32(.in(rd[4:0]  ), .out(rd_d[31:0]  ));
      decoder_5_32 u4_dec5to32(.in(sa[4:0]  ), .out(sa_d[31:0]  ));
      decoder_6_64 u2_dec6to64(.in(func[5:0]), .out(func_d[63:0]));

      wire wd_o_rt      ;
      wire wd_o_rd      ;
      wire wd_o_31      ;
      wire reg1_addr_rs ;
      wire reg1_addr_rt ;
      wire reg1_addr_rd ;
      wire reg2_addr_rs ;
      wire reg2_addr_rt ;
      wire branch_flag_0;

      /******           CPU Arithmetic     ***********/
      wire inst_ADD       = op_d[6'h00]&sa_d[5'h00]&func_d[6'h20];

      wire inst_ADDI      = op_d[6'h08];

      wire inst_ADDIU     = op_d[6'h09];

      wire inst_ADDU      = op_d[6'h00]&sa_d[5'h00]&func_d[6'h21];        
                                                      
      wire inst_DIV       = op_d[6'h00]&rd_d[5'h00]&sa_d[5'h00]&func_d[6'h1a];
              
      wire inst_DIVU      = op_d[6'h00]&rd_d[5'h00]&sa_d[5'h00]&func_d[6'h1b];
                                                                                                                                                                                                       
      wire inst_MULT      = op_d[6'h00]&rd_d[5'h00]&sa_d[5'h00]&func_d[6'h18];
                                                                             
      wire inst_MULTU     = op_d[6'h00]&rd_d[5'h00]&sa_d[5'h00]&func_d[6'h19];
                                                     
      wire inst_SLT       = op_d[6'h00]&sa_d[5'h00]&func_d[6'h2a];

      wire inst_SLTI      = op_d[6'h0a];

      wire inst_SLTIU     = op_d[6'h0b];

      wire inst_SLTU      = op_d[6'h00]&sa_d[5'h00]&func_d[6'h2b];

      wire inst_SUB       = op_d[6'h00]&sa_d[5'h00]&func_d[6'h22];

      wire inst_SUBU      = op_d[6'h00]&sa_d[5'h00]&func_d[6'h23];

      /******     CPU Branch and Jump      ***********/
      wire inst_BEQ       = op_d[6'h04];

      wire inst_BGEZ      = op_d[6'h01]&rt_d[5'h01];        

      wire inst_BGEZAL    = op_d[6'h01]&rt_d[5'h11];    

      wire inst_BGTZ      = op_d[6'h07]&rt_d[5'h00];        

      wire inst_BLEZ      = op_d[6'h06]&rt_d[5'h00];

      wire inst_BLTZ      = op_d[6'h01]&rt_d[5'h00];

      wire inst_BLTZAL    = op_d[6'h01]&rt_d[5'h10];

      wire inst_BNE       = op_d[6'h05];
          
      wire inst_J         = op_d[6'h02];
          
      wire inst_JAL       = op_d[6'h03];

      wire inst_JALR      = op_d[6'h00]&rt_d[5'h00]&sa_d[5'h00]&func_d[6'h09];

      wire inst_JR        = op_d[6'h00]&rt_d[5'h00]&rd_d[5'h00]&sa_d[5'h00]&func_d[6'h08];

      /****** CPU Load, Store and Memory Control ******/
      wire inst_LB        = op_d[6'h20];
          
      wire inst_LBU       = op_d[6'h24];

      wire inst_LH        = op_d[6'h21];
          
      wire inst_LHU       = op_d[6'h25];
          
      wire inst_LW        = op_d[6'h23];
                  
      wire inst_SB        = op_d[6'h28];
          
      wire inst_SH        = op_d[6'h29];

      wire inst_SW        = op_d[6'h2b];


      /************     CPU Logical     ****************/
      wire inst_AND       = op_d[6'h00]&sa_d[5'h00]&func_d[6'h24];

      wire inst_ANDI      = op_d[6'h0c];

      wire inst_LUI       = op_d[6'h0f]&rs_d[5'h00];

      wire inst_NOR       = op_d[6'h00]&sa_d[5'h00]&func_d[6'h27];
                                                     
      wire inst_OR        = op_d[6'h00]&sa_d[5'h00]&func_d[6'h25];

      wire inst_ORI       = op_d[6'h0d];

      wire inst_XOR       = op_d[6'h00]&sa_d[5'h00]&func_d[6'h26];

      wire inst_XORI      = op_d[6'h0e];

      /***********   CPU Move          ********************/
      wire inst_MFHI      = op_d[6'h00]&rs_d[5'h00]&rt_d[5'h00]&sa_d[5'h00]&func_d[6'h10];
                                                     
      wire inst_MFLO      = op_d[6'h00]&rs_d[5'h00]&rt_d[5'h00]&sa_d[5'h00]&func_d[6'h12];
                                                                                               
      wire inst_MTHI      = op_d[6'h00]&rt_d[5'h00]&rd_d[5'h00]&sa_d[5'h00]&func_d[6'h11];
                                                                                         
      wire inst_MTLO      = op_d[6'h00]&rt_d[5'h00]&rd_d[5'h00]&sa_d[5'h00]&func_d[6'h13];


      /***********     CPU Shift ***************************/
      wire inst_SLL       = op_d[6'h00]&rs_d[5'h00]&func_d[6'h00];

      wire inst_SLLV      = op_d[6'h00]&sa_d[5'h00]&func_d[6'h04];

      wire inst_SRA       = op_d[6'h00]&rs_d[5'h00]&func_d[6'h03];

      wire inst_SRAV      = op_d[6'h00]&sa_d[5'h00]&func_d[6'h07];

      wire inst_SRL       = op_d[6'h00]&rs_d[5'h00]&func_d[6'h02];

      wire inst_SRLV      = op_d[6'h00]&sa_d[5'h00]&func_d[6'h06];


      /************    CPU Trap ******************************/
      wire inst_BREAK     = op_d[6'h00]&func_d[6'h0d];
          
      wire inst_SYSCALL   = op_d[6'h00]&func_d[6'h0c];
      
      /****** Privileged ******/
      wire inst_ERET      = op_d[6'h10]&rs_d[5'h10]&rt_d[5'h00]&rd_d[5'h00]&sa_d[5'h00]&func_d[6'h18];

      wire inst_MFC0      = op_d[6'h10]&rs_d[5'h00]&sa_d[5'h00]&(func[5:3]==3'b0);

      wire inst_MTC0      = op_d[6'h10]&rs_d[5'h04]&sa_d[5'h0]&&(func[5:3]==3'b0);

      /******other condition ******/
      wire inst_exc       = (id_exc_code_i != `EC_None);

      wire inst_invalid   =  !(inst_ADDIU|inst_ADDU|inst_SLT|inst_SLTI
                        |inst_SLTIU|inst_SLTU|inst_SUBU|inst_MULT
                        |inst_BEQ|inst_BGEZ|inst_BGTZ|inst_BLEZ|inst_BLTZ
                        |inst_BNE|inst_J|inst_JR|inst_JAL|inst_JALR|inst_LW
                        |inst_SB|inst_LBU|inst_LHU|inst_AND|inst_ANDI
                        |inst_LUI|inst_NOR|inst_OR|inst_ORI|inst_XOR
                        |inst_XORI|inst_MFHI|inst_LB|inst_MULTU|inst_SW
                        |inst_MFLO|inst_MTHI|inst_MTLO|inst_SLL
                        |inst_SLLV|inst_SRA|inst_SRAV|inst_SRL|inst_SRLV
                        |inst_SYSCALL|inst_ERET|inst_MFC0|inst_MTC0
                        |inst_DIV|inst_DIVU|inst_ADD|inst_ADDI|inst_SUB
                        |inst_BLTZAL|inst_BGEZAL|inst_BREAK|inst_LH|inst_SH);

      /************ Internal opcode generation  ************/
      assign dec_op[7] = 0;

      assign dec_op[6] = 0;

      assign dec_op[5] = inst_MFHI
                        |inst_MFLO|inst_MTHI|inst_MTLO
                        |inst_SLL|(!cpu_rst_n)|inst_exc|inst_invalid
                        |inst_SLLV|inst_SRA|inst_SRAV|inst_SRL|inst_SRLV
                        |inst_SYSCALL|inst_ERET|inst_MFC0|inst_MTC0
                        |inst_DIV|inst_DIVU|inst_ADD|inst_ADDI|inst_SUB|inst_MULTU
                        |inst_BLTZAL|inst_BGEZAL|inst_BREAK|inst_LH|inst_SH;

      assign dec_op[4] = inst_JAL|inst_JALR|inst_LW|inst_SW|inst_LB
                        |inst_SB|inst_LBU|inst_LHU|inst_AND|inst_ANDI
                        |inst_LUI|inst_NOR|inst_OR|inst_ORI|inst_XOR
                        |inst_XORI|inst_DIVU|inst_ADD|inst_ADDI
                        |inst_SUB|inst_MULTU|inst_BLTZAL|inst_BGEZAL
                        |inst_BREAK|inst_LH|inst_SH;

      assign dec_op[3] = inst_BEQ|inst_BGEZ|inst_BGTZ|inst_BLEZ|inst_BLTZ
                        |inst_BNE|inst_J|inst_JR|inst_AND|inst_ANDI|inst_LUI
                        |inst_NOR|inst_OR|inst_ORI|inst_XOR|inst_XORI
                        |inst_SRL|inst_SRLV|inst_SYSCALL|inst_ERET
                        |inst_MFC0|inst_MTC0|inst_DIV
                        |inst_LH|inst_SH;

      assign dec_op[2] = inst_SLTIU|inst_SLTU|inst_SUBU|inst_MULT|inst_BLTZ
                        |inst_BNE|inst_J|inst_JR|inst_LB|inst_SB
                        |inst_LBU|inst_LHU|inst_OR|inst_ORI|inst_XOR
                        |inst_SLL|(!cpu_rst_n)|inst_exc|inst_invalid
                        |inst_SLLV|inst_SRA|inst_SRAV|inst_XORI
                        |inst_MFC0|inst_MTC0|inst_DIV|inst_MULTU
                        |inst_BLTZAL|inst_BGEZAL|inst_BREAK;

      assign dec_op[1] = inst_SLT|inst_SLTI|inst_SUBU|inst_MULT|inst_BGTZ
                        |inst_BLEZ|inst_J|inst_JR|inst_LW|inst_SW
                        |inst_LBU|inst_LHU|inst_LUI|inst_NOR|inst_XOR
                        |inst_XORI|inst_MTHI|inst_MTLO|inst_SRA|inst_SRAV
                        |inst_SYSCALL|inst_ERET|inst_DIV
                        |inst_ADDI|inst_SUB|inst_BGEZAL|inst_BREAK;

      assign dec_op[0] = inst_ADDU|inst_SLTI|inst_SLTU|inst_MULT|inst_BGEZ
                        |inst_BLEZ|inst_BNE|inst_JR|inst_JALR|inst_SW
                        |inst_SB|inst_LHU|inst_ANDI|inst_NOR|inst_ORI
                        |inst_XORI|inst_MFLO|inst_MTLO|inst_SLLV|inst_SRAV
                        |inst_SRLV|inst_ERET|inst_MTC0|inst_DIV|inst_ADD
                        |inst_SUB|inst_BLTZAL|inst_BREAK|inst_SH;
      
      assign dec_sel[2] = inst_SLL|(!cpu_rst_n)|inst_exc|inst_invalid
                        |inst_SLLV|inst_SRA|inst_SRAV|inst_SRL
                        |inst_SRLV|inst_MFHI|inst_MFLO|inst_MTHI|inst_MTLO
                        |inst_BREAK|inst_SYSCALL|inst_ERET|inst_MFC0
                        |inst_MTC0;

      assign dec_sel[1] = inst_LB|inst_LBU|inst_LH|inst_LHU|inst_LW
                        |inst_SB|inst_SH|inst_SW|inst_AND|inst_ANDI
                        |inst_LUI|inst_NOR|inst_OR|inst_ORI|inst_XOR
                        |inst_XORI|inst_BREAK|inst_SYSCALL
                        |inst_ERET|inst_MFC0|inst_MTC0;

      assign dec_sel[0] = inst_BEQ|inst_BGEZ|inst_BGEZAL|inst_BGTZ
                        |inst_BLTZ|inst_BLTZAL|inst_BNE|inst_J|inst_JAL
                        |inst_JALR|inst_JR|inst_AND|inst_ANDI|inst_LUI
                        |inst_NOR|inst_OR|inst_ORI|inst_XOR|inst_XORI
                        |inst_MFHI|inst_MFLO|inst_MTHI|inst_MTLO|inst_ERET
                        |inst_BLEZ|inst_MFC0|inst_MTC0;

      assign dec_wreg_o = ((!cpu_rst_n)) ? `WriteDisable  :
                        (inst_exc) ? `WriteDisable  :
                        (inst_AND|inst_OR|inst_XOR|inst_NOR|inst_SLL
                        |inst_SRL|inst_SRA|inst_SRLV|inst_SRAV|inst_MFHI
                        |inst_MFLO|inst_ADD|inst_ADDU|inst_SUB|inst_SUBU
                        |inst_SLT|inst_SLTU|inst_JALR|inst_ORI|inst_ANDI
                        |inst_XORI|inst_LUI|inst_ADDI|inst_ADDIU|inst_SLTI
                        |inst_SLTIU|inst_MFC0|inst_LB|inst_LBU|inst_LH
                        |inst_LHU|inst_LW|inst_JAL|inst_BGEZAL|inst_BLTZAL
                        |inst_SLLV) ? `WriteEnable : `WriteDisable;
      
      assign wd_o_rt   = inst_ORI|inst_ANDI|inst_XORI|inst_LUI|inst_ADDI
                        |inst_ADDIU|inst_SLTI|inst_SLTIU|inst_MFC0
                        |inst_LB|inst_LBU|inst_LH|inst_LHU|inst_LW;

      assign wd_o_rd   = inst_AND|inst_OR|inst_XOR|inst_NOR
                        |inst_SLL|inst_SRL|inst_SRA|inst_SLLV|inst_SRLV
                        |inst_SRAV|inst_MFHI|inst_MFLO|inst_ADD|inst_ADDU
                        |inst_SUB|inst_SUBU|inst_SLT|inst_SLTU|inst_JALR
                        |inst_MTC0;

      assign wd_o_31 = inst_JAL|inst_BGEZAL|inst_BLTZAL;

      assign dec_wd_o = ((!cpu_rst_n)) ? 0  :
                        (inst_exc) ? 0  :
                        (wd_o_rt)  ? rt :
                        (wd_o_rd)  ? rd :
                        (wd_o_31)  ? 5'b11111 : 0;
      
      assign dec_reg1_read_o = ((!cpu_rst_n)) ? `ReadDisable  :
                        (inst_exc)        ? `ReadDisable  :
                        (inst_AND|inst_OR|inst_XOR|inst_NOR|inst_SLL
                        |inst_SRL|inst_SRA|inst_SRLV|inst_SRAV|inst_MTHI
                        |inst_MTLO|inst_ADD|inst_ADDU|inst_SUB|inst_SUBU
                        |inst_SLT|inst_SLTU|inst_MULT|inst_MULTU|inst_JR
                        |inst_JALR|inst_DIV|inst_DIVU|inst_ORI|inst_ANDI
                        |inst_XORI|inst_ADDI|inst_ADDIU|inst_SLTI
                        |inst_SLTIU|inst_SLLV
                        |inst_MTC0|inst_LB|inst_LBU|inst_LH|inst_LHU
                        |inst_LW|inst_SB|inst_SH|inst_SW|inst_BEQ
                        |inst_BGTZ|inst_BLEZ|inst_BNE|inst_BLTZ|inst_BGEZ
                        |inst_BGEZAL|inst_BLTZAL) ? `ReadEnable : `ReadDisable;

      assign dec_reg2_read_o =((!cpu_rst_n)) ? `ReadDisable  :
                        (inst_exc)       ? `ReadDisable  :
                        (inst_AND|inst_OR|inst_XOR|inst_NOR|inst_SRLV
                        |inst_SRAV|inst_ADD|inst_ADDU|inst_SUB
                        |inst_SUBU|inst_SLLV
                        |inst_SLT|inst_SLTU|inst_MULT|inst_MULTU|inst_DIV
                        |inst_DIVU|inst_SB|inst_SH|inst_SW|inst_BEQ
                        |inst_BNE) ? `ReadEnable : `ReadDisable;


      assign reg1_addr_rs = inst_AND|inst_OR|inst_XOR|inst_NOR|inst_MTHI
                        |inst_MTLO|inst_ADD|inst_ADDU|inst_SUB|inst_SUBU
                        |inst_SLT|inst_SLTU|inst_MULT|inst_MULTU|inst_JR
                        |inst_JALR|inst_DIV|inst_DIVU|inst_ORI|inst_ANDI
                        |inst_XORI|inst_ADDI|inst_ADDIU|inst_SLTI|inst_SLTIU
                        |inst_LB|inst_LBU|inst_LH|inst_LHU|inst_LW
                        |inst_SB|inst_SH|inst_SW|inst_BEQ|inst_BGTZ
                        |inst_BLEZ|inst_BNE|inst_BLTZ|inst_BGEZ|inst_BGEZAL
                        |inst_BLTZAL;

      assign reg1_addr_rt = inst_SLL|inst_SRL|inst_SRA|inst_SLLV
                        |inst_SRLV|inst_SRAV|inst_MTC0;

      assign reg1_addr_rd = inst_MFC0;

      assign dec_reg1_addr_o =((!cpu_rst_n)) ? 0  :
                        (inst_exc)       ? 0  :
                        (reg1_addr_rs)   ? rs :
                        (reg1_addr_rd)   ? rd :
                        (reg1_addr_rt)   ? rt : 0;

      assign reg2_addr_rs = inst_SLLV|inst_SRLV|inst_SRAV;

      assign reg2_addr_rt = inst_AND|inst_OR|inst_XOR|inst_NOR
                        |inst_ADD|inst_ADDU|inst_SUB|inst_SUBU|inst_SLT
                        |inst_SLTU|inst_MULT|inst_MULTU|inst_DIV
                        |inst_DIVU|inst_SB|inst_SH|inst_SW|inst_BEQ|inst_BNE;

      assign dec_reg2_addr_o =((!cpu_rst_n)) ? 0  :
                        (inst_exc)       ? 0  :
                        (reg2_addr_rs)   ? rs :
                        (reg2_addr_rt)   ? rt : 0 ; 

      assign dec_next_delay = ((!cpu_rst_n)) ? 0  :
                        (inst_exc)       ? 0  :
                        (inst_JR|inst_JALR|inst_J|inst_JAL|inst_BEQ
                        |inst_BGTZ|inst_BLEZ|inst_BNE|inst_BLTZ|inst_BGEZ
                        |inst_BGEZAL|inst_BLTZAL) ? 1'b1 : 1'b0;

      assign dec_branch_flag = ((!cpu_rst_n)) ? `NotBranch  :
                        (inst_exc)        ? `NotBranch  :
                        (inst_JR|inst_JALR|inst_J|inst_JAL
                        |(inst_BEQ&&(id_src1_o==id_src2_o))
                        |(inst_BGTZ&&((id_src1_o[31]==1'b0) && (id_src1_o!=`ZeroWord)))
                        |(inst_BLEZ&&((id_src1_o[31]==1'b1) || (id_src1_o==`ZeroWord)))
                        |(inst_BNE&&(id_src1_o!=id_src2_o))
                        |(inst_BLTZ&&(id_src1_o[31]==1'b1))
                        |(inst_BGEZ&&(id_src1_o[31]==1'b0))
                        |(inst_BGEZAL&&(id_src1_o[31] == 1'b0))
                        |(inst_BLTZAL&&(id_src1_o[31] == 1'b1))) ? `Branch : `NotBranch;
      
      assign dec_branch_addr = ((!cpu_rst_n)) ? 0  :
                        (inst_exc)        ? 0  :
                        ((inst_JR|| inst_JALR) ? id_src1_o :
                        (inst_J || inst_JAL ) ? jump_addr_26 :
                        ((inst_BEQ&&(id_src1_o==id_src2_o))
                        |(inst_BGTZ&&((id_src1_o[31]==1'b0) && (id_src1_o!=`ZeroWord)))
                        |(inst_BLEZ&&((id_src1_o[31]==1'b1) || (id_src1_o==`ZeroWord)))
                        |(inst_BNE&&(id_src1_o!=id_src2_o))
                        |(inst_BLTZ&&(id_src1_o[31]==1'b1))
                        |(inst_BGEZ&&(id_src1_o[31]==1'b0))
                        |(inst_BGEZAL&&(id_src1_o[31] == 1'b0))
                        |(inst_BLTZAL&&(id_src1_o[31] == 1'b1))) ? jump_addr_16 : 0);

      assign dec_link_addr_o =((!cpu_rst_n)) ? 0  :
                        (inst_exc)       ? 0  :
                        (inst_JALR || inst_JAL || inst_BGEZAL 
                        || inst_BLTZAL)  ? pc_8 : 0;

      assign dec_exc_code_o = ((!cpu_rst_n)) ? `EC_None    :
                        (inst_exc)       ?  id_exc_code_i :
                        (inst_BREAK)     ? `EC_Bp      :
                        (inst_SYSCALL)   ? `EC_Sys     :
                        (inst_ERET)      ? `EC_Eret    : 
                        (!inst_invalid)  ?  id_exc_code_i : `EC_RI ;

      assign dec_exc_badvaddr_o = ((!cpu_rst_n))  ? `ZeroWord        :
                        (inst_exc)            ?  id_exc_badvaddr_i  :
                        (inst_BREAK || inst_SYSCALL || inst_ERET
                        )?  `ZeroWord  :  id_exc_badvaddr_i;

      assign dec_exc_epc_o =  ((!cpu_rst_n))               ? `ZeroWord        :
                        (inst_exc && id_in_delay_i)        ?  id_pc_i - 4     :
                        (inst_exc && (!id_in_delay_i))     ?  id_pc_i         :
                        ((inst_BREAK && id_in_delay_i)
                        ||(inst_SYSCALL && id_in_delay_i)) ? (id_pc_i - 4)    :
                        ((inst_BREAK && (!id_in_delay_i))
                        ||(inst_SYSCALL && (!id_in_delay_i)) 
                        || inst_ERET)                   ? id_pc_i             : 
                        (id_in_delay_i)                    ? (id_pc_i - 4)    : 
                        (!id_in_delay_i)                   ? id_pc_i          :
                        (inst_invalid && id_in_delay_i)    ?  id_pc_i - 4     :
                        (inst_invalid && (!id_in_delay_i)) ?  id_pc_i :  `ZeroWord;
      
      assign dec_imm =  ((!cpu_rst_n)) ? `ZeroWord  :
                        (inst_exc) ? `ZeroWord  :
                        (inst_SLL  || inst_SRL  || inst_SRA) ? {{27{1'b0}},id_inst_i[10:6]} :
                        (inst_ORI  || inst_ANDI || inst_XORI || inst_LUI) ? zero_imm :
                        (inst_ADDI || inst_ADDIU || inst_SLTI || inst_SLTIU
                        || inst_LB || inst_LBU || inst_LH || inst_LHU || inst_LW) ? signed_imm : `ZeroWord  ;
                        
      assign dec_stop = ((!cpu_rst_n)) ? `NoStop : 
                        (ex_aluop == (`LB ||`LBU||`LH||`LHU||`LW||`SB||`SH||`SW)) ? `Stop : `NoStop;

      assign      id_aluop_o       = dec_op         ;     
      assign      id_alusel_o      = dec_sel        ;
      assign      id_wreg_o        = dec_wreg_o     ;
      assign      id_wd_o          = dec_wd_o       ;
      assign      id_reg1_read_o   = dec_reg1_read_o;
      assign      id_reg2_read_o   = dec_reg2_read_o;
      assign      id_next_delay    = dec_next_delay ;
      assign      branch_flag      = dec_branch_flag;
      assign      id_reg1_addr_o   = dec_reg1_addr_o;
      assign      id_reg2_addr_o   = dec_reg2_addr_o;
      assign      branch_addr      = dec_branch_addr;
      assign      id_link_addr_o   = dec_link_addr_o;
      assign      id_exc_code_o    = dec_exc_code_o ;
      assign      id_exc_badvaddr_o= dec_exc_badvaddr_o;
      assign      id_exc_epc_o     = dec_exc_epc_o  ;
      assign      imm              = dec_imm        ;
      assign      stop_from_id      = dec_stop      ;

endmodule


