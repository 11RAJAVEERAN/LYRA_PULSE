# MicroPython SSD1306 OLED driver
# https://github.com/micropython/micropython/blob/master/drivers/display/ssd1306.py

from micropython import const

# register definitions
_SET_CONTRAST = const(0x81)
_SET_ENTIRE_ON = const(0xA4)
_SET_NORM_INV = const(0xA6)
_SET_DISP = const(0xAE)
_SET_MEM_ADDR = const(0x20)
_SET_COL_ADDR = const(0x21)
_SET_PAGE_ADDR = const(0x22)
_SET_START_LINE = const(0x40)
_SET_SEG_REMAP = const(0xA0)
_SET_MUX_RATIO = const(0xA8)
_SET_COM_OUTDIR = const(0xC0)
_SET_DISP_OFFSET = const(0xD3)
_SET_COM_PIN_CFG = const(0xDA)
_SET_DISP_CLK_DIV = const(0xD5)
_SET_PRECHARGE = const(0xD9)
_SET_VCOM_DESEL = const(0xDB)
_SET_CHARGE_PUMP = const(0x8D)


class SSD1306:
    def __init__(self, width, height, external_vcc=False):
        self.width = width
        self.height = height
        self.external_vcc = external_vcc
        self.pages = self.height // 8
        self.buffer = bytearray(self.pages * self.width)

    def init_display(self):
        for cmd in (
            _SET_DISP | 0x00,
            _SET_MEM_ADDR,
            0x00,
            _SET_START_LINE | 0x00,
            _SET_SEG_REMAP | 0x01,
            _SET_MUX_RATIO,
            self.height - 1,
            _SET_COM_OUTDIR | 0x08,
            _SET_DISP_OFFSET,
            0x00,
            _SET_COM_PIN_CFG,
            0x02 if self.width > 2 * self.height else 0x12,
            _SET_CONTRAST,
            0xFF,
            _SET_PRECHARGE,
            0x22 if self.external_vcc else 0xF1,
            _SET_VCOM_DESEL,
            0x30,
            _SET_DISP | 0x01,
            _SET_COL_ADDR,
            0,
            self.width - 1,
            _SET_PAGE_ADDR,
            0,
            self.pages - 1,
        ):
            self.write_cmd(cmd)

    def reset(self):
        self.init_display()

    def fill(self, col):
        self.buffer = bytearray(self.pages * self.width)
        if col:
            self.buffer[:] = b"\xFF" * len(self.buffer)

    def show(self):
        pass

    def text(self, text, x, y):
        pass

    def write_cmd(self, cmd):
        raise NotImplementedError


class SSD1306_I2C(SSD1306):
    def __init__(self, width, height, i2c, addr=0x3C, external_vcc=False):
        super().__init__(width, height, external_vcc)
        self.i2c = i2c
        self.addr = addr
        self.temp = bytearray(2)
        self.init_display()

    def write_cmd(self, cmd):
        self.temp[0] = 0x80
        self.temp[1] = cmd
        self.i2c.writeto(self.addr, self.temp)

    def write_data(self, buf):
        self.temp[0] = 0x40
        self.temp[1:] = b""  # placeholder to keep bytearray structure
        self.i2c.writeto(self.addr, b"\x40" + buf)

    def show(self):
        self.write_cmd(_SET_COL_ADDR)
        self.write_cmd(0)
        self.write_cmd(self.width - 1)
        self.write_cmd(_SET_PAGE_ADDR)
        self.write_cmd(0)
        self.write_cmd(self.pages - 1)
        self.i2c.writeto(self.addr, b"\x40" + self.buffer)

    def text(self, text, x, y):
        # 5x8 font by default; this is intentionally compact and compatible.
        try:
            from lib.font5x8 import FONT
        except ImportError:  # pragma: no cover - local CPython compatibility
            from font5x8 import FONT

        cursor_x = x
        for char in text:
            glyph = FONT.get(ord(char), FONT[32])
            for glyph_col, byte in enumerate(glyph):
                for bit_index in range(8):
                    if byte & (1 << (7 - bit_index)):
                        pixel_x = cursor_x + glyph_col
                        pixel_y = y + bit_index
                        if 0 <= pixel_x < self.width and 0 <= pixel_y < self.height:
                            page = pixel_y // 8
                            offset = pixel_y % 8
                            index = page * self.width + pixel_x
                            self.buffer[index] |= 1 << offset
            cursor_x += 6
