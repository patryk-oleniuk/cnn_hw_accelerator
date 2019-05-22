-- FSM handling the addressing of the BRAMs, clocking management and data multiplexing
-- Version of the accelerator : based on the paper Optimizing Loop Operation and Dataflow in FPGA
-- Acceleration of Deep Convolutional Neural Networks, Arizona State University
-- @author Patryk Oleniuk, patryk.leniuk@epfl.ch, LAP, EPFL 2017

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cnn_conv.all;

entity fsm_bram_addr_pix_ker is
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
		we_imgbram1   : out std_logic_vector((IMG_DATA_WIDTH/8) -1 downto 0);
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
		we_kerbram    : out std_logic_vector( (KER_BRAM_DATA_WIDTH/8) -1  downto 0)   --;
		--rst_kerbram   : out std_logic
	);
end entity fsm_bram_addr_pix_ker;

architecture RTL of fsm_bram_addr_pix_ker is

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
	end component pix_convolution_logic;

	component pix_accumulators_block is
		generic(
			block_w               : integer := 6; -- 6x6 block
			layer_parallelization : integer := 22
		);
		port(
			clk        : in  std_logic;
			rst        : in  std_logic;
			-- input pixel, kernel pixel, serial input
			pix_calc   : in  pix_6x6_buf;
			ker_in     : in  std_logic_vector(KER_BRAM_DATA_WIDTH - 1 downto 0);
			-- control
			accumulate : in  std_logic; -- 1 to accumulate, 0 to pause
			zero       : in  std_logic; -- 1 to zero the register, 0 to keep accumulating

			-- ouput
			acc_val    : out pix_22x6x6_buf -- 6pix per row, 6 rows, 22 layers
		);
	end component pix_accumulators_block;

	component ReLU is
		port(
			pix_in  : in  std_logic_vector(BIT_ACCURACY - 1 downto 0);
			pix_out : out std_logic_vector(BIT_ACCURACY - 1 downto 0)
		);
	end component ReLU;

	type state_type is (WAIT_START, PREPARE, LOAD_VALUES, LOAD_VALUES2, CALC_LAYER, ADD_B_CONST, FINISHED, ADD_B_CONST_LOAD_VAL, ADD_B_CONST_LOAD_VAL2, SAVE_VALUES_LOAD1, SAVE_VALUES_LOAD2, SAVE_VALUES_LAST, SAVED_ALL, SAVE_VALUES_LOAD3);
	signal state : state_type := WAIT_START;

	signal pix_cntr      : unsigned(5 downto 0); -- 0 up to 63
	signal subimg_cntr   : unsigned(4 downto 0); -- 0 up to 22
	signal blck_cntr_row : unsigned(3 downto 0); -- 0 up to 8
	signal blck_cntr_col : unsigned(3 downto 0); -- 0 up to 8

	-- maximum values for the counters (dependedn on the
	signal pix_cntr_max    : unsigned(5 downto 0);
	signal subimg_cntr_max : unsigned(4 downto 0);
	signal blck_cntr_max   : unsigned(3 downto 0); -- 8, 4 or 1

	-- used to addres the kernel BRAM
	signal ker_pix_cntr : unsigned(5 downto 0);

	-- signals to manage pix shifter
	signal pix_shift_en  : std_logic;
	signal pix_shift_rst : std_logic;

	-- signals to manage the brams addressing
	signal bram_img_addr          : unsigned(IMG_ADDR_WIDTH-1 downto 0) := (others => '0');
	signal bram_img_addr_forwrite : unsigned(IMG_ADDR_WIDTH-1 downto 0) := (others => '0');
	signal bram_ker_addr          : unsigned(KER_ADDR_WIDTH-1 downto 0);

	signal b_const_base_addr  : unsigned(KER_ADDR_WIDTH-1 downto 0);
	signal bram_ker_base_addr : unsigned(KER_ADDR_WIDTH-1 downto 0);

	signal mid_pix_offset1 : unsigned(4 downto 0); -- 0, 9
	signal mid_pix_offset2 : unsigned(4 downto 0); -- 0, 18
	signal bram6_mux       : std_logic_vector(2 downto 0); -- is selecting which BRAM is connected to BRAM6
	-- 0 for BRAM6 , 1-5 for BRAM 1-5, 6 for BRAM6, 7 for BRAM1 again

	signal sector_offset_write : unsigned(IMG_ADDR_WIDTH -1 downto 0); -- 0 or 1781
	signal sector_offset_read  : unsigned(IMG_ADDR_WIDTH -1 downto 0); -- 0 or 1781

	signal bram_we : std_logic;

	signal accumulate_en : std_logic;
	signal zero_acc      : std_logic;

	signal pix_calc              : pix_6x6_buf;
	signal pix_calc_from_shifter : pix_6x6_buf;

	-- for pixel conv logic
	signal use_BRAMs1to5 : std_logic;
	signal bram_values1  : pix_6_buf;   -- @TODO
	signal bram_values2  : pix_6_buf;
	signal bram_values3  : pix_6_buf;
	signal bram_values4  : pix_6_buf;
	signal bram_values5  : pix_6_buf;
	signal bram_values6  : pix_6_buf;

	signal bram_offset1 : std_logic_vector(1 downto 0);
	signal bram_offset2 : std_logic_vector(1 downto 0);
	signal bram_offset3 : std_logic_vector(1 downto 0);
	signal bram_offset4 : std_logic_vector(1 downto 0);
	signal bram_offset5 : std_logic_vector(1 downto 0);
	signal bram_offset6 : std_logic_vector(1 downto 0);

	signal offset_from_shifting : std_logic_vector(1 downto 0);

	signal result_6x6x22 : pix_22x6x6_buf;

	-- signals for SAVE_DATA (writing into the BRAM IMG
	signal din_dout_eq_part : std_logic;

	signal din_before_relu_imgbram1 : std_logic_vector((6*BIT_ACCURACY) - 1 downto 0);
	signal din_before_relu_imgbram2 : std_logic_vector((6*BIT_ACCURACY) - 1 downto 0);
	signal din_before_relu_imgbram3 : std_logic_vector((6*BIT_ACCURACY) - 1 downto 0);
	signal din_before_relu_imgbram4 : std_logic_vector((6*BIT_ACCURACY) - 1 downto 0);
	signal din_before_relu_imgbram5 : std_logic_vector((6*BIT_ACCURACY) - 1 downto 0);
	signal din_before_relu_imgbram6 : std_logic_vector((6*BIT_ACCURACY) - 1 downto 0);

	signal dout_bram1_reg : std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0);
	signal dout_bram2_reg : std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0);
	signal dout_bram3_reg : std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0);
	signal dout_bram4_reg : std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0);
	signal dout_bram5_reg : std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0);
	signal dout_bram6_reg : std_logic_vector((IMG_DATA_WIDTH) - 1 downto 0);

	signal dout_kerbram_reg : std_logic_vector((KER_BRAM_DATA_WIDTH) - 1 downto 0);

	signal writing_states : std_logic;
	signal load_bram_val  : std_logic;
	signal start_old      : std_logic;
	signal start_tick     : std_logic;

begin

	block_accumulator : pix_accumulators_block
		port map(
			clk        => clk,
			rst        => rst,
			pix_calc   => pix_calc,
			ker_in     => dout_kerbram_reg,
			accumulate => accumulate_en,
			zero       => zero_acc,
			acc_val    => result_6x6x22
		);

	pix_convolution_logic1 : pix_convolution_logic
		PORT MAP(
			clk          => clk,
			rst          => pix_shift_rst,
			shift_enable => pix_shift_en,
			-- pixel values for calculation
			pix_calc     => pix_calc_from_shifter,
			-- BRAM config
			use_BRAM1    => use_BRAMs1to5,
			use_BRAM2    => use_BRAMs1to5,
			use_BRAM3    => use_BRAMs1to5,
			use_BRAM4    => use_BRAMs1to5,
			use_BRAM5    => use_BRAMs1to5,
			-- use_BRAM6 : in std_logic; -- this is constantly up

			-- bram values 
			bram_values1 => bram_values1,
			bram_values2 => bram_values2,
			bram_values3 => bram_values3,
			bram_values4 => bram_values4,
			bram_values5 => bram_values5,
			bram_values6 => bram_values6,
			-- bram address offsets
			bram_offset1 => bram_offset1,
			bram_offset2 => bram_offset2,
			bram_offset3 => bram_offset3,
			bram_offset4 => bram_offset4,
			bram_offset5 => bram_offset5,
			bram_offset6 => bram_offset6
		);

	-- adding ReLU operation when saving
	Gen_ReLU1 : for i in 1 to 6 generate
		single_pix_ReLU1 : ReLU
			port map(
				pix_in  => din_before_relu_imgbram1((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY)),
				pix_out => din_imgbram1((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY))
			);
		single_pix_ReLU2 : ReLU
			port map(
				pix_in  => din_before_relu_imgbram2((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY)),
				pix_out => din_imgbram2((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY))
			);

		single_pix_ReLU3 : ReLU
			port map(
				pix_in  => din_before_relu_imgbram3((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY)),
				pix_out => din_imgbram3((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY))
			);

		single_pix_ReLU4 : ReLU
			port map(
				pix_in  => din_before_relu_imgbram4((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY)),
				pix_out => din_imgbram4((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY))
			);
		single_pix_ReLU5 : ReLU
			port map(
				pix_in  => din_before_relu_imgbram5((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY)),
				pix_out => din_imgbram5((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY))
			);

		single_pix_ReLU6 : ReLU
			port map(
				pix_in  => din_before_relu_imgbram6((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY)),
				pix_out => din_imgbram6((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY))
			);

	end generate;

	BRAM1_conn : for i in 1 to 6 generate
		bram_values1(i-1) <= dout_bram1_reg((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY));
	end generate;

	BRAM2_conn : for i in 1 to 6 generate
		bram_values2(i-1) <= dout_bram2_reg((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY));
	end generate;

	BRAM3_conn : for i in 1 to 6 generate
		bram_values3(i-1) <= dout_bram3_reg((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY));
	end generate;

	BRAM4_conn : for i in 1 to 6 generate
		bram_values4(i-1) <= dout_bram4_reg((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY));
	end generate;

	BRAM5_conn : for i in 1 to 6 generate
		bram_values5(i-1) <= dout_bram5_reg((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY));
	end generate;

	BRAM6_conn : for i in 1 to 6 generate -- MUX for BRAM
		with bram6_mux select bram_values6(i - 1) <=
			dout_bram6_reg((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY)) when std_logic_vector(to_unsigned(0, bram6_mux'length)),
			dout_bram1_reg((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY)) when std_logic_vector(to_unsigned(1, bram6_mux'length)),
			dout_bram2_reg((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY)) when std_logic_vector(to_unsigned(2, bram6_mux'length)),
			dout_bram3_reg((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY)) when std_logic_vector(to_unsigned(3, bram6_mux'length)),
			dout_bram4_reg((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY)) when std_logic_vector(to_unsigned(4, bram6_mux'length)),
			dout_bram5_reg((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY)) when std_logic_vector(to_unsigned(5, bram6_mux'length)),
			dout_bram6_reg((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY)) when std_logic_vector(to_unsigned(6, bram6_mux'length)),
			dout_bram1_reg((i*BIT_ACCURACY) - 1 downto ((i - 1)*BIT_ACCURACY)) when std_logic_vector(to_unsigned(7, bram6_mux'length)),(others => '0') when others;
	end generate;

	use_BRAMs1to5 <= '1' when pix_cntr <= 7 and (state = LOAD_VALUES2 or state = CALC_LAYER) else '0';

	with state select offset_from_shifting <=
		"00" when PREPARE,
		"01" when LOAD_VALUES,
	 "01" when LOAD_VALUES2,
	 bram_offset1 when others;

	-- select the mid offset for BRAM6
	mid_pix_offset1 <= (others => '0') when (pix_cntr < 6) else to_unsigned(9, 5);
	mid_pix_offset2 <= (others => '0') when (pix_cntr < 52) else to_unsigned(9, 5);

	bram6_mux <= std_logic_vector(pix_cntr(5 downto 3)); -- changing every 8 values

	b_const_base_addr <= (to_unsigned(KER_B_CONST_OFFSET, KER_ADDR_WIDTH));

	writing_states <= '0' when (state /= SAVE_VALUES_LOAD1 and state /= SAVE_VALUES_LOAD2 and state /= SAVE_VALUES_LAST and state /= ADD_B_CONST) else '1';

	-- selecting image BRAMs address based on the counters and states -- @TODO add BRAM offsets ? 	
	bram_img_addr <= sector_offset_read + blck_cntr_row + (blck_cntr_col*to_unsigned(9, 4)) + (subimg_cntr * to_unsigned(81, 7)) + mid_pix_offset1 + mid_pix_offset2 + unsigned(offset_from_shifting) when writing_states = '0' else bram_img_addr_forwrite;

	-- selecting kernel BRAMs based on the counters and states
	bram_ker_addr <= ker_pix_cntr + ((pix_cntr_max + 1)*subimg_cntr) + bram_ker_base_addr when (state /= ADD_B_CONST_LOAD_VAL) else b_const_base_addr + unsigned(layer_nr) - 1;

	-- the address for all the image parts is the same (just the pixels stored there are different)
	addr_imgbram1 <= std_logic_vector(bram_img_addr(IMG_ADDR_WIDTH-1-4 downto 0) & "0000") when writing_states = '0' else std_logic_vector(unsigned(bram_img_addr(IMG_ADDR_WIDTH-1-4 downto 0) + 9)) & "0000" ;
	addr_imgbram2 <= std_logic_vector(bram_img_addr(IMG_ADDR_WIDTH-1-4 downto 0) & "0000") when writing_states = '0' else std_logic_vector(unsigned(bram_img_addr(IMG_ADDR_WIDTH-1-4 downto 0) + 9)) & "0000";
	addr_imgbram3 <= std_logic_vector(bram_img_addr(IMG_ADDR_WIDTH-1-4 downto 0) & "0000") when writing_states = '0' else std_logic_vector(unsigned(bram_img_addr(IMG_ADDR_WIDTH-1-4 downto 0) + 9)) & "0000";
	addr_imgbram4 <= std_logic_vector(bram_img_addr(IMG_ADDR_WIDTH-1-4 downto 0) & "0000");
	addr_imgbram5 <= std_logic_vector(bram_img_addr(IMG_ADDR_WIDTH-1-4 downto 0) & "0000");
	addr_imgbram6 <= std_logic_vector(bram_img_addr(IMG_ADDR_WIDTH-1-4 downto 0) & "0000");

	-- KERNEL BRAM VALUES
	din_kerbram <= (others => '0');

	-- IMG BRAM zero padding
	din_imgbram1(IMG_DATA_WIDTH-1 downto 6*BIT_ACCURACY) <= (others => '0');
	din_imgbram2(IMG_DATA_WIDTH-1 downto 6*BIT_ACCURACY) <= (others => '0');
	din_imgbram3(IMG_DATA_WIDTH-1 downto 6*BIT_ACCURACY) <= (others => '0');
	din_imgbram4(IMG_DATA_WIDTH-1 downto 6*BIT_ACCURACY) <= (others => '0');
	din_imgbram5(IMG_DATA_WIDTH-1 downto 6*BIT_ACCURACY) <= (others => '0');
	din_imgbram6(IMG_DATA_WIDTH-1 downto 6*BIT_ACCURACY) <= (others => '0');

	addr_kerbram <= std_logic_vector(bram_ker_addr(IMG_ADDR_WIDTH-1-6 downto 0)) & "000000";

	-- clks are just connected to the common clk
	clk_imgbram1 <= clk;
	--clk_imgbram2 <= clk;
	--clk_imgbram3 <= clk;
	--clk_imgbram4 <= clk;
	--clk_imgbram5 <= clk;
	--clk_imgbram6 <= clk;
	--clk_kerbram  <= clk;

	-- all write enables are written to the whole 6 IMG BRAMs at the same time
	gen_WE : for i in 0 to (IMG_DATA_WIDTH/8) -1 generate
		we_imgbram1(i) <= bram_we;
	end generate;
	
	--we_imgbram2 <= bram_we;
	--we_imgbram3 <= bram_we;
	--we_imgbram4 <= bram_we;
	--we_imgbram5 <= bram_we;
	--we_imgbram6 <= bram_we;

	-- never write to the Kernel BRAM, this is constant (dependened on the training model)
	we_kerbram <= (others =>'0');

	-- resets connected to the rst
	--rst_imgbram1 <= rst;
	--rst_imgbram2 <= rst;
	--rst_imgbram3 <= rst;
	--rst_imgbram4 <= rst;
	--rst_imgbram5 <= rst;
	--rst_imgbram6 <= rst;
	--rst_kerbram  <= rst;

	-- select parameters
	with layer_nr select pix_cntr_max <=
		to_unsigned(KERNEL_SIZE*KERNEL_SIZE - 1, 6) when "001", -- 63 when layer 1
		to_unsigned(KERNEL_SIZE*KERNEL_SIZE - 1, 6) when "010", -- 63 when layer 2
        to_unsigned(KERNEL_SIZE*KERNEL_SIZE - 1, 6) when "011", -- 63 when layer 3
        to_unsigned(KERNEL_SIZE*KERNEL_SIZE - 1, 6) when "100", -- 15 when layer 4 (assigned 63 because the shifting logic is not yet working for 4)
        to_unsigned(KERNEL_SIZE*KERNEL_SIZE - 1, 6) when "101", -- 15 when layer 5 (assigned 63 because the shifting logic is not yet working for 4)
        to_unsigned(KERNEL_SIZE*KERNEL_SIZE - 1, 6) when "110", -- 15 when layer 6 (assigned 63 because the shifting logic is not yet working for 4)
		(others => '0')  when others;

	-- select parameters
	with layer_nr select blck_cntr_max <=
		to_unsigned(L1_IMG_WIDTH/PIX_BLOCK_NR - 1, 4) when "001", -- 8x8 blocks when layer 1
		to_unsigned(L2_IMG_WIDTH/PIX_BLOCK_NR - 1, 4) when "010", -- 8x8 blocks when layer 2
        to_unsigned(L3_IMG_WIDTH/PIX_BLOCK_NR - 1, 4) when "011", -- 4x4 blocks when layer 3
        to_unsigned(L4_IMG_WIDTH/PIX_BLOCK_NR - 1, 4) when "100", -- 4x4 blocks when layer 4
        to_unsigned(L5_IMG_WIDTH/PIX_BLOCK_NR - 1, 4) when "101", -- 1x1 blocks when layer 5
        to_unsigned(L6_IMG_WIDTH/PIX_BLOCK_NR - 1, 4) when "110", -- 1x1 blocks when layer 6
		(others => '0')  when others;

	with layer_nr select subimg_cntr_max <=
		to_unsigned(0, 5) when "001",   -- number of input img ->1 -1 = 0 when layer 1            
		to_unsigned(NR_INTERPICS - 1, 5) when others; -- number of input img ->22-1 = 21 when layer 2-6

	-- to swap read/write
	with layer_nr select sector_offset_read <=
		(to_unsigned(ZERO_ADDR, IMG_ADDR_WIDTH)) when "001", --   when layer 1
		(to_unsigned(IMG_SWAP_OFFSET, IMG_ADDR_WIDTH)) when "010", --   when layer 2
		(to_unsigned(ZERO_ADDR, IMG_ADDR_WIDTH)) when "011", --   when layer 3
		(to_unsigned(IMG_SWAP_OFFSET, IMG_ADDR_WIDTH)) when "100", --   when layer 4
		(to_unsigned(ZERO_ADDR, IMG_ADDR_WIDTH)) when "101", --   when layer 5
		(to_unsigned(IMG_SWAP_OFFSET, IMG_ADDR_WIDTH)) when "110", --   when layer 6
		(others => '0')  when others;

	with layer_nr select sector_offset_write <=
		(to_unsigned(IMG_SWAP_OFFSET, IMG_ADDR_WIDTH)) when "001", --   when layer 1
		(to_unsigned(ZERO_ADDR, IMG_ADDR_WIDTH)) when "010", --   when layer 2
		(to_unsigned(IMG_SWAP_OFFSET, IMG_ADDR_WIDTH)) 	when "011", --   when layer 3
		(to_unsigned(ZERO_ADDR, IMG_ADDR_WIDTH)) 		when "100", --   when layer 4
		(to_unsigned(IMG_SWAP_OFFSET, IMG_ADDR_WIDTH)) 	when "101", --   when layer 5
		(to_unsigned(ZERO_ADDR, IMG_ADDR_WIDTH)) 	when "110", --   when layer 6
		(others => '0')  when others;

	-- values of the base addreses hard-coded with values calculated from Excel
	with layer_nr select bram_ker_base_addr <=
		(to_unsigned(L1_KER_OFFSET, KER_ADDR_WIDTH)) when "001", --   when layer 1
		(to_unsigned(L2_KER_OFFSET, KER_ADDR_WIDTH)) when "010", --   when layer 2
		(to_unsigned(L3_KER_OFFSET, KER_ADDR_WIDTH)) 	when "011", --   when layer 3
		(to_unsigned(L4_KER_OFFSET, KER_ADDR_WIDTH)) 	when "100", --   when layer 4
		(to_unsigned(L5_KER_OFFSET, KER_ADDR_WIDTH)) 	when "101", --   when layer 5
		(to_unsigned(L6_KER_OFFSET, KER_ADDR_WIDTH)) 	when "110", --   when layer 6
		(others => '0')  when others;

	-- 1.0 value when we're adding B constant (multiplication 1.0 by B is B)
	gen1 : for i in 0 to 5 generate
		gen1 : for j in 0 to 5 generate
			pix_calc(i)(j) <= "000100000000" when state = ADD_B_CONST or state = ADD_B_CONST_LOAD_VAL2 or state = SAVE_VALUES_LOAD1 else pix_calc_from_shifter(i)(j);
		end generate;
	end generate;

	process(clk)
	begin
		-- only some of the values get replaced, since we wanna to change only some of them
		if (rising_edge(clk)) then
			dout_kerbram_reg <= dout_kerbram;
			dout_bram1_reg   <= dout_imgbram1;
			dout_bram2_reg   <= dout_imgbram2;
			dout_bram3_reg   <= dout_imgbram3;
			dout_bram4_reg   <= dout_imgbram4;
			dout_bram5_reg   <= dout_imgbram5;
			dout_bram6_reg   <= dout_imgbram6;
		end if;

	end process;

	-- strange MUX for saving the values 
	process(clk)
	begin
		-- only some of the values get replaced, since we wanna to change only some of them
		if (rising_edge(clk)) then

			if (load_bram_val = '1') then -- kind of a latch
				din_before_relu_imgbram1 <= dout_bram1_reg((6*BIT_ACCURACY) - 1 downto 0);
				din_before_relu_imgbram2 <= dout_bram2_reg((6*BIT_ACCURACY) - 1 downto 0);
				din_before_relu_imgbram3 <= dout_bram3_reg((6*BIT_ACCURACY) - 1 downto 0);
				din_before_relu_imgbram4 <= dout_bram4_reg((6*BIT_ACCURACY) - 1 downto 0);
				din_before_relu_imgbram5 <= dout_bram5_reg((6*BIT_ACCURACY) - 1 downto 0);
				din_before_relu_imgbram6 <= dout_bram6_reg((6*BIT_ACCURACY) - 1 downto 0);
			end if;

			-- modify some parts of latched regs + !! pixel saving MUX !!
			if (din_dout_eq_part = '1' and writing_states = '1') then -- @TODO Check it again
				gen1 : for i in 1 to 3 loop
					din_before_relu_imgbram1((i*BIT_ACCURACY) - 1 downto (i - 1)*BIT_ACCURACY) <= result_6x6x22(to_integer(subimg_cntr))(3)(i - 1);
					din_before_relu_imgbram2((i*BIT_ACCURACY) - 1 downto (i - 1)*BIT_ACCURACY) <= result_6x6x22(to_integer(subimg_cntr))(4)(i - 1);
					din_before_relu_imgbram3((i*BIT_ACCURACY) - 1 downto (i - 1)*BIT_ACCURACY) <= result_6x6x22(to_integer(subimg_cntr))(5)(i - 1);
					din_before_relu_imgbram4((i*BIT_ACCURACY) - 1 downto (i - 1)*BIT_ACCURACY) <= result_6x6x22(to_integer(subimg_cntr))(0)(i - 1);
					din_before_relu_imgbram5((i*BIT_ACCURACY) - 1 downto (i - 1)*BIT_ACCURACY) <= result_6x6x22(to_integer(subimg_cntr))(1)(i - 1);
					din_before_relu_imgbram6((i*BIT_ACCURACY) - 1 downto (i - 1)*BIT_ACCURACY) <= result_6x6x22(to_integer(subimg_cntr))(2)(i - 1);
				end loop;
			elsif (din_dout_eq_part = '0' and writing_states = '1') then
				gen0 : for i in 4 to 6 loop
					din_before_relu_imgbram1((i*BIT_ACCURACY) - 1 downto (i - 1)*BIT_ACCURACY) <= result_6x6x22(to_integer(subimg_cntr))(3)(i - 1);
					din_before_relu_imgbram2((i*BIT_ACCURACY) - 1 downto (i - 1)*BIT_ACCURACY) <= result_6x6x22(to_integer(subimg_cntr))(4)(i - 1);
					din_before_relu_imgbram3((i*BIT_ACCURACY) - 1 downto (i - 1)*BIT_ACCURACY) <= result_6x6x22(to_integer(subimg_cntr))(5)(i - 1);
					din_before_relu_imgbram4((i*BIT_ACCURACY) - 1 downto (i - 1)*BIT_ACCURACY) <= result_6x6x22(to_integer(subimg_cntr))(0)(i - 1);
					din_before_relu_imgbram5((i*BIT_ACCURACY) - 1 downto (i - 1)*BIT_ACCURACY) <= result_6x6x22(to_integer(subimg_cntr))(1)(i - 1);
					din_before_relu_imgbram6((i*BIT_ACCURACY) - 1 downto (i - 1)*BIT_ACCURACY) <= result_6x6x22(to_integer(subimg_cntr))(2)(i - 1);
				end loop;
			end if;
		end if;
	end process;

	-- start logic
	process(clk)
	begin
		-- only some of the values get replaced, since we wanna to change only some of them
		if (rising_edge(clk)) then
			start_old <= start;
		end if;
	end process;

	-- start_tick is 1 only 1 clk after rising edge of start (start reacting only when changed)
	start_tick <= not (start_old) and start;

	-- state machine logic
	process(clk, rst) is
	begin
		if rst = '1' then
			state         <= WAIT_START;
			pix_shift_en  <= '0';
			pix_cntr      <= (others => '0');
			subimg_cntr   <= (others => '0');
			blck_cntr_row <= (others => '0');
			blck_cntr_col <= (others => '0');
			accumulate_en <= '0';
			done          <= '0';
			zero_acc      <= '1';
			bram_we       <= '0';
			load_bram_val <= '0';
		elsif rising_edge(clk) then
			pix_shift_rst    <= '0';
			pix_shift_en     <= '0';
			accumulate_en    <= '0';
			zero_acc         <= '0';
			din_dout_eq_part <= '0';
			bram_we          <= '0';
			ker_pix_cntr     <= (others => '0');
			load_bram_val    <= '0';
			case state is
				when WAIT_START =>      -- wait for start
					pix_cntr         <= (others => '0');
					subimg_cntr      <= (others => '0');
					blck_cntr_row    <= (others => '0');
					blck_cntr_col    <= (others => '0');
					ker_pix_cntr     <= (others => '0');
					din_dout_eq_part <= '0';
					zero_acc         <= '1';
					if (start_tick = '1') then
						state <= PREPARE;
						done  <= '0';
					else
						state <= WAIT_START;
					end if;
				when PREPARE =>         -- some clks for loading the values to the registers
					pix_shift_en  <= '1';
					pix_shift_rst <= '1'; -- reset the pix shit logic
					state         <= LOAD_VALUES;
					ker_pix_cntr  <= (others => '0');
				when LOAD_VALUES =>     -- some clks for loading the values to the registers
					pix_shift_en  <= '1';
					pix_shift_rst <= '0'; -- reset the pix shit logic
					ker_pix_cntr  <= ker_pix_cntr + 1;
					state         <= LOAD_VALUES2;
				when LOAD_VALUES2 =>    -- some clks for loading the values to the registers(2nd clock needed)
					pix_shift_en  <= '1';
					state         <= CALC_LAYER;
					pix_cntr      <= pix_cntr + 1; -- add cntr to load the next values(change address)
					ker_pix_cntr  <= ker_pix_cntr + 1;
					accumulate_en <= '1';
				when CALC_LAYER =>      -- here we start to calculate the values
					ker_pix_cntr  <= ker_pix_cntr + 1;
					accumulate_en <= '1';
					if (pix_cntr = pix_cntr_max) then -- if one pixel ended
						pix_cntr     <= (others => '0'); -- reset the pixel counter
						pix_shift_en <= '0';
						ker_pix_cntr <= (others => '0'); -- reset the kernel pixel counter
						if (subimg_cntr = subimg_cntr_max) then -- if the sublayer counter ended
							state       <= ADD_B_CONST_LOAD_VAL; -- we're finished with these 6x6 block, move to add_B adn then save
							subimg_cntr <= (others => '0'); -- and 0 the sublayer counter

						else
							state       <= PREPARE; -- else, just load the new values and consinue with another sublayer
							subimg_cntr <= subimg_cntr + 1;
						end if;

					else                -- otherwise, just procees to another pixel
						pix_cntr     <= pix_cntr + 1;
						pix_shift_en <= '1';
					end if;
				when ADD_B_CONST_LOAD_VAL =>
					state <= ADD_B_CONST_LOAD_VAL2;

				when ADD_B_CONST_LOAD_VAL2 =>
					accumulate_en <= '1';
					state         <= ADD_B_CONST;
				when ADD_B_CONST =>
					state            <= SAVE_VALUES_LOAD1;
					din_dout_eq_part <= din_dout_eq_part; -- --don't move
					-- WRITING PRE- STATE1
					-- handling saving the values, saving the 2nd row in temp
					-- handling the addr value already to save clk cycles +1 to save the other row
					if (din_dout_eq_part = '1') then
						bram_img_addr_forwrite <= sector_offset_write + (subimg_cntr * to_unsigned(81, 7)) + blck_cntr_row + (blck_cntr_col*to_unsigned(9, 4)) + 1;
					else
						bram_img_addr_forwrite <= sector_offset_write + (subimg_cntr * to_unsigned(81, 7)) + blck_cntr_row + (blck_cntr_col*to_unsigned(9, 4));
					end if;
				when SAVE_VALUES_LOAD1 =>
					din_dout_eq_part <= din_dout_eq_part; -- --don't move
					state            <= SAVE_VALUES_LOAD2;
					load_bram_val    <= '1'; -- load the BRAM values present before
				when SAVE_VALUES_LOAD2 =>
					state            <= SAVE_VALUES_LOAD3;
					load_bram_val    <= '1'; -- load the BRAM values present before
					din_dout_eq_part <= din_dout_eq_part; -- --don't move
				when SAVE_VALUES_LOAD3 =>
					state            <= SAVE_VALUES_LAST;
					load_bram_val    <= '1'; -- load the BRAM values present before
					din_dout_eq_part <= din_dout_eq_part; -- --don't move
				when SAVE_VALUES_LAST =>
					din_dout_eq_part <= not din_dout_eq_part; -- --don't move
					bram_we          <= '1'; -- wrtie

					if (subimg_cntr >= NR_INTERPICS - 1) then -- if the sublayer counter ended
						if (din_dout_eq_part = '0') then -- then we need also 0
							state <= SAVED_ALL;
						else
							state       <= ADD_B_CONST; -- we're finished with these 6x6 block, move to add_B adn then save
							subimg_cntr <= (others => '0'); -- and 0 the sublayer counter
						end if;

					else
						if (din_dout_eq_part = '1') then -- increment the counter when
							subimg_cntr <= subimg_cntr + 1;
						end if;
						state <= ADD_B_CONST; -- else, save new image sublayer

					end if;

				when SAVED_ALL =>
					zero_acc         <= '1';
					-- iterate 6x6 block counters
					if (blck_cntr_col = blck_cntr_max) then
						blck_cntr_col <= (others => '0');
						if (blck_cntr_row = blck_cntr_max) then
							blck_cntr_row <= (others => '0');
							state         <= FINISHED;
						else
							blck_cntr_row <= blck_cntr_row + 1; -- next row
							state         <= PREPARE; -- else, just load the new values and consinue with another sublayer
							subimg_cntr <= (others => '0');
						end if;
					else
						blck_cntr_col <= blck_cntr_col + 1;
						state         <= PREPARE;
						subimg_cntr <= (others => '0');
					end if;

				when FINISHED =>
					pix_shift_en  <= '0';
					pix_shift_rst <= '1';
					state         <= WAIT_START;
					done          <= '1';
			end case;
		end if;
	end process;

end architecture RTL;
