`timescale 1 ns / 1 ps

module axis_fifo_m_v1_0 # (
	// Parameters of Axi Master Bus Interface M_AXIS
	parameter integer 	C_M_AXIS_TDATA_WIDTH = 32	,
	parameter integer 	C_M_AXIS_START_COUNT = 32	,
	parameter integer  	WRITE_DATA_WIDTH = 32		,
	parameter integer 	FIFO_WRITE_DEPTH = 4096		,
	parameter integer	LENGTH_OF_FRAME = 1024		
)
(
	// Ports of FIFO write interface
    input                  							rst_n           	,
    input                  							wr_clk              ,
    input         [WRITE_DATA_WIDTH - 1 : 0]   		din                 ,
    input                  							wr_en               ,
    output                 							full                ,
    output                 							wr_rst_busy         ,
	// Ports of Axi Master Bus Interface M_AXIS
	input 		  									m_axis_aclk			,
	input 		  									m_axis_aresetn		,
	output 		  									m_axis_tvalid		,
	output 		 [C_M_AXIS_TDATA_WIDTH-1 : 0] 		m_axis_tdata		,
	output 		 [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] 	m_axis_tkeep		,
	output 		  									m_axis_tlast		,
	input 		  									m_axis_tready		
);

// FIFO read interface
reg 										rst_n0			;
reg 										rst_n1			;

wire                    					rd_en           ;
wire    [C_M_AXIS_TDATA_WIDTH-1 : 0]      	dout            ;
wire 										prog_empty		;


// Instantiation of Axi Bus Interface M_AXIS
axis_fifo_m_v1_0_M_AXIS # ( 
	.C_M_AXIS_TDATA_WIDTH		(C_M_AXIS_TDATA_WIDTH		),
	.C_M_START_COUNT			(C_M_AXIS_START_COUNT		),
	.LENGTH_OF_FRAME			(LENGTH_OF_FRAME			)
) axis_fifo_m_v1_0_M_AXIS_inst (
    .tx_en          			(rd_en          			),
    .dout           			(dout           			),
	.prog_empty					(prog_empty					),

	.M_AXIS_ACLK				(m_axis_aclk				),
	.M_AXIS_ARESETN				(m_axis_aresetn				),
	.M_AXIS_TVALID				(m_axis_tvalid				),
	.M_AXIS_TDATA				(m_axis_tdata				),
	.M_AXIS_TKEEP				(m_axis_tkeep				),
	.M_AXIS_TLAST				(m_axis_tlast				),
	.M_AXIS_TREADY				(m_axis_tready				)
);

// delay rst_n signal by two clock cycle, make it synchronize with wr_clk
always @(posedge wr_clk) begin
	rst_n0 <= rst_n;
	rst_n1 <= rst_n0;
end

// Add user logic here
xpm_fifo_async # (
    .CDC_SYNC_STAGES        (2           			),	// positive integer
    .DOUT_RESET_VALUE       ("0"      	 			),	// String
    .FIFO_MEMORY_TYPE       ("block"     			),	// string; "auto", "block", or "distributed";
    .FIFO_READ_LATENCY      (0           			),	// positive integer;
    .FIFO_WRITE_DEPTH       (FIFO_WRITE_DEPTH       ),	// Range: 16 - 4194304
    .FULL_RESET_VALUE       (0           			),	// positive integer; 0 or 1
    .PROG_EMPTY_THRESH      (10          			),	// positive integer
    .PROG_FULL_THRESH       (20          			),	// positive integer
    .READ_DATA_WIDTH        (C_M_AXIS_TDATA_WIDTH   ),	// positive integer
    .WRITE_DATA_WIDTH       (WRITE_DATA_WIDTH       ),	// positive integer
    .READ_MODE              ("fwft"      			),	// string; "std" or "fwft";
    .RELATED_CLOCKS         (0           			),	// positive integer; 0 or 1
    .USE_ADV_FEATURES       ("0A0A"      			),	// string; "0000" to "1F1F"; 
    .WAKEUP_TIME            (0           			) 	// positive integer; 0 or 2;
) xpm_fifo_W_inst (
	.almost_empty       (			        ),
	.prog_full          (                   ),
	.prog_empty         (prog_empty        	),
	.rst                (~rst_n1         	),
	.wr_clk             (wr_clk             ),
	.wr_en              (wr_en              ),
	.din                (din                ),
	.full               (full               ),
	.wr_rst_busy        (wr_rst_busy        ),
	.rd_clk             (m_axis_aclk        ),
	.rd_en              (rd_en              ),
	.dout               (dout               ),
	.empty              (empty              ),
	.rd_rst_busy        (                   ),
	.sleep              (1'b0               ),
	.injectsbiterr      (1'b0               ),
	.injectdbiterr      (1'b0               )
);


	endmodule
