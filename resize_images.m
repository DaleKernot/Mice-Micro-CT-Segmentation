clc
clear all
close all

%% Resize images
%% Load
path = "G:\image_stack_example_SPring_8\";
file_handle = "mouse21_06_ro_2DNLM0*.tif";
dirOutput = dir(fullfile(path,file_handle)); %%% lists files in the folder that meet criteria
fileNames = {dirOutput.name}';
numFrames = numel(fileNames);
numFrames = 300;
I = imread(path + fileNames{1}); %%% creating an empty m by n by p array
sequence = zeros([size(I) numFrames],class(I));
sequence(:,:,1) = I;
sequence_masked = zeros([size(I) numFrames],class(I));
for p = 2:numFrames   %%% reading images into the array
    sequence(:,:,p) = imread(path + fileNames{p});
end
% and the previously formed BW mask:
load("BWone2three.mat");

ixjxk = size(sequence);

for k = 1:ixjxk(3);
    for j = 1:ixjxk(2);
        for i = 1:ixjxk(1);
            if reduced_ENT3(i,j,k) == 0;
                sequence_masked(i,j,k) = 0;
            else
                sequence_masked(i,j,k) = sequence(i,j,k);
            end
        end
    end
yonx = any(sequence_masked(:,:,k));
yony = any(sequence_masked(:,:,k)');
x_min(k) = find(yonx,1,'first');
x_max(k) = find(yonx,1,'last');
y_min(k) = find(yony,1,'first');
y_max(k) = find(yony,1,'last');     
end

x_min_crop = min(x_min)
x_max_crop = max(x_max)
y_min_crop = min(y_min)
y_max_crop = max(y_max)

sequence_cropped = sequence_masked(y_min_crop:y_max_crop,x_min_crop:x_max_crop,:);

figure(1)
sliceViewer(sequence_cropped);

%% Write .tif sequence
for i = 1:numFrames;
filename = fullfile('G:\Processed_files\',['Processed_scan_',sprintf('%04d',i),'.tif']);
imwrite(sequence_cropped(:,:,i),filename);
end



















