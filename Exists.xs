#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef WIN32
#include <windows.h>
#include <tlhelp32.h>
#include <malloc.h> //not there by default, needed for malloc (!)
#else
#include <sys/types.h>
#include <signal.h>
#include <errno.h>
#endif

////can't find a good ifdef for macs pre-macos x
//#if defined(macintosh) && !defined(MACOS_TRADITIONAL)
//#include "../Carbon.h"
//#include <Types.h>
//#include <Memory.h>
//#include <Processes.h>
//#endif
////with a good ifdef, compare GetProcessInformation from Mac::Processes

#include "ppport.h"

#define RETVAL_IS_UNSET -999

MODULE = Proc::Exists		PACKAGE = Proc::Exists		

PROTOTYPES: DISABLE

#returns 1 if the process exists, 0 if it doesn't
#on win32, it can also return <0 ( errors only happen on win32 ;-) )
int
_pexists(pid)
		int pid
	CODE:
#ifdef WIN32
		// this is much faster, but it has a weirdness on NTish systems - 
		// namely if these exists a pid 4, pid's 5, 6, and 7 will also 
		// return true. something in the windows guts is chopping off the 
		// bottom two bits? 
		// see: http://blogs.msdn.com/oldnewthing/archive/2008/02/28/7925962.aspx
		HANDLE hProcess;
		PROCESSENTRY32 pe32;
		DWORD err;
		int dowarn;

		dowarn=0; // XS, arg.
#ifdef win32_pids_mult4
		if(pid % 4) {
			dowarn = 1;
		}
#endif
		hProcess = OpenProcess( PROCESS_QUERY_INFORMATION, FALSE, pid );
		if(hProcess == NULL) { 
			RETVAL = 0;
		} else {
			RETVAL = 1;
			CloseHandle( hProcess );
		}
		// possible returns: -2 = err, no : -1 = err, yes : 0 = no : 1 = yes
		if(dowarn) { RETVAL -= 2; };
#else
		int ret = kill(pid, 0);
		//existent process w/ perms:  ret: 0
		//existent process w/o perms: ret: -1, err: EPERM
		//nonexistent process:        ret: -1, err: ESRCH
		if(ret == 0) {
			RETVAL = 1;
		} else if(ret == -1) {
			if(errno == EPERM) {
				RETVAL = 1;
			} else if(errno == ESRCH) {
				RETVAL = 0;
			} else {
				croak("unknown errno: %d", errno);
			}
		} else {
			croak("kill returned something other than 0 or -1: %d", ret);
		}
#endif
	OUTPUT:
		RETVAL



#a faster implementation for non-win32, non-wantarray case
int
_scalar_pexists(pids_ref, any, all)
		SV *pids_ref
		int any
		int all
	INIT:
		AV *pids;
		int npids;
		int i;
		int exists;
		int total=0;
		int pid;
		int ret;

		//NOTE: might have to stub this out on win32, where it's never called
		//make sure pids_ref is a ref pointing at an array with some elements
		//GRR no error when I typo avlen for av_len? wtf??
		if ((!SvROK(pids_ref)) || (SvTYPE(SvRV(pids_ref)) != SVt_PVAV) || 
			 ((npids = av_len((AV *)SvRV(pids_ref))) < 0)) {
			XSRETURN_UNDEF;
		}
		pids = (AV *)SvRV(pids_ref);
	CODE:
		RETVAL=RETVAL_IS_UNSET;
		for(i=0; i<=npids; i++) {
			pid = SvIV(*av_fetch(pids, i, 0));
			ret = kill(pid, 0);
			//existent process w/ perms:  ret: 0
			//existent process w/o perms: ret: -1, err: EPERM
			//nonexistent process:        ret: -1, err: ESRCH
			exists = (ret==0) ? 1 : (errno!=ESRCH);
			if((any && exists) || (all && !exists)) {
				RETVAL = exists; break;
			} else {
				total+=exists;
			}
		}
		if(RETVAL==RETVAL_IS_UNSET) { RETVAL = total; };
	OUTPUT:
		RETVAL

