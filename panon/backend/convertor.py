import numpy as np
import base64


class Numpy2Str:
    """
    Converts audio data to data URIs of 1-pixel-high BMP images,
    so that they can be used as textures by the shaders.
    """

    def __init__(self):
        # Reusable image buffers, indexed by the image width.
        self.img_data_map = {}

    def convert(self, data):
        body = self._body(data)
        head = self._head(len(body), data.shape[0], 1)
        return 'image/bmp;base64,' + base64.b64encode(head + body).decode()

    def _head(self, body_size, width, height):
        return b'BM' + (54 + body_size).to_bytes(4, 'little') +\
                b'\x00\x00\x00\x006\x00\x00\x00(\x00\x00\x00' + width.to_bytes(4, 'little') +\
                height.to_bytes(4, 'little') + b'\x01\x00\x18\x00\x00\x00\x00\x00' + body_size.to_bytes(4, 'little') +\
                b'\xc4\x0e\x00\x00\xc4\x0e\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'

    def _body(self, data):
        data_length, _ = data.shape
        if data_length not in self.img_data_map:
            self.img_data_map[data_length] = np.zeros((1, data_length, 3), dtype='uint8')
        img_data = self.img_data_map[data_length]
        img_data[0, :, :2] = data
        data = img_data[:, :, ::-1].tobytes()
        return data + b'\x00' * ((4 - len(data)) % 4)
