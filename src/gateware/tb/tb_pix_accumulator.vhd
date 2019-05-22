-- Test Bench cheching the behavioural model of the pixel accumulator. 
-- Version of the accelerator : based on the paper Optimizing Loop Operation and Dataflow in FPGA
-- Acceleration of Deep Convolutional Neural Networks, Arizona State University
-- @author Patryk Oleniuk, patryk.leniuk@epfl.ch, LAP, EPFL 2017
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cnn_conv.all;

entity tb_pix_accumulator is
end entity tb_pix_accumulator;

architecture RTL of tb_pix_accumulator is

	component pix_accumulator is
		port(
			clk          : in  std_logic;
			rst          : in  std_logic;
			-- input pixel, kernel pixel, serial input
			pix_block_in : in  std_logic_vector(BIT_ACCURACY - 1 downto 0);
			kernels_in   : in  std_logic_vector(BIT_ACCURACY - 1 downto 0);
			-- control
			accumulate   : in  std_logic; -- 1 to accumulate, 0 to pause
			zero         : in  std_logic; -- 1 to zero the register, 0 to keep accumulating

			-- ouput
			acc_val      : out std_logic_vector(BIT_ACCURACY - 1 downto 0)
		);
	end component pix_accumulator;

	signal clk : std_logic;
	signal rst : std_logic;

	-- input pixel, kernel pixel, serial input
	signal pix_in : std_logic_vector(BIT_ACCURACY - 1 downto 0);
	signal ker_in : std_logic_vector(BIT_ACCURACY - 1 downto 0);
	-- control
	signal accumulate : std_logic;      -- 1 to accumulate, 0 to pause
	signal zero       : std_logic;      -- 1 to zero the register, 0 to keep accumulating

	-- ouput
	signal acc_val : std_logic_vector(BIT_ACCURACY - 1 downto 0);

	signal value_ctr : signed(BIT_ACCURACY-1 downto 0) := (others => '0');

	-- Clock period definitions
	constant clk_period : time := 10 ns;
begin
	uut : pix_accumulator
		PORT MAP(
			pix_block_in     => pix_in,
			kernels_in     => ker_in,
			accumulate => accumulate,
			zero       => zero,
			clk        => clk,
			rst        => rst,
			acc_val    => acc_val
		);

	-- Clock process definitions( clock with 50% duty cycle is generated here.
	clk_process : process
	begin
		if (value_ctr > 1500) then
			wait;
		end if;
		clk       <= '1';
		wait for clk_period / 2;        -- for 0.5 ns signal is '0'.
		clk       <= '0';
		wait for clk_period / 2;        -- for next 0.5 ns signal is '1'.
		value_ctr <= value_ctr + 1;

	end process;

	pix_in <= std_logic_vector(signed(value_ctr)) when (value_ctr > 50) else std_logic_vector(signed(-value_ctr));
	ker_in <= ("011100000000") when value_ctr<55 else "100000000000";         -- keeep kernel at constant(7.0 fixed point) all the time

	zero       <= '0';
	accumulate <= '1';

	rst_process : process
	begin
		rst <= '1';
		wait for 6.25*clk_period;
		rst <= '0';
		wait;
	end process;

end architecture RTL;
