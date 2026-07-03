% build_channels.m
% Run this AFTER vocoder(1, NB) has been run.
% Does two things:
%   1. Generates coeff.coe ? the coefficient ROM file for all 32 channels
%   2. Auto-sets all 32 masked Subsystem blocks in your Simulink model
%
% HOW TO USE:
%   1. Run vocoder(1, NB) first (e.g. vocoder(1, 12))
%   2. Open your Simulink model vocoder_model_hw.slx
%   3. Make sure your 32 subsystems are named Channel_1, Channel_2, ... Channel_32
%   4. Run this script

global b a fix_b fix_a F BW Fs NumberOfBands numBits

% -------------------------------------------------------------------------
% PART A ? Generate coeff.coe for the FPGA coefficient ROM
% This file loads all 32 channels' b0,b1,b2,a1,a2 into BRAM.
% Each channel has 5 coefficients. Total = 32 x 5 = 160 values.
% Layout per channel (5 consecutive addresses):
%   addr 5k+0 = b0_k
%   addr 5k+1 = b1_k
%   addr 5k+2 = b2_k
%   addr 5k+3 = a1_k
%   addr 5k+4 = a2_k
% -------------------------------------------------------------------------

scale    = 2^(numBits - 1);
mask     = uint32(2^numBits - 1);
hexDigits = ceil(numBits / 4);

fid = fopen('coeff.coe', 'w');
fprintf(fid, 'memory_initialization_radix=16;\n');
fprintf(fid, 'memory_initialization_vector=\n');

total_entries = NumberOfBands * 5;
entry = 0;

for k = 1:NumberOfBands
    coeffs = [fix_b(k,1), fix_b(k,2), fix_b(k,3), ...   % b0 b1 b2
              fix_a(k,2), fix_a(k,3)];                    % a1 a2 (skip a0=1)
    for c = 1:5
        entry = entry + 1;
        hex_val = dec2hex(bitand(uint32(coeffs(c)), mask), hexDigits);
        if entry < total_entries
            fprintf(fid, '%s,\n', hex_val);
        else
            fprintf(fid, '%s;\n', hex_val);
        end
    end
end

fclose(fid);
fprintf('coeff.coe created: %d entries (%d channels x 5 coefficients, %d bits)\n', ...
    total_entries, NumberOfBands, numBits);

% -------------------------------------------------------------------------
% PART B ? Auto-set all 32 Subsystem masks in the Simulink model
% This sets b0,b1,b2,a1,a2,fc for each channel automatically.
% No manual entry needed.
% -------------------------------------------------------------------------

modelName = 'vocoder_model';   % <-- change if your model has a different name

% Check the model is open
if isempty(find_system('SearchDepth', 0, 'Name', modelName))
    error('Model "%s" is not open. Open it first, then run this script.', modelName);
end

F_hz = F * (Fs/2);   % convert normalised frequencies to Hz

for k = 1:NumberOfBands
    % The subsystem must be named Channel_1, Channel_2, ... Channel_32
    blockPath = sprintf('%s/Channel_%d', modelName, k);

    % Check the block exists
    if isempty(find_system(modelName, 'SearchDepth', 1, 'Name', sprintf('Channel_%d', k)))
        warning('Block Channel_%d not found in model. Skipping.', k);
        continue;
    end

    % Real-valued coefficients (for the floating-point Discrete Filter)
    set_param(blockPath, ...
        'b0', num2str(b(k,1), '%.10f'), ...
        'b1', num2str(b(k,2), '%.10f'), ...
        'b2', num2str(b(k,3), '%.10f'), ...
        'a1', num2str(a(k,2), '%.10f'), ...
        'a2', num2str(a(k,3), '%.10f'), ...
        'fc', num2str(F_hz(k), '%.6f'));

    fprintf('Channel_%d set: fc=%.1f Hz, b=[%.6f %.6f %.6f]\n', ...
        k, F_hz(k), b(k,1), b(k,2), b(k,3));
end

fprintf('\nAll %d channels populated automatically.\n', NumberOfBands);
fprintf('Run the model now and verify against y_full.\n');