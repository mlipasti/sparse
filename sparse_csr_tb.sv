`include "sparse_csr_tc.svh"

module sparse_csr_tb();
   sparse_csr_tc #(.ROWS(8),.COLS(4),.DENSITY(5)
                ) dut;
   
   initial begin
      dut = new();

      dut.dump();
   end
   
endmodule // sparse_csr_tb
