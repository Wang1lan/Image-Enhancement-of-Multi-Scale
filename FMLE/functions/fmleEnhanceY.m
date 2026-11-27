function [Yout,dbg] = fmleEnhanceY(Y,cfg)
%FMLEENHANCEY 处理 H×W 灰度/亮度，返回 double [0,1] 及浮点中间量。
startTime = tic;
if nargin < 2
    cfg = fmleDefaultConfig();
end
if ~ismatrix(Y)
    error('FMLE:LuminanceShape','fmleEnhanceY 需要二维亮度矩阵。');
end
Y = fmleNormalizeInput(Y);
nlm = nlmTwoScale(Y,cfg);
[Yout,dbg] = fmleApplyLayers(Y,nlm,cfg);
dbg.timing.totalSeconds = toc(startTime);
end
