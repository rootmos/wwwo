---
title: "Guarded memory calculations using Coq"
---

## The problem
Wanted to implement guarded memory allocations (a la [libsodium](https://doc.libsodium.org/memory_management#guarded-heap-allocations)) in rust.

![guarded memory allocations](guarded-memory-sketch.jpg)

Rust's memory allocators receive a desired [memory layout](https://doc.rust-lang.org/std/alloc/struct.Layout.html#method.from_size_align)
which specifies not only the size but also the alignment.
And the only guarantee we get regarding the alignment is that its a power of 2.
