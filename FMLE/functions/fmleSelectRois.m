function rois = fmleSelectRois(img)
% Select three flat ROIs, three textured ROIs and three normal profiles on the input.
% Confirm each shape by double-clicking. The demo saves the returned coordinates.
fig = figure('Name','FMLE ROI','NumberTitle','off');
cleanup = onCleanup(@() closeFigure(fig)); %#ok<NASGU>
ax = axes('Parent',fig);
imshow(img,'Parent',ax);
[h,w,~] = size(img);
types = {'flat','texture','edge'};
labels = {'平坦区','纹理区','强边缘法向剖面（两端落在稳定平台）'};
colors = [0.2 0.9 0.3; 1 0.7 0.1; 0.2 0.8 1];
for t = 1:3
    for n = 1:3
        id = sprintf('%s%d',types{t},n);
        title(ax,sprintf('%s %d/3 — 调整后双击确认',labels{t},n));
        segment = [];
        if t == 3
            shape = drawline(ax,'Color',colors(t,:),'Label',id);
            wait(shape);
            pos = round(shape.Position);
            pos = min(max(pos,1),[w h]);
            segment = [pos(1,:) pos(2,:)];
            box = [min(pos,[],1) abs(diff(pos,1,1))+1];
        else
            shape = drawrectangle(ax,'Color',colors(t,:),'Label',id);
            wait(shape);
            pos = shape.Position;
            first = min(max(ceil(pos(1:2)),1),[w h]);
            last = min(max(floor(pos(1:2)+pos(3:4)),first),[w h]);
            box = [first last-first+1];
        end
        shape.InteractionsAllowed = 'none';
        index = (t-1)*3+n;
        rois(index) = struct('id',id,'type',types{t},'rect',box, ...
            'line',segment,'period',NaN); %#ok<AGROW>
    end
end
end

function closeFigure(fig)
if isgraphics(fig)
    close(fig);
end
end
