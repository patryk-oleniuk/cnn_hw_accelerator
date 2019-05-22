-- The BRAM model to test pixel shifting logic, it contains KERNELs
-- input : BRAM pixels from the image ( 1 pixel is read only 1 time)  
-- Version of the accelerator : based on the paper Optimizing Loop Operation and Dataflow in FPGA
-- Acceleration of Deep Convolutional Neural Networks, Arizona State University
-- @author Patryk Oleniuk, patryk.leniuk@epfl.ch, LAP, EPFL 2017

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cnn_conv.all;

entity BRAM_model_kernels_readonly is
	port(
		clk  : in  std_logic;
		rst  : in  std_logic;
		addr : in  std_logic_vector(KER_ADDR_WIDTH -1  downto 0); -- 32 bit address
		din  : in  std_logic_vector(KER_BRAM_DATA_WIDTH - 1 downto 0); -- 22 layers kernels stored in one row
		dout : out std_logic_vector(KER_BRAM_DATA_WIDTH - 1 downto 0);
		we   : in  std_logic_vector( (KER_BRAM_DATA_WIDTH/8) -1  downto 0)
	);
end entity BRAM_model_kernels_readonly;

architecture RTL of BRAM_model_kernels_readonly is
	signal real_addr : unsigned(BIT_ACCURACY-1 downto 0);
	signal dout_reg1 : std_logic_vector((KER_BRAM_DATA_WIDTH) - 1 downto 0):= (others => '0');
	signal dout_reg2 : std_logic_vector((KER_BRAM_DATA_WIDTH) - 1 downto 0):= (others => '0'); 
	signal dout_reg3 : std_logic_vector((KER_BRAM_DATA_WIDTH) - 1 downto 0):= (others => '0'); 
	signal single_kerpix : std_logic_vector(BIT_ACCURACY-1 downto 0);

begin
	real_addr <= unsigned(addr) mod to_unsigned(64, BIT_ACCURACY);
	single_kerpix <= dout_reg3(BIT_ACCURACY-1 downto 0);
	
	GEN_data : for i in 1 to 22 generate
		dout_reg1((i*BIT_ACCURACY) - 1 downto ((i-1)*BIT_ACCURACY)) <=  std_logic_vector(unsigned(addr) mod to_unsigned((2**12)-1, 12)); -- pixel values from 1 to 64
	end generate;
-- only read process is simulated
	process(clk)
	begin
		if (rising_edge(clk)) then
			-- double buffering
			dout_reg3 <= dout_reg2; -- just for simulation
			dout      <= dout_reg2 after 1ns;
			dout_reg2 <= dout_reg1;
		end if;

	end process;

end architecture RTL;
