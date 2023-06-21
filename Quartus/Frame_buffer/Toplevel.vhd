library ieee, XESS;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use XESS.SdCardPckg.all;
--use XESS.CommonPckg.all;

entity Toplevel is
port (
	clk		: in	std_logic;
	hex0	: out	std_logic_vector(6 downto 0);
	hex1	: out	std_logic_vector(6 downto 0);
	hex2	: out	std_logic_vector(6 downto 0);
	hex3	: out	std_logic_vector(6 downto 0);
	hex4	: out	std_logic_vector(6 downto 0);
	hex5	: out	std_logic_vector(6 downto 0);
	LED		: out	std_logic_vector(9 downto 0);
	SW		: in	std_logic_vector(9 downto 0);
	KEY0	: in	std_logic;
	KEY1	: in	std_logic;
	--GPIO	: inout	std_logic_vector(35 downto 0); --0 2 16 18 MAIS SENSIVEL
	
	VGA_H : out std_logic;
	VGA_V : out std_logic;
	VGA_R : out std_logic_vector(3 downto 0);
	VGA_G : out std_logic_vector(3 downto 0);
	VGA_B : out std_logic_vector(3 downto 0);
	
	--SD_CLK: out std_logic;
	--SD_CMD: inout std_logic;
	--SD_DAT: inout std_logic_vector(3 downto 0);
	
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
	
	component rom_linha is
	port (
		addr  : in std_logic_vector(11 downto 0);
		data  : out std_logic_vector(11 downto 0)
	);
	end component rom_linha;
	
	component HEX2Seg is
	Port (
		hex : in STD_LOGIC_VECTOR (3 downto 0);
		seg : out STD_LOGIC_VECTOR (6 downto 0)
	);
	end component HEX2Seg;
	
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
	end component detector_borda;
	
	component IMG_ROM IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (16 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q			: OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
	end component IMG_ROM;
	
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

	component FIFO1Kx16b IS
		PORT
		(
			data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			rdclk		: IN STD_LOGIC ;
			rdreq		: IN STD_LOGIC ;
			wrclk		: IN STD_LOGIC ;
			wrreq		: IN STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
			rdempty		: OUT STD_LOGIC ;
			wrfull		: OUT STD_LOGIC 
		);
	END component FIFO1Kx16b;

	

	component SDRAM is
	port (
		clk : in std_logic;
		clk_ram : out std_logic;

		--COMMANDS
		START_RD  : in std_logic;
		START_WR : in std_logic;
		BUSY     : out std_logic;

		-- TO READ FIFO
		READ_WD   : out std_logic_vector(15 downto 0); --DUMPS 1k WORDS PER REQUESTS
		RDREQ   : out std_logic;

		-- TO WRITE FIFO
		WRITE_WD : in std_logic_vector(15 downto 0); --TALVEZ TENHA Q ADICIONAR MAIS UM DELAY POIS MEU METODO DE TESTE FOI FALHO
		WRREQ : out std_logic;
		

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
	end component SDRAM;
	
	
	signal color_en : std_logic;
	signal h_s, v_s, vga_clk:std_logic;
	signal up_count: std_logic;
	signal count_px_l: unsigned(11 downto 0) := (others => '0');
	signal count_px_v: unsigned(11 downto 0) := (others => '0');
	signal count_px_v2: unsigned(11 downto 0) := (others => '0');
	signal rom_out : std_logic_vector(11 downto 0);
	
	signal borda_bot: std_logic_vector(3 downto 0);

	signal sd_out: std_logic_vector(15 downto 0);

	signal vert_valid, hori_valid : std_logic;
	
	
	
	signal c_update : std_logic;
	signal col_up : std_logic;
	
	signal hori_sync_count : unsigned(1 downto 0);
	signal col_addr: unsigned(11 downto 0);
	
	
	signal clk_sd: std_logic;
	signal count_sd: unsigned(30 downto 0) := (others => '0');

	signal ram_clk: std_logic;
	signal ram_out: std_logic_vector(15 downto 0);



	signal rstf1: std_logic := '0';
	signal rstf2: std_logic := '0';
	signal wef1 : std_logic := '0';
	signal wef2 : std_logic := '0';
	signal cntf1 : std_logic_vector(11 downto 0);
	signal cntf2 : std_logic_vector(11 downto 0);
	signal doutf1 : std_logic_vector(15 downto 0);
	signal doutf2 : std_logic_vector(15 downto 0);
	signal f1e : std_logic;
	signal f2e : std_logic;
	signal f1f : std_logic;
	signal f2f : std_logic;


	type sd_w_fifo_states is (init, filling1, filling2, idle);
	signal sd_w_fifo_state: sd_w_fifo_states := init;
	signal last_written : std_logic := '1';
	signal rdreqwf1 : std_logic;
	signal rdreqwf2 : std_logic;
	signal wrreqwf1 : std_logic;
	signal wrreqwf2 : std_logic;
	signal doutwf1 : std_logic_vector(15 downto 0);
	signal doutwf2 : std_logic_vector(15 downto 0);
	signal wf1e : std_logic;
	signal wf2e : std_logic;
	signal wf1f : std_logic;
	signal wf2f : std_logic;
	signal fake_addr: unsigned(16 downto 0) := (others => '0');

begin

	fake_sd_clk: process (clk) is
	begin
		if rising_edge(clk) then
			count_sd <= count_sd + 1;
    	end if;
	end process;
	clk_sd <= count_sd(15);

	vga_s: vga_sync
	port map(
		clk => clk,
		rst => '1',
		H_sync => h_s,
		V_sync => v_s,
		VGA_CLK => vga_clk,
		V_valid => vert_valid,
		H_valid => hori_valid,
		ColorBurst => color_en
	);
	VGA_H <= h_s;
	VGA_V <= v_s;
	
	
	borda_vs: detector_borda
	port map(
		clk		=> vga_clk,
		rst		=> '1',
		borda	=> col_up,
		update	=> c_update
	);
	
	
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
	
	
	
	--COL 0 -> FFE
	process(vga_clk, h_s, hori_sync_count) is
	begin
		if c_update = '1' then
			col_addr <= (others => '1');
		elsif rising_edge(vga_clk) and color_en = '1' then
			col_addr <= col_addr + 1;
		end if;
	end process;
	
	
	
	process(vga_clk) is
	begin
		if rising_edge(vga_clk) then
			if h_s = '1' then
				count_px_l <= (others => '0');
			elsif color_en = '1' then
				count_px_l <= count_px_l + 1;
			end if;
		end if;
	end process;
	
	
	--PARA NOSSO ENCODING DE AGR O DECODING E O SEGUINTE
	--    std_logic_vector(count_px_v)(7 downto 0)&std_logic_vector(count_px_l/3)(8 downto 0)
	--LEITURA TRIPLICADA PARA RAM LOGO
	--    std_logic_vector(count_px_v2)(7 downto 0)&std_logic_vector(count_px_l)(8 downto 0)
	--PARA APRESENTACAO EM HD A LEITURA SERA
	--    std_logic_vector(count_px_v)(7 downto 0)&std_logic_vector(col_addr)(8 downto 0)
	
	--READ FIFO 1
	RF1: RAM_R_CACHE
	port map (
		rd_clk => vga_clk,
		wr_clk => ram_clk,
		rst    => rstf1,
		we     => wef1,
		din    => ram_out,
		addr   => std_logic_vector(col_addr),
		cnt    => cntf1,
		dout   => doutf1,
		empty  => f1e,
		full   => f1f
	);	

	--READ FIFO 2
	RF2: RAM_R_CACHE
	port map (
		rd_clk => vga_clk,
		wr_clk => ram_clk,
		rst    => rstf2,
		we     => wef2,
		din    => ram_out,
		addr   => std_logic_vector(col_addr),
		cnt    => cntf2,
		dout   => doutf2,
		empty  => f2e,
		full   => f2f
	);	

	--RAM
	RAM: SDRAM
	port map(
		clk	=> clk,
		clk_ram	=> ram_clk,

		--COMMANDS
		START_RD 	=> '0',
		START_WR	=> '0',
		BUSY    	=> open,

		-- TO READ FIFO
		READ_WD  	=> ram_out,
		RDREQ  		=> open,

		-- TO WRITE FIFO
		WRITE_WD	=> doutwf1, -- PRECISA MUDAR ISSO E SO PRA COMPILAR
		WRREQ		=> open,
		

		--SDRAM
		DRAM_DQ		=> DRAM_DQ,
		DRAM_ADDR	=> DRAM_ADDR,
		DRAM_BA		=> DRAM_BA,
		DRAM_CLK	=> DRAM_CLK,
		DRAM_CKE	=> DRAM_CKE,
		DRAM_LDQM	=> DRAM_LDQM,
		DRAM_UDQM	=> DRAM_UDQM,
		DRAM_WE_N	=> DRAM_WE_N,
		DRAM_CAS_N	=> DRAM_CAS_N,
		DRAM_RAS_N	=> DRAM_RAS_N,
		DRAM_CS_N	=> DRAM_CS_N
	);
	
	
	--WRITE FIFO 1
	WF1: FIFO1Kx16b
	port map (
		data    => "0000"&rom_out,
		rdclk   => ram_clk,
		rdreq   => rdreqwf1,
		wrclk   => clk_sd,
		wrreq   => wrreqwf1,
		q       => doutwf1,
		rdempty => wf1e,
		wrfull  => wf1f
	);

	--WRITE FIFO 2
	WF2: FIFO1Kx16b
	port map (
		data    => "0000"&rom_out,
		rdclk   => ram_clk,
		rdreq   => rdreqwf2,
		wrclk   => clk_sd,
		wrreq   => wrreqwf2,
		q       => doutwf2,
		rdempty => wf2e,
		wrfull  => wf2f
	);
	LED(9) <= wf1e;
	LED(8) <= wf1f;
	LED(7) <= wf2e;
	LED(6) <= wf2f;


	borda_bot1: detector_borda
	generic map (
		subida => false
	)
	port map(
     	clk	=> clk_sd,
		rst	=> SW(9),
		borda	=> KEY0,
		update => borda_bot(0)
	);


	sd_w_proc: process(clk_sd)
    begin
        if rising_edge(clk_sd) then
            case sd_w_fifo_state is
			when init =>
				sd_w_fifo_state <= idle;
            when idle =>
                wrreqwf1 <= '0';
                wrreqwf2 <= '0';
				if borda_bot(0) = '1' then
					if last_written = '1' and wf1e = '1' then
                    	sd_w_fifo_state <= filling1;
					elsif last_written = '0' and wf2e = '1' then
						sd_w_fifo_state <= filling2;
					end if;
				end if;
            when filling1 =>
                wrreqwf1 <= '1';
                wrreqwf2 <= '0';
                if wf1f = '1' then
                    sd_w_fifo_state <= idle;
                    last_written <= '0';
                end if;
            when filling2 =>
                wrreqwf1 <= '0';
                wrreqwf2 <= '1';
                if wf2f = '1' then
                    sd_w_fifo_state <= idle;
                    last_written <= '1';
                end if;
            end case;
        end if;
    end process;
	
	fake_addr_p: process (clk_sd) is
	begin
		if rising_edge(clk_sd) and sd_w_fifo_state /= idle then
			fake_addr <= fake_addr + 1;
		end if;
	end process;

	imagem_rom: IMG_ROM
	PORT map (
		address	=> std_logic_vector(count_px_v)(7 downto 0)&std_logic_vector(count_px_l/3)(8 downto 0),
		clock	=> VGA_CLK,
		q		=> rom_out
	);
	
	
	max_h0: HEX2Seg
	Port map (
		hex => rom_out(3 downto 0),
		seg => hex0
	);
	max_h1: HEX2Seg
	Port map (
		hex => rom_out(7 downto 4),
		seg => hex1
	);
	max_h2: HEX2Seg
	Port map (
		hex => rom_out(11 downto 8),
		seg => hex2
	);

	-- max_v0: HEX2Seg
	-- Port map (
	-- 	hex => std_logic_vector(max_v(3 downto 0)),
	-- 	seg => hex3
	-- );
	-- max_v1: HEX2Seg
	-- Port map (
	-- 	hex => std_logic_vector(max_v(7 downto 4)),
	-- 	seg => hex4
	-- );
	-- max_v2: HEX2Seg
	-- Port map (
	-- 	hex => std_logic_vector(max_v(11 downto 8)),
	-- 	seg => hex5
	-- );

	process()
	VGA_B <= rom_out(03 downto 0) when color_en = '1' else (others => '0'); --when SW(9) = '1' else (others => '0');
	VGA_G <= rom_out(07 downto 4) when color_en = '1' else (others => '0'); --when SW(8) = '1' else (others => '0');
	VGA_R <= rom_out(11 downto 8) when color_en = '1' else (others => '0'); --when SW(7) = '1' else (others => '0');
	
end architecture;