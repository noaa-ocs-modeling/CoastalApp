#! /usr/bin/env python

import re, subprocess, sys, getopt, datetime, glob, os

bad_flag=False # set to true if errors occur

FLAG_FILE='success-flag-file.txt'
PRODUTIL_PROJECT_NAME='pyprodutil'

# Search string for the spot where we insert python files:
PYCODE='--DOXYGEN-IS-TOO-STUPID-TO-FIND-THE-FILES-ON-ITS-OWN--'

def main():
    app_mode, produtil_path, py_paths = scan_args(sys.argv[1:])

    if not len(py_paths):
        error('No python files specified.  Abort.')
    py_path_string=' '.join(py_paths)
    print('INPUT = '+py_path_string)

    # app_mode = True: we are running within an app checkout via "make app_doc"
    # app_mode = False: produtil checkout via "make produtil_doc"

    produtil_rev, produtil_loc = scan_produtil(produtil_path)

    # Determine project name (eg. "PRODUTIL")
    # and project number (eg. "branches/update-docs@93510")
    project_number=produtil_loc+'@'+produtil_rev
    project_name=PRODUTIL_PROJECT_NAME

    with open('Doxyfile','wt') as dw:
        with open('Doxyfile.IN','rt') as dr:
            for line in dr:
                dw.write(line.replace('--PROJECT_NUMBER--',project_number)
                         .replace('--PROJECT_NAME--',project_name)
                         .replace('--CWD--',os.path.realpath(os.getcwd()))
                         .replace(PYCODE,py_path_string))

    if not bad_flag:
        with open(FLAG_FILE,'wt') as successf:
            successf.write('Doxygen setup completed at %s\n'%(
                datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),))
    elif os.path.exists(FLAG_FILE):
        os.remove(FLAG_FILE)
        error('Errors detected.  Please fix them and rerun.\n')
        sys.exit(1)

# ----------------------------------------------------------------------

def error(what):
    global bad_flag
    bad_flag=True
    sys.stderr.write('prep_inputs.py error: '+what.strip()+'\n')

# ----------------------------------------------------------------------

def scan_args(arglist):
    try:
        opt,args=getopt.getopt(arglist,'a')
    except getopt.GetoptError as e:
        sys.stderr.write(str(e)+'\n')
        sys.exit(2)
    return ( ('-a' in opt), args[0], args[1:] )

# ----------------------------------------------------------------------

def check_output(cmd):
    # Workaround for lack of subprocess.check_output in 2.6
    p=subprocess.Popen(['sh','-c',cmd],executable='/bin/sh',stdout=subprocess.PIPE)
    (out,err)=p.communicate()
    if p.poll():
        raise Exception('%s: non-zero exit status'%(cmd,))

    print '%s => %s --- %s'%(repr(cmd),repr(out),repr(err))
    return out

# ----------------------------------------------------------------------

def scan_produtil(produtil_dir):
    if os.path.exists(os.path.join(produtil_dir,'.git')):
        return git_scan_produtil(produtil_dir)
    else:
        error('%s: could not determine if this is a git or subversion repo'%(produtil_dir,))
        return None, None
# ----------------------------------------------------------------------

def git_scan_produtil(produtil_dir):
    produtil_rev=None
    produtil_loc=None

    info=check_output('set -e ; cd '+produtil_dir+' ; git branch')
    for line in info.splitlines():
        r=re.match('^\s*\*\s*(\S+)',line.strip())
        produtil_loc = ( r and r.group(1) ) or None
        if produtil_loc: break
    
    info=check_output('set -e ; cd '+produtil_dir+' ; git rev-parse HEAD')
    for line in info.splitlines():
        produtil_rev = line.strip()[:10] or None
        if produtil_rev: break

    if not produtil_rev:
        error('%s: could not get git hash of HEAD\n'%(produtil_dir,))
        produtil_rev='unknown'

    if not produtil_loc:
        error('%s: could not get git branch\n'%(produtil_dir,))
        produtil_loc='produtil'

    return produtil_rev, produtil_loc

if __name__=='__main__':
    main()
