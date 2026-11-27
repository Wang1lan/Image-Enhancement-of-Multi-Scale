function [M,Mraw] = buildStructureMask(d1,d2,cfg)
%BUILDSTRUCTUREMASK 从指定尺度的原始权重和计算两细节层共用的软掩模。
switch cfg.maskSource
    case 'd1'
        d = d1;
    case 'd2'
        d = d2;
    otherwise
        error('FMLE:MaskSource','maskSource 需为 d1 或 d2。');
end
p = (2*cfg.searchRadius+1)^2;
Mraw = 1-d/p;
M = min(max(Mraw,0),1);
end
