module riscvmono(
  input  logic Clk, Reset,
  // Instruction memory interface
  output logic [31:0] PC, 
  input  logic [31:0] Instr,
  // data memory interface
  output logic [31:0] DataAddress, WriteData,
  output logic        MemWrite,
  input  logic [31:0] ReadData);

  assign MemWrite = isStore;
  assign DataAddress = aluPlus;
  assign WriteData = rs2;

  wire ResultSrc = isLoad;
  wire [31:0] Result = ResultSrc ? ReadData : ALUResult;
  wire        RegWrite = isALUimm | isALUreg | isLoad;
  wire [31:0] SrcA = rs1;
  wire [31:0] SrcB = isALUreg | isBranch ? rs2  : 
                                  isStore  ? Simm : Iimm;
  // The registers bank
  reg [31:0] RegisterFile [0:31];
  wire [31:0] rs1 = rs1Id_A1 ? RegisterFile[rs1Id_A1] : 32'b0; // value of source
  wire [31:0] rs2 = rs2Id_A2 ? RegisterFile[rs2Id_A2] : 32'b0; // registers.
  always@(posedge Clk)
    if (RegWrite)
	    RegisterFile[rdId_A3] <= Result;

  wire PCSrc = isJAL | isJALR;
  wire [31:0] PCplus4 = PC + 4;
  wire [31:0] PCTarget = PC + Jimm;
  wire [31:0] PCNext = PCSrc ? PCTarget : PCplus4;
  always@(posedge Clk)
    PC <= Reset ? 32'b0 : PCNext;  

  // The 10 RISC-V Instructions
  wire isALUreg  =  (Instr[6:0] == 7'b0110011); // rd <- rs1 OP rs2   
  wire isALUimm  =  (Instr[6:0] == 7'b0010011); // rd <- rs1 OP Iimm
  wire isBranch  =  (Instr[6:0] == 7'b1100011); // if(rs1 OP rs2) PC<-PC+Bimm
  wire isJALR    =  (Instr[6:0] == 7'b1100111); // rd <- PC+4; PC<-rs1+Iimm
  wire isJAL     =  (Instr[6:0] == 7'b1101111); // rd <- PC+4; PC<-PC+Jimm
  wire isAUIPC   =  (Instr[6:0] == 7'b0010111); // rd <- PC + Uimm
  wire isLUI     =  (Instr[6:0] == 7'b0110111); // rd <- Uimm   
  wire isLoad    =  (Instr[6:0] == 7'b0000011); // rd <- mem[rs1+Iimm]
  wire isStore   =  (Instr[6:0] == 7'b0100011); // mem[rs1+Simm] <- rs2
  wire isSYSTEM  =  (Instr[6:0] == 7'b1110011); // special

  // The 5 immediate formats
  wire [31:0] Uimm={    Instr[31],   Instr[30:12], {12{1'b0}}};
  wire [31:0] Iimm={{21{Instr[31]}}, Instr[30:20]};
  wire [31:0] Simm={{21{Instr[31]}}, Instr[30:25],Instr[11:7]};
  wire [31:0] Bimm={{20{Instr[31]}}, Instr[7],Instr[30:25],Instr[11:8],1'b0};
  wire [31:0] Jimm={{12{Instr[31]}}, Instr[19:12],Instr[20],Instr[30:21],1'b0};

  // Source and destination registers
  wire [4:0] rs1Id_A1 = Instr[19:15];
  wire [4:0] rs2Id_A2 = Instr[24:20];
  wire [4:0]  rdId_A3 = Instr[11:7];
  
  // function codes
  wire [2:0] funct3 = Instr[14:12];
  wire [6:0] funct7 = Instr[31:25];
  
  // The ALU
  wire [4:0] shamt = isALUreg ? rs2[4:0] : Instr[24:20]; // shift amount

  // The adder is used by both arithmetic Instructions and JALR.
  wire [31:0] aluPlus = SrcA + SrcB;

  // Use a single 33 bits subtract to do subtraction and all comparisons
  // (trick borrowed from swapforth/J1)
  wire [32:0] aluMinus = {1'b1, ~SrcB} + {1'b0,SrcA} + 33'b1;
  wire        LT  = (SrcA[31] ^ SrcB[31]) ? SrcA[31] : aluMinus[32];
  wire        LTU = aluMinus[32];
  wire        EQ  = (aluMinus[31:0] == 0);

  // Flip a 32 bit word. Used by the shifter (a single shifter for
  // left and right shifts, saves silicium !)
  function [31:0] flip32;
    input [31:0] x;
    flip32 = {x[ 0], x[ 1], x[ 2], x[ 3], x[ 4], x[ 5], x[ 6], x[ 7], 
              x[ 8], x[ 9], x[10], x[11], x[12], x[13], x[14], x[15], 
              x[16], x[17], x[18], x[19], x[20], x[21], x[22], x[23],
              x[24], x[25], x[26], x[27], x[28], x[29], x[30], x[31]};
  endfunction

  wire [31:0] shifter_in = (funct3 == 3'b001) ? flip32(SrcA) : SrcA;
  wire [31:0] shifter = $signed({Instr[30] & SrcA[31], shifter_in}) >>> SrcB[4:0];
  wire [31:0] leftshift = flip32(shifter);
  
  // ADD/SUB/ADDI: 
  // funct7[5] is 1 for SUB and 0 for ADD. We need also to test Instr[5]
  // to make the difference with ADDI
  //
  // SRLI/SRAI/SRL/SRA: 
  // funct7[5] is 1 for arithmetic shift (SRA/SRAI) and 
  // 0 for logical shift (SRL/SRLI)
  reg [31:0]  ALUResult;
  always @(*) begin
    case(funct3)
      3'b000: ALUResult = (funct7[5] & Instr[5]) ? aluMinus[31:0] : aluPlus;
      3'b001: ALUResult = leftshift;
      3'b010: ALUResult = {31'b0, LT};
      3'b011: ALUResult = {31'b0, LTU};
      3'b100: ALUResult = (SrcA ^ SrcB);
      3'b101: ALUResult = shifter;
      3'b110: ALUResult = (SrcA | SrcB);
      3'b111: ALUResult = (SrcA & SrcB);	
    endcase
  end
endmodule