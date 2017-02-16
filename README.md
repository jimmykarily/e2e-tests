# Caasp end to end tests

This project hosts the end-to-end tests for the Caasp platform. An environment
as close to production as possible is used to run the tests.

Unit and feature tests can also be found in the [velum project](https://github.com/kubic-project/velum).
These are tests that are utilizing all the components of the platform, therefore
they are slower and more complicated to setup.

## Tools

This project is using [Rspec](http://rspec.info/) and [Capybara](http://www.rubydoc.info/gems/capybara)
(with Phantomjs driver) to interact with Velum.

The testing environment is setup using kubelet (check the [Velum README](https://github.com/kubic-project/velum/blob/master/README.md) for more)
and we use terraform to create salt-minions that act as workers on the platform.

## Running the tests

For now:

**TODO**: Make everything completely automated

```
./start_environment
```

and when everything is up and running:

```
rspec spec/**/*
```

## License

This project is licensed under the Apache License, Version 2.0. See
[LICENSE](https://github.com/kubic-project/e2e-tests/blob/master/LICENSE) for the full
license text.
