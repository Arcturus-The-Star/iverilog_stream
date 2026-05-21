
#include "_pli_types.h"
# include "sys_priv.h"
# include "vcd_priv.h"
# include  "ivl_alloc.h"
#include "vpi_user.h"


# include <librdkafka/rdkafka.h>
# include  <stdio.h>
// # include  <stdlib.h>


static char* stream_server = NULL;
static rd_kafka_t* producer;
const char* topic = "iv_data_stream";



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
	// conf = NULL;

}

static void send_message(char* key, char* value) {
	int key_len = strlen(key);
	int val_len = strlen(value);
	rd_kafka_resp_err_t err;
	err = rd_kafka_producev(producer,
		RD_KAFKA_V_TOPIC(topic),
		RD_KAFKA_V_MSGFLAGS(RD_KAFKA_MSG_F_COPY),
		RD_KAFKA_V_KEY((void*)key, key_len),
		RD_KAFKA_V_VALUE((void*)value, val_len),
		RD_KAFKA_V_OPAQUE(NULL),
		RD_KAFKA_V_END
	);
	if (err) {
		vpi_printf("Failed to produce to topic %s: %s", topic, rd_kafka_err2str(err));
	}

	rd_kafka_poll(producer, 0);
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
	}
	rd_kafka_flush(producer, 10 * 1000);
	rd_kafka_destroy(producer);
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
