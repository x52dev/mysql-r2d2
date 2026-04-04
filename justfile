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
