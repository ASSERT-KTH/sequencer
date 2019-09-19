freq.txt: 
  This lists the 567,304 tokens in the training data along with their frequency, sorted by decreasing frequency.

vocab.txt:
  This lists the 1,004 tokens used by the golden model (../../model/model.pt) in decreasing frequency.

pass.txt:
  This includes the input and output to the golden model (../../model/model.pt) for the 950 passing cases from the 4711 CodRep4 tests. The <BUG2FIX> string separates the buggy input from the fixed output.

correct_predictions:
  This directory contains the diff version of pass.txt.
