from egcd_vanilla import egcd_tuple, egcd_ziplist, egcd_lambdalist, egcd_var
from egcd_external import egcd_matrix, egcd_copy, egcd_galois, egcd_libnum, egcd_gmpy2
import sys
from time import process_time
from concurrent.futures import ProcessPoolExecutor, as_completed



def test_impl(impl,runs):
    start = process_time()
    for i in range(runs):
        globals()["egcd_" + impl](a,b) # generate & call function id from keys in results dict
    return process_time()-start

def run_tests_for_impl(impl):
    round_results = {}
    with ProcessPoolExecutor(max_workers=parallel_rounds) as ex:
        futures2round = {ex.submit(test_impl, impl, runs): round_num for round_num in range(rounds)}
        for future in as_completed(futures2round):
            round_num = futures2round[future]
            round_results[round_num] = future.result()
    return round_results

results = {
    'matrix':{},
    'copy':{},
    'tuple':{},
    'ziplist':{},
    'lambdalist':{},
    'var':{},
    'galois':{},
    'libnum':{},
    'gmpy2':{},
}

## TEST SETUP
a,b = 2**63-1,2**62+3
expected = egcd_var(a,b)
assert all(expected == globals()['egcd_'+impl](a,b) for impl in results.keys()),'gcd must return same value for any implementation'

runs=int(2**24)
rounds=3
c=16
parallel_rounds=rounds
parallel_tests=4

assert parallel_rounds*parallel_tests <= c, 'cpu load sanity check failed'

print(f"egcd(a,b)       : {a},{b}\n"
    f"rounds          : {rounds:<10}\n"
    f"runs/round      : {runs:<10}\n" 
    f"num_methods     : {len(results):<10}\n"
    f"num_conc_tests  : {parallel_tests:<10}\n"
    f"num_conc_rounds : {rounds:<10}")
print()

with ProcessPoolExecutor(max_workers=parallel_tests) as ex:
    futures2impl = {ex.submit(run_tests_for_impl, impl): impl for impl in results.keys()}
    for future in as_completed(futures2impl):
        impl = futures2impl[future]
        impl_result = future.result()
        for round_num, exec_time in impl_result.items():
            results[impl][round_num] = exec_time

line=f"{'Method':<16}"
for i in range(rounds):
        line+=f"R{i:<10}"

print(line)
for impl,result in results.items():
    line=f"{impl:<10}"
    for i in range(rounds): 
        line += f"{result[i]:10.2f}s"
    print(line)
print()


""" Example Output
[11:16:42] >> time pytainer egcd_tests/egcd_timer.py
egcd(a,b)       : 9223372036854775807,4611686018427387907
rounds          : 3         
runs/round      : 8388608   
num_methods     : 9         
num_conc_tests  : 5         
num_conc_rounds : 3         

Method          R0         R1         R2         
matrix         91.23s     91.56s     91.92s
copy           47.79s     47.61s     47.95s
tuple          18.59s     18.16s     18.36s
ziplist        14.29s     14.15s     14.47s
lambdalist     17.78s     17.83s     17.67s
var             6.17s      6.05s      6.12s
galois          7.04s      6.85s      6.99s
libnum          7.47s      7.41s      7.67s
gmpy2           4.46s      4.40s      4.36s


real    1m33.478s
user    0m0.012s
sys     0m0.011s """
