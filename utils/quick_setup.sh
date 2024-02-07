#!/usr/bin/env bash
##===- quick_setup.sh - Setup IRON for Ryzen AI dev ----------*- Script -*-===##
# 
# This file licensed under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# 
##===----------------------------------------------------------------------===##
#
# This script is the quickest path to running the Ryzen AI reference designs.
# Please have the Vitis tools and XRT environment setup before sourcing the 
# script.
#
# source ./utils/quick_setup.sh
#
##===----------------------------------------------------------------------===##

echo "Setting up RyzenAI developement tools..."
XBUTIL=`which xbutil`
if ! test -f "$XBUTIL"; then 
  echo "XRT is not installed"
  return 1
fi
NPU=`/opt/xilinx/xrt/bin/xbutil examine | grep RyzenAI`
if [[ $NPU == *"RyzenAI"* ]]; then
  echo "Ryzen AI NPU found:"
  echo $NPU
else
  echo "NPU not found. Is the amdxdna driver installed?"
  return 1
fi
if ! hash python3.8; then
  echo "This script requires python3.8"
  echo "https://linuxgenie.net/how-to-install-python-3-8-on-ubuntu-22-04/"
  echo "Don't forget python3-distutils!"
  return 1
fi
if ! hash virtualenv; then
  echo "virtualenv is not installed"
  return 1
fi
alias python3=python3.8
python3 -m virtualenv ironenv
# The real path to source might depend on the virtualenv version
if [ -r ironenv/local/bin/activate ]; then
  source ironenv/local/bin/activate
else
  source ironenv/bin/activate
fi
python3 -m pip install --upgrade pip
VPP=`which v++`
if test -f "$VPP"; then
  AIETOOLS="`dirname $VPP`/../aietools"
  mkdir -p my_install
  pushd my_install
  wget -q --show-progress https://github.com/Xilinx/mlir-aie/releases/download/latest-wheels/mlir_aie-0.0.1.2024020616+bde53fc-py3-none-manylinux_2_35_x86_64.whl
  unzip -q mlir_aie-*-py3-none-manylinux_*_x86_64.whl
  sed -i "s^TARGET_AIE_LIBDIR=.*^TARGET_AIE_LIBDIR=\"$AIETOOLS/data/versal_prod/lib\"^g" mlir_aie/bin/xchesscc_wrapper
  sed -i "s^TARGET_AIE2_LIBDIR=.*^TARGET_AIE2_LIBDIR=\"$AIETOOLS/data/aie_ml/lib\"^g" mlir_aie/bin/xchesscc_wrapper
  sed -i "s^AIETOOLS=.*^AIETOOLS=\"$AIETOOLS\"^g" mlir_aie/bin/xchesscc_wrapper
  wget -q --show-progress https://github.com/Xilinx/mlir-aie/releases/download/mlir-distro/mlir-19.0.0.2024013022+24923214-py3-none-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl
  unzip -q mlir-*-py3-none-manylinux_*_x86_64.manylinux_*_x86_64.whl
  pip install https://github.com/makslevental/mlir-python-extras/archive/d84f05582adb2eed07145dabce1e03e13d0e29a6.zip
  rm -rf mlir*.whl
  export PATH=`realpath mlir_aie/bin`:`realpath mlir/bin`:$PATH
  export LD_LIBRARY_PATH=`realpath mlir_aie/lib`:`realpath mlir/lib`:$LD_LIBRARY_PATH
  export PYTHONPATH=`realpath mlir_aie/python`:$PYTHONPATH
  popd
  python3 -m pip install -r python/requirements.txt
  pushd reference_designs/ipu-xrt
else
  echo "Vitis not found! Exiting..."
fi
