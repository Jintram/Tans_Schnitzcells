clear all
close all

folder = ['D:\movies\2010-09-02\pos6\images\'];
prefix = 'pos6-r-';

postfix = '.tif';
cd(folder);
filesToAnalyse = dir([prefix '*']);
N = length(filesToAnalyse)
temptimeList = [];
fluoList = [];
for ii = 1:N
    tempName = filesToAnalyse(ii).name;
    tempTime = str2double(filesToAnalyse(ii).date([13 14]))*3600 + str2double(filesToAnalyse(ii).date([16 17]))*60 + str2double(filesToAnalyse(ii).date([19 20]));
    temptimeList = [temptimeList tempTime];
    image = imread(tempName);
    fluoList = [fluoList mean(mean(image))];
end

timeList = (temptimeList - min(temptimeList))/60;  %Minutes

figure;
plot(timeList,fluoList,'or')


% [timeList indiceTime] = sort(temptimeList);
% imageList = [];
% for ii = 1:N
% imageList = [imageList ; filesToAnalyse(indiceTime(ii)).name]
% end


