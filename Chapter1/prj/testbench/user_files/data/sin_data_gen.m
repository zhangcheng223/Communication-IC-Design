% sin_data_gen.m
% 功能： 产生频率为10kHz的正弦波并保存为.dat文件
clc;
clear;
close all;

% 参数
fc = 1e4;                       % 载波频率
fs = 1e7;                       % 采样频率
N = 1e5;                        % 采样点数
Ts = 1/fs;                      % 采样周期
fileName = 'sin_data_fix.txt';  % 保存定点数据文件名

% 产生正弦采样点
t = [0:N-1].'*Ts;
x_sin_normal = sin(2*pi*fc*t);

% 定点化截断
x_sin_float = x_sin_normal*2^15;
x_sin_fix = fix(x_sin_normal*2^15);
x_bigger_index = find(x_sin_fix>0);
x_sin_fix(x_bigger_index) = x_sin_fix(x_bigger_index) - 1;

% 画出截断前后的波形
figure;
plot(t*1000, x_sin_float);
hold on;
plot(t*1000, x_sin_fix);
xlabel('ms');
ylabel('amplitude');
legend('浮点','定点');

fid = fopen(fileName, 'w');
fprintf(fid, '%d\n', x_sin_fix);
fclose(fid);

%% read
fid = fopen(fileName, 'r');
y_sin_fix = fscanf(fid, '%d\n');
