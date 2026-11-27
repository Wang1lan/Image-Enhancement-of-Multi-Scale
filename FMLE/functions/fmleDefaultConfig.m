function cfg = fmleDefaultConfig(preset)
%FMLEDEFAULTCONFIG 参数预设。demo 可在调用 fmleEnhance 前覆盖字段。
if nargin == 0
    preset = 'noisy';
end
cfg.preset = char(preset);
cfg.searchRadius = 2;
cfg.patchRadius = 1;
cfg.hY = 0.7;
cfg.numScales = 2;
cfg.weightMode = 'square';
cfg.filterMode = 'normalized';
cfg.alphaMode = 'eq18';
cfg.maskSource = 'd1';
cfg.useMask = true;
cfg.colorStandard = 'BT.709';       % 全范围，Cb、Cr 以 0 为中心
cfg.colorRange = 'full, zero-centered Cb/Cr';
cfg.borderMode = 'replicate';
cfg.patchDistance = 'SSD';
cfg.mappingConvention = 'endpoint-normalized sigmoid and its inverse';
cfg.detailCoordinate = 'signed detail, zero centered, no rescaling';
cfg.rngSeed = 42;

identity = struct('mode','identity','a',1,'width',1,'gain',1);
cfg.baseMap = identity;
cfg.midMap = identity;
cfg.fineMap = identity;
switch cfg.preset
    case 'noisy'
        cfg.baseMap = curve('s',5,0.75);
        cfg.midMap = curve('s',60,0.45);
        cfg.fineMap = curve('inverseS',10,1);
    case 'defocus'
        cfg.baseMap = curve('s',6,0.75);
        cfg.midMap = curve('s',50,0.33);
        cfg.fineMap = curve('s',20,0.66);
    case 'smoothing'
        cfg.midMap = curve('s',10,0.20);
        cfg.fineMap.mode = 'zero';
    case 'linear'
        cfg.midMap.mode = 'linear';
        cfg.midMap.gain = 3;
        cfg.fineMap.mode = 'linear';
    case 'identity'
        % 各层保持恒等，掩模仍由 cfg.useMask 控制。
    otherwise
        error('FMLE:Preset','未知预设 %s。',cfg.preset);
end
end

function m = curve(mode,a,width)
m = struct('mode',mode,'a',a,'width',width,'gain',1);
end
