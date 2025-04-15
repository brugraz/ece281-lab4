--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2018 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : MooreElevatorController.vhd
--| AUTHOR(S)     : Capt Phillip Warner, Capt Dan Johnson, Capt Brian Yarbrough, ***YourName***
--| CREATED       : 03/2018 Last Modified on 06/24/2020
--| DESCRIPTION   : This file implements the ICE5 Basic elevator controller (Moore Machine)
--|
--|  The system is specified as follows:
--|   - The elevator controller will traverse four floors (numbered 1 to 4).
--|   - It has two external inputs, i_up_down and i_stop.
--|   - When i_up_down is active and i_stop is inactive, the elevator will move up 
--|			until it reaches the top floor (one floor per clock, of course).
--|   - When i_up_down is inactive and i_stop is inactive, the elevator will move down 
--|			until it reaches the bottom floor (one floor per clock).
--|   - When i_stop is active, the system stops at the current floor.  
--|   - When the elevator is at the top floor, it will stay there until i_up_down 
--|			goes inactive while i_stop is inactive.  Likewise, it will remain at the bottom 
--|			until told to go up and i_stop is inactive.  
--|   - The system should output the floor it is on (1 - 4) as a four-bit binary number.
--|   - i_reset synchronously puts the FSM into state Floor 2.
--|
--|		Inputs:   i_clk     --> elevator clk
--|				  i_reset   --> reset signal
--|				  i_stop	--> signal tells elevator to stop moving
--|				  i_up_down	--> signal controls elavotor 1=up, 0=down
--|
--|		Outputs:  o_floor (3:0)	--> 4-bit signal  indicating elevator's floor
--|  
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std, unisim
--|    Files     : None
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity elevator_controller_fsm is
    Port ( i_clk        : in  STD_LOGIC;
           i_reset      : in  STD_LOGIC;
           is_stopped   : in  STD_LOGIC;
           go_up_down   : in  STD_LOGIC;
           o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
end elevator_controller_fsm;

 
architecture Behavioral of elevator_controller_fsm is

    -- Below you create a new variable type! You also define what values that 
    -- variable type can take on. Now you can assign a signal as 
    -- "sm_floor" the same way you'd assign a signal as std_logic
	type sm_floor is (floor1, floor2, floor3, floor4, floor5, floor6, floor7, floor8);
	
	-- Here you create variables that can take on the values defined above. Neat!	
	signal current_floor, next_floor, top_floor, bottom_floor: sm_floor;

begin

	-- CONCURRENT STATEMENTS ------------------------------------------------------------------------------
	top_floor    <= floor8;
	bottom_floor <= floor1;
	
	-- Next State Logic            
  next_floor <=  current_floor                when is_stopped = '1' else
	               sm_floor'succ(current_floor) when ( go_up_down = '1' and current_floor /= top_floor ) else -- going up
	               sm_floor'pred(current_floor) when ( go_up_down = '0' and current_floor /= bottom_floor ) else -- going down
	               current_floor;
           
	-- Output logic
	with current_floor select
	o_floor <= x"1" when floor1,
	           x"2" when floor2,
	           x"3" when floor3,
	           x"4" when floor4,
	           x"5" when floor5,
	           x"6" when floor6,
	           x"7" when floor7,
	           x"8" when floor8,
	           x"0" when others;
    
	-------------------------------------------------------------------------------------------------------
	
	-- PROCESSES ------------------------------------------------------------------------------------------	
	
	-- State register ------------
	state_register : process(i_clk)
	begin
        if rising_edge(i_clk) then
           if i_reset = '1' then
               current_floor <= floor2;
           else
                current_floor <= next_floor;
            end if;
        end if;
	end process state_register;
	
	
	
	-------------------------------------------------------------------------------------------------------
	
	



end Behavioral;

