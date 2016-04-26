# Redis Resource

Concourse CI resource for accessing Redis datastore.

### Why do I want to access a Redis datastore in my Concourse pipeline?
The main advantage to having a Redis server available to your Concourse
pipeline is to track transient state between runs of your pipeline.  In a
similar way that adding state-tracking via cookies to HTTP increases what you
can do, adding Redis to pipelines can open up a world of possibilities.

At the simplest, it can provide data for a unified dashboard to track the
state of all your pipelines in a single screen.  I've used it to record the
state of test pass/fail status that is in turn used by a plugin to Atlassian's
Stash Git Repository Manager to allow/deny merges of repository branches.

Furthermore, it can be used to pass data from one task to another between
jobs.  Before you were limited to using input and output of tasks only within
a single plan.  Now you can store data from a task in one job, then retrieve
it from a second, keying on a unique id that passes through the jobs (e.g. a
git commit hash of the repo under test)

It also provides a repository for version strings.  Unlike the semver-resource
that requires an external, third-party storage such as s3 or github, you can
store your versions right on your internal Redis server that runs right on the
Concourse DB instance.  Furthermore, if you're using
git-multibranch-resource, you can track multiple versions in parallel, just by
using a different key for each branch's version string.

The above are just examples of how we've used it or plan to use it in its very
short life so far.  Its potential usage is only limited to your imagination.

### Why wouldn't I just interact with Redis in my task.
True, you could just use Redis directly by your task, but that would mean you
would have to provide your task with an image that is configured with the
Redis client.  Not a big deal, but if your task is meant to run on a target
image that is itself under test by the task, you don't want to pollute the the
image with things that shouldn't be there for the intended purpose of the
image.

The resource handles all the connection details trough the familiar `source`
paradigm.  You simply have to tell it the keys you are interested in seeing,
and the `get` will create files of all the matching keys with the value as the
content.  Similarly, the `put` will take any file matching the keys patterns,
and set a key in redis using the name of the file with the content of the file
as the value.  No need to even know how Redis works.

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

### `out`: Push into Redis.

Store the contents of the files that match the keys in the redis datastore.
Note that if the location specified in the `from:` parameter only has a subset
of the matching keys, the implicit `get` that runs after the `put` will have
a different reference ID.

#### Parameters

* `from`: *Required.* The path of the directory that contains the files named
  after the keys to push.
