--test generale

-- TB EXAMPLE PFRL 2022-2023

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;

ENTITY heavy_test IS
END heavy_test;

ARCHITECTURE projecttb OF heavy_test IS
    CONSTANT CLOCK_PERIOD : TIME := 100 ns;
    SIGNAL tb_done : STD_LOGIC;
    SIGNAL mem_address : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_rst : STD_LOGIC := '0';
    SIGNAL tb_start : STD_LOGIC := '0';
    SIGNAL tb_clk : STD_LOGIC := '0';
    SIGNAL mem_o_data, mem_i_data : STD_LOGIC_VECTOR (7 DOWNTO 0);
    SIGNAL enable_wire : STD_LOGIC;
    SIGNAL mem_we : STD_LOGIC;
    SIGNAL tb_z0, tb_z1, tb_z2, tb_z3 : STD_LOGIC_VECTOR (7 DOWNTO 0);
    SIGNAL tb_w : STD_LOGIC;

    CONSTANT SCENARIOLENGTH : INTEGER := 199; -- 5 + 3 + 20 + 7   (RST) + (CH2-MEM[1]) + 20 CYCLES + (CH1-MEM[6])
    SIGNAL scenario_rst : unsigned(0 TO SCENARIOLENGTH - 1)     := "00110" & "00000000000" & "00000000000000000000" & "000000000" & "00000000000000000000" & "0000000000000" & "00000000000000000000" & "000000000000000" & "00000000000000000000" & "001" & "00000000000" & "00000000000000000000" & "000000000000" & "00100000000000000000";                                                 
    SIGNAL scenario_start : unsigned(0 TO SCENARIOLENGTH - 1)   := "00000" & "11111111111" & "00000000000000000000" & "111111111" & "00000000000000000000" & "1111111111111" & "00000000000000000000" & "111111111111111" & "00000000000000000000" & "111" & "11111111111" & "00000000000000000000" & "111111111111" & "00000000000000000000";
    SIGNAL scenario_w : unsigned(0 TO SCENARIOLENGTH - 1)       := "00000" & "10100011101" & "00000000000000000000" & "100111000" & "00000000000000000000" & "1100101001111" & "00000000000000000000" & "001110101110010" & "00000000000000000000" & "111" & "01110101010" & "00000000000000000000" & "111110101000" & "00000000000000000000";
    -- Channel 2 -> MEM[1] -> 162
    -- Channel 1 -> MEM[2] -> 75

    TYPE ram_type IS ARRAY (65535 DOWNTO 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL RAM : ram_type := (  285 => std_logic_vector(to_unsigned(93,8)),
                                56 => std_logic_vector(to_unsigned(77,8)),
                                335 => std_logic_vector(to_unsigned(32,8)),
                                7538 => std_logic_vector(to_unsigned(121,8)),
                                426 => std_logic_vector(to_unsigned(13,8)),
                                936 => std_logic_vector(to_unsigned(11,8)),
                                
                                OTHERS => "00000000"-- (OTHERS => '0')
                            );
                    
    COMPONENT project_reti_logiche IS
        PORT (
            i_clk : IN STD_LOGIC;
            i_rst : IN STD_LOGIC;
            i_start : IN STD_LOGIC;
            i_w : IN STD_LOGIC;

            o_z0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_z1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_z2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_z3 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_done : OUT STD_LOGIC;

            o_mem_addr : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_mem_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_mem_we : OUT STD_LOGIC;
            o_mem_en : OUT STD_LOGIC
        );
    END COMPONENT project_reti_logiche;

BEGIN
    UUT : project_reti_logiche
    PORT MAP(
        i_clk => tb_clk,
        i_start => tb_start,
        i_rst => tb_rst,
        i_w => tb_w,

        o_z0 => tb_z0,
        o_z1 => tb_z1,
        o_z2 => tb_z2,
        o_z3 => tb_z3,
        o_done => tb_done,

        o_mem_addr => mem_address,
        o_mem_en => enable_wire,
        o_mem_we => mem_we,
        i_mem_data => mem_o_data
    );


    -- Process for the clock generation
    CLK_GEN : PROCESS IS
    BEGIN
        WAIT FOR CLOCK_PERIOD/2;
        tb_clk <= NOT tb_clk;
    END PROCESS CLK_GEN;


    -- Process related to the memory
    MEM : PROCESS (tb_clk)
    BEGIN
        IF tb_clk'event AND tb_clk = '1' THEN
            IF enable_wire = '1' THEN
                IF mem_we = '1' THEN
                    RAM(conv_integer(mem_address)) <= mem_i_data;
                    mem_o_data <= mem_i_data AFTER 1 ns;
                ELSE
                    mem_o_data <= RAM(conv_integer(mem_address)) AFTER 1 ns; 
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    -- This process provides the correct scenario on the signal controlled by the TB
    createScenario : PROCESS (tb_clk)
    BEGIN
        IF tb_clk'event AND tb_clk = '0' THEN
            tb_rst <= scenario_rst(0);
            tb_w <= scenario_w(0);
            tb_start <= scenario_start(0);
            scenario_rst <= scenario_rst(1 TO SCENARIOLENGTH - 1) & '0';
            scenario_w <= scenario_w(1 TO SCENARIOLENGTH - 1) & '0';
            scenario_start <= scenario_start(1 TO SCENARIOLENGTH - 1) & '0';
        END IF;
    END PROCESS;

    -- Process without sensitivity list designed to test the actual component.
    testRoutine : PROCESS IS
    BEGIN
        mem_i_data <= "00000000";
        -- wait for 10000 ns;
        WAIT UNTIL tb_rst = '1';
        WAIT UNTIL tb_rst = '0';
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (postreset Z0) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (postreset Z1) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (postreset Z2) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (postreset Z3) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        WAIT UNTIL tb_start = '1';
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (poststart Z0) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (poststart Z1) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (poststart Z2) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (poststart Z3) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        WAIT UNTIL tb_done = '1';
        --WAIT UNTIL rising_edge(tb_clk);
        WAIT FOR CLOCK_PERIOD/2;
        ASSERT tb_z2 = std_logic_vector(to_unsigned(93, 8))  REPORT "TEST FALLITO (Z2 ---) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure;
        WAIT UNTIL tb_done = '0';
        wait for clock_period/2;
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (postdone Z0) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (postdone Z1) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (postdone Z2) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (postdone Z3) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        WAIT UNTIL tb_start = '1';
        WAIT UNTIL tb_done = '1';
        --WAIT UNTIL rising_edge(tb_clk);
        WAIT FOR CLOCK_PERIOD/2;
        ASSERT tb_z2 = std_logic_vector(to_unsigned(77, 8))  REPORT "TEST FALLITO (Z2 ---) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure;
        
        wait until tb_start='1';
        wait until tb_done='1';
        wait for clock_period/2;
        ASSERT tb_z2 = std_logic_vector(to_unsigned(77, 8))  REPORT "TEST FALLITO (Z2 ---) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = std_logic_vector(to_unsigned(32, 8))  REPORT "TEST FALLITO (Z3 ---) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        wait until tb_start='1';
        wait until tb_done='1';
        wait for clock_period/2;
        ASSERT tb_z2 = std_logic_vector(to_unsigned(77, 8))  REPORT "TEST FALLITO (Z2 ---) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = std_logic_vector(to_unsigned(32, 8))  REPORT "TEST FALLITO (Z3 ---) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        ASSERT tb_z0 = std_logic_vector(to_unsigned(121, 8))  REPORT "TEST FALLITO (Z0 ---) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure;
        wait until tb_rst='1';
        wait until tb_rst='0';
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (postdone Z) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (postdone Z) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (postdone Z) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (postdone Z) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        wait until tb_done='1';
        wait for clock_period/2;
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (postdone Z) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = std_logic_vector(to_unsigned(13, 8)) REPORT "TEST FALLITO (postdone Z1) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (postdone Z) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (postdone Z) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        wait until tb_start='1';
        wait until tb_rst='1';
        wait until tb_rst='0';
        for i in 0 to 16 loop
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (postdone Z) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (postdone Z) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (postdone Z) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (postdone Z) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        wait for clock_period;
        end loop;
        
        
        ASSERT false REPORT "Simulation Ended! TEST PASSATO (EXAMPLE)" SEVERITY failure;
    END PROCESS testRoutine;

END projecttb;