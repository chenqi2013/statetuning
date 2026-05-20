#!/usr/bin/env python3
"""JSON-lines RWKV test worker for the PySide desktop UI."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import traceback
from pathlib import Path


def emit(event: str, **payload) -> None:
    print(json.dumps({"event": event, **payload}, ensure_ascii=False), flush=True)


def fail(message: str) -> None:
    emit("error", message=message, traceback=traceback.format_exc())


def infer_model_args(ckpt: dict) -> tuple[int, int, int]:
    head = ckpt.get("head.weight")
    if head is None:
        raise RuntimeError("head.weight not found in checkpoint")
    vocab_size = int(head.shape[0])
    n_embd = int(head.shape[1])
    layers = [
        int(m.group(1))
        for key in ckpt.keys()
        if (m := re.match(r"blocks\.(\d+)\.", str(key)))
    ]
    n_layer = max(layers) + 1 if layers else 0
    if n_layer <= 0:
        raise RuntimeError("No blocks.* keys found in checkpoint")
    return vocab_size, n_embd, n_layer


def load_tokenizer(path: str | None):
    if path:
        p = Path(path)
        if p.name == "rwkv_vocab_v20230424.txt":
            from tokenizer.rwkv_tokenizer import TRIE_TOKENIZER

            return TRIE_TOKENIZER(str(p))
        from tokenizers import Tokenizer

        tok = Tokenizer.from_file(str(p))

        class HFTokenizer:
            def encode(self, text: str) -> list[int]:
                return tok.encode(text).ids

            def decode(self, ids: list[int]) -> str:
                return tok.decode(ids)

        return HFTokenizer()

    from tokenizer.rwkv_tokenizer import TRIE_TOKENIZER

    return TRIE_TOKENIZER(str(Path(__file__).parent / "tokenizer" / "rwkv_vocab_v20230424.txt"))


def sample_next(logits, temperature: float, top_p: float):
    import torch
    from torch.nn import functional as F

    if temperature <= 0:
        return int(torch.argmax(logits).item())
    probs = F.softmax((logits.float() / temperature), dim=-1)
    if 0 < top_p < 1:
        sorted_probs, sorted_idx = torch.sort(probs, descending=True)
        cumulative = torch.cumsum(sorted_probs, dim=-1)
        keep = cumulative <= top_p
        keep[0] = True
        filtered = torch.zeros_like(probs)
        filtered[sorted_idx[keep]] = sorted_probs[keep]
        probs = filtered / filtered.sum()
    return int(torch.multinomial(probs, num_samples=1).item())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True)
    parser.add_argument("--tokenizer", default="")
    parser.add_argument("--state", default="")
    parser.add_argument("--precision", default="bf16", choices=["bf16", "fp16", "fp32"])
    parser.add_argument("--max-context", type=int, default=512)
    args = parser.parse_args()

    os.environ.setdefault("RWKV_HEAD_SIZE_A", "64")
    os.environ.setdefault("RWKV_MY_TESTING", "x070")
    os.environ.setdefault("FUSED_KERNEL", "0")
    os.environ["RWKV_FLOAT_MODE"] = args.precision
    os.environ["RWKV_TRAIN_TYPE"] = "state" if args.state else "none"
    os.environ.setdefault("WKV", "cuda")

    try:
        import torch

        if not torch.cuda.is_available():
            raise RuntimeError("CUDA is not available. RWKV7 test inference needs CUDA in this bundled model.")

        device = torch.device("cuda")
        ckpt = torch.load(args.model, map_location="cpu", weights_only=True)
        vocab_size, n_embd, n_layer = infer_model_args(ckpt)

        class ModelArgs:
            pass

        model_args = ModelArgs()
        model_args.vocab_size = vocab_size
        model_args.n_embd = n_embd
        model_args.n_layer = n_layer
        model_args.ctx_len = args.max_context
        model_args.head_size_a = 64
        model_args.head_size_divisor = 8
        model_args.dim_att = n_embd
        model_args.dim_ffn = n_embd * 4

        import model.rwkv7.model as rwkv7_model

        rwkv7_model.torch_checkpoint = lambda fn, *a, **_: fn(*a)
        RWKV7 = rwkv7_model.RWKV7

        model = RWKV7(model_args)
        model.load_state_dict(ckpt, strict=False)
        del ckpt

        if args.state:
            state_dict = torch.load(args.state, map_location="cpu", weights_only=True)
            model.load_state_dict(state_dict, strict=False)
            del state_dict

        model = model.to(device)
        if args.precision == "bf16":
            model = model.to(torch.bfloat16)
        elif args.precision == "fp16":
            model = model.to(torch.float16)
        model.eval()

        tokenizer = load_tokenizer(args.tokenizer or None)
        emit("loaded", detail=f"vocab={vocab_size} n_embd={n_embd} n_layer={n_layer}")

        with torch.inference_mode():
            for raw in sys.stdin:
                raw = raw.strip()
                if not raw:
                    continue
                try:
                    msg = json.loads(raw)
                    if msg.get("cmd") == "quit":
                        break
                    if msg.get("cmd") != "generate":
                        continue

                    prompt = str(msg.get("prompt", ""))
                    max_tokens = int(msg.get("max_tokens", 128))
                    temperature = float(msg.get("temperature", 0.8))
                    top_p = float(msg.get("top_p", 0.9))
                    tokens = tokenizer.encode(prompt)
                    generated: list[int] = []

                    for _ in range(max_tokens):
                        context = (tokens + generated)[-args.max_context :]
                        original_len = len(context)
                        if original_len == 0:
                            context = [0]
                            original_len = 1
                        pad = (-len(context)) % 16
                        padded = context + ([0] * pad)
                        x = torch.tensor([padded], dtype=torch.long, device=device)
                        logits = model(x)[0, original_len - 1]
                        token = sample_next(logits, temperature=temperature, top_p=top_p)
                        generated.append(token)
                        text = tokenizer.decode(generated)
                        emit("partial", text=text)
                        if token == 0:
                            break

                    emit("done", text=tokenizer.decode(generated))
                except Exception as exc:
                    fail(str(exc))
    except Exception as exc:
        fail(str(exc))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
