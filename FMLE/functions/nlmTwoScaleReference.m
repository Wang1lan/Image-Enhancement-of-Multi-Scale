function [nlm, weights] = nlmTwoScaleReference(Y, cfg, offset)
% Small-image reference for the normalized two-scale NLM and one optional [dy dx].
% Clamp every original pixel coordinate independently for replicate padding.
[height, width] = size(Y);
rs = cfg.searchRadius;
rp = cfg.patchRadius;
d1 = zeros(size(Y));
d2 = zeros(size(Y));
A1 = zeros(size(Y));
A2 = zeros(size(Y));
weights = struct;
if nargin == 3
    weights.k1 = zeros(size(Y));
    weights.k2 = zeros(size(Y));
end
for row = 1:height
    for col = 1:width
        for dy = -rs:rs
            for dx = -rs:rs
                ssd = 0;
                for py = -rp:rp
                    for px = -rp:rp
                        ref = Y(clamp(row+py,height), clamp(col+px,width));
                        nbr = Y(clamp(row+dy+py,height), clamp(col+dx+px,width));
                        ssd = ssd + (ref-nbr)^2;
                    end
                end
                k1 = exp(-ssd/cfg.hY);
                k2 = exp(-ssd/(cfg.hY/2));
                neighbor = Y(clamp(row+dy,height), clamp(col+dx,width));
                d1(row,col) = d1(row,col) + k1;
                d2(row,col) = d2(row,col) + k2;
                A1(row,col) = A1(row,col) + k1*neighbor;
                A2(row,col) = A2(row,col) + k2*neighbor;
                if nargin == 3 && dy == offset(1) && dx == offset(2)
                    weights.k1(row,col) = k1;
                    weights.k2(row,col) = k2;
                end
            end
        end
    end
end
nlm = struct('d1', d1, 'd2', d2, 'A1', A1, 'A2', A2, ...
    'S1', A1./d1, 'S2', A2./d2);
end

function index = clamp(index, extent)
index = max(1,min(index,extent));
end
