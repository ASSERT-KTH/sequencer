import argparse

START_BUG = "<START_BUG>"
END_BUG = "<END_BUG>"
PRE_POST_RATIO = 2


def truncate(tokenized_file, limit):
    """
    Truncates a file to a limit of tokens. The file must be a string and be
    already tokenized. The exact algorithm can be found in the SequenceR paper

    Args:
        tokenized_file (str): The tokenized file. Tokens should be whitespace separated.
        limit (int): The max number of tokens.

    Returns:
        str: The truncated file, contains whitespace-separated tokens. Includes newline
    """

    tokens = tokenized_file.split()
    try:
        start = tokens.index(START_BUG)
        end = tokens.index(END_BUG) + 1
    except ValueError:
        # If special tokens not found assume whole text is the buggy line
        start = 0
        end = len(tokens)

    # How many total tokens around the buggy line can we add
    real_state = max(0, limit - end + start)
    # Decide how many tokens to add before the buggy line. Either a portion of the
    # real state or all the preceding if there aren't enough
    before = min(start, int(real_state // (PRE_POST_RATIO + 1) * PRE_POST_RATIO))
    # Tokens after end of buggy line. The rest of the real state
    after = real_state - before
    return " ".join(tokens[start - before : min(start + limit, end + after)]) + "\n"


def main(args=None):
    parser = argparse.ArgumentParser(
        description="Truncate the context of each line in input file up to a token limit"
    )
    parser.add_argument("srcfile", type=argparse.FileType("r"), help="Input file")
    parser.add_argument("dstfile", type=argparse.FileType("w"), help="Output file")
    parser.add_argument("limit", type=int, help="The token limit")
    args = parser.parse_args(args)

    try:
        for line in args.srcfile:
            args.dstfile.write(truncate(line, args.limit))
    finally:
        args.srcfile.close()
        args.dstfile.close()


if __name__ == "__main__":
    main()
