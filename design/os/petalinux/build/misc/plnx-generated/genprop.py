#!/usr/bin/python

import os,re,json,plnxgen,argparse

def read_sysconf(proot):
	lines = []
	with open(proot+'/project-spec/configs/config') as sysconf:
		lines = sysconf.readlines()
		sysconf.close()
	sysconf = createdict(lines)
	for key in list(sysconf.keys()):
		sysconf[key]=re.sub(r'^y$','1',sysconf[key])
		sysconf[key]=re.sub(r'^n$','0',sysconf[key])
	# DefineMethod conditional flags, Need to be true always
	sysconf['ALL'] = '1'
	sysconf['JSONMERGE'] = '1'
	return sysconf

def createdict(conf_lines):
	temp = {}
	for l in conf_lines:
		s = re.match(r'^CONFIG.*',l,re.M|re.I)
		if s:
			#FIXME: presenlty matches, splits and strips string
			l = s.group().split('=',1)
			temp[l[0]] = l[1].strip(' \"\'')
	return temp

def rpl(s, val , dict_sysconf):
	# get the total string by finding the start index
	# and splitting the rest of the string
	conf = re.split(' |,',val[s.start():])[0]
	if conf in dict_sysconf.keys():
		if val[s.start() - 1] == "!":
			tmp = '0' if dict_sysconf[conf] == '1' else '1'
			val = re.sub('!'+conf,tmp,val)
		else:
			val = re.sub(conf,dict_sysconf[conf],val)
	else:
		print("\tINFO: %s not define in system config" % (str(conf)))
		if val[s.start() - 1] == "!":
			tmp = '1'
			val = re.sub('!'+conf,tmp,val)
		else:
			val = re.sub(conf,'0',val)
	return val

def rpl_sysconf_configs(data_root,dict_sysconf):
	for ta in list(data_root.keys()):
		if not "globalvar" in data_root[ta]:
			continue
		for var in data_root[ta]["globalvar"].keys():
			if not 'globalvar' in data_root[ta]:
				continue
			val = data_root[ta]['globalvar'][var]
			val_is_list = 0
			if isinstance(val,list):
				val = data_root[ta]['globalvar'][var][-1]
				val_is_list = 1
			s =re.search(r'CONFIG_SUBSYSTEM',val)
			if s:
				val = rpl(s, val, dict_sysconf)
				if val_is_list:
					data_root[ta]['globalvar'][var][-1] = val
				else:
					data_root[ta]['globalvar'][var] = val
			if val_is_list:
				# globalvar enbale flag
				val =  data_root[ta]['globalvar'][var][1]
				s = re.search(r'CONFIG_SUBSYSTEM', val)
				en = rpl(s , val, dict_sysconf) if s else val
				data_root[ta]['globalvar'][var][1]=en
	return data_root

def expand_the_configs(data_root, dict_sysconf):
	data_root = rpl_sysconf_configs(data_root,dict_sysconf)
	return data_root

def read_json(fp):
	with open(fp, 'r') as data_file:
		data = json.load(data_file)
		data_file.close()
		return data

def write_json(data,fp):
	with open(fp, 'w') as data_file:
		json.dump(data, data_file)
		data_file.close()

def merge_json_category(c1, c2, ta, sysconf):
	tmp = {}
	if ta == "globalvar":
		for k in list(c1.keys()):
			if k in c2.keys():
				if isinstance(c1[k],list) or isinstance(c2[k],list):
					tmp[k] = c1[k][-1]+' '+c2.pop(k, None)[-1]
				else:
					tmp[k] = c1[k]+' '+c2.pop(k, None)
			else:
				tmp[k] = c1[k]
		tmp.update(c2)
	if ta == "deploy":
		tmp = c2
	if ta == "DefineMethod":
		for k in list(c1.keys()):
			conf = list(c1[k].keys())[0]
			if conf in sysconf.keys():
				if sysconf[conf] == "1":
					tmp[k] = {'JSONMERGE' : c1[k][conf]}
			if k in c2.keys():
				conf = list(c2[k].keys())[0]
				if conf in sysconf.keys():
					if sysconf[conf] == '1':
						tmp[k].append({'JSONMERGE' : c2[k].pop(conf, None)})
		for k in list(c2.keys()):
			conf = list(c2[k].keys())[0]
			if conf in sysconf.keys():
				if sysconf[conf] == "1":
					tmp[k] = {'JSONMERGE' : c2[k][conf]}
	return tmp

def merge_targets(c1, c2, sysconf):
	tmp = {}
	for ta in list(c1.keys()):
		if ta in c2.keys():
			tmp[ta] = merge_json_category(c1[ta], c2.pop(ta, None), ta, sysconf)
		else:
			tmp[ta] = c1[ta]
	tmp.update(c2)
	return tmp

def sysconf_is_true(data, sysconf, key):
	if key in list(data.keys()):
		flags = data[key].split()
		for f in flags:
			if f in sysconf.keys():
				return True if sysconf[f] == "1" else False
		return False
	#FIX-ME: Returning TRUE when JSON_FLAGS is not declared in metadata.json
	#assuming it as common target. Should be handled without assumptions.
	return True

def merge_json(cups, n, jug , sysconf):
	if n < 2:
		return cups[0]
	for ta in cups[0].keys():
		if ta in cups[1].keys():
			jug[ta] = merge_targets(cups[0][ta], cups[1].pop(ta, None), sysconf)
		else:
			jug[ta] = cups[0][ta]
	jug.update(cups[1])
	if n >= 2:
		cups.pop(0)
		cups.pop(0)
		cups.insert(0,jug)
		n -= 1
		jug = merge_json(cups, n ,jug, sysconf)
	return jug

def filter_definemethod(data, sysconf):
	c = 'DefineMethod'
	for ta in list(data.keys()):
		if c in data[ta].keys():
			for m in data[ta][c].keys():
				flag = list(data[ta][c][m].keys())[0]
				if flag == 'ALL' or flag == 'JSONMERGE':
					continue
				else:
					if flag in sysconf.keys():
						if sysconf[flag] == '1':
							continue
						else:
							data[ta][c][m]["JSONDELETE"] = data[ta][c][m].pop(flag)
					else:
						data[ta][c][m]["JSONDELETE"] = data[ta][c][m].pop(flag)
	return data

def filter_target(data, sysconf):
	for ta in list(data.keys()):
		if not sysconf_is_true(data[ta], sysconf, "JSON_FLAGS"):
			data.pop(ta, None)
	return data

def filter_data(data, sysconf):
	data = filter_target(data, sysconf)
	data = filter_definemethod(data, sysconf)
	return data

def merge_metadata(datafiles, sysconf):
	n = len(datafiles)
	tmp = {}
	data = []
	i = 0
	while i < n:
		d = read_json(datafiles[i])
		data.append(d)
		i += 1
	return merge_json(data, n , tmp, sysconf)

if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument("proot",
			help=(" Path for build directory")
			)
	parser.add_argument("target",
			help=(" Specific recipe to update the appends")
			)
	parser.add_argument("datafile", nargs='*',
			help=(" input json data file Required")
			)

	args = parser.parse_args()
	proot = args.proot
	plnxgen_path = proot+"/project-spec"
	build_dir = args.proot+"/build"
	dict_sysconf = read_sysconf(proot)
	data_root = merge_metadata(args.datafile, dict_sysconf)
	data_root = filter_data(data_root, dict_sysconf)
	cwd = os.getcwd()
#	write_json(dict_sysconf,'sysconf.json')
	data_root = expand_the_configs(data_root,dict_sysconf)
	write_json(data_root,cwd+"/plnxgen.json")
	ta = " -t "+args.target if args.target else ' -t all'
	send_args="-lp "+plnxgen_path+" -ln plnx-generated -i "+cwd+"/plnxgen.json"+ta+" -b "+build_dir
	plnxgen.main(send_args.split())
