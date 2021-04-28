`include "sparse_csr_tc.svh"

module sparse_csr_tb();
   sparse_csr_tc #(.ROWS(7),.COLS(13),.DENSITY(75)
                ) dut;
   
   initial begin
      dut = new();

      dut.dump();
   end
   
endmodule // sparse_csr_tb
