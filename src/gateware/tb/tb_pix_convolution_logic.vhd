-- Test Bench checking the behavioural model of the whole 54x54 image shifting.
-- Version of the accelerator : based on the paper Optimizing Loop Operation and Dataflow in FPGA
-- Acceleration of Deep Convolutional Neural Networks, Arizona State University
-- @author Patryk Oleniuk, patryk.leniuk@epfl.ch, LAP, EPFL 2017

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cnn_conv.all;

entity tb_pix_convolution_logic is
end entity tb_pix_convolution_logic;

architecture RTL of tb_pix_convolution_logic is
	component pix_convolution_logic is
		port(
			clk          : in  std_logic;
			rst          : in  std_logic;
			shift_enable : in  std_logic;
			-- pixel values for calculation
			pix_calc     : out pix_6x6_buf;
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
	end component;

	signal clk : std_logic;
	signal rst : std_logic;

	-- pixel values for calculation
	signal pix_calc : pix_6x6_buf;

	-- BRAM config
	signal use_BRAM1 : std_logic;
	signal use_BRAM2 : std_logic;
	signal use_BRAM3 : std_logic;
	signal use_BRAM4 : std_logic;
	signal use_BRAM5 : std_logic;
	-- use_BRAM6 : in std_logic; -- this is constantly up

	signal bram_values1 : pix_6_buf;
	signal bram_values2 : pix_6_buf;
	signal bram_values3 : pix_6_buf;
	signal bram_values4 : pix_6_buf;
	signal bram_values5 : pix_6_buf;
	signal bram_values6 : pix_6_buf;

	signal bram_offset1 : std_logic_vector(1 downto 0);
	signal bram_offset2 : std_logic_vector(1 downto 0);
	signal bram_offset3 : std_logic_vector(1 downto 0);
	signal bram_offset4 : std_logic_vector(1 downto 0);
	signal bram_offset5 : std_logic_vector(1 downto 0);
	signal bram_offset6 : std_logic_vector(1 downto 0);

	signal kernel_pixnr : natural range 0 to 200 := 0;
	signal kernel_row   : natural                := 0; -- used to count the blocks
	signal value_ctr2   : unsigned(11 downto 0)  := (others => '0');

	-- Clock period definitions
	constant clk_period : time := 10 ns;

begin

	uut : pix_convolution_logic
		PORT MAP(
			shift_enable => '1',
			clk          => clk,
			rst          => rst,
			use_BRAM1    => use_BRAM1,
			use_BRAM2    => use_BRAM2,
			use_BRAM3    => use_BRAM3,
			use_BRAM4    => use_BRAM4,
			use_BRAM5    => use_BRAM5,
			bram_values1 => bram_values1,
			bram_values2 => bram_values2,
			bram_values3 => bram_values3,
			bram_values4 => bram_values4,
			bram_values5 => bram_values5,
			bram_values6 => bram_values6,
			pix_calc    => pix_calc,
		
			bram_offset1 => bram_offset1,
			bram_offset2 => bram_offset2,
			bram_offset3 => bram_offset3,
			bram_offset4 => bram_offset4,
			bram_offset5 => bram_offset5,
			bram_offset6 => bram_offset6
		);

	clk_process : process
	begin
		if (rst = '0') then
			kernel_pixnr <= kernel_pixnr + 1;
			if ((kernel_pixnr + 1) mod 8 = 0) then
				kernel_row <= kernel_row + 1;
			end if;

		end if;

		if (kernel_pixnr > 100) then
			wait;
		end if;

		clk        <= '1';
		wait for clk_period / 2;        -- for 0.5 ns signal is '0'.
		clk        <= '0';
		wait for clk_period / 2;        -- for next 0.5 ns signal is '1'.
		value_ctr2 <= value_ctr2 + 1;

	end process;

	rst <= '1' when value_ctr2 < 3 or kernel_pixnr > 63 else '0';

	-- use BRAM1-5 only at the beggining 6 cycles
	use_BRAM1 <= '1' when kernel_pixnr <= 7 else '0';
	use_BRAM2 <= '1' when kernel_pixnr <= 7 else '0';
	use_BRAM3 <= '1' when kernel_pixnr <= 7 else '0';
	use_BRAM4 <= '1' when kernel_pixnr <= 7 else '0';
	use_BRAM5 <= '1' when kernel_pixnr <= 7 else '0';
	-- use BRAM6 always ON interally

	-- here there is a BRAM values simulation for the first image part. 
	BRAM1 : for i in 0 to 5 generate
		bram_values1(i) <= std_logic_vector(unsigned((unsigned(bram_offset1)*to_unsigned(6, 3))) + to_unsigned(i, BIT_ACCURACY) + 1);
	end generate;

	BRAM2 : for i in 0 to 5 generate
		bram_values2(i) <= std_logic_vector(unsigned((unsigned(bram_offset1)*to_unsigned(6, 3))) + to_unsigned(i, BIT_ACCURACY) + 55 + 1);
	end generate;

	BRAM3 : for i in 0 to 5 generate
		bram_values3(i) <= std_logic_vector(unsigned((unsigned(bram_offset1)*to_unsigned(6, 3))) + to_unsigned(i, BIT_ACCURACY) + to_unsigned(55, 8)*to_unsigned(2, 3) + 1);
	end generate;

	BRAM4 : for i in 0 to 5 generate
		bram_values4(i) <= std_logic_vector(unsigned((unsigned(bram_offset1)*to_unsigned(6, 3))) + to_unsigned(i, BIT_ACCURACY) + to_unsigned(55, 8)*to_unsigned(3, 3) + 1);
	end generate;

	BRAM5 : for i in 0 to 5 generate
		bram_values5(i) <= std_logic_vector(unsigned((unsigned(bram_offset1)*to_unsigned(6, 3))) + to_unsigned(i, BIT_ACCURACY) + to_unsigned(55, 8)*to_unsigned(4, 3) + 1);
	end generate;

	BRAM6 : for i in 0 to 5 generate
		bram_values6(i) <= std_logic_vector(unsigned((unsigned(bram_offset1)*to_unsigned(6, 3))) + to_unsigned(i, BIT_ACCURACY) + to_unsigned(55, 8)*to_unsigned(5, 3) + to_unsigned(55, 6)*to_unsigned(kernel_row, 6) + 1);
	end generate;

end architecture RTL;
