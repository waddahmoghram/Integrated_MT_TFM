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
<<<<<<< HEAD
delete(gcp('nocreate'));
% poolObj = localcluster.parpool(threadCount)
% poolObj.IdleTimeout = Inf
=======
delete(gcp('nocreate'));poolObj = localcluster.parpool(threadCount)
poolObj.IdleTimeout = Inf
>>>>>>> 0661c0280761b891f56c397a6b2e6a1b14724e49
