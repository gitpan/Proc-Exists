#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

//not sure which if any of these we need...
#include <sys/types.h>
#include <signal.h>
#include <errno.h>

MODULE = Proc::Exists		PACKAGE = Proc::Exists		

PROTOTYPES: DISABLE

int
_pexists(pid)
		int pid
	CODE:
		int ret = kill(pid, 0);
		//existent process w/ perms:  ret: 0
		//existent process w/o perms: ret: -1, err: EPERM
		//nonexistent process:        ret: -1, err: ESRCH
		RETVAL = (ret==0) ? 1 : (errno==EPERM);
	OUTPUT:
		RETVAL

