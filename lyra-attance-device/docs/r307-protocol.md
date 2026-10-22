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
- The startup command is VerifyPassword (`0x13`) with the configured 32-bit
  password. With the default password zero, the request is
  `EF01FFFFFFFF0100071300000000001B`; its successful ACK is
  `EF01FFFFFFFF07000300000A`. A timeout means a complete response packet was
  not received before the driver deadline; it is not a fingerprint mismatch.
- `esp32/r307_uart_diagnostic.py` uses the production `R307` driver for one
  bounded VerifyPassword test, reports zero/partial/malformed response states,
  and does not access templates or call the attendance API. Its optional
  loopback mode is separately guarded by
  `R307_LOOPBACK_CONFIRMED_DISCONNECTED`; physically disconnect the sensor
  before jumpering GPIO17 to GPIO16.
- Treat no-finger conditions as recoverable device states.
- Attendance uses the configured `R307_DETECTION_MODE` in `esp32/config.py`.
  The default is `hybrid`: a debounced GPIO18 edge is the primary hint, with
  one UART `GetImage` fallback probe every 2 seconds. GPIO18 polarity and
  reliability are unconfirmed; diagnostics showed it toggling during
  continuous contact. `R307_UART_FALLBACK_ENABLED` must be true for fallback
  probes to run. Set `R307_DETECTION_MODE = "gpio_only"` and disable fallback
  to test GPIO-only behavior; use `"uart_fallback"` to test UART-triggered
  detection without GPIO18. An idle fallback probe reporting ACK `0x02`
  resumes the idle wait; ACK `0x00` is required before conversion, and
  subsequent image capture retries are bounded. Neither no-image responses
  nor UART errors are fingerprint mismatches.
- `R307_TOUCH_ACTIVE_LEVEL` accepts `0`, `1`, or `None`. The available GPIO18
  diagnostic only showed toggles during sustained contact, so it did not
  establish which level means touched; `None` remains the default and treats
  a debounced edge in either direction as a capture hint. Set `0` or `1` only
  after correlating the level with physical contact on the device.
- After attendance feedback, removal polling requires three consecutive
  `GetImage` no-finger (`0x02`) responses, resetting the count on a successful
  image or communication error. This is a UART-based removal heuristic, not a
  separate presence sensor: if the sensor returns `0x02` while a finger is
  physically present, it can still confirm removal. A verified touch output
  or observation of stable module behavior is needed to strengthen that
  guarantee.
- Attendance capture and enrollment latch a finger placement until removal is
  confirmed. Removal polling is bounded by
  `R307_FINGER_REMOVAL_TIMEOUT_SECONDS`; a timeout keeps the scan locked and
  reports a sensor status instead of rearming on the same placement.
- Do not transmit raw fingerprint images to the backend.
- Only send the matched template ID to the server.
- Runtime access uses one `R307` instance and synchronous command/ACK
  transactions. Enrollment HTTP polling happens between sensor operations, not
  while a UART response is being read. The driver rejects overlapping commands.
- The UART diagnostic uses the same production driver and settings; do not run
  it concurrently with the attendance firmware over the same sensor UART.
- If a transaction times out, the next transaction waits briefly for and parses
  one complete late response from the timed-out command before sending a new command.
  It does not blindly flush the UART receive buffer. The
  main loop then verifies the sensor again using a bounded 2-to-30 second
  backoff; it does not repeat VerifyPassword on every normal scan or API poll.
