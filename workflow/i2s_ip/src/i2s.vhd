library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2s is
    port( 
        I2S_clk : in std_logic;   -- Horloge système (22.5792 MHz)
        I2S_rst : in std_logic;   -- Reset système actif à '1'

        -- Interface I2S (côté Dongle Pmod)
        mclk : out std_logic; -- Master clock (22.5792 MHz)
        sclk : out std_logic; -- Serial clock (clk/8 = 2.8224 MHz) 
        lrclk : out std_logic; -- Left/Right clock (sclk/64 = 44.1 kHz) : 0 -> left, 1 -> right
        sdin : in std_logic;  -- Serial data in

        -- Interface AXI-Stream
        I2S_axis_valid : out std_logic;
        I2S_axis_ready : in std_logic;
        I2S_axis_last : out std_logic;
        I2S_axis_data : out std_logic_vector(31 downto 0)
    );
end entity i2s; 

architecture RTL of i2s is
    -- Compteur pour la génération d'horloge
    signal counter : unsigned(8 downto 0) := (others => '0');
    
    -- Signaux internes d'horloge
    signal sclk_i : std_logic := '0';
    signal lrclk_i : std_logic := '0';
    
    -- État précédent pour détection des fronts
    signal sclk_prev : std_logic := '0';
    signal lrclk_prev : std_logic := '0';
    
    -- Registres pour la capture des données
    signal bit_counter : integer range 0 to 31 := 0;
    signal data_shift_reg : std_logic_vector(23 downto 0) := (others => '0');
    signal collecting_bits : std_logic := '0'; -- Indique si nous sommes en train de collecter des bits
    
    -- Signaux pour l'interface AXI Stream
    signal data_ready : std_logic := '0';  -- Indique qu'une donnée est prête pour l'AXI Stream
    signal tdata_reg : std_logic_vector(31 downto 0) := (others => '0');
    signal tvalid_reg : std_logic := '0';
    signal tlast_reg : std_logic := '0';

    -- Compteur pour la génération de tlast
    signal packet_counter : unsigned(9 downto 0) := (others => '0'); -- Peut compter jusqu'à 1024
    
    
begin
   
    clock_gen: process(I2S_clk, I2S_rst)
    begin
        if I2S_rst = '1' then
            counter <= (others => '0');
            sclk_i <= '0';
            lrclk_i <= '0';
        elsif rising_edge(I2S_clk) then
            -- Incrémenter le compteur
            counter <= counter + 1;
            
            -- Génération de SCLK (div par 8): bit 2 = /8
            sclk_i <= counter(2);
            
            -- Génération de LRCLK (div par 512): bit 8 = /512 (/8 * /64)
            lrclk_i <= counter(8);
        end if;
    end process;
    
    
    i2s_receive: process(I2S_clk, I2S_rst)
    begin
        if I2S_rst = '1' then
            sclk_prev <= '0';
            lrclk_prev <= '0';
            bit_counter <= 0;
            collecting_bits <= '0';
            data_shift_reg <= (others => '0');
            data_ready <= '0';

        elsif rising_edge(I2S_clk) then            
            -- Mémoriser les états précédents des horloges
            sclk_prev <= sclk_i;
            lrclk_prev <= lrclk_i;
            
            -- Réinitialiser data_ready après prise en compte
            if data_ready = '1' and tvalid_reg = '0' then
                data_ready <= '0';
            end if;
            
            -- Traiter le changement de canal en priorité
            if lrclk_i /= lrclk_prev then                
                bit_counter <= 0;  -- Réinitialiser le compteur pour le nouveau canal
                collecting_bits <= '1';  -- Commencer à collecter des bits
            end if;
            
            -- Échantillonnage des données sur le front descendant de SCLK
            if sclk_prev = '1' and sclk_i = '0' then
                -- Toujours décaler les bits dans le registre
                data_shift_reg <= data_shift_reg(22 downto 0) & sdin;
                
                -- N'incrémenter le compteur que si nous collectons des bits
                if collecting_bits = '1' then
                    -- Incrémenter le compteur de bits
                    if bit_counter <= 23 then -- <= sinon décalage entre compte de bit et index
                        bit_counter <= bit_counter + 1;
                        
                    else
                        -- Un mot complet de 24 bits est capturé
                        bit_counter <= 0;
                        collecting_bits <= '0';  -- Arrêter de collecter des bits jusqu'au prochain changement de LRCLK
                        data_ready <= '1';  -- Signaler que les données sont prêtes
                        
                    end if;
                end if;
            end if;
        end if;
    end process;
    

    axi_stream: process(I2S_clk, I2S_rst)
    begin
        if I2S_rst = '1' then
            tdata_reg <= (others => '0');
            tvalid_reg <= '0';
            tlast_reg <= '0';
            packet_counter <= (others => '0');

        elsif rising_edge(I2S_clk) then
            -- Par défaut, tlast est inactif
            tlast_reg <= '0';

            -- Si des données sont prêtes et qu'on n'est pas déjà en train d'envoyer
            if data_ready = '1' and tvalid_reg = '0' then
                -- Format: 7 bits à '0' + 1 bit de canal + 24 bits de données
                tdata_reg <= "0000000" & lrclk_i & data_shift_reg;
                tvalid_reg <= '1';

                -- Vérifier si on doit activer tlast (tous les 512 paquets)
                if packet_counter = 511 then
                    tlast_reg <= '1';
                end if;
                
            -- Si l'envoi est confirmé, désactiver I2S_axis_valid
            elsif tvalid_reg = '1' and I2S_axis_ready = '1' then
                tvalid_reg <= '0';

                -- Incrémenter le compteur de paquets
                if packet_counter = 511 then
                    packet_counter <= (others => '0'); -- Réinitialiser après 512 paquets
                else
                    packet_counter <= packet_counter + 1;
                end if;
                
            end if;
        end if;
    end process;
    
    -- Connexion des signaux de sortie
    mclk <= I2S_clk;
    sclk <= sclk_i;
    lrclk <= lrclk_i;
    I2S_axis_data <= tdata_reg;
    I2S_axis_valid <= tvalid_reg;
    I2S_axis_last <= tlast_reg;  -- Non utilisé dans cette implémentation
    
end architecture RTL;