function folder = fmleCompareCase(root,name,img,clean,rois,preset,source,generation)
% Compare fixed ablation settings; share the normalized decomposition and ROIs.
if nargin<8, generation = struct(); end
folder = fmleResultDir(root,name,'compare');
if ismatrix(img)
    Y = img; cb = []; cr = [];
else
    [Y,cb,cr] = rgbToYcbcrFull(img);
end
cfg = fmleDefaultConfig('noisy');
nlm = nlmTwoScale(Y,cfg);
cfgApprox = cfg;
cfgApprox.filterMode = 'approx';
nlmApprox = nlmTwoScale(Y,cfgApprox);
save(fullfile(folder,'shared.mat'),'Y','cb','cr','nlm','nlmApprox','clean','rois','-v7');
imwrite(im2uint16(img),fullfile(folder,'input.png'));
if ~isempty(clean), imwrite(im2uint16(clean),fullfile(folder,'clean.png')); end
imwrite(im2uint16(nlm.S1),fullfile(folder,'base.png'));
fmleWriteJson(fullfile(folder,'roi.json'),rois);

labels = {'A','B','C','D','D_d2','D_approx','identity_mask'};
configs = repmat(cfg,1,numel(labels));
configs(1).useMask = false; configs(1).fineMap.mode = 's';
configs(2).fineMap.mode = 's';
configs(3).useMask = false;
configs(5).maskSource = 'd2';
configs(6) = cfgApprox;
configs(7) = fmleDefaultConfig('identity');
if ~strcmpi(preset,'noisy')
    labels{end+1} = preset;
    configs(end+1) = fmleDefaultConfig(preset);
end
record = struct('input',name,'source',source,'generation',generation, ...
    'stagePreset',preset,'conditions',{labels},'configs',configs);
fmleWriteJson(fullfile(folder,'config.json'),record);
rows = cell(size(labels)); summaries = rows; globals = rows; images = rows;
for k = 1:numel(labels)
    if strcmp(configs(k).filterMode,'approx')
        active = nlmApprox;
    else
        active = nlm;
    end
    [~,dbg] = fmleApplyLayers(Y,active,configs(k));
    [out,dbg] = fmleRenderOutput(dbg,cb,cr);
    dirK = fullfile(folder,labels{k}); mkdir(dirK);
    images{k} = im2uint16(out);
    imwrite(images{k},fullfile(dirK,'output.png'));
    % The shared file stores the decomposition; keep the changed contributions here.
    save(fullfile(dirK,'fusion.mat'),'-struct','dbg','midWeighted','fineWeighted', ...
        'Zraw','Yout','clippingStats','-v7');
    [rows{k},summaries{k}] = evaluateFmle(dbg,rois,clean);
    globals{k} = fmleGlobalStats(dbg,rows{k});
    rows{k} = addvars(rows{k},repmat(string(labels{k}),height(rows{k}),1), ...
        'Before',1,'NewVariableNames','condition');
    summaries{k} = addvars(summaries{k},repmat(string(labels{k}),height(summaries{k}),1), ...
        'Before',1,'NewVariableNames','condition');
    globals{k} = addvars(globals{k},string(labels{k}),'Before',1,'NewVariableNames','condition');
    if (strcmp(preset,'noisy') && strcmp(labels{k},'D')) || strcmp(labels{k},preset)
        showFmleStages(dirK,img,out,dbg,rois);
    end
end
writetable(vertcat(rows{:}),fullfile(folder,'metrics.csv'));
writetable(vertcat(summaries{:}),fullfile(folder,'roi_summary.csv'));
writetable(vertcat(globals{:}),fullfile(folder,'global_metrics.csv'));
panels = [{img,nlm.S1,images{7}},images(1:6)];
titles = {'Input','Base (Y)','Identity + mask','A: S','B: S + mask', ...
    'C: inverse S','D: inverse S + mask','D: d2 mask','D: approx filter'};
fmleImageGrid(folder,'comparison.png',panels,titles,3,3,rois);
fmleRoiGrid(folder,'roi_comparison.png',[{img},images(1:4)], ...
    {'Input','A','B','C','D'},rois);
fprintf('FMLE comparison [%s]: %s\n',name,folder);
end
