// testcase for sparse matrix using CSR format
// populates CSR structure with random values
// and provides methods to navigate it from
// a testbench
class sparse_csr #(parameter ROWS=1024,
                   parameter COLS=1024,
                   parameter DENSITY=5 // percentage nz
                   localparam ISZERO=100-DENSITY; 
                   );

   int nnz;
   int rows;
   int cols;
   int rowptr[ROWS+1];
   int colindex[];
   bit [63:0] value[];
   
   
   function new();
      rows = ROWS;
      cols = COLS;
      nnz = 0;

      bit mask[ROWS][COLS];
      mask = '{default:0};

      // determine NNZ values in bitmask
      for(int Row=0;Row<rows;++Row) begin
	     for(int Col=0;Col<cols;++Col) begin
            randcase
              DENSITY: begin
                 mask[Row][Col] = 1'b1;
                 nnz += 1;
              end
              ISZERO:
                mask[Row][Col] = 1'b0;
            endcase // randcase
         end
      end // for (int Row=0;Row<rows;++Row)

      // allocate space in colindex and value
      colindex = new [nnz];
      value = new [nnz];

      // populate CSR structures
      int currnz = 0;
      for(int Row=0;Row<rows;++Row) begin
         rowptr[Row] = currnz;
	     for(int Col=0;Col<cols;++Col) begin
            if (mask[Row][Col]) begin
               colindex[currnz] = Col;
               value[currnz] = randomreal();
               currnz = currnz + 1;
            end
         end
      end
      rowptr[rows] = currnz;
      assert(currnz == nnz + 1);
   endfunction: new

   // access functions


   // generate random double value:
   // 1 bit sign, 11 bit exponent, 52 bit fraction
   // should be easy to modify for single precision:
   // (1 bit sign, 8 bit exponent, 23 bit fraction)
   function bit [63:0] randomreal();
      bit sign = $urandom() & 1'b1;
      bit [10:0] exp = $urandom() & {11{1'b1}};
      bit [51:0] frac = {$urandom() & {20{1'b1}},$urandom()};
      // get rid of denorms (0 exp, nonzero frac)
      if (exp == 11'b0)
        frac = 52'b0;
      // get rid of NaN/infinity (max exp)
      if (exp == 11'd2047) // 255 for SP
        exp = 11'd2046;
      return {sign,exp,frac};
   endfunction // randomreal
      
endclass // sparse_csr


