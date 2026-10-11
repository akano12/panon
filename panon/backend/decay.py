import numpy as np


class Decay:
    def __init__(self):
        self.global_decay = 0.01

        self.min_sample = 10
        self.max_sample = self.min_sample

    def process(self, fft):
        if fft is None:
            return None

        exp = 2
        retain = (1 - self.global_decay)**exp
        global_decay = 1 - retain
        global_max = self.max_sample**(1 / exp)

        vol = self.min_sample + np.mean(fft**exp)
        self.max_sample = self.max_sample * retain + vol * global_decay

        return fft / global_max
