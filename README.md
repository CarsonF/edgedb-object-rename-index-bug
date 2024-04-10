Minimal reproduction of https://github.com/edgedb/edgedb/issues/7138

To run:
```bash
edgedb project init
yarn
yarn start
```

The [script](./src/index.ts) will execute and throw an error, which is the query failing with the bug.  
The query/script should execute fine.
