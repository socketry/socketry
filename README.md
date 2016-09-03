# Socketry

[![Gem Version](https://badge.fury.io/rb/socketry.svg)](https://rubygems.org/gems/socketry)
[![Build Status](https://secure.travis-ci.org/celluloid/socketry.svg?branch=master)](https://travis-ci.org/celluloid/socketry)
[![Code Climate](https://codeclimate.com/github/celluloid/socketry.svg?branch=master)](https://codeclimate.com/github/celluloid/socketry)
[![Coverage Status](https://coveralls.io/repos/github/celluloid/socketry/badge.svg?branch=master)](https://coveralls.io/github/celluloid/socketry?branch=master)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/celluloid/socketry/blob/master/LICENSE.txt)

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

Copyright (c) 2015-2016 Tony Arcieri, Zachary Anker.

Distributed under the MIT License. See
[LICENSE.txt](https://github.com/celluloid/socketry/blob/master/LICENSE.txt)
for further details.
