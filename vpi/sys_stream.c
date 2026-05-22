
#include "_pli_types.h"
# include "sys_priv.h"
# include "vcd_priv.h"
# include  "ivl_alloc.h"
#include "vpi_user.h"


# include <librdkafka/rdkafka.h>
# include  <stdio.h>
# include <stdarg.h>


static char* stream_server = NULL;
static rd_kafka_t* producer;
static char* topic = "iv_data_stream";
static int finish_status = 0;
static int stream_status = 0;
static char* current_msg = NULL;
static PLI_UINT64 startstream_time;
static struct t_vpi_time zero_delay = { vpiSimTime, 0, 0, 0.0 };
static PLI_UINT64 stream_time;


static PLI_INT32 stream_finish_cb(p_cb_data cause) {
	if (finish_status != 0) return 0;
	
	finish_status = 1;
	
	// Stop the producer
	rd_kafka_flush(producer, 10 * 1000);
	rd_kafka_destroy(producer);
	
	return 0;
}

static PLI_INT32 startstream_cb(p_cb_data cause) {
	

	if (stream_status != 1) return 0;

	stream_status = 2;

	startstream_time = timerec_to_time64(cause->time);
	stream_time = startstream_time;

	return 0;
}

__inline__ static int install_startstream_cb(void) {
	struct t_cb_data cb;
	
	if (stream_status == 1) return 0;
	if (stream_status == 2) {
		vpi_printf("Stream warning: $startstream ignored, previously called at simtime %" PLI_UINT64_FMT "\n", startstream_time);
		return 1;
	}
	
	cb.time = &zero_delay;
	cb.reason = cbReadOnlySynch;
	cb.cb_rtn = startstream_cb;
	cb.user_data = 0x0;
	cb.obj = 0x0;
	vpi_register_cb(&cb);

	cb.reason = cbEndOfSimulation;
	cb.cb_rtn = stream_finish_cb;
	vpi_register_cb(&cb);

	stream_status = 1;
	return 0;
}

static void deliver_cb(rd_kafka_t *kafka_handle, const rd_kafka_message_t *rkmessage, void *opaque) {
	(void) kafka_handle;
	(void) opaque;
	if (rkmessage->err) {
		vpi_printf("Message delivery failed: %s\n", rd_kafka_err2str(rkmessage->err));
	}
}

static void set_config(vpiHandle callh, rd_kafka_conf_t *conf, char *key, char *value) {
	char errstr[512];
	rd_kafka_conf_res_t res;

	res = rd_kafka_conf_set(conf, key, value, errstr, sizeof(errstr));
	if (res != RD_KAFKA_CONF_OK) {
		vpi_printf("Stream Error: %s:%d: %s\n", vpi_get_str(vpiFile, callh), (int)vpi_get(vpiLineNo, callh), errstr);
		vpip_set_return_value(1);
		vpi_control(vpiFinish);
		return;
	}
}

static void send_message(char* fmt, ...) {
	va_list args;
	va_start(args, fmt);
	char* msg;
	vasprintf(&msg, fmt, args);
	va_end(args);
	char* key = "IV_STREAM_TEST";
	int key_len = strlen(key);
	int msg_len = strlen(msg);
	rd_kafka_resp_err_t err;
	err = rd_kafka_producev(producer,
		RD_KAFKA_V_TOPIC(topic),
		RD_KAFKA_V_MSGFLAGS(RD_KAFKA_MSG_F_COPY),
		RD_KAFKA_V_KEY((void*)key, key_len),
		RD_KAFKA_V_VALUE((void*)msg, msg_len),
		RD_KAFKA_V_OPAQUE(NULL),
		RD_KAFKA_V_END
	);
	if (err) {
		vpi_printf("Failed to produce to topic %s: %s", topic, rd_kafka_err2str(err));
	}

	rd_kafka_poll(producer, 0);
}

static void start_producer(vpiHandle callh) {
	char errstr[512];
	rd_kafka_conf_t *conf;

	conf = rd_kafka_conf_new();

	set_config(callh, conf, "bootstrap.servers", stream_server);
	set_config(callh, conf, "acks", "all");
	rd_kafka_conf_set_dr_msg_cb(conf, deliver_cb);

	producer = rd_kafka_new(RD_KAFKA_PRODUCER, conf, errstr, sizeof(errstr));
	if (!producer) {
		vpi_printf("Streaming Error: %s:%d: %s", vpi_get_str(vpiFile, callh), (int)vpi_get(vpiLineNo, callh), errstr);
		vpip_set_return_value(1);
		vpi_control(vpiFinish);
	}
	conf = NULL;

	vpi_printf("Stream info: started producer listening at %s\n", stream_server);
}



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
	vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    vpiHandle argv = vpi_iterate(vpiArgument, callh);
	if (!producer) {
		start_producer(callh);
		if (!producer) {
			if (argv) vpi_free_object(argv);
			return 0;
		}
	}
	
	if (install_startstream_cb()) {
		if (argv) vpi_free_object(argv);
		return 0;
	}

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
	tf_data.compiletf = sys_dumpvars_compiletf;
	tf_data.sizetf = 0;
	tf_data.user_data = "$startstream";
	res = vpi_register_systf(&tf_data);
	vpip_make_systf_system_defined(res);

}
