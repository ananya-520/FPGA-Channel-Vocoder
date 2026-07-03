function filtersCoefficients()
% Designs 32 second-order IIR bandpass filters using the mel-spaced centre
% frequencies and bandwidths computed in vocoder.m.
% Writes three output files:
%   IIR_coef_full.txt     ? real-valued (double) coefficients
%   IIR_coef_fix.txt      ? truncated fixed-point coefficients (numBits bits)
%   IIR_coef_fix_hex.txt  ? hex representation of the truncated coefficients
%
% All arrays use vocoder.m globals. Each filter is stored as one row:
%   [b0  b1  b2  a0  a1  a2]   (a0 is always 1 after normalisation)

global a b fix_a fix_b fix_hex_absa fix_hex_absb F BW Fs numBits NumberOfBands

% -------------------------------------------------------------------------
% 1. Allocate storage
%    b : NumberOfBands x 3  (numerator coefficients b0 b1 b2)
%    a : NumberOfBands x 3  (denominator coefficients 1  a1 a2)
% -------------------------------------------------------------------------
b = zeros(NumberOfBands, 3);
a = zeros(NumberOfBands, 3);

% -------------------------------------------------------------------------
% 2. Design each filter
%    F(k)  = normalised centre frequency (0-1, relative to Nyquist)
%    BW(k) = normalised bandwidth
%    Use MATLAB's butter() in bandpass mode.
%    The passband edges are [F(k)-BW(k)/2 , F(k)+BW(k)/2], clamped to (0,1).
% -------------------------------------------------------------------------
for k = 1:NumberOfBands
    f_lo = max(F(k) - BW(k)/2, 0.001);   % lower edge, never touch 0
    f_hi = min(F(k) + BW(k)/2, 0.999);   % upper edge, never touch Nyquist

    % 2nd-order Butterworth bandpass ? [b_k, a_k] each length 5 (order 4)
    % To keep a true 2nd-order biquad we use a 1st-order butter bandpass
    % (which yields order 2 overall) instead.
    % butter(1,'bandpass') gives a 2nd-order filter (3 b, 3 a coefficients).
    [b_k, a_k] = butter(1, [f_lo f_hi], 'bandpass');

    % Normalise so a(1) == 1 (MATLAB already does this, but be explicit)
    b(k,:) = b_k / a_k(1);
    a(k,:) = a_k / a_k(1);
end

% -------------------------------------------------------------------------
% 3. Write full-precision file
%    Format per line: b0  b1  b2  a0  a1  a2
% -------------------------------------------------------------------------
fid = fopen('IIR_coef_full.txt', 'w');
fprintf(fid, '%% IIR filter coefficients ? full precision (double)\n');
fprintf(fid, '%% Columns: b0  b1  b2  a0  a1  a2\n');
for k = 1:NumberOfBands
    fprintf(fid, '%.15f  %.15f  %.15f  %.15f  %.15f  %.15f\n', ...
        b(k,1), b(k,2), b(k,3), a(k,1), a(k,2), a(k,3));
end
fclose(fid);

% -------------------------------------------------------------------------
% 4. Truncate to numBits bits (match vocoder.m: fix() = truncate toward zero)
%    Scale factor = 2^(numBits-1)  (1 sign bit + (numBits-1) fractional bits)
%    fix_b, fix_a store the truncated INTEGER values.
% -------------------------------------------------------------------------
scale = 2^(numBits - 1);

fix_b = fix(b * scale);   % truncate (toward zero)
fix_a = fix(a * scale);

% -------------------------------------------------------------------------
% 5. Write fixed-point integer file
% -------------------------------------------------------------------------
fid = fopen('IIR_coef_fix.txt', 'w');
fprintf(fid, '%% IIR filter coefficients ? fixed-point integers (%d bits)\n', numBits);
fprintf(fid, '%% Columns: b0  b1  b2  a0  a1  a2\n');
for k = 1:NumberOfBands
    fprintf(fid, '%d  %d  %d  %d  %d  %d\n', ...
        fix_b(k,1), fix_b(k,2), fix_b(k,3), ...
        fix_a(k,1), fix_a(k,2), fix_a(k,3));
end
fclose(fid);

% -------------------------------------------------------------------------
% 6. Write hex file (two's-complement, numBits wide)
%    dec2bin / dec2hex on signed integers requires the uint conversion trick.
% -------------------------------------------------------------------------
% We need unsigned interpretation of the two's-complement bit pattern.
% For numBits <= 16 use uint16; adjust mask if numBits > 16.
mask = uint32(2^numBits - 1);

fix_hex_absb = cell(NumberOfBands, 3);
fix_hex_absa = cell(NumberOfBands, 3);

fid = fopen('IIR_coef_fix_hex.txt', 'w');
fprintf(fid, '%% IIR filter coefficients ? hex two''s-complement (%d bits)\n', numBits);
fprintf(fid, '%% Columns: b0  b1  b2  a0  a1  a2\n');

hexDigits = ceil(numBits / 4);   % number of hex characters needed

for k = 1:NumberOfBands
    row_str = '';
    for col = 1:3
        % b coefficients
        hb = dec2hex(bitand(uint32(fix_b(k,col)), mask), hexDigits);
        fix_hex_absb{k,col} = hb;
        row_str = [row_str, hb, '  '];
    end
    for col = 1:3
        % a coefficients
        ha = dec2hex(bitand(uint32(fix_a(k,col)), mask), hexDigits);
        fix_hex_absa{k,col} = ha;
        row_str = [row_str, ha, '  '];
    end
    fprintf(fid, '%s\n', strtrim(row_str));
end
fclose(fid);

fprintf('filtersCoefficients: wrote 3 coefficient files (%d bands, %d bits).\n', ...
    NumberOfBands, numBits);


% -------------------------------------------------------------------------
% Save coefficients as MATLAB arrays for use in Simulink
% -------------------------------------------------------------------------

% % Create a structure holding all coefficients
% coefficients = struct();
% 
% % Store b and a coefficients for each channel
% for k = 1:NumberOfBands
%     coefficients.b(k,:) = b(k,:);           % [b0 b1 b2]
%     coefficients.a(k,:) = a(k,:);           % [1  a1 a2]
%     coefficients.b_fix(k,:) = fix_b(k,:);   % fixed-point b
%     coefficients.a_fix(k,:) = fix_a(k,:);   % fixed-point a
%     coefficients.fc(k) = F_hz(k);            % centre frequency in Hz
%     coefficients.phase_inc(k) = round(F_hz(k) * 2^24 / 100e6);  % DDS phase increment
% end

end
