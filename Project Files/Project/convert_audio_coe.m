% convert_audio_coe.m
% Converts .wav audio file to .coe

x = audioread('test.wav');
x = x(:,1);
x = x / max(abs(x));

xq = round(x * 2^15);
xq = max(min(xq, 2^15-1), -2^15);
fid = fopen('test.coe','w');
fprintf(fid,'memory_initialization_radix=2;\n');
fprintf(fid,'memory_initialization_vector=\n');
bits = dec2bin(typecast(int16(xq),'uint16'),16);
for k=1:size(bits,1)
    t=';'; if k<size(bits,1), t=','; end
    fprintf(fid,'%s%s\n',bits(k,:),t);
end
fclose(fid);
disp('test.coe created');

% 1. Load your original audio file
[audio_raw, fs_original] = audioread('test.wav');

% 2. Ensure the audio is Mono (take the first channel if it's stereo)
if size(audio_raw, 2) > 1
    audio_raw = audio_raw(:, 1);
end

% 3. Resample to your processing domain frequency if it isn't already 8000 Hz
if fs_original ~= 8000
    audio_resampled = resample(audio_raw, 8000, fs_original);
else
    audio_resampled = audio_raw;
end

% 4. Quantize the audio to your hardware fixed-point representation (e.g., Fix_16_15)
% Signed, 16 bits total width, 15 bits fractional length
audio_type = numerictype(1, 16, 15); 
audio_math = fimath('RoundingMethod', 'Nearest', 'OverflowAction', 'Saturate');

% 5. Define 'y' as the fixed-point vector that System Generator reads
audio_array = fi(audio_resampled', audio_type, audio_math);
audio_array = double(audio_resampled');

% 6. Display parameters to copy directly into your Single Port RAM block
disp('--- BRAM Configuration Details ---');
fprintf('Set Depth parameter to: %d\n', length(audio_array));