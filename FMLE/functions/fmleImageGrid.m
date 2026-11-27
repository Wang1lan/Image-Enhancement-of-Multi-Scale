function fmleImageGrid(folder,file,images,labels,nRows,nCols,rois)
% Export consistently scaled image panels. Optional coordinates mark the input.
if nargin<7, rois = []; end
fig = figure('Visible','off','Color','w', ...
    'Position',[50 50 415*nCols 310*nRows]);
closer = onCleanup(@() close(fig));
t = tiledlayout(fig,nRows,nCols,'TileSpacing','compact','Padding','compact');
for j = 1:numel(images)
    ax = nexttile(t);
    imshow(images{j},'Parent',ax);
    title(ax,labels{j},'Interpreter','none');
    if j==1 && ~isempty(rois)
        hold(ax,'on');
        for k = 1:numel(rois)
            r = rois(k);
            if strcmp(r.type,'edge')
                plot(ax,r.line([1 3]),r.line([2 4]),'y-','LineWidth',1.2);
            else
                rectangle(ax,'Position',[r.rect(1:2)-0.5,r.rect(3:4)], ...
                    'EdgeColor',[0 .9 .75],'LineWidth',1);
            end
            text(ax,r.rect(1),r.rect(2),r.id,'Color','w','BackgroundColor',[.16 .16 .16], ...
                'FontSize',7,'VerticalAlignment','bottom','Interpreter','none','Clipping','on');
        end
    end
end
exportgraphics(fig,fullfile(folder,file),'Resolution',105);
end
