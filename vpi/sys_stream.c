
#include "_pli_types.h"
# include "sys_priv.h"
# include "vcd_priv.h"
# include  "ivl_alloc.h"
#include "vpi_user.h"

static char* stream_server = NULL;

# include  <stdio.h>
// # include  <stdlib.h>
# include "sys_stream.h"

static PLI_INT32 sys_enablestream_calltf(ICARUS_VPI_CONST PLI_BYTE8*name) {
	(void) name;
	s_vpi_value val;
	vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    vpiHandle argv = vpi_iterate(vpiArgument, callh);
	val.format = vpiStringVal;
	vpiHandle handle = vpi_scan(argv);
	vpi_get_value(handle, &val);
	stream_server = val.value.str;
	return 0;
}

static PLI_INT32 sys_startstream_calltf(ICARUS_VPI_CONST PLI_BYTE8*name) {
	(void) name;
	printf("Called $startstream\n");
	return 0;
}


void sys_stream_register(void) {
	s_vpi_systf_data tf_data;
    vpiHandle res;

	tf_data.type = vpiSysTask;
	tf_data.tfname = "$enablestream";
	tf_data.calltf = sys_enablestream_calltf;
	tf_data.compiletf = sys_one_string_arg_compiletf;
	tf_data.sizetf = 0;
	tf_data.user_data = "$enablestream";
	res = vpi_register_systf(&tf_data);
	vpip_make_systf_system_defined(res);

	tf_data.type = vpiSysTask;
	tf_data.tfname = "$startstream";
	tf_data.calltf = sys_startstream_calltf;
	tf_data.compiletf = sys_no_arg_compiletf;
	tf_data.sizetf = 0;
	tf_data.user_data = "$startstream";
	res = vpi_register_systf(&tf_data);
	vpip_make_systf_system_defined(res);

}
