import importlib.util


def canImportAubio():
    return importlib.util.find_spec('aubio') is not None


class BeatsDetector:
    def __init__(self, channels, samplerate, cfg_fps):

        hop_s = samplerate // cfg_fps * channels    # hop size
        win_s = hop_s * 2    # fft size

        import aubio
        # create aubio tempo detection
        self.a_tempo = aubio.tempo("default", win_s, hop_s, samplerate)
        self.hop_s = hop_s

    def isBeat(self, samples):
        return float(self.a_tempo(samples.reshape((self.hop_s, )))[0])
