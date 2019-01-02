import sys
import subprocess
from shutil import copyfile
import os

MAX_COMPILE_TIME = 60
MAX_TEST_TIME = 300

def main(argv):
    global MAX_COMPILE_TIME,MAX_TEST_TIME
    if(not os.path.exists(argv[0])):
        sys.stderr.write("Found no patch in " + argv[0] + "\n")
        sys.stderr.flush()
        sys.exit(0)

    trigger_tests = []
    cmd = ""
    cmd += "cd " + argv[1] + ";"
    cmd += "defects4j export -p tests.trigger"
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, shell=True)
    result = result.stdout.decode('utf-8')
    result = result.split("\n")
    result = list(filter(None, result))
    for i in range(len(result)):
        trigger_tests.append(result[i].strip())

    sys.stdout.write(argv[1] + " has following triggering tests:\n")
    for test in trigger_tests:
        sys.stdout.write(test+"\n")
        sys.stdout.flush()

    failling_tests = []
    cmd = ""
    cmd += "cd " + argv[1] + ";"
    cmd += "defects4j test"
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, shell=True)
    try:
        output, error = process.communicate(timeout=MAX_TEST_TIME)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
        sys.stderr.write("Time limit exceeded when running the original bug version on " + argv[1] +"\n")
        sys.stderr.flush()
        sys.exit(1)
    result = output
    result = result.decode('utf-8')
    result = result.split("\n")
    result = list(filter(None, result))
    for i in range(len(result)):
        if(result[i].startswith("Failing tests:")):
            for j in range(i+1, len(result)):
                failling_tests.append(result[j][4:].strip())
            break

    sys.stdout.write(argv[1] + " has following failing tests:\n")
    for test in failling_tests:
        sys.stdout.write(test+"\n")
        sys.stdout.flush()

    for patch in os.listdir(argv[0]):
        sys.stdout.write("Testing " + os.path.join(argv[0],patch,os.path.basename(argv[2])) + "\n")
        sys.stdout.flush()
        copyfile(os.path.join(argv[0],patch,os.path.basename(argv[2])), argv[2])

        cmd = ""
        cmd += "cd " + argv[1] + ";"
        cmd += "defects4j compile"
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        try:
            output, error = process.communicate(timeout=MAX_COMPILE_TIME)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            continue
        result = error
        result = result.decode('utf-8')
        result = result.split("\n")
        result = list(filter(None, result))
        compile_error = False
        for line in result:
            if(not line.endswith("OK")):
                compile_error = True
        if(compile_error):
            continue

        cmd = ""
        cmd += "cd " + argv[1] + ";"
        cmd += "defects4j test"
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        try:
            output, error = process.communicate(timeout=MAX_TEST_TIME)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            continue
        result = output
        result = result.decode('utf-8')
        result = result.split("\n")
        result = list(filter(None, result))

        passing_triggerTests = True
        passing_oldTests = True
        for i in range(len(result)):
            if(result[i].startswith("Failing tests:")):
                for j in range(i+1, len(result)):
                    if(result[j][4:] in trigger_tests):
                        passing_triggerTests = False
                    if(result[j][4:] not in failling_tests):
                        passing_oldTests = False
                break

        if(passing_triggerTests and passing_oldTests):
            os.rename(os.path.join(argv[0],patch), os.path.join(argv[0],patch+"_passed"))
        else:
            os.rename(os.path.join(argv[0],patch), os.path.join(argv[0],patch+"_compiled"))




if __name__=="__main__":
    main(sys.argv[1:])
