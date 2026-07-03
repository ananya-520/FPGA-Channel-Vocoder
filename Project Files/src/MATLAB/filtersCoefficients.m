% % filtersCoefficients.m
% %
% % Designs 32 independent bandpass IIR filters optimized for a musical vocoder.
% % Generates 3 files:
% %    1. IIR_coef_full.txt: High-precision float coefficients.
% %    2. IIR_coef_fix.txt: Fixed-point decimals matching hardware bit length.
% %    3. IIR_coef_fix_hex.txt: Two's Complement HEX for Xilinx BRAM initialization.
% 
% function filtersCoefficients()
%     global a b fix_a fix_b fix_hex_absb fix_hex_absa F BW Fs numBits NumberOfBands
%     global fname_IIR_full fname_IIR_fix fname_IIR_fix_hex
% 
%     b = zeros(NumberOfBands, 3);
%     a = zeros(NumberOfBands, 3);
% 
%     %% 1. DESIGN HIGH-PRECISION FLOAT FILTERS
%     for i = 1:NumberOfBands
%         % Calculate bandpass frequency boundaries
%         f_low  = F(i) - BW(i)/2;
%         f_high = F(i) + BW(i)/2;
% 
%         % Guard rails: Keep poles safely inside the stable unit circle of the Z-plane
%         f_low  = max(0.001, min(0.999, f_low));
%         f_high = max(0.001, min(0.999, f_high));
% 
%         % Generate 2nd-order Butterworth bandpass coefficients
%         [b_ch, a_ch] = butter(1, [f_low, f_high], 'bandpass');
% 
%         % Standardize normalization against a0
%         a_ch = a_ch / a_ch(1);
%         b_ch = b_ch / a_ch(1);
% 
%         a(i, :) = a_ch;
%         b(i, :) = b_ch;
%     end
% 
%     %% 2. FIXED-POINT HARDWARE CONFIGURATION
%     % Allocation for coefficients (e.g., 16 bits total):
%     % 1 Sign Bit + 1 Integer Bit (allows representation up to 1.999) + 14 Fractional Bits
%     fractional_bits = numBits - 2;  
%     scale = 2^fractional_bits;
% 
%     %% 3. QUANTIZATION VIA SYSTEMATIC ROUNDING
%     % Simulates the precision limitations of the FPGA hardware fabric
%     fix_b = round(b * scale) / scale;
%     fix_a = round(a * scale) / scale;
% 
%     %% 4. WRITE FULL PRECISION LOG FILE
%     fileID1 = fopen(fname_IIR_full, 'w');
%     fprintf(fileID1, 'Band, b0, b1, b2, a1, a2\n');
%     for i = 1:NumberOfBands
%         fprintf(fileID1, '%d,%12.8f,%12.8f,%12.8f,%12.8f,%12.8f\n', ...
%             i, b(i,1), b(i,2), b(i,3), a(i,2), a(i,3));
%     end
%     fclose(fileID1);
% 
%     %% 5. WRITE FIXED-POINT DECIMAL LOG FILE
%     fileID2 = fopen(fname_IIR_fix, 'w');
%     fprintf(fileID2, 'Band, b0, b1, b2, a1, a2\n');
%     for i = 1:NumberOfBands
%         fprintf(fileID2, '%d,%12.8f,%12.8f,%12.8f,%12.8f,%12.8f\n', ...
%             i, fix_b(i,1), fix_b(i,2), fix_b(i,3), fix_a(i,2), fix_a(i,3));
%     end
%     fclose(fileID2);
% 
%     %% 6. UNIFIED TWOS COMPLEMENT & HEX GENERATION
%     fileID3 = fopen(fname_IIR_fix_hex, 'w');
%     fprintf(fileID3, 'Band, b0, b1, b2, a1, a2\n');
% 
%     fix_hex_absb = cell(NumberOfBands, 3);
%     fix_hex_absa = cell(NumberOfBands, 3);
% 
%     for i = 1:NumberOfBands
%         for j = 1:3
%             % Convert scale factor cleanly back to direct integer steps
%             int_b = round(fix_b(i,j) * scale);
%             int_a = round(fix_a(i,j) * scale);
% 
%             % Safe Two's Complement encoding bounded strictly to your total bit-width container
%             if int_b < 0, int_b = int_b + 2^numBits; end
%             if int_a < 0, int_a = int_a + 2^numBits; end
% 
%             % Generate uniform-width hexadecimal strings for Xilinx COE mapping
%             fix_hex_absb{i,j} = dec2hex(int_b, ceil(numBits/4));
%             fix_hex_absa{i,j} = dec2hex(int_a, ceil(numBits/4));
%         end
% 
%         % Write directly into comma-separated hex asset tracking sheet
%         fprintf(fileID3, '%d,%s,%s,%s,%s,%s\n', ...
%             i, fix_hex_absb{i,1}, fix_hex_absb{i,2}, fix_hex_absb{i,3}, ...
%             fix_hex_absa{i,2}, fix_hex_absa{i,3});
%     end
%     fclose(fileID3);
% 
%     disp('Stable, mathematically bounded vocoder coefficients generated successfully.');
% 
%     %% 7. EXPORT DATA ARRAYS TO BASE WORKSPACE
%     assignin('base', 'fix_b', fix_b);
%     assignin('base', 'fix_a', fix_a);
%     assignin('base', 'fix_hex_absb', fix_hex_absb);
%     assignin('base', 'fix_hex_absa', fix_hex_absa);
% end


function filtersCoefficients()

global a b fix_a fix_b fix_hex_absb fix_hex_absa F BW Fs numBits NumberOfBands
global fname_IIR_full fname_IIR_fix fname_IIR_fix_hex

b = zeros(NumberOfBands, 3);
a = zeros(NumberOfBands, 3);

%% 1. FLOAT FILTER DESIGN
for i = 1:NumberOfBands

    f_low  = F(i) - BW(i)/2;
    f_high = F(i) + BW(i)/2;

    f_low  = max(0.001, min(0.999, f_low));
    f_high = max(0.001, min(0.999, f_high));

    [b_ch, a_ch] = butter(1, [f_low f_high], 'bandpass');

    % Normalize DC scaling (basic float normalization)
    a_ch = a_ch / a_ch(1);
    b_ch = b_ch / a_ch(1);

    a(i,:) = a_ch;
    b(i,:) = b_ch;
end

%% 2. FIXED POINT SETUP
fractional_bits = numBits - 3;   % safer headroom
scale = 2^fractional_bits;

%% 3. QUANTIZATION (ROUNDING)
fix_b = round(b * scale) / scale;
fix_a = round(a * scale) / scale;

%% 4. ? POST-QUANTIZATION STABILITY + GAIN FIX (IMPORTANT FIX)

for i = 1:NumberOfBands

    % ---- (A) prevent pole drift issues ----
    a0 = fix_a(i,1);
    fix_a(i,:) = fix_a(i,:) / a0;
    fix_b(i,:) = fix_b(i,:) / a0;

    % ---- (B) gain normalization (CRITICAL FIX) ----
    [h, ~] = freqz(fix_b(i,:), [1 fix_a(i,2:3)], 1024);

    gain = max(abs(h));

    if gain == 0
        gain = 1;
    end

    fix_b(i,:) = fix_b(i,:) / gain;
end

%% 5. FULL PRECISION FILE
fileID1 = fopen(fname_IIR_full,'w');
fprintf(fileID1,'Band, b0, b1, b2, a1, a2\n');

for i = 1:NumberOfBands
    fprintf(fileID1,'%d,%12.8f,%12.8f,%12.8f,%12.8f,%12.8f\n', ...
        i, b(i,1), b(i,2), b(i,3), a(i,2), a(i,3));
end
fclose(fileID1);

%% 6. FIXED DECIMAL FILE
fileID2 = fopen(fname_IIR_fix,'w');
fprintf(fileID2,'Band, b0, b1, b2, a1, a2\n');

for i = 1:NumberOfBands
    fprintf(fileID2,'%d,%12.8f,%12.8f,%12.8f,%12.8f,%12.8f\n', ...
        i, fix_b(i,1), fix_b(i,2), fix_b(i,3), fix_a(i,2), fix_a(i,3));
end
fclose(fileID2);

%% 7. HEX EXPORT (SAFE)
fileID3 = fopen(fname_IIR_fix_hex,'w');
fprintf(fileID3,'Band, b0, b1, b2, a1, a2\n');

fix_hex_absb = cell(NumberOfBands,3);
fix_hex_absa = cell(NumberOfBands,3);

for i = 1:NumberOfBands
    for j = 1:3

        int_b = round(fix_b(i,j) * scale);
        int_a = round(fix_a(i,j) * scale);

        % saturation protection
        int_b = max(min(int_b, 2^numBits-1), -2^numBits);
        int_a = max(min(int_a, 2^numBits-1), -2^numBits);

        if int_b < 0, int_b = int_b + 2^numBits; end
        if int_a < 0, int_a = int_a + 2^numBits; end

        fix_hex_absb{i,j} = dec2hex(int_b, ceil(numBits/4));
        fix_hex_absa{i,j} = dec2hex(int_a, ceil(numBits/4));

    end

    fprintf(fileID3,'%d,%s,%s,%s,%s,%s\n', ...
        i, fix_hex_absb{i,1}, fix_hex_absb{i,2}, fix_hex_absb{i,3}, ...
        fix_hex_absa{i,2}, fix_hex_absa{i,3});
end

fclose(fileID3);

disp('? Stable vocoder coefficients generated (gain-normalized + fixed-point safe)');

%% export
assignin('base','fix_b',fix_b);
assignin('base','fix_a',fix_a);
assignin('base','fix_hex_absb',fix_hex_absb);
assignin('base','fix_hex_absa',fix_hex_absa);

end