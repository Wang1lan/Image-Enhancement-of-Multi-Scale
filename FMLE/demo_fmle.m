clc;
clear;
close all;

% Single-image floating-point FMLE. Edit the settings here, then run.
fmleRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(fmleRoot,'functions'));
imagePath = fullfile(fmleRoot,'testImg','testImg_1.png');
cfg = fmleDefaultConfig('noisy');
roiFile = '';           % Optional roi.json from a previous run
selectRois = false;     % Draw new ROIs on the input image

img = readFmleImage(imagePath);
rois = fmleInputRois(img,imagePath,fmleRoot,roiFile,selectRois);
[out,dbg] = fmleEnhance(img,cfg);
[~,imageName] = fileparts(imagePath);
resultDir = fmleResultDir(fmleRoot,imageName,cfg.preset);
saveFmleStages(resultDir,img,out,dbg,rois,[],imagePath);
fprintf('FMLE result: %s\n',resultDir);
