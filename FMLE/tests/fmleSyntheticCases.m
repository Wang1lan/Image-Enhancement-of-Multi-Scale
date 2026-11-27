function cases = fmleSyntheticCases()
% Reproducible normalized-double inputs, clean references and fixed scoring ROIs.
% All noise-level comparisons use the same realization scaled by their noise sigma.
old = rng;
restoreRng = onCleanup(@() rng(old)); %#ok<NASGU>
rng(42,'twister');
flat = region('flat1','flat',[9 9 32 20],[],NaN);
levels = [0 0.25 0.5 0.75 1];
for k = 1:numel(levels)
    level = levels(k);
    img = level*ones(40,64);
    cases(k) = sample(sprintf('constant_%03d',round(level*100)),img,img, ...
        flat,'noisy',struct('level',level)); %#ok<AGROW>
end

cleanFlat = 0.5*ones(96,144);
standardNoise = randn(size(cleanFlat));
flatRois = [region('flat1','flat',[9 9 42 26],[],NaN), ...
    region('flat2','flat',[82 18 42 26],[],NaN), ...
    region('flat3','flat',[50 56 42 26],[],NaN)];
for sigma = [0.005 0.01 0.02 0.04]
    img = min(max(cleanFlat + sigma*standardNoise,0),1);
    g = struct('sigma',sigma,'rngSeed',42,'generator','twister','level',0.5);
    cases(end+1) = sample(sprintf('flat_noise_%03d',round(sigma*1000)), ...
        img,cleanFlat,flatRois,'noisy',g); %#ok<AGROW>
end

% Top: isolated step. Middle: two sinusoidal periods. Bottom: bars and weak texture.
chart = 0.5*ones(128,192);
chart(1:40,1:96) = 0.22;
chart(1:40,97:end) = 0.78;
x = 0:95;
chart(45:82,1:96) = repmat(0.5+0.09*sin(2*pi*x/4),38,1);
chart(45:82,97:end) = repmat(0.5+0.09*sin(2*pi*x/12),38,1);
chart(87:128,1:96) = repmat(0.28+0.44*(mod(x,6)==0),42,1);
chart(87:128,97:end) = repmat(0.5+0.015*sin(2*pi*x/8),42,1);
rois = [region('flat1','flat',[9 9 58 24],[],NaN), ...
    region('flat2','flat',[129 9 55 24],[],NaN), ...
    region('period4','texture',[13 52 64 24],[],4), ...
    region('period12','texture',[109 52 72 24],[],12), ...
    region('bars','texture',[13 95 66 24],[],NaN), ...
    region('weakPeriod8','texture',[109 95 72 24],[],8), ...
    region('step','edge',[61 24 72 1],[61 24 132 24],NaN)];
g = struct('stepLevels',[0.22 0.78],'sinePeriods',[4 12 8], ...
    'sineAmplitudes',[0.09 0.09 0.015],'barPeriod',6,'barWidth',1);
cases(end+1) = sample('chart_clean',chart,chart,rois,'smoothing',g);
g.sigma = 0.02;
g.rngSeed = 42;
g.generator = 'twister';
% Second draw follows the common flat noise field above.
img = min(max(chart + g.sigma*randn(size(chart)),0),1);
cases(end+1) = sample('chart_noisy',img,chart,rois,'noisy',g);
g = rmfield(g,{'sigma','rngSeed','generator'});
g.blurSigma = 1.25;
g.blurPadding = 'replicate';
img = imgaussfilt(chart,g.blurSigma,'Padding',g.blurPadding,'FilterDomain','spatial');
cases(end+1) = sample('chart_defocus',img,chart,rois,'defocus',g);
end

function s = sample(name,img,clean,rois,preset,generation)
s = struct('name',name,'img',img,'clean',clean,'rois',rois, ...
    'preset',preset,'generation',generation);
end

function r = region(id,type,rect,line,period)
r = struct('id',id,'type',type,'rect',rect,'line',line,'period',period);
end
