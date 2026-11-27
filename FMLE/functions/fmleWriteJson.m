function fmleWriteJson(path,value)
% Write a human-readable UTF-8 configuration or ROI record.
[fid,msg] = fopen(path,'w','n','UTF-8');
assert(fid~=-1,'FMLE:Open','Cannot open %s: %s',path,msg);
closer = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end
