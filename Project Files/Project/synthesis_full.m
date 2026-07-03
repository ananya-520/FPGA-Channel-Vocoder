function synthesis_full(ModulationFactor)
% Runs the channel vocoder using full-precision (double) IIR coefficients.
% Signal chain per channel k:
%   1. Bandpass filter  : Direct Form I, 2nd-order IIR
%   2. Rectify          : abs()
%   3. Envelope filter  : leaky integrator  y[n] = alpha*|x[n]| + (1-alpha)*y[n-1]
%   4. Carrier          : sine at F(k)*Fs/2*ModulationFactor Hz
%   5. Modulate         : envelope ? carrier
% Final output = sum across all channels, normalised.
%
% Output written to workspace variable 'y_full' and saved as 'output_full.wav'.

global a b F Fs NumberOfBands voice_input

% -------------------------------------------------------------------------
% 1. Envelope filter time constant
%    Alpha chosen so the -3 dB point is ~30 Hz (standard vocoder practice).
%    alpha = 1 - exp(-2*pi*f_env/Fs),  f_env = 30 Hz
%    For hardware friendliness, round to nearest power of two (shift trick).
% -------------------------------------------------------------------------
f_env  = 30;                           % envelope bandwidth (Hz)
alpha  = 1 - exp(-2*pi*f_env/Fs);     % ? 0.0233 at 8 kHz

N = length(voice_input);
output = zeros(N, 1);

% -------------------------------------------------------------------------
% 2. Process each channel
% -------------------------------------------------------------------------
for k = 1:NumberOfBands

    % --- 2a. Bandpass filter (Direct Form I) ---
    b_k = b(k,:);    % [b0 b1 b2]
    a_k = a(k,:);    % [1  a1 a2]
    bp = filter(b_k, a_k, voice_input);   % bandpass output

    % --- 2b. Rectify ---
    rectified = abs(bp);

    % --- 2c. Envelope: leaky integrator ---
    env = zeros(N, 1);
    for n = 1:N
        if n == 1
            env(n) = alpha * rectified(n);
        else
            env(n) = alpha * rectified(n) + (1 - alpha) * env(n-1);
        end
    end

    % --- 2d. Carrier sine wave ---
    % Centre frequency in Hz = F(k) * (Fs/2), then shifted by ModulationFactor.
    % ModulationFactor multiplies the carrier frequency (pitch robot effect).
    f_centre_hz = F(k) * (Fs/2);
    carrier_freq = f_centre_hz * ModulationFactor;
    carrier_freq = min(carrier_freq, Fs/2 - 1);   % clamp below Nyquist

    t = (0:N-1)' / Fs;
    carrier = sin(2*pi*carrier_freq*t);

    % --- 2e. Modulate ---
    output = output + env .* carrier;

end

% -------------------------------------------------------------------------
% 3. Normalise and export
% -------------------------------------------------------------------------
output = output / max(abs(output) + 1e-12);

assignin('base', 'y_full', output);            % put in MATLAB workspace
audiowrite('output_full.wav', output, Fs);
fprintf('synthesis_full: done. Max amplitude = %.4f. Saved output_full.wav\n', ...
    max(abs(output)));
end