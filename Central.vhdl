library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity central_ip is
    port(
        clock:  in  std_logic; --Entrar com o clock de 50MHz do FPGA
	    reset:  in  std_logic; --Reset, Lembre q o FPGA é active low, se aperta o botao o reset vai para 0
		sin:    in  std_logic; --Entrada da antena
        d0:  out std_logic_vector(6 downto 0);
        d1:  out std_logic_vector(6 downto 0);
        d2:  out std_logic_vector(6 downto 0)
    );
end central_ip;

architecture central_arch of central_ip is 

    component rx is 
        generic (baudrate     : integer := 300);
        port(
            clock		: in  std_logic; --Entrar com o clock de 50MHz do FPGA
            reset		: in  std_logic; --Reset, Lembre q o FPGA é active low, se aperta o botao o reset vai para 0
            sin			: in  std_logic; --Entrada da antena
            dado		: out std_logic_vector(7 downto 0); --Saida do receptor
            fim			: out std_logic --Sinal de controle da saida, So ler o valor de dado quando este sinal estiver em 1
        );
    end component;

    component bin_to_dec_and_digits is
        port (
            bin_num   : in std_logic_vector(7 downto 0);
            digit_0   : out std_logic_vector(7 downto 0);
            digit_1   : out std_logic_vector(7 downto 0);
            digit_2   : out std_logic_vector(7 downto 0)
        );
    end component;

    component display is
        port (
          input: in   std_logic_vector(7 downto 0); -- ASCII 8 bits
          output: out std_logic_vector(7 downto 0)  -- ponto + abcdefg
        );
      end component;

    signal rx_out: std_logic_vector(7 downto 0);
    signal fim, enable: std_logic;
    signal digit0,digit1,digit2: std_logic_vector(7 downto 0);
    signal disp0, disp1, disp2: std_logic_vector(7 downto 0);

    type ip_array is array (11 downto 0) of std_logic_vector(7 downto 0);
    signal ip: ip_array;

    type tipo_estado is (inicial, espera, e1, e2, e3, e4);
    signal estado: tipo_estado;

begin
    -- armazenamento
    uart: rx generic map(200) port map(clock, reset, sin, rx_out,fim);
    btdd: bin_to_dec_and_digits port map(rx_out,digit0,digit1,digit2);

    process(fim)
    variable i: integer := 0;
    begin
        if fim = '1' and  i <= 9 then
            ip(i) <= d0;
            ip(i+1) <= d1;
            ip(i+2) <= d2;
            i:= i + 3;
        else enable = '1';
        end if;
    end process;

    -- mostragem
    process(clock, reset)
    variable ciclos: integer := 0;
    variable espera: unsigned(2 downto 0) := "00";
    begin
        if reset = '1' then
        elsif clock'event and clock = '1' then
            case estado is
                when inicial =>
                    if enable = '1' then
                        estado <= espera;
                    end if;
                when espera =>
                    if ciclos = 100000000 then
                        ciclos := 0;
                        if rotacao = "00" then
                            estado <= e1;
                        elsif rotacao = "01" then
                            estado <= e2;
                        elsif rotacao = "10" then
                            estado <= e3;
                        elsif rotacao = "11" then
                            estado <= e4;
                        end if;
                    end if;
                    ciclos := ciclos + 1;

                when e1 =>
                    estado <= espera;
                    rotacao := rotacao + 1;
                    disp0 <= ip_array(0);
                    disp1 <= ip_array(1);
                    disp2 <= ip_array(2);
                    ciclos := 0;

                when e2 =>
                    estado <= espera;
                    rotacao := rotacao + 1;
                    disp0 <= ip_array(3);
                    disp1 <= ip_array(4);
                    disp2 <= ip_array(5);
                    ciclos := 0;

                when e3 =>
                    estado <= espera;
                    rotacao := rotacao + 1;
                    disp0 <= ip_array(6);
                    disp1 <= ip_array(7);
                    disp2 <= ip_array(8);
                    ciclos := 0;

                when e4 =>
                    estado <= espera;
                    rotacao := "00";
                    disp0 <= ip_array(9);
                    disp1 <= ip_array(10);
                    disp2 <= ip_array(11);
                    ciclos := 0;
            end case;
        end if; 
    end process;
    
    -- displays

    --display0: display port map(disp0,d0);
    --display1: display port map(disp1,d1);
    --display2: display port map(disp2,d2);
    d0 <= disp0;
    d1 <= disp1;
    d2 <= disp2;
end central_arch;
