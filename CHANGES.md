## 0.5.1 (2016-11-26)

* Fix regression in Socketry::SSL::Socket#close

## 0.5.0 (2016-11-26)

* Require Ruby 2.2.6+ (earlier 2.2 versions had async I/O bugs)
* Extract Socketry::SSL::Socket#accept into its own method
* Simplify Socketry::SSL::Socket#from_socket API
* Raise Socketry::SSL::CertificateVerifyError for certificate verification errors
* Specs and bugfixes for Socketry::SSL::Server
* Rename Socketry::UDP::Datagram accessors to `remote_host`, `remote_addr`, and `remote_port`
* Update to RuboCop 0.45.0

## 0.4.0 (2016-11-25)

* Specs and bugfixes for SSL sockets
* Specs and bugfixes for UDP sockets
* Add Socketry::UDP::Datagram class
* Add Socketry::AddressInUseError exception

## 0.3.0 (2016-09-24)

* Implement Socketry::TCP::Socket#read and #write
* Use StandardError as the base class for Socketry::Error
* Add Socketry::ConnectionRefusedError
* Parameterize SSL contexts

## 0.2.0 (2016-09-12)

* Rename Socketry::TCP::Socket#connected? -> #closed?

## 0.1.0 (2016-09-11)

* Initial release
