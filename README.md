# Socketry [![Gem Version][gem-image]][gem-link] [![Build Status][build-image]][build-link] [![Code Climate][codeclimate-image]][codeclimate-link] [![Coverage Status][coverage-image]][coverage-link] [![MIT licensed][license-image]][license-link]

[gem-image]: https://badge.fury.io/rb/socketry.svg
[gem-link]: https://rubygems.org/gems/socketry
[build-image]: https://secure.travis-ci.org/celluloid/socketry.svg?branch=master
[build-link]: https://travis-ci.org/celluloid/socketry
[codeclimate-image]: https://codeclimate.com/github/celluloid/socketry.svg?branch=master
[codeclimate-link]: https://codeclimate.com/github/celluloid/socketry
[coverage-image]: https://coveralls.io/repos/github/celluloid/socketry/badge.svg?branch=master
[coverage-link]: https://coveralls.io/github/celluloid/socketry?branch=master
[license-image]: https://img.shields.io/badge/license-MIT-blue.svg
[license-link]: https://github.com/celluloid/socketry/blob/master/LICENSE.txt

High-level wrappers for Ruby sockets with advanced thread-safe timeout support.

**Does not require Celluloid!** Socketry provides sockets with thread-safe
timeout support that can be used with any multithreaded Ruby app. That said,
Socketry can also be used to provide asynchronous I/O with [Celluloid::IO].

[Celluloid::IO]: https://github.com/celluloid/celluloid-io

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'socketry'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install socketry

## Usage

TODO: Coming soon!

## Contributing

* Fork this repository on github
* Make your changes and send us a pull request
* If we like them we'll merge them
* If we've accepted a patch, feel free to ask for commit access

## License

Copyright (c) 2016 Tony Arcieri

Distributed under the MIT License. See
[LICENSE.txt](https://github.com/celluloid/socketry/blob/master/LICENSE.txt)
for further details.
