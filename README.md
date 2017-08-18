# ElasticReconstructionRelease
Smaller and simpler setup for ElasticReconstruction.
* Depends on PCL with cuda/gpu built.
* Simply build the root with cmake, and everything (should) be available in ./bin for individual execution.
* Use pipeline.sh to run the entire pipeline at once in the current directory (Note: DOES NOT RECORD THE VIDEO)

# Key executables (Besides the Elastic Reconstruction ones)
* ni2Recorder : Simple application to record via a device.
* KinfuLS : Should be the same as pcl\_kinfu\_largescale, but compiled locally to save time for minor modifications.
* KinfuLS\_meshOut : Should be the same as pcl\_kinfu\_largescale\_mesh\_output, but akin the to above.

