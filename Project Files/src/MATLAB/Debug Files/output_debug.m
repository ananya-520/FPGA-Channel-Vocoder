%% SIMPLE COMPARISON: Simulink vs. synthesis_fix (time-aligned)
% Trims y_fix to match ONLY the time window that Simulink simulation ran

Fs = 8000;

fractional_bits = 15;  % IMPORTANT: match Simulink format

N_sim = length(y_sim);

% SCALE SIMULINK OUTPUT
y_sim_scaled = double(y_sim) / (2^fractional_bits);

% ALIGN LENGTH
y_fix_trim = y_fix(1:N_sim);
y_sim_trim = y_sim_scaled(1:N_sim);

% ERROR
error = y_sim_trim - y_fix_trim;

% SNR
signal_power = mean(y_fix_trim.^2);
noise_power = mean(error.^2);
SNR_dB = 10 * log10(signal_power / noise_power);

fprintf('SNR: %.2f dB\n', SNR_dB);
fprintf('Samples: %d (%.3f sec)\n', N_sim, (N_sim-1)/Fs);

% PLOTS
figure;
t = (0:N_sim-1)/Fs;

subplot(3,1,1);
plot(t, y_fix_trim);
title('MATLAB reference');

subplot(3,1,2);
plot(t, y_sim_trim);
title('Simulink (scaled)');

subplot(3,1,3);
plot(t, error);
title('Error signal');