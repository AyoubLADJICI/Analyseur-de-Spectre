library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2s_tb is
end entity i2s_tb;

architecture behavioral of i2s_tb is
    -- Constantes de test
    constant CLK_PERIOD : time := 44.293 ns; -- ~22.5792 MHz
    constant SIM_TIME   : time := 50000000 ns;  -- Temps total de simulation
    
    -- Signaux pour l'UUT (Unit Under Test)
    signal I2S_clk      : std_logic := '0';
    signal I2S_rst      : std_logic := '1';
    signal mclk     : std_logic;
    signal sclk     : std_logic;
    signal lrclk    : std_logic;
    signal sdin     : std_logic := '0';
    signal I2S_axis_valid   : std_logic;
    signal I2S_axis_ready   : std_logic := '1'; -- DMA toujours prêt à recevoir par défaut
    signal I2S_axis_last    : std_logic;
    signal I2S_axis_data    : std_logic_vector(31 downto 0);
    
    signal sim_done : boolean := false;
    
    -- Motifs de test distincts pour les canaux gauche et droit
    signal test_pattern_left  : std_logic_vector(23 downto 0) := x"A5B6C7"; -- motif pour canal gauche
    signal test_pattern_right : std_logic_vector(23 downto 0) := x"123456"; -- motif pour canal droit
    
    -- Variables de contrôle pour la génération de données
    signal bit_index : integer range 0 to 31 := 0;
    
begin
    -- Instanciation du module I2S (Unit Under Test)
    uut: entity work.i2s
        port map (
            I2S_clk     => I2S_clk,
            I2S_rst     => I2S_rst,
            mclk    => mclk,
            sclk    => sclk,
            lrclk   => lrclk,
            sdin    => sdin,
            I2S_axis_valid  => I2S_axis_valid,
            I2S_axis_ready  => I2S_axis_ready,
            I2S_axis_last   => I2S_axis_last,
            I2S_axis_data   => I2S_axis_data
        );
    
    -- Génération de l'horloge principale
    clk_process: process
    begin
        while not sim_done loop
            I2S_clk <= '0';
            wait for CLK_PERIOD/2;
            I2S_clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    -- Processus de test principal
    stim_proc: process
    begin
        -- Reset initial
        I2S_rst <= '1';
        wait for 1063 ns;
        I2S_rst <= '0';
        
        wait for SIM_TIME;
        
        sim_done <= true;
        wait;
    end process;
    
    -- Processus de génération des données SDIN
    sdin_gen_process: process
        variable last_lrclk : std_logic := '0';
        variable first_bit : boolean := true;
    begin
        wait until falling_edge(sclk);
        
        -- Détection des transitions de LRCLK
        if lrclk /= last_lrclk then
            bit_index <= 0;        -- Réinitialiser l'index de bit
            first_bit := true;     -- Marquer le premier bit
            last_lrclk := lrclk;   -- Mettre à jour le dernier LRCLK
            sdin <= '0';           -- En I2S, le premier bit après une transition LRCLK est ignoré
        elsif first_bit then
            -- Ignorer le premier bit après la transition de LRCLK (protocole I2S)
            first_bit := false;
            sdin <= '0';
        else
            -- Sélectionner le bon motif selon le canal actif
            if lrclk = '0' then
                -- Canal gauche (LRCLK = 0)
                sdin <= test_pattern_left(23 - bit_index);
            else
                -- Canal droit (LRCLK = 1)
                sdin <= test_pattern_right(23 - bit_index);
            end if;
            
            -- Incrémenter l'index du bit, avec retour à zéro si dépassement
            if bit_index < 23 then
                bit_index <= bit_index + 1;
            else
                bit_index <= 0;
            end if;
        end if;
    end process;

    
    
    
end architecture behavioral;