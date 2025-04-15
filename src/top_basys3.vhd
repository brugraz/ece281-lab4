library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

-- Lab 4
entity top_basys3 is
  port(
    -- inputs
    clk     :   in std_logic; -- native 100MHz FPGA clock
    sw      :   in std_logic_vector(15 downto 0);
    btnU    :   in std_logic; -- master_reset
    btnL    :   in std_logic; -- clk_reset
    btnR    :   in std_logic; -- fsm_reset
    
    -- outputs
    led :   out std_logic_vector(15 downto 0);
    -- 7-segment display segments (active-low cathodes)
    seg :   out std_logic_vector(6 downto 0);
    -- 7-segment display active-low enables (anodes)
    an  :   out std_logic_vector(3 downto 0)
  );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

  component sevenseg_decoder is
    port (
      i_Hex   : in  STD_LOGIC_VECTOR (3 downto 0);
      o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
    );
  end component sevenseg_decoder;
  
  component elevator_controller_fsm is
    generic (constant k_div : natural := 25000000); -- 2Hz
    port (
      i_clk        : in  STD_LOGIC;
      i_reset      : in  STD_LOGIC;
      is_stopped   : in  STD_LOGIC;
      go_up_down   : in  STD_LOGIC;
      o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
     );
    end component elevator_controller_fsm;
	
	component TDM4 is
		generic(
		  constant k_WIDTH : natural  := 4;
		  constant k_div   : natural  := 100000
		);
    port(i_clk		: in  STD_LOGIC;
         i_reset	: in  STD_LOGIC; -- asynchronous
         i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
         i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
         i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
         i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
         o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
         o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
    generic (constant k_div : natural := 2); -- basys/2
    port ( 	i_clk    : in std_logic;
            i_reset  : in std_logic;		   -- asynchronous
            o_clk    : out std_logic		   -- divided (slow) clock
    );
  end component clock_divider;
  
  constant k_div_fsm  : natural := 25000000;
  constant k_div_tdm  : natural := 50000;
  constant k_IO_width : natural := 4;
  
  constant k_floorsym : std_logic_vector := x"F"; -- floor symbol
  
  -- in
  signal w_mas_res : std_logic;
  signal w_fsm_res : std_logic;
  signal w_clk_res : std_logic;
  signal w_sw      : std_logic_vector(15 downto 0);
  
  -- component -> component
  signal w_clk_b3  : std_logic;
  signal w_clk_fsm : std_logic;
  signal w_clk_tdm : std_logic;
  signal w_fl_el1  : std_logic_vector(k_IO_width - 1 downto 0);
  signal w_fl_el2  : std_logic_vector(k_IO_width - 1  downto 0);
  signal w_hex     : std_logic_vector(k_IO_width - 1  downto 0);
  
  -- out
  signal w_led     : std_logic_vector(15 downto 0); -- for readability but just connected to w_seg
  signal w_seg     : std_logic_vector(6  downto 0);
  signal w_an      : std_logic_vector(k_IO_width - 1  downto 0);
	
begin
	-- PORT MAPS ----------------------------------------
  sevenseg_decoder_inst : sevenseg_decoder
  port map (
    i_Hex   => w_hex,
    o_seg_n => w_seg
  );
  
  elevator_1 : elevator_controller_fsm
  generic map(k_div => k_div_fsm)
  port map (
    i_clk      => w_clk_fsm,
    i_reset    => w_fsm_res,
    is_stopped => w_sw(0),
    go_up_down => w_sw(1),
    o_floor    => w_fl_el1    
  );
  
  elevator_2 : elevator_controller_fsm
  generic map(k_div => k_div_fsm)
  port map (
    i_clk      => w_clk_fsm,
    i_reset    => w_fsm_res,
    is_stopped => w_sw(14),
    go_up_down => w_sw(15),
    o_floor    => w_fl_el2
  );
  
  tdm4_inst : tdm4
  generic map(
    k_WIDTH => k_IO_width,
    k_div   => k_div_tdm
    )
  port map (
    i_clk   => w_clk_tdm,
    i_reset => w_mas_res,
    i_D3    => k_floorsym, -- F
    i_D2    => w_fl_el1,   -- #
    i_D1    => k_floorsym, -- F
    i_D0    => w_fl_el2,   -- #
    o_data  => w_hex,
    o_sel   => w_an
  );
  
  clock_divider_fsm : clock_divider
  generic map(k_div => k_div_fsm)
  port map (
    i_clk   => w_clk_b3,
    i_reset => w_clk_res,
    o_clk   => w_clk_fsm
  );
    
  clock_divider_tdm : clock_divider
  generic map(k_div => k_div_tdm)
  port map (
    i_clk   => w_clk_b3,
    i_reset => w_clk_res,
    o_clk   => w_clk_tdm
  );
	-- CONCURRENT STATEMENTS ----------------------------
  w_clk_b3  <= clk;
  -- in
  w_mas_res <= btnU;
  w_clk_res <= btnU or btnL; -- master included
  w_fsm_res <= btnU or btnR; -- master included
  w_sw(0)	  <= sw(0);
  w_sw(1)	  <= sw(1);
  w_sw(14)	<= sw(14);
  w_sw(15)	<= sw(15);
  -- out
  seg     <= w_seg;     -- display
  an      <= w_an;
  led(15) <= w_clk_fsm; -- signify clk
	led(14 downto 0) <= "000000000000000"; -- GND
	
	--from master constraint file
	-- remember resets OR with the master
	
	-- LED 15 gets the FSM slow clock signal. The rest are grounded.
	
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	
	-- reset signals
	
end top_basys3_arch;
