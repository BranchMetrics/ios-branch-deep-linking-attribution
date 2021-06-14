# Contribution Guidelines

Please submit Pull Requests against the master branch in this repo.
There is no more staging branch.

Pull Requests are required to pass unit tests for merge.

Use the `Branch-TestBed-CI` scheme with Product > Test (cmd-U).

To verify at the command line:

```bash
$ bundle check || bundle install
$ bundle exec fastlane unit_tests
```
