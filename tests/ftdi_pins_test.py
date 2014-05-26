import pybarst
from pybarst.core.server import BarstServer
from pybarst.ftdi import FTDIChannel
from pybarst.ftdi.switch import PinSettings, FTDIPinIn, FTDIPinOut
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
# and pins 0-7 should be unconnected
in_mask = 0b00000011
out_mask = 0b00000110
bi_mask = in_mask & out_mask

# single byte input
ft_in = PinSettings(bitmask=in_mask, num_bytes=1, output=False)
# 4 byte input
ft_in2 = PinSettings(bitmask=in_mask << 3, num_bytes=4, output=False)

# single byte output
ft_out = PinSettings(bitmask=out_mask, num_bytes=1, init_val=0xFF, output=True)
# 4 byte output
ft_out2 = PinSettings(bitmask=out_mask << 3, num_bytes=4, init_val=0xFF,
                      output=True)

# single byte continuous input
ft_in_cont = PinSettings(bitmask=in_mask << 6, num_bytes=1, continuous=True,
                         output=False)
# single byte output
ft_out3 = PinSettings(bitmask=(out_mask << 6) & 0xFF, num_bytes=2,
                      init_val=0xFF, output=True)

# FT2232H connected, using channel A of it.
ftdi = FTDIChannel(channels=[ft_in, ft_in2, ft_out, ft_out2, ft_in_cont,
                             ft_out3],
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
assert len(channels) == 6

# ensure that the returned channels are the correct type
bases = [FTDIPinIn, FTDIPinIn, FTDIPinOut, FTDIPinOut, FTDIPinIn, FTDIPinOut]
for i in range(len(bases)):
    assert isinstance(channels[i], bases[i])

'----------------- Create another client for the channel --------------------'
# create a second client with the same channels, it should be automatically
# initialized with the channel list from server
ftdi2 = FTDIChannel(channels=[], server=server, desc='Birch Board rev1 A')
channels2 = ftdi2.open_channel(alloc=False)
assert channels2 == ftdi2.devices
assert len(channels2) == 6
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
    channels[2].write(buff_mask=0xFF, buffer=[0xFF])
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
    channels[2].write(buff_mask=0xFF, buffer=[0xFF])
except Exception, e:
    print(e)
else:
    assert False

# set the state to active for each device, any client, but only one client
# should do this because it activates it for all clients
for device in channels:
    device.set_state(True)


'------------------ test single byte read/write devices --------------------'
client1_in, client2_in, client1_out, client2_out = (channels[0], channels2[0],
                                                    channels[2], channels2[2])
# read both clients, they should be the same
t, val = client1_in.read()
t2, val2 = client2_in.read()
print('Pin values: {}'.format(bin(val[0])))
assert len(val) == 1
assert val == val2
assert t2 > t
# we should read the initialized output value, which was initialized to 0xFF
assert bi_mask == val2[0] & bi_mask

# set everything low, but only bi_mask should be changed for reading device
# write with one client, and read with the other
client1_out.write(buff_mask=0xFF, buffer=[0x00])
t2, val2 = client2_in.read()
assert val2[0] & bi_mask == 0x00
assert val2[0] & ~bi_mask == val[0] & ~bi_mask

# write but set the mask so that the read portion cannot change
client2_out.write(buff_mask=0xFF & ~bi_mask, buffer=[0xFF])
t, val = client1_in.read()
assert val2[0] == val[0]

# finally set it high
client2_out.write(buff_mask=0xFF, buffer=[0xFF])
t2, val2 = client2_in.read()
assert bi_mask == val2[0] & bi_mask


'------------------ test 4 byte read/write devices --------------------'
bi_mask = bi_mask << 3
client1_in, client2_in, client1_out, client2_out = (channels[1], channels2[1],
                                                    channels[3], channels2[3])
# read both clients, they should be the same
t, val = client1_in.read()
t2, val2 = client2_in.read()
print('Pin values: {}'.format(map(bin, val)))
assert len(val) == 4
assert val == val2
assert t2 > t
# make sure all values read are the same
assert len(set(val)) == 1

# set everything low
client1_out.write(buff_mask=0xFF, buffer=[0x00])
t2, val2 = client2_in.read()
assert val2[0] & bi_mask == 0x00
assert len(val2) == 4
assert len(set(val2)) == 1

# finally set it high
client2_out.write(buff_mask=0xFF, buffer=[0xFF])
t, val = client1_in.read()
assert val[0] & bi_mask == bi_mask
assert len(val) == 4
assert len(set(val)) == 1


'------------------ test continuous read device --------------------'
bi_mask = (bi_mask << 3) & 0xFF  # make sure it's only 8 bit
client1_in, client2_in, client1_out, client2_out = (channels[4], channels2[4],
                                                    channels[5], channels2[5])
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

# set it high
client1_out.write(buff_mask=0xFF, buffer=[0xFF])
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
        assert v[0] & bi_mask == bi_mask
        assert len(v) == 1
    # for the next 3 seconds read both clients
    elif pytime.clock() - ts <= 6:
        t, v = client1_in.read()
        val.append((t, v))
        assert v[0] & bi_mask == bi_mask
        assert len(v) == 1
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
        assert v[0] & bi_mask == bi_mask
        assert len(v) == 1
    elif pytime.clock() - ts <= 9:
        # stop the first client from reading
        if not start:
            client1_in.cancel_read(flush=True)
            start = True
        t, v = client2_in.read()
        val2.append((t, v))
        assert v[0] & bi_mask == bi_mask
        assert len(v) == 1
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
