/*  ISC License
 *
 *  Basic RAM model with separate read/write ports and byte-wise write enable
 *
 *  Copyright (C) 2019  Olof Kindgren <olof.kindgren@gmail.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
module dpram_generic
  #(parameter SIZE=0,
    parameter DW=64,
    parameter memfile = "")
  (input wire clk,
   input wire [DW/8-1:0] 	 we,
   input wire [DW-1:0] 		 din,
   input wire [$clog2(SIZE)-1:0] waddr,
   input wire [$clog2(SIZE)-1:0] raddr,
   output reg [DW-1:0] 		 dout);

   localparam AW = $clog2(SIZE);

   reg [7:0] 			 mem [0:SIZE-1] /* verilator public */;

   integer 	 i;

   always @(posedge clk) begin
      for (i=0;i<8;i=i+1) begin
	 if (we[i]) mem[waddr+i[AW-1:0]] <= din[i*8+:8];//FIXME: BE?
	 dout[i*8+:8] <= mem[raddr+i[AW-1:0]];
      end
   end

   generate
      initial
	if(|memfile) begin
	   $display("Preloading %m from %s", memfile);
	   $readmemh(memfile, mem);
	end
   endgenerate

endmodule
