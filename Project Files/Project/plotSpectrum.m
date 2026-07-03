function plotSpectrum()
% Plots the frequency response of all 32 bandpass IIR filters.
% Shows both the full-precision (b,a) and fixed-point (fix_b,fix_a)
% responses side-by-side so you can visually check quantisation impact.

global a b fix_a fix_b Fs numBits NumberOfBands

NFFT = 1024;                      % frequency resolution
f_axis = linspace(0, Fs/2, NFFT/2+1);  % Hz axis (0 ? Nyquist)
scale = 2^(numBits - 1);          % to recover real values from integers

figure('Name','Filter Bank ? Frequency Responses','NumberTitle','off');

subplot(2,1,1);
hold on; grid on;
title(sprintf('Full-precision filter bank (%d channels)', NumberOfBands));
xlabel('Frequency (Hz)'); ylabel('|H(f)| (dB)');
for k = 1:NumberOfBands
    [H, ~] = freqz(b(k,:), a(k,:), NFFT, Fs);
    plot(f_axis, 20*log10(abs(H(1:NFFT/2+1)) + 1e-12));
end
ylim([-80 5]);

subplot(2,1,2);
hold on; grid on;
title(sprintf('Fixed-point filter bank (%d bits)', numBits));
xlabel('Frequency (Hz)'); ylabel('|H(f)| (dB)');
for k = 1:NumberOfBands
    b_real = fix_b(k,:) / scale;   % recover real values from integers
    a_real = fix_a(k,:) / scale;
    [H, ~] = freqz(b_real, a_real, NFFT, Fs);
    plot(f_axis, 20*log10(abs(H(1:NFFT/2+1)) + 1e-12));
end
ylim([-80 5]);

fprintf('plotSpectrum: displayed frequency responses for %d filters.\n', NumberOfBands);
end