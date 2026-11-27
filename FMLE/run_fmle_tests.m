function report = run_fmle_tests(scope)
% Run T01-T12 without images or interaction. Use 'normalized' for T01-T11.
if nargin == 0
    scope = 'all';
end
scope = validatestring(scope, {'all','normalized'});
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root,'functions'), fullfile(root,'tests'));
cases = fmleTestCases();
if strcmp(scope,'normalized')
    cases = cases(1:11,:);
end
count = size(cases,1);
id = compose("T%02d", (1:count)');
seconds = zeros(count,1);
for i = 1:count
    started = tic;
    try
        feval(cases{i,2});
    catch cause
        fprintf(2,'%s FAIL  %s\n', id(i), cases{i,1});
        rethrow(cause);
    end
    seconds(i) = toc(started);
    fprintf('%s PASS  %s (%.3f s)\n', id(i), cases{i,1}, seconds(i));
end
report = table(id, string(cases(:,1)), true(count,1), seconds, ...
    'VariableNames', {'ID','Test','Passed','Seconds'});
fprintf('FMLE: %d/%d tests passed.\n',count,count);
end
