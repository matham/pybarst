import pybarst
from pybarst.core.server import BarstServer
from pybarst.serial import SerialChannel
import logging
logging.root.setLevel(logging.DEBUG)

server = BarstServer(barst_path=r'C:\Program Files\Barst\Barst.exe',
                     pipe_name=r'\\PERSEPHONE\pipe\CPL_PERSEPHONE')
server.open_server()
val = server.get_version()
print(val)
assert val >= pybarst.__min_barst_version__
# in case program terminated incorrectly, make sure no serial devices are
# still running
server.close_manager('serial')
print(server.get_manager('serial'))
print(server.managers)

# for the code below, COM3 should have a loopback cable connected to it.
serial = SerialChannel(server=server, port_name='COM3', max_write=32,
                       max_read=32)
serial.open_channel()
print(serial)
serial.close_channel_client()
serial.open_channel()
serial.close_channel_client()
serial.open_channel()

text = 'cheesecake and fries.'
time, val = serial.write(value=text, timeout=10000)
print(time, val)
assert val == len(text)
# here we read the exact number of chars written.
time, val = serial.read(read_len=len(text), timeout=10000)
print(time, val)
assert len(val) == len(text)

text = 'apples with oranges.'
time, val = serial.write(value=text, timeout=10000)
print(time, val)
assert val == len(text)
# we read more than the number of chars written, forcing us to time out
time2, val = serial.read(read_len=32, timeout=10000)
print(time, val)
assert len(val) == len(text)
# we should have waited the full 10s timeout
assert time2 - time > 5.

time, val = serial.write(value='apples with oranges.', timeout=10000)
print(time, val)
assert val == len(text)
# we read less than the number of chars written only returning those chars
time, val = serial.read(read_len=7, timeout=10000)
print(time, val)
assert len(val) == 7
# now we read the rest
time, val = serial.read(read_len=len(text) - 7, timeout=10000)
print(time, val)
assert len(val) == len(text) - 7

time, val = serial.write(value='apples with oranges.', timeout=10000)
print(time, val)
assert val == len(text)
# we read less than the number of chars written only returning those chars
time, val = serial.read(read_len=7, timeout=10000)
print(time, val)
assert len(val) == 7
# now write even more
time, val = serial.write(value='apples.', timeout=10000)
print(time, val)
assert val == len('apples.')
# in this read, everything we haven't read is returned
time, val = serial.read(read_len=32, timeout=10000)
print(time, val)
assert len(val) == len(text) + len('apples.') - 7

time, val = serial.write(value='apples with oranges.', timeout=10000)
print(time, val)
assert val == len(text)
# we read more than the number of chars written, but becuase of the stop
# char, it doesn't wait to timeout, but returns everything it read when it
# hit the stop char, which here was a few more chars of the text written
time, val = serial.read(read_len=32, timeout=10000, stop_char='o')
print(time, val)
assert len(val) >= 12
# now finish up the read
time, val2 = serial.read(read_len=32, timeout=10000)
print(time, val2)
assert len(val) + len(val2) == len(text)


serial.close_channel_server()
server.close_manager('serial')

print('All tests PASSED!')
