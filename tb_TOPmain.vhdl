library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_TOPmain is
end entity tb_TOPmain;

architecture sim of tb_TOPmain is

    constant DATA_WIDTH : integer := 32;
    constant N_POINTS   : integer := 8;
    constant FRAC_WIDTH : integer := 15;
    constant HALF_WIDTH : integer := DATA_WIDTH / 2;

    constant FRAC_DATA_WIDTH : integer := 8;
    constant DATA_SCALE      : integer := 2 ** FRAC_DATA_WIDTH;

    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
    signal start : std_logic := '0';
    signal done  : std_logic;

    signal data_in  : std_logic_vector(N_POINTS*DATA_WIDTH-1 downto 0)
                      := (others => '0');
    signal data_out : std_logic_vector(N_POINTS*DATA_WIDTH-1 downto 0);

    signal sim_done : boolean := false;

    type int_vec_t is array (0 to N_POINTS-1) of integer;

    constant X_RE : int_vec_t := (2816, -2304, 1792, -1280, 768, -256, -768, 1280);
    constant X_IM : int_vec_t := (-2048, 1536, -1024, 512, 0, -512, 1024, -1536);
    --constant REF_RE : int_vec_t := ( 3328,  -618, 1280,  106, 1280,  106, 1280,  -618);
    --constant REF_IM : int_vec_t := (    0,   150,    0, -874,    0,  874,    0,  -150);

    function pack_complex(re : integer; im : integer)
        return std_logic_vector
    is
        variable v : std_logic_vector(DATA_WIDTH-1 downto 0);
    begin
        v(HALF_WIDTH-1 downto 0)          :=
            std_logic_vector(to_signed(re, HALF_WIDTH));
        v(DATA_WIDTH-1 downto HALF_WIDTH) :=
            std_logic_vector(to_signed(im, HALF_WIDTH));
        return v;
    end function;

    function get_re(sample : std_logic_vector(DATA_WIDTH-1 downto 0))
        return integer is
    begin
        return to_integer(signed(sample(HALF_WIDTH-1 downto 0)));
    end function;

    function get_im(sample : std_logic_vector(DATA_WIDTH-1 downto 0))
        return integer is
    begin
        return to_integer(signed(sample(DATA_WIDTH-1 downto HALF_WIDTH)));
    end function;

    -- Convert raw Q8.8 integer to a string with one fractional digit
    -- (cheap, no math_real dependency). Examples:
    --   3328 ->  "13.0"     106  -> "0.4"
    --   -618 -> "-2.4"     -874  -> "-3.4"
    function q88_to_str(v : integer) return string is
    variable int_part  : integer;
    variable frac_part : integer;
    variable abs_v     : integer;
    variable sign_str  : string(1 to 1);
begin
    if v < 0 then
        abs_v    := -v;
        sign_str := "-";
    else
        abs_v    := v;
        sign_str := " ";
    end if;

    int_part  := abs_v / DATA_SCALE;

    -- 4 decimales: parte fraccionaria * 10000 / 256
    frac_part := ((abs_v mod DATA_SCALE) * 10000) / DATA_SCALE;

    return sign_str
         & integer'image(int_part)
         & "."
         & integer'image(frac_part);
end function;

begin

    clk_proc : process
    begin
        while not sim_done loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
        wait;
    end process;

    DUT : entity work.TOPmain
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            N_POINTS   => N_POINTS,
            FRAC_WIDTH => FRAC_WIDTH
        )
        port map (
            clk      => clk,
            rst      => rst,
            start    => start,
            data_in  => data_in,
            data_out => data_out,
            done     => done
        );

    stim_proc : process
        variable re_hw, im_hw : integer;
        variable err_re, err_im : integer;
        variable n_fail : integer := 0;
    begin

        wait until falling_edge(clk);
        rst   <= '1';
        start <= '0';
        for i in 0 to 4 loop
            wait until falling_edge(clk);
        end loop;
        rst <= '0';
        wait until falling_edge(clk);

        for i in 0 to N_POINTS-1 loop
            data_in(
                (i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH
            ) <= pack_complex(
                X_RE(i),-- * DATA_SCALE,
                X_IM(i)-- * DATA_SCALE
            );
        end loop;

        wait until falling_edge(clk);

        start <= '1';
        wait until falling_edge(clk);
        start <= '0';

        for guard in 0 to 20 loop
            exit when done = '1';
            wait until rising_edge(clk);
        end loop;

        wait for 1 ns;

        for i in 0 to N_POINTS-1 loop
            re_hw := get_re(data_out((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH));
            im_hw := get_im(data_out((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH));
        end loop;
        
        sim_done <= true;
        wait;
        
    end process;

end architecture sim;
