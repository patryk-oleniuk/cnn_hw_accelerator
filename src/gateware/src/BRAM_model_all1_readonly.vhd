-- The BRAM model to test pixel shifting logic
-- input : BRAM pixels from the image ( 1 pixel is read only 1 time)  
-- Version of the accelerator : based on the paper Optimizing Loop Operation and Dataflow in FPGA
-- Acceleration of Deep Convolutional Neural Networks, Arizona State University
-- @author Patryk Oleniuk, patryk.leniuk@epfl.ch, LAP, EPFL 2017

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cnn_conv.all;

entity BRAM_model_all1_readonly is
	generic(
		img_bram_nr : integer range 1 to 6 := 6 -- from 1 to 6 img BRAM
	);
	port(
		clk  : in  std_logic;
		rst  : in  std_logic;
		addr : in  std_logic_vector(IMG_ADDR_WIDTH -1 downto 0); -- 32 bit address
		din  : in  std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0); -- 6 pixels stored in 1 cell
		dout : out std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0);
		we   : in  std_logic_vector( (IMG_DATA_WIDTH/8) -1  downto 0)
	);
end entity BRAM_model_all1_readonly;

architecture RTL of BRAM_model_all1_readonly is
	signal real_addr     : unsigned(6 downto 0);
	signal dout_reg1     : std_logic_vector((6*BIT_ACCURACY) - 1 downto 0);
	signal dout_reg2     : std_logic_vector((6*BIT_ACCURACY) - 1 downto 0); -- (others => '0');
	signal integer_base1 : integer;
	signal integer_base2 : integer;
	signal integer_base3 : integer;
	signal pixel_val     : pix_6_buf;

begin
	real_addr <= unsigned(addr) mod to_unsigned(81, 7);

	integer_base1 <= to_integer(real_addr / 9) * 330;
	integer_base2 <= to_integer(real_addr mod 9)* 6;
	integer_base3 <= 55 *(img_bram_nr - 1);

	GEN_data : for i in 1 to 6 generate
		dout_reg1((i*BIT_ACCURACY) - 1 downto ((i-1)*BIT_ACCURACY)) <= x"080" when img_bram_nr /=6 else x"000";--std_logic_vector(to_unsigned(i + integer_base1 + integer_base2 + integer_base3, BIT_ACCURACY));
		pixel_val(i-1)                                              <= x"080"when img_bram_nr /=6 else x"000";--std_logic_vector(to_unsigned(i + integer_base1 + integer_base2 + integer_base3, BIT_ACCURACY));
	end generate;

	-- only read process is simulated
	process(clk)
	begin
		if (rising_edge(clk)) then
			-- double buffering
			dout(6*BIT_ACCURACY - 1 downto 0) <= dout_reg2 after 1ns;
			dout_reg2                         <= dout_reg1;
		end if;

	end process;
	
	dout(IMG_DATA_WIDTH-1 downto 6*BIT_ACCURACY) <= (others =>'0');

end architecture RTL;
