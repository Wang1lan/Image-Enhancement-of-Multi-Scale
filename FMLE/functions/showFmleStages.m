function showFmleStages(folder,img,out,dbg,rois)
% Write aligned whole-image, ROI, decomposition, mask, detail and curve views.
fmleImageGrid(folder,'overview.png',{img,dbg.base,out}, ...
    {'Input','Base (Y)','Output'},1,3,rois);
fmleRoiGrid(folder,'roi_overview.png',{img,dbg.base,out}, ...
    {'Input','Base (Y)','Output'},rois);
v = max(abs([min(dbg.detailMid(:)) max(dbg.detailMid(:)) ...
             min(dbg.detailFine(:)) max(dbg.detailFine(:))]));
flabel = @(name,lim) sprintf('%s  [+/-%0.4g]',name,lim);
signed = @(a,lim) 0.5+0.5*a/(lim+(lim==0));
fmleImageGrid(folder,'decomposition.png', ...
    {dbg.Yin,dbg.S1,dbg.S2,dbg.base,signed(dbg.detailMid,v),signed(dbg.detailFine,v)}, ...
    {'Input Y','S1','S2','Base = S1',flabel('Mid',v),flabel('Fine',v)},2,3);
p = (2*dbg.cfg.searchRadius+1)^2;
fmleImageGrid(folder,'mask.png',{dbg.d1/p,dbg.d2/p,dbg.M}, ...
    {'d1 / p   [0,1]','d2 / p   [0,1]',['M (' dbg.cfg.maskSource ')   [0,1]']},1,3);
layers = {dbg.detailMid,dbg.midMapped,dbg.midWeighted; ...
          dbg.detailFine,dbg.fineMapped,dbg.fineWeighted};
names = {'Mid input','Mid mapped','Mid weighted'; ...
         'Fine input','Fine mapped','Fine weighted'};
for level = 1:2
    lim = max(cellfun(@(a) max(abs(a(:))),layers(level,:)));
    for stage = 1:3
        layers{level,stage} = signed(layers{level,stage},lim);
        names{level,stage} = flabel(names{level,stage},lim);
    end
end
fmleImageGrid(folder,'mapped_details.png',reshape(layers.',1,[]), ...
    reshape(names.',1,[]),2,3);

fig = figure('Visible','off','Color','w','Position',[80 80 1070 650]);
closer = onCleanup(@() close(fig));
t = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
cfgs = {dbg.cfg.baseMap,dbg.cfg.midMap,dbg.cfg.fineMap};
labels = {'Base','Mid','Fine'};
detail = (-1000:1000)/1000;
axGain = nexttile(t,4);
plot(axGain,detail,ones(size(detail)),'--','Color',[.5 .5 .5], ...
    'DisplayName','Unit gain'); hold(axGain,'on');
for k = 1:3
    cfg = cfgs{k};
    if k==1
        x = (0:1000)/1000; layer = 'base';
    else
        x = detail; layer = 'detail';
    end
    y = mapLayer(x,cfg,layer);
    ax = nexttile(t,k);
    plot(ax,x,x,'--','Color',[.5 .5 .5]); hold(ax,'on');
    plot(ax,x,y,'LineWidth',1.6); grid(ax,'on');
    title(ax,sprintf('%s: %s',labels{k},curveLabel(cfg)),'Interpreter','none');
    xlabel(ax,'Input'); ylabel(ax,'Mapped value'); xlim(ax,[x(1),x(end)]);
    if k>1
        gain = zeros(size(x));
        gain(x~=0) = y(x~=0)./x(x~=0);
        gain(x==0) = centerSlope(cfg);
        plot(axGain,x,gain,'LineWidth',1.5,'DisplayName',labels{k});
    end
end
grid(axGain,'on'); title(axGain,'Effective detail gain');
xlabel(axGain,'Signed detail'); ylabel(axGain,'T(D) / D'); legend(axGain,'show');
exportgraphics(fig,fullfile(folder,'curves.png'),'Resolution',115);
end

function s = centerSlope(cfg)
switch lower(cfg.mode)
    case {'s','inverses'}
        z = cfg.a*cfg.width/4;
        s = z/tanh(z);
        if strcmpi(cfg.mode,'inverseS'), s = 1/s; end
    case 'linear'
        s = cfg.gain;
    case 'identity'
        s = 1;
    otherwise
        s = 0;
end
end

function label = curveLabel(cfg)
if any(strcmpi(cfg.mode,{'s','inverseS'}))
    label = sprintf('%s  a=%g, width=%g',cfg.mode,cfg.a,cfg.width);
elseif strcmpi(cfg.mode,'linear')
    label = sprintf('linear  gain=%g',cfg.gain);
else
    label = cfg.mode;
end
end
