clc
clear all
close all

%% Write .tif sequence
Numframes = 10;

for i = 1:Numframes
     filename = ['Sample_processed_',sprintf('%04d',i),'.tif']
     %imwrite(I(:,:,i),filename) ; 
end