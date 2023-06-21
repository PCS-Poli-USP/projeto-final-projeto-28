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
	SD_DAT: inout std_logic_vector(3 downto 0)
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
	signal rom_out : std_logic_vector(11 downto 0);
	
	signal borda_bot: std_logic_vector(3 downto 0);

	component SD_dataflow is
    port (
        clk : in std_logic; --50 Mhz
        rst : in std_logic;

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

	signal sd_out: std_logic_vector(15 downto 0);
	
begin

	vga_s: vga_sync
	port map(
		clk => clks(2),
		rst => rst,
		H_sync => h_s,
		V_sync => v_s,
		VGA_CLK => vga_clk, 
		ColorBurst => color_en
	);
	VGA_H <= h_s;
	VGA_V <= v_s;
	
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
	
	
--	process(clks(0), rst, h_s) is
--	begin
--		if rst = '0' then
--			count_px_l <= (others => '0');
--		elsif rising_edge(clks(0)) then
--			if h_s = '0' then
--				count_px_l <= (others => '0');
--			elsif vga_clk='1' and color_en = '1' then
--				count_px_l <= count_px_l + 1;
--			end if;
--		end if;
--	end process;
	
	rl: rom_linha
	port map (
      addr  => std_logic_vector(count_px_l),
		data  => rom_out
	);
	
	
	GPIO(0) <= h_s;
	GPIO(1) <= v_s;
	GPIO(2) <= color_en;
	GPIO(3) <= vga_clk;
	VGA_R <= rom_out(03 downto 0) when color_en = '1' else (others => '0');
	VGA_G <= rom_out(07 downto 4) when color_en = '1' else (others => '0');
	VGA_B <= rom_out(11 downto 8) when color_en = '1' else (others => '0');
	--GPIO(11 downto 4) <= rom_out(03 downto 0)&rom_out(07 downto 4);
	GPIO(11 downto 4) <= std_logic_vector(count_px_l(7 downto 0));
	
	bordabotgen: for i in 0 to 3 generate
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
	
	
	
	sd_df: SD_dataflow
	port map(
		clk => clks(0),
		rst => borda_bot(0),

		-- SD CONTROL SIGNAL
		rst_sd => borda_bot(1),
		sd_has_data => LEDs(9),
		read_sd_page => borda_bot(2),
		sd_out => sd_out,

		-- SD CONNECTION SIGNALS
		SD_CLK => SD_CLK,
		SD_DAT => SD_DAT,
		SD_CMD => SD_CMD,
		-- DEBUG
	  f1e => GPIO(27),
	  f1f => GPIO(26),
	  f2e => GPIO(25),
	  f2f => GPIO(24),
	  lr  => GPIO(23),
	  lw  => GPIO(22),
	  h_o  => GPIO(21),
	  h_i  => GPIO(20),
	  bs   => GPIO(19)
	);
	

	GPIO(35 downto 28) <= sd_out(15 downto 8);
	LEDs(7 downto 0) <= sd_out(7 downto 0);
	
	hex0 <= (others => '1');
	hex1 <= (others => '1');
	hex2 <= (others => '1');
	hex3 <= (others => '1');
	hex4 <= (others => '1');
	hex5 <= (others => '1');
	
--	seg5: HEX2Seg
--	Port map(
--		hex => fifo_o(15 downto 12),
--		seg => hex5
--	);
--	
--	seg4: HEX2Seg
--	Port map(
--		hex => fifo_o(11 downto 8),
--		seg => hex4
--	);
--	
--	seg3: HEX2Seg
--	Port map(
--		hex => fifo_o(7 downto 4),
--		seg => hex3
--	);
--	
--	seg2: HEX2Seg
--	Port map(
--		hex => fifo_o(3 downto 0),
--		seg => hex2
--	);
	
	GPIO(18 downto 12) <= (others => '0');
	
end architecture;