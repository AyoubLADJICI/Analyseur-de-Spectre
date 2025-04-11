library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity i2s is
    port( 
        clk : in std_logic;
        rst : in std_logic;

        --côté Dongle Pmod 
        mclk : out std_logic; --master clock, 
        sclk : out std_logic; -- serial clock, fully toggles once per 8 MCLK periods
        lrclk : out std_logic; --canal gauche ou droit, fully toggles once per 64 SCLK periods.
        sdin : in std_logic; --donnée en sortie du dongle

        --côté axis
        tvalid : out std_logic; --données valides à envoyer
        tready : in std_logic; --dma prêt à recevoir
        tlast : out std_logic; --facultatif
        tdata : out std_logic_vector(31 downto 0)
    );
end entity i2s; 

architecture RTL of i2s is
    signal compteur : std_logic_vector(8 downto 0) := (others => '0'); --Division d'holorge par 512 au max (filtre du 8ème bit)
    signal div512 : std_logic; --pour lrck : clk/(2³) = 8
    signal div8 : std_logic; --pour sclk :clk/(2⁹) = 512
    signal sclk_i, lrclk_i, tvalid_i : std_logic;
    signal data_i2s : std_logic_vector(23 downto 0);
    signal tdata_out_i : std_logic_vector(31 downto 0);
    signal valid_i2s : std_logic := '0';
    signal i : integer := 0;


begin
    
    div512 <= compteur(8);
    div8 <= compteur(2);

    compteur_process : process(clk, rst) --sensibilité à clk + qu'est ce qu'il se passe quand on a pas de front montant de clk
    begin
        if rst = '1' then 
            compteur <= (others => '0');
        elsif rising_edge(clk) then
            if compteur = "111111111" then 
                compteur <= (others => '0');
            else
                compteur <= std_logic_vector(unsigned(compteur) + 1); 
            end if;
        end if;
    end process;

    i2s_process_i: process(clk, rst)
    variable sclk_prev : std_logic := '0';
    variable bit_count : integer range 0 to 23 := 0;
    begin
        if rst = '1' then
            sclk_i <= '0';
            lrclk_i <= '0';
            bit_count := 0;
            valid_i2s <= '0';
            data_i2s <= (others => '0');
            sclk_prev := '0';
        elsif rising_edge(clk) then
            sclk_i <= div8;
            lrclk_i <= div512;
            
            -- Réinitialiser valid_i2s uniquement après que les données ont été traitées
            if valid_i2s = '1' and tvalid_i = '1' and tready = '1' then
                valid_i2s <= '0';
            end if;
            
            -- Échantillonnage sur front montant de sclk
            if sclk_prev = '0' and div8 = '1' then
                -- Collecter les bits dans un registre à décalage
                data_i2s <= data_i2s(22 downto 0) & sdin;
                
                -- Incrémenter le compteur de bits
                if bit_count = 23 then
                    bit_count := 0;
                    valid_i2s <= '1';  -- Un mot complet a été reçu
                else
                    bit_count := bit_count + 1;
                end if;
            end if;
            
            -- Mémoriser l'état précédent
            sclk_prev := div8;
        end if;
    end process;

    --intégrer les signaux valid, tvalid, tready, tlast
    axis_process_i : process(clk, rst)  --sûr des sensibilités ?, valid_i2s pas dedans ? 
    begin 
    if rst = '1' then
        tdata_out_i <= (others => '0'); --écriture ?
        tvalid_i <= '0';

    elsif rising_edge(clk) then
        -- Désactiver tvalid quand tready confirme la réception
        if tvalid_i = '1' and tready = '1' then
            tvalid_i <= '0';
        end if;
        
        -- Envoyer de nouvelles données quand valid_i2s est actif
        if valid_i2s = '1' and tvalid_i = '0' then
            tdata_out_i <= "0000000" & lrclk_i & data_i2s;  -- Utiliser lrclk pour l'info de canal
            tvalid_i <= '1';
        end if;
    end if;

    end process;

    
    --i2s
    mclk <= clk; --22.5792 MHz
    lrclk <= lrclk_i;-- 44.1KHz
    sclk <=  sclk_i; -- 64*f(lrclk)  

    --axis
    tdata <= tdata_out_i;
    tvalid <= tvalid_i;
    tlast <= '0';
   


end architecture;



-- Explication des modifications
-- J'ai séparé le code en deux processus distincts :

-- i2s_receive_bits :

-- S'occupe de la réception bit par bit du signal I2S
-- Échantillonne les données sur le front descendant de SCLK
-- Stocke les bits dans un registre à décalage
-- Détecte les changements de canal (transitions LRCLK)
-- Génère le signal frame_ready lorsqu'un mot de 24 bits complet est reçu
-- axi_stream_send :

-- S'occupe uniquement de l'interface AXI Stream
-- Attend que frame_ready soit activé
-- Prépare le format des données (7 bits à '0' + 1 bit de canal + 24 bits de données)
-- Gère le handshaking AXI Stream (tvalid/tready)
-- Cette séparation des responsabilités rend le code plus modulaire et plus facile à comprendre, tout en préservant la fonctionnalité complète de l'IP I2S.




--- Code fonctionnel

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2s is
    port( 
        clk : in std_logic;   -- Horloge système (22.5792 MHz)
        rst : in std_logic;   -- Reset système actif à '1'

        -- Interface I2S (côté Dongle Pmod)
        mclk : out std_logic; -- Master clock (22.5792 MHz)
        sclk : out std_logic; -- Serial clock (clk/8 = 2.8224 MHz) 
        lrclk : out std_logic; -- Left/Right clock (sclk/64 = 44.1 kHz)
        sdin : in std_logic;  -- Serial data in

        -- Interface AXI-Stream
        tvalid : out std_logic;
        tready : in std_logic;
        tlast : out std_logic;
        tdata : out std_logic_vector(31 downto 0)
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
    signal channel : std_logic := '0';  -- 0 = gauche, 1 = droit
    signal collecting_bits : std_logic := '0'; -- Indique si nous sommes en train de collecter des bits
    
    -- Signaux pour l'interface AXI Stream
    signal data_ready : std_logic := '0';  -- Indique qu'une donnée est prête pour l'AXI Stream
    signal tdata_reg : std_logic_vector(31 downto 0) := (others => '0');
    signal tvalid_reg : std_logic := '0';
    
begin
   
    clock_gen: process(clk, rst)
    begin
        if rst = '1' then
            counter <= (others => '0');
            sclk_i <= '0';
            lrclk_i <= '0';
        elsif rising_edge(clk) then
            -- Incrémenter le compteur
            counter <= counter + 1;
            
            -- Génération de SCLK (div par 8): bit 2 = /8
            sclk_i <= counter(2);
            
            -- Génération de LRCLK (div par 512): bit 8 = /512 (/8 * /64)
            lrclk_i <= counter(8);
        end if;
    end process;
    
    
    i2s_receive: process(clk, rst)
    variable lrclk_changed : boolean;
    begin
        if rst = '1' then
            sclk_prev <= '0';
            lrclk_prev <= '0';
            bit_counter <= 0;
            collecting_bits <= '0';
            data_shift_reg <= (others => '0');
            channel <= '0';
            data_ready <= '0';
        elsif rising_edge(clk) then
            -- Détecter le changement de LRCLK d'abord
            lrclk_changed := (lrclk_i /= lrclk_prev);
            
            -- Mémoriser les états précédents des horloges
            sclk_prev <= sclk_i;
            lrclk_prev <= lrclk_i;
            
            -- Réinitialiser data_ready après prise en compte
            if data_ready = '1' and tvalid_reg = '0' then
                data_ready <= '0';
            end if;
            
            -- Traiter le changement de canal en priorité
            if lrclk_changed then                
                channel <= lrclk_i;
                bit_counter <= 0;  -- Réinitialiser le compteur pour le nouveau canal
                collecting_bits <= '1';  -- Commencer à collecter des bits
            end if;
            
            -- Échantillonnage des données sur le front descendant de SCLK
            -- Le front est détecté lorsque sclk_prev='1' et sclk_i='0'
            if sclk_prev = '1' and sclk_i = '0' then
                -- Toujours décaler les bits dans le registre
                data_shift_reg <= data_shift_reg(22 downto 0) & sdin;
                
                -- N'incrémenter le compteur que si nous collectons des bits
                if collecting_bits = '1' then
                    -- Incrémenter le compteur de bits
                    if bit_counter <= 23 then
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
    
    axi_stream: process(clk, rst)
    begin
        if rst = '1' then
            tdata_reg <= (others => '0');
            tvalid_reg <= '0';
        elsif rising_edge(clk) then
            -- Si des données sont prêtes et qu'on n'est pas déjà en train d'envoyer
            if data_ready = '1' and tvalid_reg = '0' then
                -- Format: 7 bits à '0' + 1 bit de canal + 24 bits de données
                tdata_reg <= "0000000" & channel & data_shift_reg;
                tvalid_reg <= '1';
                
                -- Si l'envoi est confirmé, désactiver tvalid
            elsif tvalid_reg = '1' and tready = '1' then
                tvalid_reg <= '0';
                
            end if;
        end if;
    end process;
    
    -- Connexion des signaux de sortie
    mclk <= clk;
    sclk <= sclk_i;
    lrclk <= lrclk_i;
    tdata <= tdata_reg;
    tvalid <= tvalid_reg;
    tlast <= '0';  -- Non utilisé dans cette implémentation
    
end architecture RTL;