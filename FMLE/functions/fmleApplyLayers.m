function [Yout,dbg] = fmleApplyLayers(Y,nlm,cfg)
%FMLEAPPLYLAYERS 在同一 NLM 结果上执行分解、映射、掩模融合及亮度限幅。
startTime = tic;
dbg.Yin = Y;
dbg.S1 = nlm.S1; dbg.S2 = nlm.S2;
dbg.d1 = nlm.d1; dbg.d2 = nlm.d2;
if isfield(nlm,'alpha1')
    dbg.alpha1 = nlm.alpha1;
    dbg.alpha2 = nlm.alpha2;
end
dbg.base = nlm.S1;
dbg.detailMid = nlm.S2-nlm.S1;
dbg.detailFine = Y-nlm.S2;
[dbg.M,dbg.Mraw] = buildStructureMask(nlm.d1,nlm.d2,cfg);
if ~isscalar(cfg.useMask) || ~ismember(cfg.useMask,[0 1])
    error('FMLE:UseMask','useMask 需为标量 true 或 false。');
end
if cfg.useMask
    dbg.Meff = dbg.M;
else
    dbg.Meff = ones(size(Y));
end
dbg.baseMapped = mapLayer(dbg.base,cfg.baseMap,'base');
dbg.midMapped = mapLayer(dbg.detailMid,cfg.midMap,'detail');
dbg.fineMapped = mapLayer(dbg.detailFine,cfg.fineMap,'detail');
[dbg.Zraw,dbg.midWeighted,dbg.fineWeighted] = ...
    blendLayers(dbg.baseMapped,dbg.midMapped,dbg.fineMapped,dbg.Meff);
Yout = min(max(dbg.Zraw,0),1);
dbg.Yout = Yout;
n = numel(Y);
clip.yRawMin = min(dbg.Zraw(:));
clip.yRawMax = max(dbg.Zraw(:));
clip.yBelowFraction = nnz(dbg.Zraw < 0)/n;
clip.yAboveFraction = nnz(dbg.Zraw > 1)/n;
clip.yClipFraction = clip.yBelowFraction+clip.yAboveFraction;
clip.yMeanChange = mean(Yout(:))-mean(Y(:));
clip.s1BelowFraction = nnz(nlm.S1 < 0)/n;
clip.s1AboveFraction = nnz(nlm.S1 > 1)/n;
clip.s2BelowFraction = nnz(nlm.S2 < 0)/n;
clip.s2AboveFraction = nnz(nlm.S2 > 1)/n;
clip.rgbRawMin = NaN; clip.rgbRawMax = NaN;
clip.rgbBelowFraction = NaN; clip.rgbAboveFraction = NaN;
clip.rgbClipFraction = NaN;
dbg.clippingStats = clip;
dbg.cfg = cfg;
dbg.timing = nlm.timing;
dbg.timing.layersSeconds = toc(startTime);
dbg.timing.totalSeconds = dbg.timing.nlmSeconds+dbg.timing.layersSeconds;
end
