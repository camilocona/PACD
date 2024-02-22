%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Clase PSK (Phase Shift Keying)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all; clear; clc;

%1. Parametros
span = 8;          % Filter span
rolloff = 0.0;      % Rolloff factor
sps = 8;            % Samples per symbol
M = 4;              % Tamaño formato de Modulación
k = log2(M);        % Bits/symbol
phOffset = pi/4;    % Phase offset (radianes)
NumSym = 500;       % Número de Símbolos generados
n = 1;              % Plot every nth value of the signal
offset = 0;         % Plot every nth value of the signal, starting from offset+1

Rsym = 0.5e6;       % Symbol Rate
Fs = Rsym * sps;    % Sampling Frequency

ojos = 0;           % Graficar diagramas de ojo si = 1

A_Esp = 0;          % Analizador de espectro si = 1

%2. Coeficientes del Filtro
filtCoeff = rcosdesign(rolloff,span,sps);

%3. Generación de Símbolos aleatorios para un alfabeto de tamaño M
rng default
data = randi([0 M-1],NumSym,1);

%4. Modulación QPSK
dataMod = pskmod(data,M,phOffset);

%5. Formación de la señal modulada (Tx)
txSig = upfirdn(dataMod,filtCoeff,sps);

%6. Cálculo de SNR para una señal sobre-muestreada
EbNo = 50;
snr = EbNo + 10*log10(k) - 10*log10(sps);

%7. Adicionando AWGN a la señal transmitida
rxSig = awgn(txSig,snr,'measured');

%8. Aplicación del Filtro Receptor (Rx)
rxSigFilt = upfirdn(rxSig, filtCoeff,1,sps);

%9. Demodulación de señal recibida
dataOut = pskdemod(rxSigFilt,M,phOffset,'gray');

%10. Diagrama de constelación

h = scatterplot(rxSigFilt(span+1:end-span),n,offset,'bx');
hold on
scatterplot(dataMod,n,offset,'r*', h)
%scatterplot(sqrt(sps)*txSig(sps*span+1:end-sps*span),sps,offset,'g.', h);
title(['SNR ',num2str(snr),', Diagrama de Constelación']);
legend('Received Signal','Ideal'), grid on;

%%

%11. Diagrama de Ojo de la señal transmitida

if ojos == 1
    
eyediagram(real(txSig(sps*span+1:sps*span+1000)),2*sps), 
title(['Roll-Off ',num2str(rolloff),', Señal Tx, In-Phase']);

eyediagram(imag(txSig(sps*span+1:sps*span+1000)),2*sps), 
title(['Roll-Off ',num2str(rolloff),', Señal Tx, Quadrature']);

%12. Diagrama de Ojo de la señal recibida

eyediagram(real(rxSig(sps*span+1:sps*span+1000)),2*sps), 
title(['SNR ',num2str(snr),', Señal Rx, In-Phase']);

eyediagram(imag(rxSig(sps*span+1:sps*span+1000)),2*sps), 
title(['SNR ',num2str(snr),', Señal Rx, Quadrature']);

end

%%

%13. Análisis Espectral 

if A_Esp == 1

SA = dsp.SpectrumAnalyzer('SampleRate',Fs,'Method','Filter bank',...
    'SpectrumType','Power','PlotAsTwoSidedSpectrum',true,...
    'ChannelNames',{'Power spectrum of the input'},'YLimits',[-120 40],'ShowLegend',true);

data = [];
for Iter = 1:1000
    Input = real(rxSig);
    NoisyInput = Input; 
    SA(NoisyInput);
     if SA.isNewDataReady
        data = [data;getSpectrumData(SA)];
     end
end
release(SA);

end

