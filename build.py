# coding: latin-1
import subprocess
import os
import glob
from colorama import *

init()

#################################################################################
def buildProject(project):
    print(Fore.YELLOW + "Building " + project)
    p = project.replace('.dproj', '.cfg')
    if os.path.isfile(p):
      if os.path.isfile(p + '.unused'):
        os.remove(p + '.unused')
      os.rename(p, p + '.unused')
    # print os.system("msbuild /t:Build /p:Config=Debug \"" + project + "\"")
    return subprocess.call("rsvars.bat & msbuild /t:Build /p:Config=Debug /p:Platform=Win32 \"" + project + "\"", shell=True) == 0


def summaryTable(builds):
    print(ansi.clear_screen())
    copyright()
    print(Fore.WHITE + "PROJECT NAME".ljust(80) + "STATUS".ljust(10))
    print(Fore.YELLOW + "=" * 90)
    good = bad = 0
    for item in builds:
        if item['status'] == 'ok':
            #WConio.textcolor(WConio.LIGHTGREEN)
            good += 1
        else:
            #WConio.textcolor(WConio.RED)
            bad += 1
        print(Fore.BLUE + item['project'].ljust(80) + (Fore.WHITE if item['status'] == 'ok' else Fore.RED) + item['status'].ljust(4))
				
    #WConio.textcolor(WConio.WHITE)
    print(Fore.YELLOW + "=" * 90)
    #WConio.textcolor(WConio.GREEN)
    print(Fore.WHITE + "GOOD :".rjust(80) + str(good).rjust(10, '.'))
    #WConio.textcolor(WConio.RED)
    print(Fore.RED + "BAD  :".rjust(80) + str(bad).rjust(10, '.'))


#################################################################################

def main(projects):
	copyright()
	builds = []
	for project in projects:
			filename = '\\'.join(project.split('\\')[-3:])
			list = {'project': filename}
			if buildProject(project):
					list["status"] = "ok"
			else:
					list["status"] = "ko"
			builds.append(list)
	summaryTable(builds)

# Store current attribute settings
#old_setting = WConio.gettextinfo()[4] & 0x00FF

def copyright():
  print(Style.BRIGHT + Fore.WHITE + "----------------------------------------------------------------------------------------")	
  print(Fore.RED +   "                   ** Delphi Redis client Building System **")
  print(Fore.WHITE + "          Delphi Redis Client is CopyRight (2014-2017) of Daniele Teti")
  print(Fore.WHITE + "  Commercial support provided by bit Time Professionals - www.bittimeprofessionals.it")
  print(Fore.RESET + "----------------------------------------------------------------------------------------\n")

## MAIN ##
projects = glob.glob("*\**\*.dproj")
projects = projects + glob.glob("**\*.dproj")
main(projects)
print(Style.RESET_ALL)