import sys
import subprocess
from shutil import copyfile
import os

def main(argv):
    if(not os.path.exists(argv[0])):
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
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, shell=True)
    result = result.stdout.decode('utf-8')
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
        result = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, shell=True)
        result = result.stderr.decode('utf-8')
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
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, shell=True)
        result = result.stdout.decode('utf-8')
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
