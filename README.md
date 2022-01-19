Plate Barcode
=============

Description
-----------

Sinatra application which will connect to an oracle database called SNP and return a new plate barcode ID.

Installation
------------

For basic development install without the deployment gems to avoid needing to handle Oracle dependencies

```zsh
bundle install --without=deployment
```

In development mode we use a null database adapter, which is patched to have a counter stored in memory.

Usage
-----

In the repository base directory run:

```
bundle exec rackup -E development -p 3011 config.ru
```

Then point your browser at: `http://localhost:3011`

Create barcodes
---------------
