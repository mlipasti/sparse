// testcase for sparse matrix using CSR format
// populates CSR structure with random values
// and provides methods to navigate it from
// a testbench
class sparse_csr #(parameter ROWS=1024,
                   parameter COLS=1024,
                   parameter DENSITY=5 // percentage nz
                   );

   localparam ISZERO=100-DENSITY;
   
   int nnz;
   int rows;
   int cols;
   int rowptr[ROWS+1];
   int colindex[];
   bit [63:0] value[];
   
   
   function new();

      bit mask[ROWS][COLS];
      int currnz = 0;

      rows = ROWS;
      cols = COLS;
      nnz = 0;

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
   function int getpos(int row, int col);
      for(int currpos=rowptr[row]; (currpos < rowptr[row+1]) && (colindex[currpos] <= col); ++currpos) begin
         if (colindex[currpos] == col)
           return currpos;
      end
      return -1; // flags that entry is not found, value implicitly zero
   endfunction: getpos
   
   function int getcol(int pos);
      return colindex[pos];
   endfunction: getcol
   
   function bit [63:0] getval(int pos);
      return value[pos];
   endfunction: getval

   // iterators
   // row iterators return row numbers
   function int firstrow();
      return nextrow(0);
   endfunction: firstrow

   function int nextrow(int currrow);
      int retval=currrow;
      while((retval < rows) && (rowptr[retval] == rowptr[++retval])) begin
      end
      return (retval < rows) ? retval - 1 : -1;
   endfunction: nextrow

   // column iterators return position (index into col/value vectors)
   function int firstcolpos(int row);
      return nextcolpos(row,0);
   endfunction: firstcolpos

   function int nextcolpos(int row, int currpos);
      int retval=currpos+1;
      return (retval < rowptr[row+1]) ? retval : -1;
   endfunction: nextcolpos



   // generate random double value:
   // 1 bit sign, 11 bit exponent, 52 bit fraction
   // should be easy to modify for single precision:
   // (1 bit sign, 8 bit exponent, 23 bit fraction)
   function bit [63:0] randomreal();
      //bit sign = $urandom() & 1'b1;
      //bit [10:0] expo = $urandom() & {11{1'b1}};
      //bit [51:0] frac = {$urandom() & {20{1'b1}},$urandom()};
      // get rid of denorms (0 exp, nonzero frac)
      //if (expo == 11'b0)
      //  frac = 52'b0;
      // get rid of NaN/infinity (max exp)
      //if (expo == 11'd2047) // 255 for SP
      //  expo = 11'd2046;
      //return {sign,expo,frac};

      // decided to use $realtobits instead so I have small numbers for easy mental sanity checks
      // this won't test the FP add/mult logic but we'll assume that works for now
      int inum = $urandom_range(1,5);
      real rnum = inum;
      return $realtobits(rnum);
   endfunction // randomreal
      
endclass // sparse_csr


