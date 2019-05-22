-- Test Bench cheching the behavioural model of the pixel shifter. 
-- Version of the accelerator : based on the paper Optimizing Loop Operation and Dataflow in FPGA
-- Acceleration of Deep Convolutional Neural Networks, Arizona State University
-- @author Patryk Oleniuk, patryk.leniuk@epfl.ch, LAP, EPFL 2017

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cnn_conv.all;

entity tb_pix_shifter is
end entity tb_pix_shifter;

architecture RTL of tb_pix_shifter is
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
	end component;

	-- sequential logic
	signal clk : std_logic;
	signal rst : std_logic;
	-- input values
	signal nxt_pix     : std_logic_vector(BIT_ACCURACY - 1 downto 0);
	signal init_pixels : pix_6_buf;
	-- output pixels for the DSP
	signal pix_calc : pix_6_buf;
	-- output data for the next block
	signal init_saved_pixels : pix_6_buf;
	signal buf_saved_pixels  : pix_7_buf;
	-- for addressing logic
	signal cntr : std_logic_vector(2 downto 0); -- max =7 for max kernel

	signal value_ctr : unsigned(BIT_ACCURACY-1 downto 0) := (others => '0');

	signal shift_en : std_logic;

	-- Clock period definitions
	constant clk_period : time := 10 ns;

begin

	-- Instantiate the Unit Under Test (UUT)
	uut : pix_shifter
		PORT MAP(
			clk               => clk,
			rst               => rst,
			nxt_pix           => nxt_pix,
			init_pixels       => init_pixels,
			pix_calc          => pix_calc,
			init_saved_pixels => init_saved_pixels,
			buf_saved_pixels  => buf_saved_pixels,
			cntr              => cntr,
			shift_enable      => shift_en
		);

	-- Clock process definitions( clock with 50% duty cycle is generated here.
	clk_process : process
	begin
		if (value_ctr > 100) then
			wait;
		end if;
		clk       <= '1';
		wait for clk_period / 2;        -- for 0.5 ns signal is '0'.
		clk       <= '0';
		wait for clk_period / 2;        -- for next 0.5 ns signal is '1'.
		value_ctr <= value_ctr + 1;

	end process;

	shift_en <= '1';
	nxt_pix  <= std_logic_vector(value_ctr);

	GEN : for i in 1 to 6 generate
		init_pixels(i-1) <= std_logic_vector(to_unsigned(i, BIT_ACCURACY));
	end generate;

	manip_process : process
	begin
		rst <= '1';
		wait for 6.25*clk_period;
		rst <= '0';
		wait;
	end process;

end architecture RTL;
