module mem #(parameter FILENAME = "memfile.hex")
          (input  logic        clk, we,
           input  logic [31:0] a, wd,
           output logic [31:0] rd);

  logic  [31:0] RAM [0:511];

  // initialize memory with instructions
  initial
    $readmemh(FILENAME, RAM);

  assign rd = RAM[a[31:2]]; // word aligned

  always_ff @(posedge clk)
    if (we)
      RAM[a[31:2]] <= wd;
endmodule