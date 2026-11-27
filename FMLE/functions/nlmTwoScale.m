function [layers, weights] = nlmTwoScale(Y,cfg,sampleOffset)
%NLMTWOSCALE 对 [0,1] double 亮度计算两尺度 NLM；两级均采样原始 Y。
% 第三参数 [dy dx] 仅供检查该搜索偏移的 k1/k2，无须保存整幅权重体。
startTime = tic;
if ~isscalar(cfg.numScales) || cfg.numScales ~= 2
    error('FMLE:Scales','numScales 必须为 2。');
end
rs = cfg.searchRadius;
rp = cfg.patchRadius;
validateattributes(rs,{'numeric'},{'real','scalar','integer','nonnegative','finite'});
validateattributes(rp,{'numeric'},{'real','scalar','integer','nonnegative','finite'});
validateattributes(cfg.hY,{'numeric'},{'real','scalar','positive','finite'});
if ~strcmp(cfg.borderMode,'replicate') || ~strcmp(cfg.patchDistance,'SSD')
    error('FMLE:NLMConvention','边界需为 replicate，块距离需为 SSD。');
end
computeSquare = strcmp(cfg.weightMode,'square');
if ~computeSquare && ~strcmp(cfg.weightMode,'direct')
    error('FMLE:WeightMode','weightMode 需为 square 或 direct。');
end
if nargout > 1
    if nargin < 3 || ~isequal(size(sampleOffset),[1 2]) || ...
            any(~ismember(sampleOffset,-rs:rs))
        error('FMLE:Offset','请指定搜索窗口内的整数偏移 [dy dx]。');
    end
end

[h,w] = size(Y);
% 两块均从同一份扩展图取样；只有在完成 patch SSD 后才裁回 H×W。
padded = padarray(Y,[rs+rp,rs+rp],'replicate','both');
rows = rs+1 : rs+h+2*rp;
cols = rs+1 : rs+w+2*rp;
reference = padded(rows,cols);
patch = ones(2*rp+1);
d1 = zeros(h,w); d2 = zeros(h,w);
A1 = zeros(h,w); A2 = zeros(h,w);
for dy = -rs:rs
    for dx = -rs:rs
        neighbor = padded(rows+dy,cols+dx);
        ssd = conv2((reference-neighbor).^2,patch,'valid');
        k1 = exp(-ssd/cfg.hY);
        if computeSquare
            k2 = k1.^2;
        else
            k2 = exp((-2*ssd)/cfg.hY);  % E/(hY/2)，避免极小 hY 再减半下溢
        end
        shiftedY = neighbor(rp+1:rp+h,rp+1:rp+w);
        d1 = d1+k1;
        d2 = d2+k2;
        A1 = A1+k1.*shiftedY;
        A2 = A2+k2.*shiftedY;
        if nargout > 1 && dy == sampleOffset(1) && dx == sampleOffset(2)
            weights = struct('k1',k1,'k2',k2);
        end
    end
end
layers = struct('d1',d1,'d2',d2,'A1',A1,'A2',A2);
switch cfg.filterMode
    case 'normalized'
        layers.S1 = A1./d1;
        layers.S2 = A2./d2;
    case 'approx'
        layers.alpha1 = scaleAlpha(d1,cfg.alphaMode);
        layers.alpha2 = scaleAlpha(d2,cfg.alphaMode);
        % 式 (10) 的恒等项使用原始 Y，各尺度独立估计一个全图标量。
        layers.S1 = Y+layers.alpha1*(A1-d1.*Y);
        layers.S2 = Y+layers.alpha2*(A2-d2.*Y);
    otherwise
        error('FMLE:FilterMode','filterMode 需为 normalized 或 approx。');
end
layers.timing.nlmSeconds = toc(startTime);
end

function alpha = scaleAlpha(d,mode)
switch mode
    case 'eq18'
        alpha = sum(d(:))/sum(d(:).^2);
    case 'eq20'
        alpha = 1/mean(d(:));
    otherwise
        error('FMLE:AlphaMode','alphaMode 需为 eq18 或 eq20。');
end
end
