package se.kth.abstraction;

import java.util.List;
import java.util.Iterator;

import spoon.Launcher;
import spoon.reflect.CtModel;
import spoon.reflect.path.CtPath;
import spoon.reflect.declaration.CtAnonymousExecutable;
import spoon.reflect.declaration.CtConstructor;
import spoon.reflect.declaration.CtElement;
import spoon.reflect.declaration.CtMethod;
import spoon.reflect.declaration.CtType;
import spoon.reflect.visitor.filter.TypeFilter;
import spoon.reflect.code.CtComment;
import spoon.support.reflect.code.CtBlockImpl;
import spoon.support.compiler.VirtualFile;

import se.kth.abstraction.exceptions.*;


public class ContextAbstraction {
	public static final String COMMENT_STRING = "ONLY FOR TOKENIZATION, BUGGY LINE BELOW";

	public static String run(String source, int buggy_line) throws ElementNotFoundException, NotInsideMethodException {
		Launcher launcher = new Launcher();
		launcher.getEnvironment().setAutoImports(true);
		launcher.getEnvironment().setNoClasspath(true);
		launcher.getEnvironment().setCommentEnabled(true);
		launcher.addInputResource(new VirtualFile(source));
		// Apparently JPype doesn't handle System.exit() well, so here I actually want
		// the method to raise and handle the exception in python
		CtModel model = launcher.buildModel();

		// this is copy-pasted
		CtMethod topLevelmethod = null;
		CtElement buggy_ctElement = null;
		CtElement tmp_ctElement = null;
		CtPath buggy_ctElement_ctPath = null;
		for(CtType<?> ctType : model.getAllTypes()) {
			for(Iterator<CtElement> desIter = ctType.descendantIterator(); desIter.hasNext(); ) {
				tmp_ctElement = desIter.next();
				try{
					if(tmp_ctElement.getPosition().getLine() == buggy_line && !(tmp_ctElement instanceof CtComment)) {
						buggy_ctElement = tmp_ctElement;
						buggy_ctElement_ctPath = tmp_ctElement.getPath();
						buggy_ctElement.addComment(buggy_ctElement.getFactory().Code().createComment(COMMENT_STRING, CtComment.CommentType.INLINE));
						break;
					}
				}catch(java.lang.UnsupportedOperationException e) {
					continue;
				}
			}
			if(buggy_ctElement != null){
				break;
			}
		}

		if(buggy_ctElement == null) {
			throw new ElementNotFoundException("Could not find CtElement at line " + buggy_line + ". This might be because there is a comment there.");
		}
		

		topLevelmethod = getTopLevelMethod(buggy_ctElement);

		if(topLevelmethod == null) {
			throw new NotInsideMethodException("Buggy ctElement is not inside a CtMethod. Bugs outside methods are not supported");
		}

		// Remove method body except diff
		List<CtMethod> all_methods = model.getElements(new TypeFilter(CtMethod.class));
		for(CtMethod method : all_methods) {
			if(!getTopLevelMethod(method).getSignature().equals(topLevelmethod.getSignature())) {
				method.setBody(new CtBlockImpl());
			}
		}

		// Remove constructor body
		List<CtConstructor> all_constructors = model.getElements(new TypeFilter(CtConstructor.class));
		for(CtConstructor constructor : all_constructors) {
			constructor.setBody(new CtBlockImpl());
		}

		// Remove static initializer
		List<CtAnonymousExecutable> all_anonymousExecutables = model.getElements(new TypeFilter(CtAnonymousExecutable.class));
		for(CtAnonymousExecutable anonymousExecutable : all_anonymousExecutables) {
			anonymousExecutable.delete();
		}

		String processed = null;
		for(CtType<?> ctType : model.getAllTypes()) {
			ctType.updateAllParentsBelow();
			if(ctType.getQualifiedName().equals(topLevelmethod.getParent(CtType.class).getTopLevelType().getQualifiedName())){
				processed = ctType.toString() + '\n';
			}
		}
		return processed;
	}

	public static CtMethod getTopLevelMethod(CtMethod ctMethod) {
		CtMethod topLevelMethod = ctMethod;
		while(topLevelMethod.getParent(CtMethod.class) != null) {
			topLevelMethod = topLevelMethod.getParent(CtMethod.class);
		}
		return topLevelMethod;
	}

	public static CtMethod getTopLevelMethod(CtElement ctElement) {
		CtMethod topLevelMethod = null;
		topLevelMethod = ctElement.getParent(CtMethod.class);
		while(topLevelMethod != null && topLevelMethod.getParent(CtMethod.class) != null) {
			topLevelMethod = topLevelMethod.getParent(CtMethod.class);
		}
		return topLevelMethod;
	}
}


