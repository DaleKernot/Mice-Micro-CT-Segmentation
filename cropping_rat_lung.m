clc
clear all
close all

path = "E:\Processed_files\";
file_handle = "Processed_stitchlong_scan_*.tif";
dirOutput = dir(fullfile(path,file_handle)); %%% lists files in the folder that meet criteria
fileNames = {dirOutput.name}';
TotalFrames = numel(fileNames);
%TotalFrames = 1000;
stitches = ceil(TotalFrames); % No more than 100 slices to process at any time, could uncrease?
FrameBounds = ceil(linspace(800,TotalFrames,stitches));

numFrames = FrameBounds;
numFrames = 1:300;

I = imread(path + fileNames{numFrames(1)}); %%% creating an empty m by n by p array
sequence = zeros([size(I) range(numFrames)],class(I));
sequence(:,:,1) = I;
for p = 2:length(numFrames);   %%% reading images into the array
    sequence(:,:,p) = imread(path + fileNames{numFrames(p)});
end
figure(1)
sliceViewer(sequence);

BW_mask = double(sequence);
BW_mask(sequence>0) = 1;

se = strel('disk',7);
se2 = strel('disk',15);
ixjxk = size(sequence);
for k = 1:ixjxk(3);
BW_mask(:,:,k) = imdilate(BW_mask(:,:,k),se);
BW_mask(:,:,k) = imclose(BW_mask(:,:,k),se2);
BW_mask2(:,:,k) = imfill(BW_mask(:,:,k),'holes');
end
figure(2)
sliceViewer(BW_mask2);


for k = 1:ixjxk(3);
    for j = 1:ixjxk(2);
        for i = 1:ixjxk(1);
            if BW_mask2(i,j,k) == 0;
                sequence_masked(i,j,k) = 0;
            else
                sequence_masked(i,j,k) = sequence2(i,j,k);
            end
        end
    end
end


path = "G:\image_stack_example_SPring_8\";
file_handle = "mouse21_06_ro_2DNLM*.tif";
dirOutput = dir(fullfile(path,file_handle)); %%% lists files in the folder that meet criteria
fileNames = {dirOutput.name}';
I = imread(path + fileNames{numFrames(1)}); %%% creating an empty m by n by p array
sequence2 = zeros([size(I) range(numFrames)],class(I));
sequence2(:,:,1) = I;
for p = 2:length(numFrames);   %%% reading images into the array
    sequence2(:,:,p) = imread(path + fileNames{numFrames(p)});
end
figure(2)
sliceViewer(sequence2);

% load("crop_datalong.mat")
% x_min_crop = min(x_min(1:TotalFrames));
% x_max_crop = max(x_max(1:TotalFrames));
% y_min_crop = min(y_min(1:TotalFrames));
% y_max_crop = max(y_max(1:TotalFrames));
% sequence_cropped = sequence(y_min_crop:y_max_crop,x_min_crop:x_max_crop,:);
% figure(2)
% sliceViewer(sequence_cropped);