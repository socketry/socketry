# frozen_string_literal: true

require "coveralls"
Coveralls.wear!

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "socketry"

RSpec.configure(&:disable_monkey_patching!)

RSpec.shared_examples "Socketry DNS resolver" do
  let(:hosts_file_example) { "localhost" }
  let(:valid_dns_example)  { "travis-ci.org" }
  let(:invalid_example)    { "this is clearly not a valid DNS address, right?" }
  let(:invalid_timeout)    { "I'm not really a timeout" }

  it "resolves DNS requests to Resolv addresses" do
    [hosts_file_example, valid_dns_example].each do |hostname|
      expect(described_class.resolve(hostname, timeout: 5)).to be_a IPAddr
    end
  end

  it "raises Socketry::Resolver::Error if given an invalid address" do
    expect { described_class.resolve(invalid_example) }.to raise_error(Socketry::Resolver::Error)
  end

  it "raises TypeError if given a bogus timeout object" do
    expect { described_class.resolve(valid_dns_example, timeout: invalid_timeout) }.to raise_error(TypeError)
  end
end

RSpec.shared_examples "Socketry stream socket" do
  let(:example_data) { "Hello, peer!" }

  context "non-blocking I/O" do
    describe "#read_nonblock" do
      it "reads data if available" do
        peer_socket.write(example_data)
        peer_socket.close
        sleep 0.001 # :( sleeps like this are bad, but writing reliable I/O tests is hard

        expect(stream_socket.read_nonblock(example_data.size)).to eq example_data
      end

      it "returns :wait_readable if we aren't ready to read" do
        expect(stream_socket.read_nonblock(1)).to eq :wait_readable
      end
    end

    describe "#write_nonblock" do
      it "returns the number of bytes written on success" do
        expect(stream_socket.write_nonblock(example_data)).to eq example_data.size
      end

      pending "returns :wait_writable if we aren't ready to write"
    end
  end

  context "blocking reads" do
    describe "#readpartial" do
      it "reads partial data" do
        peer_socket.write(example_data)
        peer_socket.close

        # TODO: test the case the read is actually partial
        expect(stream_socket.readpartial(example_data.size)).to eq example_data
      end
    end

    describe "#read" do
      it "reads complete data" do
        peer_socket.write(example_data)
        peer_socket.close

        expect(stream_socket.read(example_data.size)).to eq example_data
      end
    end
  end

  context "blocking writes" do
    describe "#writepartial" do
      it "writes partial data" do
        # TODO: test the case the write is actually partial
        expect(stream_socket.writepartial(example_data)).to eq example_data.size
        expect(peer_socket.read(example_data.size)).to eq example_data
      end
    end

    describe "#write" do
      it "writes complete data" do
        expect(stream_socket.writepartial(example_data)).to eq example_data.size
        expect(peer_socket.read(example_data.size)).to eq example_data
      end
    end
  end

  describe "#to_io" do
    it "converts to a Ruby IO object" do
      expect(stream_socket.to_io).to be_a(::IO)
    end
  end
end

def unoccupied_port(addr: "localhost", port: 10_000, max_port: 15_000)
  loop do
    begin
      socket = TCPSocket.new(addr, port)
    rescue Errno::ECONNREFUSED
      return port
    ensure
      socket.close rescue nil
    end

    port += 1
    raise "exhausted too many ports" if port > max_port
  end
end

def ssl_cert_dir
  Pathname.new("../support/ssl").expand_path(__FILE__)
end

def ssl_cert_path(label)
  ssl_cert_dir.join(label.to_s + ".crt")
end

def ssl_key_path(label)
  ssl_cert_dir.join(label.to_s + ".key")
end
