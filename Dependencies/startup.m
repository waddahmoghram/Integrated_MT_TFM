cpuCount = feature('numcores')
threadCount = str2double(getenv('NUMBER_OF_PROCESSORS'))
gpuDev = gpuDevice
localcluster = parcluster('local')
localcluster.NumThreads = 1;
localcluster.NumWorkers = threadCount;
localcluster.parpool(threadCount)

