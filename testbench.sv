module testbench();
  logic clk, reset, memwrite;
  logic [31:0] writedata, addr, readdata, pc, instr;

  // Von Neumann architecture
  `ifdef MULTI
    `ifdef STRUCT
      initial $display("### Compiling for Von Neumann architecture (structural) ###");
      riscvmulti_struct cpu(clk, reset, addr, writedata, memwrite, readdata);
    `else 
      initial $display("### Compiling for Von Neumann architecture (dataflow) ###");
      riscvmulti_combin cpu(clk, reset, addr, writedata, memwrite, readdata);
    `endif
    mem #("von_neumann.hex") mem(clk, memwrite, addr, writedata, readdata);
  `else
    // Harvard architecture
    `ifdef STRUCT
      initial begin $display("### Harvard architecture (structural) not available! ###");
      $finish; end
    `else
      initial $display("### Compiling for Harvard architecture (dataflow) ###");
      riscvmono cpu(clk, reset, pc, instr, addr, writedata, memwrite, readdata);
    `endif
    mem #("harvard_text.hex") instr_rom(.a(pc), .rd(instr));
    mem #("harvard_data.hex") data_ram(clk, memwrite, addr, writedata, readdata);

  `endif

  // initialize test
  initial
    begin
      $dumpfile("dump.vcd"); $dumpvars(0);
      reset <= 1; #20 reset <= 0;
      `ifdef MULTI
        `ifdef STRUCT
          $monitor("time=%5t, pc=%h, instr=%h, state=%4b, SrcA=%h, SrcB=%h, ALUResult=%h", $time, cpu.dp.pc, cpu.dp.instrreg.q, cpu.c.md.state, cpu.dp.alu.a, cpu.dp.alu.b, cpu.dp.alu.result); // multicycle structural style
          $writememh("registers.out", cpu.dp.rf.rf);
        `else
          $monitor("time=%5t, pc=%h, instr=%h, state=%4b, SrcA=%h, SrcB=%h, ALUResult=%h", $time, cpu.pc, cpu.instr, cpu.state, cpu.srca, cpu.srcb, cpu.aluresult); // multicycle dataflow style
          $writememh("registers.out", cpu.rf);
        `endif
        $writememh("von_neumann.out", mem.RAM);
        #12000;
        $display("Multi-cycle simulation unsucceeded!");
      `else
        `ifdef STRUCT
          $display("### Harvard architecture (structural) not available! ###");
          $finish;
        `else
          $monitor("time=%4t, pc=%h, instr=%h, SrcA=%h, SrcB=%h, ALUResult=%h", $time, pc, instr, cpu.SrcA, cpu.SrcB, cpu.ALUResult); // singlecycle
          $writememh("registers.out", cpu.RegisterFile);
        `endif
        $writememh("harvard_data.out", data_ram.RAM);
        #3000;
        $display("Single-cycle simulation unsucceeded!");
      `endif
      $finish;
    end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

  // check results
  always @(negedge clk)
    if (memwrite)
      `ifdef MULTI
        if (addr>>2 === 32'h0000006f && writedata === 32'h6d73e55f) begin
          `ifdef STRUCT 
            #10 $display("Multi-cycle (structural) simulation succeeded!");
            $writememh("registers.out", cpu.dp.rf.rf);
          `else
            #10 $display("Multi-cycle (dataflow) simulation succeeded!");
            $writememh("registers.out", cpu.rf);
          `endif 
          $writememh("von_neumann.out", mem.RAM);
      `else
        `ifdef STRUCT
          if (1'b1) begin
        `else
          if (addr>>2 === 32'h0000002e && writedata === 32'h6d73e55f) begin
            #10 $display("Single-cycle simulation succeeded!");
            $writememh("registers.out", cpu.RegisterFile);
            $writememh("harvard_data.out", data_ram.RAM);
        `endif
      `endif
        $finish;
      end
endmodule
