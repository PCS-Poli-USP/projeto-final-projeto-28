library ieee, XESS;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use XESS.SdCardPckg.all;
use XESS.CommonPckg.all;

entity Toplevel is
port (
	rst	: in	std_logic;
	clks	: in	std_logic_vector(3 downto 0);
	hex0	: out	std_logic_vector(6 downto 0);
	hex1	: out	std_logic_vector(6 downto 0);
	hex2	: out	std_logic_vector(6 downto 0);
	hex3	: out	std_logic_vector(6 downto 0);
	hex4	: out	std_logic_vector(6 downto 0);
	hex5	: out	std_logic_vector(6 downto 0);
	LEDs	: out	std_logic_vector(9 downto 0);
	DIPs	: in	std_logic_vector(9 downto 0);
	KEYs	: in	std_logic_vector(3 downto 0);
	GPIO	: inout	std_logic_vector(35 downto 0); --0 2 16 18 MAIS SENSIVEL
	VGA_H : out std_logic;
	VGA_V : out std_logic;
	VGA_R : out std_logic_vector(3 downto 0);
	VGA_G : out std_logic_vector(3 downto 0);
	VGA_B : out std_logic_vector(3 downto 0);
	SD_CLK: out std_logic;
	SD_CMD: inout std_logic;
	SD_DAT: inout std_logic_vector(3 downto 0);
	DRAM_DQ : inout std_logic_vector(15 downto 0);
	DRAM_ADDR : out std_logic_vector(12 downto 0);
	DRAM_BA : out std_logic_vector(1 downto 0);
	DRAM_CLK : out std_logic;
	DRAM_CKE : out std_logic;
	DRAM_LDQM : out std_logic;
	DRAM_UDQM : out std_logic;
	DRAM_WE_N : out std_logic;
	DRAM_CAS_N : out std_logic;
	DRAM_RAS_N : out std_logic;
	DRAM_CS_N : out std_logic
);
end entity;

architecture rtl of Toplevel is

	component vga_sync is
	port(
		clk : in std_logic;
		rst : in std_logic;
		H_sync: out std_logic;
		V_sync: out std_logic;
		VGA_CLK: out std_logic;
		V_valid: out std_logic;
		H_valid: out std_logic;
		ColorBurst :out std_logic
	);
	end component;
	
	component detector_borda is
	generic (
		subida : boolean := true
	);
	port (
      clk	: in std_logic;
		rst	: in std_logic;
		borda	: in std_logic;
		update: out std_logic
	);
	end component;
	
	component rom_linha is
	port (
      addr  : in std_logic_vector(10 downto 0);
		data  : out std_logic_vector(11 downto 0)
	);
	end component rom_linha;

	component HEX2Seg is
		Port (
			hex : in STD_LOGIC_VECTOR (3 downto 0);
			seg : out STD_LOGIC_VECTOR (6 downto 0)
		);
	end component HEX2Seg;
	
	signal color_en : std_logic;
	signal h_s, v_s, vga_clk:std_logic;
	signal up_count: std_logic;
	signal count_px_l: unsigned(10 downto 0) := (others => '0');
	signal rom_out : std_logic_vector(15 downto 0);
	
	signal borda_bot: std_logic_vector(3 downto 0);
	
	signal h_delay1, h_delay2, h_delay3, h_delay4, h_delay5: std_logic;
	signal v_delay1, v_delay2, v_delay3, v_delay4, v_delay5: std_logic;

	component SD_dataflow is
    port (
        clk : in std_logic; --50 Mhz
		  r_clk: in std_logic;
        rst : in std_logic;
		  ena : in std_logic;

        -- SD CONTROL SIGNAL
        rst_sd: in std_logic;
        sd_has_data: out std_logic;
        read_sd_page: in std_logic;
        sd_out: out std_logic_vector(15 downto 0);

        -- SD CONNECTION SIGNALS
        SD_CLK: out std_logic;
        SD_DAT: inout std_logic_vector(3 downto 0);
        SD_CMD: inout std_logic;
		  
		  -- DEBUG
		  f1e : out std_logic;
		  f1f : out std_logic;
		  f2e : out std_logic;
		  f2f : out std_logic;
		  lr  : out std_logic;
		  lw  : out std_logic;
		  h_o  : out std_logic;
		  h_i  : out std_logic;
		  bs  : out std_logic
    );
	end component SD_dataflow;

	component RAM_CLOCK is
		port (
			refclk   : in  std_logic := '0'; --  refclk.clk
			rst      : in  std_logic := '0'; --   reset.reset
			outclk_0 : out std_logic;        -- outclk0.clk
			locked   : out std_logic         --  locked.export
		);
	end component RAM_CLOCK;

	component sdram_control is
		port (
		  clk: in std_logic;
	  
		  WR_DATA	: in std_logic_vector(15 downto 0);
		  RD_DATA	: out std_logic_vector(15 downto 0);
		  BUSY	: out std_logic;
		  WR		: in std_logic;
		  RD		: in std_logic;
		  ROW_ADDR: in std_logic_vector(14 downto 0); -- BANK + ROW 
	  
		  --SDRAM
		  DRAM_DQ : inout std_logic_vector(15 downto 0);
		  DRAM_ADDR : out std_logic_vector(12 downto 0);
		  DRAM_BA : out std_logic_vector(1 downto 0);
		  DRAM_CLK : out std_logic;
		  DRAM_CKE : out std_logic;
		  DRAM_LDQM : out std_logic;
		  DRAM_UDQM : out std_logic;
		  DRAM_WE_N : out std_logic;
		  DRAM_CAS_N : out std_logic;
		  DRAM_RAS_N : out std_logic;
		  DRAM_CS_N : out std_logic
		   
		);
	  end component sdram_control;

	signal sd_out: std_logic_vector(15 downto 0);
	signal ram_clk: std_logic;
	
	signal hori_sync_count : unsigned(1 downto 0);
	signal col_addr: unsigned(11 downto 0);
	
	signal w_cache_out: std_logic_vector(15 downto 0);
	signal r_cache_out: std_logic_vector(15 downto 0);
	signal r_cache_in: std_logic_vector(15 downto 0);
	signal seg_data: std_logic_vector(15 downto 0);
	
	signal ram_ready: std_logic := '0';
	signal ram_busy_s: std_logic;

	signal R_FIFO_WE : std_logic;
	signal W_FIFO_ADV : std_logic := '0';
	signal RAM_WR_CMD : std_logic := '0';
	signal RAM_RD_CMD : std_logic := '0';

	signal W_FIFO_F: std_logic;
	signal W_FIFO_E: std_logic;
	
	signal R_FIFO_F: std_logic;
	signal R_FIFO_E: std_logic;

	signal PLL_CLK : std_logic;
	signal delay1 : std_logic;
	signal delay2 : std_logic;
	signal delay3 : std_logic;
	signal delay4 : std_logic;
	signal delay5 : std_logic;
	signal delay6 : std_logic;
	signal delay7 : std_logic;
	signal delay8 : std_logic;
	signal delay9 : std_logic;

	signal delay1_adv : std_logic;
	signal delay2_adv : std_logic;
	signal delay3_adv : std_logic;
	signal delay4_adv : std_logic;
	signal delay5_adv : std_logic;

	signal clk_cnt: unsigned(25 downto 0) := (others => '0');
	signal vert_valid, hori_valid : std_logic;
	
	signal count_px_v: unsigned(11 downto 0) := (others => '0');
	signal count_px_v2: unsigned(11 downto 0) := (others => '0');

	component RAM_R_CACHE is
		port (
			rd_clk: in  std_logic;
			wr_clk: in  std_logic;
			rst   : in  std_logic;
			we	  : in  std_logic;
			din   : in  std_logic_vector (15 downto 0);
			addr  : in  std_logic_vector (11 downto 0);
			cnt   : out std_logic_vector (11 downto 0);
			dout  : out std_logic_vector (15 downto 0);
			empty : out std_logic;
			full  : out std_logic
		);
	end component RAM_R_CACHE;

	signal c_update : std_logic;
	signal col_up : std_logic;
	
	
	 type control_unit is (idle, write_to_ram, read_from_ram);
	 signal c_u: control_unit := idle;
	
begin

	vga_s: vga_sync
	port map(
		clk => clks(2),
		rst => rst,
		H_sync => h_s,
		V_sync => v_s,
		VGA_CLK => vga_clk,
		V_valid => vert_valid,
		H_valid => hori_valid,
		ColorBurst => color_en
	);

	
	process(vga_clk, rst) is
	begin
		if rst = '0' then
			count_px_l <= (others => '1');
		elsif rising_edge(vga_clk) then
			if h_s = '1' then
				count_px_l <= (others => '1');
			elsif color_en = '1' then
				count_px_l <= count_px_l + 1;
			end if;
		end if;
	end process;
	
	
	borda_vs: detector_borda
	port map(
		clk		=> vga_clk,
		rst		=> '1',
		borda	=> col_up,
		update	=> c_update
	);
	
	process(vga_clk, h_s, hori_sync_count) is
	begin
		if c_update = '1' then
			col_addr <= (others => '1');
		elsif rising_edge(vga_clk) and color_en = '1' then
			col_addr <= col_addr + 1;
		end if;
	end process;
	
	
	process(h_s, v_s) is
	begin
		if v_s = '1' then
			hori_sync_count <= (others => '0');
			count_px_v <= (others => '1');
			count_px_v2 <= (others => '1');
		elsif rising_edge(h_s) and vert_valid = '1' then
			count_px_v2 <= count_px_v2 + 1;
			if hori_sync_count /= "10" then
				hori_sync_count <= hori_sync_count + 1;
				col_up <= '0';
			else
				col_up <= '1';
				hori_sync_count <= "00";
				count_px_v <= count_px_v + 1;
			end if;
		end if;
	end process;
	
	rl: rom_linha
	port map (
      addr  => std_logic_vector(count_px_l),
		data  => open
	);
	
	VGA_R <= rom_out(03 downto 0) when color_en = '1' else (others => '0');
	VGA_G <= rom_out(07 downto 4) when color_en = '1' else (others => '0');
	VGA_B <= rom_out(11 downto 8) when color_en = '1' else (others => '0');
	
	bordabotgen: for i in 0 to 1 generate
		bordabot0: detector_borda
		generic map(
			subida => false
		)
		port map(
			clk	=> clks(1),
			rst	=> rst,
			borda	=> KEYs(i),
			update=> borda_bot(i)
		);
	end generate;
	
	bordabotgen2: for i in 2 to 3 generate
		bordabot0: detector_borda
		generic map(
			subida => false
		)
		port map(
			clk	=> ram_clk,
			rst	=> rst,
			borda	=> KEYs(i),
			update=> borda_bot(i)
		);
	end generate;
	
	
	
	sd_df: SD_dataflow
	port map(
		clk => clks(0),
		r_clk => ram_clk,
		rst => borda_bot(0),
		ena => '1',

		-- SD CONTROL SIGNAL
		rst_sd => borda_bot(1),
		sd_has_data => LEDs(9),
		read_sd_page => W_FIFO_ADV,
		sd_out => sd_out,

		-- SD CONNECTION SIGNALS
		SD_CLK => SD_CLK,
		SD_DAT => SD_DAT,
		SD_CMD => SD_CMD,
		-- DEBUG
		f1e => open,
		f1f => open,
		f2e => open,
		f2f => open,
		lr  => open,
		lw  => open,
		h_o  => open,
		h_i  => open,
		bs   => open
	);
	
	hex5 <= (others => '1');
	hex4 <= (others => '1');

	
	GPIO(15 downto 0) <= r_cache_in;
	GPIO(16) <= R_FIFO_WE;
	GPIO(17) <= ram_clk;

	r_pll: RAM_CLOCK
	port map
	(
		refclk  => clks(0),
		rst 	=> '0',
		outclk_0=> pll_clk,
		locked	=> open
	);

	red_clk: process (clks(0)) is
	begin
		if rising_edge(clks(0)) then
			clk_cnt <= clk_cnt + 1;	
		end if;
	end process;

	ram_clk <= pll_clk;


	ram_ctrl: sdram_control
	port map (

		clk => ram_clk,

		WR_DATA	=> w_cache_out,
		RD_DATA	=> r_cache_in,
		BUSY	=> ram_busy_s,
		WR		=> delay4_adv,
		RD		=> RAM_RD_CMD,
		ROW_ADDR=> (others => '0'), -- BANK + ROW 

		--SDRAM
		DRAM_DQ => DRAM_DQ,
		DRAM_ADDR => DRAM_ADDR,
		DRAM_BA => DRAM_BA,
		DRAM_CLK => DRAM_CLK,
		DRAM_CKE => DRAM_CKE,
		DRAM_LDQM => DRAM_LDQM,
		DRAM_UDQM => DRAM_UDQM,
		DRAM_WE_N => DRAM_WE_N,
		DRAM_CAS_N => DRAM_CAS_N,
		DRAM_RAS_N => DRAM_RAS_N,
		DRAM_CS_N => DRAM_CS_N
	);

	ram_ready <= not ram_busy_s;
	LEDs(1) <= ram_ready;
	
	r_cache: RAM_R_CACHE
	port map(
		rd_clk=> vga_clk,
		wr_clk=> ram_clk,
		rst   => '0',
		we	  => delay5,
		din   => r_cache_in,
		addr  => std_logic_vector(col_addr),
		cnt   => open,
		dout  => rom_out,
		empty => R_FIFO_E,
		full  => R_FIFO_F
	);

	LEDs(8) <= R_FIFO_E;
	LEDs(7) <= R_FIFO_F;
	LEDs(0) <= ram_clk;

	w_cache_out <= sd_out;

	LEDs(6) <= W_FIFO_E;
	LEDs(5) <= W_FIFO_F;
	LEDs(4) <= W_FIFO_ADV;
	LEDs(3) <= RAM_WR_CMD;
	LEDs(2) <= RAM_RD_CMD;

	process(ram_clk) is
	begin
		if rising_edge(ram_clk) then
			if RAM_WR_CMD = '0' and R_FIFO_F = '0' and ram_ready = '1' then
				W_FIFO_ADV <= '1';
				RAM_WR_CMD <= '1';
			elsif W_FIFO_ADV = '1' and ram_ready = '1' then
				RAM_WR_CMD <= '0';
				W_FIFO_ADV <= '0';
				R_FIFO_WE  <= '1';
				RAM_RD_CMD <= '1';
			end if;
		end if;
	end process;
	
--	--APERTAR KEY 2 ESCREVER FIFO RAM
--	ST_WR: process (ram_clk) is
--	begin
--		if rising_edge(ram_clk) then
--			if borda_bot(2) = '1' and ram_ready = '1' then
--				W_FIFO_ADV <= '1';
--				RAM_WR_CMD <= '1';
--			elsif ram_ready = '1' then
--				RAM_WR_CMD <= '0';
--				W_FIFO_ADV <= '0';
--			end if;
--		end if;
--	end process;

	
	--APERTAR KEY 3 LER RAM FIFO
	ST_RD: process (ram_clk) is
	begin
		if rising_edge(ram_clk) then
			if borda_bot(3) = '1' and ram_ready = '1' then
				R_FIFO_WE  <= '1';
				RAM_RD_CMD <= '1';
			elsif R_FIFO_WE = '1' and ram_ready = '1' then
				R_FIFO_WE  <= '0';
				RAM_RD_CMD <= '0';
			end if;
		end if;
	end process;
	
	DELAY_SINC: process(vga_clk) is
	begin
		if rising_edge(vga_clk) then
			h_delay1 <= h_s;
			h_delay2 <= h_delay1;
			h_delay3 <= h_delay2;
			h_delay4 <= h_delay3;
			h_delay5 <= h_delay4;
			v_delay1 <= v_s;
			v_delay2 <= v_delay1;
			v_delay3 <= v_delay2;
			v_delay4 <= v_delay3;
			v_delay5 <= v_delay4;
		end if;
	end process;
	VGA_H <= h_delay5;
	VGA_V <= v_delay5;
	
	R_FIFO_WE_DELAY: process (ram_clk) is
	begin
	  	if rising_edge(ram_clk) then
			delay1 <= R_FIFO_WE;
			delay2 <= delay1;
			delay3 <= delay2;
			delay4 <= delay3;
			delay5 <= delay4 and R_FIFO_WE;
			delay6 <= delay5;
			delay7 <= delay6;
			delay8 <= delay7;
			delay9 <= delay8;
		end if;
	end process;

	RAM_WR_DELAY: process (ram_clk) is
	begin
		if rising_edge(ram_clk) then
			delay1_adv <= RAM_WR_CMD;
			delay2_adv <= delay1_adv;
			delay3_adv <= delay2_adv;
			delay4_adv <= delay3_adv;
			delay5_adv <= delay4_adv;
		end if;
	end process;
	
	
	seg_data <= r_cache_out;
	hexi1: HEX2Seg
	Port map (
		hex => seg_data(3 downto 0),
		seg => hex0
	);

	hexi2: HEX2Seg
	Port map (
		hex => seg_data(7 downto 4),
		seg => hex1
	);

	hexi3: HEX2Seg
	Port map (
		hex => seg_data(11 downto 8),
		seg => hex2
	);

	hexi4: HEX2Seg
	Port map (
		hex => seg_data(15 downto 12),
		seg => hex3
	);

	
end architecture;