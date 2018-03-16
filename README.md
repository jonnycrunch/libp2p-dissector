# Libp2p Dissector for Wireshark

WIP

## Todo:
 - [x] Write dissector for multistream
    - [ ] Recursive multistream stack
 - [ ] Write dissector for secio _WIP_
    - [ ] Fix protobuf bugs
    - [ ] Decryption using dumped keys
 - [ ] Write dissector for spdy (spdyshark)
 - [ ] Write dissector for mplex
 - [ ] Write dissector for yamux
 - [ ] Add some IPFS protocols

## Development

- Clone the wireshark source `$ git clone https://code.wireshark.org/review/wireshark`
- Clone the libp2p dissector `$ git clone git@github.com:mkg20001/libp2p-dissector plugins/epan/libp2p --recursive`
- Copy the additional makefiles `$ cp -r plugins/epan/libp2p/dev/* .`
- Setup the development environment using CMake

**Note: When pulling use `git pull --recursive` as otherwise submodules will not get updated**