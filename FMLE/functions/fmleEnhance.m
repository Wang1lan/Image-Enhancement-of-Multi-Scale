function [out,dbg] = fmleEnhance(img,cfg)
%FMLEENHANCE 灰度/RGB 入口，uint8、uint16 或 [0,1] 浮点输入，输出 double。
startTime = tic;
if nargin < 2
    cfg = fmleDefaultConfig();
end
if ~strcmp(cfg.colorStandard,'BT.709')
    error('FMLE:ColorStandard','本实现采用 BT.709 全范围颜色转换。');
end
if ismatrix(img)
    [out,dbg] = fmleEnhanceY(img,cfg);
else
    img = fmleNormalizeInput(img);
    [Y,Cb,Cr] = rgbToYcbcrFull(img);
    [~,dbg] = fmleEnhanceY(Y,cfg);
    [out,dbg] = fmleRenderOutput(dbg,Cb,Cr);
end
dbg.timing.totalSeconds = toc(startTime);
end
