NSLOTS = str2num(getenv('NSLOTS'));
if isempty(NSLOTS)
    NSLOTS = 1;
end
% Adjust NumWorkers for the default 'local' cluster to match the number of slots:
cluster = parcluster();
cluster.NumWorkers = NSLOTS;
% Then start your parpool and set NumWorkers to the same value:
parpool(cluster,NSLOTS);
