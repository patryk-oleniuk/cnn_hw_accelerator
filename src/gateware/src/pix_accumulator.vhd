-- Pixel accumulator/multiplicator (MACC) (signed fixed point)
-- Version of the accelerator : based on the paper Optimizing Loop Operation and Dataflow in FPGA
-- Acceleration of Deep Convolutional Neural Networks, Arizona State University
-- @author Patryk Oleniuk, patryk.leniuk@epfl.ch, LAP, EPFL 2017
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cnn_conv.all;

entity pix_accumulator is
	port(
		clk        : in  std_logic;
		rst        : in  std_logic;
		-- input pixel, kernel pixel, serial input
		pix_block_in     : in  std_logic_vector(BIT_ACCURACY - 1 downto 0);
		kernels_in     : in  std_logic_vector(BIT_ACCURACY - 1 downto 0);
		-- control
		accumulate : in  std_logic;     -- 1 to accumulate, 0 to pause
		zero       : in  std_logic;     -- 1 to zero the register, 0 to keep accumulating

		-- ouput
		acc_val    : out std_logic_vector(BIT_ACCURACY - 1 downto 0)
	);
end entity pix_accumulator;

architecture RTL of pix_accumulator is
	signal acc_val_internal : signed((2*BIT_ACCURACY) - 1 downto 0);
	signal mult_product     : signed((2*BIT_ACCURACY) -1 downto 0);
	--signal added_value      : signed(BIT_ACCURACY - 1 downto 0);
	signal saturation_pos   : std_logic;
	signal saturation_neg   : std_logic;
	signal saturation       : std_logic_vector( 1 downto 0);
	constant max_val        : signed((2*BIT_ACCURACY) - 1 downto 0) := to_signed(2**(2*BIT_ACCURACY - 1) - 1, 2*BIT_ACCURACY);
	constant min_val        : signed((2*BIT_ACCURACY) - 1 downto 0) := to_signed(-2**(2*BIT_ACCURACY - 1), 2*BIT_ACCURACY);
begin

	mult_product <= (signed(pix_block_in) * signed(kernels_in));

	-- mapping the value to add the value in the fixed point manner
	--added_value <= mult_product((2*BIT_ACCURACY) - 1 - (INT_BIT_ACC) downto (BIT_ACCURACY) - (INT_BIT_ACC));

	count : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then           -- synchronous reset
				acc_val_internal <= (others => '0');
			else
				if (zero = '1') then
					acc_val_internal <= (others => '0');
				elsif (accumulate = '1') then -- accumulating
					if (saturation = "00") then
						acc_val_internal <= acc_val_internal + mult_product;
					elsif (saturation = "10") then -- minus one when saturated max
						acc_val_internal <= acc_val_internal - 1;
					else                -- plus one when saturated min
						acc_val_internal <= acc_val_internal + 1;
					end if;

				end if;
			end if;

		end if;

	end process;

	-- external saturation above a BIT_ACCURACY signed max value
	saturation_pos <= '1' when acc_val_internal > max_val else '0';
	saturation_neg <= '1' when acc_val_internal < min_val else '0';
	saturation     <= saturation_pos & saturation_neg;

	with (saturation) select acc_val <=
		std_logic_vector(max_val((2*BIT_ACCURACY) - 1 - (INT_BIT_ACC) downto (BIT_ACCURACY) - (INT_BIT_ACC))) when "10",
		std_logic_vector(min_val((2*BIT_ACCURACY) - 1 - (INT_BIT_ACC) downto (BIT_ACCURACY) - (INT_BIT_ACC))) when "01",
		std_logic_vector(acc_val_internal((2*BIT_ACCURACY) - 1 - (INT_BIT_ACC) downto (BIT_ACCURACY) - (INT_BIT_ACC))) when others;

end architecture RTL;
