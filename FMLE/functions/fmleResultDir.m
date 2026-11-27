function path = fmleResultDir(root,name,experiment)
% Keep each run beneath its own input and preset.
stamp = char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
path = fullfile(root,'results',name,experiment,stamp);
assert(~isfolder(path),'FMLE:RunExists','Output directory already exists: %s',path);
mkdir(path);
end
