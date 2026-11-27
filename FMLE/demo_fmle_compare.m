% Compare A-D, mask sources and normalization using fixed inputs and ROIs.
fmleRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(fmleRoot,'functions'),fullfile(fmleRoot,'tests'));
imagePath = fullfile(fmleRoot,'testImg','testImg_1.png');
runReal = true;
runSynthetic = true;
roiFile = '';           % Optional roi.json from a previous run
selectRois = false;

if runReal
    img = readFmleImage(imagePath);
    rois = fmleInputRois(img,imagePath,fmleRoot,roiFile,selectRois);
    [~,imageName] = fileparts(imagePath);
    fmleCompareCase(fmleRoot,imageName,img,[],rois,'noisy',imagePath);
    clear img
end
if runSynthetic
    cases = fmleSyntheticCases();
    for caseIndex = 1:numel(cases)
        sample = cases(caseIndex);
        fmleCompareCase(fmleRoot,sample.name,sample.img,sample.clean, ...
            sample.rois,sample.preset,'fmleSyntheticCases',sample.generation);
    end
end
