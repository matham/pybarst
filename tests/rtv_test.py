import pybarst
from pybarst.core.server import BarstServer
from pybarst.rtv import RTVChannel
import logging
logging.root.setLevel(logging.DEBUG)
import time as pytime

server = BarstServer(barst_path=r'C:\Program Files\Barst\Barst.exe',
                     pipe_name=r'\\.\pipe\TestPipe')
server.open_server()
val = server.get_version()
print(val)
assert val >= pybarst.__min_barst_version__
# in case program terminated incorrectly, make sure no rtv devices are
# still running
server.close_manager('rtv')
print(server.get_manager('rtv'))
print(server.managers)

# for the code below, there should be a RTV-4 like device connected, with
# a port 0 available
rtv = RTVChannel(server=server, chan=0, video_fmt='full_NTSC',
                    frame_fmt='rgb24', lossless=False)
rtv.open_channel()
print(rtv)
rtv.close_channel_client()
try:
    # this should raise an exception b/c you cannot open an existing channel
    rtv.open_channel()
except Exception, e:
    print(e)
else:
    assert False
rtv.close_channel_server()
# re-create the channel on the server
rtv.open_channel()

try:
    # this should raise an exception b/c you cannot read inactive channel
    rtv.read()
except Exception, e:
    print(e)
else:
    assert False
rtv.set_state(state=True)

time, data = rtv.read()
print(time, len(data))
assert len(data) == rtv.buffer_size
assert len(data) == rtv.height * rtv.width * rtv.bpp
assert rtv.bpp == 3
time, data = rtv.read()
print(time, len(data))
assert len(data) == rtv.buffer_size
assert len(data) == rtv.height * rtv.width * rtv.bpp
assert rtv.bpp == 3
time, data = rtv.read()
print(time, len(data))
assert len(data) == rtv.buffer_size
assert len(data) == rtv.height * rtv.width * rtv.bpp
assert rtv.bpp == 3

# make sure a image is queued by server
pytime.sleep(.1)
rtv.set_state(state=False)
# we should still be able to read the queued image
time, data = rtv.read()
print(time, len(data))
assert len(data) == rtv.buffer_size
assert len(data) == rtv.height * rtv.width * rtv.bpp
assert rtv.bpp == 3

# make sure that there are no images waiting at the server
while 1:
    try:
        rtv.read()
    except:
        break

try:
    # this should raise an exception b/c we should be inactive
    rtv.read()
except Exception, e:
    print(e)
else:
    assert False
rtv.close_channel_server()


rtv.lossless = True
# re-create the channel on the server using lossless True
rtv.open_channel()
rtv.set_state(state=True)

time, data = rtv.read()
print(time, len(data))
assert len(data) == rtv.buffer_size
assert len(data) == rtv.height * rtv.width * rtv.bpp
assert rtv.bpp == 3

# let some data accumulate
pytime.sleep(1)
rtv.set_state(state=False, flush=True)
try:
    # this should raise an exception b/c we should instantly be inactive
    # since we flushed
    rtv.read()
except Exception, e:
    print(e)
else:
    assert False

# try again
rtv.set_state(state=True)
pytime.sleep(1)
time, data = rtv.read()
print(time, len(data))
assert len(data) == rtv.buffer_size
assert len(data) == rtv.height * rtv.width * rtv.bpp
assert rtv.bpp == 3

rtv.set_state(state=False, flush=False)
# there should still be data waiting
time, data = rtv.read()
print(time, len(data))
assert len(data) == rtv.buffer_size
assert len(data) == rtv.height * rtv.width * rtv.bpp
assert rtv.bpp == 3


rtv.close_channel_server()
server.close_manager('rtv')

print('All tests PASSED!')
