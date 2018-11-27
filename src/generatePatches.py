import sys
import os

def main(argv):
    buggy_file_lines = open(argv[0], "r").readlines()
    buggy_line_number = int(argv[1])
    buggy_line = buggy_file_lines[buggy_line_number-1]
    predictions = open(argv[2], "r").readlines()
    white_space_before_buggy_line = buggy_line[0:buggy_line.find(buggy_line.lstrip())]
    for i in range(len(predictions)):
        output_file = os.path.join(argv[3], str(i+1), os.path.basename(argv[0]))
        os.makedirs(os.path.dirname(output_file))
        output_file = open(output_file, "w")
        for j in range(len(buggy_file_lines)):
            if(j+1 == buggy_line_number):
                output_file.write(white_space_before_buggy_line+predictions[i])
            else:
                output_file.write(buggy_file_lines[j])
        output_file.close()


if __name__=="__main__":
    main(sys.argv[1:])
