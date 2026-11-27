function [rows, summary] = evaluateFmle(dbg, rois, clean)
% Evaluate the processed full frame and fixed ROIs, then average each ROI type equally.
% clean is a full-size clean luminance reference or []. Rectangles count pixels.
yin = dbg.Yin;
yout = dbg.Yout;
padding = dbg.cfg.borderMode;
% Compute residuals before cropping, including the real context around each ROI.
resIn = yin - imgaussfilt(yin,1,'Padding',padding,'FilterDomain','spatial');
resOut = yout - imgaussfilt(yout,1,'Padding',padding,'FilterDomain','spatial');
full = struct('id','full','type','image','rect',[1 1 size(yin,2) size(yin,1)], ...
    'line',[],'period',NaN);
regions = [full; rois(:)];
for k = 1:numel(regions)
    roi = regions(k);
    x = roi.rect(1) + (0:roi.rect(3)-1);
    y = roi.rect(2) + (0:roi.rect(4)-1);
    src = yin(y,x);
    dst = yout(y,x);
    raw = dbg.Zraw(y,x);
    hIn = resIn(y,x);
    hOut = resOut(y,x);
    mid = dbg.midWeighted(y,x);
    fine = dbg.fineWeighted(y,x);
    mask = dbg.M(y,x);
    q = maskPercentiles(mask);

    m.roiId = string(roi.id);
    m.roiType = string(roi.type);
    m.stdIn = std(src(:),1);
    m.stdOut = std(dst(:),1);
    m.stdRatio = ratio(m.stdOut,m.stdIn);
    m.highStdIn = std(hIn(:),1);
    m.highStdOut = std(hOut(:),1);
    m.highStdRatio = ratio(m.highStdOut,m.highStdIn);
    m.textureRmsIn = rmsValue(hIn);
    m.textureRmsOut = rmsValue(hOut);
    m.textureRmsRatio = ratio(m.textureRmsOut,m.textureRmsIn);
    m.sineAmpIn = NaN;
    m.sineAmpOut = NaN;
    if ~isempty(roi.period) && isfinite(roi.period)
        m.sineAmpIn = sineAmplitude(src,roi.period);
        m.sineAmpOut = sineAmplitude(dst,roi.period);
    end
    m.maskMin = min(mask(:));
    m.maskMax = max(mask(:));
    m.maskMean = mean(mask(:));
    m.maskP10 = q(1);
    m.maskMedian = q(2);
    m.maskP90 = q(3);
    m.midRms = rmsValue(mid);
    m.fineRms = rmsValue(fine);
    m.detailRms = rmsValue(mid + fine);
    m.overshootIn = NaN;
    m.undershootIn = NaN;
    m.overshootOut = NaN;
    m.undershootOut = NaN;
    if strcmp(roi.type,'edge')
        [m.overshootIn,m.undershootIn] = edgeExcursion(yin,roi.line);
        [m.overshootOut,m.undershootOut] = edgeExcursion(dbg.Zraw,roi.line);
    end
    m.rmseIn = NaN;
    m.psnrIn = NaN;
    m.rmseOut = NaN;
    m.psnrOut = NaN;
    if ~isempty(clean)
        ref = clean(y,x);
        m.rmseIn = rmsValue(src-ref);
        m.rmseOut = rmsValue(dst-ref);
        m.psnrIn = -20*log10(m.rmseIn);
        m.psnrOut = -20*log10(m.rmseOut);
    end
    m.rawMin = min(raw(:));
    m.rawMax = max(raw(:));
    m.clipFraction = mean(raw(:)<0 | raw(:)>1);
    m.meanIn = mean(src(:));
    m.meanOut = mean(dst(:));
    m.meanShift = m.meanOut-m.meanIn;
    measurements(k,1) = m; %#ok<AGROW>
end
rows = struct2table(measurements);
types = unique(rows.roiType,'stable');
numeric = rows.Properties.VariableNames(3:end);
values = NaN(numel(types),numel(numeric));
counts = zeros(numel(types),1);
for k = 1:numel(types)
    selected = rows.roiType == types(k);
    counts(k) = nnz(selected);
    values(k,:) = mean(rows{selected,numeric},1,'omitnan');
end
summary = [table(types,counts,'VariableNames',{'roiType','roiCount'}), ...
    array2table(values,'VariableNames',numeric)];
end

function r = ratio(out,in)
if in == 0
    r = NaN;
else
    r = out/in;
end
end

function v = rmsValue(a)
v = sqrt(mean(a(:).^2));
end

function q = maskPercentiles(mask)
% Percentile locations are centered on the ordered samples, as in prctile.
ordered = sort(mask(:));
n = numel(ordered);
pos = min(max(n*[0.1 0.5 0.9] + 0.5,1),n);
lo = floor(pos);
hi = ceil(pos);
q = ordered(lo(:)) + (pos(:)-lo(:)).*(ordered(hi(:))-ordered(lo(:)));
end

function amp = sineAmplitude(roi,period)
% Fit DC plus the in-phase and quadrature components at the known frequency.
x = (0:size(roi,2)-1)' * (2*pi/period);
coef = [ones(size(x)) cos(x) sin(x)] \ mean(roi,1)';
amp = hypot(coef(2),coef(3));
end

function [over, under] = edgeExcursion(image,segment)
% Each signal supplies its own two far-plateau estimates (outer fifths).
n = max(2,ceil(hypot(segment(3)-segment(1),segment(4)-segment(2)))+1);
xs = linspace(segment(1),segment(3),n);
ys = linspace(segment(2),segment(4),n);
profile = interp2(image,xs,ys,'linear');
tail = max(1,floor(n/5));
levels = [mean(profile(1:tail)), mean(profile(end-tail+1:end))];
over = max(0,max(profile)-max(levels));
under = max(0,min(levels)-min(profile));
end
