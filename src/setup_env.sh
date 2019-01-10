#! /bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
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

echo "Create lib folder"
mkdir -p $CURRENT_DIR/lib
echo

python3 -c "import javalang"
if [ $? -ne 0 ]; then
  echo "javalang module not installed"
  echo "Cloning javalang"
  git clone https://github.com/c2nes/javalang.git $CURRENT_DIR/lib/javalang
  echo "Installing requirements for javalang"
  pip3 install -r $CURRENT_DIR/lib/javalang/requirements.txt
  echo "Installing javalang"
  cd $CURRENT_DIR/lib/javalang
  python3 setup.py install --force
  echo "Removing javalang repo"
  rm -rf $CURRENT_DIR/lib/javalang
  echo
fi

if [ ! -d $CURRENT_DIR/lib/OpenNMT-py ]; then
  echo "Cloning OpenNMT-py"
  git clone https://github.com/chenzimin/OpenNMT-py.git $CURRENT_DIR/lib/OpenNMT-py
  echo "Installing requirements for OpenNMT-py"
  pip3 install -r $CURRENT_DIR/lib/OpenNMT-py/requirements.txt
  echo
fi

if [ ! -d $CURRENT_DIR/lib/abstraction-1.0-SNAPSHOT-jar-with-dependencies.jar ]; then
  echo "Building jar for abstraction and copy it to lib/"
  cd $CURRENT_DIR/Buggy_Context_Abstraction/abstraction
  mvn clean package
  cp target/abstraction-1.0-SNAPSHOT-jar-with-dependencies.jar $CURRENT_DIR/lib
  echo
fi

echo "Done"
echo
