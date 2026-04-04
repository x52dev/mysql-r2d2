# r2d2_mysql

> [`mysql`](https://github.com/blackbeam/rust-mysql-simple) support library for the [`r2d2`](https://github.com/sfackler/r2d2) connection pool.

[![crates.io](https://img.shields.io/crates/v/mysql-r2d2?label=latest)](https://crates.io/crates/mysql-r2d2)
[![Documentation](https://docs.rs/mysql-r2d2/badge.svg?version=26)](https://docs.rs/mysql-r2d2)
![Version](https://img.shields.io/badge/rustc-1.88+-ab6000.svg)
![License](https://img.shields.io/crates/l/mysql-r2d2.svg)
[![Download](https://img.shields.io/crates/d/mysql-r2d2.svg)](https://crates.io/crates/mysql-r2d2)

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
