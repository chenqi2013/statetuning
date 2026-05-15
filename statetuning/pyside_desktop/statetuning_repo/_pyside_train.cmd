@echo off
set "VSLANG=1033"
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
if errorlevel 1 exit /b %errorlevel%
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.4\bin;C:\Users\rwkv\Documents\statetuning\statetuning\pyside_desktop\statetuning_repo\python_venv\Lib\site-packages\torch\lib;C:\Users\rwkv\Documents\statetuning\statetuning\pyside_desktop\statetuning_repo\python_venv\Scripts;%PATH%"
python -u -X utf8 train.py --load_model C:/Users/rwkv/Downloads/cq/rwkv7-g1d-0.1b-20260129-ctx8192.pth --data_path C:/Users/rwkv/Downloads/cq/hanzipinyin_128050.jsonl --output_dir ./outmodel --vocab_size 65536 --n_embd 768 --n_layer 12 --precision bf16 --batch_size 4 --num_epochs 1 --learning_rate 1e-5 --ctx_len 512 --num_steps 1000
