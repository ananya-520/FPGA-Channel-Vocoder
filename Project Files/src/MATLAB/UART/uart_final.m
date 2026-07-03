%% uart_final.m
% Reads processed 16-bit vocoder audio samples from the Basys3 UART port
% and compares it directly against your expected reference models.

%% 1. Configuration
port = "COM8";
baud = 460800;
Fs = 8000;

% Load reference audio files
if exist('expected_output.wav', 'file') == 2
    [y_full_ref, Fs_ref] = audioread('expected_output.wav');
    N = length(y_full_ref);
else
    error('Could not find expected_output.wav! Run your software reference script first.');
end

%% 2. Open Serial Port
fprintf('Opening serial port %s at %d baud...\n', port, baud);

if exist('serialport', 'file') == 2
    % Modern MATLAB (R2019b and newer)
    s = serialport(port, baud);
    flush(s);
else
    % Legacy MATLAB (R2019a and older)
    s = serial(port, 'BaudRate', baud, 'InputBufferSize', N*2);
    fopen(s);
    flushinput(s);
end

fprintf('Serial interface ready. Please re-program or reset your Basys3 board now!\n');
fprintf('Listening to capture exactly %d audio samples (%d bytes)...\n', N, N*2);

%% 3. Read Raw Serial Data Stream (2 Bytes per Sample)
if exist('serialport', 'file') == 2
    raw_bytes = read(s, N*2, "uint8");
    clear s;
else
    raw_bytes = fread(s, N*2, 'uint8');
    fclose(s); delete(s); clear s;
end

fprintf('Data transfer complete! Processing audio...\n');

%% 4. Reconstruct 16-Bit Signed Samples from Byte Pairs
% The FPGA transmits Low Byte then High Byte (or vice versa depending on module design)
% Reshape into 2 rows: Row 1 = Low Byte, Row 2 = High Byte
raw_bytes = reshape(raw_bytes, 2, N);

% Combine bytes into 16-bit integers using typecast
y_int16 = typecast(uint8(raw_bytes(:)), 'int16');

% Convert to floating point and normalize based on Fix_16_15 format
y_basys_fpga = double(y_int16) / 32768; 

% Secondary normalization safeguard to match your script
if max(abs(y_basys_fpga)) > 0
    y_basys_fpga = y_basys_fpga / max(abs(y_basys_fpga));
end

%% 5. Save the Clean Hardware Output
audiowrite('fpga_output.wav', y_basys_fpga, Fs);
disp('Saved physical hardware response to fpga_output.wav!');

%% 6. Plotting Comparison Waves (Original vs MATLAB vs FPGA)
if exist('test.wav', 'file') == 2
    og_audio = audioread('test.wav');
else
    og_audio = y_basys_fpga;
end

figure('Name', 'Vocoder Hardware Verification System', 'NumberTitle', 'off');

subplot(3,1,1);
plot(og_audio, 'g');
title('Original Input (test.wav)');
ylabel('Amplitude');
grid on;

subplot(3,1,2);
plot(y_full_ref, 'b');
title('Expected MATLAB Simulation Reference Output');
ylabel('Amplitude');
grid on;

subplot(3,1,3);
plot(y_basys_fpga, 'r');
title('Basys3 FPGA Hardware Output via UART');
ylabel('Amplitude');
grid on;

%% 7. Audio Playback Cycle
disp('Playing MATLAB software reference audio...');
sound(y_full_ref, Fs_ref);
pause(length(y_full_ref)/Fs_ref + 1.5);

disp('Playing actual FPGA hardware audio stream...');
sound(y_basys_fpga, Fs);