% synthesis_fix.m

% Introduces the precision loss of using finite hardware bits. 
% It simulates exactly what your Basys3 FPGA hardware will output.

function synthesis_fix(ModulationFactor)
    global fix_b fix_a voice_input Fs NumberOfBands
    
    nSamples = length(voice_input);
    synthesized_signal = zeros(nSamples, 1);
    
    % Core LPF envelope extractor
    [b_lpf, a_lpf] = butter(2, 30/(Fs/2), 'low');
    
    t = (0:nSamples-1)' / Fs;
    carrier = sign(sin(2*pi*140*t)) + (rand(nSamples, 1) - 0.5) * 0.2; 
    
    for i = 1:NumberOfBands
        % 1. Filter using your quantized hardware coefficients
        band_speech = filter(fix_b(i,:), fix_a(i,:), voice_input);
        
        % 2. Extract envelope
        envelope = filter(b_lpf, a_lpf, abs(band_speech));
        
        % 3. Apply quantized coefficients to the carrier band
        band_carrier = filter(fix_b(i,:), fix_a(i,:), carrier);
        
        % 4. Multiply and Accumulate
        modulated_band = band_carrier .* envelope * ModulationFactor;
        synthesized_signal = synthesized_signal + modulated_band;
    end
    
    synthesized_signal = synthesized_signal / max(abs(synthesized_signal));
    
    % Pause briefly so the previous audio playback doesn't overlap
    pause(length(voice_input)/Fs + 1); 
    sound(synthesized_signal, Fs);
    audiowrite('expected_output.wav', synthesized_signal, 8000);
    disp('Saved to expected_output.wav!');
    disp('Completed Hardware-Emulated Fixed-Point Synthesis Audio Playback.');
    
    assignin('base', 'y_fix', synthesized_signal);
    
end