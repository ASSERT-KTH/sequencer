package se.kth.abstraction;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
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
import java.util.Iterator;

import com.github.difflib.DiffUtils;
import com.github.difflib.algorithm.DiffException;
import com.github.difflib.patch.AbstractDelta;
import com.github.difflib.patch.Patch;

import gumtree.spoon.AstComparator;
import gumtree.spoon.diff.Diff;
import gumtree.spoon.diff.support.SpoonSupport;
import spoon.Launcher;
import spoon.reflect.CtModel;
import spoon.reflect.path.CtPath;
import spoon.reflect.declaration.CtAnonymousExecutable;
import spoon.reflect.declaration.CtConstructor;
import spoon.reflect.declaration.CtElement;
import spoon.reflect.declaration.CtField;
import spoon.reflect.declaration.CtMethod;
import spoon.reflect.declaration.CtType;
import spoon.reflect.visitor.filter.TypeFilter;
import spoon.reflect.code.CtComment;
import spoon.support.reflect.code.CtBlockImpl;


public class methodWithClassContextAbstraction {
public static void main(String[] args) throws FileNotFoundException, IOException {

        File buggy_file = new File(args[0]);
        int buggy_line = Integer.parseInt(args[1]);
        File working_dir = new File(args[2]);

        if(!buggy_file.exists() || buggy_file.isDirectory()) {
                System.err.println(args[0] + " does not exists or is a directory.");
                System.exit(1);
        }

        if(!working_dir.exists() || !working_dir.isDirectory()) {
                System.err.println(args[2] + " does not exists or is not a directory.");
                System.exit(1);
        }

        generateAbstraction(buggy_file, buggy_line, working_dir);
        System.exit(0);
}

public static void generateAbstraction(File buggy_file, int buggy_line, File working_dir){
        Launcher launcher = new Launcher();
        launcher.getEnvironment().setAutoImports(true);
        launcher.getEnvironment().setNoClasspath(true);
        launcher.getEnvironment().setCommentEnabled(true);
        launcher.addInputResource(buggy_file.toString());
        try {
                launcher.buildModel();
        } catch (Exception e) {
                System.err.println("Failed to build spoon model for " + buggy_file.getAbsolutePath());
                System.exit(1);
        }

        CtModel model = launcher.getModel();
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
                                        buggy_ctElement.addComment(buggy_ctElement.getFactory().Code().createComment("ONLY FOR TOKENIZATION, BUGGY LINE BELOW", CtComment.CommentType.INLINE));
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

        if(buggy_ctElement == null){
          System.err.println("Could not find CtElement at line " + buggy_line +" in " + buggy_file);
          System.exit(1);
        }

        topLevelmethod = getTopLevelMethod(buggy_ctElement);

        if(topLevelmethod == null) {
                System.err.println("Buggy ctElement is not inside of CtMethod");
                System.exit(1);
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

        for(CtType<?> ctType : model.getAllTypes()) {
            ctType.updateAllParentsBelow();
            if(ctType.getQualifiedName().equals(topLevelmethod.getParent(CtType.class).getTopLevelType().getQualifiedName())){
              try{
                BufferedWriter writer = new BufferedWriter(new FileWriter(new File(working_dir, buggy_file.getName().split(".java")[0]+"_abstract.java")));
                writer.write(ctType.toString()+'\n');
                writer.close();
                break;
              }catch(java.io.IOException e){
                System.err.println("Error when writing abstraction to file");
                System.exit(1);
              }
            }
        }
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
