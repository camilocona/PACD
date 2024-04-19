% Procesamiento Avanzado en Comunicaciones Digitales
% Prof. Jhon James Granada Torres
% Universidad de Antioquia

% clear
% clc
% close all

%% Cargar Datos

%folder_path = '/MATLAB Drive/28Gbd_16QAM2';

file = 'C:/PACDClase9_Ultimo/D1_LW100k_LP100e_3.mat';
loaded_data = load(file);

data = loaded_data.data;

% Reemplazar NaN por 0
%data(isnan(data)) = 0;


sig_rx_ = data(1:16384, 1) + 1i *data(1:16384, 2);
sig_tx = data(16389:32772, 1) + 1i * data(16389:32772, 2);

M = 16; %Formato de modulación cargado: 16-QAM o 64QAM

%Reemplazar lo anterior por la tarea de carga automática de datos

num_sym = length(sig_rx_);

k=log2(M);

cont=1;

%% Canal AWGN

for SNR=28:2:28

    SNR_v(cont)=SNR;

sig_rx=awgn(sig_rx_, SNR,'measured');


%% Demodulación sin ecualizar
sym_tx = qamdemod(sig_tx,M);

sym_rx = qamdemod(sig_rx,M);

%% Cálculo del BER sin ecualizar

BER= biterr(sym_rx, sym_tx)/(num_sym*k);

BER_v(cont)=BER;

BER_before_eq=BER

%% Ecualizador LMS

Coe=5;
mu=0.001;
trainlen=300;

eq_LMS = comm.LinearEqualizer( ...
    'Algorithm','LMS', ...
    'NumTaps',Coe, ...
    'StepSize',mu, ...
    'Constellation', qammod(0:M-1,M));
eq_LMS.ReferenceTap = 1;

sig_eq_lms = eq_LMS(sig_rx,sig_tx(1:trainlen));
sig_eq2_lms = sig_eq_lms(trainlen+1:end); %recorta la secuencia de entrenamiento
sym_eq2_lms = qamdemod(sig_eq2_lms,M);

BER_after_eq_LMS= biterr(sym_eq2_lms, sym_tx(trainlen+1:end))/((num_sym-trainlen)*k)

BER_eqv(cont)=BER_after_eq_LMS;

sig_eq=sig_eq2_lms; %para graficar al final sin importar el ecualizador usado

cont=cont+1;
end

%% Graficar
figure(7)
subplot(4,4,9)
plot(real(sig_rx), imag(sig_rx), '.black')
hold on
plot(real(sig_eq), imag(sig_eq), '.r')
xlabel('In-Phase')
ylabel('Quadrature')
legend('Sin ecualizar', 'Ecualizada LW = 1Hz')

figure(20)
%semilogy(SNR_v, BER_v,'-or','DisplayName','Sin ecualizar')
%hold on
semilogy(SNR_v, BER_eqv,'-*c' ,'DisplayName','Ecualizada LW = 100KHz')
hold on
grid on
xlabel('SNR [dB]')
ylabel('BER')
legend('show')
