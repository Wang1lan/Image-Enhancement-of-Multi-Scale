function fmleRoiGrid(folder,file,images,labels,rois)
% Show one recorded ROI per category; grow narrow edge views for context.
[~,first] = unique({rois.type},'stable');
first = sort(first);
if isempty(first), return; end
nCols = numel(images);
crops = cell(1,numel(first)*nCols);
titles = cell(size(crops));
[h,w,~] = size(images{1});
for i = 1:numel(first)
    r = rois(first(i)); box = r.rect;
    margin = max(0,ceil((40-box(3:4))/2));
    xx = max(1,box(1)-margin(1)):min(w,box(1)+box(3)-1+margin(1));
    yy = max(1,box(2)-margin(2)):min(h,box(2)+box(4)-1+margin(2));
    for j = 1:nCols
        k = (i-1)*nCols+j;
        crops{k} = images{j}(yy,xx,:);
        titles{k} = sprintf('%s | %s',r.id,labels{j});
    end
end
fmleImageGrid(folder,file,crops,titles,numel(first),nCols);
end
