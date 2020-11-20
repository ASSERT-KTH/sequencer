import sys
import re
import os

def main(argv):
    predictions = open(argv[0], "r").readlines()
    predictions_asCodeLines = []

    for prediction in predictions:
        tmp = toJavaSourceCode(prediction)
        if tmp != "":
            predictions_asCodeLines.append(tmp)

    if(len(predictions_asCodeLines) == 0):
        sys.stderr.write("All predictions contains <unk> token")
        sys.exit(1)

    output_file_path = os.path.join(argv[1], "predictions_JavaSource.txt")
    previous_asCodeLines_set = set()
    if os.path.exists(output_file_path):
        with open(output_file_path) as f:
            previous_asCodeLines_set = set(f.read().splitlines())

    predictions_asCodeLines_file = open(output_file_path, "a")
    for predictions_asCodeLine in predictions_asCodeLines:
        if predictions_asCodeLine not in previous_asCodeLines_set:
            predictions_asCodeLines_file.write(predictions_asCodeLine + "\n")
    predictions_asCodeLines_file.close()
    sys.exit(0)


def toJavaSourceCode(prediction):
    tokens = prediction.strip().split(" ")
    tokens = [token.replace("<seq2seq4repair_space>", " ") for token in tokens]
    codeLine = ""
    delimiter = JavaDelimiter()
    for i in range(len(tokens)):
        if(tokens[i] == "<unk>"):
            return ""
        if(i+1 < len(tokens)):
            # DEL = delimiters
            # ... = method_referece
            # STR = token with alphabet in it


            if(not isDelimiter(tokens[i])):
                if(not isDelimiter(tokens[i+1])): # STR (i) + STR (i+1)
                    codeLine = codeLine+tokens[i]+" "
                else: # STR(i) + DEL(i+1)
                    codeLine = codeLine+tokens[i]
            else:
                if(tokens[i] == delimiter.varargs): # ... (i) + ANY (i+1)
                    codeLine = codeLine+tokens[i]+" "
                elif(tokens[i] == delimiter.biggerThan): # > (i) + ANY(i+1)
                    codeLine = codeLine+tokens[i]+" "
                elif(tokens[i] == delimiter.rightBrackets and i > 0):
                    if(tokens[i-1] == delimiter.leftBrackets): # [ (i-1) + ] (i)
                        codeLine = codeLine+tokens[i]+" "
                    else: # DEL not([) (i-1) + ] (i)
                        codeLine = codeLine+tokens[i]
                else: # DEL not(... or ]) (i) + ANY
                    codeLine = codeLine+tokens[i]
        else:
            codeLine = codeLine+tokens[i]
    return codeLine

def isDelimiter(token):
    return not token.upper().isupper()

class JavaDelimiter:
    @property
    def varargs(self):
        return "..."

    @property
    def rightBrackets(self):
        return "]"

    @property
    def leftBrackets(self):
        return "["

    @property
    def biggerThan(self):
        return ">"



if __name__=="__main__":
    main(sys.argv[1:])
