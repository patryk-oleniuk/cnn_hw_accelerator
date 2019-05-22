-- Combinatorial Intercconnection between pixel shifters with MUX/s and interface for BRAM.
-- Version of the accelerator : based on the paper Optimizing Loop Operation and Dataflow in FPGA
-- Acceleration of Deep Convolutional Neural Networks, Arizona State University
-- @author Patryk Oleniuk, patryk.leniuk@epfl.ch, LAP, EPFL 2017

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cnn_conv.all;

entity interpix_interface is
	port(
		-- the most iomportant flag different for each state and shifter
		use_BRAM    : in  std_logic;
		-- counter value from the following pix shifter 
		counter_val : in  std_logic_vector(2 downto 0); -- up to 7

		-- register values from previous pix shifter 
		saved_reg   : in  pix_7_buf;
		init_saved  : in  pix_6_buf;
		-- output value from the followint pix shifter
		next_pixel  : out std_logic_vector(BIT_ACCURACY - 1 downto 0);
		init_pix    : out pix_6_buf;
		
		-- BRAM address (only 0 or 1 or 2) you need to add base!
		bram_offset_addr : out std_logic_vector(1 downto 0);
		bram_values : in pix_6_buf
	);
end entity interpix_interface;

architecture RTL of interpix_interface is
	signal next_pixel_reg  : std_logic_vector(BIT_ACCURACY -1 downto 0);
	signal next_pixel_bram : std_logic_vector(BIT_ACCURACY -1 downto 0);

	signal init_pix_reg  : pix_6_buf;
	signal init_pix_bram : pix_6_buf;

begin

	next_pixel <= next_pixel_bram when (use_BRAM = '1') else next_pixel_reg;
	init_pix   <= init_pix_bram when (use_BRAM = '1') else init_pix_reg;

    -- simply assign the values   
    init_pix_reg <= init_saved;

	-- next_pixel_reg values multiplexer
	with counter_val select next_pixel_reg <=
		saved_reg(0) when "000",
		saved_reg(1) when "001",
        saved_reg(2) when "010",
        saved_reg(3) when "011",
        saved_reg(4) when "100",
		saved_reg(5) when "101",
        saved_reg(6) when "110",
        (others => '0') when "111", -- at this point we should load the init not next
        (others => '0')  when others;

	-- init values
	init_pix_bram <= bram_values;
	
	-- next_pixel_reg values multiplexer
	with counter_val select next_pixel_bram <=
		bram_values(0) when "000", --0
		bram_values(1) when "001", --1
        bram_values(2) when "010", --2
        bram_values(3) when "011", --3
        bram_values(4) when "100", --4
		bram_values(5) when "101", --5
        bram_values(0) when "110", --6
        bram_values(0) when "111", --7
        (others => '0')  when others;
	
    
    -- if counter_val = 7 or 0 then load the basis, otherwise load the offset
    with counter_val select bram_offset_addr <=
		"01" when "000", --0
		"01" when "001", --1
        "01" when "010", --2
        "01" when "011", --3
        "10" when "100", --4 -- value in the next row (BRAM has 2clk addressing latency!)
		"00" when "101", --5 -- loading the init (BRAM has 2clk addressing latency!)
        "01" when "110", --6 
        "01" when "111", --7 
        ("00")  when others;

end architecture RTL;
