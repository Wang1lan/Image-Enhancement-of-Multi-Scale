function [Y,Cb,Cr] = rgbToYcbcrFull(img)
%RGBTOYCBCRFULL 全范围 BT.709，从 H×W×3 归一化 RGB 提取 Y 及零中心色度。
kr = 0.2126; kg = 0.7152; kb = 0.0722;
R = img(:,:,1); G = img(:,:,2); B = img(:,:,3);
Y = kr*R+kg*G+kb*B;
Cb = (B-Y)/(2*(1-kb));
Cr = (R-Y)/(2*(1-kr));
end
