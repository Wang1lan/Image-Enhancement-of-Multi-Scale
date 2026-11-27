function stats = fmleGlobalStats(dbg,rows)
% Report full-frame clipping, mean change, and raw mask distribution.
stats = struct2table(dbg.clippingStats);
full = rows(rows.roiType=="image",:);
stats = [stats,full(:,{'maskMin','maskMax','maskMean','maskP10','maskMedian','maskP90'})];
stats.Properties.VariableNames{'maskMedian'} = 'maskP50';
end
