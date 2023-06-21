library ieee, work;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.utils.all;

entity Toplevel is
  port (
	clk : in std_logic;
	LED : out std_logic_vector(9 downto 0);
	SW  : in std_logic_vector(9 downto 0);
	KEY : in std_logic_vector(1 downto 0);

	SEG7: out byte_array(5 downto 0);
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
end entity;

architecture rtl of Toplevel is

	component RAM_PLL is
		port
		(
			areset		: in std_logic  := '0';
			inclk0		: in std_logic  := '0';
			c0		: out std_logic ;
			locked		: out std_logic 
		);
	end component RAM_PLL;
	
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
	
	component RAM_R_CACHE is
    port (
		clk	  : in  std_logic;
        rst   : in  std_logic;
		we	  : in std_logic;
        din   : in  std_logic_vector (15 downto 0);
		addr  : in  std_logic_vector (9 downto 0);
        dout  : out std_logic_vector (15 downto 0);
		empty : out std_logic;
		full : out std_logic
    );
	end component RAM_R_CACHE;
	
	
	component HEX2Seg is
	Port (
		hex : in STD_LOGIC_VECTOR (3 downto 0);
		seg : out STD_LOGIC_VECTOR (7 downto 0)
	);
	end component HEX2Seg;
	
	component RAM_W_CACHE is
    port (
		clk	  : in  std_logic;
		adv   : in  std_logic;
        rst   : in  std_logic;
        dout  : out std_logic_vector (15 downto 0);
		empty : out std_logic;
		full : out std_logic
    );
	end component RAM_W_CACHE;

	component detector_borda is
	generic (
		subida : boolean := false
	);
	port (
		clk	: in std_logic;
		rst	: in std_logic;
		borda	: in std_logic;
		update: out std_logic
	);
	end component detector_borda;


	
	signal PLL_CNT: unsigned(25 downto 0) := (others => '0');
	signal ram_clk : std_logic;
	
	signal w_cache_out: std_logic_vector(15 downto 0);
	signal r_cache_out: std_logic_vector(15 downto 0);
	signal r_cache_in: std_logic_vector(15 downto 0);
	signal seg_data: std_logic_vector(15 downto 0);
	
	signal ram_ready: std_logic := '0';
	signal ram_busy_s: std_logic;

	signal KEY_PRESS : std_logic_vector(1 downto 0);
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
begin
	
	r_pll: RAM_PLL
	port map
	(
		areset	=> '0',
		inclk0  => clk,
		c0		=> PLL_CLK,
		locked	=> open
	);

	process(PLL_CLK) is
  	begin
		if rising_edge(PLL_CLK) then
			PLL_CNT <= PLL_CNT + 1;
		end if;
	end process;


	ram_clk <= PLL_CLK;


	ram_ctrl: sdram_control
	port map (

		clk => ram_clk,

		WR_DATA	=> w_cache_out,
		RD_DATA	=> r_cache_in,
		BUSY	=> ram_busy_s,
		WR		=> RAM_WR_CMD,
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
	LED(9) <= ram_ready;
	
	r_cache: RAM_R_CACHE
	port map(
		clk	  => ram_clk,
		rst   => '1',
		we	  => delay5,
		din   => r_cache_in,
		addr  => SW,
		dout  => r_cache_out,
		empty => R_FIFO_E,
		full  => R_FIFO_F
	);
	LED(8) <= R_FIFO_E;
	LED(7) <= R_FIFO_F;
	LED(0) <= ram_clk;


	ram_w: RAM_W_CACHE
    port map (
		clk	  => ram_clk,
		adv	  => W_FIFO_ADV,      --DUMP DATA WHILE ADV IS TRUE
		rst   => '1',
		dout  => w_cache_out,
		empty => W_FIFO_E,
		full  => W_FIFO_F
    );
	LED(6) <= W_FIFO_E;
	LED(5) <= W_FIFO_F;
	LED(4) <= W_FIFO_ADV;
	LED(3) <= RAM_WR_CMD;
	LED(2) <= RAM_RD_CMD;

	borda_bot: for i in 0 to 1 generate
		BOTi: detector_borda
		generic map (
			subida => false
		)
		port map (
			clk	=> ram_clk,
			rst	=> '1',
			borda => KEY(i),
			update => KEY_PRESS(i)
		);
	end generate;

	--APERTAR KEY 0 ESCREVER FIFO RAM
	ST_WR: process (ram_clk) is
	begin
		if rising_edge(ram_clk) then
			if KEY_PRESS(0) = '1' and ram_ready = '1' then
				W_FIFO_ADV <= '1';
				RAM_WR_CMD <= '1';
			elsif ram_ready = '1' then
				RAM_WR_CMD <= '0';
				W_FIFO_ADV <= '0';
			end if;
		end if;
	end process;

	
	--APERTAR KEY 1 LER RAM FIFO
	ST_RD: process (ram_clk) is
	begin
		if rising_edge(ram_clk) then
			if KEY_PRESS(1) = '1' and ram_ready = '1' then
				R_FIFO_WE  <= '1';
				RAM_RD_CMD <= '1';
			elsif R_FIFO_WE = '1' and ram_ready = '1' then
				R_FIFO_WE  <= '0';
				RAM_RD_CMD <= '0';
			end if;
		end if;
	end process;
	
	R_FIFO_WE_DELAY: process (ram_clk) is
	begin
	  	if rising_edge(ram_clk) then
			delay1 <= R_FIFO_WE;
			delay2 <= delay1;
			delay3 <= delay2;
			delay4 <= delay3;
			delay5 <= delay4 and R_FIFO_WE;
		end if;
	end process;
	
	
	seg_data <= r_cache_out;
	hexgen: for i in 0 to 3 generate
		hexi: HEX2Seg
		Port map (
			hex => seg_data(4*i+3 downto 4*i),
			seg => SEG7(i)
		);
	end generate;


end architecture;
