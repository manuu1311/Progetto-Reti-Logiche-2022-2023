library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;
USE std.textio.ALL;


entity project_reti_logiche is
port (
i_clk : in std_logic;
i_rst : in std_logic;
i_start : in std_logic;
i_w : in std_logic;
o_z0 : out std_logic_vector(7 downto 0);
o_z1 : out std_logic_vector(7 downto 0);
o_z2 : out std_logic_vector(7 downto 0);
o_z3 : out std_logic_vector(7 downto 0);
o_done : out std_logic;
o_mem_addr : out std_logic_vector(15 downto 0);
i_mem_data : in std_logic_vector(7 downto 0);
o_mem_we : out std_logic;
o_mem_en : out std_logic
);
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
	type state_type is (idle,capture,memory);
	
	signal state_curr,state_next : state_type;
	signal num,num_next : integer range 0 to 17;
	signal intestazione: std_logic_vector(1 downto 0);
	signal address: std_logic_vector(15 downto 0);
	signal mem_done, mem_done_next : boolean;
	signal o_done_next: std_logic;
	signal o_z0_next,o_z1_next,o_z2_next,o_z3_next : std_logic_vector(7 downto 0);
	signal o_en_next,o_we_next : std_logic;
	signal rst_sig : boolean;

begin
	reset: process(i_clk,i_rst)	
	begin
		if (i_rst='1') then
			o_z0<="00000000";
			o_z1<="00000000";
			o_z2<="00000000";
			o_z3<="00000000";			
			o_done<='0';
			mem_done<=false;
			state_curr<=idle;
			rst_sig<=true;
        else
            if (rst_sig=false) then
                state_curr<=state_next;
                num<=num_next;
            end if;
            if (rising_edge(i_clk)) then
                rst_sig<=false;
                mem_done<=mem_done_next;
                o_z0<=o_z0_next;
                o_z1<=o_z1_next;
                o_z2<=o_z2_next;
                o_z3<=o_z3_next;
                o_mem_en<=o_en_next;
                o_mem_we<=o_we_next;
                o_done<=o_done_next;
			    end if;
		end if;
	end process;
	
	fsm: process(i_clk,rst_sig)
        variable o_z0_mem,o_z1_mem,o_z2_mem,o_z3_mem : std_logic_vector(7 downto 0);
        variable address_temp : std_logic_vector(15 downto 0);
		begin
		if (rst_sig=true) then
		  o_z0_mem:="00000000";
		  o_z1_mem:="00000000";
		  o_z2_mem:="00000000";
		  o_z3_mem:="00000000";
		end if;	
		if (rising_edge(i_clk)) then
		o_z0_next<="00000000";
		o_z1_next<="00000000";
		o_z2_next<="00000000";
		o_z3_next<="00000000";
		o_done_next<='0';
		mem_done_next<=mem_done;
		state_next<=state_curr;
			case state_curr is
				when idle =>
					num_next<=1;
					address_temp:="0000000000000000";
					intestazione<="00";
					mem_done_next<=false;
					o_en_next<='0';
					o_we_next<='0';
					if (i_start='1') then
					    intestazione(1)<=i_w;
						state_next<=capture;
						num_next<=1;
					end if;
				
				when capture =>
					if (i_start='1') then
						if (num<2) then
							intestazione(0)<=i_w;
						else
							address_temp(17-num):=i_w;
						end if;						
						num_next<=num+1;
						state_next<=capture;
					elsif (i_start='0') then
					    o_mem_addr<=std_logic_vector(shift_right(unsigned(address_temp),18-num));
						o_en_next<='1';
						o_we_next<='0';
						state_next<=memory;
						num_next<=1;
					end if;
					
				when memory =>
				    if (mem_done=true) then
					o_en_next<='0';
					mem_done_next<=false;
					state_next<=idle;
                    if (intestazione="00") then
                        o_z0_mem:=i_mem_data;
                    elsif (intestazione="01") then
                        o_z1_mem:=i_mem_data;
                    elsif (intestazione="10") then
                        o_z2_mem:=i_mem_data;
                    elsif (intestazione="11") then
                        o_z3_mem:=i_mem_data;
                    end if;
                    o_z0_next<=o_z0_mem;
                    o_z1_next<=o_z1_mem;
                    o_z2_next<=o_z2_mem;
                    o_z3_next<=o_z3_mem;
                    o_done_next<='1';
					else
					mem_done_next<=true;
					state_next<=memory;
					end if;			
			end case;
        end if;
	end process;
end Behavioral;