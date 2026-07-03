
% This file is an edit to the code available in the below link under its
% Appendix B section
%https://people.ece.cornell.edu/land/courses/ece5760/FinalProjects/s2019/...
% ...jc2697_jaj263_tk455/jc2697_jaj263_tk455/jc2697_jaj263_tk455/index.html
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
%--The following files will be used to store the coefficients of the 32 IIR
% filters, "full": for the real value; "fix" for the values of the coefficients
% when represented with numberofbits bits using truncation; "hex" for the hex
% representation of the fix values

fname_IIR_full='IIR_coef_full.txt';
fname_IIR_fix='IIR_coef_fix.txt';
fname_IIR_fix_hex='IIR_coef_fix_hex.txt';

% sampling frequency
Fs = 8000 ;

voice_input = audioread(audiofile);
voice_input = voice_input/max(voice_input);

% The bandwidths of the spectrum sub-bands 
M = linspace(401.25, 2016, NumberOfBands);
F = 700*(exp(M/1125)-1)/(Fs/2);
% make the bandpass edges cross at about 50%
BW = 0.035*(0.15 ./(F) + 1); % of freq

%- calculate the IIR filters coefficients and store them in files
filtersCoefficients();

% Optional: plot freq response of the filters with full precision
% coefficients and total number of bits numBits
plotSpectrum();

% Transform the audio signal using full precision filters coefficients
synthesis_full(ModulationFactor);

% Transform the audio signal using fixed precision filters coefficients
synthesis_fix(ModulationFactor);


