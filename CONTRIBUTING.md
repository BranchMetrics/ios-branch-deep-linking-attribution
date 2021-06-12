# Contribution Guidelines

Please submit Pull Requests against the staging branch in this repo.

Pull Requests are required to pass unit tests for merge.

Use the `Branch-TestBed-CI` scheme with Product > Test (cmd-U).

To verify at the command line:

```bash
$ bundle check || bundle install
$ bundle exec fastlane unit_tests
```
