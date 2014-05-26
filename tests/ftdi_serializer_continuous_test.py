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
                 num_boards=2, clock_size=2, continuous=True, output=False)
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
client1_in, client2_in, client1_out, client2_out = (channels[0], channels2[0],
                                                    channels[1], channels2[1])
print('Canceling without a read request should cause an exception')
try:
    client1_in.cancel_read(flush=True)
except Exception, e:
    print(e)
else:
    assert False
try:
    client2_in.cancel_read(flush=True)
except Exception, e:
    print(e)
else:
    assert False

# write
client1_out.write(set_high=[3], set_low=[5, 1])
val = []
val2 = []
ts = pytime.clock()
start = start2 = False
# read simultaneously from both clients to make sure that each client only
# triggers itself, not both
while 1:
    # for the first 3 seconds trigger and read client1
    if pytime.clock() - ts <= 3:
        t, v = client1_in.read()
        val.append((t, v))
        assert len(v) == 16
    # for the next 3 seconds read both clients
    elif pytime.clock() - ts <= 6:
        t, v = client1_in.read()
        val.append((t, v))
        assert len(v) == 16
        if not start2:
            print("Client2 hasn't read so it should still not be able to "
            "cancel.")
            try:
                client2_in.cancel_read(flush=True)
            except Exception, e:
                print(e)
            else:
                assert False
            start2 = True
        t, v = client2_in.read()
        val2.append((t, v))
        assert len(v) == 16
    elif pytime.clock() - ts <= 9:
        # stop the first client from reading
        if not start:
            client1_in.cancel_read(flush=True)
            start = True
        t, v = client2_in.read()
        val2.append((t, v))
        assert len(v) == 16
    else:
        break
# and stop client 2 as well
client2_in.cancel_read(flush=True)
print('After a cancel with flush, another cancel should fail.')
try:
    client1_in.cancel_read(flush=True)
except Exception, e:
    print(e)
else:
    assert False
try:
    client2_in.cancel_read(flush=True)
except Exception, e:
    print(e)
else:
    assert False


# the second client reads should start 3 sec after first
assert val2[0][0] - val[0][0] > 2.5
# the second client reads should end 3 sec after first
assert val2[-1][0] - val[-1][0] > 2.5
print('Read {}, {} items at a rate of {} Hz, {} Hz for clients 1 and 2.'.
      format(len(val), len(val2), len(val) / (val[-1][0] - val[0][0]),
             len(val2) / (val2[-1][0] - val2[0][0])))
print('Client 1 and 2 read in intervals, ({}, {}), ({}, {}), respectively.'
      .format(val[0][0], val[-1][0], val2[0][0], val2[-1][0]))


# start a read
t1, val = client1_in.read()
# let data pile up
pytime.sleep(6)
client1_in.cancel_read(flush=False)
# because we didn't flush, we should read old data
t2, val = client1_in.read()
assert t2 - t1 < 0.1
# cancel again, and flush
client1_in.cancel_read(flush=True)

pytime.sleep(3)
# start another read
t3, val = client1_in.read()
# we should read new data, not old because we flushed
assert t3 - t2 > 2.5
# let data pile up
pytime.sleep(6)
client1_in.cancel_read(flush=True)
# because we flushed, we should read new data
t4, val = client1_in.read()
assert t4 - t3 > 5.5
# stop the read
client1_in.cancel_read(flush=True)


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
