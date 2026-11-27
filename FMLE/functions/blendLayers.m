function [Zraw,midWeighted,fineWeighted] = blendLayers(baseMapped,midMapped,fineMapped,Meff)
%BLENDLAYERS 将映射后的两层细节乘同一掩模，再加至映射后的基础层。
midWeighted = Meff.*midMapped;
fineWeighted = Meff.*fineMapped;
Zraw = baseMapped+midWeighted+fineWeighted;
end
