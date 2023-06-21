library ieee, XESS;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use XESS.SdCardPckg.all;
use XESS.CommonPckg.all;

entity SD_dataflow is
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
end SD_dataflow;

architecture behaviorial of SD_dataflow is

    component SdCardCtrl is
		generic (
			FREQ_G          : real       := 50.0;  -- Master clock frequency (MHz).
			INIT_SPI_FREQ_G : real       := 0.4;  -- Slow SPI clock freq. during initialization (MHz).
			SPI_FREQ_G      : real       := 25.0;  -- Operational SPI freq. to the SD card (MHz).
			BLOCK_SIZE_G    : natural    := 512;  -- Number of bytes in an SD card block or sector.
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


	component SD_FIFO_16x1K is
		 port (
			wr_clk	  : in  std_logic;
			r_clk	  : in  std_logic;
			load_b: in  std_logic;
			rst   : in  std_logic;
			din   : in  std_logic_vector (7 downto 0);
			dout  : out std_logic_vector (15 downto 0);
			handshake: out  std_logic;
			we	   : in std_logic;
			re		: in std_logic;
			empty : out std_logic;
			full  : out std_logic;
			w_data   : out STD_LOGIC_VECTOR (15 downto 0);
			f_we  : out std_logic
		 );
	end component SD_FIFO_16x1K;


    component BLK_READER is
        port (
        clk	 : in  std_logic;
        START	 : in  std_logic;
        inc	 : in 	std_logic;
        Rd_blk : out std_logic;
        blk_num: out std_logic_vector(1 downto 0)
        );
    end component BLK_READER;


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


    type sd_w_fifo_states is (filling1, filling2, idle);
	 signal sd_w_fifo_state: sd_w_fifo_states := idle;
    type sd_r_fifo_states is (init, reading1, reading2, idle);
	 signal sd_r_fifo_state: sd_r_fifo_states := init;
	 
	 type block_reader_states is (idle, counting, ask_blk);
	 signal block_reader_state: block_reader_states := idle;
	 
	 
	 
    signal last_read    : std_logic := '1';
    signal last_written : std_logic := '1';


    signal sd_addr : std_logic_vector(31 downto 0);
    signal page_num: unsigned(20 downto 0) := (others => '0');

    signal clock_count: unsigned(18 downto 0);


    signal fifo1_out : std_logic_vector(15 downto 0);
    signal fifo2_out : std_logic_vector(15 downto 0);
	 signal fifo1_q : std_logic_vector(15 downto 0);
    signal fifo2_q : std_logic_vector(15 downto 0);
    signal fifo1_hs : std_logic;
    signal fifo2_hs : std_logic;
    signal fifo1_we : std_logic;
    signal fifo2_we : std_logic;
    signal fifo1_re : std_logic;
    signal fifo2_re : std_logic;
    signal fifo1_empty : std_logic;
    signal fifo2_empty : std_logic;
    signal fifo1_full : std_logic;
    signal fifo2_full : std_logic;
    signal clockdiv : std_logic;
    signal handshake_o : std_logic;
    signal handshake_i : std_logic;
    signal busy_sig : std_logic;
    signal read_block : std_logic;
    signal saida_sd: std_logic_vector(7 downto 0);
    signal block_num: std_logic_Vector(2 downto 0);
	 signal fifo_fwe : std_logic;

    signal reading: std_logic;
    signal start_read: std_logic;
	 signal blk_cnt: unsigned(1 downto 0) := (others => '0');
	 signal start_reading, inc_blk: std_logic;
	 signal ena2 : std_logic := '0';
	 
begin

   clock_div: process (clk, rst) is
	begin
		if rst = '1' then
			clock_count <= (others => '0');
		elsif rising_edge(clk) then
			clock_count <= clock_count + 1;
		end if;
	end process;

	clockdiv <= clock_count(5);

    sd_cartao: SdCardCtrl
	port map(
			-- Host-side interface signals.
			clk_i      => clk,  -- Master clock.
			reset_i    => rst_sd,  -- active-high, synchronous  reset.
			rd_i       => read_block,  -- active-high read block request.
			wr_i       => '0',      -- active-high write block request.
			continue_i => '0',      -- If true, inc address and continue R/W.
			addr_i     => sd_addr,  -- Block address.
			data_i     => x"00",    -- Data to write to block.
			data_o     => saida_sd,  -- Data read from block.
			busy_o     => busy_sig,  -- High when controller is busy performing some operation.
			hndShk_i   => handshake_i,  -- High when host has data to give or has taken data.
			hndShk_o   => handshake_o,  -- High when controller has taken data or has data to give.
			error_o    => open,
			-- I/O signals to the external SD card.
			cs_bo      => SD_DAT(3), -- Active-low chip-select.
			sclk_o     => SD_CLK,  -- Serial clock to SD card.
			mosi_o     => SD_CMD,  -- Serial data output to SD card.
			miso_i     => SD_DAT(0)  -- Serial data input from SD card.
    );
    sd_addr(08 downto 00) <= (others => '0');
    --sd_addr(10 downto 09) <= (others => '0');
	 sd_addr(10 downto 09) <= std_logic_vector(blk_cnt);
    sd_addr(31 downto 11) <= std_logic_vector(page_num);
	 --sd_addr(31 downto 11) <= (others => '0');


    SD_FIFO_1: SD_FIFO_16x1K
    port map(
        wr_clk    => clockdiv,
        r_clk     => r_clk, -- Vai mudar no futuro
        load_b    => handshake_o,
        rst       => rst,
        din       => saida_sd,
        dout      => fifo1_out,
        handshake => fifo1_hs,
        we        => fifo1_we,
        re		   => fifo1_re,
        empty     => fifo1_empty,
        full      => fifo1_full,
		  w_data    => fifo1_q,
		  f_we      => fifo_fwe
    );

    SD_FIFO_2: SD_FIFO_16x1K
    port map(
        wr_clk    => clockdiv,
        r_clk     => r_clk, -- Vai mudar no futuro
        load_b    => handshake_o,
        rst       => rst,
        din       => saida_sd,
        dout      => fifo2_out,
        handshake => fifo2_hs,
        we        => fifo2_we,
        re		  => fifo2_re,
        empty     => fifo2_empty,
        full      => fifo2_full,
		  w_data    => fifo2_q,
		  f_we      => open
    );

--   read_page_sd: BLK_READER
--	port map(
--		clk     => clockdiv,
--		START   => sd_advance_block,
--		inc     => busy_sig,
--		Rd_blk  => read_block,
--		blk_num => open
--	);
	
	dec_st_read: detector_borda
	generic map (
		subida => true
	)
	port map(
		clk	=> clockdiv,
		rst	=> '1',
		borda	=> reading,
		update=> start_reading
	);
	
	dec_busy: detector_borda
	generic map (
		subida => false
	)
	port map(
		clk	=> clockdiv,
		rst	=> '1',
		borda	=> busy_sig,
		update=> inc_blk
	);
	
	blk_proc: process(clockdiv)
	begin
		if rising_edge(clockdiv) then
			case block_reader_state is
			when idle =>
				read_block <= '0';
				blk_cnt <= "00";
				if start_reading = '1' then
					block_reader_state <= ask_blk;
				end if;
			when counting =>
				read_block <= '0';
				if inc_blk = '1' then
					blk_cnt <= blk_cnt + 1;
					block_reader_state <= ask_blk;					
				end if;
			when ask_blk =>
				read_block <= '1';
				if blk_cnt = "11" then
					block_reader_state <= idle;
				else 
					block_reader_state <= counting;
				end if;
			end case;
		end if;
	end process;

	
	 wait_sd_ready: process(busy_sig)
	 begin
		if falling_edge(busy_sig) then
			ena2 <= '1';
		end if;
	 end process;

    sd_w_proc: process(clockdiv)
    begin
        if rising_edge(clockdiv) and ena2 = '1' then
            case sd_w_fifo_state is
            when idle =>
                fifo1_we <= '0';
                fifo2_we <= '0';
                reading <= '0';
                if last_written = '1' and fifo1_empty = '1' and busy_sig = '0' then
                    sd_w_fifo_state <= filling1;
                elsif last_written = '0' and fifo2_empty = '1' and busy_sig = '0' then
                    sd_w_fifo_state <= filling2;
                end if;
            when filling1 =>
                reading <= '1';
                fifo1_we <= '1';
                fifo2_we <= '0';
                handshake_i <= fifo1_hs;
                if fifo1_full = '1' then
                    page_num <= page_num+1;
                    sd_w_fifo_state <= idle;
                    last_written <= '0';
                end if;
            when filling2 =>
                reading <= '1';
                fifo1_we <= '0';
                fifo2_we <= '1';
                handshake_i <= fifo2_hs;
                if fifo2_full = '1' then
                    page_num <= page_num+1;
                    sd_w_fifo_state <= idle;
                    last_written <= '1';
                end if;
            end case;
        end if;
    end process;

    borda_read: detector_borda
    generic map(
        subida => true
    )
    port map (
        clk	=> r_clk,
        rst	=> '1',
        borda => read_sd_page,
        update => start_read
    );

    -- POSSIVEL CONDIÇÃO DE CORRIDA NO CICLO DE MUNDAÇA DE LEITURA CASO HAJA UM CICLO DE MUDANÇA DE ESCRITA

    sd_r_proc: process(r_clk, last_read, start_read)
    begin
        if rising_edge(r_clk) and ena2 = '1' then
            case sd_r_fifo_state is
				when init =>
					 sd_r_fifo_state <= idle;
					 fifo1_re <= '0';
                fifo2_re <= '0';
            when idle =>
                fifo1_re <= '0';
                fifo2_re <= '0';
                if last_read = '1' and fifo1_full = '1' and start_read = '1' then
                    sd_r_fifo_state <= reading1;
                elsif last_read = '0' and fifo2_full = '1' and start_read = '1' then
                    sd_r_fifo_state <= reading2;
                end if;
            when reading1 =>
                sd_out <= fifo1_out;
					 --sd_out <= std_logic_vector(blk_cnt-1)(1 downto 0)&"00"&fifo1_out(11 downto 0);
                fifo1_re <= '1';
                fifo2_re <= '0';
                if fifo1_empty = '1' then
                    sd_r_fifo_state <= idle;
                    last_read <= '0';
                end if;
            when reading2 =>
                sd_out <= fifo2_out;
					 --sd_out <= std_logic_vector(blk_cnt-1)(1 downto 0)&"00"&fifo2_out(11 downto 0);
                fifo1_re <= '0';
                fifo2_re <= '1';
                if fifo2_empty = '1' then
                    sd_r_fifo_state <= idle;
                    last_read <= '1';
                end if;
            end case;
        end if;
    end process;

    sd_has_data <= fifo1_full when last_read = '1' else fifo2_full;
	 
	f1e <= fifo1_empty;
	f1f <= fifo_fwe;
	f2e <= fifo1_re;
	f2f <= fifo2_re;
	lr  <= last_read;
	lw  <= start_read;
	h_o <= handshake_o;
	h_i <= handshake_i;
	bs <= busy_sig;
	--sd_out <= x"00"&read_block&std_logic_vector(blk_cnt)&busy_sig&handshake_o&handshake_i&reading&"0";


end architecture;