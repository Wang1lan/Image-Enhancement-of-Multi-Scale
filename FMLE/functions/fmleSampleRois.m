function rois = fmleSampleRois()
% Fixed evaluation coordinates for the supplied 1428-by-1080 testImg_1.png.
% Rectangle convention is [first column, first row, column count, row count].
boxes = [160 210 40 32; 185 348 40 32; 1156 935 40 32; ...
         701 283 56 40; 585 495 56 40; 968 442 56 40];
types = {'flat','flat','flat','texture','texture','texture'};
for k = 1:size(boxes,1)
    t = types{k};
    rois(k) = struct('id',sprintf('%s%d',t,mod(k-1,3)+1), ...
        'type',t,'rect',boxes(k,:),'line',[],'period',NaN); %#ok<AGROW>
end
% Tissue fold and tooth boundaries, sampled across the input edge.
lines = [765 534 784 551; 646 747 622 756; 1258 773 1258 799];
for k = 1:size(lines,1)
    s = lines(k,:);
    rect = [min(s(1),s(3)) min(s(2),s(4)) abs(s(3)-s(1))+1 abs(s(4)-s(2))+1];
    rois(end+1) = struct('id',sprintf('edge%d',k),'type','edge','rect',rect, ...
        'line',s,'period',NaN); %#ok<AGROW>
end
end
