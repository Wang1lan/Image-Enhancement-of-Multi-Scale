function rois = fmleInputRois(img,path,root,roiFile,selectNew)
% Load saved coordinates, use the supplied example or select on a new image.
if selectNew
    rois = fmleSelectRois(img);
elseif ~isempty(roiFile)
    rois = jsondecode(fileread(roiFile));
elseif strcmpi(path,fullfile(root,'testImg','testImg_1.png'))
    rois = fmleSampleRois();
else
    rois = fmleSelectRois(img);
end
for k = 1:numel(rois)
    if isempty(rois(k).period)
        rois(k).period = NaN;
    end
    rois(k).rect = reshape(rois(k).rect,1,4);
    if ~isempty(rois(k).line)
        rois(k).line = reshape(rois(k).line,1,4);
    end
end
end
