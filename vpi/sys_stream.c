
#include "_pli_types.h"
#include "sv_vpi_user.h"
# include "sys_priv.h"
# include "vcd_priv.h"
# include  "ivl_alloc.h"
#include "vpi_user.h"


# include <librdkafka/rdkafka.h>
# include  <stdio.h>
# include <stdarg.h>
# include <time.h>
# include <assert.h>
# include <string.h>

DECLARE_VCD_INFO(stream_info, const char*);
static struct stream_info *stream_const_list = NULL;
static struct stream_info *stream_list = NULL;
static struct stream_info *stream_dmp_list = NULL;

static char* stream_server = NULL;
static rd_kafka_t* producer;
static char* topic = "iv_data_stream";
static int finish_status = 0;
static int stream_status = 0;
static PLI_UINT64 startstream_time;
static struct t_vpi_time zero_delay = { vpiSimTime, 0, 0, 0.0 };
static PLI_UINT64 stream_cur_time;
static int dump_no_date = 0;

static const char*units_names[] = {
      "s",
      "ms",
      "us",
      "ns",
      "ps",
      "fs"
};

/*
 * managed qsorted list of scope names/variables for duplicates bsearching
 */

struct vcd_names_list_s stream_tab = { 0, 0, 0, 0 };
struct vcd_names_list_s stream_var = { 0, 0, 0, 0 };

static char strid[8] = "!";

static void gen_new_strid(void)
{
      static unsigned value = 0;
      unsigned v = ++value;
      unsigned int i;

      for (i=0; i < sizeof(strid)-1; i++) {
           strid[i] = (char)((v%94)+33); /* for range 33..126 */
           v /= 94;
           if(!v) {
                 strid[i+1] = '\0';
                 return;
           }
      }
	// This should never happen since 94**7 is a lot if identifiers!
      assert(0);
}
static void send_message(char* msg) {
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

static char* truncate_bitvec(char *s) {
	char r;

    r=*s;
    if(r=='1') return s;
    else s += 1;

    for(;;s++) {
	  char l;
	  l=r; r=*s;
	  if(!r) return (s-1);
	  if(l!=r) return(((l=='0')&&(r=='1'))?s:s-1);
    }
}

typedef struct {
    char  *data;
    size_t len;
    size_t cap;
} StrBuf;

static StrBuf message;

int strbuf_init(StrBuf *buf, size_t initial_cap) {
    buf->data = malloc(initial_cap);
    if (!buf->data) return -1;
    buf->data[0] = '\0';
    buf->len = 0;
    buf->cap = initial_cap;
    return 0;
}

static int strbuf_grow(StrBuf *buf, size_t needed) {
    if (needed <= buf->cap) return 0;
    size_t new_cap = buf->cap * 2;
    if (new_cap < needed) new_cap = needed;
    char *tmp = realloc(buf->data, new_cap);
    if (!tmp) return -1;
    buf->data = tmp;
    buf->cap  = new_cap;
    return 0;
}

int strbuf_append_line(StrBuf *buf, const char *line) {
    size_t line_len = strlen(line);
    size_t needed   = buf->len + line_len + 2;
    if (strbuf_grow(buf, needed) < 0) return -1;
    memcpy(buf->data + buf->len, line, line_len);
    buf->len += line_len;
    buf->data[buf->len++] = '\n';
    buf->data[buf->len]   = '\0';
    return 0;
}

void strbuf_free(StrBuf *buf) {
    free(buf->data);
    buf->data = NULL;
    buf->len  = 0;
    buf->cap  = 0;
}

int strbuf_append_linef(StrBuf *buf, const char *fmt, ...) {
    va_list args;

    va_list args_copy;
    va_start(args, fmt);
    va_copy(args_copy, args);
    int needed_chars = vsnprintf(NULL, 0, fmt, args);
    va_end(args);

    if (needed_chars < 0) {
        va_end(args_copy);
        return -1;
    }

    size_t needed = buf->len + (size_t)needed_chars + 1;
    if (strbuf_grow(buf, needed) < 0) {
        va_end(args_copy);
        return -1;
    }

    vsnprintf(buf->data + buf->len, (size_t)needed_chars + 1, fmt, args_copy);
    va_end(args_copy);

    buf->len += (size_t)needed_chars;
    buf->data[buf->len]   = '\0';
    return 0;
}

static PLI_INT32 stream_finish_cb(p_cb_data cause) {
	struct stream_info *cur, *next;

	if (finish_status != 0) return 0;
	
	finish_status = 1;

	startstream_time = timerec_to_time64(cause->time);

	if (startstream_time != stream_cur_time) {
		strbuf_append_linef(&message, "#%" PLI_UINT64_FMT "\n", startstream_time);
		send_message(message.data);
	}

	// Stop the producer
	rd_kafka_flush(producer, 10 * 1000);
	rd_kafka_destroy(producer);

	// Free any dangling message
	strbuf_free(&message);

	for (cur = stream_list; cur; cur = next) {
		next = cur->next;
		free((char*)cur->ident);
		free(cur);
	}
	stream_list = 0;
	for (cur = stream_const_list; cur; cur = next) {
		next = cur->next;
		free((char*)cur->ident);
		free(cur);
	}
	stream_const_list = 0;
	vcd_names_delete(&stream_tab);
	vcd_names_delete(&stream_var);
	nexus_ident_delete();
	free(stream_server);
	
	return 0;
}

static void show_this_item(struct stream_info *info) {
	s_vpi_value value;
	PLI_INT32 type = vpi_get(vpiType, info->item);
	
	if (type == vpiRealVar) {
		value.format = vpiRealVal;
		vpi_get_value(info->item, &value);
		strbuf_append_linef(&message, "r%.16g %s\n", value.value.real, info->ident);
	} else if (type == vpiNamedEvent) {
		strbuf_append_linef(&message, "1%s\n", info->ident);
	} else if (type == vpiParameter && vpi_get(vpiConstType, info->item) == vpiRealConst) {
		value.format = vpiRealVal;
		vpi_get_value(info->item, &value);
		strbuf_append_linef(&message, "r%.16g %s\n", value.value.real, info->ident);
	} else if (vpi_get(vpiSize, info->item) == 1) {
		value.format = vpiBinStrVal;
		vpi_get_value(info->item, &value);
		strbuf_append_linef(&message, "%s%s\n", value.value.str, info->ident);
	} else {
		value.format = vpiBinStrVal;
		vpi_get_value(info->item, &value);
		strbuf_append_linef(&message, "b%s %s\n", truncate_bitvec(value.value.str), info->ident);
	}

}

static PLI_INT32 startstream_cb(p_cb_data cause) {
	if (stream_status != 1) return 0;

	stream_status = 2;

	startstream_time = timerec_to_time64(cause->time);
	stream_cur_time = startstream_time;
	
	strbuf_append_linef(&message, "$enddefinitions $end\n");

	strbuf_append_linef(&message, "$comment Show the parameter values. $end\n");
	strbuf_append_linef(&message, "$dumpall\n");
	ITERATE_VCD_INFO(stream_const_list, stream_info, next, show_this_item);
	strbuf_append_linef(&message, "$end\n");
	strbuf_append_linef(&message, "#%" PLI_UINT64_FMT "\n", startstream_time);
	strbuf_append_linef(&message, "$dumpvars\n");
	ITERATE_VCD_INFO(stream_list, stream_info, next, show_this_item);
	strbuf_append_linef(&message, "$end\n");
	send_message(message.data);
	strbuf_free(&message);

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



static void start_producer(vpiHandle callh) {
	char errstr[512];
	rd_kafka_conf_t *conf;

	conf = rd_kafka_conf_new();

	set_config(callh, conf, "bootstrap.servers", stream_server);
	set_config(callh, conf, "acks", "all");
	rd_kafka_conf_set_dr_msg_cb(conf, deliver_cb);

	producer = rd_kafka_new(RD_KAFKA_PRODUCER, conf, errstr, sizeof(errstr));
	conf = NULL;

	if (!producer) {
		vpi_printf("Streaming Error: %s:%d: %s", vpi_get_str(vpiFile, callh), (int)vpi_get(vpiLineNo, callh), errstr);
		vpip_set_return_value(1);
		vpi_control(vpiFinish);
	} else {
		int prec = vpi_get(vpiTimePrecision, 0);
		unsigned scale = 1;
		unsigned udx = 0;
		time_t walltime;

		time(&walltime);
		assert(prec >= -15);
		while (prec < 0) {
			udx += 1;
			prec += 3;
		}
		while (prec > 0) {
			scale *= 10;
			prec -= 1;
		}
		strbuf_init(&message, 50);
		if (!dump_no_date) strbuf_append_linef(&message, "$date\n\t%s$end\n", asctime(localtime(&walltime)));
		strbuf_append_linef(&message, "$version\n\tIcarus Verilog\n$end\n$timescale\n\t%u%s\n$end\n", scale, units_names[udx]);
		send_message(message.data);
		strbuf_free(&message);
	}

	vpi_printf("Stream info: started producer producing to %s\n", stream_server);
}

static PLI_INT32 variable_cb_2(p_cb_data cause) {

	struct stream_info *info = stream_dmp_list;
	PLI_UINT32 now = timerec_to_time64(cause->time);
	
	if (now != stream_cur_time) {
		strbuf_append_linef(&message, "#%" PLI_UINT64_FMT "\n", now);
		stream_cur_time = now;
	}

	do {
		show_this_item(info);
		info->scheduled = 0;
	} while ((info = info->dmp_next) != 0);

	stream_dmp_list = 0;
	send_message(message.data);
	strbuf_free(&message);
	
	return 0;
}

static PLI_INT32 variable_cb_1(p_cb_data cause) {
	struct t_cb_data cb;
	struct stream_info *info = (struct stream_info*) cause->user_data;
	
	if (info->scheduled) return 0;
	if (stream_status != 2) return 0;
	
	if (!stream_dmp_list) {
		cb = *cause;
		cb.time = &zero_delay;
		cb.reason = cbReadOnlySynch;
		cb.cb_rtn = variable_cb_2;
		vpi_register_cb(&cb);
	}
	info->scheduled = 1;
	info->dmp_next = stream_dmp_list;
	stream_dmp_list = info;
	return 0;
}

static void scan_item(unsigned depth, vpiHandle item, int skip) {

	static int dumpable_types[] = {
		/* Value */
		vpiNamedEvent,
		vpiNet,
		vpiParameter,
		vpiReg,
		vpiVariables,
		/* Scope */
		vpiFunction,
		vpiGenScope,
		vpiModule,
		vpiNamedBegin,
		vpiNamedFork,
		vpiTask,
		-1
    };

	struct t_cb_data cb;
	struct stream_info* info;

	const char *type;
	const char *name;
	const char *fullname;
	const char *prefix;
	const char *ident;
	int64_t nexus_id;
	unsigned size;
	PLI_INT32 item_type;

	item_type = vpi_get(vpiType, item);
	switch (item_type) {
	  case vpiNamedEvent: type = "event"; break;
	  case vpiIntVar:
	  case vpiIntegerVar: type = "integer"; break;
	    /* VCD doesn't support real parameters, so lie. */
	  case vpiParameter:
	    switch (vpi_get(vpiConstType, item)) {
		case vpiRealConst: type = "real"; break;
		default: type = "parameter"; break;
	    }
	    break;
	    /* Icarus converts realtime to real. */
	  case vpiRealVar:    type = "real"; break;
	  case vpiMemoryWord:
	  case vpiBitVar:
	  case vpiByteVar:
	  case vpiShortIntVar:
	  case vpiLongIntVar:
	  case vpiReg:        type = "reg"; break;
	    /* Icarus converts a time to a plain register. */
	  case vpiTimeVar:    type = "time"; break;
	  case vpiNet:
	    switch (vpi_get(vpiNetType, item)) {
		case vpiWand:    type = "wand"; break;
		case vpiWor:     type = "wor"; break;
		case vpiTri:     type = "tri"; break;
		case vpiTri0:    type = "tri0"; break;
		case vpiTri1:    type = "tri1"; break;
		case vpiTriReg:  type = "trireg"; break;
		case vpiTriAnd:  type = "triand"; break;
		case vpiTriOr:   type = "trior"; break;
		case vpiSupply1: type = "supply1"; break;
		case vpiSupply0: type = "supply0"; break;
		default:         type = "wire"; break;
	    }
	    break;

	  case vpiNamedBegin: type = "begin"; break;
	  case vpiGenScope:   type = "begin"; break;
	  case vpiNamedFork:  type = "fork"; break;
	  case vpiFunction:   type = "function"; break;
	  case vpiModule:     type = "module"; break;
	  case vpiPackage:    type = "package"; break;
	  case vpiTask:       type = "task"; break;

	  default:
	    vpi_printf("Streaming warning: $startstream: Unsupported argument "
	               "type (%s).\n", vpi_get_str(vpiType, item));
	    return;
      }
	/* Do some special processing/checking on array words. Dumping array words is an Icarus extension. */
	if (item_type == vpiMemoryWord) {
		if (vpi_get(vpiConstantSelect, item) == 0) {
			vpiHandle array = vpi_handle(vpiParent, item);
			PLI_INT32 idx = vpi_get(vpiIndex, item);
			item = vpi_handle_by_index(array, idx);
		}
		if (vpi_get(vpiType, item) == vpiMemoryWord && vpi_handle_by_name(vpi_get_str(vpiFullName, item), 0)) {
			vpi_printf("Stream warning: array word %s will conflict with an escaped identifier", vpi_get_str(vpiFullName, item));
		}
	}

	fullname = vpi_get_str(vpiFullName, item);
	switch (item_type) {
	case vpiNamedEvent:
	case vpiIntegerVar:
	case vpiBitVar:
	case vpiByteVar:
	case vpiShortIntVar:
	case vpiIntVar:
	case vpiLongIntVar:
	case vpiRealVar:
	case vpiMemoryWord:
	case vpiReg:
	case vpiTimeVar:
	case vpiNet:
		if (skip || vpi_get(vpiAutomatic, item)) return;
		if (vcd_names_search(&stream_var, fullname)) return;
		
		name = vpi_get_str(vpiName, item);
		prefix = is_escaped_id(name) ? "\\" : "";
		nexus_id = vpi_get64(_vpiNexusId, item);
		
		ident = 0;
		if (nexus_id) ident = find_nexus_ident(nexus_id);
		if (!ident) {
			ident = strdup(strid);
			gen_new_strid();

			if (nexus_id) set_nexus_ident(nexus_id, ident);

			info = malloc(sizeof(*info));
			
			info->time.type = vpiSimTime;
			info->item = item;
			info->ident = ident;
			info->scheduled = 0;

			cb.time = &info->time;
			cb.user_data = (char*)info;
			cb.value = NULL;
			cb.obj = item;
			cb.reason = cbValueChange;
			cb.cb_rtn = variable_cb_1;
			
			info->dmp_next = 0;
			info->next = stream_list;
			stream_list = info;
			
			info->cb = vpi_register_cb(&cb);
		}

		
		if (item_type == vpiNamedEvent) {
			size = 1;
		} else {
			size = vpi_get(vpiSize, item);
		}
		strbuf_append_linef(&message, "$var %s %u %s %s%s", type, size, ident, prefix, name);
		if (size > 1 || vpi_get(vpiLeftRange, item) != 0) {
			strbuf_append_linef(&message, " [%i:%i]",
					(int)vpi_get(vpiLeftRange, item),
					(int)vpi_get(vpiRightRange, item));
		}
		strbuf_append_linef(&message, " $end\n");
		break;
	
	case vpiParameter:
		if (skip) return;
		
		size = vpi_get(vpiSize, item);
		name = vpi_get_str(vpiName, item);
		prefix = is_escaped_id(name) ? "\\" : "";
		ident = strdup(strid);
		gen_new_strid();
		
		info = malloc(sizeof(*info));
		info->item = item;
		info->ident = ident;
		info->scheduled = 0;
		info->dmp_next = 0;
		info->next = stream_const_list;
		stream_const_list = info;
		info->cb = NULL;

		strbuf_append_linef(&message, "$var %s %u %s %s%s $end\n", type, size, ident, prefix, name);
		break;
	case vpiModule:
	case vpiGenScope:
	case vpiFunction:
	case vpiTask:
	case vpiNamedBegin:
	case vpiNamedFork:
		if (depth > 0) {
			int i;
			int nskip = (vcd_names_search(&stream_tab, fullname) != 0);
			
			if (nskip) {
				vpi_printf("Stream warning: ignoring signals in previously scanned scope %s. \n", fullname);
			} else {
				vcd_names_add(&stream_tab, fullname);
			}
			name = vpi_get_str(vpiName, item);
			strbuf_append_linef(&message, "$scope %s %s $end\n", type, name);
			
			for (i=0; dumpable_types[i]>0; i++) {
				vpiHandle hand;
				vpiHandle argv = vpi_iterate(dumpable_types[i], item);
				while (argv && (hand = vpi_scan(argv))) {
					scan_item(depth-1, hand, nskip);
				}
			}
			strbuf_append_linef(&message, "$upscope $end\n");
		}
		break;
	case vpiPackage:
		if (vcd_instance_contains_dumpable_items(dumpable_types, item)) {
			vpi_printf("Stream warning: $startstream: Package (%s) is not dumpable with stream.\n", vpi_get_str(vpiFullName, item));
		}
		break;

	}

	return;
}

static int draw_scope(vpiHandle item, vpiHandle callh) {
	int depth;
	const char *name;
	const char *type;
	
	vpiHandle scope = vpi_handle(vpiScope, item);
	if (!scope) return 0;
	
	depth = 1 + draw_scope(scope, callh);
	name = vpi_get_str(vpiName, scope);
	
	switch (vpi_get(vpiType, scope)) {
		case vpiNamedBegin:  type = "begin";      break;
		case vpiGenScope:    type = "begin";      break;
		case vpiTask:        type = "task";       break;
		case vpiFunction:    type = "function";   break;
		case vpiNamedFork:   type = "fork";       break;
		case vpiModule:      type = "module";     break;
		default:
			type = "invalid";
			vpi_printf("Stream error: %s:%d: $enablestream: Unsupported scope type (%d)\n",
					vpi_get_str(vpiFile, callh),
					(int)vpi_get(vpiLineNo, callh),
					(int)vpi_get(vpiType, item));
			assert(0);
	}

	strbuf_append_linef(&message, "$scope %s %s $end\n", type, name);

	return depth;
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
    vpiHandle item;
    s_vpi_value value;
    unsigned depth = 0;

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

	/* Init the message */
	strbuf_init(&message, 100);

    /* Get the depth if it exists. */
    if (argv) {
	    value.format = vpiIntVal;
	    vpi_get_value(vpi_scan(argv), &value);
		depth = value.value.integer;
    }
    if (!depth) depth = 10000;

	/* This dumps all the instances in the design if none are given. */
    if (!argv || !(item = vpi_scan(argv))) {
	    argv = vpi_iterate(vpiInstance, 0x0);
	    assert(argv);  /* There must be at least one top level instance. */
	    item = vpi_scan(argv);
    }

	for ( ; item; item = vpi_scan(argv)) {
		char *scname;
		const char *fullname;
		int add_var = 0;
		int dep;
		PLI_INT32 item_type = vpi_get(vpiType, item);
		
		switch (item_type) {
			case vpiIntegerVar:
			case vpiBitVar:
			case vpiByteVar:
			case vpiShortIntVar:
			case vpiIntVar:
			case vpiLongIntVar:
			case vpiMemoryWord:
			case vpiNamedEvent:
			case vpiNet:
			case vpiParameter:
			case vpiRealVar:
			case vpiReg:
			case vpiTimeVar:
				scname = strdup(vpi_get_str(vpiFullName, vpi_handle(vpiScope, item)));
				fullname = vpi_get_str(vpiFullName, item);
				if (((item_type != vpiMemoryWord) && vcd_names_search(&stream_tab, scname)) || vcd_names_search(&stream_var, fullname)) {
					vpi_printf("Stream warning: skipping signal %s, it was previously included.\n", fullname);
					free(scname);
					continue;
				} else {
					add_var = 1;
				}
				free(scname);
				
		}

		dep = draw_scope(item, callh);

		scan_item(depth, item, 0);
		vcd_names_sort(&stream_tab);
		
		while (dep--) strbuf_append_linef(&message, "$upscope $end\n");
		
		if (add_var) {
			vcd_names_add(&stream_var, vpi_get_str(vpiFullName, item));
			vcd_names_sort(&stream_var);
		}


	}
	// Prevents duplication detection from interfering with dumping
	nexus_ident_delete();

	return 0;
}

static PLI_INT32 sys_streamflush_calltf(ICARUS_VPI_CONST PLI_BYTE8 *name) {
	(void)name;
	if (producer) {
		rd_kafka_flush(producer, 1000 * 100);
	}
	return 0;
}


void sys_stream_register(void) {
	s_vpi_systf_data tf_data;
    vpiHandle res;
	int idx;
	struct t_vpi_vlog_info vlog_info;
	
	vpi_get_vlog_info(&vlog_info);
	for (idx = 0; idx < vlog_info.argc; idx += 1) {
		if (strcmp(vlog_info.argv[idx],"-no-date") == 0) {
        	dump_no_date = 1;
        }
	}

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

	tf_data.type = vpiSysTask;
	tf_data.tfname = "$streamflush";
	tf_data.calltf = sys_streamflush_calltf;
	tf_data.compiletf = sys_no_arg_compiletf;
	tf_data.sizetf = 0;
	tf_data.user_data = "$streamflush";
	res = vpi_register_systf(&tf_data);
	vpip_make_systf_system_defined(res);

}
