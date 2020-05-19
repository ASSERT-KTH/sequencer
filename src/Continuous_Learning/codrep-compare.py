
import io;
import sys

def main(argv):

    if(len(argv) < 3 or argv[0] == "-h" or argv[0] == "--help"):
        print("Usage: python codrep-compare.py /path/to/predictions /path/to/test_data /path/to/output")
        exit(0)

    n = 50
    path_to_predictions = argv[0]
    path_to_test_data = argv[1]
    path_to_output = argv[2]

    target_file = io.open(path_to_test_data, "r", encoding="utf-8")
    patches_file = io.open(path_to_predictions, "r", encoding="utf-8")

    target_lines = target_file.readlines()

    matches_found_no_repeat = 0
    matches_found_total = 0

    for target_line in target_lines:
        found = 0
        for i in range(n):
            patch_line = patches_file.readline()
            
            if(patch_line == target_line):
                matches_found_total += 1
                if(found == 0):
                    matches_found_no_repeat += 1
                found = 1

    print("found fixes for " + str(matches_found_no_repeat) + " bugs")
    print("found " + str(matches_found_total) + " total fixes")

    print("analized " + str(len(target_lines)) + " total changes")

    with open(path_to_output, "w") as result_file:
        result_file.write(str(matches_found_total) + "," + str(matches_found_no_repeat) + "," + str(len(target_lines)))


if __name__=="__main__":
    main(sys.argv[1:])
