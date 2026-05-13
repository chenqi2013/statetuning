@echo off
set "VSLANG=1033"
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
if errorlevel 1 exit /b %errorlevel%
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.4\bin;C:\Users\rwkv\Documents\statetuning\statetuning\statetuning_repo\statetuning_repo\python_venv\Lib\site-packages\torch\lib;C:\Users\rwkv\Documents\statetuning\statetuning\statetuning_repo\statetuning_repo\python_venv\Scripts;%PATH%"
python -u -X utf8 C:\Users\rwkv\Documents\statetuning\statetuning\statetuning_repo\statetuning_repo\_pyside_train_compat.py
