
from enum import Enum


class KEY(Enum):
    ESCAPE          = 1
    ONE             = '1'
    TWO             = '2'
    THREE           = '3'
    FOUR            = '4'
    FIVE            = '5'
    SIX             = '6'
    SEVEN           = '7'
    EIGHT           = '8'
    NINE            = '9'
    ZERO            = '0'
    MINUS           = '-'
    EQUALS          = '='
    BAKCSPACE       = '\b'
    TAB             = '\t'

    A               = 'A'
    B               = 'B'
    C               = 'C'
    D               = 'D'
    E               = 'E'
    F               = 'F'
    G               = 'G'
    H               = 'H'
    I               = 'I'
    J               = 'J'
    K               = 'K'
    L               = 'L'
    M               = 'M'
    N               = 'N'
    O               = 'O'
    P               = 'P'
    Q               = 'Q'
    R               = 'R'
    S               = 'S'
    T               = 'T'
    U               = 'U'
    A               = 'A'
    V               = 'V'
    W               = 'W'
    X               = 'X'
    Y               = 'Y'
    Z               = 'Z'


class ScanCodeKey:
    def __init__(self, scancode, pressed, key):
        self.scancode = scancode
        self.pressed = pressed
        self.key = key

class ScanCodeSet:
    def __init__(self, name):
        self.name = name
        self.keys = []
    
    def add(self, scancode, pressed, key):
        self.keys.append(ScanCodeKey(scancode, pressed, key));
    
    def __repr__(self):
        buffer = []
        buffer.append


scanCodeSet1 = ScanCodeSet('scan_code_set1')
scanCodeSet1.add(0x01, True, KEY.ESCAPE)
scanCodeSet1.add(0x02, True, KEY.ONE)
scanCodeSet1.add(0x03, True, KEY.TWO)
scanCodeSet1.add(0x04, True, KEY.THREE)
scanCodeSet1.add(0x05, True, KEY.FOUR)
scanCodeSet1.add(0x06, True, KEY.FIVE)
scanCodeSet1.add(0x07, True, KEY.SIX)
scanCodeSet1.add(0x08, True, KEY.SEVEN)
scanCodeSet1.add(0x09, True, KEY.EIGHT)
scanCodeSet1.add(0x0A, True, KEY.NINE)
scanCodeSet1.add(0x0B, True, KEY.ZERO)

scanCodeSet1.add(0x0C, True, KEY.MINUS)
scanCodeSet1.add(0x0D, True, KEY.EQUALS)
scanCodeSet1.add(0x0E, True, KEY.BAKCSPACE)
scanCodeSet1.add(0x0F, True, KEY.TAB)

scanCodeSet1.add(0x10, True, KEY.Q)
scanCodeSet1.add(0x11, True, KEY.W)
scanCodeSet1.add(0x12, True, KEY.E)
scanCodeSet1.add(0x13, True, KEY.R)
scanCodeSet1.add(0x14, True, KEY.T)
scanCodeSet1.add(0x15, True, KEY.Y)
scanCodeSet1.add(0x16, True, KEY.U)
scanCodeSet1.add(0x17, True, KEY.I)
scanCodeSet1.add(0x18, True, KEY.O)
scanCodeSet1.add(0x19, True, KEY.P)


scanCodeSet1.add(0x1E, True, KEY.A)
scanCodeSet1.add(0x1F, True, KEY.S)
scanCodeSet1.add(0x20, True, KEY.D)
scanCodeSet1.add(0x21, True, KEY.F)
scanCodeSet1.add(0x22, True, KEY.G)
scanCodeSet1.add(0x23, True, KEY.H)
scanCodeSet1.add(0x24, True, KEY.J)
scanCodeSet1.add(0x25, True, KEY.L)

scanCodeSet1.add(0x2C, True, KEY.Z)
scanCodeSet1.add(0x2D, True, KEY.X)
scanCodeSet1.add(0x2E, True, KEY.C)
scanCodeSet1.add(0x2F, True, KEY.V)
scanCodeSet1.add(0x30, True, KEY.B)
scanCodeSet1.add(0x31, True, KEY.N)
scanCodeSet1.add(0x32, True, KEY.M)

print("")

