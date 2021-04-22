// testcase for multiplying two sparse matrices in CSR format
// creates two random matrices, computes expected result in CSR format
// and provides methods to navigate it from
// a testbench

`include "sparse_csr.svh"

class sparse_csr_tc #(parameter ROWS=1024,
                      parameter COLS=1024,
                      parameter DENSITY=5 // percentage nz
                   );

   // A is ROWSxCOLS, B is COLSxROWS, C is ROWSxROWS

   sparse_csr #(.ROWS(ROWS),.COLS(COLS),.DENSITY(DENSITY)
                ) A;
   sparse_csr #(.ROWS(COLS),.COLS(ROWS),.DENSITY(DENSITY)
                ) B;
   
   // CSR for C = AxB
   int nnz;
   int rows;
   int cols;
   int rowptr[ROWS+1];
   int colindex[];
   bit [63:0] value[];
   
   function new();
      int     currnz;
      rows = ROWS;
      cols = COLS;

      A = new();
      B = new();

      // could instead estimate worst case size of C per
      // Matthias Boehm et al. 2014
      // SystemML’s Optimizer: Plan Generation for Large-Scale Machine Learning Programs.
      // IEEE Data Eng. Bull. 37, 3 (2014), 52–62
      // but for now I will traverse A & B twice, first to count nnz, then to multiply
          
      nnz = 0;
      for(int Arow=A.firstrow();Arow!=-1;Arow=A.nextrow(Arow)) begin
         for(int Bcol=0;Bcol<B.cols;++Bcol) begin
            for(int Acolpos=A.firstcolpos(Arow);Acolpos!=-1;Acolpos=A.nextcolpos(Arow,Acolpos)) begin
               if (B.getpos(A.getcol(Acolpos),Bcol) != -1) begin
                  ++nnz; // found one partial product; assume no cancellation errors
                  break; // skip to next col of B
               end // if
            end // for(int Acolpos
         end // for(int Bcol
      end // for(int Arow

      // allocate space in colindex and value
      colindex = new [nnz];
      value = new [nnz];

      // perform actual matrix multiplication
      //for(int Arow=A.firstrow();Arow!=-1;Arow=A.nextrow(Arow)) begin
      currnz = 0;
      for(int Arow=0;Arow<A.rows;++Arow) begin
         for(int Bcol=0;Bcol<B.cols;++Bcol) begin
            real partialproduct = 0.0;
            bit  nz = 1'b0;
            for(int Acolpos=A.firstcolpos(Arow);Acolpos!=-1;Acolpos=A.nextcolpos(Arow,Acolpos)) begin
               int Bcolpos = B.getpos(A.getcol(Acolpos),Bcol);
               if (Bcolpos != -1) begin
                  partialproduct += $bitstoreal(A.getval(Acolpos)) * $bitstoreal(B.getval(Bcolpos));
               end
            end
            if (nz) begin
               value[currnz] = $realtobits(partialproduct);
               colindex[currnz] = Bcol;
               ++currnz;
            end // if (nz)
         end // for (int Bcol=0;Bcol<B.cols;++Bcol)
         rowptr[Arow] = currnz;
      end // for (int Arow=A.firstrow();Arow!=-1;Arow=A.nextrow(Arow))
      
      assert(currnz == nnz);

   endfunction: new

   function void dump();
      int maxrows = (A.rows > B.rows) ? A.rows : B.rows;
      // display A,B,C for debugging purposes
      $display("C = A x B");
      for(int Row=0;Row<maxrows;++Row) begin
         for(int Col=0;Col<cols;++Col) begin
            int pos = getpos(Row,Col);
            real val = (pos != -1) ? $bitstoreal(getval(pos)) : 0.0;
            if (Row > rows)
              $write("      ");
            else
              $write("%5.0f ",val);
         end
         $write("  ");
         for(int Col=0;Col<A.cols;++Col) begin
            int pos = A.getpos(Row,Col);
            real val = (pos != -1) ? $bitstoreal(A.getval(pos)) : 0.0;
            if (Row > A.rows)
              $write("      ");
            else
              $write("%5.0f ",val);
         end
         $write("  ");
         for(int Col=0;Col<B.cols;++Col) begin
            int pos = B.getpos(Row,Col);
            real val = (pos != -1) ? $bitstoreal(B.getval(pos)) : 0.0;
            if (Row > B.rows)
              $write("      ");
            else
              $write("%5.0f ",val);
         end
         $write("\n");
      end // for (int Row=0;Row<DIM;++Row)
   endfunction: dump

   function int getpos(int row, int col);
      for(int currpos=rowptr[row]; (currpos < rowptr[row+1]) && (colindex[currpos] <= col); ++currpos) begin
         if (colindex[currpos] == col)
           return currpos;
      end
      return -1; // flags that entry is not found, value implicitly zero
   endfunction: getpos
   
   // hackish; refactor so that C is also a sparse_csr
   function int getcol(int pos);
      return colindex[pos];
   endfunction: getcol
   
   function bit [63:0] getval(int pos);
      return value[pos];
   endfunction: getval
      
endclass // sparse_csr_tc


