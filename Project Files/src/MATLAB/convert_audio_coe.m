% convert_audio_coe.m

% Converts a standard audio file into a 16-bit signed fixed-point .coe file
% and pushes the initialized array directly to the MATLAB Base Workspace.

% Load the original raw audio file
[audio_raw, fs_original] = audioread('test.wav');

% Ensure the audio is Mono (Strip away extra channels if stereo)
if size(audio_raw, 2) > 1
    audio_raw = audio_raw(:, 1);
end

% Resample to your system's target processing domain (8000 Hz)
target_fs = 8000;
if fs_original ~= target_fs
    audio_resampled = resample(audio_raw, target_fs, fs_original);
else
    audio_resampled = audio_raw;
end

% Peak Normalization to protect dynamic range and prevent overflow
audio_resampled = audio_resampled / max(abs(audio_resampled) + 1e-12);

% Hardware Fixed-Point Quantization (Fix_16_15 Simulation representation)
% Scale to 16-bit signed integer range [-32768, 32767]
xq = round(audio_resampled * 2^15);
xq = max(min(xq, 2^15 - 1), -2^15); % Saturate limits to prevent integer wrapping


%% WRITE OUT THE XILINX .COE FILE (Radix = 2)

fid = fopen('test.coe', 'w');
fprintf(fid, 'memory_initialization_radix=2;\n');
fprintf(fid, 'memory_initialization_vector=\n');

% Convert signed integers to 16-bit unsigned Two's Complement bit arrays
unsigned_ints = typecast(int16(xq), 'uint16');
binary_strings = dec2bin(unsigned_ints, 16);

% Loop through and print binary bits with comma/semicolon termination
total_samples = size(binary_strings, 1);
for k = 1:total_samples
    if k < total_samples
        terminator = ',';
    else
        terminator = ';'; % Finishes the vector initialization
    end
    fprintf(fid, '%s%s\n', binary_strings(k, :), terminator);
end
fclose(fid);

disp('test.coe successfully compiled for BRAM initialization.');

%% PUSH VARIABLES TO BASE WORKSPACE

% Push the row-vector version of the normalized data to match your model specs
audio_data = audio_resampled'; 

assignin('base', 'audio_data', audio_data);

fprintf('\n--- BRAM Configuration Details ---\n');
fprintf('Set Depth parameter inside Xilinx ROM block to: %d\n', length(audio_data));
fprintf('Variables successfully exported to Workspace under vector: "audio_data"\n');