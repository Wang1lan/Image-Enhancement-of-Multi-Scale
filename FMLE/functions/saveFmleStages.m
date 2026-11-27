function saveFmleStages(folder,img,out,dbg,rois,clean,source)
% Archive a complete single-preset run. PNGs are display data; MAT stays double.
imwrite(im2uint16(img),fullfile(folder,'input.png'));
imwrite(im2uint16(out),fullfile(folder,'output.png'));
fmleWriteJson(fullfile(folder,'config.json'),struct('source',source,'cfg',dbg.cfg));
fmleWriteJson(fullfile(folder,'roi.json'),rois);
[rows,summary] = evaluateFmle(dbg,rois,clean);
writetable(rows,fullfile(folder,'metrics.csv'));
writetable(summary,fullfile(folder,'roi_summary.csv'));
writetable(fmleGlobalStats(dbg,rows),fullfile(folder,'global_metrics.csv'));
save(fullfile(folder,'intermediate.mat'),'dbg','rois','clean','-v7');
showFmleStages(folder,img,out,dbg,rois);
end
