@echo off
set "VSLANG=1033"
set "PYTHONUTF8=1"
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
if errorlevel 1 exit /b %errorlevel%
C:\Users\rwkv\miniconda3\python.EXE -X utf8 -u C:\Users\rwkv\Documents\statetuning\statetuning\pyside_desktop\statetuning_repo\_pyside_rwkv_test_worker.py --model D:/dengzi/rl_cpp/rwkv_lightning_libtorch/rwkv7-g1d-0.1b-20260129-ctx8192.pth --precision bf16 --tokenizer D:/dengzi/rl_cpp/rwkv_lightning_libtorch/rwkv_vocab_v20230424.txt
