%% COMPARE: Audio Input Captured vs. Original Audio Data
% Checks if the BRAM is delivering audio correctly to the IIR filter

Fs = 8000;  % Must match your vocoder.m

% Get the number of samples captured
audio_input_data = audio_input_captured(:);
N_captured = length(audio_input_data);

% Trim audio_data to match (might be row or column vector)
audio_data_trim = audio_data(:);
audio_data_trim = audio_data_trim(1:N_captured);

% Compute error
error = audio_input_data - audio_data_trim;

% Compute SNR
signal_power = mean(audio_data_trim.^2);
noise_power = mean(error.^2);
SNR_dB = 10 * log10(signal_power / noise_power);

fprintf('\n=== AUDIO INPUT COMPARISON ===\n');
fprintf('Samples compared: %d (%.3f seconds)\n', N_captured, (N_captured-1)/Fs);
fprintf('SNR (Input Captured vs. Original): %.2f dB\n', SNR_dB);

% Check for match
if SNR_dB > 100
    fprintf('? PERFECT: Audio input matches original exactly\n');
elseif SNR_dB > 60
    fprintf('? GOOD: Audio input matches (minor quantization)\n');
else
    fprintf('? PROBLEM: Audio input does NOT match original\n');
    fprintf('   Likely cause: BRAM address timing or counter issue\n');
end

fprintf('\nOriginal audio statistics:\n');
fprintf('  Max: %.6f\n', max(abs(audio_data_trim)));
fprintf('  Min: %.6f\n', min(audio_data_trim));
fprintf('  Mean: %.6e\n', mean(audio_data_trim));
fprintf('  RMS: %.6f\n', sqrt(mean(audio_data_trim.^2)));

fprintf('\nCaptured audio statistics:\n');
fprintf('  Max: %.6f\n', max(abs(audio_input_data)));
fprintf('  Min: %.6f\n', min(audio_input_data));
fprintf('  Mean: %.6e\n', mean(audio_input_data));
fprintf('  RMS: %.6f\n', sqrt(mean(audio_input_data.^2)));

% Plot comparison
figure('Name', 'Audio Input Comparison', 'NumberTitle', 'off');
time_axis = (0:N_captured-1) / Fs;

subplot(3,1,1);
plot(time_axis, audio_data_trim, 'b', 'LineWidth', 1);
title('Original audio\_data (from BRAM init)');
ylabel('Amplitude');
grid on;
xlim([0, time_axis(end)]);

subplot(3,1,2);
plot(time_axis, audio_input_data, 'r', 'LineWidth', 1);
title('Captured at IIR Filter Input');
ylabel('Amplitude');
grid on;
xlim([0, time_axis(end)]);

subplot(3,1,3);
plot(time_axis, error, 'g', 'LineWidth', 0.5);
title(sprintf('Difference | SNR: %.2f dB', SNR_dB));
ylabel('Error');
xlabel('Time (seconds)');
grid on;
xlim([0, time_axis(end)]);

% Detailed check: first and last 500 samples
fprintf('\n=== SAMPLE-BY-SAMPLE CHECK ===\n');
fprintf('First 10 samples:\n');
fprintf('Index | Original | Captured | Error\n');
for i = 1:10
    fprintf('%5d | %8.6f | %8.6f | %8.6e\n', i-1, audio_data_trim(i), audio_input_data(i), error(i));
end

fprintf('\nLast 10 samples:\n');
fprintf('Index | Original | Captured | Error\n');
for i = max(1, N_captured-9):N_captured
    fprintf('%5d | %8.6f | %8.6f | %8.6e\n', i-1, audio_data_trim(i), audio_input_data(i), error(i));
end

% Export for further analysis
assignin('base', 'audio_comparison_error', error);
assignin('base', 'audio_comparison_SNR_dB', SNR_dB);

fprintf('\nExported: audio_comparison_error, audio_comparison_SNR_dB\n');