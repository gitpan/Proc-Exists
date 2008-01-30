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
		HANDLE hProcessSnap;
		PROCESSENTRY32 pe32;
		DWORD err;

		SetLastError(0);
		RETVAL=0;
		hProcessSnap = CreateToolhelp32Snapshot( TH32CS_SNAPPROCESS, 0 );
		if( hProcessSnap == INVALID_HANDLE_VALUE ) {
			RETVAL = -1;
		} else {
			pe32.dwSize = sizeof( PROCESSENTRY32 );
			if( !Process32First( hProcessSnap, &pe32 ) ) {
				CloseHandle( hProcessSnap );
				RETVAL = -2;
			} else {
				do {
					if(pid ==  pe32.th32ProcessID) { RETVAL=1; break; };
				} while( Process32Next( hProcessSnap, &pe32 ) );
				CloseHandle( hProcessSnap );
			}
		}

		////this is much faster, but it has a bug - if these exists a pid 4,
		////pid's 5, 6, and 7 will also return true. something in the windows
		////guts is chopping off the bottom two bits?
		//HANDLE hProcess;
		//PROCESSENTRY32 pe32;
		//DWORD err;

		//hProcess = OpenProcess( PROCESS_QUERY_INFORMATION, FALSE, pid );
		//if(hProcess == NULL) { 
		//	RETVAL = 0;
		//} else {
		//	RETVAL = 1;
		//	CloseHandle( hProcess );
		//}
#else
		int ret = kill(pid, 0);
		//existent process w/ perms:  ret: 0
		//existent process w/o perms: ret: -1, err: EPERM
		//nonexistent process:        ret: -1, err: ESRCH
		RETVAL = (ret==0) ? 1 : (errno!=ESRCH);
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
#ifdef WIN32
		int *iv_pids;
		HANDLE hProcessSnap;
		PROCESSENTRY32 pe32;
		DWORD err;
#else
		int pid;
		int ret;
#endif
		//make sure pids_ref is a ref pointing at an array with some elements
//GRR no error when I typo avlen for av_len? wtf??
		if ((!SvROK(pids_ref)) || (SvTYPE(SvRV(pids_ref)) != SVt_PVAV) || 
			 ((npids = av_len((AV *)SvRV(pids_ref))) < 0)) {
			XSRETURN_UNDEF;
		}
		pids = (AV *)SvRV(pids_ref);
	CODE:
#ifdef WIN32

		npids++;
		//munge pids -> an int[] iv_pids
		iv_pids = malloc(npids * sizeof(int));
		if(iv_pids==NULL) { XSRETURN_UNDEF; };

		for(i=0; i<npids; i++) {
			iv_pids[i] = SvIV(*av_fetch(pids, i, 0));
		}

		//iterate over the proc list
		SetLastError(0);
		RETVAL=RETVAL_IS_UNSET;
		hProcessSnap = CreateToolhelp32Snapshot( TH32CS_SNAPPROCESS, 0 );
		if( hProcessSnap == INVALID_HANDLE_VALUE ) {
			RETVAL = -1;
		} else {
			pe32.dwSize = sizeof( PROCESSENTRY32 );
			if( !Process32First( hProcessSnap, &pe32 ) ) {
				CloseHandle( hProcessSnap );
				RETVAL = -2;
			} else {
				do {
					//mark off the current process from the handle (set -1)
					exists=0;
					for(i=0; i<npids; i++) {
						if(iv_pids[i] == pe32.th32ProcessID) {
							exists=1;
							break;
						}
					}

					//return immediately if any/all and appropriate value
					//note all && !exists makes no sense here since we are
					//iterating over the existing processes in the outer loop
					//TODO: THINK: probably a more efficient/elegant way here
					if(any && exists) {
						RETVAL = exists; break;
					} else {
						total+=exists;
					}
				} while( Process32Next( hProcessSnap, &pe32 ) );
				CloseHandle( hProcessSnap );
			}
		}
		free(iv_pids);
		if(RETVAL==RETVAL_IS_UNSET) {
			//handle the all case here, since we can't short-circuit
			//due to the nature of the win32 code
			if(all) {
				RETVAL = (npids == total) ? total : 0;
			} else {
				RETVAL = total;
			}
		};
#else
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
#endif
	OUTPUT:
		RETVAL

