import threading
import vvp_reg
import run_ivl
import test_lists
import argparse
import sys
import confluent_kafka
import os

stop_event = threading.Event()

def print_header(cfg: dict, files: list):
    '''Print all the header information. '''
    # This returns 13 or similar
    ivl_version = run_ivl.get_ivl_version(cfg['suffix'])

    print("Running ", end='')
    if cfg['vlog95']:
        print("vlog95 ", end='')
    print("compiler/VVP streaming tests for Icarus Verilog ", end='')
    # pylint: disable-next=consider-using-f-string
    print("version: {ver}".format(ver=ivl_version), end='')
    if cfg['suffix']:
        # pylint: disable-next=consider-using-f-string
        print(", suffix: {suffix}".format(suffix=cfg['suffix']), end='')
    if cfg['strict']:
        if cfg['force-sv']:
            print(" (strict, force SV)", end='')
        else:
            print(" (strict)", end='')
    elif cfg['force-sv']:
        print(" (force SV)", end='')
    if cfg['with-valgrind']:
        print(" (valgrind)", end='')
    print("")
    # pylint: disable-next=consider-using-f-string
    print("Using list(s): {files}".format(files=', '.join(files)))
    print("-" * 76)

def stream_listen(options: dict, ready_event: threading.Event):
    if "KAFKA_BOOTSTRAP_SERVERS" in os.environ:
        server = os.environ['KAFKA_BOOTSTRAP_SERVERS']
    else:
        server = "localhost:9092"
    config = {
        'bootstrap.servers': f"{server}",
        'group.id': f"iv_kafka_{options['key']}",
        'broker.address.family': 'v4',
        "debug": "broker,protocol"
    }

    assigned_event = threading.Event()
    
    def on_assign(consumer, partitions):
        for p in partitions:
            lo, hi = consumer.get_watermark_offsets(p, timeout=5.0, cached=False)
            p.offset = hi
        consumer.assign(partitions)
        assigned_event.set()

    consumer = confluent_kafka.Consumer(config)
    consumer.subscribe(['iv_data_stream'], on_assign=on_assign)
    while not assigned_event.is_set():
        consumer.poll(0.1)
    consumer.poll(0.1)
    ready_event.set()
    msg_count = 0
    with open(os.path.join("log", f"{options['key']}-vvp-stream.log"), "wb") as f:
        while True:
            msg = consumer.poll(0.1)
            if msg is None:
                if stop_event.is_set():
                    break
            elif msg.error():
                print(f"ERROR: {msg.error()}")
            else:
                value = msg.value()
                f.write(value if value else b'')
                msg_count += 1
    consumer.close()

if __name__ == "__main__":
    argp = argparse.ArgumentParser(description='')
    argp.add_argument('--suffix', type=str, default='',
                      help='The Icarus executable suffix, default "%(default)s".')
    argp.add_argument('--strict', action='store_true',
                      help='Force strict standard compliance, default "%(default)s".')
    argp.add_argument('--with-valgrind', action='store_true',
                      help='Run the test suite with valgrind, default "%(default)s".')
    argp.add_argument('--force-sv', action='store_true',
                      help='Force tests to be run as SystemVerilog, default "%(default)s".')
    argp.add_argument('--vlog95', action='store_true',
                      help='Convert tests to Verilog 95 and then run, default "%(default)s".')
    argp.add_argument('files', nargs='*', type=str, default=['regress-stream.list'],
                      help='File(s) containing a list of the tests to run, default "%(default)s".')
    args = argp.parse_args()

    ivl_cfg = {
        'suffix'        : args.suffix,
        'strict'        : args.strict,
        'with-valgrind' : args.with_valgrind,
        'force-sv'      : args.force_sv,
        'vlog95'        : args.vlog95
    }
    print_header(ivl_cfg, args.files);
    tests_list = test_lists.read_lists(args.files)
    width = max(len(item[0]) for item in tests_list)

    error_count = 0
    for cur in tests_list:
        result = vvp_reg.process_test(cur, ivl_cfg)
        error_count += result[0]
        print("{name:>{width}}: {result}".format(name=cur[0], width=width, result=result[1]))
    print('=' * 76)
    print("Test results: Ran {ran}, Failed {failed}.".format(ran=len(tests_list), \
                                                             failed=error_count))
    sys.exit(error_count)
