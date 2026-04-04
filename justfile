set lazy := true

toolchain := ""
msrv := ```
    cargo metadata --format-version=1 \
    | jq -r 'first(.packages[] | select(.source == null and .rust_version)) | .rust_version' \
    | sed -E 's/^1\.([0-9]{2})$/1\.\1\.0/'
```
msrv_rustup := "+" + msrv

_list:
    @just --list

# Format project.
fmt:
    just --unstable --fmt
    # nixpkgs-fmt .
    fd --type=file --hidden --extension=md --extension=yml --exec-batch prettier --write
    fd --hidden --extension=toml --exec-batch taplo format
    cargo +nightly fmt

# Check project.
check:
    just --unstable --fmt --check
    # nixpkgs-fmt --check .
    fd --type=file --hidden --extension=md --extension=yml --exec-batch prettier --check
    fd --hidden --extension=toml --exec-batch taplo format --check
    fd --hidden --extension=toml --exec-batch taplo lint
    cargo +nightly fmt -- --check
    cargo clippy --workspace --all-targets --all-features

# Downgrade dev-dependencies necessary to run MSRV checks/tests.
@downgrade-for-msrv:
    # cargo {{ toolchain }} update -p=foo --precise=x.y.z # next ver: 1.mm

[private]
backup-lockfile:
    cp Cargo.lock target/Cargo.lock.bak

[private]
restore-lockfile:
    cp target/Cargo.lock.bak Cargo.lock

[private]
test-lib:
    cargo {{ toolchain }} nextest run --workspace --all-targets --all-features

[private]
test-doc:
    cargo {{ toolchain }} test --doc --workspace --all-features

[env("RUSTDOCFLAGS", "--cfg docsrs -D warnings")]
[private]
test-doc-compile:
    cargo {{ toolchain }} doc --workspace --no-deps --all-features

# Run tests.
[parallel]
test: test-lib test-doc test-doc-compile

# Run tests on MRSV.
test-msrv: backup-lockfile && restore-lockfile
    @just toolchain="$(just --eval msrv_rustup)" downgrade-for-msrv test

# Test workspace and generate Codecov coverage file
test-coverage-codecov toolchain="":
    cargo {{ toolchain }} llvm-cov --workspace --all-features --codecov --output-path codecov.json

# Test workspace and generate LCOV coverage file
test-coverage-lcov toolchain="":
    cargo {{ toolchain }} llvm-cov --workspace --all-features --lcov --output-path lcov.info
