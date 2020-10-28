package se.kth.codrepFilter;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;

import com.github.difflib.DiffUtils;
import com.github.difflib.algorithm.DiffException;
import com.github.difflib.patch.AbstractDelta;
import com.github.difflib.patch.Patch;

import gumtree.spoon.AstComparator;
import gumtree.spoon.diff.Diff;
import gumtree.spoon.diff.support.SpoonSupport;
import spoon.Launcher;
import spoon.reflect.CtModel;
import spoon.reflect.declaration.CtAnonymousExecutable;
import spoon.reflect.declaration.CtConstructor;
import spoon.reflect.declaration.CtElement;
import spoon.reflect.declaration.CtField;
import spoon.reflect.declaration.CtMethod;
import spoon.reflect.declaration.CtType;
import spoon.reflect.visitor.filter.TypeFilter;
import spoon.support.reflect.code.CtBlockImpl;


public class ExtractMCFChangesWithClassContext {
	public static void main(String[] args) throws FileNotFoundException, IOException{
		HashSet<String> dup = new HashSet<String>();
		
		int count = 0;
		Path pre_versions_path = Paths.get("/Users/zimin/codrep4_filtered/pre_versions");
		File pre_versions = pre_versions_path.toFile();
		//File[] files_pre = pre_versions.listFiles();
		List<File> files_pre = new ArrayList<File>(Arrays.asList(pre_versions.listFiles()));
		Collections.sort(files_pre, new Comparator<File>() {
			public int  compare(File f1, File f2) {
				int f1_name  = Integer.parseInt(f1.getName().split(".java")[0]);
				int f2_name  = Integer.parseInt(f2.getName().split(".java")[0]);
				if(f1_name < f2_name) {
					return -1;
				}else {
					return 1;
				}
			}
		});
		for(File file_pre : files_pre) {
			if(file_pre.getAbsolutePath().endsWith(".java")) {
				File file_post = new File(file_pre.getAbsolutePath().replace("pre", "post"));
				System.err.println(file_pre.toString());
				generateChange(file_pre, file_post, dup);
				count+=1;
				if(count % 100 == 0) {
					System.out.println("Count: " + Integer.toString(count));
				}
			}
		}
		System.out.println("Done");
	}
	
	public static void generateChange(File pre, File post, HashSet<String> dup){
		Diff diff;
		try {
				diff = new AstComparator().compare(pre, post);
		} catch (Exception e) {
			return;
		}
		
		if(isImportChange(pre, post)) {
			return;
		}
		
		if(isPackageChange(pre, post)) {
			return;
		}

		CtElement element;
		try {
			element = diff.commonAncestor();
		} catch (Exception e) {
			return;
		}
		if(element == null) {
			return;
		}
		
		CtMethod methodSrc = element.getParent(CtMethod.class);
		CtField fieldSrc = element.getParent(CtField.class);
		CtConstructor constructorSrc = element.getParent(CtConstructor.class);
		if(methodSrc != null && fieldSrc == null && constructorSrc == null) {
			generateMethodChange(pre,post,dup,diff,methodSrc);
		}
		/*
		if(methodSrc == null && fieldSrc != null && constructorSrc == null) {
			generateFieldChange(pre,post,dup,diff,fieldSrc);	
		}
		if(methodSrc == null && fieldSrc == null && constructorSrc != null) {
			generateConstructorChange(pre,post,dup,diff,constructorSrc);	
		}
		*/
	}
	
	public static CtMethod getTopLevelMethod(CtMethod method) {
		CtMethod topLevelMethod = method;
		while(topLevelMethod.getParent(CtMethod.class) != null) {
			topLevelMethod = topLevelMethod.getParent(CtMethod.class);
		}
		return topLevelMethod;
	}
	
	public static void generateMethodChange(File pre, File post, HashSet<String> dup, Diff diff, CtMethod methodSrc) {
		SpoonSupport support = new SpoonSupport();
		CtMethod methodTgt = (CtMethod) support.getMappedElement(diff, methodSrc, true);
		
		Launcher launcher_pre = new Launcher();
		launcher_pre.getEnvironment().setAutoImports(true);
		launcher_pre.getEnvironment().setNoClasspath(true);
		launcher_pre.getEnvironment().setCommentEnabled(false);
		//launcher_pre.getEnvironment().setLevel("OFF");
		launcher_pre.addInputResource(pre.toString()); 
		try {
			launcher_pre.buildModel();
		} catch (Exception e) {
			return;
		}
		CtModel model_pre = launcher_pre.getModel();
		
		Launcher launcher_post = new Launcher();
		launcher_post.getEnvironment().setAutoImports(true);
		launcher_post.getEnvironment().setNoClasspath(true);
		launcher_post.getEnvironment().setCommentEnabled(false);
		//launcher_post.getEnvironment().setLevel("OFF");
		launcher_post.addInputResource(post.toString()); 
		try {
			launcher_post.buildModel();
		} catch (Exception e) {
			return;
		}
		CtModel model_post = launcher_post.getModel();
		
		// Remove method body except diff
		List<CtMethod> all_methods_pre = model_pre.getElements(new TypeFilter(CtMethod.class));
		for(CtMethod method : all_methods_pre) {
			if(!getTopLevelMethod(method).getSignature().equals(getTopLevelMethod(methodSrc).getSignature())) {
				method.setBody(new CtBlockImpl());
			}
		}
		
		// Remove constructor body
		List<CtConstructor> all_constructors_pre = model_pre.getElements(new TypeFilter(CtConstructor.class));
		for(CtConstructor constructor : all_constructors_pre) {
			constructor.setBody(new CtBlockImpl());
		}
		
		// Remove static initializer
		List<CtAnonymousExecutable> all_anonymousExecutables_pre = model_pre.getElements(new TypeFilter(CtAnonymousExecutable.class));
		for(CtAnonymousExecutable anonymousExecutable : all_anonymousExecutables_pre) {
			anonymousExecutable.delete();
		}

		// Remove method body except diff
		List<CtMethod> all_methods_post = model_post.getElements(new TypeFilter(CtMethod.class));
		for(CtMethod method : all_methods_post) {
			if(!getTopLevelMethod(method).getSignature().equals(getTopLevelMethod(methodTgt).getSignature())) {
				method.setBody(new CtBlockImpl());
			}
		}
		
		// Remove constructor body
		List<CtConstructor> all_constructors_post = model_post.getElements(new TypeFilter(CtConstructor.class));
		for(CtConstructor constructor : all_constructors_post) {
			constructor.setBody(new CtBlockImpl());
		}
		
		// Remove static initializer
		List<CtAnonymousExecutable> all_anonymousExecutables_post = model_post.getElements(new TypeFilter(CtAnonymousExecutable.class));
		for(CtAnonymousExecutable anonymousExecutable : all_anonymousExecutables_post) {
			anonymousExecutable.delete();
		}
		
		StringBuilder sb_pre = new StringBuilder();
		StringBuilder sb_post = new StringBuilder();

		for(CtType<?> ctType : model_pre.getAllTypes()) {
			if(ctType.getQualifiedName().equals(methodSrc.getParent(CtType.class).getTopLevelType().getQualifiedName()))
			{
				try {
					sb_pre.append(ctType.toString()+'\n');
				} catch (Exception e){
					return;
				}
			}
		}

		for(CtType<?> ctType : model_post.getAllTypes()) {
			if(ctType.getQualifiedName().equals(methodTgt.getParent(CtType.class).getTopLevelType().getQualifiedName()))
			{
				try {
					sb_post.append(ctType.toString()+'\n');
				} catch (Exception e){
					return;
				}
			}
		}
		
		if(!hasDiff(sb_pre.toString(), sb_post.toString())) {
			return;
		}
		
		String pair = sb_pre.toString().replaceAll("\\s+","") + sb_post.toString().replaceAll("\\s+","");
		
		if(dup.contains(pair)) {
			return;
		} else {
			dup.add(pair);
		}
		
		try {
			BufferedWriter pre_writer = new BufferedWriter(new FileWriter(pre.toString().replaceAll("_versions", "_method_classContext_verions")));
			BufferedWriter post_writer = new BufferedWriter(new FileWriter(post.toString().replaceAll("_versions", "_method_classContext_verions")));
			pre_writer.write(sb_pre.toString());
			post_writer.write(sb_post.toString());
			pre_writer.flush();
			post_writer.flush();
			pre_writer.close();
			post_writer.close();
		} catch (IOException e) {
			System.err.println("IOException in generateMethodChange() for: " + pre.toString() + " and " + post.toString());
			System.err.println("Error message:");
			System.err.println(e.getMessage());
			return;
		}
		
	}
	
	public static void generateFieldChange(File pre, File post, HashSet<String> dup, Diff diff, CtField fieldSrc) {
		SpoonSupport support = new SpoonSupport();
		CtField fieldTgt = (CtField) support.getMappedElement(diff, fieldSrc, true);
		
		Launcher launcher_pre = new Launcher();
		launcher_pre.getEnvironment().setAutoImports(true);
		launcher_pre.getEnvironment().setNoClasspath(true);
		launcher_pre.getEnvironment().setCommentEnabled(false);
		//launcher_pre.getEnvironment().setLevel("OFF");
		launcher_pre.addInputResource(pre.toString()); 
		try {
			launcher_pre.buildModel();
		} catch (Exception e) {
			return;
		}
		CtModel model_pre = launcher_pre.getModel();
		
		Launcher launcher_post = new Launcher();
		launcher_post.getEnvironment().setAutoImports(true);
		launcher_post.getEnvironment().setNoClasspath(true);
		launcher_post.getEnvironment().setCommentEnabled(false);
		//launcher_post.getEnvironment().setLevel("OFF");
		launcher_post.addInputResource(post.toString()); 
		try {
			launcher_post.buildModel();
		} catch (Exception e) {
			return;
		}
		CtModel model_post = launcher_post.getModel();
		
		// Remove method body
		List<CtMethod> all_methods_pre = model_pre.getElements(new TypeFilter(CtMethod.class));
		for(CtMethod method : all_methods_pre) {
			method.setBody(new CtBlockImpl());
		}
		
		// Remove constructor body
		List<CtConstructor> all_constructors_pre = model_pre.getElements(new TypeFilter(CtConstructor.class));
		for(CtConstructor constructor : all_constructors_pre) {
			constructor.setBody(new CtBlockImpl());
		}
		
		// Remove static initializer
		List<CtAnonymousExecutable> all_anonymousExecutables_pre = model_pre.getElements(new TypeFilter(CtAnonymousExecutable.class));
		for(CtAnonymousExecutable anonymousExecutable : all_anonymousExecutables_pre) {
			anonymousExecutable.delete();
		}

		// Remove method body 
		List<CtMethod> all_methods_post = model_post.getElements(new TypeFilter(CtMethod.class));
		for(CtMethod method : all_methods_post) {
			method.setBody(new CtBlockImpl());
		}
		
		// Remove constructor body
		List<CtConstructor> all_constructors_post = model_post.getElements(new TypeFilter(CtConstructor.class));
		for(CtConstructor constructor : all_constructors_post) {
			constructor.setBody(new CtBlockImpl());
		}
		
		// Remove static initializer
		List<CtAnonymousExecutable> all_anonymousExecutables_post = model_post.getElements(new TypeFilter(CtAnonymousExecutable.class));
		for(CtAnonymousExecutable anonymousExecutable : all_anonymousExecutables_post) {
			anonymousExecutable.delete();
		}
		
		StringBuilder sb_pre = new StringBuilder();
		StringBuilder sb_post = new StringBuilder();
		
		for(CtType<?> ctType : model_pre.getAllTypes()) {
			if(ctType.getQualifiedName().equals(fieldSrc.getParent(CtType.class).getTopLevelType().getQualifiedName()))
			{
				try {
					sb_pre.append(ctType.toString()+'\n');
				} catch (Exception e){
					return;
				}
			}
		}
		
		for(CtType<?> ctType : model_post.getAllTypes()) {
			if(ctType.getQualifiedName().equals(fieldTgt.getParent(CtType.class).getTopLevelType().getQualifiedName()))
			{
				try {
					sb_post.append(ctType.toString()+'\n');
				} catch (Exception e){
					return;
				}
			}
		}
		
		if(!hasDiff(sb_pre.toString(), sb_post.toString())) {
			return;
		}
		
		String pair = sb_pre.toString().replaceAll("\\s+","") + sb_post.toString().replaceAll("\\s+","");
		
		if(dup.contains(pair)) {
			return;
		} else {
			dup.add(pair);
		}

		try {
			BufferedWriter pre_writer = new BufferedWriter(new FileWriter(pre.toString().replaceAll("_versions", "_MCF_classContext_versions")));
			BufferedWriter post_writer = new BufferedWriter(new FileWriter(post.toString().replaceAll("_versions", "_MCF_classContext_versions")));
			pre_writer.write(sb_pre.toString());
			post_writer.write(sb_post.toString());
			pre_writer.flush();
			post_writer.flush();
			pre_writer.close();
			post_writer.close();
		} catch (IOException e) {
			System.err.println("IOException in generateFieldChange() for: " + pre.toString() + " and " + post.toString());
			System.err.println("Error message:");
			System.err.println(e.getMessage());
			return;
		}
	}
	
	public static void generateConstructorChange(File pre, File post, HashSet<String> dup, Diff diff, CtConstructor constructorSrc) {
		SpoonSupport support = new SpoonSupport();
		CtConstructor constructorTgt = (CtConstructor) support.getMappedElement(diff, constructorSrc, true);
		
		Launcher launcher_pre = new Launcher();
		launcher_pre.getEnvironment().setAutoImports(true);
		launcher_pre.getEnvironment().setNoClasspath(true);
		launcher_pre.getEnvironment().setCommentEnabled(false);
		//launcher_pre.getEnvironment().setLevel("OFF");
		launcher_pre.addInputResource(pre.toString()); 
		try {
			launcher_pre.buildModel();
		} catch (Exception e) {
			return;
		}
		CtModel model_pre = launcher_pre.getModel();
		
		Launcher launcher_post = new Launcher();
		launcher_post.getEnvironment().setAutoImports(true);
		launcher_post.getEnvironment().setNoClasspath(true);
		launcher_post.getEnvironment().setCommentEnabled(false);
		//launcher_post.getEnvironment().setLevel("OFF");
		launcher_post.addInputResource(post.toString()); 
		try {
			launcher_post.buildModel();
		} catch (Exception e) {
			return;
		}
		CtModel model_post = launcher_post.getModel();
		
		// Remove method body
		List<CtMethod> all_methods_pre = model_pre.getElements(new TypeFilter(CtMethod.class));
		for(CtMethod method : all_methods_pre) {
			method.setBody(new CtBlockImpl());
		}
		
		// Remove constructor body except diff
		List<CtConstructor> all_constructors_pre = model_pre.getElements(new TypeFilter(CtConstructor.class));
		for(CtConstructor constructor : all_constructors_pre) {
			if(!constructor.getSignature().equals(constructorSrc.getSignature())) {
				constructor.setBody(new CtBlockImpl());
			}
		}

		// Remove static initializer
		List<CtAnonymousExecutable> all_anonymousExecutables_pre = model_pre.getElements(new TypeFilter(CtAnonymousExecutable.class));
		for(CtAnonymousExecutable anonymousExecutable : all_anonymousExecutables_pre) {
			anonymousExecutable.delete();
		}

		// Remove method body 
		List<CtMethod> all_methods_post = model_post.getElements(new TypeFilter(CtMethod.class));
		for(CtMethod method : all_methods_post) {
			method.setBody(new CtBlockImpl());
		}
		
		// Remove constructor body except diff
		List<CtConstructor> all_constructors_post = model_post.getElements(new TypeFilter(CtConstructor.class));
		for(CtConstructor constructor : all_constructors_post) {
			if(!constructor.getSignature().equals(constructorTgt.getSignature())) {
				constructor.setBody(new CtBlockImpl());
			}
		}
		
		// Remove static initializer
		List<CtAnonymousExecutable> all_anonymousExecutables_post = model_post.getElements(new TypeFilter(CtAnonymousExecutable.class));
		for(CtAnonymousExecutable anonymousExecutable : all_anonymousExecutables_post) {
			anonymousExecutable.delete();
		}
		
		StringBuilder sb_pre = new StringBuilder();
		StringBuilder sb_post = new StringBuilder();
		
		for(CtType<?> ctType : model_pre.getAllTypes()) {
			if(ctType.getQualifiedName().equals(constructorSrc.getParent(CtType.class).getTopLevelType().getQualifiedName()))
			{
				try {
					sb_pre.append(ctType.toString()+'\n');
				} catch (Exception e){
					return;
				}
			}
		}
		
		for(CtType<?> ctType : model_post.getAllTypes()) {
			if(ctType.getQualifiedName().equals(constructorTgt.getParent(CtType.class).getTopLevelType().getQualifiedName()))
			{
				try {
					sb_post.append(ctType.toString()+'\n');
				} catch (Exception e){
					return;
				}
			}
		}
		
		if(!hasDiff(sb_pre.toString(), sb_post.toString())) {
			return;
		}
		
		String pair = sb_pre.toString().replaceAll("\\s+","") + sb_post.toString().replaceAll("\\s+","");
		
		if(dup.contains(pair)) {
			return;
		} else {
			dup.add(pair);
		}

		try {
			BufferedWriter pre_writer = new BufferedWriter(new FileWriter(pre.toString().replaceAll("_versions", "_MCF_classContext_versions")));
			BufferedWriter post_writer = new BufferedWriter(new FileWriter(post.toString().replaceAll("_versions", "_MCF_classContext_versions")));
			pre_writer.write(sb_pre.toString());
			post_writer.write(sb_post.toString());
			pre_writer.flush();
			post_writer.flush();
			pre_writer.close();
			post_writer.close();
		} catch (IOException e) {
			System.err.println("IOException in generateFieldChange() for: " + pre.toString() + " and " + post.toString());
			System.err.println("Error message:");
			System.err.println(e.getMessage());
			return;
		}
	}
	
	
	public static boolean isImportChange(File pre, File post)
	{
		try {
			List<String> original = Files.readAllLines(pre.toPath());
			List<String> revised = Files.readAllLines(post.toPath());
			Patch<String> patch = DiffUtils.diff(original, revised);
			for (AbstractDelta<String> delta : patch.getDeltas()) {
				if(delta.getSource().getLines().size() > 0 && delta.getSource().getLines().get(0).startsWith("import ")) {
				    return true;
				}
				if(delta.getTarget().getLines().size() > 0 && delta.getTarget().getLines().get(0).startsWith("import ")) {
				    return true;
				}
			}
			return false;
		} catch (IOException e) {
			System.err.println("IOException in isImportChange() for: " + pre.toString() + " and " + post.toString());
			System.err.println("Error message:");
			System.err.println(e.getMessage());
			// So that we ignore these changes
			return true;
		} catch (DiffException e) {
			System.err.println("DiffException in isImportChange() for: " + pre.toString() + " and " + post.toString());
			System.err.println("Error message:");
			System.err.println(e.getMessage());
			// So that we ignore these changes
			return true;
		} 
	}
	
	public static boolean isPackageChange(File pre, File post)
	{
		try {
			List<String> original = Files.readAllLines(pre.toPath());
			List<String> revised = Files.readAllLines(post.toPath());
			Patch<String> patch = DiffUtils.diff(original, revised);
			for (AbstractDelta<String> delta : patch.getDeltas()) {
				if(delta.getSource().getLines().size() > 0 && delta.getSource().getLines().get(0).startsWith("package ")) {
				    return true;
				}
				if(delta.getTarget().getLines().size() > 0 && delta.getTarget().getLines().get(0).startsWith("package ")) {
				    return true;
				}
			}
			return false;
		} catch (IOException e) {
			System.err.println("IOException in isPackageChange() for: " + pre.toString() + " and " + post.toString());
			System.err.println("Error message:");
			System.err.println(e.getMessage());
			// So that we ignore these changes
			return true;
		} catch (DiffException e) {
			System.err.println("DiffException in isPackageChange() for: " + pre.toString() + " and " + post.toString());
			System.err.println("Error message:");
			System.err.println(e.getMessage());
			// So that we ignore these changes
			return true;
		} 
	}
	
	// TODO, this should get removed.
	// Method-level changes inside static initializer are detected but not generated
	// Referencing class in the same directory is detected but not generated. (SKIP_DOC -> DocBuilder.SKIP_DOC)
	public static boolean hasDiff(String pre, String post) {
		if(pre.replaceAll("\\s+","").equals(post.replaceAll("\\s+",""))) {
			return false;
		} else {
			return true;
		}
	}
}
