package se.kth.codrepFilter;

import java.io.File;
import java.util.HashSet;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

import gumtree.spoon.AstComparator;
import gumtree.spoon.diff.Diff;
import gumtree.spoon.diff.operations.Operation;
import spoon.Launcher;
import spoon.SpoonModelBuilder;
import spoon.compiler.SpoonResource;
import spoon.compiler.SpoonResourceHelper;
import spoon.reflect.CtModel;
import spoon.reflect.code.CtBlock;
import spoon.reflect.code.CtCodeSnippetStatement;
import spoon.reflect.code.CtStatement;
import spoon.reflect.declaration.CtAnnotation;
import spoon.reflect.declaration.CtElement;
import spoon.reflect.declaration.CtField;
import spoon.reflect.declaration.CtMethod;
import spoon.reflect.declaration.CtType;
import spoon.reflect.factory.Factory;
import spoon.reflect.factory.FactoryImpl;
import spoon.support.DefaultCoreFactory;
import spoon.support.StandardEnvironment;
import spoon.support.compiler.jdt.JDTBasedSpoonCompiler;
import gumtree.spoon.builder.SpoonGumTreeBuilder;

public class Filter
{
    public static void main( String[] args ) throws IOException
    {
    		HashSet<String> dup = new HashSet<String>();

    		int count = 0;
    		Path pre_versions_path = Paths.get("/Users/zimin/codrep4_filtered/pre_versions");
    		File pre_versions = pre_versions_path.toFile();
    		File[] files_pre = pre_versions.listFiles();
    		for(File file_pre : files_pre) {
    			if(file_pre.getAbsolutePath().endsWith(".java")) {
    				File file_post = new File(file_pre.getAbsolutePath().replace("pre_versions", "post_versions"));
    				String file_pre_string = new String(Files.readAllBytes(file_pre.toPath()));
    				String file_post_string = new String(Files.readAllBytes(file_post.toPath()));
    				String pair = file_pre_string.replaceAll("\\s+","") + file_post_string.replaceAll("\\s+","");
    				if(!contains_AST_diffs(file_pre, file_post) || dup.contains(pair)) {
    					file_pre.delete();
    					file_post.delete();
    				}else {
    					dup.add(pair);
    				}
    				count+=1;
    				if(count % 100 == 0) {
    					System.out.println("Count: " + Integer.toString(count));
    				}
    			}
    		}
    		System.out.println("Done");
    }

    public static boolean contains_AST_diffs(File pre, File post) {
    		Diff diff;
    		try {
    				diff = new AstComparator().compare(pre, post);
			} catch (Exception e) {
				return false;
			}

    		List<Operation> operations = diff.getAllOperations();
    		if(operations.size() == 0)
    		{
    			return false;
    		}

    		CtElement el = diff.commonAncestor();
    		if(el instanceof CtAnnotation) {
        		return false;
        }

    		return true;
    }
}
