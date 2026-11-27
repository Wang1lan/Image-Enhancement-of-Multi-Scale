function rgbRaw = ycbcrToRgbFull(Y,Cb,Cr)
%YCBCRTORGBFULL 全范围 BT.709 逆变换；返回限幅前的 double RGB。
kr = 0.2126; kg = 0.7152; kb = 0.0722;
R = Y+2*(1-kr)*Cr;
B = Y+2*(1-kb)*Cb;
G = (Y-kr*R-kb*B)/kg;
rgbRaw = cat(3,R,G,B);
end
