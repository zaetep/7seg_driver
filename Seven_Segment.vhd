-- Author: Kaden Downes
-- This file describes a seven segment display with a variable number of digits. It takes a DATA vector and uses a multiplexer to display the data as a number.

library IEEE;
use     ieee.std_logic_1164.all;

-----------------------
entity SEVEN_SEGMENT is
-----------------------
    generic ( DIGITS    : natural := 8 );                               -- number of digits in the display
    port    ( RESET     : in  std_logic;                                -- active high master reset
              CLOCK     : in  std_logic;                                -- master clock
              ENABLE    : in  std_logic;                                -- clock enable
              CLEAR     : in  std_logic;                                -- synchronous clear
              BLANKING  : in  std_logic;                                -- leading 0 blanking control
              DATA      : in  std_logic_vector (4*DIGITS-1 downto 0);   -- display value
              DP        : in  std_logic_vector   (DIGITS-1 downto 0);   -- decimal point enable for each digit
              DIGIT     : out std_logic_vector   (DIGITS-1 downto 0);   -- 7-segment digit enable
              SEGMENT   : out std_logic_vector          (7 downto 0));  -- 7-segment segment enable
end SEVEN_SEGMENT;

------------------------------------
architecture RTL of SEVEN_SEGMENT is
------------------------------------
    function To_Segment (DATA : std_logic_vector (3 downto 0)) return std_logic_vector is begin
        case DATA is                                -- return vectors are in downto index
            when "0000"     => return "0111111";    -- "0"
            when "0001"     => return "0000110";    -- "1"
            when "0010"     => return "1011011";    -- "2"
            when "0011"     => return "1001111";    -- "3"
            when "0100"     => return "1100110";    -- "4"
            when "0101"     => return "1101101";    -- "5"
            when "0110"     => return "1111101";    -- "6"
            when "0111"     => return "0000111";    -- "7"
            when "1000"     => return "1111111";    -- "8"
            when "1001"     => return "1101111";    -- "9"
            when "1010"     => return "1110111";    -- "A"
            when "1011"     => return "1111100";    -- "B"
            when "1100"     => return "0111001";    -- "C"
            when "1101"     => return "1011110";    -- "D"
            when "1110"     => return "1111001";    -- "E"
            when "1111"     => return "1110001";    -- "F"
            when others     => return "1000000";    -- "-" when unknown value
        end case;
    end To_Segment;
    signal      COUNT : natural;
    signal      BLANK : std_logic_vector (DIGITS downto 0);
begin
    ---------------------------------------------
    COUNTER_PROCESS: process (RESET, CLOCK) begin
    ---------------------------------------------
        if (RESET = '1') then                           -- active high master reset set count to 0
            COUNT <= 0;
        elsif (CLOCK'event and CLOCK = '1') then        -- check for rising edge
            if (CLEAR = '1') then                       -- synchronous clear sets count to 0 if enabled
                COUNT <= 0;
            elsif (ENABLE = '1') then                   -- check if counter is enabled
                if (COUNT = DIGITS-1) then              -- if at max value, loop back to 0
                    COUNT <= 0;
                else 
                    COUNT <= COUNT + 1;                 -- otherwise, increment count
                end if;
            end if;
        end if;
    end process;
    ---------------------------------------------
    OUTPUT_PROCESS:  process (RESET, CLOCK) begin
    ---------------------------------------------
        if (RESET = '1') then                           -- active high master reset sets everything to 0
            for I in 0 to DIGITS-1 loop
                DIGIT(I) <= '0';
            end loop;
            SEGMENT <= "00000000";
        elsif (CLOCK'event and CLOCK = '1') then        -- check for rising edge
            if (CLEAR = '1') then                       -- synchronous clear sets everything to 0
                for I in 0 to DIGITS-1 loop
                    DIGIT(I) <= '0';
                end loop;
                SEGMENT <= "00000000";
            elsif (ENABLE = '1') then                   -- check if output is enabled
                for I in 0 to DIGITS-1 loop             -- Loop checks what value COUNT is, and applies correct values to DIGIT,
                    if (I = COUNT) then                 -- BLANK, and SEGMENT for the corresponding sections of each signal.
                        DIGIT(I) <= '1';
                        if (BLANK(I) = '0') then
                            SEGMENT <= DP(I) & To_Segment (DATA (4*I+3 downto 4*I));
                        else
                            SEGMENT <= DP(I) & "0000000";
                        end if;
                    else
                        DIGIT(I) <= '0';
                    end if;
                end loop;
            end if;
        end if;
    end process;
    BLANK(DIGITS) <= BLANKING;      -- enable blanking if set to 1, disable if set to 0
    BLANKGEN: for I in 1 to DIGITS-1 generate
        BLANK(DIGITS-I) <= BLANK (DIGITS-I+1) when (DATA (4*I+3 downto 4*I) = "0000") else '0';
    end generate;
    BLANK(0)      <= '0';           -- digit 0 is always on
end architecture;