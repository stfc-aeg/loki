#!/usr/bin/python
import json,argparse,os,io,subprocess,re

################################################################################
#
#Checks for meta-plnx-generated
	#Not Available
		#create a layer with yocto-layer create and prepare the json file here
		#can the bbappends be empty? or we should create it when needed
	#
#Apply the top level configs needed
#@use the env of the bbfile file for each component using recipetool
#
#################################################################################

class cmdline_arg_parse:
	def __init__(self,args):
		self.user_opts = self.cmd_option_parse(args)
	def cmd_option_parse(self,args):
		usr_opts = argparse.ArgumentParser()
		usr_opts.add_argument(
			"-i",
			"--in_json",
			dest="in_json",
			required=True,
			help=("'-i | --in_json' input json file")
		)
		usr_opts.add_argument(
			"-lp",
			"--layerpath",
			dest="lpath",
			required=True,
			help=("'-lp | --layerpath' destination layer path for append files")
		)
		usr_opts.add_argument(
			"-ln",
			"--layername",
			dest="lname",
			required=True,
			help=("'-ln | --layername' destination layer name")
		)
		usr_opts.add_argument(
			"-p",
			"--layerpriority",
			dest="lprio",
			type=int,
			default=6,
			help=("'-p | --layerpriority' layer priority to create")
		)
		usr_opts.add_argument(
			"-f",
			"--filepaths",
			dest="apndpaths",
			default="bbappendfilepaths.json",
			help=("'-f | --filepaths' bbappenfilepaths.json path")
		)
		usr_opts.add_argument(
			"-t",
			"--target",
			dest="ta",
			default='all',
			help=("'-t | --target' spcific target to generate")
		)
		usr_opts.add_argument(
			"-b",
			"--builddir",
			dest="builddir",
			required=True,
			help=("'-b | --builddir' build directory path")
		)
		return usr_opts.parse_args(args)

class gvar(object):
	name = "",
	assign = "",
	enable = "",
	val = ""
	def __init__(self, name, assign, enable, val):
		self.name = name
		self.assign = assign
		self.enable = enable
		self.val =val

def delete_a_line(fp,str):
	noskip = 1
	f = open(fp, 'r');
	lines = f.readlines()
	f.close()
	f = open(fp,'w+')
	for l in lines:
		str_m = re.escape(str)
		mat = re.match(r'^'+str_m+'\s',l)
		if not mat and noskip==1:
			f.write(l)
		else:
			# If having a line break, delete the next lines also
			if re.search(r'\\$',l):
				noskip = 0
			elif re.search(r'"$',l):
				noskip = 1
	f.close()

def FILESEXTRAPATHS_append_write(fp,data):
	delete_a_line(fp,'FILESEXTRAPATHS_append')
	tmp = "FILESEXTRAPATHS_append := \""+data+"\"\n"
	f = open(fp,'a')
	f.write(tmp)
	f.close()

def FILESEXTRAPATHS_prepend_write(fp,data):
	delete_a_line(fp,'FILESEXTRAPATHS_prepend')
	tmp = "FILESEXTRAPATHS_prepend := \""+data+"\"\n"
	f = open(fp,'a')
	f.write(tmp)
	f.close()

def KERNEL_IMAGETYPE_zynq_write(fp,data):
	delete_a_line(fp,'KERNEL_IMAGETYPE_zynq')
	tmp = "KERNEL_IMAGETYPE_zynq ?= \""+data+"\"\n"
	f = open(fp,'a')
	f.write(tmp)
	f.close()

def SRC_URI_append_write(fp,data):
	delete_a_line(fp,'SRC_URI_append')
	with open(fp,'a') as appendfile:
		tmp="SRC_URI_append =\"\\\n"
		files=data.split()
		for f in files:
			tmp += "    "+f.strip(" ")+"\\\n"
		tmp +="\"\n"
		appendfile.write(tmp)
		appendfile.close()

def inherit_write(fp,data):
	delete_a_line(fp,'inherit')
	with open(fp,'a') as appendfile:
		tmp = 'inherit '+data+"\n"
		appendfile.write(tmp)
		appendfile.close()

def export_write(fp,data):
	delete_a_line(fp,'export')
	data_list = data.split()
	with open(fp,'a') as appendfile:
		for d in data_list:
			tmp = 'export '+ d +"\n"
			appendfile.write(tmp)
		appendfile.close()

def assignment_override_prop_set(fp, gvobj):
	delete_a_line(fp, gvobj.name)
	if gvobj.enable == "1":
		with open(fp, 'a') as appenfile:
			tmp = gvobj.name+' '+gvobj.assign+' \"'+gvobj.val+'\"\n'
			appenfile.write(tmp)
			appenfile.close()

def prop_set(fp, data):
	#There are few special varaibles, which recipetool dosent handle nice
	#Just do raw write for those
	for key in list(data.keys()):
		if key in ['SRC_URI_append','FILESEXTRAPATHS_prepend','FILESEXTRAPATHS_append','inherit','export','KERNEL_IMAGETYPE_zynq']:
			func = key+"_write(\""+fp+"\",\""+data[key]+"\")"
			eval(func)
		else:
			if not data[key] == 'PLNX_NONE':
				if isinstance(data[key],list):
					obj = gvar(key,data[key][0],data[key][1],data[key][2])
					assignment_override_prop_set(fp,obj)
				else:
					obj = gvar(key, "=", "1", data[key])
					assignment_override_prop_set(fp,obj)
			else:
				delete_a_line(fp,key)

#IMPROVE-ME: Not a good way
#	Below def removes the existing fuction definiton of yocto styled fuction
#	and requres the fuction to be in below format
#	fuction_name(){
#	....
#	...
#	}
#
#	It tries to do this by reading the whole file and re-wirtting back
#	leaving the function.
def check_and_delete_previous_define(fp, func):
	noskip=1
	with open(fp,'r') as file:
		lines = file.readlines()
		file.close()
	with open(fp,'w+') as file:
		#seek to start and beging writeback
		func = re.escape(func)
		for l in lines:
			if not re.match('^'+func+'\s', l) and noskip:
				#write only if it dosent match and noskip is set
				file.write(l)
			else:
				#fuction def started, prepare to skip untill
				#we hit '}'
				noskip=0
				if re.match('^}',l):
					noskip=1
		file.truncate()
		file.close()

def deploy_append_set(fp, data):
	dstfolder = list(data['dst'].keys())[0]
	srcfolder = list(data['src'].keys())[0]
	str="""do_deploy_append(){
	install -d %s\n"""%(dstfolder)
	for s,d in zip(data['src'][srcfolder], data['dst'][dstfolder]):
		str += "	install -m 0644 %s/%s %s/%s\n"%(srcfolder, s,\
								dstfolder, d)
	str +="}\n"
	check_and_delete_previous_define(fp,'do_deploy_append')
	with open(fp, "a") as file:
		file.write(str)
		file.close()

def method_append(fp, data):
	for m in list(data.keys()):
		check_and_delete_previous_define(fp, m)
		k = list(data[m].keys())[0]
		if k != "JSONDELETE":
			str=m+" {\n\t"+'\n\t'.join(data[m][k])+"\n}\n"
			with io.open(fp, "a") as file:
				file.write(str)
				file.close()

def create_and_config_append(ta, data, fp):
	# set the properties(global)
	if 'globalvar' in data:
		prop_set(fp, data['globalvar'])
	# do_deploy_append
	if 'deploy' in data:
		deploy_append_set(fp, data['deploy'])
	# define methods
	if 'DefineMethod' in data:
		method_append(fp, data['DefineMethod'])
	# set_method_properties ?

def create_append(lp, ln ,t):
	cmd="recipetool newappend -w "+lp+"/meta-"+ln+" "+t
	print("> %s" % (str(cmd)))
	obj = subprocess.Popen( cmd.split(), stdout=subprocess.PIPE)
	obj.wait()
	if obj.returncode != 0:
		print("WARNING: No recipe %s found" % (str(t)))
		return None
	output = obj.communicate()[0]
	return output.splitlines()[-1]

#Insert an empty line, as bbappends cannot work with empty files
def insert_newline(fp):
	with open(fp,'w') as appendfile:
		appendfile.write("\n")
		appendfile.close()

def create_appends_for_targets(lp, ln, targets, pathfile):
	paths={}
	for t in targets:
		p = create_append(lp, ln, t)
		if p:
			paths[t] = p.decode('utf-8')
			insert_newline(paths[t])
	write_json(pathfile, paths)

def check_avail_of_all_targ(lp, ln, targets, pathfile):
	paths = read_json(pathfile)
	if not paths:
		print("INFO: bbappends.json not found, Creating new")
		create_appends_for_targets(lp, ln, targets, pathfile)
		paths = read_json(pathfile)
	else:
		# Check existance of appens, create if not available
		for t in targets:
			if t in paths.keys():
				print("INFO: %s append file exists" % (str(t)))
			else:
				p = create_append(lp, ln, t)
				if p:
					paths[t] = p
					insert_newline(paths[t])
		write_json(pathfile, paths)

def adding_layer(lp, ln, bdir):
	os.chdir(bdir)
	#adding meta-plnx-generated to bblayer.conf
	cmd="bitbake-layers add-layer "+lp+"/meta-"+ln
	subprocess.call(cmd.split(' '))

def check_for_layer(lp, ln, prio, ta, pathfile, bdir):
	#check and create if needed
	if not os.path.exists(lp):
		print("ERROR: Path Dosent exists: %s" % (str(lp)))
		exit(1)
	elif os.path.exists(lp+"/"+"meta-"+ln):
		print("INFO: Layer Already Exists, using the same")
		prevdir=os.getcwd()
		adding_layer(lp, ln, bdir)
		os.chdir(prevdir)
		if len(ta) != 0:
			check_avail_of_all_targ(lp, ln, ta, pathfile)
	else:
		# Add layer to bblayer if needed
		print("INFO: Layer Dosent exists, creating new")
		prevdir=os.getcwd()
		os.chdir(bdir)
		cmd="bitbake-layers create-layer "+str(lp)+"/meta-"+ln+" -p "+str(prio)
		print("%s" % cmd)
		if subprocess.call(cmd.split(' ')):
			print("ERROR: Could not create layer %s" % (str(ln)))
			exit(1)
		else:
			cmd="rm -rf meta-"+ln+"/recipes-example"
			os.system(cmd)
			os.chdir(prevdir)
			adding_layer(lp, ln, bdir)
			os.chdir(prevdir)
		create_appends_for_targets(lp, ln, ta, pathfile)

#
#target json file format:
# targets:
# 		ta1:
# 			prop:
# 				name:value pairs
# 			deploy:
# 				src:path filename
# 				dst:path
# 		ta2:
# 			...
# 			...
#
#json file for file names
# ta1: path
# ta2: path
# ...
# ...
#
#Note: ta1,ta2... should be target name(fsbl,pmufw)
def read_json(fp):
	try:
		with open(fp, 'r') as data_file:
			data = json.load(data_file)
			data_file.close()
			return data
	except IOError:
		return None

def write_json(fp, data):
	with open(fp, 'w') as data_file:
		json.dump(data, data_file)
	data_file.close()

def main(args):
	#read cmd line ops
	opt = cmdline_arg_parse(args)
	in_json = opt.user_opts.in_json
	lpath = opt.user_opts.lpath
	lname = opt.user_opts.lname
	lprio = opt.user_opts.lprio
	builddir = opt.user_opts.builddir
	apndpaths = opt.user_opts.apndpaths
	sys_conf = read_json(in_json)
	check_for_layer(lpath, lname, lprio, sys_conf.keys(), apndpaths, builddir)
	file_paths = read_json(apndpaths)
	if opt.user_opts.ta == 'all':
		targets = sys_conf.keys()
	else:
		targets = opt.user_opts.ta.split()
	for ta in targets:
		if not ta in file_paths.keys():
			print(" WARNING:Skipping %s append file creation" % (str(ta)))
		else:
			create_and_config_append(ta, sys_conf[ta], file_paths[ta])

if __name__ == "__main__":
	import sys
	main(sys.argv[1:])
