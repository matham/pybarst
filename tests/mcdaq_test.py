import pybarst
from pybarst.core.server import BarstServer
from pybarst.mcdaq import MCDAQChannel
import logging
logging.root.setLevel(logging.DEBUG)
import time as pytime

server = BarstServer(barst_path=r'C:\Program Files\Barst\Barst.exe',
                     pipe_name=r'\\.\pipe\TestPipe')
server.open_server()
val = server.get_version()
print(val)
assert val >= pybarst.__min_barst_version__
# in case program terminated incorrectly, make sure no mcdaq devices are
# still running
server.close_manager('mcdaq')
print(server.get_manager('mcdaq'))
print(server.managers)


'----------------------- Create the channel --------------------------'
# for the code below, there should be a something a MC DAQ device connected
# which supports both reading and writing. It hsould be enumerated as port 0
daq = MCDAQChannel(chan=0, server=server, direction='rw', init_val=0)
print(daq)

print('try a read/write, it should fail because channel is not open yet')
try:
    daq.read()
except Exception, e:
    print(e)
else:
    assert False
daq.open_channel()
# close and reopen this channel locally
daq.close_channel_client()
daq.open_channel()
assert daq.chan == 0

'----------------- Create another client for the channel --------------------'
# create a second client with the same channels, it should be automatically
# initialized with the channel list from server
daq2 = MCDAQChannel(chan=0, server=server, direction='r')
print('try a read/write, it should fail because client2 is not open yet')
try:
    daq2.write(mask=0x00FF, value=0x000F)
except Exception, e:
    print(e)
else:
    assert False
daq2.open_channel()
assert daq2.direction == daq.direction
assert daq2.direction == 'rw' or daq2.direction == 'wr'


'------------------ test read/write devices --------------------'
# read both clients, they should be the same
t, val = daq.read()
t2, val2 = daq2.read()
print('Pin values: {:08b}'.format(val))
assert val == val2
assert t2 > t

# write from both clients
t = daq.write(mask=0x00FF, value=0x000F)
t2 = daq.write(mask=0x00FF, value=0x0000)
assert t2 > t


daq2.close_channel_client()
daq.close_channel_server()

'------------------ test continuous read device --------------------'

daq = MCDAQChannel(chan=0, server=server, direction='rw', init_val=0,
                   continuous=True)
daq2 = MCDAQChannel(chan=0, server=server, direction='r')
daq.open_channel()
daq2.open_channel()


# set it high
val = []
val2 = []
ts = pytime.clock()
start = start2 = False
# read simultaneously from both clients to make sure that each client only
# triggers itself, not both
while 1:
    # for the first 3 seconds trigger and read client1
    if pytime.clock() - ts <= 3:
        t, v = daq.read()
        val.append((t, v))
    # for the next 3 seconds read both clients
    elif pytime.clock() - ts <= 6:
        t, v = daq.read()
        val.append((t, v))
        if not start2:
            start2 = True
        t, v = daq2.read()
        val2.append((t, v))
    elif pytime.clock() - ts <= 9:
        # stop the first client from reading
        if not start:
            daq.cancel_read(flush=True)
            start = True
        t, v = daq2.read()
        val2.append((t, v))
    else:
        break
# and stop client 2 as well
daq2.cancel_read(flush=True)


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
t1, val = daq.read()
# let data pile up
pytime.sleep(6)
daq.cancel_read(flush=False)
# because we didn't flush, we should read old data
t2, val = daq.read()
assert t2 - t1 < 0.1
# cancel again, and flush
daq.cancel_read(flush=True)

pytime.sleep(3)
# start another read
t3, val = daq.read()
# we should read new data, not old because we flushed
assert t3 - t2 > 2.5
# let data pile up
pytime.sleep(6)
daq.cancel_read(flush=True)
# because we flushed, we should read new data
t4, val = daq.read()
assert t4 - t3 > 5.5
# stop the read
daq.cancel_read(flush=True)


daq2.close_channel_client()
daq.close_channel_server()
server.close_manager('mcdaq')

print('All tests PASSED!')
