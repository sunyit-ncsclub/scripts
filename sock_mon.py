#!/usr/bin/python
import curses
import threading
import time
import termios
import fcntl
import struct
import sys
import signal
from scapy.all import *

packet_list = []
ingress_list = []
egress_list = []
good_ports = []
address = ''
screen = None
monitor_event = None
threshold = 0

class display_screen():
	width  = 0
	height = 0

	window = {  'main'    : None, 
				'ingress' : None, 
				'egress'  : None, 
			 }
	
	def __init__(self, height, width):
		self.width = width
		self.height = height
		self.address = address
		
		display_size_y = None
		display_size_x = None

		curses.initscr()
		curses.start_color()

		curses.init_pair(1, curses.COLOR_GREEN, curses.COLOR_BLACK)
		curses.init_pair(2, curses.COLOR_RED, curses.COLOR_BLACK)

		curses.noecho()
		curses.cbreak()
		curses.curs_set(0)

		self.window['main'] = curses.newwin(height, width / 2, 0, 0)
		self.window['ingress'] = curses.newwin(height / 2, width / 2, 0, width / 2)
		self.window['egress'] = curses.newwin(height / 2 , width / 2, height / 2, width / 2)

		for w in self.window:
			self.window[w].box(0, 1)

		self.set_title()

	def set_title(self):
		self.window['main'].addstr(0, 2, "Packets In/Out", curses.A_BOLD | curses.A_UNDERLINE)
		self.window['ingress'].addstr(0, 2, "Possible Malicious Ingress", curses.A_BOLD | curses.A_UNDERLINE)
		self.window['egress'].addstr(0, 2, "Possible Malicious Egress", curses.A_BOLD | curses.A_UNDERLINE)
		self.window['main'].refresh()
		self.window['ingress'].refresh()
		self.window['egress'].refresh()

	def exit(self):
			curses.endwin()

	def stop():
		self.exit()
		self.kill()

def get_term_size():
	data = struct.pack("HH", 0, 0)
	file_no = sys.stdout.fileno()
	res = fcntl.ioctl(file_no, termios.TIOCGWINSZ, data)
	return struct.unpack("HH", res)

def init_display(height, width):
	global screen
	global packet_list
	global ingress_list
	global egress_list
	global monitor_event
	global good_ports
	global threshold

	proto = 0
	src_ip = 1
	dst_ip = 2
	src_port = 3
	dst_port = 4

	screen = display_screen(height, width)
	(y,x) = screen.window['main'].getmaxyx()
	
	screen.display_size_y = y - 2
	screen.display_size_x = x - 2

	for j in xrange(screen.display_size_y):
		packet_list.append(['','','','',''])
	(iy,ix) = screen.window['ingress'].getmaxyx()
	iy = iy - 2
	ix = ix - 2
	for j in xrange(iy):
		ingress_list.append(['',0])


	(ey,ex) = screen.window['egress'].getmaxyx()
	ey = ey - 2
	ex = ex - 2
	for j in xrange(ey):
		egress_list.append(['',0])


	while not monitor_event.is_set():
		packets = packet_list[:screen.display_size_y]


		while len(packet_list) > screen.display_size_y:
			packet_list.pop(0)

		for j in xrange(screen.display_size_y):
			if screen.address in packets[j][src_ip]:
				m = "OUT: PROTO: %s  SRC PORT: %s\tDST_IP: %s" % (packets[j][proto],packets[j][src_port], packets[j][dst_ip])
				while len(m) < screen.display_size_x - 8:
					m = m + " "
				if packets[j][src_port] in good_ports:
					screen.window['main'].addstr(j+1, 1, m, curses.A_BOLD | curses.color_pair(1))
				else:
					screen.window['main'].addstr(j+1, 1, m, curses.A_BOLD | curses.color_pair(2))

			if screen.address in packets[j][dst_ip]:
				m = "IN:  PROTO: %s  DST PORT: %s\tDST_IP: %s" % (packets[j][proto],packets[j][dst_port], packets[j][src_ip])
				while len(m) < screen.display_size_x - 8:
					m = m + " "	
				if packets[j][dst_port] in good_ports:
					screen.window['main'].addstr(j+1, 1, m, curses.A_BOLD | curses.color_pair(1))
				else:
					screen.window['main'].addstr(j+1, 1, m, curses.A_BOLD | curses.color_pair(2))

		for j in xrange(iy):
			s = len(ingress_list)
			while s > iy:
				ingress_list.pop(0)
				s = len(ingress_list)
			m = "%d\t%s" % (ingress_list[j][1], ingress_list[j][0])
			while len(m) < ix - 5:
				m = m + " "
				if m[0] != "0":
					if ingress_list[j][1] >= threshold:
						screen.window['ingress'].addstr(j+1, 1, "%s" % m, curses.A_BOLD | curses.color_pair(2))
					else:
						screen.window['ingress'].addstr(j+1, 1, "%s" % m)

		for j in xrange(ey):
			s = len(egress_list)
			while s > ey:
				egress_list.pop(0)
				s = len(egress_list)
			m = "%d\t%s" % (ingress_list[j][1], ingress_list[j][0])
			while len(m) < ex - 5:
				m = m + " "
				if m[0] != "0":
					if egress_list[j][1] >= threshold:
						screen.window['egress'].addstr(j+1, 1, "%s" % m, curses.A_BOLD | curses.color_pair(2))
					else:
						screen.window['egress'].addstr(j+1, 1, "%s" %  m)

		screen.window['main'].refresh()
		screen.window['ingress'].refresh()
		screen.window['egress'].refresh()

	screen.exit()

def process_packet(packet):
	global monitor_event
	global packet_list
	global ingress_list
	global egress_list
	global good_ports

	if monitor_event.is_set(): sys.exit(0)

	src_addr = None
	dst_addr = None
	src_port = None
	dst_port = None
	proto = None

	if IP in packet:
		src_addr = packet[IP].src
		dst_addr = packet[IP].dst
	else: return
	if TCP in packet:
		proto = "TCP"
		src_port = packet[TCP].sport
		dst_port = packet[TCP].dport
	if UDP in packet:
		proto = "UDP"
		src_port = packet[UDP].sport
		dst_port = packet[UDP].dport

	if src_addr is None or dst_addr is None: return
	if src_port is None or dst_port is None: return
	if proto is None: return
	if address in src_addr or address in dst_addr: 

		packet_list.append([proto, src_addr, dst_addr, src_port, dst_port])

		found = 0

		if address in src_addr and int(src_port) not in good_ports:
			for source in egress_list:
				if dst_addr in source[0]:
					index = egress_list.index(source)
					egress_list[index][1] += 1
					found = 1
					break
			if found == 0:
				egress_list.append([dst_addr,1])

		found = 0
		if address in dst_addr and int(dst_port) not in good_ports:
			for source in ingress_list:
				if src_addr in source[0]:
					index = ingress_list.index(source)
					ingress_list[index][1] += 1
					found = 1
					break
			if found == 0:
				ingress_list.append([src_addr,1])

def init_monitor():
	sniff(filter="tcp or udp", count=0, prn=process_packet)

def signal_handler(signum, frame):
	global monitor_event
	monitor_event.set()

def main():
	global good_ports
	global address
	global monitor_event
	global threshold

	if len(sys.argv) < 4:
		print "usage: %s <IP to monitor> <GOOD PORTS> <packet count threshold>\n ex. %s 192.168.1.1 80,21,443,8000-8010 25" % (sys.argv[0], sys.argv[0])
		sys.exit(0)

	address = sys.argv[1]
	threshold = int(sys.argv[3])
	ports = sys.argv[2].split(',')
	for p in ports:
		if "-" in p:
			r1,r2 = p.split("-")
			r = range(int(r1),int(r2)+1)
			for port in r:
				good_ports.append(port)
		else:
			good_ports.append(int(p))

	monitor_event = threading.Event()
	signal.signal(signal.SIGINT, signal_handler)

	(height, width) = get_term_size()
	if height < 20 or width < 80:
		print "Error: Terminal size too small, needs to be at least 80x20!"
		print "Terminal size: %dx%d" % (width, height)
		sys.exit(-1)
	else:
		monitor = threading.Thread(target=init_monitor).start()
		init_display(height, width)

if __name__ == "__main__":
	main()
