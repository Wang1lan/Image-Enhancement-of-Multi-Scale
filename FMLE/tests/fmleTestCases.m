function cases = fmleTestCases()
% Independent acceptance tests for the floating-point FMLE implementation.
cases = {
    'Scalar NLM, borders and tiny images',           @referenceAgreement
    'Square and direct per-offset weights',          @weightEquivalence
    'Self weight and raw weight bounds',             @weightBounds
    'Constant images including boundaries',          @constantImages
    'Three-layer decomposition',                    @decomposition
    'Identity with mask disabled',                  @unmaskedIdentity
    'Masked identity and mask source',              @maskedIdentity
    'Injected zero and one masks',                  @injectedMasks
    'Signed S and inverse-S curves',                @mappingCurves
    'Input, clipping and file decoding',            @outputContract
    'Full-range BT.709 and RGB identity',           @rgbIdentity
    'Normalization-free approximation',             @approximation
};
end

function Y = sampleImage()
% An asymmetric non-square pattern with distinct corners and signed details.
Y = reshape(mod((1:35).^2+3*(1:35),37)/36, 5,7);
end

function near(actual, expected, tolerance, label)
assert(isequal(size(actual),size(expected)), '%s: actual %s, expected %s.', ...
    label, mat2str(size(actual)), mat2str(size(expected)));
assert(isreal(actual) && all(isfinite(actual(:))), '%s contains nonfinite or complex values.', label);
err = max(abs(double(actual(:))-double(expected(:))));
assert(err <= tolerance, '%s: max error %.17g, tolerance %.17g.', label, err, tolerance);
end

function compareNlm(actual, expected, tolerance)
for key = {'S1','S2','d1','d2','A1','A2'}
    name = key{1};
    near(actual.(name),expected.(name),tolerance,name);
end
end

function referenceAgreement()
cfg = fmleDefaultConfig('noisy');
images = {sampleImage(), [0.95,0.2;0.3,0], [1,0.4,0.1], [0;0.8], 0.35};
for i = 1:numel(images)
    compareNlm(nlmTwoScale(images{i},cfg),nlmTwoScaleReference(images{i},cfg),1e-10);
end
cfg.searchRadius = 1;
cfg.patchRadius = 2;
cfg.hY = 0.31;
compareNlm(nlmTwoScale(images{1},cfg),nlmTwoScaleReference(images{1},cfg),1e-10);
end

function weightEquivalence()
cfg = fmleDefaultConfig('noisy');
direct = cfg;
direct.weightMode = 'direct';
Y = sampleImage();
for dy = -cfg.searchRadius:cfg.searchRadius
    for dx = -cfg.searchRadius:cfg.searchRadius
        offset = [dy dx];
        [squareNlm,square] = nlmTwoScale(Y,cfg,offset);
        [directNlm,independent] = nlmTwoScale(Y,direct,offset);
        [~,ref] = nlmTwoScaleReference(Y,cfg,offset);
        near(square.k1,ref.k1,1e-10,'k1 vs scalar SSD');
        near(square.k2,ref.k2,1e-10,'k2 vs scalar SSD and hY/2');
        near(square.k2,square.k1.^2,1e-10,'k2 vs squared raw k1');
        near(square.k2,independent.k2,1e-10,'square vs direct k2');
    end
end
compareNlm(squareNlm,directNlm,1e-10);
end

function weightBounds()
cfg = fmleDefaultConfig('noisy');
Y = sampleImage();
[nlm,self] = nlmTwoScale(Y,cfg,[0 0]);
near(self.k1,ones(size(Y)),0,'center k1');
near(self.k2,ones(size(Y)),0,'center k2');
p = (2*cfg.searchRadius+1)^2;
violation = max([0; 1-nlm.d2(:); nlm.d2(:)-nlm.d1(:); nlm.d1(:)-p]);
near(violation,0,1e-12,'1 <= d2 <= d1 <= p');
end

function constantImages()
cfg = fmleDefaultConfig('noisy');
p = (2*cfg.searchRadius+1)^2;
for value = [0,0.25,0.5,0.75,1]
    Y = value*ones(4,9);
    [~,dbg] = fmleEnhanceY(Y,cfg);
    near(dbg.S1,Y,1e-12,'constant S1');
    near(dbg.S2,Y,1e-12,'constant S2');
    near(dbg.d1,p*ones(size(Y)),1e-12,'constant d1');
    near(dbg.d2,p*ones(size(Y)),1e-12,'constant d2');
    for name = {'detailMid','detailFine','M'}
        near(dbg.(name{1}),zeros(size(Y)),1e-12,name{1});
    end
end
end

function decomposition()
cfg = fmleDefaultConfig('noisy');
Y = sampleImage();
[~,d] = fmleEnhanceY(Y,cfg);
near(d.base,d.S1,1e-12,'base');
near(d.detailMid,d.S2-d.S1,1e-12,'mid detail');
near(d.detailFine,Y-d.S2,1e-12,'fine detail');
near(d.base+d.detailMid+d.detailFine,Y,1e-12,'three-layer reconstruction');
end

function unmaskedIdentity()
cfg = fmleDefaultConfig('identity');
cfg.useMask = false;
Y = sampleImage();
[out,d] = fmleEnhanceY(Y,cfg);
near(d.Meff,ones(size(Y)),0,'disabled effective mask');
near(d.M,1-d.d1/(2*cfg.searchRadius+1)^2,1e-12,'retained raw structural mask');
near(d.Zraw,Y,1e-12,'unmasked identity Zraw');
near(out,Y,1e-12,'unmasked identity Yout');
end

function maskedIdentity()
cfg = fmleDefaultConfig('identity');
Y = sampleImage();
p = (2*cfg.searchRadius+1)^2;
for source = {'d1','d2'}
    cfg.maskSource = source{1};
    [~,d] = fmleEnhanceY(Y,cfg);
    M = 1-d.(source{1})/p;
    near(d.Mraw,M,1e-12,'raw mask');
    near(d.M,M,1e-12,'mask from unnormalized weights');
    near(d.Meff,M,1e-12,'effective mask');
    near(d.Zraw,(1-M).*d.base+M.*Y,1e-12,'masked identity');
end
end

function injectedMasks()
base = sampleImage();
mid = flipud(base)-0.35;
fine = fliplr(base)-0.65;
for mask = [0,1]
    [raw,midWeighted,fineWeighted] = blendLayers(base,mid,fine,mask*ones(size(base)));
    near(midWeighted,mask*mid,1e-12,'selected mid detail');
    near(fineWeighted,mask*fine,1e-12,'selected fine detail');
    near(raw,base+mask*(mid+fine),1e-12,'injected mask reconstruction');
end
end

function mappingCurves()
parameters = [5 .75; 60 .45; 10 1; 6 .75; 50 .33; 20 .66; 10 .2];
for i = 1:size(parameters,1)
    a = parameters(i,1);
    w = parameters(i,2);
    s = struct('mode','s','a',a,'width',w,'gain',1);
    invS = s;
    invS.mode = 'inverseS';
    for layer = {'base','detail'}
        kind = layer{1};
        c = 0.5*strcmp(kind,'base');
        x = unique([linspace(c-1,c+1,10001), c-w/2, c, c+w/2]);
        outside = (x <= c-w/2) | (x >= c+w/2);
        for map = {s,invS}
            y = mapLayer(x,map{1},kind);
            assert(isreal(y) && all(isfinite(y)), 'Nonfinite %s map (a=%g, w=%g).',kind,a,w);
            near(max(0,-min(diff(y))),0,1e-14,'monotonicity');
            near(y(outside),x(outside),1e-14,'identity outside width and at endpoints');
            near(mapLayer(c,map{1},kind),c,1e-14,'zero/midpoint');
            if c == 0
                near(mapLayer(-x,map{1},kind),-y,1e-13,'odd signed-detail map');
            end
        end
        near(mapLayer(mapLayer(x,s,kind),invS,kind),x,1e-8,'inverseS(S(x))');
        near(mapLayer(mapLayer(x,invS,kind),s,kind),x,1e-8,'S(inverseS(x))');
        % Check actual shape against the endpoint-normalized sigmoid definition.
        probe = c+w/5;
        sigmoid = @(t) 1/(1+exp(-a*t));
        expected = c-w/2+w*(sigmoid(probe-c)-sigmoid(-w/2))/(sigmoid(w/2)-sigmoid(-w/2));
        near(mapLayer(probe,s,kind),expected,1e-12,'S curve at interior point');
    end
end
end

function outputContract()
cfg = fmleDefaultConfig('linear');
cfg.useMask = false;
cfg.baseMap.mode = 'linear';
cfg.baseMap.gain = 4;
[out,d] = fmleEnhance(0.6*ones(5,7),cfg);
near(d.Zraw,2.4*ones(5,7),1e-12,'preserved over-range Zraw');
near(out,ones(5,7),0,'clipped luma');
near(d.clippingStats.yClipFraction,1,0,'luma clipped fraction');
required = {'Yin','S1','S2','d1','d2','base','detailMid','detailFine','Mraw','M','Meff', ...
    'baseMapped','midMapped','fineMapped','midWeighted','fineWeighted','Zraw','Yout','cfg','timing','clippingStats'};
assert(all(isfield(d,required)), 'Incomplete debug fields.');
cfg.baseMap.gain = 1.7;
rgb = repmat(reshape([1,0.15,0],1,1,3),4,5);
[out,d] = fmleEnhance(rgb,cfg);
near(out,max(0,min(1,d.rgbRaw)),0,'RGB clipping after reconstruction');
near(d.clippingStats.rgbClipFraction,mean(d.rgbRaw(:)>1 | d.rgbRaw(:)<0), ...
    1e-12,'RGB clipping fraction per channel sample');
assert(any(d.rgbRaw(:)>1),'Expected at least one unclipped RGB sample above 1.');
for preset = {'noisy','defocus','smoothing','identity','linear'}
    out = fmleEnhance(rgb,fmleDefaultConfig(preset{1}));
    assert(isequal(size(out),size(rgb)) && isreal(out) && isa(out,'double') && ...
        all(isfinite(out(:)) & out(:)>=0 & out(:)<=1), 'Invalid output for %s.',preset{1});
end
cfg = fmleDefaultConfig('identity');
cfg.useMask = false;
mustReject(@() fmleEnhance([0.5 NaN],cfg),'NaN');
mustReject(@() fmleEnhance([0.5 Inf],cfg),'Inf');
mustReject(@() fmleEnhance(single([0 1.1]),cfg),'out-of-range float');
mustReject(@() fmleEnhance(zeros(2,3,4),cfg),'four-channel array');
bad = cfg;
bad.numScales = 3;
mustReject(@() fmleEnhance(sampleImage(),bad),'numScales=3');
checkPng(cfg);
checkOtherFormats();
end

function checkPng(cfg)
file = [tempname '.png'];
gray16 = reshape(uint16([0,12,90,983,2048,4095]),2,3);
imwrite(gray16,file);
cleanup = onCleanup(@() delete(file)); %#ok<NASGU>
gray = readFmleImage(file);
near(fmleEnhance(gray,cfg),double(gray16)/65535,1e-12,'uint16 PNG range uses 65535');
near(fmleEnhance(single(im2double(gray16)),cfg),double(single(im2double(gray16))), ...
    1e-12,'single input preserved');
rgb = cat(3,uint8([11,22;33,44]),255*ones(2,'uint8'),zeros(2,'uint8'));
imwrite(rgb,file);
near(fmleEnhance(readFmleImage(file),cfg),im2double(rgb),1e-12,'uint8 RGB PNG full range');
imwrite(rgb,file,'Alpha',uint8([255,200;255,255]));
mustReject(@() readFmleImage(file),'PNG with alpha');
imwrite(uint8([0,1;1,0]),[0 0 0;1 0.5 0],file,'Transparency',[0;1]);
mustReject(@() readFmleImage(file),'indexed PNG transparent entry');
imwrite(rgb,file,'Transparency',[0 1 0]);
mustReject(@() readFmleImage(file),'RGB PNG transparent color');
end

function checkOtherFormats()
gray = uint8(round(255*sampleImage()));
rgb = cat(3,gray,flipud(gray),fliplr(gray));
for ext = {'.bmp','.tiff','.jpg'}
    file = [tempname ext{1}];
    imwrite(rgb,file);
    cleanup = onCleanup(@() delete(file));
    near(readFmleImage(file),im2double(imread(file)),0,['decoded RGB ' ext{1}]);
    clear cleanup;
end
mono = logical([0 1;1 0]);
for ext = {'.png','.bmp','.tif'}
    file = [tempname ext{1}];
    imwrite(mono,file);
    cleanup = onCleanup(@() delete(file));
    near(readFmleImage(file),double(mono),0,['1-bit grayscale ' ext{1}]);
    clear cleanup;
end
rgb16 = cat(3,uint16(257)*uint16(gray),uint16(193)*uint16(gray),uint16(gray));
for ext = {'.png','.tif','.jpg'}
    file = [tempname ext{1}];
    if strcmp(ext{1},'.jpg')
        data = rgb16(:,:,1);  % MATLAB supports 16-bit lossless JPEG for grayscale.
        imwrite(data,file,'BitDepth',16,'Mode','lossless');
    else
        data = rgb16;
        imwrite(data,file);
    end
    cleanup = onCleanup(@() delete(file));
    near(readFmleImage(file),double(data)/65535,0,['16-bit ' ext{1}]);
    clear cleanup;
end
file = [tempname '.tif'];
values = [0.125,0.5;0,1];
writeFloatTiff(file,values);
cleanup = onCleanup(@() delete(file));
near(readFmleImage(file),values,0,'double TIFF retained');
writeFloatTiff(file,[-0.01,0.7;NaN,1]);
mustReject(@() readFmleImage(file),'out-of-range/nonfinite floating TIFF');
clear cleanup;
file = [tempname '.bmp'];
expected = reshape([0 0;0 1;1 0].',[1 2 3]);  % blue, then green
for sizeDib = [56 108 124]
    writeBitfieldsBmp(file,sizeDib,0);
    cleanup = onCleanup(@() delete(file));
    near(readFmleImage(file),expected,0,'RGB32 bitfields with padding byte');
    writeBitfieldsBmp(file,sizeDib,hex2dec('FF000000'));
    mustReject(@() readFmleImage(file),'explicit BMP alpha mask');
    clear cleanup;
end
end

function writeFloatTiff(file,Y)
t = Tiff(file,'w');
cleanup = onCleanup(@() t.close()); %#ok<NASGU>
t.setTag(struct('ImageLength',size(Y,1),'ImageWidth',size(Y,2), ...
    'Photometric',Tiff.Photometric.MinIsBlack,'BitsPerSample',64, ...
    'SampleFormat',Tiff.SampleFormat.IEEEFP,'SamplesPerPixel',1, ...
    'RowsPerStrip',size(Y,1),'PlanarConfiguration',Tiff.PlanarConfiguration.Chunky));
t.write(Y);
end

function writeBitfieldsBmp(file,sizeDib,alphaMask)
% Two pixels. The high byte is reserved when alphaMask=0 and intentionally nonzero.
fid = fopen(file,'w','ieee-le');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
pixelOffset = 14+sizeDib;
fwrite(fid,'BM','char');
fwrite(fid,[pixelOffset+8,0,pixelOffset,sizeDib,2,1],'uint32');
fwrite(fid,[1 32],'uint16');
fwrite(fid,[3 8 2835 2835 0 0],'uint32');
fwrite(fid,[hex2dec('FF0000'),hex2dec('FF00'),255,alphaMask],'uint32');
fwrite(fid,zeros(1,sizeDib-56),'uint8');
fwrite(fid,[255 0 0 100 0 255 0 255],'uint8');
end

function mustReject(action,label)
try
    action();
catch err
    assert(~strcmp(err.identifier,'MATLAB:UndefinedFunction'), ...
        'Unavailable function while testing %s: %s.',label,err.message);
    return;
end
error('fmleTest:expectedError','Expected explicit rejection for %s.',label);
end

function rgbIdentity()
cfg = fmleDefaultConfig('identity');
cfg.useMask = false;
patches = reshape(eye(3),[3,1,3]);
[Y,Cb,Cr] = rgbToYcbcrFull(patches);
coeff = [0.2126;0.7152;0.0722];
near(Y,coeff,1e-12,'BT.709 primary luminance');
near(Cb,(patches(:,:,3)-Y)/(2*(1-coeff(3))),1e-12,'BT.709 zero-centered Cb');
near(Cr,(patches(:,:,1)-Y)/(2*(1-coeff(1))),1e-12,'BT.709 zero-centered Cr');
near(ycbcrToRgbFull(Y,Cb,Cr),patches,1e-12,'BT.709 primary round-trip');
base = sampleImage();
rgb = cat(3,base,flipud(base),fliplr(base));
[out,d] = fmleEnhance(rgb,cfg);
near(out,rgb,1e-12,'RGB identity reconstruction');
near(d.rgbRaw,rgb,1e-12,'RGB identity before clipping');
end

function approximation()
cfg = fmleDefaultConfig('noisy');
Y = sampleImage();
exact = nlmTwoScale(Y,cfg);
cfg.filterMode = 'approx';
for mode = {'eq18','eq20'}
    cfg.alphaMode = mode{1};
    n = nlmTwoScale(Y,cfg);
    [~,d] = fmleEnhanceY(Y,cfg);
    for level = 1:2
        suffix = num2str(level);
        weight = exact.(['d' suffix]);
        weightedY = exact.(['A' suffix]);
        if strcmp(mode{1},'eq18')
            alpha = sum(weight(:))/sum(weight(:).^2);
        else
            alpha = 1/mean(weight(:));
        end
        near(n.(['alpha' suffix]),alpha,1e-12,['scale-specific alpha' suffix]);
        near(d.(['alpha' suffix]),alpha,1e-12,['saved alpha' suffix]);
        near(n.(['S' suffix]),Y+alpha*(weightedY-weight.*Y),1e-12,['approx S' suffix]);
    end
    near(d.base+d.detailMid+d.detailFine,Y,1e-12,'approx three-layer reconstruction');
    flat = 0.37*ones(3,6);
    constant = nlmTwoScale(flat,cfg);
    near(constant.S1,flat,1e-12,'approx constant S1');
    near(constant.S2,flat,1e-12,'approx constant S2');
    fprintf('  %s normalized vs approx: max|dS1|=%.6g, max|dS2|=%.6g\n', ...
        mode{1},max(abs(n.S1(:)-exact.S1(:))),max(abs(n.S2(:)-exact.S2(:))));
end
% Local uniform dark/bright patches give larger d than the full-frame average.
% Eq. (18) can overshoot here; intermediate smoothings must retain that excursion.
stream = RandStream('mt19937ar','Seed',42);
dark = rand(stream,25);
dark(1:10,1:10) = 0;
dark(5,5) = 0.15;
cfg.alphaMode = 'eq18';
[~,low] = fmleEnhanceY(dark,cfg);
[~,high] = fmleEnhanceY(1-dark,cfg);
for level = 1:2
    field = sprintf('S%d',level);
    lo = low.(field);
    hi = high.(field);
    assert(any(lo(:)<0) && any(hi(:)>1), ...
        'Expected out-of-range %s, actual min %.17g and max %.17g.',field,min(lo(:)),max(hi(:)));
    near(low.clippingStats.(sprintf('s%dBelowFraction',level)),mean(lo(:)<0), ...
        1e-12,'low smoothing outlier fraction');
    near(high.clippingStats.(sprintf('s%dAboveFraction',level)),mean(hi(:)>1), ...
        1e-12,'high smoothing outlier fraction');
end
end
