-- This block is a higher level with many accumulator blocks (
-- input : BRAM pixels from the image ( 1 pixel is read only 1 time)  
-- Version of the accelerator : based on the paper Optimizing Loop Operation and Dataflow in FPGA
-- Acceleration of Deep Convolutional Neural Networks, Arizona State University
-- @author Patryk Oleniuk, patryk.leniuk@epfl.ch, LAP, EPFL 2017

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cnn_conv.all;

entity pix_accumulators_block is
	generic(
		block_w           : integer := 6; -- 6x6 block
		layer_parallelization : integer := 22
	);
	port(
		clk        : in std_logic;
		rst        : in std_logic;
		-- input pixel, kernel pixel, serial input
		pix_calc   : in pix_6x6_buf;
		ker_in     : in std_logic_vector(KER_BRAM_DATA_WIDTH - 1 downto 0);
		-- control
		accumulate : in std_logic;      -- 1 to accumulate, 0 to pause
		zero       : in std_logic;      -- 1 to zero the register, 0 to keep accumulating

		-- ouput
		acc_val   : out pix_22x6x6_buf  -- 6pix per row, 6 rows, 22 layers
	);
end entity pix_accumulators_block;

architecture RTL of pix_accumulators_block is
	
	component pix_accumulator is
		port(
			clk        : in  std_logic;
			rst        : in  std_logic;
			-- input pixel, kernel pixel, serial input
			pix_block_in     : in  std_logic_vector(BIT_ACCURACY - 1 downto 0);
			kernels_in     : in  std_logic_vector(BIT_ACCURACY - 1 downto 0); -- 22 kernel values concatenated
			-- control
			accumulate : in  std_logic; -- 1 to accumulate, 0 to pause
			zero       : in  std_logic; -- 1 to zero the register, 0 to keep accumulating

			-- ouput
			acc_val    : out std_logic_vector(BIT_ACCURACY - 1 downto 0)
		);
	end component pix_accumulator;

begin

	-- generate 22*6x6 accumulators and connect them to the same signal
	GEN_KER : for k in 1 to layer_parallelization generate
	begin
		GEN_IN_ROW : for i in 1 to block_w generate
		begin
			GEN_IN_COL : for j in 1 to block_w generate
			begin
				acc : pix_accumulator
					port map(
						clk        => clk,
						rst        => rst,
						pix_block_in     => pix_calc(i-1)(j-1),
						kernels_in     => ker_in((k*BIT_ACCURACY) - 1 downto ((k - 1)*BIT_ACCURACY)),
						accumulate => accumulate,
						zero       => zero,
						acc_val    => acc_val(k-1)(i-1)(j-1)
					);
			end generate;
		end generate;
	end generate;

end architecture RTL;
