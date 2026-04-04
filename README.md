# `mysql-r2d2`

<!-- prettier-ignore-start -->

[![crates.io](https://img.shields.io/crates/v/mysql-r2d2?label=latest)](https://crates.io/crates/mysql-r2d2)
[![Documentation](https://docs.rs/mysql-r2d2/badge.svg?version=27.0.0)](https://docs.rs/mysql-r2d2/27.0.0)
[![dependency status](https://deps.rs/crate/mysql-r2d2/27.0.0/status.svg)](https://deps.rs/crate/mysql-r2d2/27.0.0)
![MIT](https://img.shields.io/crates/l/mysql-r2d2.svg)
<br />
[![CI](https://github.com/x52dev/mysql-r2d2/actions/workflows/ci.yml/badge.svg)](https://github.com/x52dev/mysql-r2d2/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/x52dev/mysql-r2d2/branch/main/graph/badge.svg)](https://codecov.io/gh/x52dev/mysql-r2d2)
![Version](https://img.shields.io/badge/rustc-1.65+-ab6000.svg)
[![Download](https://img.shields.io/crates/d/mysql-r2d2.svg)](https://crates.io/crates/mysql-r2d2)

<!-- prettier-ignore-end -->

> [`mysql`](https://github.com/blackbeam/rust-mysql-simple) support library for the [`r2d2`](https://github.com/sfackler/r2d2) connection pool.

## Usage

```rust
use std::{env, sync::Arc, thread};

use mysql_r2d2::{
    mysql::{prelude::*, Opts, OptsBuilder},
    r2d2, MySqlConnectionManager,
};

fn main() {
    let url = env::var("DATABASE_URL").unwrap();
    let opts = Opts::from_url(&url).unwrap();
    let builder = OptsBuilder::from_opts(opts);
    let manager = MySqlConnectionManager::new(builder);
    let pool = Arc::new(r2d2::Pool::builder().max_size(4).build(manager).unwrap());

    let mut tasks = vec![];

    for _ in 0..3 {
        let pool = pool.clone();
        let th = thread::spawn(move || {
            let mut conn = pool.get().expect("error getting connection from pool");

            let _ = conn
                .query("SELECT version()")
                .map(|rows: Vec<String>| rows.is_empty())
                .expect("error executing query");
        });

        tasks.push(th);
    }

    for th in tasks {
        let _ = th.join();
    }
}
```
