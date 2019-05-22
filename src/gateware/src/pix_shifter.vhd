-- The basic 6x6 pixel shifting module.
-- Version of the accelerator : based on the paper Optimizing Loop Operation and Dataflow in FPGA
-- Acceleration of Deep Convolutional Neural Networks, Arizona State University
-- @author Patryk Oleniuk, patryk.leniuk@epfl.ch, LAP, EPFL 2017

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cnn_conv.all;

entity pix_shifter is
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
end entity pix_shifter;

architecture RTL of pix_shifter is

	-- set of shift registers
	signal shift_pos1 : std_logic_vector(BIT_ACCURACY - 1 downto 0);
	signal shift_pos2 : std_logic_vector(BIT_ACCURACY - 1 downto 0);
	signal shift_pos3 : std_logic_vector(BIT_ACCURACY - 1 downto 0);
	signal shift_pos4 : std_logic_vector(BIT_ACCURACY - 1 downto 0);
	signal shift_pos5 : std_logic_vector(BIT_ACCURACY - 1 downto 0);
	signal shift_pos6 : std_logic_vector(BIT_ACCURACY - 1 downto 0);
	--signal shift_pos7 : std_logic_vector(BIT_ACCURACY - 1 downto 0); -- additional sr to store 13th value

	-- registers for outputs
	signal init_out_reg : pix_6_buf;
	signal counter      : unsigned(2 downto 0);

--
begin

	init_saved_pixels <= init_out_reg;
	cntr              <= std_logic_vector(counter);
	pix_calc(0)       <= shift_pos1;
	pix_calc(1)       <= shift_pos2;
	pix_calc(2)       <= shift_pos3;
	pix_calc(3)       <= shift_pos4;
	pix_calc(4)       <= shift_pos5;
	pix_calc(5)       <= shift_pos6;

	count : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then           -- synchronous reset
				counter    <= "111";
				for i in 0 to 5 loop
					init_out_reg(i) <= (others => '0');
				end loop;
				shift_pos1 <= (others => '0');
				shift_pos2 <= (others => '0');
				shift_pos3 <= (others => '0');
				shift_pos4 <= (others => '0');
				shift_pos5 <= (others => '0');
				shift_pos6 <= (others => '0');
			elsif(shift_enable = '0') then
				-- change nothing
				
			else
				-- increment the counter
				counter <= counter + 1;

				-- shift SR every clock cycle
				shift_pos6 <= nxt_pix;
				shift_pos5 <= shift_pos6;
				shift_pos4 <= shift_pos5;
				shift_pos3 <= shift_pos4;
				shift_pos2 <= shift_pos3;
				shift_pos1 <= shift_pos2;

				if (counter = 7) then   -- load new values and start again 
					init_out_reg <= init_pixels;

					shift_pos1 <= init_pixels(0);
					shift_pos2 <= init_pixels(1);
					shift_pos3 <= init_pixels(2);
					shift_pos4 <= init_pixels(3);
					shift_pos5 <= init_pixels(4);
					shift_pos6 <= init_pixels(5);

				elsif (counter = 6) then -- if almost finished, upload the saved register

					buf_saved_pixels(0) <= shift_pos1;
					buf_saved_pixels(1) <= shift_pos2;
					buf_saved_pixels(2) <= shift_pos3;
					buf_saved_pixels(3) <= shift_pos4;
					buf_saved_pixels(4) <= shift_pos5;
					buf_saved_pixels(5) <= shift_pos6;
					buf_saved_pixels(6) <= nxt_pix;
				else

				end if;

			end if;
		end if;

	end process count;

end architecture RTL;
