clc
clear all
close all

%% Segmenting of rat scans 
% 1) Load to 3D array
% 2) Apply some Pre processing tansforms
% 3) Edge detection/Threshold/Texture analysis for segmentation
% 4) Based of segmentation, reduce image size to minimum possible
%
tic
%% Load
path = "I:\image_stack_example_SPring_8\";
file_handle = "mouse21_06_ro_2DNLM*.tif";
dirOutput = dir(fullfile(path,file_handle)); %%% lists files in the folder that meet criteria
fileNames = {dirOutput.name}';
TotalFrames = numel(fileNames);
stitches = ceil(TotalFrames/200); % No more than 100 slices to process at any time, could increase?
FrameBounds = ceil(linspace(1,TotalFrames,stitches));

x_min = [];
x_max = [];
y_min = [];
y_max = [];

for stitch = 2:length(FrameBounds);

    if stitch == 2
      numFrames = FrameBounds(stitch-1):FrameBounds(stitch);     
    else
      numFrames = (FrameBounds(stitch-1)+1):FrameBounds(stitch);  
    end

rng = max(numFrames) - min(numFrames);
I = imread(path + fileNames{numFrames(1)}); %%% creating an empty m by n by p array
sequence = zeros([size(I) rng],class(I));
sequence(:,:,1) = I;
sequence_masked = zeros([size(I) rng],class(I));
for p = 2:length(numFrames);   %%% reading images into the array
    sequence(:,:,p) = imread(path + fileNames{numFrames(p)});
end

sequence = im2uint8(sequence);
figure(1);
imhist(sequence,255); % overall histogram of image sequence
ixjxk = size(sequence);
figure(2);
sliceViewer(sequence); % Slice view of original images
% sequence = histeq(sequence,255);
% figure(3);
% imhist(sequence,255); % overall histogram of image sequence
% figure(4);
% sliceViewer(sequence); % Slice view of original images


fprintf('Loaded \n');
toc
BW_thresh = zeros(ixjxk);
BW_thresh(sequence>145) = 1; % first threshold at 145 (units?)


% for k = 1:ixjxk(3);
%     for i=1:ixjxk(1);
%         for j=1:ixjxk(2);
%             if sequence(i,j,k)>= 145;
%                 BW_thresh(i,j,k)=1;
%             else
%                 BW_thresh(i,j,k)=0;
%             end
%         end
%     end
% end

% for k = 1:ixjxk(3);
%     for i=1:ixjxk(1);
%         for j=1:ixjxk(2);
%             if sequence(i,j,k)>= 110 & sequence(i,j,k)<= 120;
%                 BW_shadow_thresh(i,j,k)=1;
%             else
%                 BW_shadow_thresh(i,j,k)=0;
%             end
%         end
%     end
% end
% se = strel('disk',3);
% BW_shadow_thresh = imerode(BW_shadow_thresh,se);


figure(1);
sliceViewer(BW_thresh);
se = strel('disk',3);
BW = imerode(BW_thresh,se);
% figure(3);
% sliceViewer(BW);
% figure(13);
% sliceViewer(BW_shadow_thresh);
% fprintf('Initial thresholds \n');

% % Dont think we even need this now
CC = bwconncomp(BW);
numPixels = cellfun(@numel,CC.PixelIdxList);
% [peaks, locs] = findpeaks(numPixels,'MinPeakProminence',2e5);
% idx_2_clear = [];
% for i = 1:length(locs);
% idx_2_clear = [idx_2_clear ; CC.PixelIdxList{locs(i)}];
% end
% BW(idx_2_clear) = 0;
% %
volume_threshold = max(numPixels)/25;

BW = bwareaopen(BW,round(volume_threshold)); % quite good

figure(4)
sliceViewer(BW)

for k = 1:ixjxk(3);
BW(:,:,k) = imfill(BW(:,:,k),'holes');
end
se = strel('disk',8);
BW = imdilate(BW,se);
BW = imclose(BW,se);
for k = 1:ixjxk(3);
BW(:,:,k) = imfill(BW(:,:,k),'holes');
end
combined = double(sequence) + 255*double(BW);
BW_combined = 255*double(BW_thresh) + 127*double(BW); 

figure(6);
sliceViewer(uint8(BW_combined));

bounds = zeros(ixjxk);
con_parts = zeros(ixjxk);
for K = 1:ixjxk(3);
    [B,L] = bwboundaries(BW(:,:,K),'noholes');
    try
        [B2,L2] = bwboundaries(BW(:,:,K + 1),'noholes');
        [B1,L1] = bwboundaries(BW(:,:,K - 1),'noholes');
        B = [B1;B;B2];
        L = L1 + L + L2;
    end
    for k = 1:length(B)
        boundary = B{k};
        for i = 1:length(boundary(:,1));
            bounds(boundary(i,1),boundary(i,2),K) = 1;
        end
    end
end
Intersect_points = (bounds & BW_thresh);
idx = find(Intersect_points); % id of intersecting points
[rows,cols,slice] = ind2sub(size(Intersect_points),idx); %
for i = 1:length(rows)
    if con_parts(rows(i),cols(i),slice(i)) == 0; % stops filling is equivalent fill has alredy been done
        con_parts(:,:,slice(i)) = con_parts(:,:,slice(i)) + grayconnected(BW_thresh(:,:,slice(i)),rows(i),cols(i));
%         idx = find(con_parts(:,:,slice(i)));
%         [rows2,cols2,slice2] = ind2sub(size(con_parts(:,:,slice(i))),idx);
    else
    end
end
% dilate connected parts
con_parts = imdilate(con_parts,strel('disk',4)); 
fprintf('First round of connected boundaries \n');
figure(10)
sliceViewer(con_parts)
toc


% bounds = zeros(ixjxk);
% for K = 1:ixjxk(3);
% [B,L] = bwboundaries(BW_shadow_thresh(:,:,K),'noholes');
% try
% [B2,L2] = bwboundaries(BW_shadow_thresh(:,:,K + 1),'noholes');
% [B1,L1] = bwboundaries(BW_shadow_thresh(:,:,K - 1),'noholes');
% B = [B1;B;B2];
% L = L1 + L + L2;
% end
% for k = 1:length(B)
%    boundary = B{k};
%     for i = 1:length(boundary(:,1));
%         bounds(boundary(i,1),boundary(i,2),K) = 1;
%     end 
% end
% end
% Intersect_points = (bounds & BW_thresh);
% idx = find(Intersect_points); % id of intersecting points
% [rows,cols,slice] = ind2sub(size(Intersect_points),idx); %
% for i = 1:length(rows)
%     if con_parts(rows(i),cols(i),slice(i)) == 0; % stops filling is equivalent fill has alredy been done 
%         con_parts(:,:,slice(i)) = con_parts(:,:,slice(i)) + grayconnected(BW_thresh(:,:,slice(i)),rows(i),cols(i));
%     else
%     end
% end
% 
% 

% Repeat using connected parts extension:
bounds = zeros(ixjxk);
con_parts2 = zeros(ixjxk);
for K = 1:ixjxk(3);
[B,L] = bwboundaries(con_parts(:,:,K),'noholes');
try
    try
    [B3,L3] = bwboundaries(con_parts(:,:,K + 5),'noholes');
    catch
    [B3,L3] = bwboundaries(con_parts(:,:,ixjxk(3)),'noholes');
    end
[B2,L2] = bwboundaries(con_parts(:,:,K + 1),'noholes');
[B1,L1] = bwboundaries(con_parts(:,:,K - 1),'noholes');
B = [B1;B;B2;B3];
L = L1 + L + L2 + L3;
end
for k = 1:length(B)
   boundary = B{k};
    for i = 1:length(boundary(:,1))
        bounds(boundary(i,1),boundary(i,2),K) = 1;
    end 
end
end
Intersect_points = (bounds & BW_thresh);
idx = find(Intersect_points); % id of intersecting points
[rows,cols,slice] = ind2sub(size(Intersect_points),idx); %
for i = 1:length(rows)
    if con_parts2(rows(i),cols(i),slice(i)) == 0; % stops filling is equivalent fill has alredy been done 
        con_parts2(:,:,slice(i)) = con_parts2(:,:,slice(i)) + grayconnected(BW_thresh(:,:,slice(i)),rows(i),cols(i));
    else
    end
end
% dilate connected parts
%con_parts2 = imdilate(con_parts2,strel('disk',1)); 
fprintf('Second round of connected boundaries \n');
toc

doubled_up= 255*double(con_parts2) + 140*double(con_parts) + 70*double(BW); 
% figure(10)
% sliceViewer(uint8(doubled_up));
doubled_up = con_parts2 + con_parts + BW;
clear BW BW_thresh Intersect_points con_parts con_parts2
% rand range
a = 124;
b = 134;

sequence(doubled_up>1) = round((b-a).*rand(1) + a);

% for k = 1:ixjxk(3);
%     for i=1:ixjxk(1);
%         for j=1:ixjxk(2);
%             if doubled_up(i,j,k) >= 1;
%                 sequence(i,j,k)=round((b-a).*rand(1) + a);
%             else
%                 sequence(i,j,k)=sequence(i,j,k);
%             end
%         end
%     end
% end

% figure(7);
% sliceViewer(sequence);
clear bounds BW_combined combined doubled_up I random_BW L idx cols boundary rows
fprintf('Hidden hard tissues \n');
toc

%% Texture analysis
% lack of contrast between lung, soft tissue and background means
% thresholding would unlikley work. Many strong edges such as bone and body
% boundary that would be picked up by edge detection. My first attempt
% would be to examine the texture across the image, as the higher
% randomness within the lungs may be an easy find.


%H1 = logical(ones(15,15));
%H2 = logical(ones(7,7));
H3 = logical(ones(9,9));
% ENT1 = entropyfilt(sequence,H1);
% ENT2 = entropyfilt(sequence,H2);
ENT3 = entropyfilt(sequence,H3);
fprintf('Entropy filter \n')
toc


% figure(5);
% sliceViewer(ENT3);

ENT3_scaled = rescale(ENT3);
sequence_binary = imbinarize(ENT3_scaled,0.75); % Hard number, may not be robust
%ct = bwconncomp(sequence_binary)
clear ENT3_scaled
% Threshold that targets the strong edges of airways
for k = 1:ixjxk(3);
    for i=1:ixjxk(1);
        for j=1:ixjxk(2);
            if sequence(i,j,k)<= 115 & sequence(i,j,k)>= 90; % optimised thresholds
                % another tech for finding these circular objects would be
                % ideal
                BW(i,j,k)=1;
            else
                BW(i,j,k)=0;
            end
        end
    end
end

sequence_binary = sequence_binary + BW;
reduced_ENT3 = bwareaopen(sequence_binary,1e5); % hard number

se = strel('disk',10);
for k = 1:ixjxk(3);
    reduced_ENT3(:,:,k) = imfill(reduced_ENT3(:,:,k),'holes');
end

CC = bwconncomp(sequence_binary);
numPixels = cellfun(@numel,CC.PixelIdxList);
vol_lim = max(numPixels)/10;
reduced_ENT3 = bwareaopen(reduced_ENT3,round(vol_lim));

for k = 1:ixjxk(3);
    reduced_ENT3(:,:,k) = imclose(reduced_ENT3(:,:,k),se);
    reduced_ENT3(:,:,k) = imfill(reduced_ENT3(:,:,k),'holes');
    %reduced_ENT3(:,:,k) = bwconvhull(reduced_ENT3(:,:,k),'objects');
end


% figure(11);
% sliceViewer(reduced_ENT3);
%reduced_ENT3 = bwareafilt(sequence_binary,2);
CC = bwconncomp(reduced_ENT3);
stats = regionprops(CC,'centroid');
getgone = CC.PixelIdxList(1); % need a line to decide which object to remove
reduced_ENT3(getgone{1,1}) = 0;

combined = double(sequence) + 100*double(reduced_ENT3);

figure(12);
sliceViewer(uint8(combined));


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
x_min(end+1) = find(yonx,1,'first');
x_max(end+1) = find(yonx,1,'last');
y_min(end+1) = find(yony,1,'first');
y_max(end+1) = find(yony,1,'last');     
end

% x_min_crop = min(x_min);
% x_max_crop = max(x_max);
% y_min_crop = min(y_min);
% y_max_crop = max(y_max);

%% Write .tif sequence
for i = 1:length(numFrames);
filename = fullfile('E:\Processed_files\',['Processed_stitch_scan_',sprintf('%04d',numFrames(i)),'.tif']);
imwrite(sequence_masked(:,:,i),filename);
end
fprintf("Done and written this stitch \n")
toc
end
save("crop_data","y_min","y_max","x_min","x_max");
% sequence_cropped = sequence_masked(y_min_crop:y_max_crop,x_min_crop:x_max_crop,:);
% 
% figure(100);
% sliceViewer(sequence_cropped);
% 

toc






