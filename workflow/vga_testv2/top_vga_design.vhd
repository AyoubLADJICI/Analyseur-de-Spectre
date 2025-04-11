library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--use xil_defaultlib.clk_wiz_0;  -- parfois optionnel, dépend du contexte

entity top_vga is
    Port (
        clk100MHz       : in  STD_LOGIC;  -- 100 MHz
        --reset     : in  STD_LOGIC;
        hsync     : out STD_LOGIC;
        vsync     : out STD_LOGIC;
        red       : out STD_LOGIC_VECTOR(3 downto 0);
        green     : out STD_LOGIC_VECTOR(3 downto 0);
        blue      : out STD_LOGIC_VECTOR(3 downto 0)
        
        -- AXI Stream Input from DMA
        --tdata      : in STD_LOGIC_VECTOR(31 downto 0);  -- 32 bits
        --tvalid     : in STD_LOGIC;
        --tlast      : in STD_LOGIC;
        --tready     : out STD_LOGIC
    );
end top_vga;

architecture Structural of top_vga is

    signal pixel_x    : STD_LOGIC_VECTOR(10 downto 0);
    signal pixel_y_int: STD_LOGIC_VECTOR(9 downto 0);
    signal video_on   : STD_LOGIC;
    signal clk65MHz : std_logic;
    --signal clk100MHz : std_logic;
    
    -- Signaux AXI simulés en interne pour le test
    signal tdata_test  : STD_LOGIC_VECTOR(31 downto 0) := x"00000F0F";
    signal tvalid_test : STD_LOGIC := '1';
    signal tlast_test  : STD_LOGIC := '0';
    signal tready_test : STD_LOGIC;


begin
    -- Instance du bloc qui convertit 100 MHz en 65 MHz
    bd_wrapper_inst: entity work.vga_bd_wrapper
        port map(
            clk100MHz => clk100MHz,
            clk65MHz => clk65MHz
        );
    -- Contrôleur VGA : fournit hsync, vsync, video_on, pixel_x/y
    vga_ctrl : entity work.vga_controller
        port map (
            clk      => clk65MHz,
            --reset    => reset,
            hsync    => hsync,
            vsync    => vsync,
            video_on => video_on,
            pixel_x  => pixel_x,
            pixel_y  => pixel_y_int
        );

    -- Générateur de couleurs VGA (reçoit AXI + coordonnées)
    vga_gen : entity work.vga_pattern
        port map (
            pixel_x  => pixel_x,
            pixel_y  => pixel_y_int,
            video_on => video_on,
            red      => red,
            green    => green,
            blue     => blue,
    
            tdata    => tdata_test,
            tvalid   => tvalid_test,
            tready   => tready_test,
            tlast    => tlast_test

            --tdata    => tdata(11 downto 0), -- on garde les 12 bits RGB
            --tvalid   => tvalid,
            --tready   => tready,
            --tlast    => tlast
        );
        
    -- Simulation d'une zone avec flux AXI actif (quart supérieur gauche)
   process(pixel_x, pixel_y_int)
    begin
        if to_integer(unsigned(pixel_x)) < 100 or
           to_integer(unsigned(pixel_x)) > 924 or
           to_integer(unsigned(pixel_y_int)) < 100 or
           to_integer(unsigned(pixel_y_int)) > 668 then
            tvalid_test <= '1'; -- Cadre
        else
            tvalid_test <= '0'; -- Centre
        end if;
    end process;

    



    -- Connexion du signal interne à la sortie
    --pixel_y <= pixel_y_int;

end Structural;
