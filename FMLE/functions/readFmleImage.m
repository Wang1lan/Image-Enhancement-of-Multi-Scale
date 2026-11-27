function img = readFmleImage(path)
% Read a grayscale or RGB image as normalized doubles, preserving its range.
[~,~,ext] = fileparts(path);
assert(any(strcmpi(ext,{'.png','.bmp','.jpg','.jpeg','.tif','.tiff'})), ...
    'FMLE:FileType','Expected a PNG, BMP, JPEG or TIFF file.');
info = imfinfo(path);
info = info(1);
if isfield(info,'Transparency') && ~strcmpi(info.Transparency,'none')
    error('FMLE:Alpha','Images with alpha or transparency are unsupported.');
end
if isfield(info,'SamplesPerPixel') && ~ismember(info.SamplesPerPixel,[1 3])
    error('FMLE:Channels','Unsupported number of samples per pixel (including alpha).');
end
if strcmpi(ext,'.bmp') && (isfield(info,'AlphaMask') || info.BitmapHeaderSize==56 || ...
        (info.BitDepth==32 && strcmpi(info.CompressionType,'bitfields')))
    [img,map] = readMaskedBmp(path,info);
elseif strcmpi(ext,'.png')
    [img,map,alpha] = imread(path);
    if ~isempty(alpha)
        error('FMLE:Alpha','PNG alpha channels are unsupported.');
    end
else
    [img,map] = imread(path);
end
if ~isempty(map)
    img = ind2rgb(img,map);
    if isequal(map(:,1),map(:,2),map(:,3))
        img = img(:,:,1);
    end
end
if islogical(img)
    img = double(img);  % 1-bit grayscale files already encode 0 and 1.
end
img = fmleNormalizeInput(img);
end

function [img,map] = readMaskedBmp(path,info)
fid = fopen(path,'r','ieee-le');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
if isfield(info,'AlphaMask')
    alphaMask = info.AlphaMask;
elseif info.BitmapHeaderSize==56
    % MATLAB omits the fourth DWORD mask from a 56-byte V3 DIB header.
    fseek(fid,14+52,'bof');
    alphaMask = fread(fid,1,'uint32');
else
    alphaMask = 0;
end
if alphaMask~=0
    error('FMLE:Alpha','BMP images with an alpha mask are unsupported.');
end
if info.BitDepth~=32 || ~strcmpi(info.CompressionType,'bitfields')
    [img,map] = imread(path);
    return
end
% Decode RGB32 with the actual masks: a zero alpha mask is padding and may
% occupy any byte. Sorting channel masks can incorrectly include that byte.
fseek(fid,info.ImageDataOffset,'bof');
words = fread(fid,[info.Width abs(info.Height)],'*uint32').';
if info.Height>0
    words = flipud(words);
end
masks = uint32([info.RedMask,info.GreenMask,info.BlueMask]);
img = zeros([size(words),3]);
for ch = 1:3
    img(:,:,ch) = double(bitand(words,masks(ch)))/double(masks(ch));
end
map = [];
end
