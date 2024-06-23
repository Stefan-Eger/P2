import socket


class UDP_Input:
    def __init__(self, ip="127.0.0.1", port=5005, buffer_size=1024):
        self.buffer_size = buffer_size
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  # UDP
        self.sock.bind((ip, port))
        self.sock.setblocking(False)
        self.lastReceived = 0.0

    def getValue(self):
        ret = 0.0
        try:
            data, addr = self.sock.recvfrom(self.buffer_size)
            ret = float(data.decode())
            self.lastReceived = ret
            print(f"received message: {data.decode()} from: {addr}")
        except BlockingIOError:
            ret = self.lastReceived
            #print("Socket has not received any data")

        return ret

    def close(self):
        self.sock.close()
