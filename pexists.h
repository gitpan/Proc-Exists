//it seems a waste to have this file just for one static function...
//is there some way to pull it into the XS?
static int __pexists(int pid) {
#ifdef WIN32
	// this is much faster than iterating over a process snapshot,
	// and more closely mirrors the POSIX code, but it has a weirdness
	// on NTish systems - namely if these exists a pid 4, pid's 5, 6,
	// and 7 will also return true. something in the windows guts is
	// chopping off the bottom two bits, see:
	// http://blogs.msdn.com/oldnewthing/archive/2008/02/28/7925962.aspx
	HANDLE hProcess;
	//TODO: CLEANUP: are pe32 and err needed anymore?
	PROCESSENTRY32 pe32;
	DWORD err;

	if (pid < 0) { croak("got non-integer pid"); }

#ifdef win32_pids_mult4
	if(pid % 4) {
		warn("windows ignored the bottom 2 bits of the pid %d, beware!", pid);
	};
#endif

	hProcess = OpenProcess( PROCESS_QUERY_INFORMATION, FALSE, pid );
	if(hProcess == NULL) { 
		return 0;
	} else {
		CloseHandle( hProcess );
		return 1;
	}
#else
	int ret;

	if (pid < 0) { croak("got non-integer pid"); }

	ret = kill(pid, 0);
	//existent process w/ perms:  ret: 0
	//existent process w/o perms: ret: -1, err: EPERM
	//nonexistent process:        ret: -1, err: ESRCH
	if(ret == 0) {
		return 1;
	} else if(ret == -1) {
		if(errno == EPERM) {
			return 1;
		} else if(errno == ESRCH) {
			return 0;
		} else {
			croak("unknown errno: %d", errno);
		}
	} else {
		croak("kill returned something other than 0 or -1: %d", ret);
	}
#endif
	croak("internal error: we should never get here");

}

