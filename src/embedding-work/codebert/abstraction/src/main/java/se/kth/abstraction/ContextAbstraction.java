package se.kth.abstraction;

import se.kth.abstraction.exceptions.AbstractionException;
import se.kth.abstraction.exceptions.ElementNotFoundException;
import se.kth.abstraction.exceptions.UnsupportedElementException;
import se.kth.abstraction.exceptions.UnsupportedLocationException;
import spoon.Launcher;
import spoon.reflect.CtModel;
import spoon.reflect.code.CtComment;
import spoon.reflect.declaration.*;
import spoon.reflect.visitor.filter.TypeFilter;
import spoon.support.compiler.VirtualFile;
import spoon.support.reflect.code.CtBlockImpl;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Comparator;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.function.Function;
import java.util.function.Predicate;
import java.util.stream.Collectors;


public class ContextAbstraction {
	public static final String COMMENT_STRING = "ONLY FOR TOKENIZATION, BUGGY LINE BELOW";

	static CtModel getModel(String source) throws AbstractionException {
		Launcher launcher = new Launcher();
		launcher.getEnvironment().setAutoImports(true);
		launcher.getEnvironment().setNoClasspath(true);
		launcher.getEnvironment().setCommentEnabled(true);
		launcher.addInputResource(new VirtualFile(source));
		// Apparently JPype doesn't handle System.exit() well, so here I actually want
		// the method to raise and handle the exception elsewhere
		try {
			return launcher.buildModel();
		} catch (Exception e) {
			throw new AbstractionException("Unable to create model");
		}
	}

	static String getFormattedTime() {
		LocalDateTime now = LocalDateTime.now();
		DateTimeFormatter formatter = DateTimeFormatter.ofPattern("HH:mm:ss");
		return formatter.format(now);
	}

	public static List<String> runMany(List<AbstractionItem> items) {
		List<String> abstracted = items.parallelStream().map(item -> {
			// Log some info. I read online that this is super bad, but hey, it kinda works
			String out = null;
			try {
				out = run(item.code, item.lineno);
			} catch (AbstractionException e) {}
			return out;
		}).collect(Collectors.toList());

		return abstracted;
	}

	public static String run(String source, int buggy_line) throws AbstractionException {
		CtModel model = getModel(source);
		List<CtElement> buggyElementList = model.getElements(
				ctElement -> ctElement.getPosition().isValidPosition()
						&& ctElement.getPosition().getLine() == buggy_line);

		if (buggyElementList.isEmpty()) {
			throw new ElementNotFoundException("Unable to find buggy element at line " + buggy_line);
		}
		/*
		 Throw here because lines that contained several CtElements, some of which are annotations or comments
		 where messing up the formatting of the marking comment
		*/
		if (buggyElementList.stream().anyMatch(
				ctElement -> ctElement instanceof CtComment || ctElement instanceof CtAnnotation)) {
			throw new UnsupportedElementException("Buggy comment or annotations are not supported");
		}
		CtElement buggyElement = buggyElementList.get(0);

		CtMethod topLevelmethod = getTopLevelMethod(buggyElement);
		if (buggyElement.getParent(CtConstructor.class) != null
				|| buggyElement.getParent(CtAnonymousExecutable.class) != null
				|| topLevelmethod == null) {
			throw new UnsupportedLocationException();
		}
		// Add comment to mark line
		buggyElement.addComment(buggyElement.getFactory().Code().createComment(COMMENT_STRING, CtComment.CommentType.INLINE));
		// Remove method body except diff
		List<CtMethod> all_methods = model.getElements(new TypeFilter(CtMethod.class));
		for (CtMethod method : all_methods) {
			if (!getTopLevelMethod(method).getSignature().equals(topLevelmethod.getSignature())) {
				method.setBody(new CtBlockImpl());
			}
		}
		// Remove constructor body
		List<CtConstructor> all_constructors = model.getElements(new TypeFilter(CtConstructor.class));
		for (CtConstructor constructor : all_constructors) {
			constructor.setBody(new CtBlockImpl());
		}
		// Remove static initializer
		List<CtAnonymousExecutable> all_anonymousExecutables = model.getElements(new TypeFilter(CtAnonymousExecutable.class));
		for (CtAnonymousExecutable anonymousExecutable : all_anonymousExecutables) {
			anonymousExecutable.delete();
		}

		String processed = null;
		for (CtType<?> ctType : model.getAllTypes()) {
			ctType.updateAllParentsBelow();
			if (ctType.getQualifiedName().equals(topLevelmethod.getParent(CtType.class).getTopLevelType().getQualifiedName())) {
				try {
					processed = ctType.toString() + '\n';
				} catch (NoClassDefFoundError | RuntimeException e) {
					// For some reason this sometimes throws different weird exceptions/errors
					// I think is a problem from spoon, but I don't know, maybe I am
					// building the project incorrectly
					throw new AbstractionException("Unable to reconstruct abstracted file");
				}
				break;
			}
		}
		// Sometimes spoon just fails to add the identifying comment, so here we signal failure in those cases
		if (processed != null && !processed.contains(COMMENT_STRING)) {
			throw new AbstractionException("Unable to mark comment (this could be a limitation of spoon).");
		}
		return processed;
	}

	public static CtMethod getTopLevelMethod(CtMethod ctMethod) {
		CtMethod topLevelMethod = ctMethod;
		while (topLevelMethod.getParent(CtMethod.class) != null) {
			topLevelMethod = topLevelMethod.getParent(CtMethod.class);
		}
		return topLevelMethod;
	}

	public static CtMethod getTopLevelMethod(CtElement ctElement) {
		CtMethod topLevelMethod = null;
		topLevelMethod = ctElement.getParent(CtMethod.class);
		while (topLevelMethod != null && topLevelMethod.getParent(CtMethod.class) != null) {
			topLevelMethod = topLevelMethod.getParent(CtMethod.class);
		}
		return topLevelMethod;
	}
}


