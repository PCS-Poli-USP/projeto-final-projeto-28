library ieee, work;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.utils.all;

entity Toplevel is
  port (
	ram_clk : in std_logic;

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
	DRAM_LDQM : out std_logic;-----------------------------------------------
	DRAM_UDQM : out std_logic;
	DRAM_WE_N : out std_logic;
	DRAM_CAS_N : out std_logic;
	DRAM_RAS_N : out std_logic;
	DRAM_CS_N : out std_logic
	 
  );
end entity;

architecture rtl of Toplevel is
	
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

	signal ram_busy_s: std_logic;

	signal R_FIFO_WE : std_logic;
	signal RAM_WR_CMD : std_logic := '0';
	signal RAM_RD_CMD : std_logic := '0';

	signal delay1 : std_logic;
	signal delay2 : std_logic;
	signal delay3 : std_logic;
	signal delay4 : std_logic;
begin

	ram_ctrl: sdram_control
	port map (

		clk => ram_clk,

		WR_DATA	=> WRITE_WD,
		RD_DATA	=> READ_WD,
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
	BUSY <= ram_busy_s;


	--APERTAR KEY 0 ESCREVER FIFO RAM
	ST_WR: process (ram_clk) is
	begin
		if rising_edge(ram_clk) then
			if START_WR = '1' and ram_busy_s = '0' then
				WRREQ <= '1';
				RAM_WR_CMD <= '1';
			elsif ram_busy_s = '0' then
				RAM_WR_CMD <= '0';
				WRREQ <= '0';
			end if;
		end if;
	end process;

	
	--APERTAR KEY 1 LER RAM FIFO
	ST_RD: process (ram_clk) is
	begin
		if rising_edge(ram_clk) then
			if START_RD = '1' and ram_busy_s = '0' then
				R_FIFO_WE  <= '1';
				RAM_RD_CMD <= '1';
			elsif R_FIFO_WE = '1' and ram_busy_s = '0' then
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
			RDREQ <= delay4 and R_FIFO_WE;
		end if;
	end process;

end architecture;