`ifndef DEFINES
`define DEFINES


// uncomment the following line when synthesizing to board
//`define SYNTH
// comment the following when doing anything except the sint demo
//`define SINT_DEMO

`ifdef SYNTH
	`define DC 'h0
`else
	`define DC 'hx
`endif

`define FP_R2	 	 32'h3F35_04F3
`define FP_NR2 		 32'hBF35_04F3
`define FP_64		 32'h4280_0000
`define FP_32		 32'h4200_0000
`define FP_16		 32'h4180_0000
`define FP_8		 32'h4100_0000
`define FP_4		 32'h4080_0000
`define FP_2		 32'h4000_0000
`define FP_1		 32'h3F80_0000
`define FP_N1		 32'hBF80_0000
`define FP_0		 32'h0

// Defs for camera initialization
`ifdef SYNTH


	`define INIT_CAM_X 32'h3f90_0000 // 40800000
	`define INIT_CAM_Y 32'h3f90_0000 // 40400000
	`define INIT_CAM_Z 32'hbfa0_0000 // C1200000
`else
  /*
  `define INIT_CAM_X $shortrealtobits(0.25)
	`define INIT_CAM_Y $shortrealtobits(0)
	`define INIT_CAM_Z $shortrealtobits(1)
*/
		//`define BUNNY
	`ifdef BUNNY
	  `define INIT_CAM_X $shortrealtobits(0.25) // 0.25
	  `define INIT_CAM_Y $shortrealtobits(0) // 0.0
	  `define INIT_CAM_Z $shortrealtobits(1.0) // 1.0
	`else
	  `define INIT_CAM_X $shortrealtobits(1.125)
	  `define INIT_CAM_Y $shortrealtobits(1.125)
	  `define INIT_CAM_Z $shortrealtobits(-1.25)
	`endif

`endif


`ifndef SYNTH
	`define move_scale 32'h3F800000
`else
	`define move_scale 32'h32ABCC77 
`endif

// Number of caches and max read size for memory interface
//`define numcaches 3 // T3DO: change back to 4 later
`define numcaches 4 // TODO: change back to 4 later
`define maxTrans 64

// Number of primary rays for PRG

`ifndef SYNTH
	`define PW_REAL 0.25 // TODO: make this considerably smaller
	`define PW_FP 32'h3E80_0000
`else
	`define PW_REAL 1.0
	`define PW_FP `FP_1
`endif

`ifndef SYNTH
`define PW_0 $shortrealtobits(`PW_REAL*32)
`define PW_1 $shortrealtobits(`PW_REAL*16)
`define PW_2 $shortrealtobits(`PW_REAL*8)
`define PW_3 $shortrealtobits(`PW_REAL*4)
`define PW_4 $shortrealtobits(`PW_REAL*2)
`define PW_5 $shortrealtobits(`PW_REAL)
`else
`define PW_0 `FP_32
`define PW_1 `FP_16
`define PW_2 `FP_8
`define PW_3 `FP_4
`define PW_4 `FP_2
`define PW_5 `FP_1
`endif

// Epsilon = 10^-20 for now?
`define EPSILON 32'h1E3C_E508


////////////////////// Defines for Caches //////////////////////
// parameters for icache
`define I_ADDR_W              16
`define I_BO_W                0
`define I_TAG_W               6
`define I_INDEX_W             10
`define I_LINE_W              288
`define I_NUM_BLK             1
`define I_BLK_W               `I_LINE_W/`I_NUM_BLK
`define I_BASE_ADDR           25'h0_00_00_00
`define I_NUM_LINES           1024

// parameters for tcaches
`define T_ADDR_W              16
`define T_BO_W                3
`define T_TAG_W               4
`define T_INDEX_W             9
`define T_LINE_W              384
`define T_NUM_BLK             8
`define T_BLK_W               `T_LINE_W/`T_NUM_BLK
`define T_BASE_ADDR           25'h0_80_00_00
`define T_NUM_LINES           512

// parameters for lcache
`define L_ADDR_W              16
`define L_BO_W                4
`define L_TAG_W               2
`define L_INDEX_W             10
`define L_LINE_W              256
`define L_NUM_BLK             16
`define L_BLK_W               `L_LINE_W/`L_NUM_BLK
`define L_BASE_ADDR           25'h1_00_00_00
`define L_NUM_LINES           1024

// parameters for icache
`define S_ADDR_W              16
`define S_BO_W                1
`define S_TAG_W               5
`define S_INDEX_W             10
`define S_LINE_W              320
`define S_NUM_BLK             2
`define S_BLK_W               `S_LINE_W/`S_NUM_BLK
`define S_BASE_ADDR           25'h1_80_00_00
`define S_NUM_LINES           1024
////////////////////// End of Defines for Caches //////////////////////

////////////////////// Defines for XMODEM //////////////////////
`define CLK_FREQ        50000000
//`define BAUD_RATE       115200
`ifdef SYNTH
    `define XM_CYC_PER_BIT     9'd434 // TODO: define in terms of CLK_FREQ and BAUD
`else
    `define XM_CYC_PER_BIT     9'd20 // TODO: define in terms of CLK_FREQ and BAUD
`endif

`define XM_NUM_SAMPLES     4'd10

`define XM_MAX_RETRY       4'd10
`define XM_NUM_CYC_TIMEOUT (10*`CLK_FREQ)

`define SOH 8'h01
`define EOT 8'h04

`define ACK 8'h06
`define NAK 8'h15
////////////////////// End of Defines for XMODEM //////////////////////


////////////////////// Defines for VGA //////////////////////

`define MAX_ROWS 10'd480
`define MAX_COLS 10'd640

//Defines number of pixels at each resolution
`define RES_0 (20*15)
`define ROWS_RES_0 15
`define COLS_RES_0 20

`define RES_1 (20*15*4)
`define ROWS_RES_1 30
`define COLS_RES_1 40

`define RES_2 (20*15*16)
`define ROWS_RES_2 60
`define COLS_RES_2 80

`define RES_3 (20*15*64)
`define ROWS_RES_3 120
`define COLS_RES_3 160

`define RES_4 (20*15*256)
`define ROWS_RES_4 240
`define COLS_RES_4 320

`define RES_5 (20*15*1024)
`define ROWS_RES_5 480
`define COLS_RES_5 640


`define RES_SCALE2


`ifdef RES_SCALE0
	`define NUM_ROWS `ROWS_RES_0
	`define NUM_COLS `COLS_RES_0
	`define RES_SCALE 0
`elsif RES_SCALE1
	`define NUM_ROWS `ROWS_RES_1
	`define NUM_COLS `COLS_RES_1
	`define RES_SCALE 1
`elsif RES_SCALE2
	`define NUM_ROWS `ROWS_RES_2
	`define NUM_COLS `COLS_RES_2
	`define RES_SCALE 2
`elsif RES_SCALE3
	`define NUM_ROWS `ROWS_RES_3
	`define NUM_COLS `COLS_RES_3
	`define RES_SCALE 3
`elsif RES_SCALE4
	`define NUM_ROWS `ROWS_RES_4
	`define NUM_COLS `COLS_RES_4
	`define RES_SCALE 4
`elsif RES_SCALE5
	`define NUM_ROWS `ROWS_RES_5
	`define NUM_COLS `COLS_RES_5
	`define RES_SCALE 5
`endif


`define VGA_NUM_ROWS        10'd`NUM_ROWS
`define VGA_NUM_COLS        10'd`NUM_COLS


// following in terms of 25 MHz clock
`define VGA_HS_TDISP        `VGA_NUM_COLS
`define VGA_HS_TPW          10'd96
`define VGA_HS_TFP          10'd16
`define VGA_HS_TBP          10'd48
`define VGA_HS_OFFSET      (`VGA_HS_TPW + `VGA_HS_TBP)
`define VGA_HS_TS           (`VGA_HS_OFFSET+`VGA_HS_TDISP+`VGA_HS_TFP)

// following in terms of lines
`define VGA_VS_TDISP        `VGA_NUM_ROWS
`define VGA_VS_TPW          10'd2
`define VGA_VS_TFP          10'd10
`define VGA_VS_TBP          10'd29
`define VGA_VS_OFFSET      (`VGA_VS_TPW + `VGA_VS_TBP)
`define VGA_VS_TS           (`VGA_VS_OFFSET+`VGA_VS_TDISP+`VGA_VS_TFP)

`define VGA_CYC25_PER_SCREEN  1*(`VGA_VS_TS * `VGA_HS_TS) // 1* to cast as 32 bit integer
////////////////////// End of Defines for VGA //////////////////////

////////////////////// Defines for PRG //////////////////////
`define num_rays (`NUM_ROWS*`NUM_COLS*1) // 307200

// Values in the range [0,5], determines resolution.
// Default value is max resolution


// Defines the dimensions of a sub-box
`define PRG_BOX_ROWS 5'd15
`define PRG_BOX_COLS 5'd20


`define X_MULT (`MAX_COLS/32)
`define Y_MULT (`MAX_ROWS/32)



// defines for -w/2 and -h/2 //half width = -4, half height = -3
`ifndef SYNTH
	`define half_screen_width  $shortrealtobits(`PW_REAL*(-(`MAX_COLS/2.0)))
	`define half_screen_height $shortrealtobits(`PW_REAL*(-(`MAX_ROWS/2.0)))
	// D = 6 for now
	`define SCREEN_DIST $shortrealtobits(`PW_REAL*(`MAX_ROWS/2.0)) // 45 degrees viewing angle
`else
	`define half_screen_width  32'hC3A0_0000 // -320
	`define half_screen_height 32'hC370_0000 // -240
	// D = 4 for now
	`define SCREEN_DIST 32'h4370_0000 // 240
`endif

////////////////////// End of Defines for PRG //////////////////////

////////////////////// Defines for shader /////////////////////////
`define MISS_COLOR 24'hff_ff_ff
`define TRI_0_COLOR 24'haa_aa_aa
`define TRI_2_COLOR 24'h08_cc_08
`define TRI_1_COLOR 24'hf8_f8_02
`define TRI_3_COLOR 24'hff_01_01

`endif
