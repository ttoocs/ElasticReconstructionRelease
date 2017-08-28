

#ER_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/ER_port/bin

#export PATH=$ER_DIR:$PATH
#export PCL_BIN="/home/scott/pcl_merging/pcl_copyin_funcs/build/bin"
#export ER_BIN="/home/scott/s2017/ER_port/bin"

#export PATH=$PCL_BIN:$ER_BIN:$PATH

export s2017Dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


export PATH=$s2017Dir/bin:$PATH

SET_SAMPLES(){
  if [ "$1" == "" ]; then
    SAMPLES="50"
    echo "Setting size of samples to 50. (50 frames per fragment)"
  else
    echo "Set samples to $1"
    SAMPLES="$1"
  fi

}

SETUP(){
#  ONI=$1
#  
#  NAME=$( basename $ONI)
#  
  SET_SAMPLES $1
#
#  CURDIR=$(pwd)
#  DIR=$CURDIR/ER.$NAME
#  mkdir -p $WORKDIR
#  cd $WORKDIR
#
#  if [ ! -e $ONI ]; then
#    echo "$ONI is not an absolute path (or doesn't exist)"
#    exit
#  fi
#
#  ln -s $ONI ./in.oni
}

CDDIR(){
#  if [ $WORKDIR != "" ]; then
#    cd $WORKDIR
#  else
    echo "DIR NOT SET, CANNOT CD."
#  fi

}

UGLYHACK(){
  echo "Ugly hack run in "`pwd`
  mkdir -p hack
  cd hack
  OLDIFS=$IFS
  IFS=$(echo -en "\n\b")
  for i in `find  ../../ -type f `; do ln -s $i ./ ; done
  cd ..
  IFS=$OLDIFS
}


ER_HELP(){
  echo "PCL_KINFU"
  echo "GR"
  echo "GO"
  echo "BC"
  echo "FP"
  echo "INTEGRATE"
  
  echo "or PIPELINE"

  echo "Afterwards, run pcl_kinfu_largeScale_mesh_output <filename>"
  echo " Then in meshlab, import all of them, merge (removing verts/faces), and export."


}
PCL_KINFU(){
  ( time (
  CDDIR
  SET_SAMPLES $1
  rm -rf kinfu
  mkdir -p kinfu
  cd kinfu
  PCL_ARGS=" -r -ic -sd 10 -oni ../ -vs 4 --fragment "$SAMPLES" --rgbd_odometry --record_log ./100-0.log --camera ../cam.param"
#  pcl_kinfu_largeScale $PCL_ARGS 
  KinfuLS $PCL_ARGS
  cd ..
  ) ) 2>&1 | tee kinfu_log.txt
}

PSEUDO_KINFU(){
  ( time (
  CDDIR
  SET_SAMPLES $1
  rm -rf kinfu
  mkdir -p kinfu
  cd kinfu
  genTraj.sh #This is located in the openCV_TRAJ
  pseudo_kinfu.sh
  cd ..
  ) ) 2>&1 | tee pkinfu_log.txt
}


GR(){
  ( time (
  CDDIR
  SET_SAMPLES $1
  rm -rf gr
  mkdir -p gr
  cd gr
  ARGS=" ../kinfu/ ../kinfu/100-0.log $SAMPLES"
  GlobalRegistration $ARGS
  cd ..
  ) ) 2>&1 | tee gr_log.txt
}

GO(){
  ( time (
  CDDIR
  rm -rf go
  mkdir -p go
  cd go
  ARGS="-w 100 --odometry ../gr/odometry.log --odometryinfo ../gr/odometry.info --loop ../gr/result.txt --loopinfo ../gr/result.info --pose ./pose.log --keep keep.log --refine ./reg_refine_all.log"
  time ( GraphOptimizer $ARGS )
  cd ..
  ) ) 2>&1 | tee go_log.txt
}

BC(){
  ( time (
  CDDIR
  rm -rf bc
  mkdir -p bc
  cd bc

  UGLYHACK
  ARGS=" --reg_traj ./hack/reg_refine_all.log --registration --reg_dist 0.05 --reg_ratio 0.25 --reg_num 0 --save_xyzn "
  #ARGS=" --reg_traj ./go/reg_refine_all.log --registration --reg_dist 0.05 --reg_ratio 0.25 --reg_num 0 --save_xyzn "
  BuildCorrespondence $ARGS
  echo "BC DONE: $?"

  cd ..
  ) ) 2>&1 | tee bc_log.txt
}

FO(){
  ( time ( 
  CDDIR
  rm -rf fo
  mkdir -p fo
  cd fo
  NUMPCDS=$(ls -l ../kinfu/cloud_bin_*.pcd | wc -l | tr -d ' ')
  
  UGLYHACK
 
#  ARGS=" --slac --rgbdslam ./hack/init.log --registration ./hack/reg_output.log --dir ./hack/ --num $NUMPCDS --resolution 12 --iteration 10 --length 4.0 --write_xyzn_sample 10"
  ARGS=" --slac --rgbdslam ../gr/init.log --registration ../bc/reg_output.log --dir ./hack/ --num $NUMPCDS --resolution 12 --iteration 10 --length 4.0 --write_xyzn_sample 10"

  FragmentOptimizer $ARGS
  cd ..
  echo "Done fragment"
  ) ) 2>&1 | tee fo_log.txt
}

INTEGRATE(){
  ( time (
  CDDIR
  SET_SAMPLES $1
  rm -rf integrate
  mkdir -p integrate
  cd integrate
  ln -s ../fo ./
  NUMPCDS=$(ls -l ../kinfu/cloud_bin_*.pcd | wc -l | tr -d ' ')

  UGLYHACK

  echo "Running Integrate with Fragment Optimizer"
  ARGS=" --pose_traj ../fo/pose.log --seg_traj ../kinfu/100-0.log --ctr ../fo/output.ctr --num $NUMPCDS --resolution 12 --camera ../cam.param --oni_file ../ --length 4.0 --interval $SAMPLES --save_to fo_world.pcd "
  Integrate $ARGS

  echo "Running Integrate without Fragment Optimizer"
  ARGS=" --pose_traj ../go/pose.log --seg_traj ../kinfu/100-0.log --resolution 12 --camera ../cam.param --oni_file ../ --length 4.0 --interval $SAMPLES --save_to go_world.pcd "
  Integrate $ARGS
  
  cd ..
  ) ) 1>&2 | tee integrate_log.txt
}


MESH(){
  ( time (
  CDDIR
  SET_SAMPLES $1
  rm -rf mesh
  mkdir -p mesh
  cd mesh

  INFILE=""
  if [ -e ../integrate/fo_world.pcd ]; then
    echo "Running Integrate with Fragment Optimizer"
    INFILE="../integrate/fo_world.pcd"
  else
    echo "Running Integrate without Fragment Optimizer"
    INFILE="../integrate/go_world.pcd"
  fi

  #pcl_kinfu_largeScale_mesh_output $INFILE --volume_size 4
  KinfuLS_meshOut $INFILE --volume_size 4 
 
  #String for meshlab inputs
  MESHES=""
  for i in `ls | grep mesh_`; do
    MESHES=$MESHES" -i "$i
  done

  meshlabserver -s $s2017Dir/meshlab_merge_meshes_script.mlx -o mesh.ply $MESHES

  cd ..
  ) ) 1>&2 | tee mesh_log.txt

}

Pipeline() {
( time ( 
  SETUP $1 $2

  PCL_KINFU $SAMPLES

  GR $SAMPLES

  GO $SAMPLES
 
  BC $SAMPLES 
 
  FO $SAMPLES 

  INTEGRATE $SAMPLES

  MESH 

  echo "Pipeline Finished" > status.txt

) ) 2>&1 | tee pipeline.log
}

PPipeline() {
( time (
  SETUP $1 $2
  
  PSEUDO_KINFU

  GR $SAMPLES

  GO $SAMPLES
 
  BC $SAMPLES 
 
  FO $SAMPLES 

  INTEGRATE $SAMPLES
  
  MESH

  echo "Pseudo Pipeline Finished" > status.txt

) ) 2>&1 | tee pseudo_pipeline.log
}
  

CompairPipe(){
( time ( 
  SETUP $1 $2

  #ASSUMES BTRFS partiton w/ copy-on-write:
  rm -rf pseudo
  rm -rf pcl
  FILES=`ls`
  mkdir pseudo
  mkdir pcl
  cp --reflink -r ./$FILES ./pseudo
  cp --reflink -r ./$FILES ./pcl
  
  cd pseudo

  if [ ! -e status.txt ] ; then
    PPipeline
  fi  
  cd ..
  cd pcl
  
  if [ ! -e status.txt ] ; then
   Pipeline
  fi
  cd ..
) ) 2>&1 | tee compair_log.txt

}

#if [ "$1" == "" ]; then 
#  echo "Ye need arguments (The oni file in absolute path)"
#else
#  Pipeline $1 $2
#fi

