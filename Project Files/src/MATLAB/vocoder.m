% vocoder.m


%-- ModulationFactor any positive integer value from 1 to thousands
%--numberofbits : total number of bits allocated to represent the IIR
%filters real coefficient values

function vocoder(ModulationFactor,numberofbits)
global a  b  fix_a fix_b fix_hex_absa  fix_hex_absb F  BW Fs
global numBits  NumberOfBands fname_IIR_full fname_IIR_fix fname_IIR_fix_hex 
global voice_input
 
%-- test input audio signal 
audiofile='test.wav';

numBits=numberofbits;

% The audio signal will be filtered by 32 pass bands IIR filters
NumberOfBands=32;  

% The following files will be used to store the coefficients of the 32 IIR filters
% - "full": for the real value; 
% - "fix" for the values of the coefficients when represented with numberofbits bits using truncation; 
% - "hex" for the hex representation of the fix values

fname_IIR_full='IIR_coef_full.txt';
fname_IIR_fix='IIR_coef_fix.txt';
fname_IIR_fix_hex='IIR_coef_fix_hex.txt';

% sampling frequency
Fs = 8000 ;

% Normalize between -1 to 1
voice_input = audioread(audiofile);
voice_input = voice_input/max(voice_input);


%% Logarithmic Mel-Scale Filter Spacing

% The bandwidths of the spectrum sub-bands 
M = linspace(401.25, 2016, NumberOfBands);
F = 700*(exp(M/1125)-1)/(Fs/2);

% Convert the normalized F back to Hz, then to 24-bit DDS tuning words
F_hz = F * (Fs/2);
phase_steps = (F_hz * ModulationFactor) / Fs;

% Make the bandpass edges cross at about 50%
BW = 0.035*(0.15 ./(F) + 1); % of freq

%% Helper Functions

% Calculate the IIR filters coefficients and store them in files
filtersCoefficients();

% Optional: plot freq response of the filters with full precision
% coefficients and total number of bits numBits
plotSpectrum();

% Transform the audio signal using full precision filters coefficients
synthesis_full(ModulationFactor);

% Transform the audio signal using fixed precision filters coefficients
synthesis_fix(ModulationFactor);


%% Send Variables to Workspace

assignin('base', 'Fs', Fs);
assignin('base', 'NumberOfBands', NumberOfBands);
assignin('base', 'numBits', numBits);
assignin('base', 'F', F);
assignin('base', 'phase_steps', phase_steps);

% Push the normalized 1D audio sample array (Your Simulink ROM Initializer)
assignin('base', 'audio_data', voice_input);