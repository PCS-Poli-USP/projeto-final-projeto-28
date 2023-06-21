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
	
	component SdCardCtrl is
		generic (
			FREQ_G          : real       := 50.0;  -- Master clock frequency (MHz).
			INIT_SPI_FREQ_G : real       := 0.4;  -- Slow SPI clock freq. during initialization (MHz).
			SPI_FREQ_G      : real       := 25.0;  -- Operational SPI freq. to the SD card (MHz).
			BLOCK_SIZE_G    : natural    := 256;  -- Number of bytes in an SD card block or sector.
			CARD_TYPE_G     : CardType_t := SD_CARD_E  -- Type of SD card connected to this controller.
		);
		port (
			-- Host-side interface signals.
			clk_i      : in  std_logic;       -- Master clock.
			reset_i    : in  std_logic                     := NO;  -- active-high, synchronous  reset.
			rd_i       : in  std_logic                     := NO;  -- active-high read block request.
			wr_i       : in  std_logic                     := NO;  -- active-high write block request.
			continue_i : in  std_logic                     := NO;  -- If true, inc address and continue R/W.
			addr_i     : in  std_logic_vector(31 downto 0) := x"00000000";  -- Block address.
			data_i     : in  std_logic_vector(7 downto 0)  := x"00";  -- Data to write to block.
			data_o     : out std_logic_vector(7 downto 0)  := x"00";  -- Data read from block.
			busy_o     : out std_logic;  -- High when controller is busy performing some operation.
			hndShk_i   : in  std_logic;  -- High when host has data to give or has taken data.
			hndShk_o   : out std_logic;  -- High when controller has taken data or has data to give.
			error_o    : out std_logic_vector(15 downto 0) := (others => NO);
			-- I/O signals to the external SD card.
			cs_bo      : out std_logic                     := HI;  -- Active-low chip-select.
			sclk_o     : out std_logic                     := LO;  -- Serial clock to SD card.
			mosi_o     : out std_logic                     := HI;  -- Serial data output to SD card.
			miso_i     : in  std_logic                     := ZERO  -- Serial data input from SD card.
		);
	end component;

	component HEX2Seg is
		Port (
			hex : in STD_LOGIC_VECTOR (3 downto 0);
			seg : out STD_LOGIC_VECTOR (6 downto 0)
		);
	end component HEX2Seg;
	
	component SD_FIFO_512 is
    port (
		  clk	  : in  std_logic;
        load_b: in  std_logic;
        rst   : in  std_logic;
        din   : in  std_logic_vector (7 downto 0);
		  addr  : in  std_logic_vector (7 downto 0);
        dout  : out std_logic_vector (15 downto 0);
		  handshake: out  std_logic
    );
	end component SD_FIFO_512;
	
	
	signal color_en : std_logic;
	signal h_s, v_s, vga_clk:std_logic;
	signal up_count: std_logic;
	signal count_px_l: unsigned(10 downto 0) := (others => '0');
	signal rom_out : std_logic_vector(11 downto 0);
	
	signal borda_bot: std_logic_vector(3 downto 0);
	signal saida_sd: std_logic_vector(7 downto 0);

	signal clock_count: unsigned(17 downto 0) := (others => '0');
	signal clockdiv: std_logic;
	signal handshake_i: std_logic;
	signal handshake_o: std_logic;
	signal fifo_o: std_logic_vector(15 downto 0);
	begin
	
	clock_div:
	process (clks(0), rst) is
	begin
		if rst = '0' then
			clock_count <= (others => '0');
		elsif rising_edge(clks(0)) then
			clock_count <= clock_count + 1;
		end if;
	end process;

	clockdiv <= clock_count(8);

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
	GPIO(33 downto 20) <= (others => '0');
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
	
	
	sd_cartao: SdCardCtrl
	generic map(
			FREQ_G          => 50.0,      -- Master clock frequency (MHz).
			INIT_SPI_FREQ_G => 0.4,       -- Slow SPI clock freq. during initialization (MHz).
			SPI_FREQ_G      => 5.0,      -- Operational SPI freq. to the SD card (MHz).
			BLOCK_SIZE_G    => 512,       -- Number of bytes in an SD card block or sector.
			CARD_TYPE_G     => SD_CARD_E  -- Type of SD card connected to this controller.
	)
	port map(
			-- Host-side interface signals.
			clk_i 	  => clks(1),  -- Master clock.
			reset_i    => borda_bot(2),  -- active-high, synchronous  reset.
			rd_i       => borda_bot(0),  -- active-high read block request.
			wr_i       => '0',      -- active-high write block request.
			continue_i => '0',      -- If true, inc address and continue R/W.
			--addr_i     => x"000" & "000" & DIPs(7 downto 0) & "000000000",  -- Block address.
			addr_i     => x"000" & "000" & "00000001" & "000000000",  -- Block address.
			data_i     => x"00",    -- Data to write to block.
			data_o     => saida_sd,  -- Data read from block.
			busy_o     => LEDs(9),  -- High when controller is busy performing some operation.
			hndShk_i   => handshake_i,  -- High when host has data to give or has taken data.
			hndShk_o   => handshake_o,  -- High when controller has taken data or has data to give.
			error_o    => open,
			-- I/O signals to the external SD card.
			cs_bo      => SD_DAT(3), -- Active-low chip-select.
			sclk_o     => SD_CLK,  -- Serial clock to SD card.
			mosi_o     => SD_CMD,  -- Serial data output to SD card.
			miso_i     => SD_DAT(0)  -- Serial data input from SD card.
		);
	
	LEDs(8) <= handshake_o;
	
	sd_f: SD_FIFO_512
	port map(
		  clk	   => clockdiv,
        load_b => handshake_o,
        rst    => borda_bot(3),
        din    => saida_sd,
		  addr   => DIPs(7 downto 0),
        dout   => fifo_o,
		  handshake => handshake_i
	);
	
	hex0 <= (others => '1');
	hex1 <= (others => '1');
	
	seg5: HEX2Seg
	Port map(
		hex => fifo_o(15 downto 12),
		seg => hex5
	);
	
	seg4: HEX2Seg
	Port map(
		hex => fifo_o(11 downto 8),
		seg => hex4
	);
	
	seg3: HEX2Seg
	Port map(
		hex => fifo_o(7 downto 4),
		seg => hex3
	);
	
	seg2: HEX2Seg
	Port map(
		hex => fifo_o(3 downto 0),
		seg => hex2
	);
	
	GPIO(35) <= SD_DAT(0);
	GPIO(34) <= SD_CMD;
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
end architecture;