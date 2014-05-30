from pybarst.core.server import BarstServer
from pybarst.ftdi import FTDIChannel
from pybarst.ftdi.adc import ADCSettings
import time

server = BarstServer(barst_path=r'C:\Program Files\Barst\Barst.exe',
                     pipe_name=r'\\.\pipe\TestPipe')
server.open_server()
server.close_server()
server.open_server()
print(server.get_manager('ftdi'))


# for the following tests, the clock should be connected at pin 7 of the
# FTDI port and the data pins should be connected to pins 0-6 in the forward
# order. Both ADC channels not be connected to anything, so it should read
# close to zero.
'-------------------------- Configurations -------------------------------'
# all the configurations to test
chans = ((True, False), (False, True), (True, True))  # if chan 1/2 are active
num_pins = range(2, 8)  # the number of data pins connected.
data_width = (16, 24)   # the width of the data points to read
data_rate = (11000, 1000)  # the sampling rate to use
max_error = 0.01    # the max diff from zero the channels may read
num_packets = 1000  # the number of adc packets to read before stopping


# generate the settings classes for all these combos
adc_settings = []
for chan1, chan2 in chans:
    for num_pin in num_pins:
        for width in data_width:
            for rate in data_rate:
                adc_settings.append(ADCSettings(clock_bit=7,
                lowest_bit=7 - num_pin, num_bits=num_pin,
                sampling_rate=(rate / 2) if chan1 and chan2 else rate,
                chan1=chan1, chan2=chan2, transfer_size=100, data_width=width))

ts = time.clock()
for i in range(len(adc_settings)):
    adc = adc_settings[i]
    server.close_manager('ftdi')  # make sure we start clean
    server.get_manager('ftdi')
    ftdi = FTDIChannel(channels=[adc], server=server,
                       desc='Birch Board rev1 B')

    # create the channel and open the adc peripheral and activate it
    adc, = ftdi.open_channel(alloc=True)
    adc.open_channel()
    adc.set_state(True)

    sett = adc.settings
    assert adc_settings[i].chan1 == sett.chan1
    assert adc_settings[i].chan2 == sett.chan2
    assert adc_settings[i].lowest_bit == sett.lowest_bit
    assert adc_settings[i].num_bits == sett.num_bits
    assert adc_settings[i].transfer_size == sett.transfer_size
    assert adc_settings[i].data_width == sett.data_width

    # now read
    idx = None
    fullness = []
    ch1, ch2 = [0], [0]
    tts = time.clock()
    while time.clock() - tts < 30:
        d = adc.read()
        fullness.append(d.fullness)
        if sett.chan1:
            assert sum(map(abs, d.chan1_data)) / sett.transfer_size < max_error
            assert abs(len(d.chan1_data) - sett.transfer_size) <= 1
            assert abs(len(d.chan1_raw) - sett.transfer_size) <= 1
            ch1.extend(map(abs, d.chan1_data))
        if sett.chan2:
            assert sum(map(abs, d.chan2_data)) / sett.transfer_size < max_error
            assert abs(len(d.chan2_data) - sett.transfer_size) <= 1
            assert abs(len(d.chan2_raw) - sett.transfer_size) <= 1
            ch2.extend(map(abs, d.chan2_data))

        assert not d.overflow_count
        assert not d.noref
        if idx is None:
            idx = d.count
        else:
            assert d.count == idx + 1
            idx = idx + 1
        assert not d.bad_count

    adc.set_state(False, True)
    ftdi.close_channel_server()

    print('{}/{} ok, t: {:.2f}, Channels: ({} [{:.4f}], {} [{:.4f}]), '
          'Bits: {}, Rate: {:.2f}, Width: {}, Full: {:.1f}%'
          .format(i + 1, len(adc_settings), time.clock() - ts,
                  bool(sett.chan1), sum(ch1) / len(ch1), bool(sett.chan2),
                  sum(ch2) / len(ch2), sett.num_bits, sett.sampling_rate,
                  sett.data_width, sum(fullness) / len(fullness) * 100))

# deactivate using and close
server.close_server()

print('All PASSED!!!!!!!!!!')
