# Redis Resource

Concourse CI resource for accessing redis datastore.


## Source Configuration

* `host`: *Required.* The name or ip of the Redis host.

* `port`: *Optional.* The port of the Redis host. Default: 6379

* `password`: *Optional.* The password to connect to the Redis server, if
  required.

* `db_number`: *Optional.* The Redis database number, defaults to 0

* `keys`: *Required.* An array of keys that are to be fetched and are allowed
  to be written. Each array element may use glob-style pattern matching.

### Example

Resource configuration:

``` yaml

resource_types:
  - name: redis
    type: docker-image
    source:
      repository: starkandwayne/redis-resource

resources:
- name: redis-values
  type: redis
  source:
    host: redis.myorg.com
    password: my-hard-to-guess-password
    db_number: 3
    keys:
      - this-key
      - that-key
      - "a:prefix:*"
```

Fetching values from the datastore

``` yaml
- get: redis-values
```

Pushing values to the datastore:

``` yaml
- put: redis-values
  params: {from: results}
```

## Behavior

### `check`: Check for changes to the key contents or new matching keys.

The keys are pulled, written to the filesystem with the key being the filename
and the value being the content.  If the sha1sum of these files and contents
differ, the sha1sum will be reported as a new version.

### `in`: Store the contents for the matching keys on the file system.

The keys are pulled, written to the filesystem with the key being the filename
and the value being the content.

### `out`: Push to a repository.

Store the contents of the files that match the keys in the redis datastore.

#### Parameters

* `from`: *Required.* The path of the directory that contains the files named
  after the keys to push.
