function synthesis_fix(ModulationFactor)
% Runs the channel vocoder using TRUNCATED fixed-point IIR coefficients.
% Identical signal chain to synthesis_full, but:
%   - Bandpass uses fix_b, fix_a (integer-valued, truncated to numBits bits).
%   - Coefficients are scaled back to real values (divide by 2^(numBits-1))
%     before calling filter(), modelling what the hardware multiplier sees.
%   - Envelope filter uses the power-of-two alpha trick (right-shift form)
%     to model the multiply-free hardware implementation.
%
% Output written to workspace variable 'y_fix' and saved as 'output_fix.wav'.
% Compare y_fix against y_full to quantify the effect of coefficient truncation.

global fix_a fix_b F Fs NumberOfBands numBits voice_input

scale = 2^(numBits - 1);   % fixed-point scale factor

% -------------------------------------------------------------------------
% 1. Envelope alpha ? power-of-two version (hardware shift trick)
%    Find the integer shift alpha_shift such that 2^(-alpha_shift) is the
%    closest power of two to the ideal alpha = 1-exp(-2*pi*30/Fs).
% -------------------------------------------------------------------------
f_env      = 30;
alpha_ideal = 1 - exp(-2*pi*f_env/Fs);           % ? 0.0233
alpha_shift = round(-log2(alpha_ideal));           % nearest integer shift
alpha_pow2  = 2^(-alpha_shift);                   % actual alpha used

fprintf('synthesis_fix: envelope alpha = 2^(-%d) = %.6f (ideal %.6f)\n', ...
    alpha_shift, alpha_pow2, alpha_ideal);

N = length(voice_input);
output = zeros(N, 1);

% -------------------------------------------------------------------------
% 2. Process each channel with fixed-point coefficients
% -------------------------------------------------------------------------
for k = 1:NumberOfBands

    % --- 2a. Recover real-valued coefficients from truncated integers ---
    %     This exactly models what happens on the FPGA: the stored integer
    %     is divided by the scale factor when used in a multiply.
    b_k = fix_b(k,:) / scale;    % truncated b0, b1, b2
    a_k = fix_a(k,:) / scale;    % truncated 1, a1, a2

    % Renormalise a so a(1)==1 (truncation may shift it slightly from 1.0)
    b_k = b_k / a_k(1);
    a_k = a_k / a_k(1);

    % --- 2b. Bandpass filter ---
    bp = filter(b_k, a_k, voice_input);

    % --- 2c. Rectify ---
    rectified = abs(bp);

    % --- 2d. Envelope: power-of-two leaky integrator (shift form) ---
    %   Hardware: y[n] = ((rectified[n] - y[n-1]) >> alpha_shift) + y[n-1]
    %   Software model of same:
    env = zeros(N, 1);
    for n = 1:N
        if n == 1
            prev = 0;
        else
            prev = env(n-1);
        end
        env(n) = alpha_pow2 * (rectified(n) - prev) + prev;
        % Truncate to 16-bit fixed point after the update (models FPGA word length)
        env(n) = fix(env(n) * 2^15) / 2^15;
    end

    % --- 2e. Carrier ---
    f_centre_hz  = F(k) * (Fs/2);
    carrier_freq = f_centre_hz * ModulationFactor;
    carrier_freq = min(carrier_freq, Fs/2 - 1);

    t = (0:N-1)' / Fs;
    carrier = sin(2*pi*carrier_freq*t);

    % --- 2f. Modulate ---
    % Truncate the product to 16-bit to model the hardware multiplier output
    channel_out = fix(env .* carrier * 2^15) / 2^15;
    output = output + channel_out;

end

% -------------------------------------------------------------------------
% 3. Truncate the sum output to 16-bit (models the final requantisation)
% -------------------------------------------------------------------------
output = fix(output * 2^15) / 2^15;
output = output / max(abs(output) + 1e-12);

assignin('base', 'y_fix', output);
audiowrite('output_fix.wav', output, Fs);

% -------------------------------------------------------------------------
% 4. Print SNR vs full-precision reference (if y_full exists in workspace)
% -------------------------------------------------------------------------
if evalin('base','exist(''y_full'',''var'')')
    y_full = evalin('base', 'y_full');
    len = min(length(y_full), length(output));
    err = y_full(1:len) - output(1:len);
    snr_db = 10*log10(sum(y_full(1:len).^2) / (sum(err.^2) + 1e-30));
    fprintf('synthesis_fix: numBits=%d  SNR vs full = %.1f dB\n', numBits, snr_db);
else
    fprintf('synthesis_fix: done (run synthesis_full first to get SNR comparison).\n');
end

fprintf('synthesis_fix: saved output_fix.wav\n');
end