# Third-Party Notices

This inventory records components used to build or planned for distribution
with Exocomp. The machine-readable source of truth is
[`licenses/components.toml`](licenses/components.toml). Release artifacts must
include this file, the project [`LICENSE`](LICENSE), `NOTICE`, and every
upstream license or notice named by their build-specific inventory.

## Runtime components

### Erlang/OTP

- Use: ERTS runtime bundled in node and coordinator OTP releases.
- License: [Apache-2.0](https://github.com/erlang/otp/blob/master/LICENSE.txt).
- Copyright: Ericsson AB and Erlang/OTP contributors.
- Redistribution: permitted under Apache-2.0. Preserve the upstream license,
  copyright, and notice material from the exact pinned OTP release.

### llama.cpp

- Use: bundled `llama-server` inference runtime.
- License: [MIT](https://github.com/ggml-org/llama.cpp/blob/master/LICENSE).
- Copyright: 2023-2026 the ggml authors.
- Redistribution: permitted under the MIT License. Preserve the following
  license text and all build-generated notices for enabled backends and
  vendored libraries.

> MIT License
>
> Copyright (c) 2023-2026 The ggml authors
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to
> deal in the Software without restriction, including without limitation the
> rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
> sell copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in
> all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.

## Model artifacts

### Qwen2.5 1.5B Instruct Q4_K_M GGUF

- Use: default offline inference model.
- Publisher: Qwen Team, Alibaba Cloud.
- Source: [Qwen/Qwen2.5-1.5B-Instruct-GGUF](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF).
- License: [Apache-2.0](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/blob/main/LICENSE).
- Redistribution: the publisher records the official GGUF repository and
  weights as Apache-2.0. A release must pin the repository revision and
  Q4_K_M file SHA-256 and must ship the upstream license and model card.

Model outputs are not covered by the Exocomp license. Operators remain
responsible for reviewing model behavior and applicable law for their use.

## Build-time components

### Elixir

- Use: build-time language and release tooling; it is not required on target
  hosts.
- License: [Apache-2.0](https://github.com/elixir-lang/elixir/blob/main/LICENSE).
- Copyright: the Elixir contributors.
- Redistribution: permitted under Apache-2.0. If Elixir files are ever included
  in an artifact, preserve their upstream license and notices.

## Dependency policy

Every direct and transitive Hex dependency in `mix.lock` must have an entry in
`licenses/components.toml` before it can pass the compliance gate. Entries
must identify an approved SPDX license and the applicable notice file.
Optional `llama.cpp` backends or libraries are disabled unless the release
inventory records their exact version, license, redistribution status, and
required notice text.
