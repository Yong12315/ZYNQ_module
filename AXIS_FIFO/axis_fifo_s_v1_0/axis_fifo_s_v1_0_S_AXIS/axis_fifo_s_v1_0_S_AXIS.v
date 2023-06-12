
`timescale 1 ns / 1 ps

module axis_fifo_s_v1_0_S_AXIS # (
	// AXI4Stream sink: Data Width
	parameter integer 	C_S_AXIS_TDATA_WIDTH = 32	,
	// FIFO
	parameter integer 	READ_DATA_WIDTH = 32		,
	parameter integer	FIFO_WRITE_DEPTH = 4096		
)
(
	// FIFO interface
	input											rst_n				,
	input											wr_clk				,
	input											rd_clk				,
	input											rd_en				,
	output		[READ_DATA_WIDTH - 1 : 0]			dout				,
	output											empty				,
	// AXI4Stream sink: Clock
	input   										S_AXIS_ACLK			,
	// AXI4Stream sink: Reset
	input   										S_AXIS_ARESETN		,
	// Ready to accept data in
	output   										S_AXIS_TREADY		,
	// Data in
	input  		[C_S_AXIS_TDATA_WIDTH-1 : 0] 		S_AXIS_TDATA		,
	// Byte qualifier
	input  		[(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] 	S_AXIS_TKEEP		,
	// Indicates boundary of last packet
	input   										S_AXIS_TLAST		,
	// Data is in valid
	input   										S_AXIS_TVALID
);


reg 				rst_n0				;
reg					rst_n1				;

wire				almost_full			;


// function called clogb2 that returns an integer which has the 
// value of the ceiling of the log base 2.
function integer clogb2 (input integer bit_depth);
begin
	for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
	bit_depth = bit_depth >> 1;
end
endfunction

// Define the states of state machine
// The control state machine oversees the writing of input streaming data to the FIFO,
// and outputs the streaming data from the FIFO
parameter [1:0] IDLE = 1'b0,        // This is the initial/idle state 

                WRITE_FIFO  = 1'b1; // In this state FIFO is written with the
                                    // input stream data S_AXIS_TDATA

wire  		axis_tready			;
// State variable
reg 		mst_exec_state		;  
// FIFO implementation signals
genvar 		byte_index			;     
// FIFO write enable
wire 		fifo_wren			;
// FIFO full flag
reg 		fifo_full_flag		;
// sink has accepted all the streaming data and stored in FIFO
wire 		writes_done			;
// I/O Connections assignments

assign S_AXIS_TREADY = axis_tready;
// Control state machine implementation
always @(posedge S_AXIS_ACLK) 
begin
	// Synchronous reset (active low)
	if (!S_AXIS_ARESETN) 
	begin
		mst_exec_state <= IDLE;
	end  
else
	case (mst_exec_state)
		IDLE: 
        // The sink starts accepting tdata when 
        // there tvalid is asserted to mark the
        // presence of valid streaming data 
			if (S_AXIS_TVALID)
			begin
				mst_exec_state <= WRITE_FIFO;
			end
			else
			begin
				mst_exec_state <= IDLE;
			end
		WRITE_FIFO: 
        // When the sink has accepted all the streaming input data,
        // the interface swiches functionality to a streaming master
			if (writes_done)
			begin
				mst_exec_state <= IDLE;
			end
			else
			begin
            // The sink accepts and stores tdata 
            // into FIFO
				mst_exec_state <= WRITE_FIFO;
			end
	endcase
end

// while state is in WRITE_FIFO and FIFO is'nt full, slave is ready to receive data
assign axis_tready = (mst_exec_state == WRITE_FIFO) && ~almost_full;

// last data means WRITE_FIFO is done
assign writes_done = S_AXIS_TLAST;

// fifo_wren is enabled while master is valid and slave is ready 
assign fifo_wren = S_AXIS_TVALID && S_AXIS_TREADY;

// delay rst_n signal by two clock cycle, make it synchronize with wr_clk
always @(posedge wr_clk) begin
	rst_n0 <= rst_n;
	rst_n1 <= rst_n0;
end

// FIFO Implementation
xpm_fifo_async # (
    .CDC_SYNC_STAGES            (2                      ),      // positive integer
    .DOUT_RESET_VALUE           ("0"           			),      // String
    .FIFO_MEMORY_TYPE           ("block"                ),      // string; "auto", "block", or "distributed";
    .FIFO_READ_LATENCY          (1                      ),      // positive integer;
    .FIFO_WRITE_DEPTH           (FIFO_WRITE_DEPTH       ),      // Range: 16 - 4194304
    .FULL_RESET_VALUE           (0                      ),      // positive integer; 0 or 1
    .PROG_EMPTY_THRESH          (10                     ),      // positive integer
    .PROG_FULL_THRESH           (20                     ),      // positive integer
    .READ_DATA_WIDTH            (READ_DATA_WIDTH        ),      // positive integer
    .WRITE_DATA_WIDTH           (C_S_AXIS_TDATA_WIDTH   ),      // positive integer
    .READ_MODE                  ("std"                 	),      // string; "std" or "fwft";
    .RELATED_CLOCKS             (0                      ),      // positive integer; 0 or 1
    .USE_ADV_FEATURES           ("0A0A"                 ),      // string; "0000" to "1F1F"; 
    .WAKEUP_TIME                (0                      )       // positive integer; 0 or 2;
) xpm_fifo_W_inst (
	.almost_full        (almost_full        ),
	.prog_full          (                   ),
	.prog_empty         (                   ),
	.rst                (~rst_n         	),
	.wr_clk             (wr_clk             ),
	.wr_en              (fifo_wren          ),
	.din                (S_AXIS_TDATA       ),
	.wr_rst_busy        (                   ),
	.rd_clk             (rd_clk             ),
	.rd_en              (rd_en              ),
	.dout               (dout               ),
	.empty              (empty              ),
	.rd_rst_busy        (                   ),
	.sleep              (1'b0               ),
	.injectsbiterr      (1'b0               ),
	.injectdbiterr      (1'b0               )
);


	endmodule
