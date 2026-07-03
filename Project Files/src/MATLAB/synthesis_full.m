% synthesis_full.m

% An example of what a perfect computer-calculated vocoder sounds like.

function synthesis_full(ModulationFactor)
    global b a voice_input Fs NumberOfBands
    
    nSamples = length(voice_input);
    synthesized_signal = zeros(nSamples, 1);
    
    % Define a basic low-pass filter to extract the volume envelope (~20-50 Hz)
    [b_lpf, a_lpf] = butter(2, 30/(Fs/2), 'low');
    
    % Create your carrier signal (white noise or a rich harmonic buzz)
    % This matches your high-speed hardware synthesis domain
    t = (0:nSamples-1)' / Fs;
    carrier = sign(sin(2*pi*140*t)) + (rand(nSamples, 1) - 0.5) * 0.2; 
    
    for i = 1:NumberOfBands
        % 1. Extract the audio information inside this specific band
        band_speech = filter(b(i,:), a(i,:), voice_input);
        
        % 2. Full-wave rectification & Low-pass filtering to track the volume envelope
        envelope = filter(b_lpf, a_lpf, abs(band_speech));
        
        % 3. Filter the carrier signal in this exact same band
        band_carrier = filter(b(i,:), a(i,:), carrier);
        
        % 4. Modulate and scale by your custom volume factor
        modulated_band = band_carrier .* envelope * ModulationFactor;
        
        % 5. Add back to the master accumulator bucket
        synthesized_signal = synthesized_signal + modulated_band;
    end
    
    % Normalize output to protect your ears/speakers
    synthesized_signal = synthesized_signal / max(abs(synthesized_signal));
    sound(synthesized_signal, Fs);
    disp('Completed Floating-Point Synthesis Audio Playback.');
end