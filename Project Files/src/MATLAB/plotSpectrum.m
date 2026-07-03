% plotSpectrum.m

% A visual validation to plot the bandpass filter

% Functionality
%     1. Computes Frequency Responses
%     2. Overlays the Plots

function plotSpectrum()
    global a b fix_a fix_b Fs NumberOfBands numBits
    
    figure('Name', 'Vocoder Filter Bank Response Verification');
    hold on;
    n_points = 1024; % Resolution of the spectrum plot
    
    for i = 1:NumberOfBands
        % Ideal full precision magnitude response
        [H_full, w] = freqz(b(i,:), a(i,:), n_points, Fs);
        % Hardware-emulated fixed precision magnitude response
        [H_fix, ~]  = freqz(fix_b(i,:), fix_a(i,:), n_points, Fs);
        
        % Convert to Decibels (dB)
        plot(w, 20*log10(abs(H_full)), 'b-', 'LineWidth', 1);
        plot(w, 20*log10(abs(H_fix)), 'r--', 'LineWidth', 1);
    end
    
    title(['32-Channel Filter Bank: Full vs Fixed Precision (', num2str(numBits), ' bits)']);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
    ylim([-40, 5]);
    grid on;
    legend('Full Precision', 'Fixed Precision');
end