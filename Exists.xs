#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef WIN32
#include <windows.h>
#include <tlhelp32.h>
#else
#include <sys/types.h>
#include <signal.h>
#include <errno.h>
#endif

#include "ppport.h"


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
		RETVAL = (ret==0) ? 1 : (errno==EPERM);
#endif
	OUTPUT:
		RETVAL

