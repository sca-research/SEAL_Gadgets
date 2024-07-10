import numpy as np
# Read the measured traces from the TRS file
# Riscure TRS trace set file wrapper
class TRS_Reader(object):
    Number_of_Traces=0
    index=0#Trace index
    number_of_samples=0
    isint=True
    cryptolen=0
    traces = None
    plaintext= None
    ciphertext= None
    pos=0#Starting position of data section

    def __init__(self,filename):
        self.f = open(filename, 'rb+')
    def __del__(self):
        self.f.close()

    def read_header(self):
        self.index = 0
        # Read Header Info
        # Tag   Len Discription
        # 0x41  4   Number of traces
        while(True):
            tag = self.f.read(1)
            if tag==b'\x41':
                len=int.from_bytes(self.f.read(1), byteorder='little')
                self.Number_of_Traces=int.from_bytes(self.f.read(len), byteorder='little')
                continue
            if tag==b'\x42':
                len=int.from_bytes(self.f.read(1), byteorder='little')
                self.number_of_samples=int.from_bytes(self.f.read(len), byteorder='little')
                continue
            if tag==b'\x43':
                len=int.from_bytes(self.f.read(1), byteorder='little')
                if self.f.read(len)==b'\x02':
                    self.isint=True
                else:
                    self.isint=False
                continue
            if tag == b'\x44':
                len = int.from_bytes(self.f.read(1), byteorder='little')
                self.cryptolen=int.from_bytes(self.f.read(len), byteorder='little')
                continue
            if tag == b'\x5F':
                len = int.from_bytes(self.f.read(1), byteorder='little')
                self.pos = self.f.tell()
                break
            len = int.from_bytes(self.f.read(1), byteorder='little')
            self.f.read(len)

    def read_traces(self,N=0,startp=0,endp=0):
        if(N==0):
            N=self.Number_of_Traces
        if(endp==0):
            endp=self.number_of_samples
        self.traces=np.zeros((N,endp-startp),np.int16)
        self.plaintext=np.zeros((N,int(self.cryptolen/2)), np.dtype('B'))
        self.ciphertext=np.zeros((N,int(self.cryptolen/2)),np.dtype('B'))
        while self.index<N:
            if self.index % 10000==0:
                print("Reading traces "+str(self.index))
            p=self.f.read(int(self.cryptolen/2))
            c=self.f.read(int(self.cryptolen/2))
            for i in range(int(self.cryptolen/2)):
                self.plaintext[self.index][i]  = p[i]
                self.ciphertext[self.index][i] = c[i]
            for i in range(self.number_of_samples):
                if(self.isint):
                    if(i<endp and i>=startp):
                        self.traces[self.index][i-startp]=int.from_bytes(self.f.read(2), byteorder='little', signed=True)
                    else:
                        self.f.read(2)
                else:
                    if(i<endp and i>=startp):
                        self.traces[self.index][i-startp] = float.from_bytes(self.f.read(4))
                    else:
                        self.f.read(4)
            self.index=self.index+1
        self.f.seek(self.pos,0)
        self.index=0
    def read_onesample(self,no,N=0):
        if(N==0):
            N=self.Number_of_Traces
        OneSample=np.zeros(N,np.int16)
        while self.index<N:
            if self.index % 10000==0:
                print("Reading Sample "+str(no)+":\t"+str(self.index))
            p=self.f.read(int(self.cryptolen/2))
            c=self.f.read(int(self.cryptolen/2))
            for i in range(self.number_of_samples):
                if(self.isint):
                    if(i==no):
                        OneSample[self.index]=int.from_bytes(self.f.read(2), byteorder='little', signed=True)
                    else:
                        self.f.read(2)
                else:
                    if (i == no):
                        OneSample[self.index]  = float.from_bytes(self.f.read(4))
                    else:
                        self.f.read(4)
            self.index=self.index+1
        self.f.seek(self.pos,0)
        self.index=0
        return OneSample
    def read_plainciphertext(self,N=0):
        if(N==0):
            N=self.Number_of_Traces
        self.plaintext=np.zeros((N,int(self.cryptolen/2)), np.dtype('B'))
        self.ciphertext=np.zeros((N,int(self.cryptolen/2)),np.dtype('B'))
        while self.index<N:
            if self.index % 10000==0:
                print("Reading Plaintext/Ciphertext "+str(self.index))
            p=self.f.read(int(self.cryptolen/2))
            c=self.f.read(int(self.cryptolen/2))
            for i in range(int(self.cryptolen/2)):
                self.plaintext[self.index][i]  = p[i]
                self.ciphertext[self.index][i] = c[i]
            for i in range(self.number_of_samples):
                if(self.isint):
                    self.f.read(2)
                else:
                    self.f.read(4)
            self.index=self.index+1
        self.f.seek(self.pos,0)
        self.index=0
        return self.plaintext,self.ciphertext







if __name__ == "__main__":
    trs = TRS_Reader("../Neymans-Smooth-Test/Realistic Experiments/ShareSlicing_M0/FourShare_8plaintext_differentshares_attack_repeat1000/M0ShiftRight_4shares_8blocks_attack_500K_repeat1000.trs")
    trs.read_header()
    trs.read_traces()
    del (trs)