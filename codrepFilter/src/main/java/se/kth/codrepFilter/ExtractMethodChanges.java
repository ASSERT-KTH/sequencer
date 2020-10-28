package se.kth.codrepFilter;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashSet;
import java.util.List;

import com.github.difflib.DiffUtils;
import com.github.difflib.algorithm.DiffException;
import com.github.difflib.patch.AbstractDelta;
import com.github.difflib.patch.Patch;

import gumtree.spoon.AstComparator;
import gumtree.spoon.diff.Diff;
import gumtree.spoon.diff.support.SpoonSupport;
import spoon.reflect.declaration.CtElement;
import spoon.reflect.declaration.CtMethod;

public class ExtractMethodChanges {
	public static void main( String[] args ) throws Exception
    {
		HashSet<String> dup = new HashSet<String>();
		
		int count = 0;
		Path pre_versions_path = Paths.get("/Users/zimin/codrep4_filtered/pre_versions");
		File pre_versions = pre_versions_path.toFile();
		File[] methods_pre = pre_versions.listFiles();
		for(File method_pre : methods_pre) {
			if(method_pre.getAbsolutePath().endsWith(".java")) {
				System.err.println(method_pre.toString());
				File method_post = new File(method_pre.getAbsolutePath().replace("pre_versions", "post_versions"));
				generateChangeInMethod(method_pre, method_post, dup);
				count+=1;
				if(count % 100 == 0) {
					System.out.println("Count: " + Integer.toString(count));
				}
			}
		}
		System.out.println("Done");
    }
	
	public static void generateChangeInMethod(File pre, File post, HashSet<String> dup) throws Exception {
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
		if(methodSrc == null) {
			return;
		}
		
		SpoonSupport support = new SpoonSupport();
		CtMethod methodTgt = (CtMethod) support.getMappedElement(diff, methodSrc, true);
		
		//System.out.println(methodSrc.getParent(CtType.class).getQualifiedName() + "#" + methodSrc.getSignature());
		
		String method_pre_string = methodSrc.toString();
		String method_post_string = methodTgt.toString();
		String pair = method_pre_string.replaceAll("\\s+","") + method_post_string.replaceAll("\\s+","");
		
		if(dup.contains(pair)) {
			return;
		} else {
			dup.add(pair);
		}
		
		try {
			BufferedWriter pre_writer = new BufferedWriter(new FileWriter(pre.toString().replaceAll("_versions", "_method_test_versions")));
			BufferedWriter post_writer = new BufferedWriter(new FileWriter(post.toString().replaceAll("_versions", "_method_test_versions")));
			pre_writer.write(methodSrc.toString());
			post_writer.write(methodTgt.toString());
			pre_writer.flush();
			post_writer.flush();
			pre_writer.close();
			post_writer.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
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
}
