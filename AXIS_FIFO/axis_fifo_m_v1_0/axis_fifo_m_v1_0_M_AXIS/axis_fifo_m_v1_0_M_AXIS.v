
`timescale 1 ns / 1 ps

module axis_fifo_m_v1_0_M_AXIS # (
	// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
	parameter integer 	C_M_AXIS_TDATA_WIDTH = 32		,
	// Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
	parameter integer 	C_M_START_COUNT	= 32			,
	// length of data which everytime sent from FIFO to slave
	parameter integer	LENGTH_OF_FRAME = 1024			
)
(	
	// | ********************************FIFO interface******************************** |
    input     	[C_M_AXIS_TDATA_WIDTH-1 : 0]		dout            	,
	input											prog_empty			,
	// read enable
    output                  						tx_en           	,
	// | ********************************AXIS interface******************************** |
	input   										M_AXIS_ACLK			,
	input   										M_AXIS_ARESETN		,
	// Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
	output   										M_AXIS_TVALID		,
	// TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
	output  	[C_M_AXIS_TDATA_WIDTH-1 : 0] 		M_AXIS_TDATA		,
	// TKEEP is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
	output  	[(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] 	M_AXIS_TKEEP		,
	// TLAST indicates the boundary of a packet.
	output   										M_AXIS_TLAST		,
	// TREADY indicates that the slave can accept a transfer in the current cycle.
	input   										M_AXIS_TREADY
);


// function called clogb2 that returns an integer which has the                      
// value of the ceiling of the log base 2.                                           
function integer clogb2 (input integer bit_depth);                                   
begin                                                                              
    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                                      
        bit_depth = bit_depth >> 1;                                                    
end                                                                                
endfunction

// WAIT_COUNT_BITS is the width of the wait counter.                                 
localparam integer 	WAIT_COUNT_BITS = clogb2(C_M_START_COUNT - 1)		;                      
localparam integer	FRAME_LENGTH_BITS = clogb2(LENGTH_OF_FRAME - 1)		;

// Define the states of state machine
// The control state machine oversees the writing of input streaming data to the FIFO,
// and outputs the streaming data from the FIFO                                      
parameter 	[1:0] 	IDLE = 2'b00			,	// This is the initial/idle state               
                	INIT_COUNTER  = 2'b01	, 	// This state initializes the counter, once   
                                				// the counter reaches C_M_START_COUNT count,        
                                				// the state machine changes state to SEND_STREAM1     
                	SEND_STREAM0   = 2'b10	, 	// In this state the M_AXIS_TREADY is ready,
                                     			// and FIFO isn't empty change state to SEND_STREAM1
					SEND_STREAM1 = 2'b11	;	// in this state, it transfore 
												// LENGTH_OF_FRAME data to slave

// counter of length of data in one frame 
reg 		[FRAME_LENGTH_BITS : 0]			frame_length_cnt		;
// State variable                                                                    
reg 		[1:0] 							mst_exec_state			;
// AXI Stream internal signals
// wait counter. The master waits for the user defined number of clock cycles before initiating a transfer.
reg 		[WAIT_COUNT_BITS-1 : 0] 		count					;
// streaming data valid
wire  										axis_tvalid				;
// streaming data valid delayed by one clock cycle
reg  										axis_tvalid_delay		;
// Last of the streaming data 
wire  										axis_tlast				;
// Last of the streaming data delayed by one clock cycle
reg  										axis_tlast_delay		;
// The master has issued all the streaming data stored in FIFO
wire  										tx_done					;

// I/O Connections assignments
assign M_AXIS_TVALID = axis_tvalid_delay;
assign M_AXIS_TDATA	= dout;
assign M_AXIS_TLAST	= axis_tlast_delay;
assign M_AXIS_TKEEP	= {(C_M_AXIS_TDATA_WIDTH/8){1'b1}};

// Control state machine implementation
always @(posedge M_AXIS_ACLK)
begin
	// Synchronous reset (active low)
	if (!M_AXIS_ARESETN)
	begin                                                                 
		mst_exec_state <= IDLE;                                             
		count <= 0; 
		frame_length_cnt <= 'd0;
	end                                                                   
	else                                                                    
	case (mst_exec_state)
	IDLE:
		begin                                                           
			mst_exec_state  <= INIT_COUNTER;
			frame_length_cnt <= 'd0;
		end
	INIT_COUNTER:                                                       
        // The slave starts accepting tdata when                          
        // there tvalid is asserted to mark the                           
        // presence of valid streaming data                               
		if ( count == C_M_START_COUNT - 1 )                               
		begin                                                           
			mst_exec_state  <= SEND_STREAM0;                               
		end                                                             
		else                                                              
		begin                                                           
			count <= count + 1;                                           
			mst_exec_state  <= INIT_COUNTER;                              
		end                                                             
	SEND_STREAM0:
		if(M_AXIS_TREADY && ~prog_empty) begin
			mst_exec_state <= SEND_STREAM1;
		end
	SEND_STREAM1:                                                        
        // The example design streaming master functionality starts       
        // when the master drives output tdata from the FIFO and the slave
        // has finished storing the S_AXIS_TDATA                          
		if (tx_done)                                                      
		begin                                                           
			mst_exec_state <= IDLE;
			frame_length_cnt <= 'd0;
		end                                                             
		else                                                              
		begin
			if(M_AXIS_TREADY) begin
				frame_length_cnt <= frame_length_cnt + 1;
			end
		end
	endcase
end

//tvalid generation
//axis_tvalid is asserted when the control state machine's state is SEND_STREAM1
assign axis_tvalid = (mst_exec_state == SEND_STREAM1);

// AXI tlast generation                                                                                                                                   
assign axis_tlast = axis_tvalid_delay && (frame_length_cnt == LENGTH_OF_FRAME - 1);

// Delay the axis_tvalid and axis_tlast signal by one clock cycle
// to match the latency of M_AXIS_TDATA
always @(posedge M_AXIS_ACLK)
begin
	if (!M_AXIS_ARESETN)                                                                         
	begin
		axis_tvalid_delay <= 1'b0;                                                               
		axis_tlast_delay <= 1'b0;
	end                                                                                        
	else                                                                                         
	begin                                                                                      
		axis_tvalid_delay <= axis_tvalid;
		axis_tlast_delay <= axis_tlast;
	end
end
assign tx_done = axis_tlast;

//FIFO read enable generation
assign tx_en = M_AXIS_TREADY && M_AXIS_TVALID;


endmodule
