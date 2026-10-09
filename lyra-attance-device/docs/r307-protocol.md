# R307 protocol notes

This project implements a practical R307 packet driver compatible with MicroPython.

## Packet structure

Each UART packet is parsed as follows:

- Header: 0xEF01
- Address: 4 bytes (default 0xFFFFFFFF)
- Packet identifier
- Length: 2 bytes big-endian, including the checksum
- Contents: one-byte command/confirmation code followed by parameters
- Checksum: 2 bytes big-endian; sum of packet identifier, length, and contents

## Commands implemented

- Verify password (0x13)
- Get image
- Convert image to template
- Search database
- Register/model generation
- Store model
- Delete template
- Empty database
- Template count read
- Read sys parameter

## Important handling

- Validate packet header before reading payload.
- Validate checksum before trusting the response.
- Treat no-finger conditions as recoverable device states.
- Do not transmit raw fingerprint images to the backend.
- Only send the matched template ID to the server.
