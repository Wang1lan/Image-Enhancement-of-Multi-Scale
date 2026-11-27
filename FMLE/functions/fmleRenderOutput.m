function [out,dbg] = fmleRenderOutput(dbg,Cb,Cr)
%FMLERENDEROUTPUT 灰度传入 []/[]；RGB 用原色度和已限幅亮度恢复并限幅。
if isempty(Cb) && isempty(Cr)
    out = dbg.Yout;
    return
end
startTime = tic;
dbg.Cb = Cb;
dbg.Cr = Cr;
dbg.rgbRaw = ycbcrToRgbFull(dbg.Yout,Cb,Cr);
out = min(max(dbg.rgbRaw,0),1);
clip = dbg.clippingStats;
clip.rgbRawMin = min(dbg.rgbRaw(:));
clip.rgbRawMax = max(dbg.rgbRaw(:));
clip.rgbBelowFraction = nnz(dbg.rgbRaw < 0)/numel(out);
clip.rgbAboveFraction = nnz(dbg.rgbRaw > 1)/numel(out);
clip.rgbClipFraction = clip.rgbBelowFraction+clip.rgbAboveFraction;
dbg.clippingStats = clip;
dbg.timing.totalSeconds = dbg.timing.totalSeconds+toc(startTime);
end
