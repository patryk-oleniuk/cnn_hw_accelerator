-- The pix logic shifter TB with connected BRAM models
-- input : BRAM pixels from the image ( 1 pixel is read only 1 time)  
-- Version of the accelerator : based on the paper Optimizing Loop Operation and Dataflow in FPGA
-- Acceleration of Deep Convolutional Neural Networks, Arizona State University
-- @author Patryk Oleniuk, patryk.leniuk@epfl.ch, LAP, EPFL 2017

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cnn_conv.all;

entity tb_pixlogic_with_img_BRAMs is
end entity tb_pixlogic_with_img_BRAMs;

architecture RTL of tb_pixlogic_with_img_BRAMs is

	component BRAM_model_all1_readonly is
		generic(
			img_bram_nr : integer range 1 to 6 := 6 -- from 1 to 6 img BRAM
		);
		port(
			clk  : in  std_logic;
			rst  : in  std_logic;
			addr : in  std_logic_vector(IMG_ADDR_WIDTH -1  downto 0); -- 32 bit address
			din  : in  std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0); -- 6 pixels stored in 1 cell
			dout : out std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0);
			we   : in  std_logic_vector((IMG_DATA_WIDTH/8) - 1 downto 0)
		);

	end component BRAM_model_all1_readonly;

	component BRAM_model_kernels_readonly is

		port(
			clk  : in  std_logic;
			rst  : in  std_logic;
			addr : in  std_logic_vector(KER_ADDR_WIDTH -1  downto 0); -- 32 bit address
			din  : in  std_logic_vector(KER_BRAM_DATA_WIDTH - 1 downto 0); -- 22 layers kernels stored in one row
			dout : out std_logic_vector(KER_BRAM_DATA_WIDTH - 1 downto 0);
			we   : in  std_logic_vector((KER_BRAM_DATA_WIDTH/8) - 1 downto 0)
		);
	end component BRAM_model_kernels_readonly;

	component fsm_bram_addr_pix_ker is
		port(
			clk           : in  std_logic;
			rst           : in  std_logic;
			-- start/status/control signals
			start         : in  std_logic;
			done          : out std_logic;
			layer_nr      : in  std_logic_vector(2 downto 0); -- layer nr

			-- IMG BRAM1 interface
			addr_imgbram1 : out std_logic_vector(IMG_ADDR_WIDTH - 1 downto 0); -- 32 bit address
			clk_imgbram1  : out std_logic;
			din_imgbram1  : out std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0); -- 6 pixels stored in 1 cell
			dout_imgbram1 : in  std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0);
			we_imgbram1   : out std_logic_vector((IMG_DATA_WIDTH/8) - 1 downto 0);
			--rst_imgbram1  : out std_logic;
			-- IMG BRAM2 interface
			addr_imgbram2 : out std_logic_vector(IMG_ADDR_WIDTH - 1 downto 0); -- 32 bit address
			--clk_imgbram2  : out std_logic;
			din_imgbram2  : out std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0); -- 6 pixels stored in 1 cell
			dout_imgbram2 : in  std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0);
			--we_imgbram2   : out std_logic;
			--rst_imgbram2  : out std_logic;
			-- IMG BRAM3 interface
			addr_imgbram3 : out std_logic_vector(IMG_ADDR_WIDTH - 1 downto 0); -- 32 bit address
			--clk_imgbram3  : out std_logic;
			din_imgbram3  : out std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0); -- 6 pixels stored in 1 cell
			dout_imgbram3 : in  std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0);
			--we_imgbram3   : out std_logic;
			--rst_imgbram3  : out std_logic;
			-- IMG BRAM1 interface
			addr_imgbram4 : out std_logic_vector(IMG_ADDR_WIDTH - 1 downto 0); -- 32 bit address
			--clk_imgbram4  : out std_logic;
			din_imgbram4  : out std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0); -- 6 pixels stored in 1 cell
			dout_imgbram4 : in  std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0);
			--we_imgbram4   : out std_logic;
			--rst_imgbram4  : out std_logic;
			-- IMG BRAM2 interface
			addr_imgbram5 : out std_logic_vector(IMG_ADDR_WIDTH - 1 downto 0); -- 32 bit address
			--clk_imgbram5  : out std_logic;
			din_imgbram5  : out std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0); -- 6 pixels stored in 1 cell
			dout_imgbram5 : in  std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0);
			--we_imgbram5   : out std_logic;
			--rst_imgbram5  : out std_logic;
			-- IMG BRAM3 interface
			addr_imgbram6 : out std_logic_vector(IMG_ADDR_WIDTH - 1 downto 0); -- 32 bit address
			--clk_imgbram6  : out std_logic;
			din_imgbram6  : out std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0); -- 6 pixels stored in 1 cell
			dout_imgbram6 : in  std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0);
			--we_imgbram6   : out std_logic;
			--rst_imgbram6  : out std_logic;
			-- 1 BRAM for KERNEL / B constant 
			-- IMG BRAM3 interface
			addr_kerbram  : out std_logic_vector(KER_ADDR_WIDTH - 1 downto 0); -- 32 bit address
			--clk_kerbram   : out std_logic;
			din_kerbram   : out std_logic_vector(KER_BRAM_DATA_WIDTH - 1 downto 0); -- 22 pixels stored in 1 cell (12 * 22 = 264 --> 512)
			dout_kerbram  : in  std_logic_vector(KER_BRAM_DATA_WIDTH - 1 downto 0);
			we_kerbram    : out std_logic_vector((KER_BRAM_DATA_WIDTH/8) - 1 downto 0) --;
			--rst_kerbram   : out std_logic
		);
	end component fsm_bram_addr_pix_ker;

	signal clk : std_logic;
	signal rst : std_logic;

	-- IMG BRAM1 interface
	signal addr_imgbram1 : std_logic_vector(IMG_ADDR_WIDTH - 1 downto 0); -- 32 bit address
	signal clk_imgbram1  : std_logic;
	signal din_imgbram1  : std_logic_vector(IMG_DATA_WIDTH - 1 downto 0); -- 6 pixels stored in 1 cell
	signal dout_imgbram1 : std_logic_vector(IMG_DATA_WIDTH - 1 downto 0);
	-- IMG BRAM2 interface
	signal addr_imgbram2 : std_logic_vector(IMG_ADDR_WIDTH - 1 downto 0); -- 32 bit address
	signal clk_imgbram2  : std_logic;
	signal din_imgbram2  : std_logic_vector(IMG_DATA_WIDTH - 1 downto 0); -- 6 pixels stored in 1 cell
	signal dout_imgbram2 : std_logic_vector(IMG_DATA_WIDTH - 1 downto 0);
	-- IMG BRAM3 interface
	signal addr_imgbram3 : std_logic_vector(IMG_ADDR_WIDTH - 1 downto 0); -- 32 bit address
	signal clk_imgbram3  : std_logic;
	signal din_imgbram3  : std_logic_vector(IMG_DATA_WIDTH - 1 downto 0); -- 6 pixels stored in 1 cell
	signal dout_imgbram3 : std_logic_vector(IMG_DATA_WIDTH - 1 downto 0);
	signal we_imgbram3   : std_logic_vector((IMG_DATA_WIDTH/8) - 1 downto 0);
	signal rst_imgbram3  : std_logic;
	-- IMG BRAM1 interface
	signal addr_imgbram4 : std_logic_vector(IMG_ADDR_WIDTH - 1 downto 0); -- 32 bit address
	signal clk_imgbram4  : std_logic;
	signal din_imgbram4  : std_logic_vector(IMG_DATA_WIDTH - 1 downto 0); -- 6 pixels stored in 1 cell
	signal dout_imgbram4 : std_logic_vector(IMG_DATA_WIDTH - 1 downto 0);
	-- IMG BRAM2 interface
	signal addr_imgbram5 : std_logic_vector(IMG_ADDR_WIDTH - 1 downto 0); -- 32 bit address
	signal clk_imgbram5  : std_logic;
	signal din_imgbram5  : std_logic_vector(IMG_DATA_WIDTH - 1 downto 0); -- 6 pixels stored in 1 cell
	signal dout_imgbram5 : std_logic_vector(IMG_DATA_WIDTH - 1 downto 0);

	-- IMG BRAM3 interface
	signal addr_imgbram6 : std_logic_vector(IMG_ADDR_WIDTH - 1 downto 0); -- 32 bit address
	signal clk_imgbram6  : std_logic;
	signal din_imgbram6  : std_logic_vector(IMG_DATA_WIDTH - 1 downto 0); -- 6 pixels stored in 1 cell
	signal dout_imgbram6 : std_logic_vector(IMG_DATA_WIDTH - 1 downto 0);

	-- 1 BRAM for KERNEL / B constant 
	signal addr_kerbram : std_logic_vector(KER_ADDR_WIDTH - 1 downto 0); -- 32 bit address
	signal clk_kerbram  : std_logic;
	signal din_kerbram  : std_logic_vector(KER_BRAM_DATA_WIDTH - 1 downto 0); -- 22 pixels stored in 1 cell (12 * 22 = 264 --> 512)
	signal dout_kerbram : std_logic_vector(KER_BRAM_DATA_WIDTH - 1 downto 0);

	signal kernel_pixnr : natural range 0 to 100000 := 0;
	signal kernel_row   : natural                   := 0; -- used to count the blocks
	signal value_ctr2   : natural                   := 0;

	signal start : std_logic;

	-- Clock period definitions
	constant clk_period : time := 10 ns;

begin

	BRAM1_sim : BRAM_model_all1_readonly
		GENERIC MAP(
			img_bram_nr => 1
		)
		port map(
			clk  => clk,
			rst  => rst,
			addr => addr_imgbram1,
			din  => din_imgbram1,
			dout => dout_imgbram1,
			we   => we_imgbram3
		);

	BRAM2_sim : BRAM_model_all1_readonly
		GENERIC MAP(
			img_bram_nr => 2
		)
		port map(
			clk  => clk,
			rst  => rst,                -- unused
			addr => addr_imgbram2,
			din  => din_imgbram2,       -- unused
			dout => dout_imgbram2,
			we   => we_imgbram3
		);

	BRAM3_sim : BRAM_model_all1_readonly
		GENERIC MAP(
			img_bram_nr => 3
		)
		port map(
			clk  => clk,
			rst  => rst,                -- unused
			addr => addr_imgbram3,
			din  => din_imgbram3,       -- unused
			dout => dout_imgbram3,
			we   => we_imgbram3
		);

	BRAM4_sim : BRAM_model_all1_readonly
		GENERIC MAP(
			img_bram_nr => 4
		)
		port map(
			clk  => clk,
			rst  => rst,                -- unused
			addr => addr_imgbram4,
			din  => din_imgbram4,       -- unused
			dout => dout_imgbram4,
			we   => we_imgbram3
		);

	BRAM5_sim : BRAM_model_all1_readonly
		GENERIC MAP(
			img_bram_nr => 5
		)
		port map(
			clk  => clk,
			rst  => rst,                -- unused
			addr => addr_imgbram5,
			din  => din_imgbram5,       -- unused
			dout => dout_imgbram5,
			we   => we_imgbram3
		);

	BRAM6_sim : BRAM_model_all1_readonly
		GENERIC MAP(
			img_bram_nr => 6
		)
		port map(
			clk  => clk,
			rst  => rst,                -- unused
			addr => addr_imgbram6,
			din  => din_imgbram6,       -- unused
			dout => dout_imgbram6,
			we   => we_imgbram3
		);

	BRAM_KER_SIM : BRAM_model_kernels_readonly
		port map(
			clk  => clk,
			rst  => rst,                -- unused
			addr => addr_kerbram,
			din  => din_kerbram,        -- unused
			dout => dout_kerbram,
			we   => (others => '0')
		);

	uut : fsm_bram_addr_pix_ker
		PORT MAP(
			clk           => clk,
			rst           => rst,
			start         => start,
			layer_nr      => "001",     -- for now we simulate for the 2nd layer
			dout_imgbram1 => dout_imgbram1,
			dout_imgbram2 => dout_imgbram2,
			dout_imgbram3 => dout_imgbram3,
			dout_imgbram4 => dout_imgbram4,
			dout_imgbram5 => dout_imgbram5,
			dout_imgbram6 => dout_imgbram6,
			dout_kerbram  => dout_kerbram,
			din_imgbram1  => din_imgbram1,
			din_imgbram2  => din_imgbram2,
			din_imgbram3  => din_imgbram3,
			din_imgbram4  => din_imgbram4,
			din_imgbram5  => din_imgbram5,
			din_imgbram6  => din_imgbram6,
			addr_imgbram1 => addr_imgbram1,
			addr_imgbram2 => addr_imgbram2,
			addr_imgbram3 => addr_imgbram3,
			addr_imgbram4 => addr_imgbram4,
			addr_imgbram5 => addr_imgbram5,
			addr_imgbram6 => addr_imgbram6,
			addr_kerbram  => addr_kerbram,
			we_imgbram1   => we_imgbram3
		);

	clk_process : process
	begin
		if (rst = '0') then
			kernel_pixnr <= kernel_pixnr + 1;
			if ((kernel_pixnr + 1) mod 8 = 0) then
				kernel_row <= kernel_row + 1;
			end if;

		end if;

		if (kernel_pixnr > 100000) then
			wait;
		end if;

		clk        <= '1';
		wait for clk_period / 2;        -- for 0.5 ns signal is '0'.
		clk        <= '0';
		wait for clk_period / 2;        -- for next 0.5 ns signal is '1'.
		value_ctr2 <= value_ctr2 + 1;

	end process;

	rst <= '1' when value_ctr2 < 3 else '0';

	start <= '1' when value_ctr2 > 10 and value_ctr2 < 20 else '0';

end architecture RTL;
