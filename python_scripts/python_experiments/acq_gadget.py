# This code is for recording power consumption corresponding to random inputs.
# This code uses Rapid Block Mode of the Picoscope for recording the traces.
# The traces can be used for computing the SNR and f-test.
from picosdk.ps5000a import ps5000a as ps
from picosdk.functions import mV2adc, assert_pico_ok
import serial
import ctypes
import TRS_TraceSet
from tqdm import tqdm
from type_of_execution_gadget import *
start_time = time.time()


class Acquisition_Gadget(object):
    def __init__(self, gadget_name, name_trs_file, Mask_ORD=2, step=1000,
                 Number_traces=30000, points_per_cycle=125,
                 total_cycle=38, max_sam_in_pico_mem=128E6,
                 timebase=2, voltage_range="PS5000A_500MV", v_range=0.5,
                 start_cycle=0, end_cycle=0, ftest=False, ftest_collapsed=False,
                 ttest_f_vs_r=False, split_ttest=False, sh_i=None, sh_k=None,
                 tpl_attackt=False, fix_a=None, fix_b=None):

        check_status_ftest_ttest_template(ftest, ftest_collapsed, ttest_f_vs_r, split_ttest, sh_i, sh_k, tpl_attackt)
        valid_gadget(gadget_name)

        self.G_n = gadget_name
        self.Mask_ORD = Mask_ORD
        self.path_trace = "/media/IWAS\\mahpar/T7 Shield/Nima_2_Jan/"
        self.trs = None
        self.step = step  # Printing the related data on screen after 100 acquisition
        self.name_trs_file = name_trs_file
        # Number of traces
        self.Number_traces = Number_traces
        self.ftest = ftest
        self.ftest_collapsed = ftest_collapsed
        self.ttest_f_vs_r = ttest_f_vs_r
        self.split_ttest = split_ttest
        self.sh_i = sh_i
        self.sh_k = sh_k
        self.d = 1 if ttest_f_vs_r else 0
        self.tpl_attackt = tpl_attackt
        self.fix_a = fix_a
        self.fix_b = fix_b

        # self.n_traces_in_1rapid_block: the number of memory segments that the scope device will use,
        # and he number of waveforms to be captured in one run
        # self.n_traces_in_1rapid_block = n_traces_in_1rapid_block
        # Number of samples
        # timebase = (2 ^ 1)/10e-9 = 2ns, sampling rate = 500 MSa/s
        # (Page 22, 3.6 Timebase, Programming with the PicoScope 5000 Series (A API))
        # https://www.picotech.com/download/manuals/picoscope-5000-series-a-api-programmers-guide.pdf
        ## Timebase: n=1:sampling_rate:500, n=2:sampling_rate:250, n=3:sampling_rate:125
        self.timebase = timebase
        # using channel A
        self.voltage_range = voltage_range
        self.v_range = v_range

        # HPC1_opt_2: freq = 2MHz, T ~= 86 us
        # points_per_clock = (1/f) * sampling_rate
        self.points_per_cycle = points_per_cycle  # each clock is sampled with 125 points
        # samples = number_of_cycles * points_per_clock
        # samples = 92 * points_per_clock

        if start_cycle > total_cycle or (end_cycle + 1) > total_cycle:
            raise Exception("start_cycle > total_cycle or (end_cycle + 1) > total_cycle")
        self.total_cycle = total_cycle

        self.start_cycle = start_cycle
        self.start_s_stor = self.start_cycle * self.points_per_cycle
        self.end_cycle = end_cycle + 1
        self.end_s_stor = self.end_cycle * self.points_per_cycle
        self.storing_n_cycle = self.end_cycle - self.start_cycle
        self.storing_m_sample = self.storing_n_cycle * self.points_per_cycle
        self.samples = self.total_cycle * self.points_per_cycle
        self.x = self.start_cycle * self.points_per_cycle
        self.x = 0

        # self.trs.write_header(self.Number_traces, self.samples, True, all_len_t, xscale, yscale)
        if (self.start_cycle == 0) and (self.end_cycle == 1):
            self.trs_Header = self.samples
            self.s_e = slice(None)
            print('[+] Each trace contains {:d} samples'.format(self.samples))

        else:
            self.trs_Header = self.storing_m_sample
            self.s_e = slice(self.start_s_stor, self.end_s_stor)
            print('[+] Each trace contains {:d} samples'.format(self.storing_m_sample))

        if (self.Number_traces * self.samples) <= max_sam_in_pico_mem:
            self.repeat = 1
            self.n_traces_in_1rapid_block = self.Number_traces
        else:
            self.n_traces_in_1rapid_block = int(max_sam_in_pico_mem / self.samples)
            self.repeat = math.ceil(self.Number_traces / self.n_traces_in_1rapid_block)
        self.q = self.Number_traces % self.n_traces_in_1rapid_block
        print("\n-------------------------------------------------------------------")
        print("ACQ_trs_file:", self.name_trs_file)
        print("n_traces_in_1rapid_block=", self.n_traces_in_1rapid_block, ",  repeat=", self.repeat)
        print("Last repeat contains {} traces".format(self.q))
        print("-------------------------------------------------------------------")

    def capture(self):
        # Serial port communication: look this up in 'device manager'
        port = '/dev/ttyUSB0'  # Serial port

        # Initialized random generator for generating inputs and randomness
        ##################################################
        random.seed()

        # Open serial port
        ##################################################
        ser = serial.Serial(port)
        print("Opening the serial port ...")

        # Wait for 200ms
        time.sleep(0.1)

        # Connect the scope
        # Create chandle and status ready for use
        ##################################################
        chandle = ctypes.c_int16()
        status = {}

        # Open 5000 series PicoScope
        #################################################
        # ps5000aOpenUnit(*handle, *serial, resolution)
        # handle = chandle = ctypes.c_int16()
        # serial = None: the serial number of the scope
        # Resolution set to 8 Bit
        resolution = ps.PS5000A_DEVICE_RESOLUTION["PS5000A_DR_8BIT"]
        # Returns handle to chandle for use in future API functions
        status["openunit"] = ps.ps5000aOpenUnit(ctypes.byref(chandle), None, resolution)

        try:
            assert_pico_ok(status["openunit"])
        except:  # PicoNotOkError:
            powerStatus = status["openunit"]

            # When a USB 3.0 device is connected to a non-USB 3.0 port, this means:
            # PICO_USB3_0_DEVICE_NON_USB3_0_PORT = (uint)0x0000011EUL == 286;
            if powerStatus == 286:
                status["changePowerSource"] = ps.ps5000aChangePowerSource(chandle, powerStatus)
            else:
                raise
            assert_pico_ok(status["changePowerSource"])

        # Set up channel A
        print("Preparing channel A ...")
        #################################################
        # ps5000aSetChannel(handle, channel, enabled, coupling_type, ch_Range, analogueOffset)
        # handle = chandle = ctypes.c_int16()
        chA = ps.PS5000A_CHANNEL["PS5000A_CHANNEL_A"]
        coupling_type = ps.PS5000A_COUPLING["PS5000A_DC"]
        # chA_Range = ps.PS5000A_RANGE["PS5000A_500MV"]
        chA_Range = ps.PS5000A_RANGE[self.voltage_range]
        status["setChA"] = ps.ps5000aSetChannel(chandle, chA, 1, coupling_type, chA_Range, 0.3)
        assert_pico_ok(status["setChA"])

        # Set up channel B
        print("Preparing channel B ...")
        #################################################
        # ps5000aSetChannel(handle, channel, enabled, coupling_type, ch_Range, analogueOffset)
        # handle = chandle = ctypes.c_int16()
        chB = ps.PS5000A_CHANNEL["PS5000A_CHANNEL_B"]
        coupling_type = ps.PS5000A_COUPLING["PS5000A_DC"]

        #  opt / picoscope / include / libps5000a / ps5000aApi.h:  enPS5000ARange
        chB_Range = ps.PS5000A_RANGE["PS5000A_5V"]
        status["setChB"] = ps.ps5000aSetChannel(chandle, chB, 1, coupling_type, chB_Range, 0)
        assert_pico_ok(status["setChB"])

        # Gets timebase information
        #################################################
        # ps5000GetTimebase(handle,timebase,noSamples,* timeIntervalNanoseconds,oversample,* maxSamples, segmentIndex)
        # ps5000GetTimebase2: 2 is because of float
        # Handle = chandle
        # Nosample = samples
        # TimeIntervalNanoseconds = ctypes.byref(timeIntervalns)
        # MaxSamples = ctypes.byref(returnedMaxSamples)
        # Segement index = 0
        timeIntervalns = ctypes.c_float()
        returnedMaxSamples = ctypes.c_int32()
        status["GetTimebase"] = ps.ps5000aGetTimebase2(chandle, self.timebase, self.samples,
                                                       ctypes.byref(timeIntervalns),
                                                       ctypes.byref(returnedMaxSamples), 0)
        assert_pico_ok(status["GetTimebase"])

        # Set up signal trigger (Using Channel B)
        print("Preparing the trigger through channel B ...")
        #################################################
        post_trigger = False
        # trigger threshold(mV)
        threshold = 2000
        # trigger direction
        posedge_trigger = True
        delay = 0

        # if post_trigger:
        #     preTriggerSamples = 0  # preTriggerSamples
        #     postTriggerSamples = samples  # postTriggerSamples
        # else:
        #     preTriggerSamples = samples
        #     postTriggerSamples = 0

        if post_trigger:
            preTriggerSamples = 0  # preTriggerSamples
            postTriggerSamples = self.samples  # postTriggerSamples
        else:
            # 8: Number of unrelated instructions,
            # the instructions that used to separating main codes from trigger
            # and also the instructions that are used to create pos_edge of trigger
            preTriggerSamples = self.samples + self.x
            postTriggerSamples = self.x

        # ps5000aSetSimpleTrigger(handle, enable,source, threshold, direction, delay, autoTrigger_ms)
        # handle = chandle = ctypes.c_int16()
        source = ps.PS5000A_CHANNEL["PS5000A_CHANNEL_B"]
        # mV2adc(millivolts, range, maxADC): Takes a voltage value and converts it into adc counts
        # maxADC = ctypes.c_int16(32512) # 32512 the Max value that PicoScope can represent.
        # however, it should be 2 ^ 16 = 65536
        # when vertical values are represented by integer,
        # they are always in range (the range of vertical axis) [-32512, 32512]* uint
        # [-5v, 5V]
        threshold = mV2adc(threshold, chB_Range, ctypes.c_int16(32512))
        direction_rising = ps.PS5000A_THRESHOLD_DIRECTION["PS5000A_RISING"]
        direction_falling = ps.PS5000A_THRESHOLD_DIRECTION["PS5000A_FALLING"]

        if posedge_trigger:
            status["trigger"] = ps.ps5000aSetSimpleTrigger(chandle, 1, source, threshold, direction_rising, delay, 0)

        else:
            status["trigger"] = ps.ps5000aSetSimpleTrigger(chandle, 1, source, threshold, direction_falling, delay, 0)

        assert_pico_ok(status["trigger"])

        # Setup MemorySegments
        #################################################
        # ps5000MemorySegments(handle, nSegments, * nMaxSamples)
        cmaxSamples = ctypes.c_int32()  # the number of samples that are available in each segment,
        # if two channels are enabled it will be halved
        # Here, main signal is on ChA, Trigger is on ChB. All, two channels
        # Our pico has 256Ms memory, with two enabled channels, it would be 128Ms
        print("\n---------------------------")

        [n_rnd_g, in_len_g, out_len_g, in_len_t, out_len_t, all_len_t] = tx_rx_data_len(self.Mask_ORD, self.d, self.G_n)
        # Write TRS file header
        #################################################
        # write_header(n, number_of_samples, isint, cryptolen, xscale, yscale):
        # The data stored in trs file is:
        # 1: data_set(for indicating the data is random or fix) + 2: input_a + 3: input_b +
        # 4: input_of_gadget (= mask_a + mask_b + rnd_gadget) + 5: shares of the output of the gadget
        self.trs = TRS_TraceSet.TRS_TraceSet(self.path_trace + self.name_trs_file + ".trs")
        print(self.path_trace + self.name_trs_file + ".trs")
        # 65536 = 2 ^ 16
        # yscale is Vertical UNIT. unit=ChannelA.range/65536.
        # chA_Range = ps.PS5000A_RANGE["PS5000A_1V"]: 1 V ---> 1/65536
        # timebase = 1: 2/1e9 = 2 ns = 2e-9
        xscale = (2 ** self.timebase) / 1E9
        yscale = self.v_range / 65536

        self.trs.write_header(self.Number_traces, self.trs_Header, True, all_len_t, xscale, yscale)
        counter = 0

        for n in tqdm(range(self.repeat)):
            if (n == self.repeat - 1) and (self.q != 0):
                self.n_traces_in_1rapid_block = self.q

            status["MemorySegments"] = ps.ps5000aMemorySegments(chandle, self.n_traces_in_1rapid_block,
                                                                ctypes.byref(cmaxSamples))
            assert_pico_ok(status["MemorySegments"])

            # Set the number of captures
            #################################################
            # ps5000SetNoOfCaptures(handle, nCaptures), This function sets the number of
            # captures to be collected in one run of rapid block mode. Call before a run
            # the number of memory segments equal to or greater than the number of captures
            status["SetNoOfCaptures"] = ps.ps5000aSetNoOfCaptures(chandle, self.n_traces_in_1rapid_block)
            assert_pico_ok(status["SetNoOfCaptures"])

            source = ps.PS5000A_CHANNEL["PS5000A_CHANNEL_A"]

            Databuffer = []
            for i in range(self.n_traces_in_1rapid_block):
                buffer = (ctypes.c_int16 * self.samples)()
                Databuffer.append(buffer)
                status["SetDataBuffers"] = ps.ps5000aSetDataBuffers(chandle, source, ctypes.byref(buffer), None,
                                                                    self.samples, i, 0)
                assert_pico_ok(status["SetDataBuffers"])

            # Starts the block capture
            #################################################
            # ps5000aRunBlock(handle,noOfPreTriggerSamples,noOfPostTriggerSamples,
            # timebase, * timeIndisposedMs,segmentIndex,lpReady,* pParameter)
            # Start the oscilloscope running (starts a collection of data points (samples) in block mode)
            # Handle = chandle
            # Number of prTriggerSamples
            # Number of postTriggerSamples
            # Timebase = 2 = 4ns (see Programmer's guide for more information on timebases)
            # time indisposed ms = None (This is not needed within the example)
            # Segment index = 0
            # LpRead = None
            # pParameter = None
            status["runBlock"] = ps.ps5000aRunBlock(chandle, preTriggerSamples, postTriggerSamples, self.timebase, None,
                                                    0, None, None)
            assert_pico_ok(status["runBlock"])
            # Executing the code rapid-block times
            ##################################################
            # Traces for using in f-test or snr
            if self.ftest:
                [in_data, out_data] = EXE_Ftest(self.G_n, self.Mask_ORD + 1, self.step,
                                                self.n_traces_in_1rapid_block, in_len_g,
                                                n_rnd_g, out_len_g, ser, self.ftest_collapsed)

            # Traces for using in t-test
            if self.ttest_f_vs_r:
                # self.ttest_f_vs_r = ttest_f_vs_r
                if self.split_ttest:
                    [in_data, out_data] = EXE_i_k_fix_rnd_data(self.G_n, self.sh_i, self.sh_k,
                                                               self.Mask_ORD, self.step,
                                                               self.n_traces_in_1rapid_block, in_len_g,
                                                               n_rnd_g, out_len_g, ser, fix_value=0)
                else:
                    [in_data, out_data] = EXE_fix_rnd_data(self.G_n, self.Mask_ORD, self.step,
                                                           self.n_traces_in_1rapid_block, in_len_g,
                                                           n_rnd_g, out_len_g, ser, fix_value=0)

            # Traces for using in template-attack
            if self.tpl_attackt:
                [in_data, out_data] = EXE_FIX(self.G_n, self.Mask_ORD + 1, self.step,
                                              self.n_traces_in_1rapid_block, in_len_g,
                                              n_rnd_g, out_len_g, ser,
                                              a_fix=self.fix_a, b_fix=self.fix_b)
            # data collection from scope ps5000aIsReady
            #################################################
            # Check for data collection to finish using ps5000aIsReady
            #################################################
            # ps5000aIsReady(chandle, * ready)
            # handle = chandle = ctypes.c_int16()
            ready = ctypes.c_int16(0)
            check = ctypes.c_int16(0)
            while ready.value == check.value:
                status["isReady"] = ps.ps5000aIsReady(chandle, ctypes.byref(ready))

            # Create overflow location
            #################################################
            # ps5000aGetValuesBulk(handle, * noOfSamples, fromSegmentIndex, toSegmentIndex,
            # downSampleRatio, downSampleRatioMode, * overflow)
            # allows more than one waveform to be retrieved at a time in rapid block
            # mode. The waveforms must have been collected sequentially and in the same run
            # handle = chandle = ctypes.c_int16()
            overflow = (ctypes.c_int16 * self.n_traces_in_1rapid_block)()
            # create converted type maxSamples
            cTotalSamples = ctypes.c_int32(self.samples)
            status["GetValuesBulk"] = ps.ps5000aGetValuesBulk(chandle, ctypes.byref(cTotalSamples), 0,
                                                              self.n_traces_in_1rapid_block - 1, 0, 0,
                                                              ctypes.byref(overflow))
            assert_pico_ok(status["GetValuesBulk"])

            #################################################
            # ps.ps5000aGetValuesTriggerTimeOffsetBulk64(handle, * times,* timeUnits,fromSegmentIndex,toSegmentIndex)
            # retrieves the time offset, as a 64-bit integer, for a group of waveforms
            # captured in rapid block mode.
            # Times = (ctypes.c_int16 * self.n_traces_in_1rapid_block)()
            # TimeUnits = ctypes.c_char()
            # status["GetValuesTriggerTimeOffsetBulk"] = ps.ps5000aGetValuesTriggerTimeOffsetBulk64 \
            #     (chandle, ctypes.byref(Times), ctypes.byref(TimeUnits), 0, r_block-1)
            # assert_pico_ok(status["GetValuesTriggerTimeOffsetBulk"])

            for k in range(self.n_traces_in_1rapid_block):
                if overflow[k] != 0:
                    print("overflow!")

            traces_val = np.array(Databuffer)
            print('\n[+] Storing {:d}-th segment in TRS file'.format(n + 1))

            for p in range(self.n_traces_in_1rapid_block):
                # t_val = traces_val[p] if (self.trs_Header == self.samples) else traces_val[p, self.s_e]
                t_val = traces_val[p, self.s_e]
                # self.trs.write_trace(in_data[p], out_data[p], traces_val[p], True)
                self.trs.write_trace(in_data[p], out_data[p], t_val, True)
                counter += 1
                if counter >= self.Number_traces:
                    break

        ser.close()
        # Close scope
        ps.ps5000aStop(chandle)
        ps.ps5000aCloseUnit(chandle)
        self.trs.close()
        # print("[+] The number of traces:", i + 1)
        print('[+] Trs file contains {:d} traces'.format(counter))

        time_run(start_time)


# voltage_range="PS5000A_500MV", v_range=0.5,
# voltage_range="PS5000A_1V", v_range=1,
if __name__ == "__main__":
    # gadget_name = ["isw", "bbpp", "dom_indep", "hpc1_opt", "pini1", "pini2"]
    G_n = "bbpp"
    v_G = 1  # the implementation version of the gadget
    n_sh = 3
    # i = int(sys.argv[1])
    # k = int(sys.argv[2])
    # n_trace = int(sys.argv[3])
    i = 0
    k = 1
    n_trace = 1
    trs_file = f"{G_n}_{n_sh}_V{v_G}_sh{i}_sh{k}_{n_trace}K"

    # gadget_name = ["isw", "bbpp", "dom_indep", "hpc1_opt", "pini1", "pini2"]
    # ftest: the traces are for f-test
    acq = Acquisition_Gadget(G_n, trs_file, Mask_ORD=n_sh - 1, step=20000,
                             Number_traces=n_trace * 1000, points_per_cycle=125,
                             total_cycle=248, max_sam_in_pico_mem=127.5E6,
                             timebase=2, voltage_range="PS5000A_500MV", v_range=0.5,
                             start_cycle=0, end_cycle=0,
                             # start_cycle=10, end_cycle=12, (12-10 +1 cy) capturing cy:10, 11, 12
                             #####  random inputs or f-test
                             ftest=False, ftest_collapsed=False,
                             #####  t-test
                             ttest_f_vs_r=True, split_ttest=True, sh_i=i, sh_k=k,
                             #####  fix input template
                             tpl_attackt=False, fix_a=None, fix_b=None)
    acq.capture()
    print(trs_file)

