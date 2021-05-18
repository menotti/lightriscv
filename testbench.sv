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
          $finish;
        end
      end
    end
endmodule