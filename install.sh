# Env variables
WHEEL_DIR="$HOME/exp/tensorflow/wheel/"
JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/"
if [[ `hostname -d` == 'iro.umontreal.ca' ]] ; then
    OUT_BASE="/Tmp/visin/bazel-cache"
else
    OUT_BASE="/tmp/bazel-cache"
fi
export TEST_TMPDIR=$OUT_BASE  # This seems to work!

# Copy to Tmp (LISA ONLY)
if [[ `hostname -d` == 'iro.umontreal.ca' ]] ; then
    echo "Copying dir to /Tmp"
    rm -rf /Tmp/visin/tensorflow
    cp -r ../tensorflow /Tmp/visin/tensorflow
    cd /Tmp/visin/tensorflow
fi

# Echo flags
echo "Use the following flags:"
if [[ `hostname` == 'nvidia-robotica' ]] ; then
    echo -e "\t-march=native -mfma -mfpmath=both -msse4.2"
    echo -e "\t5.2" 
elif [[ `hostname` == 'fraptop' ]] ; then
    echo -e "\t-march=native -msse4.2"
elif [[ `hostname -d` == 'iro.umontreal.ca' ]] ; then
    echo -e "\t-march=native -mfpmath=both -msse4.2 -mavx" # -mavx2 -mfma
elif [[ `hostname` == 'AITeam' ]] ; then
    echo "\t-march=native -mfma -mfpmath=both -msse4.2 -mavx -mavx2"
fi
# LISA
if [[ `hostname -d` == 'iro.umontreal.ca' ]] ; then
    echo -e "\t/Tmp/lisa/os_v5/cudnn_v5.1rc"
    echo -e "\t3.7,5.2,3.5,6.0,6.1" 
fi

# Configure
./configure --output_base $OUT_BASE 

# Build
FLAGS="--config=opt"
if [[ `hostname` == 'fraptop' ]] ; then
    echo "\n*** Compilation without CUDA"
else
    echo "\n*** Compilation with CUDA"
    FLAGS=$FLAGS" --config=cuda"
fi
bazel build $FLAGS //tensorflow/tools/pip_package:build_pip_package || { echo 'Compilation failed' ; exit 1; }

# Build pip
echo -e "\nBuilding pip package"
bazel-bin/tensorflow/tools/pip_package/build_pip_package $WHEEL_DIR || { echo 'Pip compilation failed' ; exit 1; } 
LATEST_WHEEL=`find $WHEEL_DIR -type f -printf '%T@ %p\n' | sort -n | head -1 | cut -f2- -d" "`

# Install pip
echo -e "\nInstalling pip package"
pip install --user -U $LATEST_WHEEL
if [[ `hostname -d` == 'iro.umontreal.ca' ]] ; then
    pip uninstall numpy
fi
