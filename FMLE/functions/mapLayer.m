function out = mapLayer(in,mapCfg,layerType)
%MAPLAYER 点映射，基础层以 0.5 为中心，原始有符号细节以 0 为中心。
switch layerType
    case 'base'
        center = 0.5;
    case 'detail'
        center = 0;
    otherwise
        error('FMLE:LayerType','layerType 需为 base 或 detail。');
end
switch mapCfg.mode
    case 'identity'
        out = in;
    case 'zero'
        out = zeros(size(in));
    case 'linear'
        validateattributes(mapCfg.gain,{'numeric'},{'scalar','finite','real'});
        out = mapCfg.gain.*in;
    case {'s','inverseS'}
        a = mapCfg.a;
        width = mapCfg.width;
        validateattributes(a,{'numeric'},{'scalar','finite','real','positive'});
        validateattributes(width,{'numeric'},{'scalar','finite','real','positive','<=',1});
        half = width/2;
        inside = in > center-half & in < center+half;
        out = in;
        % Fig. 11 的分段近似：在两个端点与恒等线连续连接。
        scale = tanh(a*width/4);
        if scale <= eps
            return   % 此时两种曲线在 double 精度内均退化为恒等线
        elseif scale == 1
            warning('FMLE:CurveSaturation','a*width 过大，double 无法分辨 S 曲线近端点处的变化。');
        end
        offset = in(inside)-center;
        if strcmp(mapCfg.mode,'s')
            out(inside) = center+half*(tanh(a*offset/2)/scale);
        else
            argument = (offset/half)*scale;
            limit = 1-eps(1)/2;
            argument = min(max(argument,-limit),limit);
            out(inside) = center+atanh(argument)*(2/a);
        end
    otherwise
        error('FMLE:MapMode','未知的映射模式 %s。',mapCfg.mode);
end
end
