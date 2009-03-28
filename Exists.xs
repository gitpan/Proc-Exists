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
#include "pexists.h"

#define RETVAL_IS_UNSET -999

MODULE = Proc::Exists		PACKAGE = Proc::Exists		

PROTOTYPES: DISABLE

### static int _pexists() from pexists.h behaves as follows:
# returns 1 if the process exists, 0 if it doesn't
# on win32/NT, can also return -2 or -1 if the pid was not a multiple of 4
# in which case the pure perl code emits a warning and adds 2 to get
# the expected 0 or 1 value, as appropriate

# XS implementation for scalar context
int
_scalar_pexists(pids_ref, any, all)
		SV *pids_ref
		int any
		int all
	INIT:
		AV *pids;
		SV *pid_sv;
		int npids;
		int i;
		int exists;
		int total=0;
		int pid;
		char *pidstr;
		STRLEN len;
//warn("inXS: _scalar_pexists");

		//make sure pids_ref is a ref pointing at an array with some elements
		//GRR, no error when I typo avlen for av_len? grumble XS grumble...
		if ((!SvROK(pids_ref)) || (SvTYPE(SvRV(pids_ref)) != SVt_PVAV) || 
			 ((npids = av_len((AV *)SvRV(pids_ref))) < 0)) {
			XSRETURN_UNDEF;
		}
		pids = (AV *)SvRV(pids_ref);
	CODE:
		RETVAL=RETVAL_IS_UNSET;
		for(i=0; i<=npids; i++) {
			pid_sv = *av_fetch(pids, i, 0);

			//verify pid is an integer... or else "abc" becomes (int)(0)
			//note: if the scalar isn't in int-ready format, make it so and
			//do error checking to rule out strings like "abc", floats like
			//1.32, and negative integers
			if(!SvIOKp(pid_sv)) {
				pidstr = SvPV(pid_sv, len);
				if(__is_int(pidstr, len)) {
					if(sscanf(pidstr, "%d", &pid) == 0) {
						croak("got non-number pid: '%s'", pidstr);
					} else {
						//warn("converted %s to int: %d outside of perlapi", pidstr, pid);
					}
				} else {
					croak("got non-integer pid: '%s'", pidstr);
				}
			} else {
				pid = SvIV(pid_sv);
			}
			if (pid < 0) {
				croak("got negative pid: '%s'", SvPV_nolen(pid_sv));
			}

			exists = __pexists(pid);

			if( any && exists) {
				RETVAL = pid; break;
			} else if( all && !exists ) {
				RETVAL = 0; break;
			} else {
				total+=exists;
			}
		}
		if(RETVAL==RETVAL_IS_UNSET) { RETVAL = total; };
	OUTPUT:
		RETVAL

### TODO: _list_pexists and _scalar_pexists are still VERY similar...
### must be some way to unify them further?
# XS implementation for list context
void
_list_pexists(pids_ref)
		SV *pids_ref
	INIT:
		AV *pids;
		SV *pid_sv;
		int npids;
		int i;
		int exists;
		int pid;
		char *pidstr;
//warn("inXS: _list_pexists");

		//make sure pids_ref is a ref pointing at an array with some elements
		//GRR, no error when I typo avlen for av_len? grumble XS grumble...
		if ((!SvROK(pids_ref)) || (SvTYPE(SvRV(pids_ref)) != SVt_PVAV) || 
			 ((npids = av_len((AV *)SvRV(pids_ref))) < 0)) {
			XSRETURN_UNDEF;
		}
		pids = (AV *)SvRV(pids_ref);
	PPCODE:
		for(i=0; i<=npids; i++) {
			pid_sv = *av_fetch(pids, i, 0);

			//verify pid is an integer... or else "abc" becomes (int)(0)
			//note: if the scalar isn't in int-ready format, make it so and
			//do error checking to rule out strings like "abc", floats like
			//1.32, and negative integers
			if(!SvIOKp(pid_sv)) {
				pidstr = SvPV_nolen(pid_sv);
				if(__is_int(pidstr, SvLEN(pid_sv))) {
					if(sscanf(pidstr, "%d", &pid) == 0) {
						croak("got non-number pid: '%s'", pidstr);
					} else {
						//warn("converted %s to int: %d outside of perlapi", pidstr, pid);
					}
				} else {
					croak("got non-integer pid: '%s'", pidstr);
				}
			} else {
				pid = SvIV(pid_sv);
			}
			if (pid < 0) {
				croak("got negative pid: '%s'", SvPV_nolen(pid_sv));
			}

			exists = __pexists(pid);

			if(exists) {
				mXPUSHi(pid);
				//XPUSHs(sv_2mortal(newSViv(pid))); //needed for old perls?
			};
		}


