#!/usr/bin/python

import subprocess
import time
import itertools
import os

last_process_list = []
curr_process_list = []
new_processes = []
recent_processes = []

def print_processes(process_list, fields):
	print "%s\t%s\t%s" % ("UID", "PID", "CMD")
	for p in process_list:
		p = p.split(None, fields)
		print "%s\t%s\t%s" % (p[0], p[1], p[7][:80])

while True:
	ps = subprocess.Popen(['ps', '-ef'], stdout=subprocess.PIPE).communicate()[0]
	processes = ps.split('\n')

	fields = len(processes[0].split()) - 1

	for row in processes[1:]:
		p = row.split(None, fields)
		if len(p) == 8:
			if "ps -ef" in p:
				continue
			if "./sock_mon.py" in p[7]:
				continue
			curr_process_list.append(row)

	c = set(tuple(curr_process_list))
	l = set(tuple(last_process_list))

	if len(l) > 0:
		new_processes =  list(c - l)
		for process in new_processes:
			recent_processes.append(process)
			while len(recent_processes) > 20:
				recent_processes.pop(0)
		print "New processes since last check:"
		print_processes(new_processes, fields)
		print "\n20 Most recent processes started:"
		print_processes(recent_processes, fields)

	time.sleep(5)
	os.system('clear')
	last_process_list = curr_process_list
	curr_process_list = []
