y = double(y_sim);
fprintf('Original size: %d samples\n', length(y));

% Downsample by 32 (because folded architecture runs 32x faster than audio rate)
y_down = downsample(y, 32);
fprintf('Downsampled size: %d samples\n', length(y_down));
fprintf('Duration: %.2f seconds\n', length(y_down)/8000);

% Normalize
y_norm = y_down / max(abs(y_down));

% Play
sound(y_norm, 8000);

% Save
audiowrite('vocoder_output.wav', y_norm, 8000);
disp('Saved to vocoder_output.wav!');
% -------------------------------------------------------------------------------------------------------------
% Compare FPGA output vs MATLAB reference
[y_full_ref, Fs_ref] = audioread('expected_output.wav');
[y_fpga, Fs_fpga] = audioread('vocoder_output.wav');

figure;
subplot(3,1,1);
plot(audio_data);
title('Original test.wav');
ylabel('Amplitude');

subplot(3,1,2);
plot(y_full_ref);
title('MATLAB Output');
ylabel('Amplitude');

subplot(3,1,3);
plot(y_fpga);
title('Vocoder output');
ylabel('Amplitude');

% Play each one
% disp('Playing original...');
% % sound(audio_data, 8000);
% % pause(length(audio_data)/8000 + 1);
% og_audio = audioread('test.wav');
% sound(og_audio, 8000);
% pause(length(audio_data)/8000 + 1)

disp('Playing MATLAB reference...');
sound(y_full_ref, Fs_ref);
pause(length(y_full_ref)/Fs_ref + 1);

disp('Playing FPGA output...');
sound(y_fpga, Fs_fpga);