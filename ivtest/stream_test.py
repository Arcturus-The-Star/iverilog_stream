import vvp_reg
import run_ivl
import test_lists
import kafka
import argparse
import sys

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
    argp.add_argument('--server', type=str, default='localhost:9092', help='The server for streaming, default "%(default)"')
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
