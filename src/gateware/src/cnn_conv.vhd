-- package to manage parameters for Convolutionla Neural Networks accelerator ( convolution )
-- Version of the accelerator : based on the paper Optimizing Loop Operation and Dataflow in FPGA
-- Acceleration of Deep Convolutional Neural Networks, Arizona State University
-- @author Patryk Oleniuk, patryk.leniuk@epfl.ch, LAP, EPFL 2017

library ieee;
use ieee.std_logic_1164.all;

-- the pixel shifting logic is based on 6x6 blocks calculated in paralllel for 22 kernels. 
package cnn_conv is
	-- bit constants
	constant FRAC_BIT_ACC        : integer := 8; --bits wide
	constant INT_BIT_ACC         : integer := 4; --bits wide
	constant BIT_ACCURACY        : integer := FRAC_BIT_ACC + INT_BIT_ACC; --bits wide
	constant IMAGE_SIZE          : integer := 48; --img sizeN - N pix by N pix
	constant KERNEL_SIZE         : integer := 8; --kernel sizeN - N pix by N pix
	constant BUF_SIZE            : integer := IMAGE_SIZE * KERNEL_SIZE; --kernel sizeN - N pix by N pix
	constant KER_BRAM_DATA_WIDTH : integer := 512; -- multiple of 32bit for easy writing (0 padding)
	constant KER_ADDR_WIDTH      : integer := 32;
	constant IMG_ADDR_WIDTH      : integer := 32;
	constant IMG_DATA_WIDTH      : integer := 128; -- multiple of 32 bit for easy writing (0 padding)
	constant NR_INTERPICS        : integer := 22;
	constant PIX_BLOCK_NR        : integer := 6;
	constant L1_IMG_WIDTH        : integer := 48; -- number of 6x6 pixel blocks for layer1 img size 
	constant L2_IMG_WIDTH        : integer := 48; -- number of 6x6 pixel blocks for layer1 img size 
	constant L3_IMG_WIDTH        : integer := 24; -- number of 6x6 pixel blocks for layer1 img size 
	constant L4_IMG_WIDTH        : integer := 24; -- number of 6x6 pixel blocks for layer1 img size 
	constant L5_IMG_WIDTH        : integer := 6; -- number of 6x6 pixel blocks for layer1 img size 
	constant L6_IMG_WIDTH        : integer := 6; -- number of 6x6 pixel blocks for layer1 img size 

	-- addresses of constant value in the BRAMs (depends on the agreed structure, is in Exel file).
	constant KER_B_CONST_OFFSET : integer := 7104; -- address in kernel BRAM where the BRAM constants start (after all kernels)
	constant IMG_SWAP_OFFSET    : integer := 1782; -- address in img BRAMs to swap images between read and write ops
	constant L1_KER_OFFSET      : integer := 0; -- address in kernel BRAM where the L1 kernel 1 pixels start
	constant L2_KER_OFFSET      : integer := 64; -- address in kernel BRAM where the L2 kernel 1 pixels start
	constant L3_KER_OFFSET      : integer := 1472; -- address in kernel BRAM where the L3 kernel  pixels start
	constant L4_KER_OFFSET      : integer := 2880; -- address in kernel BRAM where the L4 kernel 1 pixels start
	constant L5_KER_OFFSET      : integer := 4288; -- address in kernel BRAM where the L5 kernel 1 pixels start
	constant L6_KER_OFFSET      : integer := 5696; -- address in kernel BRAM where the L6 kernel 1 pixels start
	constant ZERO_ADDR          : integer := 0;

	-- types
	type pix_6_buf is array (0 to 5) of std_logic_vector(BIT_ACCURACY - 1 downto 0); -- used for pixel shifting logic
	type pix_7_buf is array (0 to 6) of std_logic_vector(BIT_ACCURACY - 1 downto 0); -- used for pixel shifting logic
	type pix_6x6_buf is array (0 to 5) of pix_6_buf; -- used for accumulator logic
	type pix_22x6x6_buf is array (0 to 21) of pix_6x6_buf; -- used for accumulator logic

end package cnn_conv;

package body cnn_conv is
end package body cnn_conv;
