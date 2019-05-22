-- The basic pixels shifting logic for 54x54 image with 6x6 window. The output: every clk new pixels to accumulate for the DSPs
-- input : BRAM pixels from the image ( 1 pixel is read only 1 time)  
-- Version of the accelerator : based on the paper Optimizing Loop Operation and Dataflow in FPGA
-- Acceleration of Deep Convolutional Neural Networks, Arizona State University
-- @author Patryk Oleniuk, patryk.leniuk@epfl.ch, LAP, EPFL 2017

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cnn_conv.all;

entity pix_convolution_logic is
	port(
		clk          : in  std_logic;
		rst          : in  std_logic;
		shift_enable : in  std_logic;
		-- pixel values for calculation
		pix_calc    : out pix_6x6_buf;

		-- BRAM config
		use_BRAM1    : in  std_logic;
		use_BRAM2    : in  std_logic;
		use_BRAM3    : in  std_logic;
		use_BRAM4    : in  std_logic;
		use_BRAM5    : in  std_logic;
		-- use_BRAM6 : in std_logic; -- this is constantly up

		-- bram values 
		bram_values1 : in  pix_6_buf;
		bram_values2 : in  pix_6_buf;
		bram_values3 : in  pix_6_buf;
		bram_values4 : in  pix_6_buf;
		bram_values5 : in  pix_6_buf;
		bram_values6 : in  pix_6_buf;
		-- bram address offsets
		bram_offset1 : out std_logic_vector(1 downto 0);
		bram_offset2 : out std_logic_vector(1 downto 0);
		bram_offset3 : out std_logic_vector(1 downto 0);
		bram_offset4 : out std_logic_vector(1 downto 0);
		bram_offset5 : out std_logic_vector(1 downto 0);
		bram_offset6 : out std_logic_vector(1 downto 0)
	);
end entity pix_convolution_logic;

architecture RTL of pix_convolution_logic is
	component interpix_interface is
		port(
			-- the most iomportant flag different for each state and shifter
			use_BRAM         : in  std_logic;
			-- counter value from the following pix shifter 
			counter_val      : in  std_logic_vector(2 downto 0); -- up to 7

			-- register values from previous pix shifter 
			saved_reg        : in  pix_7_buf;
			init_saved       : in  pix_6_buf;
			-- output value from the followint pix shifter
			next_pixel       : out std_logic_vector(BIT_ACCURACY - 1 downto 0);
			init_pix         : out pix_6_buf;
			-- BRAM address (only 0 or 1 or 2) you need to add base!
			bram_offset_addr : out std_logic_vector(1 downto 0);
			bram_values      : in  pix_6_buf
		);
	end component interpix_interface;

	component pix_shifter is
		port(
			-- sequential logic
			clk               : in  std_logic;
			rst               : in  std_logic;
			shift_enable      : in  std_logic;
			-- input values
			nxt_pix           : in  std_logic_vector(BIT_ACCURACY - 1 downto 0);
			init_pixels       : in  pix_6_buf;
			-- output pixels for the DSP
			pix_calc          : out pix_6_buf;
			-- output data for the next block
			init_saved_pixels : out pix_6_buf;
			buf_saved_pixels  : out pix_7_buf;
			-- for addressing logic
			cntr              : out std_logic_vector(2 downto 0) -- max =7 for max kernel
		);
	end component pix_shifter;

	signal nxt_pix1 : std_logic_vector(BIT_ACCURACY - 1 downto 0);
	signal nxt_pix2 : std_logic_vector(BIT_ACCURACY - 1 downto 0);
	signal nxt_pix3 : std_logic_vector(BIT_ACCURACY - 1 downto 0);
	signal nxt_pix4 : std_logic_vector(BIT_ACCURACY - 1 downto 0);
	signal nxt_pix5 : std_logic_vector(BIT_ACCURACY - 1 downto 0);
	signal nxt_pix6 : std_logic_vector(BIT_ACCURACY - 1 downto 0);

	signal init_pixels1 : pix_6_buf;
	signal init_pixels2 : pix_6_buf;
	signal init_pixels3 : pix_6_buf;
	signal init_pixels4 : pix_6_buf;
	signal init_pixels5 : pix_6_buf;
	signal init_pixels6 : pix_6_buf;

	-- signal init_saved_pixels1 : pix_6_buf; --goes nowhere
	signal init_saved_pixels2 : pix_6_buf;
	signal init_saved_pixels3 : pix_6_buf;
	signal init_saved_pixels4 : pix_6_buf;
	signal init_saved_pixels5 : pix_6_buf;
	signal init_saved_pixels6 : pix_6_buf;

	-- signal buf_saved_pixels1 : pix_7_buf; --goes nowhere
	signal buf_saved_pixels2 : pix_7_buf;
	signal buf_saved_pixels3 : pix_7_buf;
	signal buf_saved_pixels4 : pix_7_buf;
	signal buf_saved_pixels5 : pix_7_buf;
	signal buf_saved_pixels6 : pix_7_buf;

	signal cntr1 : std_logic_vector(2 downto 0);
	signal cntr2 : std_logic_vector(2 downto 0);
	signal cntr3 : std_logic_vector(2 downto 0);
	signal cntr4 : std_logic_vector(2 downto 0);
	signal cntr5 : std_logic_vector(2 downto 0);
	signal cntr6 : std_logic_vector(2 downto 0);

	constant buf_saved_pixels7  : pix_7_buf := (others => (others => '0'));
	constant init_saved_pixels7 : pix_6_buf := (others => (others => '0'));

begin

	-- from the left
	pix_shifter1 : pix_shifter
		PORT MAP(
			clk          => clk,
			rst          => rst,
			shift_enable => shift_enable,
			nxt_pix      => nxt_pix1,
			init_pixels  => init_pixels1,
			-- init_saved_pixels => init_saved_pixels1, -- goes nowhere
			-- buf_saved_pixels  => buf_saved_pixels1, -- goes nowehere
			cntr         => cntr1,
			pix_calc     => pix_calc(0)
		);

	pix_shifter2 : pix_shifter
		PORT MAP(
			clk               => clk,
			rst               => rst,
			shift_enable      => shift_enable,
			nxt_pix           => nxt_pix2,
			init_pixels       => init_pixels2,
			init_saved_pixels => init_saved_pixels2,
			buf_saved_pixels  => buf_saved_pixels2,
			cntr              => cntr2,
			pix_calc          => pix_calc(1)
		);

	pix_shifter3 : pix_shifter
		PORT MAP(
			clk               => clk,
			rst               => rst,
			shift_enable      => shift_enable,
			nxt_pix           => nxt_pix3,
			init_pixels       => init_pixels3,
			init_saved_pixels => init_saved_pixels3,
			buf_saved_pixels  => buf_saved_pixels3,
			cntr              => cntr3,
			pix_calc          => pix_calc(2)
		);

	pix_shifter4 : pix_shifter
		PORT MAP(
			clk               => clk,
			rst               => rst,
			shift_enable      => shift_enable,
			nxt_pix           => nxt_pix4,
			init_pixels       => init_pixels4,
			init_saved_pixels => init_saved_pixels4,
			buf_saved_pixels  => buf_saved_pixels4,
			cntr              => cntr4,
			pix_calc          => pix_calc(3)
		);

	pix_shifter5 : pix_shifter
		PORT MAP(
			clk               => clk,
			rst               => rst,
			shift_enable      => shift_enable,
			nxt_pix           => nxt_pix5,
			init_pixels       => init_pixels5,
			init_saved_pixels => init_saved_pixels5,
			buf_saved_pixels  => buf_saved_pixels5,
			cntr              => cntr5,
			pix_calc          => pix_calc(4)
		);

	pix_shifter6 : pix_shifter
		PORT MAP(
			clk               => clk,
			rst               => rst,
			shift_enable      => shift_enable,
			nxt_pix           => nxt_pix6,
			init_pixels       => init_pixels6,
			init_saved_pixels => init_saved_pixels6,
			buf_saved_pixels  => buf_saved_pixels6,
			cntr              => cntr6,
			pix_calc          => pix_calc(5)
		);

	-- from the left
	inter1 : interpix_interface
		port map(
			use_BRAM         => use_BRAM1,
			counter_val      => cntr1,
			saved_reg        => buf_saved_pixels2,
			init_saved       => init_saved_pixels2,
			bram_values      => bram_values1,
			next_pixel       => nxt_pix1,
			init_pix         => init_pixels1,
			bram_offset_addr => bram_offset1
		);

	inter2 : interpix_interface
		port map(
			use_BRAM         => use_BRAM2,
			counter_val      => cntr2,
			saved_reg        => buf_saved_pixels3,
			init_saved       => init_saved_pixels3,
			bram_values      => bram_values2,
			next_pixel       => nxt_pix2,
			init_pix         => init_pixels2,
			bram_offset_addr => bram_offset2
		);

	inter3 : interpix_interface
		port map(
			use_BRAM         => use_BRAM3,
			counter_val      => cntr3,
			saved_reg        => buf_saved_pixels4,
			init_saved       => init_saved_pixels4,
			bram_values      => bram_values3,
			next_pixel       => nxt_pix3,
			init_pix         => init_pixels3,
			bram_offset_addr => bram_offset3
		);

	inter4 : interpix_interface
		port map(
			use_BRAM         => use_BRAM4,
			counter_val      => cntr4,
			saved_reg        => buf_saved_pixels5,
			init_saved       => init_saved_pixels5,
			bram_values      => bram_values4,
			next_pixel       => nxt_pix4,
			init_pix         => init_pixels4,
			bram_offset_addr => bram_offset4
		);

	inter5 : interpix_interface
		port map(
			use_BRAM         => use_BRAM5,
			counter_val      => cntr5,
			saved_reg        => buf_saved_pixels6,
			init_saved       => init_saved_pixels6,
			bram_values      => bram_values5,
			next_pixel       => nxt_pix5,
			init_pix         => init_pixels5,
			bram_offset_addr => bram_offset5
		);

	inter6 : interpix_interface
		port map(
			use_BRAM         => '1',    -- constantly up
			counter_val      => cntr6,
			saved_reg        => buf_saved_pixels7, -- nothing
			init_saved       => init_saved_pixels7, -- nothing
			bram_values      => bram_values6,
			next_pixel       => nxt_pix6,
			init_pix         => init_pixels6,
			bram_offset_addr => bram_offset6
		);

end architecture RTL;
