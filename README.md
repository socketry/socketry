# Socketry [![Gem Version][gem-image]][gem-link] [![Build Status][build-image]][build-link] [![Code Climate][codeclimate-image]][codeclimate-link] [![Coverage Status][coverage-image]][coverage-link] [![MIT licensed][license-image]][license-link]

[gem-image]: https://badge.fury.io/rb/socketry.svg
[gem-link]: https://rubygems.org/gems/socketry
[build-image]: https://secure.travis-ci.org/socketry/socketry.svg?branch=master
[build-link]: https://travis-ci.org/socketry/socketry
[codeclimate-image]: https://codeclimate.com/github/socketry/socketry.svg?branch=master
[codeclimate-link]: https://codeclimate.com/github/socketry/socketry
[coverage-image]: https://coveralls.io/repos/github/socketry/socketry/badge.svg?branch=master
[coverage-link]: https://coveralls.io/github/socketry/socketry?branch=master
[license-image]: https://img.shields.io/badge/license-MIT-blue.svg
[license-link]: https://github.com/socketry/socketry/blob/master/LICENSE.txt

High-level wrappers for Ruby sockets with advanced thread-safe timeout support.

**Does not require Celluloid!** Socketry provides sockets with thread-safe
timeout support that can be used with any multithreaded Ruby app. That said,
Socketry can also be used to provide asynchronous I/O with [Celluloid::IO].

[Celluloid::IO]: https://github.com/celluloid/celluloid-io

## Motivation

By default, Ruby sockets do not provide a built-in timeout mechanism. The only
timeout mechanism provided by the language leverages [timeout.rb], which uses
[unsafe multithreaded behaviors] to implement timeouts.

While Socketry provides a synchronous, blocking API similar to Ruby's own
`TCPSocket` and `UDPSocket` classes, behind the scenes it uses non-blocking I/O
to implement thread-safe timeouts.

Highly modular and pluggable, Socketry also provides the flexibility to
seamlessly leverage [Celluloid::IO] for event-driven I/O.

[timeout.rb]: http://ruby-doc.org/stdlib-2.3.1/libdoc/timeout/rdoc/Timeout.html
[unsafe multithreaded behaviors]: http://blog.headius.com/2008/02/ruby-threadraise-threadkill-timeoutrb.html
[Celluloid::IO]: https://github.com/celluloid/celluloid-io

## Installation

Add this line to your application's Gemfile:

```ruby
gem "socketry"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install socketry

## Basic Usage

Below is a basic example of how to use Socketry to make an HTTPS request:

```ruby
require "socketry"

socket = Socketry::SSL::Socket.connect("github.com", 443)
socket.writepartial("GET / HTTP/1.0\r\nHost: github.com\r\n\r\n")
p socket.readpartial(1024)
```

[TCP], [UDP], and [SSL] servers and sockets also available.

[TCP]: https://github.com/socketry/socketry/wiki/TCP
[UDP]: https://github.com/socketry/socketry/wiki/UDP
[SSL]: https://github.com/socketry/socketry/wiki/SSL

## Documentation

[Please see the Socketry wiki](https://github.com/socketry/socketry/wiki)
for more detailed documentation and usage notes.

[YARD API documentation](http://www.rubydoc.info/gems/socketry/)
is also available.

## Contributing

* Fork this repository on github
* Make your changes and send us a pull request
* If we like them we'll merge them
* If we've accepted a patch, feel free to ask for commit access

## License

Copyright (c) 2016 Tony Arcieri. Distributed under the MIT License. See
[LICENSE.txt](https://github.com/socketry/socketry/blob/master/LICENSE.txt)
for further details.
