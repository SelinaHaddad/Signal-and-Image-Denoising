clear all
close all
clc

fileID = fopen('ramp_T.txt','r'); 
Data_N0 = fscanf(fileID,'%40f\n' ); 
Data_N = Data_N0;% Copying data to a new variable
fclose(fileID);

Step_points = 200; % 200 or 100 or higher 
Iteration_cycle = 50;  % 5 or 10 or higher
epsilon = 0.0; % Threshold for the regularization process
lambda = 0.0001; % Regularization parameter (controls regularization strength)

kk = 0;
while kk < Iteration_cycle
    % Calculating the difference between subsequent elements
    Drevative_D = Data_N(2:end) - Data_N(1:end-1);
    
    % Ridge Regression (Tikhonov regularization) 
    Drevative_DUp0 = Drevative_D;
    Drevative_DDown0 = Drevative_D;
    % Setting values below the positive threshold to 0:
    Drevative_DUp0(Drevative_DUp0 < epsilon) = 0;
    % Setting values above the negative threshold to 0:
    Drevative_DDown0(Drevative_DDown0 > -epsilon) = 0;

    epsilon = epsilon^3; % Reducing epsilon's value with each iteration

    % Updating the signal with the regularization term
    Data_N_up = Data_N(2:end);
    Data_N_up(Drevative_DUp0 == 0) = 0;
    Data_N_up = [Data_N(1); Data_N_up];
    Data_N_up0 = Data_N_up;

    % Applying Tikhonov regularization and smoothing the signal
    if Data_N_up == 0
        start_i = 1;
    end

    for i = 2:length(Data_N_up)
        if Data_N_up(i) + Data_N_up(i-1) == 0
            continue
        end
        if Data_N_up(i-1) ~= 0 && Data_N_up(i) == 0
            start_i = i - 1;
        end
        if Data_N_up(i) ~= 0 && Data_N_up(i-1) == 0
            final_i = i;
            for j = start_i+1:i
                Data_N_up(j) = Data_N_up(start_i) + (j - start_i) * (Data_N_up(final_i) - Data_N_up(start_i)) / (final_i - start_i);
            end
        end
    end

    Graph_upper = Data_N_up; % Storing the upper part of the updated signal

    % Applying Tikhonov regularization (repeating the process for the lower
    % part of the signal)
    Data_N_up = Data_N(2:end);
    Data_N_up(Drevative_DDown0 == 0) = 0;
    Data_N_up = [Data_N(1); Data_N_up];
    Data_N_up0 = Data_N_up;

    if Data_N_up == 0
        start_i = 1;
    end

    for i = 2:length(Data_N_up)
        if Data_N_up(i) + Data_N_up(i-1) == 0
            continue
        end
        if Data_N_up(i-1) ~= 0 && Data_N_up(i) == 0
            start_i = i - 1;
        end
        if Data_N_up(i) ~= 0 && Data_N_up(i-1) == 0
            final_i = i;
            for j = start_i+1:i
                Data_N_up(j) = Data_N_up(start_i) + (j - start_i) * (Data_N_up(final_i) - Data_N_up(start_i)) / (final_i - start_i);
            end
        end
    end

    Graph_lower = Data_N_up; % Storing the lower part of the updated signal

    % Finding the last non-zero element if the last element of Graph_lower
    % =  0
    if Graph_lower(end) == 0
        for j = 1:length(Graph_lower)
            if Graph_lower(end - j) ~= 0
                posit = length(Graph_lower) - j;
                break
            end
        end
        for j = posit+1:length(Graph_lower)
            Graph_lower(j) = Graph_lower(j - 1);
        end
    end

    % Finding the last non-zero element if the last element of Graph_upper
    % =  0
    if Graph_upper(end) == 0
        for j = 1:length(Graph_upper)
            if Graph_upper(end - j) ~= 0
                posit = length(Graph_upper) - j;
                break
            end
        end
        for j = posit+1:length(Graph_upper)
            Graph_upper(j) = Graph_upper(j - 1);
        end
    end

    % Averaging the upper and lower regularization passes:
    signal_final = (Graph_lower + Graph_upper) / 2;
    % Replacing every signal calue with the mean of itsellf and the 4
    % nearest neighbors (used to smoothen the signal)
    for hh = 3:Step_points:(length(Data_N0)-3)
        signal_final(hh) = (Data_N0(hh - 2) + Data_N0(hh - 1) + Data_N0(hh) + Data_N0(hh + 1) + Data_N0(hh + 2)) / 5;
    end
    
    % Updating data with Tikhonov regularization term
    Data_N = Data_N + lambda * (signal_final - Data_N);

    kk = kk + 1;
    %fprintf('Iteration number = %d \n', kk)
end

subplot(3,1,1);
plot(signal_final,'b')
hold on
plot(Data_N0,'r')
title('Signal + trend (Zoom in to see better)')
subplot(3,1,2);
plot(signal_final,'g')
title('Trend Only=Signal without noise')
subplot(3,1,3); 
plot(Data_N0-signal_final,'r')
title('Noise only')

% To find the SNR:
noise = Data_N0 - signal_final;
snr_value = snr(signal_final,noise);
fprintf('SNR value: %.5f dB\n', snr_value);

% To find the MSE:
mse_value = immse(Data_N0, signal_final);
fprintf('MSE value: %.5f\n', mse_value);

% To find the RMSE:
rmse_value = sqrt(mse_value);
fprintf('RMSE value: %.5f\n', rmse_value);
