library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity sdram_control is
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
end entity sdram_control;


architecture rtl of sdram_control is


	constant H: std_logic := '1';
	constant L: std_logic := '0';

	constant OPERATING_MODE : std_logic_vector(12 downto 0) := "000"&'0'&"00"&"010"&'0'&"111";
	
	type CMD is record
		CS_N : std_logic;
		RAS_N : std_logic;
		CAS_N : std_logic;
		WE_N : std_logic;
  	end record;

	constant NOP_C : CMD 				:= (CS_N => L, RAS_N => H, CAS_N => H, WE_N => H);
	constant PRECHARGE_C : CMD 			:= (CS_N => L, RAS_N => L, CAS_N => H, WE_N => L);
	constant AUTO_REFRESH_C : CMD 		:= (CS_N => L, RAS_N => L, CAS_N => L, WE_N => H);
	constant LOAD_MODE_REGISTER_C : CMD := (CS_N => L, RAS_N => L, CAS_N => L, WE_N => L);
	constant ACTIVATE_C : CMD 			:= (CS_N => L, RAS_N => L, CAS_N => H, WE_N => H);
	constant WRITE_C : CMD 				:= (CS_N => L, RAS_N => H, CAS_N => L, WE_N => L);
	constant READ_C : CMD 				:= (CS_N => L, RAS_N => H, CAS_N => L, WE_N => H);
	signal CURR_CMD : CMD := NOP_C;


	type cmd_state is (init, idle, write, read);
	signal estado: cmd_state := init;

	type init_substates is (NOP, PRECHARGE, A_REFRESH, LMR);
	signal init_substate: init_substates := NOP;
	signal init_count: unsigned(2 downto 0) := (others => L);
	signal init_refresh_count : unsigned(2 downto 0) := (others => L);
	signal init_precharged: std_logic := L;
	signal init_mode_registered: std_logic := L;

	
	type write_substates is (PRE_NOP, WRITE, NOP, PRECHARGE, PRECHARGE_NOP);
	signal write_substate: write_substates := PRE_NOP;
	signal write_buff2: std_logic_vector(15 downto 0);
	signal write_buff: std_logic_vector(15 downto 0);
	signal count: unsigned(9 downto 0) := (others => L);

	type read_substates is (PRE_NOP, READ, NOP, PRECHARGE, PRECHARGE_NOP);
	signal read_substate: read_substates := PRE_NOP;

	signal bank_buff: std_logic_vector(1 downto 0);


begin


	DRAM_LDQM <= L;
	DRAM_UDQM <= L;
	DRAM_CLK <= clk;
	DRAM_CKE <= H;
	RD_DATA <= DRAM_DQ;

	DRAM_CS_N <= CURR_CMD.CS_N;
	DRAM_RAS_N <= CURR_CMD.RAS_N;
	DRAM_CAS_N <= CURR_CMD.CAS_N;
	DRAM_WE_N  <= CURR_CMD.WE_N;



	cmd_proc: process (clk) is
	begin
		if falling_edge(clk) then
			write_buff2 <= WR_DATA;
			write_buff <= write_buff2;
			case estado is
				when init =>
					DRAM_DQ <= (others => 'Z');
					case init_substate is
						when NOP =>
							CURR_CMD <= NOP_C;
							init_count <= init_count + 1;
							
							if init_count = "111" then
								if init_mode_registered = H then
									estado <= idle;
								elsif init_precharged = L then
									init_substate <= PRECHARGE;
								elsif init_refresh_count = "000" then -- 000 MEANS 8 ITERATIONS
									init_substate <= LMR;
								else
									init_substate <= A_REFRESH;
								end if;
							end if;
							
						when PRECHARGE =>
							CURR_CMD <= PRECHARGE_C;
							DRAM_ADDR(10) <= H;

							init_precharged <= H;
							init_substate <= A_REFRESH;

						when A_REFRESH =>
							CURR_CMD <= AUTO_REFRESH_C;

							init_substate <= NOP;
							init_refresh_count <= init_refresh_count + 1;
							
						when LMR =>
							CURR_CMD <= LOAD_MODE_REGISTER_C;
							DRAM_BA(1) <= L;
							DRAM_BA(0) <= L;
							DRAM_ADDR <= OPERATING_MODE; -- ADDR 10 IS LOW!
							
							init_substate <= NOP;
							init_mode_registered <= H;
					end case;
				when idle =>
					DRAM_DQ <= (others => 'Z');
					--Preparing for activate, addr is X for NOP
					DRAM_ADDR <= ROW_ADDR(12 downto 0);
					DRAM_BA <= ROW_ADDR(14 downto 13);
					bank_buff <= ROW_ADDR(14 downto 13);

					if WR = H then
						CURR_CMD <= ACTIVATE_C;
						estado <= write;
					elsif RD = H then
						CURR_CMD <= ACTIVATE_C;
						estado <= read;
					else 
						CURR_CMD <= NOP_C;
						estado <= idle;
					end if;
				when write =>
					DRAM_ADDR <= (others => '0');
					DRAM_DQ <= write_buff2;
					case write_substate is
						when PRE_NOP =>
							CURR_CMD <= NOP_C;
							write_substate <= WRITE;

						when WRITE =>
							CURR_CMD <= WRITE_C;
							write_substate <= NOP;
							count <= count + 1;

						when NOP =>
							CURR_CMD <= NOP_C;
							count <= count + 1;
							if count = "1111111111" then
								write_substate <= PRECHARGE;
							end if;

						when PRECHARGE =>
							CURR_CMD <= PRECHARGE_C;
							write_substate <= PRECHARGE_NOP;

						when PRECHARGE_NOP =>
							CURR_CMD <= NOP_C;
							write_substate <= PRE_NOP;
							estado <= idle;
					end case;
				when read =>
					DRAM_ADDR <= (others => '0');
					DRAM_DQ <= (others => 'Z');
					DRAM_BA <= bank_buff;
					case read_substate is
						
						when PRE_NOP =>
							CURR_CMD <= NOP_C;
							read_substate <= READ;

						when READ =>
							CURR_CMD <= READ_C;
							read_substate <= NOP;
							count <= count + 1;

						when NOP =>
							CURR_CMD <= NOP_C;
							count <= count + 1;
							if count = "1111111111" then
								read_substate <= PRECHARGE;
							end if;

						when PRECHARGE =>
							CURR_CMD <= PRECHARGE_C;
							read_substate <= PRECHARGE_NOP;

						when PRECHARGE_NOP =>
							CURR_CMD <= NOP_C;
							read_substate <= PRE_NOP;
							estado <= idle;
					end case;
			end case;
		end if;
	end process;

	BUSY <= L when estado = idle else H;

end architecture;