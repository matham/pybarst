import pybarst
from pybarst.core.server import BarstServer
from pybarst.ftdi import FTDIChannel
from pybarst.ftdi.switch import (SerializerSettings, FTDISerializerIn,
                                 FTDISerializerOut)
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
server.close_manager('ftdi')
print(server.get_manager('ftdi'))
print(server.managers)


'----------------------- Create the channel --------------------------'
# for the code below, there should be a FT232R/FT2232H like device connected
# and pins 0-5 should be unconnected

# input, two boards
ft_in = SerializerSettings(clock_bit=0, data_bit=1, latch_bit=2,
                 num_boards=2, clock_size=2, continuous=False, output=False)
# output
ft_out = SerializerSettings(clock_bit=3, data_bit=4, latch_bit=5,
                 num_boards=1, clock_size=2, output=True)

# FT2232H connected, using channel A of it.
ftdi = FTDIChannel(channels=[ft_in, ft_out],
                   server=server, desc='Birch Board rev1 A')

print('since open_channel, alloc keyword is false, a error should be raised')
try:
    channels = ftdi.open_channel()
except Exception, e:
    print(e)
else:
    assert False
print(ftdi)
channels = ftdi.open_channel(alloc=True)
# close and reopen this channel locally
ftdi.close_channel_client()
channels = ftdi.open_channel(alloc=False)
assert channels == ftdi.devices
assert len(channels) == 2

# ensure that the returned channels are the correct type
bases = [FTDISerializerIn, FTDISerializerOut]
for i in range(len(bases)):
    assert isinstance(channels[i], bases[i])

'----------------- Create another client for the channel --------------------'
# create a second client with the same channels, it should be automatically
# initialized with the channel list from server
ftdi2 = FTDIChannel(channels=[], server=server, desc='Birch Board rev1 A')
channels2 = ftdi2.open_channel(alloc=False)
assert channels2 == ftdi2.devices
assert len(channels2) == 2
# ensure that the returned channels are the correct type
for i in range(len(bases)):
    assert isinstance(channels2[i], bases[i])


'----------------------- Open all devices --------------------------'
print('try a read/write, it should fail because device is not open yet')
try:
    channels[0].read()
except Exception, e:
    print(e)
else:
    assert False
try:
    channels[1].write(set_high=[3], set_low=[5, 1])
except Exception, e:
    print(e)
else:
    assert False

# open local connection to each peripheral device, we don't really have to
# do it all at once
for device in channels2:
    device.open_channel()
for device in channels:
    device.open_channel()

print('try a read/write, it should fail because device is not active yet')
try:
    channels[0].read()
except Exception, e:
    print(e)
else:
    assert False
try:
    channels[1].write(set_high=[3], set_low=[5, 1])
except Exception, e:
    print(e)
else:
    assert False

# set the state to active for each device, any client, but only one client
# should do this because it activates it for all clients
for device in channels:
    device.set_state(True)


'---------------------------- now test ------------------------------'
# since no device may be connected, we cannot test the actual read/write values
client1_in, client2_in, client1_out, client2_out = (channels[0], channels2[0],
                                                    channels[1], channels2[1])
t, val = client1_in.read()
t2, val2 = client2_in.read()
print('Pin values: {}'.format(val))
assert len(val) == 16
assert len(val) == len(val2)
assert t2 > t

# write some
t = client1_out.write(set_high=[3], set_low=[5, 1])
t2 = client2_out.write(set_high=[3], set_low=[2, 1])
assert t2 > t

print("Writing to pin outside 0-7 is invalid since we set it to only one "
      "board")
try:
    client1_out.write(set_high=[8])
except Exception, e:
    print(e)
else:
    assert False
try:
    client2_out.write(set_high=[9])
except Exception, e:
    print(e)
else:
    assert False
try:
    client1_out.write(set_high=[-2])
except Exception, e:
    print(e)
else:
    assert False


'------------------ deactivate and close all devices --------------------'
# sets the state globally, so only one client should do it.
for device in channels2:
    device.set_state(False)
for device in channels:
    device.close_channel_client()
for device in channels2:
    # you cannot delete a peripheral device, so it should raise exception
    try:
        device.close_channel_server()
    except:
        pass
    else:
        assert False
for device in channels2:
    device.close_channel_client()

ftdi.close_channel_server()
server.close_manager('ftdi')

print('All tests PASSED!')
