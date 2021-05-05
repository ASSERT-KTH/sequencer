package se.kth.abstraction;

// The simplest of classes since java doesn't have tuples
public class AbstractionItem {
	// I know, bad design, public members and stuff...
	public String code;
	public int lineno;

	public AbstractionItem(String code, int lineno) {
		this.code = code;
		this.lineno = lineno;
	}
}
