import javalang
import sys
import os

def main(argv):
    abstract_file_lines = open(argv[0], "r").readlines()
    buggy_line = -1
    for i in range(len(abstract_file_lines)):
        if(abstract_file_lines[i].strip().startswith("// ONLY FOR TOKENIZATION, BUGGY LINE BELOW")):
            buggy_line = i+2
            break

    if(buggy_line == -1):
        sys.stderr.write("Could not find buggy line ('// ONLY FOR TOKENIZATION, BUGGY LINE BELOW' missing)\n")
        sys.exit(1)

    tokens_string = ""
    try:
        tokens = list(javalang.tokenizer.tokenize(''.join(abstract_file_lines)))
        buggy_line_start = True
        buggy_line_end = True
        for token in tokens:
            if(token.position[0] == buggy_line and buggy_line_start):
                tokens_string = tokens_string + "<START_BUG>" + " "
                tokens_string = tokens_string + token.value + " "
                buggy_line_start = False
            elif(token.position[0] != buggy_line and not buggy_line_start and buggy_line_end):
                tokens_string = tokens_string + "<END_BUG>" + " "
                tokens_string = tokens_string + token.value + " "
                buggy_line_end = False
            else:
                tokens_string = tokens_string + token.value + " "
    except:
        sys.stderr.write("Tokenization failed\n")
        sys.exit(1)

    tokenized_file = open(argv[1], "w")
    tokenized_file.write(tokens_string + '\n')
    tokenized_file.close()
    sys.exit(0)


if __name__=="__main__":
    main(sys.argv[1:])
