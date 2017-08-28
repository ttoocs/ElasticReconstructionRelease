# ElasticReconstructionRelease
Smaller and simpler setup for Elastic Reconstruction.
* Depends on PCL with cuda/gpu built.
* Simply build the root with cmake, and everything (should) be available in ./bin for individual execution.
* Source pipeline.sh to include the simplified pipeline commands and binaries
  * - You can then use `Pipeline` to run the entire pipeline in the current directory. (NOTE: DOES NOT RECORD A VIDEO, ASSUMES ONE ALREADY PRESENT)

# Key executable (Besides the Elastic Reconstruction ones)
* ni2Recorder : Simple application to record via a device.
* KinfuLS : Should be the same as pcl\_kinfu\_largescale, but compiled locally to save time for minor modifications.
* KinfuLS\_meshOut : Should be the same as pcl\_kinfu\_largescale\_mesh\_output, but akin the to above.
* All of the Elastic Reconstruction executables.
