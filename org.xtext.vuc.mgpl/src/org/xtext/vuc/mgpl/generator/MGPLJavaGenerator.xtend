/*
 * Copyright 2018 Christopher Osthues
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.xtext.vuc.mgpl.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.xtext.vuc.mgpl.generator.java.Animation
import org.xtext.vuc.mgpl.generator.java.Game
import org.xtext.vuc.mgpl.generator.java.MGPLObjects
import org.xtext.vuc.mgpl.mGPL.AnimBlock
import org.xtext.vuc.mgpl.mGPL.ArrayObjDecl
import org.xtext.vuc.mgpl.mGPL.ArrayVarDecl
import org.xtext.vuc.mgpl.mGPL.AssStmt
import org.xtext.vuc.mgpl.mGPL.AttrAss
import org.xtext.vuc.mgpl.mGPL.AttrAssList
import org.xtext.vuc.mgpl.mGPL.BracketExpr
import org.xtext.vuc.mgpl.mGPL.Decl
import org.xtext.vuc.mgpl.mGPL.EventBlock
import org.xtext.vuc.mgpl.mGPL.Expr
import org.xtext.vuc.mgpl.mGPL.ExprAtomic
import org.xtext.vuc.mgpl.mGPL.ForStmt
import org.xtext.vuc.mgpl.mGPL.IfStmt
import org.xtext.vuc.mgpl.mGPL.Numeric
import org.xtext.vuc.mgpl.mGPL.ObjDecl
import org.xtext.vuc.mgpl.mGPL.Operation
import org.xtext.vuc.mgpl.mGPL.Prog
import org.xtext.vuc.mgpl.mGPL.SimpleObjDecl
import org.xtext.vuc.mgpl.mGPL.SimpleVarDecl
import org.xtext.vuc.mgpl.mGPL.Stmt
import org.xtext.vuc.mgpl.mGPL.StmtBlock
import org.xtext.vuc.mgpl.mGPL.Touches
import org.xtext.vuc.mgpl.mGPL.UnaryOperation
import org.xtext.vuc.mgpl.mGPL.Var
import org.xtext.vuc.mgpl.mGPL.VarDecl

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class MGPLJavaGenerator extends AbstractGenerator {
	
	public static val String[] GAME_ATTRIBUTES = #["speed"];
	public static val String[] RECTANGLE_ATTRIBUTES = #["x", "y", "width", "height", "visible", "animation_block"];
	public static val String[] CIRCLE_ATTRIBUTES = #["x", "y", "radius", "visible", "animation_block"];
	public static val String[] TRIANGLE_ATTRIBUTES = #["x", "y", "width", "height", "visible", "animation_block"];
	// TODO: attrAssLists: check attrAssList for suitable constructor, if no found generate setter invocations
	
	private val String packagePath = "com/xtext/vuc/mgpl/";
	private val String packageName = "com.xtext.vuc.mgpl";
	private var String programName;
	
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		fsa.generateFile(packagePath + "Game.java", Game.game(packageName))
		new MGPLObjects().doGenerate(fsa, packagePath, packageName)
		fsa.generateFile(packagePath + 'Animation.java', Animation.animation(packageName))
		fsa.generateFile(packagePath + "Util.java", util)

		for (prog : resource.allContents.toIterable.filter(Prog)) {
			var String gameName = prog.name.toLowerCase;
			
			programName = naming(prog.name).toFirstUpper
			fsa.generateFile(packagePath + gameName + "/" + programName + ".java", prog.compile(gameName))
			fsa.generateFile(packagePath + gameName + "/ui/" + programName + "UI.java", gameUI(prog, gameName));
		}
	}
	
	def util() '''
		package «packageName»;
		
		public class Util {
			private Util() {}
			
			public static boolean intToBoolean(int value) {
				return value != 0;
			}
			
			public static boolean intToBoolean(boolean value) {
				return value;
			}
		}
		'''
	
	def gameUI(Prog prog, String pn) '''
		package «packageName».«pn».ui;
		
		import javafx.animation.AnimationTimer;
		import javafx.application.Application;
		import javafx.event.EventHandler;
		import javafx.scene.Scene;
		import javafx.scene.input.KeyEvent;
		import javafx.scene.layout.Pane;
		import javafx.stage.Stage;
		
		import «packageName».«pn».«programName»;
		
		public class «programName»UI extends Application {
			private «programName» game;
			
			@Override
			public void start(Stage primaryStage) throws Exception {
				game = new «programName»();
				primaryStage.setTitle(game.getName());
				
				Pane root = new Pane();
				root.setPrefWidth(«programName».WIDTH);
				root.setPrefHeight(«programName».HEIGHT);
				root.getChildren().addAll(game.getShapes());
				
				Scene scene = new Scene(root);
				// Register an EventHandler to handle the user input
				scene.addEventHandler(KeyEvent.KEY_PRESSED, new EventHandler<KeyEvent>() {
					@Override
					public void handle(KeyEvent event) {
						switch (event.getCode()) {
						«FOR event : prog.blocks.filter(EventBlock)»
							case «getKeyStroke(event.key)»:
								game.«event.key»Pressed();
								break;
						«ENDFOR»
						}
					}
				});
				
				primaryStage.setScene(scene);
				primaryStage.setX(«programName».X);
				primaryStage.setY(«programName».Y);
				
				// Handle the animations
				new AnimationTimer() {
					private long lastNanoTime = 0;
					
					@Override
					public void handle(long currentNanoTime) {
						if (((double)currentNanoTime - lastNanoTime) >= 1000000000 / game.getSpeed()) {
							game.runAnimations();
							lastNanoTime = currentNanoTime;
						}
					}
				}.start();
		
				primaryStage.show();
			}
			
			public static void main(String[] args) {
				launch(args);
			}
		}
	'''
	
	def shortNames(String s) {
		switch s {
			case "width": return "w"
			case "height": return "h"
			case "radius": return "r"
		}
		return null
	}
	
	def naming(String s) {
		var String name = s;
		switch s {
			case "w": name = "width"
			case "h": name = "height"
			case "r": name = "radius"
		}
		var int i;
		while ((i = name.indexOf("_")) !== -1) {
			name = name.replaceFirst("_", "");
			var String c = name.substring(i, i + 1);
			name = name.substring(0, i) + c.toFirstUpper + name.substring(i + 1);
		}
		return name;
	}
	
	def getKeyStroke(String key) {
		switch key {
			case "space": return "SPACE"
			case "leftarrow": return "LEFT"
			case "rightarrow": return "RIGHT"
			case "uparrow": return "UP"
			case "downarrow": return "DOWN"
		}
	}
	
	def setter(String name, String expr) '''
		set«naming(name).toFirstUpper»(«IF name == "animation_block"»new «naming(expr.replace("Animate", "")).toFirstUpper + "Animation()"»«ELSEIF name == "visible"»Util.intToBoolean(«expr»)«ELSE»«expr»«ENDIF»)'''
	
	def getter(String pName, String name) '''
		«IF pName == programName»«name.toUpperCase»«ELSE»«IF name == "visible"»is«ELSE»get«ENDIF»«naming(name).toFirstUpper»()«ENDIF»'''
	
	def compile(Prog prog, String pn) '''
		package «packageName».«pn»;
		
		import «packageName».Animation;
		import «packageName».Game;
		import «packageName».Util;
		import «packageName».object.*;
		
		public class «programName» extends Game {
			public static final int X = «getConstant(prog.attrAssList, "x")»;
			public static final int Y = «getConstant(prog.attrAssList, "y")»;
			public static final int WIDTH = «getConstant(prog.attrAssList, "width")»;
			public static final int HEIGHT = «getConstant(prog.attrAssList, "height")»;
			
			«FOR decl : prog.decls»
			«decl.compile»;
			«ENDFOR»
			
			public «programName»() {
				«var attr = attrAssList(prog.attrAssList, GAME_ATTRIBUTES)»
				super("«prog.name»"«IF attr != ""», «attr»«ENDIF»);
				«FOR mgplObj : prog.decls.filter(SimpleObjDecl)»
				shapes.add(«naming(mgplObj.name)».getShape());
				«ENDFOR»
				«FOR mgplObj : prog.decls.filter(ArrayObjDecl)»
				«var String mgplName = naming(mgplObj.name)»
				for (int i = 0; i < «mgplName».length; i++) {
					«mgplName»[i] = new «getObjType(mgplObj.objType)»();
					shapes.add(«mgplName»[i].getShape());
				}
				«ENDFOR»
				
				«prog.stmtBlock.compile»
			}
			
			@Override
			public void runAnimations() {
				«FOR mgplObj : prog.decls.filter(SimpleObjDecl)»
				«naming(mgplObj.name)».runAnimation();
				«ENDFOR»
				«FOR mgplObj : prog.decls.filter(ArrayObjDecl)»
				for («getObjType(mgplObj.objType)» obj : «naming(mgplObj.name)») {
					obj.runAnimation();
				}
				«ENDFOR»
			}
			«FOR eventBlock : prog.blocks.filter(EventBlock)»
			«eventBlock.compile»
			«ENDFOR»
			«FOR animBlock : prog.blocks.filter(AnimBlock)»
			«animBlock.compile»
			«ENDFOR»
		}
	'''
	
	def compile(Decl decl) {
		switch decl {
			VarDecl: (decl as VarDecl).compile
			ObjDecl: (decl as ObjDecl).compile
		}
	}
	
	def compile(VarDecl decl) {
		switch decl {
			SimpleVarDecl: (decl as SimpleVarDecl).compile
			ArrayVarDecl: (decl as ArrayVarDecl).compile
		}
	}
	
	def compile(ObjDecl decl) {
		switch decl {
			SimpleObjDecl: (decl as SimpleObjDecl).compile
			ArrayObjDecl: (decl as ArrayObjDecl).compile
		}
	}
	
	def compile(SimpleVarDecl decl) '''
		int «naming(decl.name)»«IF decl.init !== null» = «decl.init.compile»«ENDIF»'''
	
	def compile(ArrayVarDecl decl) '''
		«arrayInit("int", naming(decl.name), decl.len)»'''
	
	def compile(SimpleObjDecl decl) '''
		«var objType = getObjType(decl.objType)»
		«objType» «naming(decl.name)» = new «objType»(«decl.attrAssList.objAttrList(objType)»)'''
		
	def compile(ArrayObjDecl decl) '''
		«arrayInit(getObjType(decl.objType), naming(decl.name), decl.len)»'''
	
	def arrayInit(String type, String name, int len) '''
		«type»[] «name» = new «type»[«len»]'''
	
	def getObjType(String type) {
		switch type {
			case "rectangle": return "MGPLRectangle"
			case "triangle": return "MGPLTriangle"
			case "circle": return "MGPLCircle"
		}
	}
	
	def objAttrList(AttrAssList aas, String objType) {
		switch objType {
			case "MGPLRectangle": return attrAssList(aas, RECTANGLE_ATTRIBUTES)
			case "MGPLCircle": return attrAssList(aas, CIRCLE_ATTRIBUTES)
			case "MGPLTriangle": return attrAssList(aas, TRIANGLE_ATTRIBUTES)
		}
	}
	
	def attrAssList(AttrAssList aas, String[] attrs) {
		var boolean first = true;
		var String list = "";
		for (attr : attrs) {
			var attrVal = getAttribute(aas, attr);
			if (attrVal !== null) {
				if (!first) {
					list += ", ";
				}
				list += attrVal;
				first = false;
			}
		}
		return list;
	}
	
	def getAttribute(AttrAssList aas, String attr) {
		var String shortName = shortNames(attr);
		for (AttrAss aa : aas.attrList) {
			if (aa.name == attr || (shortName !== null && aa.name == shortName)) {
				var String expr = aa.expr.compile.toString;
				if (aa.name == "animation_block") {
					return "new " + naming(expr.replace("Animate", "")).toFirstUpper + "Animation()"
				} else if (aa.name == "visible") {
					return "Util.intToBoolean(" + expr + ")"
				} else {
					return expr
				}
			}
		}
		return null;
	}
	
	def getConstant(AttrAssList aas, String attr) {
		var String attrVal = getAttribute(aas, attr);
		if (attrVal === null) {
			return 0;
		} else {
			return attrVal;
		}
	}
	
	def compile(StmtBlock stmtBlock) '''
		«IF stmtBlock.stmts !== null»
		«FOR stmt : stmtBlock.stmts»
		«stmt.compile»
		«ENDFOR»«ENDIF»
	'''
	
	def compile(Stmt stmt) {
		switch stmt {
			IfStmt: (stmt as IfStmt).compile
			ForStmt: (stmt as ForStmt).compile
			AssStmt: (stmt as AssStmt).compile + ";"
		}
	}
	
	def compile(IfStmt is) '''
		if («is.expr.compile») {
			«is.thenBlock.compile»
		}«IF is.^else» else {
			«is.elseBlock.compile»
		}«ENDIF»
	'''
	
	def compile(ForStmt fs) '''
		for («fs.init.compile»; «fs.condition.compile»; «fs.counter.compile») {
			«fs.loopBody.compile»
		}
	'''
	
	def compile(AssStmt asStmt) '''
		«asStmt.^var.assign(asStmt.expr)»'''
	
	def compile(Var v) '''
		«IF naming(v.name) != programName»«naming(v.name)»«ELSE»«programName»«ENDIF»«IF v.array»[«v.arrayAccess.compile»]«ENDIF»'''
	
	def assign(Var v, Expr expr) '''
		«v.compile»«IF v.access».«setter(v.accName, expr.compile.toString)»«ELSE» = «expr.compile»«ENDIF»'''
	
	def accessor(Var v) '''
		«v.compile»«IF v.access».«getter(naming(v.name), v.accName)»«ENDIF»'''
	
	def compile(EventBlock eventBlock) '''
		
		@Override
		public void «eventBlock.key»Pressed() {
			«eventBlock.stmtBlock.compile»
		}
	'''
	
	def compile(AnimBlock animBlock) '''
		«var objType = getObjType(animBlock.objType)»
		
		private class «naming(animBlock.name.replaceAll("_animate", "")).toFirstUpper»Animation implements Animation {
			@Override
			public void run(MGPLObject mgplObj) {
				«objType» «naming(animBlock.objName)» = («objType») mgplObj;
				«animBlock.stmtBlock.compile»
			}
		}
	'''
	
	def compile(Expr expr) {
		switch expr {
			Operation: (expr as Operation).compile
			UnaryOperation: (expr as UnaryOperation).compile
			BracketExpr: (expr as BracketExpr).compile
			ExprAtomic: (expr as ExprAtomic).compile
		}
	}
	
	def compile(Operation op) '''
		«var rel = op.op == "||" || op.op == "&&"»«intToBoolean(op.left.compile.toString, rel)» «op.op» «intToBoolean(op.right.compile.toString, rel)»'''
	
	def compile(UnaryOperation up) '''
		«up.op»«intToBoolean(up.expr.compile.toString, up.op == "!")»'''
		
	def intToBoolean(String expr, boolean rel) '''
		«IF rel»Util.intToBoolean(«expr»)«ELSE»«expr»«ENDIF»'''
	
	def compile(BracketExpr be) '''
		(«be.expr.compile»)'''
	
	def compile(ExprAtomic expr) {
		switch expr {
			Numeric: (expr as Numeric).compile
			Var: (expr as Var).accessor
			Touches: (expr as Touches).compile
		}
	}
	
	def compile(Numeric numeric) '''
		«numeric.numeric»'''
	
	def compile(Touches touches) '''
		«touches.left.compile».touches(«touches.right.compile»)'''
}
