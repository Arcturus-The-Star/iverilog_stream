// Based on file authored by Andres Meza

`timescale 1 ns / 1 ps

`define NUM_RAND_TEST_ROUNDS 4

`define HW_NUM_R_TRANS 4
`define HW_NUM_W_TRANS 4

`define HW_W_BURST_SIZE 8
`define HW_R_BURST_SIZE 8

`define HW_R_BASE_ADDR  'h30000000
`define HW_W_BASE_ADDR  'ha0000000

`define AC_R_LOW_ADDR_1   16'h2000
`define AC_R_HIGH_ADDR_1  16'h4000
`define AC_R_LOW_ADDR_2   16'h7000
`define AC_R_HIGH_ADDR_2  16'ha000

`define AC_W_LOW_ADDR_1   16'h0000
`define AC_W_HIGH_ADDR_1  16'hb000
`define AC_W_LOW_ADDR_2   16'hc000
`define AC_W_HIGH_ADDR_2  16'hf000

`define READ_TEST       1
`define WRITE_TEST      1

`define ILL_TRANS       0

`define ENABLED_REGIONS 32'hffffffff    // | 31 W REGIONS 16 | 15 R REGIONS 0 |

module test();

  localparam integer C_S_AXI_DATA_WIDTH	= 32;
  localparam integer C_S_AXI_ADDR_WIDTH = 8;

  localparam integer C_M_AXI_BURST_LEN    = 16;
  localparam integer C_M_AXI_ID_WIDTH     = 1;
  localparam integer C_M_AXI_ADDR_WIDTH   = 32;
  localparam integer C_M_AXI_DATA_WIDTH   = 32;
  localparam integer C_M_AXI_ARUSER_WIDTH = 1;
  localparam integer C_M_AXI_AWUSER_WIDTH = 1;
  localparam integer C_M_AXI_WUSER_WIDTH  = 1;
  localparam integer C_M_AXI_RUSER_WIDTH  = 1;
  localparam integer C_M_AXI_BUSER_WIDTH  = 1;

  logic                                tb_aclk = 0;
  logic                                tb_aresetn = 1;
  logic                                tb_done = 0;
  logic                                tb_intr_line_r;
  logic                                tb_intr_line_w;

  logic [C_S_AXI_ADDR_WIDTH-1 : 0]     tb_s_axi_awaddr = 0;
  logic [2 : 0]                        tb_s_axi_awprot;
  logic                                tb_s_axi_awvalid = 0;
  logic                                tb_s_axi_awready;

  logic [C_S_AXI_DATA_WIDTH-1 : 0]     tb_s_axi_wdata = 0;
  logic [(C_S_AXI_DATA_WIDTH/8)-1 : 0] tb_s_axi_wstrb = 0;
  logic                                tb_s_axi_wvalid = 0;
  logic                                tb_s_axi_wready;

  logic [1 : 0]                        tb_s_axi_bresp;
  logic                                tb_s_axi_bvalid;
  logic                                tb_s_axi_bready;

  logic [C_S_AXI_ADDR_WIDTH-1 : 0]     tb_s_axi_araddr = 0;
  logic [2 : 0]                        tb_s_axi_arprot;
  logic                                tb_s_axi_arvalid = 0;
  logic                                tb_s_axi_arready;

  logic [C_S_AXI_DATA_WIDTH-1 : 0]     tb_s_axi_rdata;
  logic [1 : 0]                        tb_s_axi_rresp;
  logic                                tb_s_axi_rvalid;
  logic                                tb_s_axi_rready;

  logic [C_M_AXI_ID_WIDTH-1 : 0]       tb_m_axi_awid;
  logic [C_M_AXI_ADDR_WIDTH-1 : 0]     tb_m_axi_awaddr;
  logic [7 : 0]                        tb_m_axi_awlen;
  logic [2 : 0]                        tb_m_axi_awsize;
  logic [1 : 0]                        tb_m_axi_awburst;
  logic                                tb_m_axi_awlock;
  logic [3 : 0]                        tb_m_axi_awcache;
  logic [2 : 0]                        tb_m_axi_awprot;
  logic [3 : 0]                        tb_m_axi_awqos;
  logic [C_M_AXI_AWUSER_WIDTH-1 : 0]   tb_m_axi_awuser;
  logic                                tb_m_axi_awvalid;
  logic                                tb_m_axi_awready;

  logic [C_M_AXI_DATA_WIDTH-1 : 0]     tb_m_axi_wdata;
  logic [(C_M_AXI_DATA_WIDTH/8)-1 : 0] tb_m_axi_wstrb;
  logic                                tb_m_axi_wlast;
  logic [C_M_AXI_WUSER_WIDTH-1 : 0]    tb_m_axi_wuser;
  logic                                tb_m_axi_wvalid;
  logic                                tb_m_axi_wready;

  logic [C_M_AXI_ID_WIDTH-1 : 0]       tb_m_axi_bid    = 0;
  logic [1 : 0]                        tb_m_axi_bresp  = 0;
  logic [C_M_AXI_BUSER_WIDTH-1 : 0]    tb_m_axi_buser  = 0;
  logic                                tb_m_axi_bvalid = 0;
  logic                                tb_m_axi_bready;

  logic [C_M_AXI_ID_WIDTH-1 : 0]       tb_m_axi_arid;
  logic [C_M_AXI_ADDR_WIDTH-1 : 0]     tb_m_axi_araddr;
  logic [7 : 0]                        tb_m_axi_arlen;
  logic [2 : 0]                        tb_m_axi_arsize;
  logic [1 : 0]                        tb_m_axi_arburst;
  logic                                tb_m_axi_arlock;
  logic [3 : 0]                        tb_m_axi_arcache;
  logic [2 : 0]                        tb_m_axi_arprot;
  logic [3 : 0]                        tb_m_axi_arqos;
  logic [C_M_AXI_ARUSER_WIDTH-1 : 0]   tb_m_axi_aruser;
  logic                                tb_m_axi_arvalid;
  logic                                tb_m_axi_arready;

  logic [C_M_AXI_ID_WIDTH-1 : 0]       tb_m_axi_rid    = 0;
  logic [C_M_AXI_DATA_WIDTH-1 : 0]     tb_m_axi_rdata  = 0;
  logic [1 : 0]                        tb_m_axi_rresp  = 0;
  logic                                tb_m_axi_rlast  = 0;
  logic [C_M_AXI_RUSER_WIDTH-1 : 0]    tb_m_axi_ruser  = 0;
  logic                                tb_m_axi_rvalid = 0;
  logic                                tb_m_axi_rready;

  logic                                tb_HW_r_start = 0;
  logic                                tb_HW_w_start = 0;
  logic                                tb_HW_reset   = 0; 
  logic [31:0]                         tb_HW_r_base_addr = 0;
  logic [31:0]                         tb_HW_w_base_addr = 0;
  logic [15:0]                         tb_HW_r_num_trans;
  logic [15:0]                         tb_HW_w_num_trans;
  
  logic [7:0]                          tb_HW_r_burst_len;
  logic [7:0]                          tb_HW_w_burst_len;
  logic                                tb_HW_data_val;
  //-- output done
  logic                                tb_HW_w_done;
  logic                                tb_HW_r_done;
  
  logic                                tb_illegal;
  logic                                tb_init_flag;


  logic tb_i_config = 0;
  logic [31 : 0] tb_o_data; 

  acw #(
    .C_S_CTRL_AXI(32),
    .C_S_CTRL_AXI_ADDR_WIDTH(8)
  )
  u0 (
    .ACLK               (tb_aclk),
    .ARESETN            (tb_aresetn),
    .INTR_LINE_R        (tb_intr_line_r),
    .INTR_LINE_W        (tb_intr_line_w),

    .r_start_wire       (tb_HW_r_start),
    .w_start_wire       (tb_HW_w_start),
    .reset_wire         (tb_HW_reset), 
    .r_base_addr_wire   (tb_HW_r_base_addr),
    .w_base_addr_wire   (tb_HW_w_base_addr),

    .r_num_trans_wire   (tb_HW_r_num_trans),
    .w_num_trans_wire   (tb_HW_w_num_trans),
    
    .r_burst_len_wire   (tb_HW_r_burst_len),
    .w_burst_len_wire   (tb_HW_w_burst_len),
    .data_val_wire      (tb_HW_data_val),

    .w_done_wire        (tb_HW_w_done),
    .r_done_wire        (tb_HW_r_done),

    .S_AXI_CTRL_AWADDR  (tb_s_axi_awaddr),
    .S_AXI_CTRL_AWPROT  (tb_s_axi_awprot),
    .S_AXI_CTRL_AWVALID (tb_s_axi_awvalid),
    .S_AXI_CTRL_AWREADY (tb_s_axi_awready),

    .S_AXI_CTRL_WDATA   (tb_s_axi_wdata),
    .S_AXI_CTRL_WSTRB   (tb_s_axi_wstrb),
    .S_AXI_CTRL_WVALID  (tb_s_axi_wvalid),
    .S_AXI_CTRL_WREADY  (tb_s_axi_wready),

    .S_AXI_CTRL_BRESP   (tb_s_axi_bresp),
    .S_AXI_CTRL_BVALID  (tb_s_axi_bvalid),
    .S_AXI_CTRL_BREADY  (tb_s_axi_bready),

    .S_AXI_CTRL_ARADDR  (tb_s_axi_araddr),
    .S_AXI_CTRL_ARPROT  (tb_s_axi_arprot),
    .S_AXI_CTRL_ARVALID (tb_s_axi_arvalid),
    .S_AXI_CTRL_ARREADY (tb_s_axi_arready),

    .S_AXI_CTRL_RDATA   (tb_s_axi_rdata),
    .S_AXI_CTRL_RRESP   (tb_s_axi_rresp),
    .S_AXI_CTRL_RVALID  (tb_s_axi_rvalid),
    .S_AXI_CTRL_RREADY  (tb_s_axi_rready),

    .M_AXI_AWID         (tb_m_axi_awid),
    .M_AXI_AWADDR       (tb_m_axi_awaddr),
    .M_AXI_AWLEN        (tb_m_axi_awlen),
    .M_AXI_AWSIZE       (tb_m_axi_awsize),
    .M_AXI_AWBURST      (tb_m_axi_awburst),
    .M_AXI_AWLOCK       (tb_m_axi_awlock),
    .M_AXI_AWCACHE      (tb_m_axi_awcache),
    .M_AXI_AWPROT       (tb_m_axi_awprot),
    .M_AXI_AWQOS        (tb_m_axi_awqos),
    .M_AXI_AWUSER       (tb_m_axi_awuser),
    .M_AXI_AWVALID      (tb_m_axi_awvalid),
    .M_AXI_AWREADY      (tb_m_axi_awready),

    .M_AXI_WDATA        (tb_m_axi_wdata),
    .M_AXI_WSTRB        (tb_m_axi_wstrb),
    .M_AXI_WLAST        (tb_m_axi_wlast),
    .M_AXI_WUSER        (tb_m_axi_wuser),
    .M_AXI_WVALID       (tb_m_axi_wvalid),
    .M_AXI_WREADY       (tb_m_axi_wready),

    .M_AXI_BID          (tb_m_axi_bid),
    .M_AXI_BRESP        (tb_m_axi_bresp),
    .M_AXI_BUSER        (tb_m_axi_buser),
    .M_AXI_BVALID       (tb_m_axi_bvalid),
    .M_AXI_BREADY       (tb_m_axi_bready),

    .M_AXI_ARID         (tb_m_axi_arid),
    .M_AXI_ARADDR       (tb_m_axi_araddr),
    .M_AXI_ARLEN        (tb_m_axi_arlen),
    .M_AXI_ARSIZE       (tb_m_axi_arsize),
    .M_AXI_ARBURST      (tb_m_axi_arburst),
    .M_AXI_ARLOCK       (tb_m_axi_arlock),
    .M_AXI_ARCACHE      (tb_m_axi_arcache),
    .M_AXI_ARPROT       (tb_m_axi_arprot),
    .M_AXI_ARQOS        (tb_m_axi_arqos),
    .M_AXI_ARUSER       (tb_m_axi_aruser),
    .M_AXI_ARVALID      (tb_m_axi_arvalid),
    .M_AXI_ARREADY      (tb_m_axi_arready),

    .M_AXI_RID          (tb_m_axi_rid),
    .M_AXI_RDATA        (tb_m_axi_rdata),
    .M_AXI_RRESP        (tb_m_axi_rresp),
    .M_AXI_RLAST        (tb_m_axi_rlast),
    .M_AXI_RUSER        (tb_m_axi_ruser),
    .M_AXI_RVALID       (tb_m_axi_rvalid),
    .M_AXI_RREADY       (tb_m_axi_rready),

    .i_config           (tb_i_config),
    .o_data             (tb_o_data)
  );

// ------------------- RESET THE DUT
  task reset_dut();
    repeat (4) #10;
    tb_HW_reset <= 1;
    tb_aresetn <= 0;
    repeat (4) #10;
    tb_HW_reset <= 0;
    tb_aresetn <= 1;
    #10;
  endtask : reset_dut
// ----------------END RESET THE DUT

  task test_round();
      reset_dut();

      $display("[ACW_tb] \ttb_HW_r_base_addr = %h", tb_HW_r_base_addr);
      $display("[ACW_tb] \ttb_HW_w_base_addr = %h", tb_HW_w_base_addr);

      repeat (4) @(posedge tb_aclk);

    //------------------ INITIAL CONFIGURATION
      tb_m_axi_rid    <= 0;
      tb_m_axi_rdata  <= 0;
      tb_m_axi_rresp  <= 0;
      tb_m_axi_rlast  <= 0;
      tb_m_axi_ruser  <= 0;
      tb_m_axi_rvalid <= 0;

      tb_m_axi_bid    <= 0;
      tb_m_axi_bresp  <= 0;
      tb_m_axi_buser  <= 0;
      tb_m_axi_bvalid <= 0;

      tb_init_flag    <= 1;
    //---------------END INITIAL CONFIGURATION

    //------------------ CONFIGURE THE ACCESS CONTROL: READ LOWER & UPPER BOUND

      tb_s_axi_awaddr <= {6'h06, 2'b00};
      tb_s_axi_awvalid <= 1;

      repeat (2) @(posedge tb_aclk);

      tb_s_axi_wdata <= {`AC_R_HIGH_ADDR_1, `AC_R_LOW_ADDR_1};
      tb_s_axi_wstrb <= 4'hf;
      tb_s_axi_wvalid <= 1;

      @(tb_s_axi_wvalid == 1 && tb_s_axi_awvalid == 1 && tb_s_axi_bvalid == 1);
      tb_s_axi_awvalid <= 0;
      tb_s_axi_wvalid <= 0;



      tb_s_axi_awaddr <= {6'h0a, 2'b00};
      tb_s_axi_awvalid <= 1;

      repeat (2) @(posedge tb_aclk);

      tb_s_axi_wdata <= {`AC_R_HIGH_ADDR_2, `AC_R_LOW_ADDR_2};
      tb_s_axi_wstrb <= 4'hf;
      tb_s_axi_wvalid <= 1;

      @(tb_s_axi_wvalid == 1 && tb_s_axi_awvalid == 1 && tb_s_axi_bvalid == 1);
      tb_s_axi_awvalid <= 0;
      tb_s_axi_wvalid <= 0;
    //---------------END CONFIGURE THE ACCESS CONTROL: READ LOWER & UPPER BOUND

    //------------------ CONFIGURE THE ACCESS CONTROL: WRITE LOWER & UPPER BOUND

      tb_s_axi_awaddr <= {6'h16, 2'b00};
      tb_s_axi_awvalid <= 1;

      repeat (2) @(posedge tb_aclk);

      tb_s_axi_wdata <= {`AC_W_HIGH_ADDR_1, `AC_W_LOW_ADDR_1};
      tb_s_axi_wstrb <= 4'hf;
      tb_s_axi_wvalid <= 1;

      @(tb_s_axi_wvalid == 1 && tb_s_axi_awvalid == 1 && tb_s_axi_bvalid == 1);
      tb_s_axi_awvalid <= 0;
      tb_s_axi_wvalid <= 0;


      tb_s_axi_awaddr <= {6'h19, 2'b00};
      tb_s_axi_awvalid <= 1;

      repeat (2) @(posedge tb_aclk);

      tb_s_axi_wdata <= {`AC_W_HIGH_ADDR_2, `AC_W_LOW_ADDR_2};
      tb_s_axi_wstrb <= 4'hf;
      tb_s_axi_wvalid <= 1;

      @(tb_s_axi_wvalid == 1 && tb_s_axi_awvalid == 1 && tb_s_axi_bvalid == 1);
      tb_s_axi_awvalid <= 0;
      tb_s_axi_wvalid <= 0;

    //---------------END CONFIGURE THE ACCESS CONTROL: WRITE LOWER & UPPER BOUND

    //------------------ ENABLE REGIONS

      tb_s_axi_awaddr <= {6'h00, 2'b00};
      tb_s_axi_awvalid <= 1;

      repeat (2) @(posedge tb_aclk);

      tb_s_axi_wdata <= `ENABLED_REGIONS; 
      tb_s_axi_wstrb <= 4'hf;
      tb_s_axi_wvalid <= 1;

      @(tb_s_axi_wvalid == 1 && tb_s_axi_awvalid == 1 && tb_s_axi_bvalid == 1);
      tb_s_axi_awvalid <= 0;
      tb_s_axi_wvalid <= 0;

    //---------------END ENABLE REGIONS

    //------------------ READ TEST
    if(`READ_TEST)
      begin
        tb_HW_r_start <= 1;

        repeat (10) @(posedge tb_aclk);

        for(int i = 0; i < `HW_NUM_R_TRANS; i++)
          begin
            if(tb_intr_line_r)
              begin 
                $display("[ACW_tb] \tinto illegal read trans");

                tb_illegal <= 1;
                @(posedge tb_aclk && tb_intr_line_r );  
                repeat (5) @(posedge tb_aclk);
                // read the anomaly register


                // reset the anomaly
                tb_s_axi_awaddr  <= {6'h01, 2'b00};
                tb_s_axi_awvalid <= 1;

                repeat (2) @(posedge tb_aclk);

                tb_s_axi_wdata  <= 1'b1;
                tb_s_axi_wstrb  <= 4'hf;
                tb_s_axi_wvalid <= 1;

                @(tb_s_axi_wvalid == 1 && tb_s_axi_awvalid == 1 && tb_s_axi_bvalid == 1);
                tb_s_axi_awvalid <= 0;
                tb_s_axi_wvalid  <= 0; 

              end      
            else 
              begin 
                $display("[ACW_tb] \tinto legal read trans");

          	tb_illegal <= 0;
                @(posedge tb_aclk && (~tb_init_flag || (tb_m_axi_arvalid && tb_m_axi_arready)));
                tb_init_flag <= 0;
                repeat (10) @(posedge tb_aclk);
                tb_m_axi_rdata <= i;
                tb_m_axi_rresp <= 0;
                tb_m_axi_rvalid <= 1;
                repeat (`HW_R_BURST_SIZE-1) @(posedge tb_aclk && tb_m_axi_rvalid == 1 && tb_m_axi_rready == 1);
                tb_m_axi_rlast <= 1;
                repeat (2) @(posedge tb_aclk && tb_m_axi_rvalid == 1 && tb_m_axi_rready == 1 && tb_m_axi_rlast == 1);
                tb_m_axi_rvalid <= 0;
                tb_m_axi_rlast <= 0;
              end
          end
	  tb_HW_r_start <= 0;
      end
    //---------------END READ TEST

    //------------------ WRITE TEST
    if(`WRITE_TEST)
      begin
        tb_HW_w_start <= 1;

        repeat (10) @(posedge tb_aclk);

        for(int i = 0; i < `HW_NUM_W_TRANS; i++)
          begin 
            if(tb_intr_line_w) 
              begin // illegal transaction
                $display("[ACW_tb] \tinto illegal write trans");
                tb_illegal <= 1;

                @(posedge tb_aclk && tb_intr_line_w );
                repeat (5) @(posedge tb_aclk);
                // read the anomaly register


                // reset the anomaly
                tb_s_axi_awaddr  <= {6'h01, 2'b00};
                tb_s_axi_awvalid <= 1;

                repeat (2) @(posedge tb_aclk);

                tb_s_axi_wdata  <= 2'b10;
                tb_s_axi_wstrb  <= 4'hf;
                tb_s_axi_wvalid <= 1;

                @(tb_s_axi_wvalid == 1 && tb_s_axi_awvalid == 1 && tb_s_axi_bvalid == 1);
                tb_s_axi_awvalid <= 0;
                tb_s_axi_wvalid  <= 0;
              end
            else 
              begin
                $display("[ACW_tb] \tinto legal write trans");
                tb_illegal <= 0;

                @(posedge tb_aclk && tb_m_axi_wvalid && tb_m_axi_wready && tb_m_axi_wlast);
                repeat (5) @(posedge tb_aclk); 
                tb_m_axi_bvalid <= 1;
                repeat (2) @(posedge tb_aclk && tb_m_axi_bvalid);
                tb_m_axi_bvalid <= 0;
              end
          end
	  tb_HW_w_start <= 0;
      end
    //---------------END WRITE TEST
  endtask

//-------------------- CLK PROCESS
  initial begin
			$dumpfile("localhost:9092");
			$dumpvars(0, test);
      while (!tb_done) begin
          tb_aclk <= 1;
          #(10/2);
          tb_aclk <= 0;
          #(10/2);
      end
      $stop;
  end
//-----------------END CLK PROCESS

//-------------------- STATIC CONF TESTBENCH (MOCK MEMORY AND MOCK PROCESSOR)
  assign tb_s_axi_arprot  = 0;
  assign tb_s_axi_awprot  = 0;
  assign tb_s_axi_bready  = 1;
  assign tb_s_axi_rready  = 1;

  assign tb_m_axi_awready = 1;
  assign tb_m_axi_arready = 1;
  assign tb_m_axi_wready  = 1;

//-----------------END STATIC CONF TESTBENCH (MOCK MEMORY AND MOCK PROCESSOR)

//-------------------- HW STATIC CONFIGURATION
  //assign tb_HW_r_base_addr = `HW_R_BASE_ADDR;
  //assign tb_HW_w_base_addr = `HW_W_BASE_ADDR;

  assign tb_HW_r_num_trans = `HW_NUM_R_TRANS;
  assign tb_HW_w_num_trans = `HW_NUM_W_TRANS;

  assign tb_HW_r_burst_len = `HW_R_BURST_SIZE;
  assign tb_HW_w_burst_len = `HW_W_BURST_SIZE;

  assign tb_HW_data_val    = 1;
  
//-----------------END HW STATIC CONFIGURATION

//-------------------- TEST
  initial begin
    
    for(int i = 0; i < `NUM_RAND_TEST_ROUNDS; i++)
      begin 
        $display("[ACW_tb] Round %d of %d", i+1, `NUM_RAND_TEST_ROUNDS);
        test_round();
      end

    tb_i_config <= 1'b0;

    repeat (10) @(posedge tb_aclk);

    tb_i_config <= 1'b1;

    repeat (5) @(posedge tb_aclk);
    $finish;
  end

//-----------------END TEST

endmodule

// Based on file authored by Andres Meza

module axi_m_generic_module(
        r_misb_clk_cnt_out,
        r_ready_to_sample_out,
        clk,
        r_start,
        w_start,
        reset,
        axi_resetn,
        r_displ,
        w_displ,
        r_max_outs,
        w_max_outs,
        r_phase,
        w_phase,
        r_base_addr,
        w_base_addr,
        r_num_trans,
        w_num_trans,
        r_burst_len,
        w_burst_len,
        data_val,
        r_misb_clk_cycle,
        w_misb_clk_cycle,
        w_done,
        r_done,
        m_axi_awid,
        m_axi_awaddr,
        m_axi_awlen,
        m_axi_awsize,
        m_axi_awburst,
        m_axi_awlock,
        m_axi_awcache,
        m_axi_awprot,
        m_axi_awqos,
        m_axi_awuser,
        m_axi_awvalid,
        m_axi_awready,
        m_axi_wdata,
        m_axi_wstrb,
        m_axi_wlast,
        m_axi_wuser,
        m_axi_wvalid,
        m_axi_wready,
        m_axi_bid,
        m_axi_bresp,
        m_axi_buser,
        m_axi_bvalid,
        m_axi_bready,
        m_axi_arid,
        m_axi_araddr,
        m_axi_arlen,
        m_axi_arsize,
        m_axi_arburst,
        m_axi_arlock,
        m_axi_arcache,
        m_axi_arprot,
        m_axi_arqos,
        m_axi_aruser,
        m_axi_arvalid,
        m_axi_arready,
        m_axi_rid,
        m_axi_rdata,
        m_axi_rresp,
        m_axi_rlast,
        m_axi_ruser,
        m_axi_rvalid,
        m_axi_rready
    );
    parameter c_m00_axi_target_slave_base_addr  = 8'b00000000;
    parameter [31:0]c_m00_axi_burst_len  = 16;
    parameter [31:0]c_m00_axi_id_width  = 1;
    parameter [31:0]c_m00_axi_addr_width  = 32;
    parameter [31:0]c_m00_axi_data_width  = 32;
    parameter [31:0]c_m00_axi_awuser_width  = 1;
    parameter [31:0]c_m00_axi_aruser_width  = 1;
    parameter [31:0]c_m00_axi_wuser_width  = 1;
    parameter [31:0]c_m00_axi_ruser_width  = 1;
    parameter [31:0]c_m00_axi_buser_width  = 1;
    parameter [31:0]c_s00_axi_id_width  = 1;
    parameter [31:0]c_s00_axi_data_width  = 32;
    parameter [31:0]c_s00_axi_addr_width  = 32;
    parameter [31:0]c_s00_axi_awuser_width  = 1;
    parameter [31:0]c_s00_axi_aruser_width  = 1;
    parameter [31:0]c_s00_axi_wuser_width  = 1;
    parameter [31:0]c_s00_axi_ruser_width  = 1;
    parameter [31:0]c_s00_axi_buser_width  = 1;
    output [15:0]r_misb_clk_cnt_out;
    output r_ready_to_sample_out;
    input clk;
    input r_start;
    input w_start;
    input reset;
    input axi_resetn;
    input [7:0]r_displ;
    input [7:0]w_displ;
    input [7:0]r_max_outs;
    input [7:0]w_max_outs;
    input [15:0]r_phase;
    input [15:0]w_phase;
    input [31:0]r_base_addr;
    input [31:0]w_base_addr;
    input [15:0]r_num_trans;
    input [15:0]w_num_trans;
    input [7:0]r_burst_len;
    input [7:0]w_burst_len;
    input data_val;
    input [15:0]r_misb_clk_cycle;
    input [15:0]w_misb_clk_cycle;
    output w_done;
    output r_done;
    output [( c_m00_axi_id_width - 1 ):0]m_axi_awid;
    output [( c_s00_axi_addr_width - 1 ):0]m_axi_awaddr;
    output [7:0]m_axi_awlen;
    output [2:0]m_axi_awsize;
    output [1:0]m_axi_awburst;
    output m_axi_awlock;
    output [3:0]m_axi_awcache;
    output [2:0]m_axi_awprot;
    output [3:0]m_axi_awqos;
    output [( c_m00_axi_awuser_width - 1 ):0]m_axi_awuser;
    output m_axi_awvalid;
    input m_axi_awready;
    output [( c_m00_axi_data_width - 1 ):0]m_axi_wdata;
    output [( ( c_m00_axi_data_width / 8 ) - 1 ):0]m_axi_wstrb;
    output m_axi_wlast;
    output [( c_m00_axi_wuser_width - 1 ):0]m_axi_wuser;
    output m_axi_wvalid;
    input m_axi_wready;
    input [( c_m00_axi_id_width - 1 ):0]m_axi_bid;
    input [1:0]m_axi_bresp;
    input [( c_m00_axi_buser_width - 1 ):0]m_axi_buser;
    input m_axi_bvalid;
    output m_axi_bready;
    output [( c_m00_axi_id_width - 1 ):0]m_axi_arid;
    output [( c_m00_axi_addr_width - 1 ):0]m_axi_araddr;
    output [7:0]m_axi_arlen;
    output [2:0]m_axi_arsize;
    output [1:0]m_axi_arburst;
    output m_axi_arlock;
    output [3:0]m_axi_arcache;
    output [2:0]m_axi_arprot;
    output [3:0]m_axi_arqos;
    output [( c_m00_axi_aruser_width - 1 ):0]m_axi_aruser;
    output m_axi_arvalid;
    input m_axi_arready;
    input [( c_m00_axi_id_width - 1 ):0]m_axi_rid;
    input [( c_m00_axi_data_width - 1 ):0]m_axi_rdata;
    input [1:0]m_axi_rresp;
    input m_axi_rlast;
    input [( c_m00_axi_ruser_width - 1 ):0]m_axi_ruser;
    input m_axi_rvalid;
    output m_axi_rready;
    wire [15:0]w_misb_clk_cnt;
    wire r_ready_to_sample;
    reg [7:0]r_displ_int;
    reg [7:0]w_displ_int;
    reg [7:0]r_max_outs_int;
    reg [7:0]w_max_outs_int;
    reg [15:0]r_phase_int;
    reg [15:0]w_phase_int;
    reg [31:0]r_base_addr_int;
    reg [31:0]w_base_addr_int;
    reg [15:0]r_num_trans_int;
    reg [15:0]w_num_trans_int;
    reg [7:0]r_burst_len_int;
    reg [7:0]w_burst_len_int;
    reg data_val_flag;
    reg r_phase_start;
    reg w_phase_start;
    reg [15:0]r_phase_counter;
    reg [15:0]w_phase_counter;
    reg w_start_int;
    reg r_start_int;
    reg r_done;
    reg w_done;
    reg [15:0]r_trans_counter;
    reg [15:0]r_displ_cnt;
    reg [15:0]r_pend_outs_trans;
    reg [0:0]r_grant_trans_flag;
    reg r_addr_init;
    reg [( c_m00_axi_addr_width - 1 ):0]m_axi_araddr_int;
    reg m_axi_arvalid_int;
    reg [2:0]r_state;
    reg [15:0]w_trans_counter;
    reg [15:0]w_displ_cnt;
    reg [0:0]w_grant_trans_flag;
    reg w_addr_init;
    reg [15:0]w_pend_outs_trans;
    reg [( c_m00_axi_addr_width - 1 ):0]m_axi_awaddr_int;
    reg m_axi_awvalid_int;
    reg [2:0]w_state;
    reg [15:0]r_done_counter;
    reg [15:0]r_misb_clk_cnt;
    reg [0:0]r_end_trans_flag;
    reg [15:0]w_data_done_cnt;
    reg [7:0]w_data_counter;
    reg [31:0]m_axi_wdata_int;
    reg m_axi_wvalid_int;
    reg m_axi_wlast_int;
    reg [15:0]w_done_counter;
    reg [0:0]w_end_trans_flag;
    assign r_misb_clk_cnt_out = r_misb_clk_cnt;
    assign r_ready_to_sample_out = r_ready_to_sample;
    assign m_axi_awid = 1'b0;
    assign m_axi_awaddr = m_axi_awaddr_int;
    assign m_axi_awlen = w_burst_len_int;
    assign m_axi_awsize = 3'b010;
    assign m_axi_awburst = 2'b01;
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0011;
    assign m_axi_awprot = 3'b000;
    assign m_axi_awqos = 1'b0;
    assign m_axi_awuser = 1'b0;
    assign m_axi_awvalid = m_axi_awvalid_int;
    assign m_axi_wdata = m_axi_wdata_int;
    assign m_axi_wstrb = 4'b1111;
    assign m_axi_wlast = m_axi_wlast_int;
    assign m_axi_wuser = 1'b0;
    assign m_axi_wvalid = m_axi_wvalid_int;
    assign m_axi_bready = 1'b1;
    assign m_axi_arid = 1'b0;
    assign m_axi_araddr = m_axi_araddr_int;
    assign m_axi_arlen = r_burst_len_int;
    assign m_axi_arsize = 3'b010;
    assign m_axi_arburst = 2'b01;
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0011;
    assign m_axi_arprot = 3'b000;
    assign m_axi_arqos = 1'b0;
    assign m_axi_aruser = 1'b0;
    assign m_axi_arvalid = m_axi_arvalid_int;
    always @ (  posedge clk)
    begin : data_set_process
        if ( ( reset == 1'b1 ) | ( axi_resetn == 1'b0 ) ) 
        begin
            r_displ_int <= { 1'b0 };
            w_displ_int <= { 1'b0 };
            r_max_outs_int <= { 1'b0 };
            w_max_outs_int <= { 1'b0 };
            r_phase_int <= { 1'b0 };
            w_phase_int <= { 1'b0 };
            r_base_addr_int <= { 1'b0 };
            w_base_addr_int <= { 1'b0 };
            r_num_trans_int <= { 1'b0 };
            w_num_trans_int <= { 1'b0 };
            r_burst_len_int <= { 1'b0 };
            w_burst_len_int <= { 1'b0 };
            data_val_flag <= 1'b0;
        end
        else
        begin 
            if ( clk == 1'b1 ) 
            begin
                if ( data_val == 1'b1 ) 
                begin
                    r_displ_int <= r_displ;
                    w_displ_int <= w_displ;
                    r_max_outs_int <= r_max_outs;
                    w_max_outs_int <= w_max_outs;
                    r_phase_int <= r_phase;
                    w_phase_int <= w_phase;
                    r_base_addr_int <= r_base_addr;
                    w_base_addr_int <= w_base_addr;
                    r_num_trans_int <= r_num_trans;
                    w_num_trans_int <= w_num_trans;
                    data_val_flag <= 1'b1;
                    r_burst_len_int <= r_burst_len;
                    w_burst_len_int <= w_burst_len;
                end
            end
        end
    end
    always @ (  posedge clk)
    begin : start_proc
        if ( ( reset == 1'b1 ) | ( axi_resetn == 1'b0 ) ) 
        begin
            r_phase_start <= 1'b0;
            w_phase_start <= 1'b0;
        end
        else
        begin 
            if ( clk == 1'b1 ) 
            begin
                if ( r_start == 1'b1 ) 
                begin
                    r_phase_start <= 1'b1;
                end
                if ( w_start == 1'b1 ) 
                begin
                    w_phase_start <= 1'b1;
                end
            end
        end
    end
    always @ (  posedge clk)
    begin : phase_proc
        if ( ( reset == 1'b1 ) | ( axi_resetn == 1'b0 ) ) 
        begin
            r_phase_counter <= { 1'b0 };
            w_phase_counter <= { 1'b0 };
            w_start_int <= 1'b0;
            r_start_int <= 1'b0;
        end
        else
        begin 
            if ( clk == 1'b1 ) 
            begin
                if ( r_phase_start == 1'b1 ) 
                begin
                    if ( r_phase_counter != r_phase_int ) 
                    begin
                        r_phase_counter <= ( r_phase_counter + 1 );
                    end
                    else
                    begin 
                        r_start_int <= 1'b1;
                    end
                end
                if ( w_phase_start == 1'b1 ) 
                begin
                    if ( w_phase_counter != w_phase_int ) 
                    begin
                        w_phase_counter <= ( w_phase_counter + 1 );
                    end
                    else
                    begin 
                        w_start_int <= 1'b1;
                    end
                end
            end
        end
    end
    always @ (  posedge clk)
    begin : done_proc
        if ( clk == 1'b1 ) 
        begin
            if ( data_val_flag == 1'b1 ) 
            begin
                if ( r_done_counter == r_num_trans_int ) 
                begin
                    r_done <= 1'b1;
                end
                if ( w_done_counter == w_num_trans_int ) 
                begin
                    w_done <= 1'b1;
                end
            end
            else
            begin 
                r_done <= 1'b0;
                w_done <= 1'b0;
            end
        end
    end
    always @ (  posedge clk)
    begin : address_read_channel_process
        if ( ( reset == 1'b1 ) | ( axi_resetn == 1'b0 ) ) 
        begin
            r_trans_counter <= { 1'b0 };
            r_displ_cnt <= { 1'b0 };
            r_pend_outs_trans <= { 1'b0 };
            r_grant_trans_flag <= 1'b0;
            r_addr_init <= 1'b0;
            r_state <= 3'b000;
            m_axi_araddr_int <= r_base_addr_int;
            m_axi_arvalid_int <= 1'b0;
        end
        else
        begin 
            if ( clk == 1'b1 ) 
            begin
                r_grant_trans_flag <= 1'b0;
                r_pend_outs_trans <= ( r_pend_outs_trans - r_end_trans_flag );
                if ( r_start_int == 1'b1 ) 
                begin
                    if ( r_state == 3'b000 ) 
                    begin
                        if ( ( r_trans_counter < r_num_trans_int ) & ( r_pend_outs_trans < r_max_outs_int ) ) 
                        begin
                            if ( r_addr_init == 1'b0 ) 
                            begin
                                m_axi_araddr_int <= r_base_addr_int;
                                r_addr_init <= 1'b1;
                            end
                            else
                            begin 
                                m_axi_araddr_int <= ( m_axi_araddr_int + { ( r_burst_len_int[5:0] + 1'b1 ), 2'b00 } );
                            end
                            m_axi_arvalid_int <= 1'b1;
                            r_state <= 3'b001;
                            r_trans_counter <= ( r_trans_counter + 1 );
                            r_grant_trans_flag <= 1'b1;
                        end
                        else
                        begin 
                            m_axi_arvalid_int <= 1'b0;
                        end
                    end
                    else
                    begin 
                        if ( r_state == 3'b001 ) 
                        begin
                            if ( ( m_axi_arvalid_int == 1'b1 ) & ( m_axi_arready == 1'b1 ) ) 
                            begin
                                if ( r_displ_cnt < r_displ_int ) 
                                begin
                                    r_displ_cnt <= ( r_displ_cnt + 1 );
                                    r_state <= 3'b010;
                                end
                                else
                                begin 
                                    r_state <= 3'b000;
                                end
                                m_axi_arvalid_int <= 1'b0;
                            end
                        end
                        else
                        begin 
                            if ( r_state == 3'b010 ) 
                            begin
                                if ( r_displ_cnt == r_displ_int ) 
                                begin
                                    r_displ_cnt <= { 1'b0 };
                                    r_state <= 3'b000;
                                end
                                else
                                begin 
                                    r_displ_cnt <= ( r_displ_cnt + 1 );
                                end
                            end
                            else
                            begin 
                                m_axi_arvalid_int <= 1'b0;
                            end
                        end
                    end
                end
            end
        end
    end
    always @ (  posedge clk)
    begin : address_write_channel_process
        if ( ( reset == 1'b1 ) | ( axi_resetn == 1'b0 ) ) 
        begin
            w_trans_counter <= { 1'b0 };
            w_displ_cnt <= { 1'b0 };
            w_grant_trans_flag <= 1'b0;
            w_addr_init <= 1'b0;
            w_state <= 3'b000;
            w_pend_outs_trans <= 0;
            m_axi_awaddr_int <= w_base_addr_int;
            m_axi_awvalid_int <= 1'b0;
        end
        else
        begin 
            if ( clk == 1'b1 ) 
            begin
                w_grant_trans_flag <= 1'b0;
                w_pend_outs_trans <= w_pend_outs_trans + w_grant_trans_flag - w_end_trans_flag;
                if ( w_start_int == 1'b1 ) 
                begin
                    if ( w_state == 3'b000 ) 
                    begin
                        if ( ( w_trans_counter < w_num_trans_int ) & ( w_pend_outs_trans < w_max_outs_int ) ) 
                        begin
                            if ( w_addr_init == 1'b0 ) 
                            begin
                                m_axi_awaddr_int <= w_base_addr_int;
                                w_addr_init <= 1'b1;
                            end
                            else
                            begin 
                                m_axi_awaddr_int <= ( m_axi_awaddr_int + { ( w_burst_len_int[5:0] + 1'b1 ), 2'b00 } );
                            end
                            m_axi_awvalid_int <= 1'b1;
                            w_state <= 3'b001;
                            w_grant_trans_flag <= 1'b1;
                        end
                        else
                        begin 
                            m_axi_awvalid_int <= 1'b0;
                        end
                    end
                    else
                    begin 
                        if ( w_state == 3'b001 ) 
                        begin
                            if ( ( m_axi_awvalid_int == 1'b1 ) & ( m_axi_awready == 1'b1 ) ) 
                            begin
                                w_trans_counter <= ( w_trans_counter + 1 );
                                if ( w_displ_cnt < w_displ_int ) 
                                begin
                                    w_displ_cnt <= ( w_displ_cnt + 1 );
                                    w_state <= 3'b010;
                                end
                                else
                                begin 
                                    w_state <= 3'b000;
                                end
                                m_axi_awvalid_int <= 1'b0;
                            end
                        end
                        else
                        begin 
                            if ( w_state == 3'b010 ) 
                            begin
                                if ( w_displ_cnt == w_displ_int ) 
                                begin
                                    w_displ_cnt <= { 1'b0 };
                                    w_state <= 3'b000;
                                end
                                else
                                begin 
                                    w_displ_cnt <= ( w_displ_cnt + 1 );
                                end
                            end
                            else
                            begin 
                                m_axi_awvalid_int <= 1'b0;
                            end
                        end
                    end
                end
            end
        end
    end
    assign r_ready_to_sample = & ( ~( ( r_misb_clk_cnt ^ r_misb_clk_cycle )));
    assign m_axi_rready = r_ready_to_sample;
    always @ (  posedge clk)
    begin : data_read_channel
        if ( ( reset == 1'b1 ) | ( axi_resetn == 1'b0 ) ) 
        begin
            r_done_counter <= { 1'b0 };
            r_misb_clk_cnt <= { 1'b0 };
        end
        else
        begin 
            if ( clk == 1'b1 ) 
            begin
                if ( ( ( m_axi_rvalid == 1'b1 ) & ( r_ready_to_sample == 1'b1 ) ) & ( m_axi_rlast == 1'b1 ) ) 
                begin
                    r_done_counter <= ( r_done_counter + 1 );
                    r_end_trans_flag <= 1'b1;
                    r_misb_clk_cnt <= { 1'b0 };
                end
                else
                begin 
                    if ( ( m_axi_rvalid == 1'b1 ) & ( r_ready_to_sample == 1'b0 ) ) 
                    begin
                        r_misb_clk_cnt <= ( r_misb_clk_cnt + 1 );
                    end
                    else
                    begin 
                        r_end_trans_flag <= 1'b0;
                    end
                end
            end
        end
    end
    always @ (  posedge clk)
    begin : data_write_channel
        if ( ( reset == 1'b1 ) | ( axi_resetn == 1'b0 ) ) 
        begin
            w_data_done_cnt <= { 1'b0 };
            w_data_counter <= 2'b01;
            m_axi_wdata_int <= 8'b00000000;
            m_axi_wlast_int <= 1'b0;
            m_axi_wvalid_int <= 1'b0;
        end
        else
        begin 
            if ( clk == 1'b1 ) 
            begin
                if ( w_data_done_cnt < w_trans_counter ) 
                begin
                    m_axi_wvalid_int <= 1'b1;
                end
                else
                begin 
                    m_axi_wvalid_int <= 1'b0;
                end
                if ( ( m_axi_wvalid_int == 1'b1 ) & ( m_axi_wready == 1'b1 ) ) 
                begin
                    if ( w_data_counter == w_burst_len_int ) 
                    begin
                        m_axi_wlast_int <= 1'b1;
                        w_data_counter <= 2'b00;
                        w_data_done_cnt <= ( w_data_done_cnt + 1 );
                    end
                    else
                    begin 
                        w_data_counter <= ( w_data_counter + 1 );
                        m_axi_wlast_int <= 1'b0;
                    end
                    m_axi_wdata_int <= { 6'b000000, w_data_counter };
                end
            end
        end
    end
    always @ (  posedge clk)
    begin : b_resp_channel
        if ( ( reset == 1'b1 ) | ( axi_resetn == 1'b0 ) ) 
        begin
            w_done_counter <= { 1'b0 };
        end
        else
        begin 
            if ( clk == 1'b1 ) 
            begin
                if ( m_axi_bvalid == 1'b1 ) 
                begin
                    w_done_counter <= ( w_done_counter + 1 );
                    w_end_trans_flag <= 1'b1;
                end
                else
                begin 
                    w_end_trans_flag <= 1'b0;
                end
            end
        end
    end
endmodule

// Based on file authored by Andres Meza

`timescale 1 ns / 1 ps

module acw #
(
  parameter integer C_S_CTRL_AXI = 32,
  parameter integer C_S_CTRL_AXI_ADDR_WIDTH	= 8,
  parameter integer LOG_MAX_OUTS_TRAN = 4,
  parameter integer MAX_OUTS_TRANS    = 16,

  parameter integer C_LOG_BUS_SIZE_BYTE  = 2, //clog2(C_M_AXI_DATA_WIDTH/8),
  parameter integer C_M_AXI_BURST_LEN	 = 16,
  parameter integer C_M_AXI_ID_WIDTH	 = 1,
  parameter integer C_M_AXI_ADDR_WIDTH	 = 32,
  parameter integer C_M_AXI_DATA_WIDTH	 = 32,
  parameter integer C_M_AXI_ARUSER_WIDTH = 1,
  parameter integer C_M_AXI_AWUSER_WIDTH = 1,
  parameter integer C_M_AXI_WUSER_WIDTH	 = 1,
  parameter integer C_M_AXI_RUSER_WIDTH	 = 1,
  parameter integer C_M_AXI_BUSER_WIDTH	 = 1
)
(
//-------------------- GLOBAL PORTS
  input  wire ACLK,
  input  wire ARESETN,
  output wire INTR_LINE_R,
  output wire INTR_LINE_W,

//-----------------END GLOBAL PORTS

//-------------------- AXI CONFIGURATION S PORTS
  input  wire [C_S_CTRL_AXI_ADDR_WIDTH-1 : 0] S_AXI_CTRL_AWADDR,
  input  wire [2 : 0]                         S_AXI_CTRL_AWPROT,
  input  wire                                 S_AXI_CTRL_AWVALID,
  output wire                                 S_AXI_CTRL_AWREADY,

  input  wire [C_S_CTRL_AXI-1 : 0]            S_AXI_CTRL_WDATA,
  input  wire [(C_S_CTRL_AXI/8)-1 : 0]        S_AXI_CTRL_WSTRB,
  input  wire                                 S_AXI_CTRL_WVALID,
  output wire                                 S_AXI_CTRL_WREADY,

  output wire [1 : 0]                         S_AXI_CTRL_BRESP,
  output wire                                 S_AXI_CTRL_BVALID,
  input  wire                                 S_AXI_CTRL_BREADY,

  input  wire [C_S_CTRL_AXI_ADDR_WIDTH-1 : 0] S_AXI_CTRL_ARADDR,
  input  wire [2 : 0]                         S_AXI_CTRL_ARPROT,
  input  wire                                 S_AXI_CTRL_ARVALID,
  output wire                                 S_AXI_CTRL_ARREADY,

  output wire [C_S_CTRL_AXI-1 : 0]            S_AXI_CTRL_RDATA,
  output wire [1 : 0]                         S_AXI_CTRL_RRESP,
  output wire                                 S_AXI_CTRL_RVALID,
  input  wire                                 S_AXI_CTRL_RREADY,

//-----------------END AXI CONFIGURATION S PORTS

//-------------------- HARDWARE MODULE PORTS

  input wire         r_start_wire, //: in std_logic;
  input wire         w_start_wire, //: in std_logic;

  input wire         reset_wire,

  //-- base address
  input wire[31 : 0] r_base_addr_wire, //: in std_logic_vector (31 downto 0);
  input wire[31 : 0] w_base_addr_wire, //: in std_logic_vector (31 downto 0);
  //-- num transaction
  input wire[15 : 0] r_num_trans_wire, //: in std_logic_vector(15 downto 0);
  input wire[15 : 0] w_num_trans_wire, //: in std_logic_vector(15 downto 0);

  input wire[7 : 0] r_burst_len_wire,  //: in std_logic_vector(7 downto 0);
  input wire[7 : 0] w_burst_len_wire,  //: in std_logic_vector(7 downto 0);

  input wire        data_val_wire, //: in std_logic;

  //-- output done
  output wire       w_done_wire,  //: out std_logic;
  output wire       r_done_wire,  //: out std_logic;


//-----------------END HARDWARE MODULE PORTS


//-------------------- M OUTPUT INTERFACE PORTS

  output wire [C_M_AXI_ID_WIDTH-1 : 0]        M_AXI_AWID,
  output wire [C_M_AXI_ADDR_WIDTH-1 : 0]      M_AXI_AWADDR,
  output wire [7 : 0]                         M_AXI_AWLEN,
  output wire [2 : 0]                         M_AXI_AWSIZE,
  output wire [1 : 0]                         M_AXI_AWBURST,
  output wire                                 M_AXI_AWLOCK,
  output wire [3 : 0]                         M_AXI_AWCACHE,
  output wire [2 : 0]                         M_AXI_AWPROT,
  output wire [3 : 0]                         M_AXI_AWQOS,
  output wire [C_M_AXI_AWUSER_WIDTH-1 : 0]    M_AXI_AWUSER,
  output wire                                 M_AXI_AWVALID,
  input  wire                                 M_AXI_AWREADY,

  output wire [C_M_AXI_DATA_WIDTH-1 : 0]      M_AXI_WDATA,
  output wire [C_M_AXI_DATA_WIDTH/8-1 : 0]    M_AXI_WSTRB,
  output wire                                 M_AXI_WLAST,
  output wire [C_M_AXI_WUSER_WIDTH-1 : 0]     M_AXI_WUSER,
  output wire                                 M_AXI_WVALID,
  input  wire                                 M_AXI_WREADY,

  input  wire [C_M_AXI_ID_WIDTH-1 : 0]        M_AXI_BID,
  input  wire [1 : 0]                         M_AXI_BRESP,
  input  wire [C_M_AXI_BUSER_WIDTH-1 : 0]     M_AXI_BUSER,
  input  wire                                 M_AXI_BVALID,
  output wire                                 M_AXI_BREADY,

  output wire [C_M_AXI_ID_WIDTH-1 : 0]        M_AXI_ARID,
  output wire [C_M_AXI_ADDR_WIDTH-1 : 0]      M_AXI_ARADDR,
  output wire [7 : 0]                         M_AXI_ARLEN,
  output wire [2 : 0]                         M_AXI_ARSIZE,
  output wire [1 : 0]                         M_AXI_ARBURST,
  output wire                                 M_AXI_ARLOCK,
  output wire [3 : 0]                         M_AXI_ARCACHE,
  output wire [2 : 0]                         M_AXI_ARPROT,
  output wire [3 : 0]                         M_AXI_ARQOS,
  output wire [C_M_AXI_ARUSER_WIDTH-1 : 0]    M_AXI_ARUSER,
  output wire                                 M_AXI_ARVALID,
  input  wire                                 M_AXI_ARREADY,

  input  wire [C_M_AXI_ID_WIDTH-1 : 0]        M_AXI_RID,
  input  wire [C_M_AXI_DATA_WIDTH-1 : 0]      M_AXI_RDATA,
  input  wire [1 : 0]                         M_AXI_RRESP,
  input  wire                                 M_AXI_RLAST,
  input  wire [C_M_AXI_RUSER_WIDTH-1 : 0]     M_AXI_RUSER,
  input  wire                                 M_AXI_RVALID,
  output wire                                 M_AXI_RREADY,

//-----------------END M OUTPUT INTERFACE PORTS

  input  wire i_config,
  output wire [31 : 0] o_data
);

//-------------------- AXI S CONFIGURATION SIGNALS
  reg [C_S_CTRL_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
  reg                                 axi_awready;
  reg                                 axi_wready;
  reg [1 : 0]                         axi_bresp;
  reg                                 axi_bvalid;
  reg [C_S_CTRL_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
  reg                                 axi_arready;
  reg [C_S_CTRL_AXI-1 : 0]            axi_rdata;
  reg [1 : 0]                         axi_rresp;
  reg                                 axi_rvalid;

  localparam integer ADDR_LSB = (C_S_CTRL_AXI/32)+1;
  localparam integer OPT_MEM_ADDR_BITS = 5;

  reg [C_S_CTRL_AXI-1 : 0] reg00_config;
  reg [C_S_CTRL_AXI-1 : 0] reg01_config;
  reg [C_S_CTRL_AXI-1 : 0] reg02_r_anomaly;
  reg [C_S_CTRL_AXI-1 : 0] reg03_r_anomaly;
  reg [C_S_CTRL_AXI-1 : 0] reg04_w_anomaly;
  reg [C_S_CTRL_AXI-1 : 0] reg05_w_anomaly;
  reg [C_S_CTRL_AXI-1 : 0] reg06_r_config;
  reg [C_S_CTRL_AXI-1 : 0] reg07_r_config;
  reg [C_S_CTRL_AXI-1 : 0] reg08_r_config;
  reg [C_S_CTRL_AXI-1 : 0] reg09_r_config;
  reg [C_S_CTRL_AXI-1 : 0] reg10_r_config;
  reg [C_S_CTRL_AXI-1 : 0] reg11_r_config;
  reg [C_S_CTRL_AXI-1 : 0] reg12_r_config;
  reg [C_S_CTRL_AXI-1 : 0] reg13_r_config;
  reg [C_S_CTRL_AXI-1 : 0] reg14_r_config;
  reg [C_S_CTRL_AXI-1 : 0] reg15_r_config;
  reg [C_S_CTRL_AXI-1 : 0] reg16_r_config;
  reg [C_S_CTRL_AXI-1 : 0] reg17_r_config;
  reg [C_S_CTRL_AXI-1 : 0] reg18_r_config;
  reg [C_S_CTRL_AXI-1 : 0] reg19_r_config;
  reg [C_S_CTRL_AXI-1 : 0] reg20_r_config;
  reg [C_S_CTRL_AXI-1 : 0] reg21_r_config;
  reg [C_S_CTRL_AXI-1 : 0] reg22_w_config;
  reg [C_S_CTRL_AXI-1 : 0] reg23_w_config;
  reg [C_S_CTRL_AXI-1 : 0] reg24_w_config;
  reg [C_S_CTRL_AXI-1 : 0] reg25_w_config;
  reg [C_S_CTRL_AXI-1 : 0] reg26_w_config;
  reg [C_S_CTRL_AXI-1 : 0] reg27_w_config;
  reg [C_S_CTRL_AXI-1 : 0] reg28_w_config;
  reg [C_S_CTRL_AXI-1 : 0] reg29_w_config;
  reg [C_S_CTRL_AXI-1 : 0] reg30_w_config;
  reg [C_S_CTRL_AXI-1 : 0] reg31_w_config;
  reg [C_S_CTRL_AXI-1 : 0] reg32_w_config;
  reg [C_S_CTRL_AXI-1 : 0] reg33_w_config;
  reg [C_S_CTRL_AXI-1 : 0] reg34_w_config;
  reg [C_S_CTRL_AXI-1 : 0] reg35_w_config;
  reg [C_S_CTRL_AXI-1 : 0] reg36_w_config;
  reg [C_S_CTRL_AXI-1 : 0] reg37_w_config;

  wire                     regXX_rden;
  wire                     regXX_wren;
  reg [C_S_CTRL_AXI-1 : 0] reg_data_out;
  integer                  byte_index;
  reg                      aw_en;

  assign S_AXI_CTRL_AWREADY = axi_awready;
  assign S_AXI_CTRL_WREADY  = axi_wready;
  assign S_AXI_CTRL_BRESP   = axi_bresp;
  assign S_AXI_CTRL_BVALID  = axi_bvalid;
  assign S_AXI_CTRL_ARREADY = axi_arready;
  assign S_AXI_CTRL_RDATA   = axi_rdata;
  assign S_AXI_CTRL_RRESP   = axi_rresp;
  assign S_AXI_CTRL_RVALID  = axi_rvalid;

//-----------------END AXI S CONFIGURATION SIGNALS

//-------------------- S CONTROL LOGIC
  always @ (posedge ACLK)
  begin
    if (ARESETN == 1'b0)
      begin
        axi_awready <= 1'b0;
        aw_en <= 1'b1;
      end
    else
      begin
        if (~axi_awready && S_AXI_CTRL_AWVALID && S_AXI_CTRL_WVALID && aw_en)
          begin
            axi_awready <= 1'b1;
            aw_en <= 1'b0;
          end
          else if (S_AXI_CTRL_BREADY && axi_bvalid)
              begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
              end
        else
          begin
            axi_awready <= 1'b0;
          end
      end
  end

  always @ (posedge ACLK)
  begin
    if (ARESETN == 1'b0)
      begin
        axi_awaddr <= 0;
      end
    else
      begin
        if (~axi_awready && S_AXI_CTRL_AWVALID && S_AXI_CTRL_WVALID && aw_en)
          begin
            axi_awaddr <= S_AXI_CTRL_AWADDR;
          end
      end
  end

  always @ (posedge ACLK)
  begin
    if ( ARESETN == 1'b0 )
      begin
        axi_wready <= 1'b0;
      end
    else
      begin
        if (~axi_wready && S_AXI_CTRL_WVALID && S_AXI_CTRL_AWVALID && aw_en )
          begin
            axi_wready <= 1'b1;
          end
        else
          begin
            axi_wready <= 1'b0;
          end
      end
  end

  assign regXX_wren = axi_wready && S_AXI_CTRL_WVALID && axi_awready && S_AXI_CTRL_AWVALID;

  always @ (posedge ACLK)
  begin
    if (ARESETN == 1'b0)
      begin
        reg00_config    <= 0;
        reg01_config    <= 0;
        //reg02_r_anomaly <= 0;
        //reg03_r_anomaly <= 0;
        //reg04_w_anomaly <= 0;
        //reg05_w_anomaly <= 0;
        reg06_r_config  <= 0;
        reg07_r_config  <= 0;
        reg08_r_config  <= 0;
        reg09_r_config  <= 0;
        reg10_r_config  <= 0;
        reg11_r_config  <= 0;
        reg12_r_config  <= 0;
        reg13_r_config  <= 0;
        reg14_r_config  <= 0;
        reg15_r_config  <= 0;
        reg16_r_config  <= 0;
        reg17_r_config  <= 0;
        reg18_r_config  <= 0;
        reg19_r_config  <= 0;
        reg20_r_config  <= 0;
        reg21_r_config  <= 0;
        reg22_w_config  <= 0;
        reg23_w_config  <= 0;
        reg24_w_config  <= 0;
        reg25_w_config  <= 0;
        reg26_w_config  <= 0;
        reg27_w_config  <= 0;
        reg28_w_config  <= 0;
        reg29_w_config  <= 0;
        reg30_w_config  <= 0;
        reg31_w_config  <= 0;
        reg32_w_config  <= 0;
        reg33_w_config  <= 0;
        reg34_w_config  <= 0;
        reg35_w_config  <= 0;
        reg36_w_config  <= 0;
        reg37_w_config  <= 0;

      end
    else 
      begin
        reg01_config <= 0;
        if (regXX_wren)
          begin
            case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
              6'h00:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg00_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h01:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg01_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              /*6'h02:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg02_r_anomaly[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h03:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg03_r_anomaly[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h04:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg04_w_anomaly[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h05:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg05_w_anomaly[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end*/
              6'h06:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg06_r_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h07:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg07_r_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h08:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg08_r_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h09:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg09_r_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h0A:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg10_r_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h0B:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg11_r_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h0C:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg12_r_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h0D:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg13_r_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h0E:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg14_r_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h0F:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg15_r_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h10:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg16_r_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h11:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg17_r_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h12:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg18_r_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h13:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg19_r_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h14:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg20_r_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h15:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg21_r_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h16:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg22_w_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h17:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg23_w_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h18:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg24_w_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h19:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg25_w_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h1A:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg26_w_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h1B:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg27_w_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h1C:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg28_w_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h1D:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg29_w_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h1E:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg30_w_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h1F:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg31_w_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h20:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg32_w_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h21:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg33_w_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h22:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg34_w_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h23:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg35_w_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h24:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg36_w_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              6'h25:
                for ( byte_index = 0; byte_index <= (C_S_CTRL_AXI/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_CTRL_WSTRB[byte_index] == 1 ) begin
                    reg37_w_config[(byte_index*8) +: 8] <= S_AXI_CTRL_WDATA[(byte_index*8) +: 8];
                  end
              default : begin
                  reg00_config    <= reg00_config;
                  reg01_config    <= reg01_config;
                  //reg02_r_anomaly <= reg02_r_anomaly;
                  //reg03_r_anomaly <= reg03_r_anomaly;
                  //reg04_w_anomaly <= reg04_w_anomaly;
                  //reg05_w_anomaly <= reg05_w_anomaly;
                  reg06_r_config  <= reg06_r_config;
                  reg07_r_config  <= reg07_r_config;
                  reg08_r_config  <= reg08_r_config;
                  reg09_r_config  <= reg09_r_config;
                  reg10_r_config  <= reg10_r_config;
                  reg11_r_config  <= reg11_r_config;
                  reg12_r_config  <= reg12_r_config;
                  reg13_r_config  <= reg13_r_config;
                  reg14_r_config  <= reg14_r_config;
                  reg15_r_config  <= reg15_r_config;
                  reg16_r_config  <= reg16_r_config;
                  reg17_r_config  <= reg17_r_config;
                  reg18_r_config  <= reg18_r_config;
                  reg19_r_config  <= reg19_r_config;
                  reg20_r_config  <= reg20_r_config;
                  reg21_r_config  <= reg21_r_config;
                  reg22_w_config  <= reg22_w_config;
                  reg23_w_config  <= reg23_w_config;
                  reg24_w_config  <= reg24_w_config;
                  reg25_w_config  <= reg25_w_config;
                  reg26_w_config  <= reg26_w_config;
                  reg27_w_config  <= reg27_w_config;
                  reg28_w_config  <= reg28_w_config;
                  reg29_w_config  <= reg29_w_config;
                  reg30_w_config  <= reg30_w_config;
                  reg31_w_config  <= reg31_w_config;
                  reg32_w_config  <= reg32_w_config;
                  reg33_w_config  <= reg33_w_config;
                  reg34_w_config  <= reg34_w_config;
                  reg35_w_config  <= reg35_w_config;
                  reg36_w_config  <= reg36_w_config;
                  reg37_w_config  <= reg37_w_config;
                end
            endcase
          end
	    end
  end

  always @ (posedge ACLK)
	begin
	  if (ARESETN == 1'b0)
	    begin
	      axi_bvalid  <= 1'b0;
	      axi_bresp   <= 2'b0;
	    end
	  else
	    begin
	      if (axi_awready && S_AXI_CTRL_AWVALID && ~axi_bvalid && axi_wready && S_AXI_CTRL_WVALID)
	        begin
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; 
	        end                   
	      else
	        begin
	          if (S_AXI_CTRL_BREADY && axi_bvalid)
	            begin
	              axi_bvalid <= 1'b0;
	            end
	        end
	    end
	end

  always @ (posedge ACLK)
	begin
	  if (ARESETN == 1'b0)
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end
	  else
	    begin
	      if (~axi_arready && S_AXI_CTRL_ARVALID)
	        begin
	          axi_arready <= 1'b1;
	          axi_araddr  <= S_AXI_CTRL_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end
	end

  always @ (posedge ACLK)
	begin
	  if (ARESETN == 1'b0)
	    begin
	      axi_rvalid <= 1'b0;
	      axi_rresp  <= 2'b0;
	    end
	  else
	    begin
	      if (axi_arready && S_AXI_CTRL_ARVALID && ~axi_rvalid)
	        begin
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; 
	        end
	      else if (axi_rvalid && S_AXI_CTRL_RREADY)
	        begin
	          axi_rvalid <= 1'b0;
	        end
	    end
	end

  assign regXX_rden = axi_arready & S_AXI_CTRL_ARVALID & ~axi_rvalid;
	always @(*)
	begin
    case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
      6'h00   : reg_data_out <= reg00_config;
      6'h01   : reg_data_out <= reg01_config;
      6'h02   : reg_data_out <= reg02_r_anomaly;
      6'h03   : reg_data_out <= reg03_r_anomaly;
      6'h04   : reg_data_out <= reg04_w_anomaly;
      6'h05   : reg_data_out <= reg05_w_anomaly;
      6'h06   : reg_data_out <= reg06_r_config;
      6'h07   : reg_data_out <= reg07_r_config;
      6'h08   : reg_data_out <= reg08_r_config;
      6'h09   : reg_data_out <= reg09_r_config;
      6'h0A   : reg_data_out <= reg10_r_config;
      6'h0B   : reg_data_out <= reg11_r_config;
      6'h0C   : reg_data_out <= reg12_r_config;
      6'h0D   : reg_data_out <= reg13_r_config;
      6'h0E   : reg_data_out <= reg14_r_config;
      6'h0F   : reg_data_out <= reg15_r_config;
      6'h10   : reg_data_out <= reg16_r_config;
      6'h11   : reg_data_out <= reg17_r_config;
      6'h12   : reg_data_out <= reg18_r_config;
      6'h13   : reg_data_out <= reg19_r_config;
      6'h14   : reg_data_out <= reg20_r_config;
      6'h15   : reg_data_out <= reg21_r_config;
      6'h16   : reg_data_out <= reg22_w_config;
      6'h17   : reg_data_out <= reg23_w_config;
      6'h18   : reg_data_out <= reg24_w_config;
      6'h19   : reg_data_out <= reg25_w_config;
      6'h1A   : reg_data_out <= reg26_w_config;
      6'h1B   : reg_data_out <= reg27_w_config;
      6'h1C   : reg_data_out <= reg28_w_config;
      6'h1D   : reg_data_out <= reg29_w_config;
      6'h1E   : reg_data_out <= reg30_w_config;
      6'h1F   : reg_data_out <= reg31_w_config;
      6'h20   : reg_data_out <= reg32_w_config;
      6'h21   : reg_data_out <= reg33_w_config;
      6'h22   : reg_data_out <= reg34_w_config;
      6'h23   : reg_data_out <= reg35_w_config;
      6'h24   : reg_data_out <= reg36_w_config;
      6'h25   : reg_data_out <= reg37_w_config;
      default : reg_data_out <= 0;
    endcase
	end

  	always @ (posedge ACLK)
	begin
	  if (ARESETN == 1'b0)
	    begin
	      axi_rdata  <= 0;
	    end
	  else
	    begin
	      if (regXX_rden)
	        begin
	          axi_rdata <= reg_data_out;    
	        end
	    end
	end

//-----------------END S CONTROL LOGIC

//-------------------- AXI M INTERNAL SIGNALS
  wire [C_M_AXI_ID_WIDTH-1 : 0]     M_AXI_AWID_wire;
  wire [C_M_AXI_ADDR_WIDTH-1 : 0]   M_AXI_AWADDR_wire;
  wire [7 : 0]                      M_AXI_AWLEN_wire;
  wire [2 : 0]                      M_AXI_AWSIZE_wire;
  wire [1 : 0]                      M_AXI_AWBURST_wire;
  wire                              M_AXI_AWLOCK_wire;
  wire [3 : 0]                      M_AXI_AWCACHE_wire;
  wire [2 : 0]                      M_AXI_AWPROT_wire;
  wire [3 : 0]                      M_AXI_AWQOS_wire;
  wire [C_M_AXI_AWUSER_WIDTH-1 : 0] M_AXI_AWUSER_wire;
  wire                              M_AXI_AWVALID_wire;
  wire                              M_AXI_AWREADY_wire;

  wire [C_M_AXI_DATA_WIDTH-1 : 0]   M_AXI_WDATA_wire;
  wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB_wire;
  wire                              M_AXI_WLAST_wire;
  wire [C_M_AXI_WUSER_WIDTH-1 : 0]  M_AXI_WUSER_wire;
  wire                              M_AXI_WVALID_wire;
  wire                              M_AXI_WREADY_wire;

  wire [C_M_AXI_ID_WIDTH-1 : 0]     M_AXI_BID_wire;
  wire [1 : 0]                      M_AXI_BRESP_wire;
  wire [C_M_AXI_BUSER_WIDTH-1 : 0]  M_AXI_BUSER_wire;
  wire                              M_AXI_BVALID_wire;
  wire                              M_AXI_BREADY_wire;

  wire [C_M_AXI_ID_WIDTH-1 : 0]     M_AXI_ARID_wire;
  wire [C_M_AXI_ADDR_WIDTH-1 : 0]   M_AXI_ARADDR_wire;
  wire [7 : 0]                      M_AXI_ARLEN_wire;
  wire [2 : 0]                      M_AXI_ARSIZE_wire;
  wire [1 : 0]                      M_AXI_ARBURST_wire;
  wire                              M_AXI_ARLOCK_wire;
  wire [3 : 0]                      M_AXI_ARCACHE_wire;
  wire [2 : 0]                      M_AXI_ARPROT_wire;
  wire [3 : 0]                      M_AXI_ARQOS_wire;
  wire [C_M_AXI_AWUSER_WIDTH-1 : 0] M_AXI_ARUSER_wire;
  wire                              M_AXI_ARVALID_wire;
  wire                              M_AXI_ARREADY_wire;

	wire [C_M_AXI_ID_WIDTH-1 : 0]     M_AXI_RID_wire;
	wire [C_M_AXI_DATA_WIDTH-1 : 0]   M_AXI_RDATA_wire;
	wire [1 : 0]                      M_AXI_RRESP_wire;
	wire                              M_AXI_RLAST_wire;
	wire [C_M_AXI_RUSER_WIDTH-1 : 0]  M_AXI_RUSER_wire;
	wire                              M_AXI_RVALID_wire;
	wire                              M_AXI_RREADY_wire;


	reg [C_M_AXI_ID_WIDTH-1 : 0]      M_AXI_AWID_INT;
	reg [C_M_AXI_ADDR_WIDTH-1 : 0]    M_AXI_AWADDR_INT;
	reg [7 : 0]                       M_AXI_AWLEN_INT;
	reg [2 : 0]                       M_AXI_AWSIZE_INT;
	reg [1 : 0]                       M_AXI_AWBURST_INT;
  reg                               M_AXI_AWLOCK_INT;
	reg [3 : 0]                       M_AXI_AWCACHE_INT;
	reg [2 : 0]                       M_AXI_AWPROT_INT;
	reg [3 : 0]                       M_AXI_AWQOS_INT;
	reg [C_M_AXI_AWUSER_WIDTH-1 : 0]  M_AXI_AWUSER_INT;

	reg [C_M_AXI_ID_WIDTH-1 : 0]      M_AXI_ARID_INT;
	reg [C_M_AXI_ADDR_WIDTH-1 : 0]    M_AXI_ARADDR_INT;
	reg [7 : 0]                       M_AXI_ARLEN_INT;
	reg [2 : 0]                       M_AXI_ARSIZE_INT;
 	reg [1 : 0]                       M_AXI_ARBURST_INT;
  reg                               M_AXI_ARLOCK_INT;
 	reg [3 : 0]                       M_AXI_ARCACHE_INT;
 	reg [2 : 0]                       M_AXI_ARPROT_INT;
	reg [3 : 0]                       M_AXI_ARQOS_INT;
	reg [C_M_AXI_ARUSER_WIDTH-1 : 0]  M_AXI_ARUSER_INT;

//-----------------END AXI M INTERNAL SIGNALS

//-------------------- MEMORY CNTRL LOGIC SIGNALS
  reg AW_ILL_TRANS [MAX_OUTS_TRANS-1 : 0];
  reg [LOG_MAX_OUTS_TRAN-1 : 0] AW_ILL_TRANS_FIL_PTR;
  reg [LOG_MAX_OUTS_TRAN-1 : 0] AW_ILL_DATA_TRANS_SRV_PTR;
  reg [LOG_MAX_OUTS_TRAN-1 : 0] AW_ILL_TRANS_SRV_PTR;
  reg AR_ILL_TRANS [MAX_OUTS_TRANS-1 : 0];
  reg [LOG_MAX_OUTS_TRAN-1 : 0] AR_ILL_TRANS_FIL_PTR;
  reg [LOG_MAX_OUTS_TRAN-1 : 0] AR_ILL_TRANS_SRV_PTR;
  reg                           AW_STATE;
  reg                           AR_STATE;
  reg                           B_STATE;
  reg                           R_STATE;
  reg                           AW_ILLEGAL_REQ;
  reg                           AR_ILLEGAL_REQ;

  wire                          W_DATA_TO_SERVE;
  wire                          W_B_TO_SERVE;
  wire                          W_CH_EN;

  wire                          AW_CH_EN;
  wire                          AR_CH_EN;
    
  reg                           AW_CH_DIS;
  reg                           AR_CH_DIS;
    
  wire                          AW_EN_RST;
  wire                          AR_EN_RST;

  wire [15 : 0]                 AW_ADDR_VALID;
  wire [15 : 0]                 AR_ADDR_VALID;

  wire [15 : 0]                 AW_HIGH_ADDR;
  wire [15 : 0]                 AR_HIGH_ADDR;

  wire                          AW_ADDR_VALID_FLAG;
  wire                          AR_ADDR_VALID_FLAG;
  wire                          AR_OVERFLOW_DETC;
  wire                          AW_OVERFLOW_DETC;
	
//-----------------END MEMORY CNTRL LOGIC SIGNALS

//-------------------- ACW WRITE STATE
  reg [1:0] acw_w_state;

  always @ (posedge ACLK) begin
    if (ARESETN == 1'b0) begin
      acw_w_state <= 2'b00;
    end
    else begin
      case (acw_w_state)
        2'b00: begin
          if (|reg00_config == 1'b1) begin
            acw_w_state <= 2'b01;  
          end
        end

        2'b01: begin
          if (~AW_STATE == 1'b1) begin
            if ( M_AXI_AWVALID_wire && M_AXI_AWREADY_wire) begin
              if ( AW_ADDR_VALID_FLAG == 0 ) begin
                acw_w_state <= 2'b10;
              end
            end
          end
        end

        2'b10: begin
          if (AW_EN_RST == 1'b1) begin
            acw_w_state <= 2'b01;
          end
        end

        default: begin
          acw_w_state <= acw_w_state;
        end
      endcase
    end
  end
  
//-----------------END ACW WRITE STATE

//-------------------- ACCESS CONTROL WRITE MANAGEMENT

  //single interrupt line
  //assign INTR_LINE = ~AR_CH_DIS || ~AW_CH_DIS;

  assign INTR_LINE_R = AR_CH_DIS;
  assign INTR_LINE_W = AW_CH_DIS;

  assign AW_CH_EN = ~AW_ILLEGAL_REQ && ~AW_CH_DIS;
  assign AR_CH_EN = ~AR_ILLEGAL_REQ && ~AR_CH_DIS;

  assign AW_EN_RST = reg01_config[0];
  assign AR_EN_RST = reg01_config[1];
  
  always @ (posedge ACLK)
  begin
    if (ARESETN == 1'b0)
      begin
  		  AR_CH_DIS <= 0;
  		  AW_CH_DIS <= 0;
      end
    else 
      begin
        if (AW_ILLEGAL_REQ)
          begin
            AW_CH_DIS <= 1;
          end
  	    else if (AW_EN_RST) 
          begin
            AW_CH_DIS <= 0;
          end

        if (AR_ILLEGAL_REQ) 
          begin
  		      AR_CH_DIS <= 1;
          end
  		  else if (AR_EN_RST) 
          begin
  	        AR_CH_DIS <= 0;
          end
      end
  end


  assign M_AXI_AWREADY_wire = ~AW_STATE && AW_CH_EN;
  assign M_AXI_AWVALID = AW_STATE && ~AW_ILLEGAL_REQ;

  assign M_AXI_AWID    = M_AXI_AWID_INT;
  assign M_AXI_AWADDR  = M_AXI_AWADDR_INT;
  assign M_AXI_AWLEN   = M_AXI_AWLEN_INT;
  assign M_AXI_AWSIZE  = M_AXI_AWSIZE_INT;
  assign M_AXI_AWBURST = M_AXI_AWBURST_INT;
  assign M_AXI_AWLOCK  = M_AXI_AWLOCK_INT;
  assign M_AXI_AWCACHE = M_AXI_AWCACHE_INT;
  assign M_AXI_AWPROT  = M_AXI_AWPROT_INT;
  assign M_AXI_AWQOS   = M_AXI_AWQOS_INT;
  assign M_AXI_AWUSER  = M_AXI_AWUSER_INT;

  assign AW_HIGH_ADDR = (M_AXI_AWADDR_wire + ((M_AXI_AWLEN_wire + 1) << C_LOG_BUS_SIZE_BYTE));

  assign AW_ADDR_VALID[0]  =  (reg00_config[16] && (AW_HIGH_ADDR <=  reg22_w_config[31:16]) && (M_AXI_AWADDR_wire[31:16] >= reg22_w_config[15:0]) ) ? 1 : 0;
  assign AW_ADDR_VALID[1]  =  (reg00_config[17] && (AW_HIGH_ADDR <=  reg23_w_config[31:16]) && (M_AXI_AWADDR_wire[31:16] >= reg23_w_config[15:0]) ) ? 1 : 0;
  assign AW_ADDR_VALID[2]  =  (reg00_config[18] && (AW_HIGH_ADDR <=  reg24_w_config[31:16]) && (M_AXI_AWADDR_wire[31:16] >= reg24_w_config[15:0]) ) ? 1 : 0;
  assign AW_ADDR_VALID[3]  =  (reg00_config[19] && (AW_HIGH_ADDR <=  reg25_w_config[31:16]) && (M_AXI_AWADDR_wire[31:16] >= reg25_w_config[15:0]) ) ? 1 : 0;
  assign AW_ADDR_VALID[4]  =  (reg00_config[20] && (AW_HIGH_ADDR <=  reg26_w_config[31:16]) && (M_AXI_AWADDR_wire[31:16] >= reg26_w_config[15:0]) ) ? 1 : 0;
  assign AW_ADDR_VALID[5]  =  (reg00_config[21] && (AW_HIGH_ADDR <=  reg27_w_config[31:16]) && (M_AXI_AWADDR_wire[31:16] >= reg27_w_config[15:0]) ) ? 1 : 0;
  assign AW_ADDR_VALID[6]  =  (reg00_config[22] && (AW_HIGH_ADDR <=  reg28_w_config[31:16]) && (M_AXI_AWADDR_wire[31:16] >= reg28_w_config[15:0]) ) ? 1 : 0;
  assign AW_ADDR_VALID[7]  =  (reg00_config[23] && (AW_HIGH_ADDR <=  reg29_w_config[31:16]) && (M_AXI_AWADDR_wire[31:16] >= reg29_w_config[15:0]) ) ? 1 : 0;
  assign AW_ADDR_VALID[8]  =  (reg00_config[24] && (AW_HIGH_ADDR <=  reg30_w_config[31:16]) && (M_AXI_AWADDR_wire[31:16] >= reg30_w_config[15:0]) ) ? 1 : 0;
  assign AW_ADDR_VALID[9]  =  (reg00_config[25] && (AW_HIGH_ADDR <=  reg31_w_config[31:16]) && (M_AXI_AWADDR_wire[31:16] >= reg31_w_config[15:0]) ) ? 1 : 0;
  assign AW_ADDR_VALID[10] =  (reg00_config[26] && (AW_HIGH_ADDR <=  reg32_w_config[31:16]) && (M_AXI_AWADDR_wire[31:16] >= reg32_w_config[15:0]) ) ? 1 : 0;
  assign AW_ADDR_VALID[11] =  (reg00_config[27] && (AW_HIGH_ADDR <=  reg33_w_config[31:16]) && (M_AXI_AWADDR_wire[31:16] >= reg33_w_config[15:0]) ) ? 1 : 0;
  assign AW_ADDR_VALID[12] =  (reg00_config[28] && (AW_HIGH_ADDR <=  reg34_w_config[31:16]) && (M_AXI_AWADDR_wire[31:16] >= reg34_w_config[15:0]) ) ? 1 : 0;
  assign AW_ADDR_VALID[13] =  (reg00_config[29] && (AW_HIGH_ADDR <=  reg35_w_config[31:16]) && (M_AXI_AWADDR_wire[31:16] >= reg35_w_config[15:0]) ) ? 1 : 0;
  assign AW_ADDR_VALID[14] =  (reg00_config[30] && (AW_HIGH_ADDR <=  reg36_w_config[31:16]) && (M_AXI_AWADDR_wire[31:16] >= reg36_w_config[15:0]) ) ? 1 : 0;
  assign AW_ADDR_VALID[15] =  (reg00_config[31] && (AW_HIGH_ADDR <=  reg37_w_config[31:16]) && (M_AXI_AWADDR_wire[31:16] >= reg37_w_config[15:0]) ) ? 1 : 0;

  // ------------ OVERFLOW MANAGEMENT 04/29/2021 -----------------
    //assign AW_ADDR_VALID_FLAG = |AW_ADDR_VALID;

    assign AW_ADDR_VALID_FLAG = |AW_ADDR_VALID & ~AW_OVERFLOW_DETC;
    assign AW_OVERFLOW_DETC = M_AXI_AWADDR_wire[C_M_AXI_ADDR_WIDTH-1] & ~AW_HIGH_ADDR[C_M_AXI_ADDR_WIDTH-1];

  // -------------------------------------------------------------

  always @ (posedge ACLK)
  begin
    if(ARESETN == 1'b0)
      begin
        AW_STATE          <= 1'b0;
        AW_ILLEGAL_REQ       <= 0;
        AW_ILL_TRANS_FIL_PTR <= 0;
        M_AXI_AWID_INT       <= 0;
        M_AXI_AWADDR_INT     <= 0;
        M_AXI_AWLEN_INT      <= 0;
        M_AXI_AWSIZE_INT     <= 0;
        M_AXI_AWBURST_INT    <= 0;
        M_AXI_AWLOCK_INT     <= 0;
        M_AXI_AWCACHE_INT    <= 0;
        M_AXI_AWPROT_INT     <= 0;
        M_AXI_AWQOS_INT      <= 0;
        M_AXI_AWUSER_INT     <= 0;
        reg04_w_anomaly      <= 0;
        reg05_w_anomaly      <= 0;
      end
    else
      begin
        if(~AW_STATE) 
          begin
            if( M_AXI_AWVALID_wire && M_AXI_AWREADY_wire)
              begin
                AW_STATE <= 1'b1;
                if( AW_ADDR_VALID_FLAG == 1 )
                  begin
                    AW_ILLEGAL_REQ    <= 1'b0;
                    AW_ILL_TRANS[AW_ILL_TRANS_FIL_PTR] <= 1'b0;
                    M_AXI_AWID_INT    <= M_AXI_AWID_wire;
                    M_AXI_AWADDR_INT  <= M_AXI_AWADDR_wire;
                    M_AXI_AWLEN_INT   <= M_AXI_AWLEN_wire;
                    M_AXI_AWSIZE_INT  <= M_AXI_AWSIZE_wire;
                    M_AXI_AWBURST_INT <= M_AXI_AWBURST_wire;
                    M_AXI_AWLOCK_INT  <= M_AXI_AWLOCK_wire;
                    M_AXI_AWCACHE_INT <= M_AXI_AWCACHE_wire;
                    M_AXI_AWPROT_INT  <= M_AXI_AWPROT_wire;
                    M_AXI_AWQOS_INT   <= M_AXI_AWQOS_wire;
                    M_AXI_AWUSER_INT  <= M_AXI_AWUSER_wire;
                  end
                else
                  begin
                    AW_ILLEGAL_REQ <= 1'b1;
                    AW_ILL_TRANS[AW_ILL_TRANS_FIL_PTR] <= 1'b1;
                    reg04_w_anomaly <= M_AXI_AWADDR_wire;
                    reg05_w_anomaly[7:0] <= M_AXI_AWLEN_wire;
                    reg05_w_anomaly[C_M_AXI_DATA_WIDTH - 1 : C_M_AXI_DATA_WIDTH - 1 - C_M_AXI_ID_WIDTH] <= M_AXI_AWID_wire;
                    reg05_w_anomaly[C_M_AXI_DATA_WIDTH - 1 - C_M_AXI_ID_WIDTH - 1 : C_M_AXI_DATA_WIDTH - 1 - C_M_AXI_ID_WIDTH - 1 - 3] <= M_AXI_AWPROT_wire;
                    reg05_w_anomaly[C_M_AXI_DATA_WIDTH - 1 - C_M_AXI_ID_WIDTH - 1 - 3 - 1 : C_M_AXI_DATA_WIDTH - 1 - C_M_AXI_ID_WIDTH - 1 - 3 - 1 - 3] <= M_AXI_AWCACHE_wire;
                    reg05_w_anomaly[C_M_AXI_DATA_WIDTH - 1 - C_M_AXI_ID_WIDTH - 1 - 3 - 1 - 3 - 1 : C_M_AXI_DATA_WIDTH - 1 - C_M_AXI_ID_WIDTH - 1 - 3 - 1 - 3 - 1] <= M_AXI_AWLOCK_wire;
                  end
                AW_ILL_TRANS_FIL_PTR <= AW_ILL_TRANS_FIL_PTR + 1'b1;
              end
          end
        else   
          begin
            if( (AW_ILLEGAL_REQ == 1'b0 && M_AXI_AWREADY == 1'b1 ) || AW_ILLEGAL_REQ == 1'b1 )  
              begin
                AW_STATE <= 1'b0;
                AW_ILLEGAL_REQ <= 0;
              end
          end
      end
  end

  assign M_AXI_WDATA       = W_CH_EN ? M_AXI_WDATA_wire  : 0;
  assign M_AXI_WSTRB       = W_CH_EN ? M_AXI_WSTRB_wire  : 0;
  assign M_AXI_WLAST       = W_CH_EN ? M_AXI_WLAST_wire  : 0;
  assign M_AXI_WUSER       = W_CH_EN ? M_AXI_WUSER_wire  : 0;
  assign M_AXI_WVALID      = W_CH_EN ? M_AXI_WVALID_wire : 0;
  assign M_AXI_WREADY_wire = W_CH_EN ? M_AXI_WREADY      : 1;

  assign W_DATA_TO_SERVE = |(AW_ILL_DATA_TRANS_SRV_PTR ^ AW_ILL_TRANS_FIL_PTR);
  assign W_CH_EN = W_DATA_TO_SERVE & ~AW_ILL_TRANS[AW_ILL_DATA_TRANS_SRV_PTR];

  always @ (posedge ACLK)
  begin
    if(ARESETN == 0)
      begin
        AW_ILL_DATA_TRANS_SRV_PTR <= 0;
      end
    else
      begin
        if(M_AXI_WLAST_wire == 1 && M_AXI_WVALID_wire == 1)
          begin
            AW_ILL_DATA_TRANS_SRV_PTR <= AW_ILL_DATA_TRANS_SRV_PTR + 1'b1;
          end
      end
  end

  assign M_AXI_BID_wire    = ~B_STATE ? M_AXI_BID         : 0;
  assign M_AXI_BRESP_wire  = ~B_STATE ? M_AXI_BRESP       : 2'b11; 
  assign M_AXI_BUSER_wire  = ~B_STATE ? M_AXI_BUSER       : 0;
  assign M_AXI_BVALID_wire = ~B_STATE ? M_AXI_BVALID      : 1;
  assign M_AXI_BREADY      = ~B_STATE ? M_AXI_BREADY_wire : 0;

  assign W_B_TO_SERVE = |(AW_ILL_TRANS_SRV_PTR ^ AW_ILL_TRANS_FIL_PTR);

  always @ (posedge ACLK)
  begin
    if (ARESETN == 1'b0)
      begin
          B_STATE <= 0;
          AW_ILL_TRANS_SRV_PTR <= 0;
      end
    else
      begin
        if (~B_STATE)
          begin
            if (M_AXI_WVALID_wire == 1 && M_AXI_WLAST_wire == 1 && AW_ILL_TRANS[AW_ILL_TRANS_SRV_PTR] == 1)
              begin
                B_STATE <= 1;
              end
          end
          else
            begin
              if(M_AXI_BREADY_wire == 1)
                begin
                  B_STATE <= 0;
                end
            end
          if(M_AXI_BVALID_wire == 1 && M_AXI_BREADY_wire == 1)
            begin
              AW_ILL_TRANS_SRV_PTR <= AW_ILL_TRANS_SRV_PTR + 1'b1;
            end
      end
  end

//-----------------END ACCESS CONTROL WRITE MANAGEMENT

//-------------------- ACW READ STATE
  reg [1:0] acw_r_state;

  always @ (posedge ACLK) begin
    if (ARESETN == 1'b0) begin
      acw_r_state <= 2'b00;
    end
    else begin
      case (acw_r_state)
        2'b00: begin
          if (|reg00_config == 1'b1) begin
            acw_r_state <= 2'b01;  
          end
        end

        2'b01: begin
          if (~AR_STATE == 1'b1) begin
            if ( M_AXI_ARVALID_wire && M_AXI_ARREADY_wire) begin
              if ( AR_ADDR_VALID_FLAG == 0 ) begin
                acw_r_state <= 2'b10;
              end
            end
          end
        end

        2'b10: begin
          if (AR_EN_RST == 1'b1) begin
            acw_r_state <= 2'b01;
          end
        end

        default: begin
          acw_r_state <= acw_r_state;
        end
      endcase
    end
  end
  
//-----------------END ACW READ STATE
  
//-------------------- ACCESS CONTROL READ MANAGEMENT
  assign M_AXI_ARREADY_wire = ~AR_STATE && AR_CH_EN;
  assign M_AXI_ARVALID = AR_STATE && ~AR_ILLEGAL_REQ;


  assign M_AXI_ARID    = M_AXI_ARID_INT;
  assign M_AXI_ARADDR  = M_AXI_ARADDR_INT;
  assign M_AXI_ARLEN   = M_AXI_ARLEN_INT;
  assign M_AXI_ARSIZE  = M_AXI_ARSIZE_INT;
  assign M_AXI_ARBURST = M_AXI_ARBURST_INT;
  assign M_AXI_ARLOCK  = M_AXI_ARLOCK_INT;
  assign M_AXI_ARCACHE = M_AXI_ARCACHE_INT;
  assign M_AXI_ARPROT  = M_AXI_ARPROT_INT;
  assign M_AXI_ARQOS   = M_AXI_ARQOS_INT;
  assign M_AXI_ARUSER  = M_AXI_ARUSER_INT;

  assign AR_HIGH_ADDR = (M_AXI_ARADDR_wire + ((M_AXI_ARLEN_wire + 1) << C_LOG_BUS_SIZE_BYTE));

  assign AR_ADDR_VALID[0]  = (reg00_config[0]  && (AR_HIGH_ADDR <= reg06_r_config[31:16]) && (M_AXI_ARADDR_wire[31:16] >= reg06_r_config[15:0]) ) ? 1 : 0;
  assign AR_ADDR_VALID[1]  = (reg00_config[1]  && (AR_HIGH_ADDR <= reg07_r_config[31:16]) && (M_AXI_ARADDR_wire[31:16] >= reg07_r_config[15:0]) ) ? 1 : 0;
  assign AR_ADDR_VALID[2]  = (reg00_config[2]  && (AR_HIGH_ADDR <= reg08_r_config[31:16]) && (M_AXI_ARADDR_wire[31:16] >= reg08_r_config[15:0]) ) ? 1 : 0;
  assign AR_ADDR_VALID[3]  = (reg00_config[3]  && (AR_HIGH_ADDR <= reg09_r_config[31:16]) && (M_AXI_ARADDR_wire[31:16] >= reg09_r_config[15:0]) ) ? 1 : 0;
  assign AR_ADDR_VALID[4]  = (reg00_config[4]  && (AR_HIGH_ADDR <= reg10_r_config[31:16]) && (M_AXI_ARADDR_wire[31:16] >= reg10_r_config[15:0]) ) ? 1 : 0;
  assign AR_ADDR_VALID[5]  = (reg00_config[5]  && (AR_HIGH_ADDR <= reg11_r_config[31:16]) && (M_AXI_ARADDR_wire[31:16] >= reg11_r_config[15:0]) ) ? 1 : 0;
  assign AR_ADDR_VALID[6]  = (reg00_config[6]  && (AR_HIGH_ADDR <= reg12_r_config[31:16]) && (M_AXI_ARADDR_wire[31:16] >= reg12_r_config[15:0]) ) ? 1 : 0;
  assign AR_ADDR_VALID[7]  = (reg00_config[7]  && (AR_HIGH_ADDR <= reg13_r_config[31:16]) && (M_AXI_ARADDR_wire[31:16] >= reg13_r_config[15:0]) ) ? 1 : 0;
  assign AR_ADDR_VALID[8]  = (reg00_config[8]  && (AR_HIGH_ADDR <= reg14_r_config[31:16]) && (M_AXI_ARADDR_wire[31:16] >= reg14_r_config[15:0]) ) ? 1 : 0;
  assign AR_ADDR_VALID[9]  = (reg00_config[9]  && (AR_HIGH_ADDR <= reg15_r_config[31:16]) && (M_AXI_ARADDR_wire[31:16] >= reg15_r_config[15:0]) ) ? 1 : 0;
  assign AR_ADDR_VALID[10] = (reg00_config[10] && (AR_HIGH_ADDR <= reg16_r_config[31:16]) && (M_AXI_ARADDR_wire[31:16] >= reg16_r_config[15:0]) ) ? 1 : 0;
  assign AR_ADDR_VALID[11] = (reg00_config[11] && (AR_HIGH_ADDR <= reg17_r_config[31:16]) && (M_AXI_ARADDR_wire[31:16] >= reg17_r_config[15:0]) ) ? 1 : 0;
  assign AR_ADDR_VALID[12] = (reg00_config[12] && (AR_HIGH_ADDR <= reg18_r_config[31:16]) && (M_AXI_ARADDR_wire[31:16] >= reg18_r_config[15:0]) ) ? 1 : 0;
  assign AR_ADDR_VALID[13] = (reg00_config[13] && (AR_HIGH_ADDR <= reg19_r_config[31:16]) && (M_AXI_ARADDR_wire[31:16] >= reg19_r_config[15:0]) ) ? 1 : 0;
  assign AR_ADDR_VALID[14] = (reg00_config[14] && (AR_HIGH_ADDR <= reg20_r_config[31:16]) && (M_AXI_ARADDR_wire[31:16] >= reg20_r_config[15:0]) ) ? 1 : 0;
  assign AR_ADDR_VALID[15] = (reg00_config[15] && (AR_HIGH_ADDR <= reg21_r_config[31:16]) && (M_AXI_ARADDR_wire[31:16] >= reg21_r_config[15:0]) ) ? 1 : 0;


  // ------------ OVERFLOW MANAGEMENT 04/29/2021 -----------------
    //assign AR_ADDR_VALID_FLAG = |AR_ADDR_VALID;

    assign AR_ADDR_VALID_FLAG = |AR_ADDR_VALID & ~AR_OVERFLOW_DETC;
    assign AR_OVERFLOW_DETC = M_AXI_ARADDR_wire[C_M_AXI_ADDR_WIDTH-1] & ~AR_HIGH_ADDR[C_M_AXI_ADDR_WIDTH-1];

  // -------------------------------------------------------------

  always @ (posedge ACLK)
  begin
    if (ARESETN == 1'b0)
      begin
        AR_STATE       <= 1'b0;
        AR_ILLEGAL_REQ    <= 0;
        AR_ILL_TRANS_FIL_PTR <= 0;
        M_AXI_ARID_INT    <= 0;
        M_AXI_ARADDR_INT  <= 0;
        M_AXI_ARLEN_INT   <= 0;
        M_AXI_ARSIZE_INT  <= 0;
        M_AXI_ARBURST_INT <= 0;
        M_AXI_ARLOCK_INT  <= 0;
        M_AXI_ARCACHE_INT <= 0;
        M_AXI_ARPROT_INT  <= 0;
        M_AXI_ARQOS_INT   <= 0;
        M_AXI_ARUSER_INT  <= 0;
        reg02_r_anomaly   <= 0;
        reg03_r_anomaly   <= 0;
      end
    else
      begin
        if(~AR_STATE)
          begin
            if( M_AXI_ARVALID_wire && M_AXI_ARREADY_wire)
              begin
                AR_STATE <= 1;
                if(AR_ADDR_VALID_FLAG)
                  begin
                    AR_ILLEGAL_REQ <= 1'b0;
                    AR_ILL_TRANS[AR_ILL_TRANS_FIL_PTR] <= 1'b0;
                    M_AXI_ARID_INT <= M_AXI_ARID_wire;
                    M_AXI_ARADDR_INT <= M_AXI_ARADDR_wire;
                    M_AXI_ARLEN_INT <= M_AXI_ARLEN_wire;
                    M_AXI_ARSIZE_INT <= M_AXI_ARSIZE_wire;
                    M_AXI_ARBURST_INT <= M_AXI_ARBURST_wire;
                    M_AXI_ARLOCK_INT <= M_AXI_ARLOCK_wire;
                    M_AXI_ARCACHE_INT <= M_AXI_ARCACHE_wire;
                    M_AXI_ARPROT_INT <= M_AXI_ARPROT_wire;
                    M_AXI_ARQOS_INT <= M_AXI_ARQOS_wire;
                    M_AXI_ARUSER_INT <= M_AXI_ARUSER_wire;
                  end
                else
                  begin
                    AR_ILLEGAL_REQ <= 1'b1;
                    AR_ILL_TRANS[AR_ILL_TRANS_FIL_PTR] <= 1'b1;
                    reg02_r_anomaly <= M_AXI_AWADDR_wire;
                    reg03_r_anomaly[7:0] <= M_AXI_AWLEN_wire;
                    reg03_r_anomaly[C_M_AXI_DATA_WIDTH - 1 : C_M_AXI_DATA_WIDTH - 1 - C_M_AXI_ID_WIDTH] <= M_AXI_AWID_wire;
                    reg03_r_anomaly[C_M_AXI_DATA_WIDTH - 1 - C_M_AXI_ID_WIDTH - 1 : C_M_AXI_DATA_WIDTH - 1 - C_M_AXI_ID_WIDTH - 1 - 3] <= M_AXI_AWPROT_wire;
                    reg03_r_anomaly[C_M_AXI_DATA_WIDTH - 1 - C_M_AXI_ID_WIDTH - 1 - 3 - 1 : C_M_AXI_DATA_WIDTH - 1 - C_M_AXI_ID_WIDTH - 1 - 3 - 1 - 3] <= M_AXI_AWCACHE_wire;
                    reg03_r_anomaly[C_M_AXI_DATA_WIDTH - 1 - C_M_AXI_ID_WIDTH - 1 - 3 - 1 - 3 - 1 : C_M_AXI_DATA_WIDTH - 1 - C_M_AXI_ID_WIDTH - 1 - 3 - 1 - 3 - 1] <= M_AXI_AWLOCK_wire;
                  end
                  AR_ILL_TRANS_FIL_PTR <= AR_ILL_TRANS_FIL_PTR + 1'b1;
              end
          end
        else
          begin
            if( (AR_ILLEGAL_REQ == 1'b0 && M_AXI_ARREADY == 1'b1 ) || AR_ILLEGAL_REQ == 1'b1 )
              begin
                AR_STATE <= 1'b0;
                AR_ILLEGAL_REQ <= 0;
              end
          end
      end
  end

  assign M_AXI_RID_wire    = ~R_STATE ? M_AXI_RID         : 0;
  assign M_AXI_RDATA_wire  = ~R_STATE ? M_AXI_RDATA       : 0;
  assign M_AXI_RRESP_wire  = ~R_STATE ? M_AXI_RRESP   : 2'b11;
  assign M_AXI_RLAST_wire  = ~R_STATE ? M_AXI_RLAST       : 1;
  assign M_AXI_RUSER_wire  = ~R_STATE ? M_AXI_RUSER       : 0;
  assign M_AXI_RVALID_wire = ~R_STATE ? M_AXI_RVALID      : 1;
  assign M_AXI_RREADY      = ~R_STATE ? M_AXI_RREADY_wire : 0;

  always @ (posedge ACLK)
  begin
    if (ARESETN == 1'b0)
      begin
        R_STATE <= 1'b0;
        AR_ILL_TRANS_SRV_PTR <= 0;
      end
    else
      begin
        if (~R_STATE)
          begin
            if(AR_STATE == 1'b1 && AR_ILL_TRANS[AR_ILL_TRANS_SRV_PTR] == 1'b1 )
              begin
                R_STATE <= 1'b1;
              end
          end
        else
          begin
            if(M_AXI_RREADY_wire == 1'b1)
              begin
                R_STATE <= 0;
              end
          end
        if(M_AXI_RREADY_wire == 1 && M_AXI_RVALID_wire == 1 && M_AXI_RLAST_wire == 1)
          begin
            AR_ILL_TRANS_SRV_PTR <= AR_ILL_TRANS_SRV_PTR + 1'b1;
          end
      end
  end

//-----------------END ACCESS CONTROL READ MANAGEMENT

//-------------------- INSTANCIATE THE HARDWARE MODULE
  wire [7 : 0]  r_displ_wire;          // : in std_logic_vector (7 downto 0);
  wire [7 : 0]  w_displ_wire;          // : in std_logic_vector (7 downto 0);

  wire [7 : 0]  r_max_outs_wire;       // : in std_logic_vector (7 downto 0);
  wire [7 : 0]  w_max_outs_wire;       // : in std_logic_vector (7 downto 0);

  wire [15 : 0] r_phase_wire;          // : in std_logic_vector (15 downto 0);
  wire [15 : 0] w_phase_wire;          // : in std_logic_vector (15 downto 0);

  wire [15 : 0] r_misb_clk_cycle_wire; // : in std_logic_vector(15 downto 0);
  wire [15 : 0] w_misb_clk_cycle_wire; // : in std_logic_vector(15 downto 0);


  assign r_displ_wire = 1;          // : in std_logic_vector (7 downto 0);
  assign w_displ_wire = 1;          // : in std_logic_vector (7 downto 0);

  assign r_max_outs_wire = 6;       // : in std_logic_vector (7 downto 0);
  assign w_max_outs_wire = 6;       // : in std_logic_vector (7 downto 0);

  assign r_phase_wire = 1;          // : in std_logic_vector (15 downto 0);
  assign w_phase_wire = 1;          // : in std_logic_vector (15 downto 0);

  assign r_misb_clk_cycle_wire = 0; // : in std_logic_vector(15 downto 0);
  assign w_misb_clk_cycle_wire = 0; // : in std_logic_vector(15 downto 0);


  axi_m_generic_module myHWtask(
    .r_misb_clk_cnt_out(),
    .r_ready_to_sample_out(),
    .clk              (ACLK),
    .r_start          (r_start_wire),
    .w_start          (w_start_wire),
    .reset            (reset_wire),
    .axi_resetn       (ARESETN),
    .r_displ          (r_displ_wire),
    .w_displ          (w_displ_wire),
    .r_max_outs       (r_max_outs_wire),
    .w_max_outs       (w_max_outs_wire),
    .r_phase          (r_phase_wire),
    .w_phase          (w_phase_wire),
    .r_base_addr      (r_base_addr_wire),
    .w_base_addr      (w_base_addr_wire),
    .r_num_trans      (r_num_trans_wire),
    .w_num_trans      (w_num_trans_wire),
    .r_burst_len      (r_burst_len_wire),
    .w_burst_len      (w_burst_len_wire), //  : in std_logic_vector(7 downto 0);
    .data_val         (data_val_wire), //    : in std_logic;
    .r_misb_clk_cycle (r_misb_clk_cycle_wire), //    : in std_logic_vector(15 downto 0);
    .w_misb_clk_cycle (w_misb_clk_cycle_wire), //   : in std_logic_vector(15 downto 0);
    .w_done           (w_done_wire),     // : out std_logic;
    .r_done           (r_done_wire),    //  : out std_logic;

    .m_axi_awid       (M_AXI_AWID_wire),
    .m_axi_awaddr     (M_AXI_AWADDR_wire),	//: out std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    .m_axi_awlen      (M_AXI_AWLEN_wire),   //: out std_logic_vector(7 downto 0);
    .m_axi_awsize     (M_AXI_AWSIZE_wire),  //: out std_logic_vector(2 downto 0);
    .m_axi_awburst    (M_AXI_AWBURST_wire),	//: out std_logic_vector(1 downto 0);
    .m_axi_awlock     (M_AXI_AWLOCK_wire),  //: out std_logic;
    .m_axi_awcache    (M_AXI_AWCACHE_wire),	//: out std_logic_vector(3 downto 0);
    .m_axi_awprot     (M_AXI_AWPROT_wire),  //: out std_logic_vector(2 downto 0);
    .m_axi_awqos      (M_AXI_AWQOS_wire),   //: out std_logic_vector(3 downto 0);
    .m_axi_awuser     (M_AXI_AWUSER_wire),  //: out std_logic_vector(7 downto 0);
    .m_axi_awvalid    (M_AXI_AWVALID_wire), //: out std_logic;
    .m_axi_awready    (M_AXI_AWREADY_wire), //: in std_logic;
    .m_axi_wdata      (M_AXI_WDATA_wire),	  //: out std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
    .m_axi_wstrb      (M_AXI_WSTRB_wire),   //: out std_logic_vector(C_M00_AXI_DATA_WIDTH/8-1 downto 0);
    .m_axi_wlast      (M_AXI_WLAST_wire),	  //: out std_logic;
    .m_axi_wuser      (M_AXI_WUSER_wire),   //: out std_logic_vector(7 downto 0);
    .m_axi_wvalid     (M_AXI_WVALID_wire),	//: out std_logic;
    .m_axi_wready     (M_AXI_WREADY_wire),  //: in std_logic;
    .m_axi_bid        (M_AXI_BID_wire),	    //: in std_logic_vector(C_M00_AXI_ID_WIDTH-1 downto 0);
    .m_axi_bresp      (M_AXI_BRESP_wire),   //: in std_logic_vector(1 downto 0);
    .m_axi_buser      (M_AXI_BUSER_wire),   //: in std_logic_vector(7 downto 0);
    .m_axi_bvalid     (M_AXI_BVALID_wire),  //: in std_logic;
    .m_axi_bready     (M_AXI_BREADY_wire),  //: out std_logic;
    .m_axi_arid       (M_AXI_ARID_wire),    //: out std_logic_vector(C_M00_AXI_ID_WIDTH-1 downto 0);
    .m_axi_araddr     (M_AXI_ARADDR_wire),	//: out std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
    .m_axi_arlen      (M_AXI_ARLEN_wire),   //: out std_logic_vector(7 downto 0);
    .m_axi_arsize     (M_AXI_ARSIZE_wire),  //: out std_logic_vector(2 downto 0);
    .m_axi_arburst    (M_AXI_ARBURST_wire),	//: out std_logic_vector(1 downto 0);
    .m_axi_arlock     (M_AXI_ARLOCK_wire),	//: out std_logic;
    .m_axi_arcache    (M_AXI_ARCACHE_wire), //: out std_logic_vector(3 downto 0);
    .m_axi_arprot     (M_AXI_ARPROT_wire),	//: out std_logic_vector(2 downto 0);
    .m_axi_arqos      (M_AXI_ARQOS_wire),   //: out std_logic_vector(3 downto 0);
    .m_axi_aruser     (M_AXI_ARUSER_wire),	//: out std_logic_vector(7 downto 0);
    .m_axi_arvalid    (M_AXI_ARVALID_wire),	//: out std_logic := '0'; -- initializing handshake signals on the address read channel
    .m_axi_arready    (M_AXI_ARREADY_wire),	//: in std_logic;
    .m_axi_rid        (M_AXI_RID_wire),	    //: in std_logic_vector(C_M00_AXI_ID_WIDTH-1 downto 0);
    .m_axi_rdata      (M_AXI_RDATA_wire),   //: in std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
    .m_axi_rresp      (M_AXI_RRESP_wire),   //: in std_logic_vector(1 downto 0);
    .m_axi_rlast      (M_AXI_RLAST_wire),	  //: in std_logic;
    .m_axi_ruser      (M_AXI_RUSER_wire),   //: in std_logic_vector(7 downto 0);
    .m_axi_rvalid     (M_AXI_RVALID_wire),  //: in std_logic;
    .m_axi_rready     (M_AXI_RREADY_wire)   //: out std_logic
  );

//-----------------END INSTANCIATE THE HARDWARE MODULE

  reg [C_S_CTRL_AXI-1 : 0] reg0_config;
  reg [31 : 0] internal_data;


  always @ (posedge ACLK)
  begin
    if (ARESETN == 1'b0)
      begin
        reg0_config <= 0;
      end
    else
      begin
        if (i_config == 1'b1)
          begin
            reg0_config <= reg0_config + 1'b1;
          end
      end
  end

  always @ (posedge ACLK)
  begin
    if (ARESETN == 1'b0)
      begin
        internal_data <= 32'h0000FFFF;
      end
    else
      begin
        internal_data <= internal_data;
      end
  end


  assign o_data = (reg0_config[0] == 1'b1) ? internal_data  : 32'hFFFF0000;
endmodule
