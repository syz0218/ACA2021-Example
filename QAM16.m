clc,clear
% 参数设置
Rs = 8e6;                                            % 符号速率             
fs = 600e6;                                          % 采样频率
Lenth_msg = 2000;                                     % 符号数量
OSample = fs / Rs;                                   % 过采样率
f_carrier = 100e6;                                   % 载波频率

% 生成 16QAM 符号
M = 16;                                              % 16QAM
msg = randi([0 M-1], 1, Lenth_msg);                  % 随机生成符号
msg_mod = qammod(msg, M, 'UnitAveragePower', true);  % 16QAM 调制

% 根升余弦成型滤波
alpha = 0.5;
htx = rcosdesign(alpha, 6, OSample, 'sqrt');         % 根升余弦滤波器

msg_os = upsample(msg_mod, OSample);                 % 对信号进行过采样
Baseband_send = conv(msg_os, htx, 'same');           % 基带信号

% 上变频至中频
carrier_send = exp(1j * 2 * pi * f_carrier / fs * (1:length(Baseband_send)));
MF_QAM = Baseband_send .* carrier_send;              % 调制信号

EbN0 = -20:5;
BER_simulated_all = zeros(1,length(EbN0));
for i = 1:length(EbN0)
    % 通过AWGN信道传输
    SNR_dB = EbN0(i)-6.02;                                         % 信噪比(dB)
    MF_QAM_noisy = awgn(MF_QAM, SNR_dB, 'measured');     % 添加AWGN噪声

    % 下变频
    MF_QAM_received = MF_QAM_noisy .* conj(carrier_send);

    % 匹配滤波
    Baseband_received = conv(MF_QAM_received, fliplr(htx), 'same');

    % 下采样并判决
    msg_downsampled = downsample(Baseband_received, OSample);
    msg_received = qamdemod(msg_downsampled, M, 'UnitAveragePower', true);

    BER_simulated_all(i) = sum(msg ~= msg_received) / Lenth_msg;
end
%% 绘图
% 绘制基带信号时域波形
figure(1);
subplot(211);plot(real(Baseband_send));
title('基带信号时域波形');
grid on;
set(gca, 'FontSize',16);set(gcf, 'color', 'w');
% 绘制基带信号频谱
subplot(212);pwelch(Baseband_send, [], [], [], fs);
title('基带信号频谱');
grid on;
set(gca, 'FontSize',16);set(gcf, 'color', 'w');

% 绘制中频信号实部时域波形
figure(2);
subplot(211);plot(real(MF_QAM));
title('中频信号实部时域波形');
grid on;
set(gca, 'FontSize',16);set(gcf, 'color', 'w');
% 绘制中频信号频谱
subplot(212);pwelch(MF_QAM, [], [], [], fs);
title('中频信号频谱');
grid on;
set(gca, 'FontSize',16);set(gcf, 'color', 'w');

% 绘制加噪后的中频信号实部时域波形
figure(3);
subplot(211);plot(real(MF_QAM_noisy));
title('加噪后的中频信号实部时域波形');
grid on;
set(gca, 'FontSize',16);set(gcf, 'color', 'w');
% 绘制加噪后的中频信号频谱
subplot(212);pwelch(MF_QAM_noisy, [], [], [], fs);
title('加噪后的中频信号频谱');
grid on;
set(gca, 'FontSize',16);set(gcf, 'color', 'w');

figure(4);
subplot(211);plot(real(MF_QAM_received));
title('加噪后的低频信号实部时域波形(接收)');
grid on;
set(gca, 'FontSize',16);set(gcf, 'color', 'w');
% 绘制加噪后的中频信号频谱
subplot(212);pwelch(MF_QAM_received, [], [], [], fs);
title('加噪后的低频信号频谱(接收)');
grid on;
set(gca, 'FontSize',16);set(gcf, 'color', 'w');

% 绘制基带信号时域波形
figure(5);
subplot(211);plot(real(msg_received));
title('最终接收信号波形');
grid on;
set(gca, 'FontSize',16);set(gcf, 'color', 'w');

% 绘制基带信号频谱
subplot(212);pwelch(real(msg_received), [], [], [], fs);
title('最终接收信号频谱');
grid on;
set(gca, 'FontSize',16);set(gcf, 'color', 'w');

%% 性能分析
% 星座图
scatterplot(msg_downsampled);
title('星座图');
grid on;
set(gca, 'FontSize',16);

% 眼图
eyediagram(real(Baseband_received), 2*OSample);
title('眼图');
grid on;
set(gca, 'FontSize',16);
% 理论BER
BER_theoretical = berawgn(EbN0, 'psk', 2, 'nondiff');

% 绘制 BER 曲线
figure;
semilogy(EbN0, BER_simulated_all, '-*', EbN0, BER_theoretical, '-+');
xlabel('Eb/N0 (dB)');
ylabel('BER');
legend('Simulated', 'Theoretical');
title('BER vs. Eb/N0');
axis([EbN0(1) EbN0(end) 1e-5 5]);
grid on;
set(gca, 'FontSize',16);set(gcf, 'color', 'w');