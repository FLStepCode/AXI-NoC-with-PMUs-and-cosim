import serial
import time
import random
import numpy as np
import matplotlib.pyplot as plt

with serial.Serial('/dev/ttyUSB0', 9600) as ser:


    if not ser.is_open:
        raise Exception('KAAAAL')
    else:
        print(ser.name)

    ser.write(int.to_bytes(1, 1, 'little'))
    ser.write(int.to_bytes(32, 1, 'little'))
    print(int.from_bytes(ser.read(), 'little'))
    
    
    fig, ax = plt.subplots(2, 3)

    for cores in range(0, 5):

        for len in [0, 1, 3, 7]:
            totals = [[0 for _ in range(19)] for _ in range(6)]

            for _ in range(4):

                for pow in range(0, 6):
                    if (pow == 5):
                        probs = [1.0, 0.0]
                    else:
                        probs = [1.0 - (1.0 / 2**pow), 1.0 / 2**pow]
                    print(probs)

                    ser.write(int.to_bytes(8, 1, 'little'))
                    ser.write(int.to_bytes(0, 1, 'little'))

                    ser.write(int.to_bytes(8, 1, 'little'))
                    ser.write(int.to_bytes(1, 1, 'little'))

                    active = np.arange(16)
                    np.random.shuffle(active)
                    active = active[:2**cores]
                    print(active)
                    for i in active:
                        for j in range(32):
                            ser.write(int.to_bytes(3, 1, 'little'))
                            ser.write(int.to_bytes(int(i), 1, 'little'))
                            ser.write(int.to_bytes(int(np.random.randint(1, 16)), 1, 'little'))
                            ser.write(int.to_bytes(len, 1, 'little'))
                            ser.write(int.to_bytes(int(np.random.choice([0, 1], p=probs)), 1, 'little'))
                            

                            ser.write(int.to_bytes(2, 1, 'little'))
                            ser.write(int.to_bytes(int(i), 1, 'little'))
                            ser.write(int.to_bytes(int(np.random.randint(1, 16)), 1, 'little'))
                            ser.write(int.to_bytes(len, 1, 'little'))
                            ser.write(int.to_bytes(int(np.random.choice([0, 1], p=probs)), 1, 'little'))

                            print("*", end='')
                        print()

                    ser.write(int.to_bytes(5, 1, 'little'))

                    idle = 0
                    while idle != 0xFFFF:
                        ser.write(int.to_bytes(4, 1, 'little'))

                        idle = int.from_bytes(ser.read(), 'little')
                        idle += (int.from_bytes(ser.read(), 'little') << 8)
                        print(hex(idle))

                    for i in active:
                        for j in [15, 17]:
                            ser.write(int.to_bytes(6, 1, 'little'))
                            ser.write(int.to_bytes(int(i), 1, 'little'))
                            ser.write(int.to_bytes(j, 1, 'little'))

                            thing = 0
                            for k in range(4):
                                thing = thing + (int.from_bytes(ser.read(), 'little') << (8 * k))
                            totals[pow][j] += thing
                            print(str(thing).rjust(7), end=' ')
                        print()
            
            print("Plotting...")
            y = [0 for _ in range(6)]
            x = [2**pow for pow in range(0, 6)]
            for pow in range(0, 6):
                y[pow] = totals[pow][15] / totals[pow][17]
            
            ax[cores//3][cores%3].set_xscale('log', base=2)
            ax[cores//3][cores%3].plot(x, y, marker='o', label=f'Len={len}')
            print("Plotted...")
        
        ax[cores//3][cores%3].legend()
    plt.show()