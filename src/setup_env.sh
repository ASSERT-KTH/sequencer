#! /bin/bash
set -e

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(dirname "$CURRENT_DIR")"

if ! command -v python3 &>/dev/null; then
  echo "Python 3 is not installed"
  exit 1
fi

if ! command -v pip3 &>/dev/null; then
  echo "Pip 3 is not installed"
  exit 1
fi

if ! command -v mvn &>/dev/null; then
  echo "Maven is not installed"
  exit 1
fi

if ! command -v git &>/dev/null; then
  echo "git is not installed"
  exit 1
fi

if ! command -v java &>/dev/null; then
  echo "java is not installed"
  exit 1
fi

if ! command -v sshpass &>/dev/null; then
  echo "sshpass is not installed"
  exit 1
fi

echo "Create lib folder"
mkdir -p $CURRENT_DIR/lib
echo


if ! python3 -c "import javalang" 2>/dev/null ; then
  echo "javalang module not installed"
  echo "Cloning javalang"
  git clone https://github.com/c2nes/javalang.git $CURRENT_DIR/lib/javalang
  echo "Installing requirements for javalang"
  pip3 install -r $CURRENT_DIR/lib/javalang/requirements.txt
  echo "Installing javalang"
  cd $CURRENT_DIR/lib/javalang
  python3 setup.py install --force
  cd $CURRENT_DIR
  echo "Removing javalang repo"
  rm -rf $CURRENT_DIR/lib/javalang
  echo
  cd $CURRENT_DIR
fi

if [ ! -d $CURRENT_DIR/lib/OpenNMT-py ]; then
  echo "Cloning OpenNMT-py"
  git clone https://github.com/chenzimin/OpenNMT-py.git $CURRENT_DIR/lib/OpenNMT-py
  echo "Installing requirements for OpenNMT-py"
  pip3 install -r $CURRENT_DIR/lib/OpenNMT-py/requirements.txt
  echo
  cd $CURRENT_DIR
fi

if [ -d $CURRENT_DIR/lib/OpenNMT-py ]; then    
  echo "Installing requirements for OpenNMT-py"
  pip3 install -r $CURRENT_DIR/lib/OpenNMT-py/requirements.txt
  echo
  cd $CURRENT_DIR
fi

if [ ! -d $CURRENT_DIR/lib/abstraction-1.0-SNAPSHOT-jar-with-dependencies.jar ]; then
  echo "Building jar for abstraction and copy it to lib/"
  cd $CURRENT_DIR/Buggy_Context_Abstraction/abstraction
  mvn clean package
  cp target/abstraction-1.0-SNAPSHOT-jar-with-dependencies.jar $CURRENT_DIR/lib
  echo
  cd $CURRENT_DIR
fi

export data_path="$ROOT_DIR/data"
export OpenNMT_py="$ROOT_DIR/src/lib/OpenNMT-py"

echo "Done"
echo
