library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package twiddle_pkg is

    constant FFT_SIZE    : integer := 8;
    constant NUM_TWIDDLE : integer := 4;  -- FFT_SIZE / 2
    constant COEFF_WIDTH : integer := 16;

    -- Array type for twiddle coefficient tables
    type t_twiddle_array is array (0 to NUM_TWIDDLE-1) of integer;

    -- Real part:  TWIDDLE_RE(k) = round( cos(2*pi*k/N) * 2^15 )
    constant TWIDDLE_RE : t_twiddle_array := (
         32767,  -- k=0  cos( -0 deg) =  1.00000
         23170,  -- k=1  cos(-45 deg) =  0.70711
             0,  -- k=2  cos(-90 deg) =  0.00000
        -23170   -- k=3  cos(-135 deg) = -0.70711
    );

    -- Imag part:  TWIDDLE_IM(k) = round( sin(2*pi*k/N) * 2^15 )
    -- Note: the imaginary part is subtracted in the butterfly.
    --       The sign is already embedded in the stored value.
    constant TWIDDLE_IM : t_twiddle_array := (
             0,  -- k=0  sin( -0 deg) = -0.00000
        -23170,  -- k=1  sin(-45 deg) = -0.70711
        -32768,  -- k=2  sin(-90 deg) = -1.00000
        -23170   -- k=3  sin(-135 deg) = -0.70711
    );

end package twiddle_pkg;
