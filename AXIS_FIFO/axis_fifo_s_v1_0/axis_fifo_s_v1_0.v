`timescale 1 ns / 1 ps

module axis_fifo_s_v1_0 # (
	// Parameters of Axi Slave Bus Interface S_AXIS
	parameter integer 	C_S_AXIS_TDATA_WIDTH = 32	,
	// FIFO interface
	parameter integer	READ_DATA_WIDTH = 32		,
	parameter integer	FIFO_WRITE_DEPTH = 4096		
)
(
	// FIFO interface
    input                   						rst_n           	,
    input                   						rd_clk              ,
    input                   						rd_en               ,
    output    	[31:0]  							dout                ,
    output                  						empty               ,
	// Ports of Axi Slave Bus Interface S_AXIS
	input   										s_axis_aclk			,
	input   										s_axis_aresetn		,
	output   										s_axis_tready		,
	input		[C_S_AXIS_TDATA_WIDTH-1 : 0] 		s_axis_tdata		,
	input  		[(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] 	s_axis_tkeep		,
	input   										s_axis_tlast		,
	input   										s_axis_tvalid		
);


// Instantiation of Axi Bus Interface S_AXIS
axis_fifo_s_v1_0_S_AXIS # ( 
	.C_S_AXIS_TDATA_WIDTH	(C_S_AXIS_TDATA_WIDTH	),
	.READ_DATA_WIDTH 		(READ_DATA_WIDTH 		),
	.FIFO_WRITE_DEPTH		(FIFO_WRITE_DEPTH		)
) axis_fifo_s_v1_0_S_AXIS_inst (
	// FIFO interface
    .wr_clk             (s_axis_aclk        ),
    .rst_n          	(rst_n          	),
    .rd_clk             (rd_clk             ),
    .rd_en              (rd_en              ),
    .dout               (dout               ),
    .empty              (empty              ),
	// AXI stream interface
	.S_AXIS_ACLK		(s_axis_aclk		),
	.S_AXIS_ARESETN		(s_axis_aresetn		),
	.S_AXIS_TREADY		(s_axis_tready		),
	.S_AXIS_TDATA		(s_axis_tdata		),
	.S_AXIS_TKEEP		(s_axis_tkeep		),
	.S_AXIS_TLAST		(s_axis_tlast		),
	.S_AXIS_TVALID		(s_axis_tvalid		)
);


endmodule
