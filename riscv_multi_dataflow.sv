module riscv_multi_dataflow(
  input logic clk, reset,
  output logic [31:0] adr, writedata,
  output logic memwrite,
  input logic [31:0] readdata);
  
  // os 12 estados mapeados por H&H no seu processador multiciclo
  localparam [3:0] FETCH = 4'b0000, DECODE = 4'b0001, MEMADR = 4'b0010, MEMRD = 4'b0011, MEMWB = 4'b0100, MEMWR = 4'b0101, RTYPEEX = 4'b0110, RTYPEWB = 4'b0111, BEQEX = 4'b1000, ADDIEX = 4'b1001, ADDIWB = 4'b1010, JEX = 4'b1011;
  
  logic [3:0] state; // o estado em si

  wire sFETCH   = (state == FETCH);   // le a memória em PC e computa PC+4
  wire sDECODE  = (state == DECODE);  // registra os valores rs1 e rs2 (a/b)
  wire sMEMADR  = (state == MEMADR);  // computa o valor efetivo de uma 'variavel' (a + imediato)
  wire sMEMRD   = (state == MEMRD);   // le a memoria
  wire sMEMWB   = (state == MEMWB);   // escreve o dado para o registrador (lw)
  wire sMEMWR   = (state == MEMWR);   // guardo o dado para a memoria (rw)
  wire sRTYPEEX = (state == RTYPEEX); // R-type
  wire sRTYPEWB = (state == RTYPEWB); // R-type
  wire sBEQEX   = (state == BEQEX);   // branch
  wire sADDIEX  = (state == ADDIEX);  // computa a + imediato
  wire sADDIWB  = (state == ADDIWB);  // escreve o resultado da ULA pro registrador
  wire sJEX     = (state == JEX);     // jump
  
  // as 'variaveis' (registradores)
  logic [31:0] pc, pca;   // PC, endereço atual da instrução (von Neumman)
  logic [31:0] instr;     // o codigo da instrução
  logic [31:0] data;      // o dado a ser lido
  logic [31:0] a, b;      // rs1 e rs2 (facilitar a leitura)
  logic [31:0] aluout;    // o resultado da ULA
  logic [31:0] rf [0:31]; // array com as 32 palavras nos registradores

  // decodificação dos opcodes
  localparam [6:0] LW = 7'b0000011, SW = 7'b0100011, RTYPE = 7'b0110011, BEQ = 7'b1100011, ADDI = 7'b0010011, JAL = 7'b1101111;

  wire [6:0] opcode = instr[6:0]; // os bits do opcode

  wire isLW = (opcode == LW); // load word
  wire isSW = (opcode == SW); // save word
  wire isRTYPE = (opcode == RTYPE); // r-type
  wire isBEQ = (opcode == BEQ); // branch
  wire isADDI = (opcode == ADDI); // add immediate
  wire isJAL = (opcode == JAL); // jump

  // máquina de estados, novamente, seguindo o modelo de H&H
  wire [3:0] nextstate =
      sFETCH   ? DECODE  : // começa no FETCH
      sDECODE  ? (isLW | isSW ? MEMADR  : // DECODE analisa qual função será feita
                  isRTYPE     ? RTYPEEX :
                  isBEQ       ? BEQEX   :
                  isADDI      ? ADDIEX  :
                  isJAL       ? JEX     : 4'bx) :
      sMEMADR  ? (isLW ? MEMRD : // ler ou escrever?
                  isSW ? MEMWR : 4'bx)  :
      sMEMRD   ? MEMWB   : //se ler, escreve pro FETCH
      sRTYPEEX ? RTYPEWB : // se ler, escreve pro FETCH, mas R-Type
      sADDIEX  ? ADDIWB  : // se ler, escreve pro FETCH, mas adiciona imediato
      (sMEMWB | sMEMWR | sRTYPEWB | sBEQEX | sADDIWB | sJEX) ? FETCH :
                   4'bx;

  
  // transposição da tabela de sinais de controle (linhas 174-188 do código estrutural)
  wire pcwrite = sFETCH | sJEX; // funções que "subscrevem" PC
  assign memwrite = sMEMWR;     // escreve na memória
  wire irwrite = sFETCH;
  wire regwrite = sMEMWB | sRTYPEWB | sADDIWB;
  wire branch = sBEQEX;
  wire iord = sMEMRD | sMEMWR;
  wire memtoreg = sMEMWB;
  wire [1:0] alusrca = sJEX ? 2'b10 : (sMEMADR | sRTYPEEX | sBEQEX | sADDIEX) ? 2'b01 : 2'b00;
  wire [1:0] pcsrc = sBEQEX ? 2'b01 : 2'b00;
  wire [2:0] alusrcb = sFETCH ? 3'b001 : sDECODE ? 3'b011 : (sMEMADR | sADDIEX) ? 3'b010 : sJEX ? 3'b100 : 3'b000;
  wire [1:0] aluop = sRTYPEEX ? 2'b10 : sBEQEX ? 2'b01 : 2'b00;

  // decoficando pra ULA
  wire [2:0] funct3 = instr[14:12];

  wire [2:0] alucontrol = (aluop  == 2'b00)  ? 3'b010 :   // add
                          (aluop  == 2'b01)  ? 3'b110 :   // sub
                          (funct3 == 3'b000) ? 3'b010 :   // ADD
                          (funct3 == 3'b111) ? 3'b000 :   // AND
                          (funct3 == 3'b110) ? 3'b001 :   // OR
                          (funct3 == 3'b010) ? 3'b111 :   // SLT
                                               3'bxxx;

  // campos da instrução
  wire [4:0] rs1Id = instr[19:15];
  wire [4:0] rs2Id = instr[24:20];
  wire [4:0] rdId = instr[11:7];

  //imediatos (os únicos usados são o immI e immJ, por mais que o arquivo original tenha o U e o S)
  wire [31:0] immI = {{20{instr[31]}}, instr[31:20]};
  wire [31:0] immJ = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

  // DATAPATH
  
  // banco de registradores
  wire [31:0] rd1 = (rs1Id != 0) ? rf[rs1Id] : 32'b0;
  wire [31:0] rd2 = (rs2Id != 0) ? rf[rs2Id] : 32'b0;

  //muxes
  assign adr = iord ? aluout : pc;  // pegar a memória com o pc (0) ou o endereço calculado pela ULA
  wire [31:0] wd3 = memtoreg ? data : aluout; // o que é escrito no registrador? da memória ou da ULA
  wire [31:0] srca = (alusrca == 2'b10) ? pca : (alusrca == 2'b01) ? a : pc; // primeiro operando da ULA, calcular o pca, pegar o registrador 1 (a), ou calcular a posição do PC+4
  wire [31:0] srcb = (alusrcb == 3'b001) ? 32'd4 : // segundo operando: 4 para PC+4, imeditado I, escalonamento de branch, jump, ou usar o registrador 2 (b)
                     (alusrcb == 3'b010) ? immI  :
                     (alusrcb == 3'b011) ? (immI<<2) :
                     (alusrcb[2]) ? immJ : b;
  // ULA
  wire [31:0] condinvb = alucontrol[2] ? ~srcb : srcb; // subtração ou adição
  wire [31:0] sum = srca + condinvb + alucontrol[2];
  wire [31:0] aluresult = (alucontrol==3'b000 || alucontrol==3'b100) ? (srca & srcb) :
                          (alucontrol==3'b001 || alucontrol==3'b101) ? (srca | srcb) :
                          (alucontrol==3'b010 || alucontrol==3'b110) ? sum           :
                          {31'b0, sum[31]}; // seleciona a operação a ser feita
  wire zero = (aluresult == 32'b0); // resultado usado pelo 'beq' para ver se é igual a zero
  wire pcen = pcwrite | (branch & zero); // 'write enable' do PC
  wire [31:0] pcnext = pcsrc[0] ? aluout : aluresult; // qual valor a ser pego? O do último ciclo (aluout) ou o atual (aluresult)?

  assign writedata = b; // guarda rs2 na memória
  
  // os 7 registrados e os estados
  always @(posedge clk, posedge reset)
    if (reset) begin // reseta todas as 'variáveis'
      state <= FETCH; pc <= 0; pca <= 0; instr <= 0; data <= 0; a <= 0; b <= 0; aluout <= 0;
    end else begin
      state <= nextstate;
      if (pcen) pc <= pcnext; // se for pra escrever, salva o próximo como pc
      if (pcen) pca <= pc;    // e salva o anterior como pca
      if (irwrite) instr <= readdata; // coloca a palavra lida no registrador de instrução
      data <= readdata; // captura qualquer memória lida para dados
      a <= rd1;
      b <= rd2;
      aluout <= aluresult; // deixa o resultado salvo para os próximos ciclos (máquina de estados)
    end

  always @(posedge clk)
    if (regwrite) rf[rdId] <= wd3; // guardar wd3 no registrador rdId
endmodule
