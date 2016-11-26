# frozen_string_literal: true

RSpec.describe Socketry::UDP::Socket do
  let(:bind_addr) { "localhost" }
  let(:bind_port) { 10_000 }

  let(:example_data) { "Hello, peer!" }

  subject(:udp_server) { described_class.bind(bind_addr, bind_port) }
  subject(:udp_client) { described_class.connect(bind_addr, bind_port) }

  describe "#initialize" do
    it "creates new sockets" do
      expect(described_class.new).to be_a described_class
    end
  end

  describe "#bind" do
    it "raises Socketry::AddressInUseError if an address is in use" do
      # Create the UDP server
      udp_server

      # Attempt to bind to the same host/port again
      expect { described_class.bind(bind_addr, bind_port) }.to raise_error(Socketry::AddressInUseError)

      udp_server.close
    end
  end

  describe "#connect" do
    before { udp_server }
    after  { udp_server.close }

    it "connects to UDP servers" do
      udp_socket = described_class.connect(bind_addr, bind_port)
      expect(udp_socket).to be_a described_class
      udp_socket.close
    end
  end

  describe "#recvfrom_nonblock" do
    it "needs tests!"
  end

  describe "#recvfrom" do
    before { udp_server }

    after do
      udp_client.close
      udp_server.close
    end

    it "receives messages" do
      udp_client.send example_data
      expect(udp_server.recvfrom(16).message).to eq example_data
    end
  end

  describe "#send" do
    context "without connect" do
      it "sends packets" do
        udp_socket = described_class.from_addr(bind_addr)
        expect(udp_socket.send(example_data, host: bind_addr, port: bind_port)).to eq example_data.size
      end
    end

    context "with connect" do
      it "sends packets" do
        expect(udp_client.send(example_data)).to eq example_data.size
      end
    end
  end
end
