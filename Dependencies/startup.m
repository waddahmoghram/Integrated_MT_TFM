cpuCount = feature('numcores')
try
   threadCount = str2double(getenv('NUMBER_OF_PROCESSORS'))      %For Windows Local OS
catch
    threadCount = str2double(getenv('NSLOTS'))                   %For UIowa High-performance computing (HPC)
end
if gpuDeviceCount ~= 0
    gpuDeviceCount
    gpuDev = gpuDevice
end
patchJobStorageLocation
localcluster = parcluster('local')
localcluster.NumThreads = 1
localcluster.NumWorkers = threadCount
delete(localcluster.Jobs)
localcluster.JobStorageLocation
localcluster
delete(gcp('nocreate'));
% poolObj = localcluster.parpool(threadCount)
% poolObj.IdleTimeout = Inf