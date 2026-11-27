function img = fmleNormalizeInput(img)
%FMLENORMALIZEINPUT uint8/uint16 按类型满量程转换；浮点必须已归一化。
validateattributes(img,{'uint8','uint16','single','double'},{'nonempty','real','nonsparse'});
if ~ismatrix(img) && ~(ndims(img) == 3 && size(img,3) == 3)
    error('FMLE:ImageShape','仅支持 H×W 灰度或 H×W×3 RGB，包含 Alpha 的图像不受支持。');
end
if isfloat(img)
    validateattributes(img,{'single','double'},{'finite','>=',0,'<=',1});
    img = double(img);
else
    img = im2double(img);
end
end
