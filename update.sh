#!/usr/bin/env bash

set -ex

# NOTE: Last executed using Rust 1.49.0

cargo install --version 0.17.0 svd2rust
cargo install --version 0.7.0  form
rustup component add rustfmt
pip3 install --upgrade --user "svdtools>=0.1.13"

rm -rf src
mkdir src

svd patch svd/rp2040.yaml

svd2rust -i svd/rp2040.svd.patched

form -i lib.rs -o src
rm lib.rs

cargo fmt

sed -i "/extern crate bare_metal;/d" ./src/lib.rs
sed -i 's/bare_metal::Nr/cortex_m::interrupt::Nr/g' ./src/lib.rs
sed -i '/legacy_directory_ownership/d' ./src/lib.rs
sed -i '/plugin_as_library/d' ./src/lib.rs
sed -i '/safe_extern_statics/d' ./src/lib.rs
sed -i '/unions_with_drop_fields/d' ./src/lib.rs
# Original svd has \n (two chars) in it, which gets converted to "\n" and "\\n" by svd2rust
# If we convert them to newline characters in the SVD, they don't turn up in markdown so docs suffers
# So, convert both \\n and \n to [spc] [spc] [newline], then strip the spaces out if there are consecutive [newlines]
# This means that by the time we're in markdown \n\n becomes new paragraph, and \n becomes a new line
find src -name '*.rs' -exec sed -i -e 's/\\\\n/\\n/g' -e 's/\\n/  \n/g' -e 's/\n  \n/\n\n/g' {} \;

# Sort specified fields alphanumerically for easier consumption in docs.rs
./sortFieldsAlphaNum.sh
