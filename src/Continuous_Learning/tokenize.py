import javalang
import sys
import os
import glob
import io

def main(argv):

    if(len(argv) < 2 or argv[0] == "-h" or argv[0] == "--help"):
        print("Usage: python tokenize.py /path/to/source/dir /path/to/target/files")
        exit(0)

    files = glob.glob(argv[0] +  "/*/*.java-*")
    train_src_file = io.open(argv[1] + "/src-train.txt", "w", encoding="utf-8")
    train_tgt_file = io.open(argv[1] + "/tgt-train.txt", "w", encoding="utf-8")
    val_src_file = io.open(argv[1] + "/src-val.txt", "w", encoding="utf-8")
    val_tgt_file = io.open(argv[1] + "/tgt-val.txt", "w", encoding="utf-8")

    train_tmp_file = io.open(argv[1] + "/train-tmp.txt", "w", encoding="utf-8")
    val_tmp_file = io.open(argv[1] + "/val-tmp.txt", "w", encoding="utf-8")

    file_count = 0
    for file in files:
        fo = io.open(file, "r", encoding="utf-8")
        fo.readline()
        hunk_file_lines = fo.readlines()
        
        source_hunk = []
        target_line = ""

        try:
            for line in hunk_file_lines:
                if(line.startswith("-")):
                    actual_line = line.replace('-', ' ', 1).strip()
                    if(actual_line.startswith("*") or actual_line.startswith("//")):
                        raise Exception("change inside comment") # javalang package does not handle comment tokens
                    else:
                        source_hunk.append("SEQUENCER_TOKENIZER_START_BUG " + line.replace('-', ' ', 1).strip() + " SEQUENCER_TOKENIZER_END_BUG ")
                elif(line.startswith("+")):
                    target_line = line.replace('+', ' ', 1).strip()
                    if(target_line.startswith("*") or target_line.startswith("//")):
                        raise Exception("change inside comment") # javalang package does not handle comment tokens
                else:
                    source_hunk.append(line.strip() + " ")


            source_tokens = ""
            target_tokens = ""

            tokens = list(javalang.tokenizer.tokenize(''.join(source_hunk)))
            for token in tokens:
                source_tokens = source_tokens + " " + token.value

            tokens = list(javalang.tokenizer.tokenize(target_line))
            for token in tokens:
                target_tokens = target_tokens + " " + token.value

        except Exception as e:
            sys.stderr.write("Tokenization failed for file " + file + "\n")
            continue

        source_tokens = source_tokens.replace("SEQUENCER_TOKENIZER_START_BUG", "<START_BUG>")
        source_tokens = source_tokens.replace("SEQUENCER_TOKENIZER_END_BUG", "<END_BUG>")

        # print(source_tokens + '\n')
        # print(target_tokens + '\n')

        # we need transactional behavior
        # assume if write to tmp doesnt fail
        # then write to real file wont fail either

        try:
            train_tmp_file.write(target_tokens.strip() + '\n')
            val_tmp_file.write(source_tokens.strip() + '\n')
        except Exception as e:
            sys.stderr.write("Tokenization failed for file " + file + "\n")
            continue


        if(file_count % 20 == 0):
            val_src_file.write(source_tokens.strip() + '\n')
            val_tgt_file.write(target_tokens.strip() + '\n')
        else:
            train_src_file.write(source_tokens.strip() + '\n')
            train_tgt_file.write(target_tokens.strip() + '\n')

        file_count = file_count + 1

        fo.close()
    
    val_src_file.close()
    val_tgt_file.close()
    train_src_file.close()
    train_tgt_file.close()

    train_tmp_file.close()
    val_tmp_file.close()
    
    os.remove(argv[1] + "/train-tmp.txt")
    os.remove(argv[1] + "/val-tmp.txt")
    
    sys.exit(0)


if __name__=="__main__":
    main(sys.argv[1:])
