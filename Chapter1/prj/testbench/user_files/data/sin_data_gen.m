% sin_data_gen.m
% ���ܣ� ����Ƶ��Ϊ10kHz�����Ҳ�������Ϊ.dat�ļ�
clc;
clear;
close all;

% ����
fc = 1e4;                       % �ز�Ƶ��
fs = 1e7;                       % ����Ƶ��
N = 1e5;                        % ��������
Ts = 1/fs;                      % ��������
fileName = 'sin_data_fix.txt';  % ���涨�������ļ���

% �������Ҳ�����
t = [0:N-1].'*Ts;
x_sin_normal = sin(2*pi*fc*t);

% ���㻯�ض�
x_sin_float = x_sin_normal*2^15;
x_sin_fix = fix(x_sin_normal*2^15);
x_bigger_index = find(x_sin_fix>0);
x_sin_fix(x_bigger_index) = x_sin_fix(x_bigger_index) - 1;

% �����ض�ǰ��Ĳ���
figure;
plot(t*1000, x_sin_float);
hold on;
plot(t*1000, x_sin_fix);
xlabel('ms');
ylabel('amplitude');
legend('����','����');

fid = fopen(fileName, 'w');
fprintf(fid, '%d\n', x_sin_fix);
fclose(fid);

%% read
fid = fopen(fileName, 'r');
y_sin_fix = fscanf(fid, '%d\n');
