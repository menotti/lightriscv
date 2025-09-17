module testbench();

  logic        clk;
  logic        reset;

  logic [31:0] writedata, adr, readdata;
  logic        memwrite;
  
    
  // microprocessor (control & datapath)
  riscvmulti riscvmulti(clk, reset, adr, writedata, memwrite, readdata);

  // memory 
  mem #("fibo.hex") mem(clk, memwrite, adr, writedata, readdata);
  
  // initialize test
  initial
    begin
      // $monitor("time=%0t, pc=%h, instr=%h, state=%4b, aluIn1=%h, aluIn2=%h, aluOut=%h", $time, riscvmulti.dp.pc, riscvmulti.dp.instrreg.q, riscvmulti.c.md.state, riscvmulti.dp.alu.a, riscvmulti.dp.alu.b, riscvmulti.dp.alu.result);
      $dumpfile("dump.vcd"); $dumpvars(0);
      reset <= 1; #22 reset <= 0;
      #42000 $finish;
    end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

  // check results
  always @(negedge clk)
    begin
      if(memwrite) begin
        if(adr>>2 === 32'h0000006f && writedata === 32'h6d73e55f) begin
          $display("Simulation succeeded!");
          //$writememh("fibo_ok.hex", mem.RAM);
          $finish;
        end
      end
    end
endmodule