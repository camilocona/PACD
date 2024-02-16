%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Clase PAM, banda-base, banda-pasante
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; close all; clc;

M = 2;            %Número de niveles
Rsym = 5e6;       %Tasa de Símbolo (Bit)
Fc = 10e6;        %Frecuencia de Portadora
Fs = 8 * Fc;      %Frecuencia de Muestreo
sps = Fs/Rsym;    %Número de muestras por símbolo
span = 16;        %Expansión del filtro
NoBits = 1024;    %Número de Bits
rng default

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%1. Bits
bits = randi([0 M-1],NoBits,1);
bits_up = upsample(bits,sps);
figure, stem(bits_up(1:5*sps),'db'),
axis([0 5*sps+1 0 inf]), grid on, 
title(['5 Bits con ',num2str(sps),' muestras por periodo']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%2. Fitro para Forma de Pulso: Raíz de Coseno Realzado 
fig = 1; filtro = zeros(1,span*sps+1,5);
for roff = 0:0.25:1                          % La variación es el Roll-Off
    filtro(:,:,fig) = rcosdesign(roff,span,sps);
    fig = fig+1;
end
figure, 
plot(filtro(:,:,1),'-ob'),    %Roll-Off = 0.0
axis([0 length(filtro(:,:,1)) min(min(filtro))-0.1 max(max(filtro))+0.1]), grid on, hold on, 
title('Respuesta al Impulso RRC'); 
plot(filtro(:,:,3),'-sk'),    %Roll-Off = 0.5
plot(filtro(:,:,5),'-hr'),    %Roll-Off = 1.0
legend('roll-off = 0.0','roll-off = 0.5','roll-off = 1.0');

% fvtool(filtro(:,:,3), 'Analysis', 'impulse') % MatlabTool Respuesta Impulso

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%3. Forma de Pulso (Pulse Shaping)

%3.1. Pulse Shaping, Roll-Off = 0.0
Pulses_0p0 = upfirdn(bits,filtro(:,:,1),sps);   %Con sobre-muestreo de sps muestras por simbolo
Pulses_0p0 = Pulses_0p0 - mean(Pulses_0p0);
Pulses_0p0_recortado = Pulses_0p0(span*sps+1:end-span*sps); %Se eliminan los primeros y últimos símbolos
%figure, plot(Pulses_0p0_recortado,'-d'); grid on; title('Forma de Pulso, Roll-Off = 0.0');

%3.2. Pulse Shaping, Roll-Off = 0.25
Pulses_0p25 = upfirdn(bits,filtro(:,:,2),sps);   %Con sobre-muestreo de sps muestras por simbolo
Pulses_0p25 = Pulses_0p25 - mean(Pulses_0p25);
Pulses_0p25_recortado = Pulses_0p25(span*sps+1:end-span*sps); %Se eliminan los primeros y últimos símbolos
%figure, plot(Pulses_0p25_recortado,'-d'); grid on; title('Forma de Pulso, Roll-Off = 0.25');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%4. Función de Matlab para calcular el Diagrama de Ojo

%4.1. Función de Matlab
eyediagram(Pulses_0p0_recortado(1:end-1),1*sps); grid on;

figure,
%4.2. Función "Paso a Paso"
for m = sps/2:sps:length(Pulses_0p0_recortado)-sps
    plot(Pulses_0p0_recortado(m:m+sps),'-o'), hold on; grid on;
    title('Diagrama de Ojo - "Paso a Paso"');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%5. Modulación Banda Pasante

%5.1. Generación de portadora - Seno
NoBits_BP = (length(Pulses_0p25_recortado)-1)/sps;  %Número Bits Procesados
t = (0:1/Fs:(NoBits_BP/Rsym)-1/Fs).';
carrier = sqrt(2)*exp(1i*2*pi*Fc*t);   %Generada como una Exponencial

%5.2. Modulación 
Pulses_0p25_up = (Pulses_0p25_recortado(1:end-1)).*real(carrier);  %Banda Pasante
Pulses_0p25_BB = Pulses_0p25_recortado(1:end-1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%6. Espectro de Potencia, PAM Banda Base

SA = dsp.SpectrumAnalyzer('SampleRate',Fs,'Method','Filter bank',...
    'SpectrumType','Power','PlotAsTwoSidedSpectrum',true,...
    'ChannelNames',{'Power spectrum of the input'},'YLimits',[-100 20],'ShowLegend',true);

data = [];
for Iter = 1:3500
    Input = Pulses_0p25_up + Pulses_0p25_BB;
    NoisyInput = Input; 
    SA(NoisyInput);
     if SA.isNewDataReady
        data = [data;getSpectrumData(SA)];
     end
end
release(SA);