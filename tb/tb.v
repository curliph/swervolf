/*  ISC License
 *
 *  Verilog testbench for SweRV SoC
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
`default_nettype none
module tb
`ifdef VERILATOR
  (input clk,
   input rst)
`endif
  ;

`ifndef VERILATOR
   reg 	 clk = 1'b0;
   reg 	 rst = 1'b1;
   always #5 clk <= !clk;
   initial #100 rst <= 1'b0;
`endif

   localparam LSU_MEM_SIZE = 32'h1000000;
   localparam IFU_MEM_SIZE = 32'h1000000;

   wire        lsu_we    ;
   wire [31:0] lsu_addr  ;
   wire [7:0]  lsu_be    ;
   wire [63:0] lsu_wrdata;
   wire [63:0] lsu_rdata ;

   wire        ifu_we    ;
   wire [31:0] ifu_addr  ;
   wire [7:0]  ifu_be    ;
   wire [63:0] ifu_wrdata;
   wire [63:0] ifu_rdata ;

   reg [1023:0] ifu_mem_file;
   reg [1023:0] lsu_mem_file;
   reg [1023:0] signature_file;

   AXI_BUS #(32, 64, 3, 3) ifu;
   AXI_BUS #(32, 64, 3, 3) lsu;

   integer 	f = 0;
   initial begin
      if ($value$plusargs("ifu_mem_file=%s", ifu_mem_file)) begin
	 $display("Loading IFU mem from %0s", ifu_mem_file);
	 $readmemh(ifu_mem_file, ifu_mem.mem);
      end
      if ($value$plusargs("lsu_mem_file=%s", lsu_mem_file)) begin
	 $display("Loading LSU mem from %0s", lsu_mem_file);
	 $readmemh(lsu_mem_file, lsu_mem.mem);
      end

      if ($value$plusargs("signature=%s", signature_file)) begin
	 $display("Writing signature to %0s", signature_file);
	 f = $fopen(signature_file, "w");
      end
   end

   always @(posedge clk) begin
      if (lsu_we & (lsu_addr == 32'h10000000)) begin
	 $fwrite(f, "%c", lsu_wrdata[7:0]);
	 $write("%c", lsu_wrdata[7:0]);
      end
      if (lsu_we & (lsu_addr == 32'h20000000)) begin
	 $display("Finito");
	 $finish;
      end
   end


   axi2mem
     #(.AXI_ID_WIDTH   (`RV_IFU_BUS_TAG),
       .AXI_ADDR_WIDTH (32),
       .AXI_DATA_WIDTH (64),
       .AXI_USER_WIDTH (0))
   ifu_axi2mem
     (.clk_i  (clk),
      .rst_ni (!rst),
      .slave  (ifu),
      .req_o  (),
      .we_o   (),
      .addr_o (ifu_addr),
      .be_o   (),
      .data_o (),
      .data_i (ifu_rdata));

   dpram_generic
     #(.SIZE (IFU_MEM_SIZE))
   ifu_mem
     (.clk   (clk),
      .we    (8'd0),
      .din   (64'd0),
      .waddr ('0),
      .raddr ({ifu_addr[$clog2(IFU_MEM_SIZE)-1:3],3'b000}),
      .dout  (ifu_rdata));

   axi2mem
     #(.AXI_ID_WIDTH   (`RV_LSU_BUS_TAG),
       .AXI_ADDR_WIDTH (32),
       .AXI_DATA_WIDTH (64),
       .AXI_USER_WIDTH (0))
   lsu_axi2mem
     (.clk_i  ( clk       ),
      .rst_ni ( !rst      ),
      .slave  ( lsu       ),
      .req_o  (           ),
      .we_o   ( lsu_we    ),
      .addr_o ( lsu_addr  ),
      .be_o   ( lsu_be    ),
      .data_o ( lsu_wrdata),
      .data_i ( lsu_rdata ));

   dpram_generic
     #(.SIZE (LSU_MEM_SIZE))
   lsu_mem
     (.clk   (clk),
      .we    (lsu_be & {8{lsu_we}}),
      .din   (lsu_wrdata),
      .waddr ({lsu_addr[$clog2(LSU_MEM_SIZE)-1:3],3'b000}),
      .raddr ({lsu_addr[$clog2(LSU_MEM_SIZE)-1:3],3'b000}),
      .dout  (lsu_rdata));

swerv_wrapper rvtop
  (
   .clk     (clk),
   .rst_l   (!rst),
   .rst_vec (31'h80000000), //FIXME?
   .nmi_int (1'b0),
   .nmi_vec (31'hee000000),

   .trace_rv_i_insn_ip      (),
   .trace_rv_i_address_ip   (),
   .trace_rv_i_valid_ip     (),
   .trace_rv_i_exception_ip (),
   .trace_rv_i_ecause_ip    (),
   .trace_rv_i_interrupt_ip (),
   .trace_rv_i_tval_ip      (),

   // Bus signals

   //-------------------------- LSU AXI signals--------------------------
   // AXI Write Channels
   .lsu_axi_awvalid  (lsu.aw_valid ),
   .lsu_axi_awready  (lsu.aw_ready ),
   .lsu_axi_awid     (lsu.aw_id    ),
   .lsu_axi_awaddr   (lsu.aw_addr  ),
   .lsu_axi_awregion (lsu.aw_region),
   .lsu_axi_awlen    (lsu.aw_len   ),
   .lsu_axi_awsize   (lsu.aw_size  ),
   .lsu_axi_awburst  (lsu.aw_burst ),
   .lsu_axi_awlock   (lsu.aw_lock  ),
   .lsu_axi_awcache  (lsu.aw_cache ),
   .lsu_axi_awprot   (lsu.aw_prot  ),
   .lsu_axi_awqos    (lsu.aw_qos   ),

   .lsu_axi_wvalid   (lsu.w_valid),
   .lsu_axi_wready   (lsu.w_ready),
   .lsu_axi_wdata    (lsu.w_data ),
   .lsu_axi_wstrb    (lsu.w_strb ),
   .lsu_axi_wlast    (lsu.w_last ),

   .lsu_axi_bvalid   (lsu.b_valid),
   .lsu_axi_bready   (lsu.b_ready),
   .lsu_axi_bresp    (lsu.b_resp),
   .lsu_axi_bid      (lsu.b_id  ),

   // AXI Read Channels
   .lsu_axi_arvalid  (lsu.ar_valid ),
   .lsu_axi_arready  (lsu.ar_ready ),
   .lsu_axi_arid     (lsu.ar_id    ),
   .lsu_axi_araddr   (lsu.ar_addr  ),
   .lsu_axi_arregion (lsu.ar_region),
   .lsu_axi_arlen    (lsu.ar_len   ),
   .lsu_axi_arsize   (lsu.ar_size  ),
   .lsu_axi_arburst  (lsu.ar_burst ),
   .lsu_axi_arlock   (lsu.ar_lock  ),
   .lsu_axi_arcache  (lsu.ar_cache ),
   .lsu_axi_arprot   (lsu.ar_prot  ),
   .lsu_axi_arqos    (lsu.ar_qos   ),

   .lsu_axi_rvalid   (lsu.r_valid),
   .lsu_axi_rready   (lsu.r_ready),
   .lsu_axi_rid      (lsu.r_id   ),
   .lsu_axi_rdata    (lsu.r_data ),
   .lsu_axi_rresp    (lsu.r_resp ),
   .lsu_axi_rlast    (lsu.r_last ),

   //-------------------------- IFU AXI signals--------------------------
   // AXI Write Channels
   .ifu_axi_awvalid  (),
   .ifu_axi_awready  (1'b0),
   .ifu_axi_awid     (),
   .ifu_axi_awaddr   (),
   .ifu_axi_awregion (),
   .ifu_axi_awlen    (),
   .ifu_axi_awsize   (),
   .ifu_axi_awburst  (),
   .ifu_axi_awlock   (),
   .ifu_axi_awcache  (),
   .ifu_axi_awprot   (),
   .ifu_axi_awqos    (),

   .ifu_axi_wvalid   (),
   .ifu_axi_wready   (1'b0),
   .ifu_axi_wdata    (),
   .ifu_axi_wstrb    (),
   .ifu_axi_wlast    (),

   .ifu_axi_bvalid   (1'b0),
   .ifu_axi_bready   (),
   .ifu_axi_bresp    (2'b00),
   .ifu_axi_bid      (),

   // AXI Read Channels
   .ifu_axi_arvalid  (ifu.ar_valid ),
   .ifu_axi_arready  (ifu.ar_ready ),
   .ifu_axi_arid     (ifu.ar_id    ),
   .ifu_axi_araddr   (ifu.ar_addr  ),
   .ifu_axi_arregion (ifu.ar_region),
   .ifu_axi_arlen    (ifu.ar_len   ),
   .ifu_axi_arsize   (ifu.ar_size  ),
   .ifu_axi_arburst  (ifu.ar_burst ),
   .ifu_axi_arlock   (ifu.ar_lock  ),
   .ifu_axi_arcache  (ifu.ar_cache ),
   .ifu_axi_arprot   (ifu.ar_prot  ),
   .ifu_axi_arqos    (ifu.ar_qos   ),

   .ifu_axi_rvalid   (ifu.r_valid),
   .ifu_axi_rready   (ifu.r_ready),
   .ifu_axi_rid      (ifu.r_id   ),
   .ifu_axi_rdata    (ifu.r_data ),
   .ifu_axi_rresp    (ifu.r_resp ),
   .ifu_axi_rlast    (ifu.r_last ),

   //-------------------------- SB AXI signals-------------------------
   // AXI Write Channels
   .sb_axi_awvalid  (),
   .sb_axi_awready  (1'b0),
   .sb_axi_awid     (),
   .sb_axi_awaddr   (),
   .sb_axi_awregion (),
   .sb_axi_awlen    (),
   .sb_axi_awsize   (),
   .sb_axi_awburst  (),
   .sb_axi_awlock   (),
   .sb_axi_awcache  (),
   .sb_axi_awprot   (),
   .sb_axi_awqos    (),

   .sb_axi_wvalid   (),
   .sb_axi_wready   (1'b0),
   .sb_axi_wdata    (),
   .sb_axi_wstrb    (),
   .sb_axi_wlast    (),

   .sb_axi_bvalid   (1'b0),
   .sb_axi_bready   (),
   .sb_axi_bresp    (2'b00),
   .sb_axi_bid      (`RV_SB_BUS_TAG'd0),

   // AXI Read Channels
   .sb_axi_arvalid  (),
   .sb_axi_arready  (1'b0),
   .sb_axi_arid     (),
   .sb_axi_araddr   (),
   .sb_axi_arregion (),
   .sb_axi_arlen    (),
   .sb_axi_arsize   (),
   .sb_axi_arburst  (),
   .sb_axi_arlock   (),
   .sb_axi_arcache  (),
   .sb_axi_arprot   (),
   .sb_axi_arqos    (),

   .sb_axi_rvalid   (1'b0),
   .sb_axi_rready   (),
   .sb_axi_rid      (`RV_SB_BUS_TAG'd0),
   .sb_axi_rdata    (64'd0),
   .sb_axi_rresp    (2'b00),
   .sb_axi_rlast    (1'b0),

   //-------------------------- DMA AXI signals--------------------------
   // AXI Write Channels
   .dma_axi_awvalid  (1'b0),
   .dma_axi_awready  (),
   .dma_axi_awid     (`RV_DMA_BUS_TAG'd0),
   .dma_axi_awaddr   (32'd0),
   .dma_axi_awsize   (3'd0),
   .dma_axi_awprot   (3'd0),
   .dma_axi_awlen    (8'd0),
   .dma_axi_awburst  (2'd0),

   .dma_axi_wvalid   (1'b0),
   .dma_axi_wready   (),
   .dma_axi_wdata    (64'd0),
   .dma_axi_wstrb    (8'd0),
   .dma_axi_wlast    (1'b0),

   .dma_axi_bvalid   (),
   .dma_axi_bready   (1'b0),
   .dma_axi_bresp    (),
   .dma_axi_bid      (),

   // AXI Read Channels
   .dma_axi_arvalid  (1'b0),
   .dma_axi_arready  (),
   .dma_axi_arid     (`RV_DMA_BUS_TAG'd0),
   .dma_axi_araddr   (32'd0),
   .dma_axi_arsize   (3'd0),
   .dma_axi_arprot   (3'd0),
   .dma_axi_arlen    (8'd0),
   .dma_axi_arburst  (2'd0),

   .dma_axi_rvalid   (),
   .dma_axi_rready   (1'b0),
   .dma_axi_rid      (),
   .dma_axi_rdata    (),
   .dma_axi_rresp    (),
   .dma_axi_rlast    (),

   // clk ratio signals
   .lsu_bus_clk_en (1'b1),
   .ifu_bus_clk_en (1'b1),
   .dbg_bus_clk_en (1'b0),
   .dma_bus_clk_en (1'b0),


//   input logic                   ext_int,
   .timer_int (1'b0),
   .extintsrc_req ('0),

   .dec_tlu_perfcnt0 (),
   .dec_tlu_perfcnt1 (),
   .dec_tlu_perfcnt2 (),
   .dec_tlu_perfcnt3 (),

   .jtag_tck    (1'b0), // JTAG clk
   .jtag_tms    (1'b0), // JTAG TMS
   .jtag_tdi    (1'b0), // JTAG tdi
   .jtag_trst_n (1'b0), // JTAG Reset
   .jtag_tdo    (), // JTAG TDO

   .i_cpu_halt_req      (1'b0),
   .o_cpu_halt_ack      (),
   .o_cpu_halt_status   (),
   .o_debug_mode_status (),
   .i_cpu_run_req       (1'b0),
   .o_cpu_run_ack       (),

   .scan_mode  (1'b0),
   .mbist_mode (1'b0));

endmodule
