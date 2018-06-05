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
package org.xtext.vuc.mgpl.validation

import java.util.Arrays
import java.util.HashMap
import java.util.HashSet
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.validation.Check
import org.xtext.vuc.mgpl.mGPL.AnimBlock
import org.xtext.vuc.mgpl.mGPL.ArrayObjDecl
import org.xtext.vuc.mgpl.mGPL.ArrayVarDecl
import org.xtext.vuc.mgpl.mGPL.AssStmt
import org.xtext.vuc.mgpl.mGPL.AttrAss
import org.xtext.vuc.mgpl.mGPL.AttrAssList
import org.xtext.vuc.mgpl.mGPL.Decl
import org.xtext.vuc.mgpl.mGPL.EventBlock
import org.xtext.vuc.mgpl.mGPL.Expr
import org.xtext.vuc.mgpl.mGPL.MGPLPackage
import org.xtext.vuc.mgpl.mGPL.Numeric
import org.xtext.vuc.mgpl.mGPL.ObjDecl
import org.xtext.vuc.mgpl.mGPL.Operation
import org.xtext.vuc.mgpl.mGPL.Prog
import org.xtext.vuc.mgpl.mGPL.SimpleObjDecl
import org.xtext.vuc.mgpl.mGPL.SimpleVarDecl
import org.xtext.vuc.mgpl.mGPL.Touches
import org.xtext.vuc.mgpl.mGPL.UnaryOperation
import org.xtext.vuc.mgpl.mGPL.Var

/**
 * This class contains custom validation rules. 
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class MGPLValidator extends AbstractMGPLValidator {
	public static val String[] GAME_ATTRIBUTES = #["x", "y", "width", "height", "speed"];
	public static val String[] GAME_ATTRIBUTES_SHORT = #["w", "h"];
	public static val String[] RECTANGLE_TRIANGLE_ATTRIBUTES = #["x", "y", "width", "height", "animation_block",
		"visible"];
	public static val String[] RECTANGLE_TRIANGLE_ATTRIBUTES_SHORT = #["w", "h"];
	public static val String[] CIRCLE_ATTRIBUTES = #["x", "y", "radius", "animation_block", "visible"];
	public static val String[] CIRCLE_ATTRIBUTES_SHORT = #["r"];
	
	public static val String[] OBJECT_TYPES = #['rectangle', 'triangle', 'circle'];
	
	public static val String NO_DECLARED_ANIM = 'No declared animation block for object type ';
	

	/**
	 * TASK 1: Declarations
	 * No identically named declarations are allowed. So, for example, the name of 
	 * an integer variable can not be used as the name of another declared object. 
	 * The declaration order, if not determined by the grammar, is not relevant 
	 * (no define before apply).
	 */
	@Check
	def checkDecls(Prog prog) {
		var HashSet<String> keys = new HashSet<String>();
		var HashSet<String> anims = new HashSet<String>();
		var HashSet<String> ids = new HashSet<String>();

		// Check for duplicated key events
		for (EventBlock eBlock : prog.blocks.filter(EventBlock)) {
			if (!keys.add(eBlock.key)) {
				error('Duplicate key event ' + eBlock.key, eBlock, MGPLPackage.Literals.EVENT_BLOCK__KEY);
			}
		}

		// Check for duplicated animation blocks
		for (AnimBlock aBlock : prog.blocks.filter(AnimBlock)) {
			if (!anims.add(aBlock.name)) {
				error('Duplicate animation ' + aBlock.name, aBlock, MGPLPackage.Literals.ANIM_BLOCK__NAME);
			}
		}

		// Check for duplicated variable declarations and naming collisions with animation blocks
		// (no need for key events because they are identified as key words by the scanner)
		for (Decl decl : prog.decls) {
			if (!ids.add(decl.name)) {
				error('Duplicate variable ' + decl.name, decl, MGPLPackage.Literals.DECL__NAME);
			}
			if (!anims.add(decl.name)) {
				error('Variable name ' + decl.name + ' colliding with animation', decl,
					MGPLPackage.Literals.DECL__NAME);
			} else {
				anims.remove(decl.name);
			}
//			if (!keys.add(decl.name)) {
//				error('Variable name ' + decl.name + ' colliding with key event', decl, MGPLPackage.Literals.DECL__NAME);
//			} else {
//				keys.remove(decl.name);
//			}
		}

		// Check for naming collisions with variable declarations
		// (no need for key events because they are identified as key words by the scanner)
		for (AnimBlock aBlock : prog.blocks.filter(AnimBlock)) {
			if (!ids.add(aBlock.name)) {
				error('Animation name ' + aBlock.name + ' colliding with variable', aBlock,
					MGPLPackage.Literals.ANIM_BLOCK__NAME);
			} else {
				ids.remove(aBlock.name);
			}
		}
	}
	

	/**
	 * TASK 2: Bindings
	 * All applied occurrences of variable or object names must be declared. In particular, 
	 * array accesses require the presence of a corresponding array declaration and attribute 
	 * accesses the presence of an object with a corresponding attribute (further on the 
	 * attributes below). An animation_block attribute must always point to an existing 
	 * animation handler of appropriate type.
	 */
	@Check
	def checkBindings(Prog prog) {
		var Set<String> simpleVarNames = prog.getSimpleVariables;
		var Set<String> arrayVarNames = prog.getArrayVariables;
		var Map<String, String> simpleObjs = prog.eAllContents.filter(SimpleObjDecl).toMap([o|o.name], [o|o.objType]);
		simpleObjs.put(prog.name, "game");
		var Map<String, String> arrayObjs = prog.eAllContents.filter(ArrayObjDecl).toMap([o|o.name], [o|o.objType]);
		var Map<String, String> anims = prog.eAllContents.filter(AnimBlock).toMap([ab|ab.name], [ab|ab.objType]);

		for (Decl d : prog.decls) {
			for (Var v : d.eAllContents.toIterable.filter(Var)) {
				checkVariableBinding(v, anims, simpleVarNames, arrayVarNames, simpleObjs, arrayObjs);
			}
			if (d instanceof SimpleVarDecl) {
				var String type = resolveType((d as SimpleVarDecl).init, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames);
				if ("int" != type) {
					error('Type mismatch: cannot convert from ' + type + ' to int', d, MGPLPackage.Literals.SIMPLE_VAR_DECL__INIT);
				}
			}
			if (d instanceof ObjDecl) {
				for (AttrAss aas : d.eAllContents.toIterable.filter(AttrAss)) {
					checkAttrAss(d, aas, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames);
				}
			}
		}
		for (Var v : prog.stmtBlock.eAllContents.toIterable.filter(Var)) {
			checkVariableBinding(v, anims, simpleVarNames, arrayVarNames, simpleObjs, arrayObjs);
		}
		for (EventBlock eb : prog.blocks.filter(EventBlock)) {
			for (Var v : eb.eAllContents.toIterable.filter(Var)) {
				checkVariableBinding(v, anims, simpleVarNames, arrayVarNames, simpleObjs, arrayObjs);
			}
		}
		for (AnimBlock ab : prog.blocks.filter(AnimBlock)) {
			simpleObjs.put(ab.objName, ab.objType);
			for (Var v : ab.eAllContents.toIterable.filter(Var)) {
				checkVariableBinding(v, anims, simpleVarNames, arrayVarNames, simpleObjs, arrayObjs);
			}
			simpleObjs.remove(ab.objName);
		}
		
		for (AssStmt ass : prog.eAllContents.toIterable.filter(AssStmt)) {
			checkAssStmt(ass, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames);
		}
	}
	
	/**
	 * Checks if a variable is correctly used (array, simple), has an appropriate 
	 * attribute or if it is declared.
	 */
	def private checkVariableBinding(Var v, Map<String, String> anims, Set<String> simpleVarNames, Set<String> arrayVarNames, 
								Map<String, String> simpleObjs, Map<String, String> arrayObjs) {
		var boolean isArrVar = arrayVarNames.contains(v.name);
		var boolean isArrObj = arrayObjs.containsKey(v.name);
		var boolean isVar = simpleVarNames.contains(v.name);
		var boolean isObj = simpleObjs.containsKey(v.name);
		if (v.array) {
			if (isVar && isObj) {
				error(v.name + ' is not an array', v, MGPLPackage.Literals.VAR__NAME);
			} else if (!isArrVar && !isArrObj) {
				error('The array ' + v.name + ' is not declared', v, MGPLPackage.Literals.VAR__NAME);
			} else if (isArrVar && v.access) {
				error('Array of simple type have no attributes', v, MGPLPackage.Literals.VAR__ACC_NAME);
			} else if (isArrObj && v.access && !hasAttribute(arrayObjs.get(v.name), v.accName)) {
				error(v.name + ' has no attribute ' + v.accName, v, MGPLPackage.Literals.VAR__ACC_NAME);
			}
		} else {
			if (isArrVar || isArrObj) {
				if (v.access && !v.array) {
					error('Array has no attribute ' + v.accName, v, MGPLPackage.Literals.VAR__ACC_NAME);
				}
				// Assignment of arrays are allowed (array1 = array2);
			} else if (!isVar && !isObj && !anims.containsKey(v.name)) {
				error('The variable ' + v.name + ' is not declared', v, MGPLPackage.Literals.VAR__NAME);
			} else if (isVar && v.access) {
				error('Simple types have no attributes', v, MGPLPackage.Literals.VAR__ACC_NAME);
			} else if (isObj && v.access && !hasAttribute(simpleObjs.get(v.name), v.accName)) {
				error(v.name + ' has no attribute ' + v.accName, v, MGPLPackage.Literals.VAR__ACC_NAME);
			}
		}
	}

	/**
	 * Checks the given object type for the presence of the given attribute.
	 */
	def private hasAttribute(String objType, String attributeName) {
		switch objType {
			case "circle":
				return CIRCLE_ATTRIBUTES.contains(attributeName) || CIRCLE_ATTRIBUTES_SHORT.contains(attributeName)
			case "triangle",
			case "rectangle":
				return RECTANGLE_TRIANGLE_ATTRIBUTES.contains(attributeName) ||
					RECTANGLE_TRIANGLE_ATTRIBUTES_SHORT.contains(attributeName)
			case "game":
				return GAME_ATTRIBUTES.contains(attributeName) || GAME_ATTRIBUTES_SHORT.contains(attributeName)
		}

		return false;
	}
	
	/**
	 * Checks the type of all attribute assignments.
	 */
	def private checkAttrAss(ObjDecl d, AttrAss aas, Map<String, String> anims, Map<String, String> simpleObjs, 
							 Map<String, String> arrayObjs, Set<String> simpleVarNames, Set<String> arrayVarNames) {
		if (aas.name != "animation_block") {
			var String type = resolveType(aas.expr, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames);
			if (type != "int") {
				error('Type mismatch: cannot convert from ' + type + ' to int', aas, MGPLPackage.Literals.ATTR_ASS__EXPR);
			}
		}
		checkAnimationBlock(d.name, aas.name, aas.expr, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames, aas, MGPLPackage.Literals.ATTR_ASS__EXPR);
	}
	
	/**
	 * Checks if all assignment statements are type correct.
	 */
	def private checkAssStmt(AssStmt ass, Map<String, String> anims, Map<String, String> simpleObjs, 
							 Map<String, String> arrayObjs, Set<String> simpleVarNames, Set<String> arrayVarNames) {
		var varName = ass.^var.name;
		var String assign = resolveType(ass.^var, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames);
		var String access = resolveType(ass.expr, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames);
		
		if (assign != access && assign !== null && access !== null) {
			error('Type mismatch: cannot convert from ' + access + ' to ' + assign, ass, MGPLPackage.Literals.ASS_STMT__EXPR);
		}
		
		if (ass.^var.access) {
			checkAnimationBlock(varName, ass.^var.accName, ass.expr, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames, ass, MGPLPackage.Literals.ASS_STMT__EXPR);
		}
	}
	
	/**
	 * Checks the assignment of an animation block.
	 */
	def private checkAnimationBlock(String varName, String attrName, Expr expr, Map<String, String> anims, Map<String, String> simpleObjs, 
							 Map<String, String> arrayObjs, Set<String> simpleVarNames, Set<String> arrayVarNames, 
							 EObject obj, EReference ref) {
		var boolean isVar = (expr instanceof Var);
		if (attrName == "animation_block") {
			if (isVar) {
				var Var access = expr as Var;
				var animName = access.name;
				if (access.access && access.accName == "animation_block") {
					var String varType = getAnimationType(varName, simpleObjs, arrayObjs);
					var String animationType = getAnimationType(animName, simpleObjs, arrayObjs);
					if (varType != animationType) {
						error('Type mismatch: cannot convert from ' + animationType + ' to ' + varType, obj, ref);
					}
				} else {
					if (anims.get(animName) != simpleObjs.get(varName) && anims.get(animName) != arrayObjs.get(varName)) {
						error(NO_DECLARED_ANIM + anims.get(animName), obj, ref);
					}
				}
			}
		}
	}
	
	/**
	 * Retrieves the type of a variable.
	 */
	def private resolveType(Var v, Map<String, String> anims, Map<String, String> simpleObjs, 
							Map<String, String> arrayObjs, Set<String> simpleVarNames, 
							Set<String> arrayVarNames) {
		if (v.access) {
			if (v.accName == "animation_block") {
				return "animation";
			} else {
				return "int";
			}
		} else {
			if (arrayVarNames.contains(v.name)) {
				if (v.array) {
					return "int";
				} else {
					return "int[]";
				}
			} else if (simpleVarNames.contains(v.name)) {
				return "int";
			} else if (arrayObjs.containsKey(v.name)) {
				if (v.array) {
					return arrayObjs.get(v.name);
				} else {
					return arrayObjs.get(v.name) + "[]";
				}
			} else if (simpleObjs.containsKey(v.name)) {
				return simpleObjs.get(v.name);
			} else if (anims.containsKey(v.name)) {
				return "animation";
			}
		}
		return null;
	}
	
	/**
	 * Retrieves the type of an expression.
	 */
	def private resolveType(Expr e, Map<String, String> anims, Map<String, String> simpleObjs, 
							Map<String, String> arrayObjs, Set<String> simpleVarNames, 
							Set<String> arrayVarNames) {
		if (e instanceof Var) {
			return resolveType((e as Var), anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames);
		} else {
			return "int";
		}
	}
	
	/**
	 * Retrieves the type of an object for an animation block.
	 */
	def private getAnimationType(String animationName, Map<String, String> simpleObjs, Map<String, String> arrayObjs) {
		var String animationType = arrayObjs.get(animationName);
		if (animationType === null) {
			animationType = simpleObjs.get(animationName);
		}
		return animationType;
	}
	
	
	/**
	 * TASK 3: Expressions
	 * Both operands of the touches expression must be graphic objects. In all other 
	 * expressions (numeric, relational, and Boolean), the operands must be of type 
	 * int. For example, the expression 1 + bullets [i] is not allowed if bullets is 
	 * an object array over the type circle. There is no independent Boolean type. 
	 * Rather, 0 stands for false and every other value for true.
	 */
	@Check
	def checkExpressions(Prog prog) {
		var Set<String> simpleVarNames = prog.getSimpleVariables;
		var Set<String> arrayVarNames = prog.getArrayVariables;
		var Map<String, String> simpleObjs = prog.eAllContents.filter(SimpleObjDecl).toMap([o|o.name], [o|o.objType]);
		simpleObjs.put(prog.name, "game");
		var Map<String, String> arrayObjs = prog.eAllContents.filter(ArrayObjDecl).toMap([o|o.name], [o|o.objType]);
		var Map<String, String> anims = prog.eAllContents.filter(AnimBlock).toMap([ab|ab.name], [ab|ab.objType]);
		
		checkTouchesExpressions(prog, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames);
		checkArithmeticExpressions(prog, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames);
	}

	/**
	 * Checks of all touches expressions are type correct (of type object).
	 */
	def private checkTouchesExpressions(Prog prog, Map<String, String> anims, Map<String, String> simpleObjs, 
							Map<String, String> arrayObjs, Set<String> simpleVarNames, Set<String> arrayVarNames) {
		for (Decl d : prog.decls) {
			for (Touches t : d.eAllContents.toIterable.filter(Touches)) {
				checkTouchesExpression(t, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames);
			}
		}
		for (Touches t : prog.stmtBlock.eAllContents.toIterable.filter(Touches)) {
			checkTouchesExpression(t, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames);
		}
		for (EventBlock eb : prog.blocks.filter(EventBlock)) {
			for (Touches t : eb.eAllContents.toIterable.filter(Touches)) {
				checkTouchesExpression(t, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames);
			}
		}

		for (AnimBlock aBlock : prog.blocks.filter(AnimBlock)) {
			var Map<String, String> animObjects = new HashMap<String, String>(simpleObjs);
			animObjects.put(aBlock.objName, aBlock.objType);
			for (Touches t : aBlock.eAllContents.toIterable.filter(Touches)) {
				checkTouchesExpression(t, anims, animObjects, arrayObjs, simpleVarNames, arrayVarNames);
			}
		}
	}

	/**
	 * Checks if both operands of a touches expression are of type object.
	 */
	def private checkTouchesExpression(Touches touches, Map<String, String> anims, Map<String, String> simpleObjs, 
							Map<String, String> arrayObjs, Set<String> simpleVarNames, Set<String> arrayVarNames) {
		var String type = resolveType(touches.left, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames);
		if (!OBJECT_TYPES.contains(type)) {
			error('Type mismatch: cannot convert from ' + type + ' to Object', touches, MGPLPackage.Literals.TOUCHES__LEFT);
		}
		type = resolveType(touches.right, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames);
		if (!OBJECT_TYPES.contains(type)) {
			error('Type mismatch: cannot convert from ' + type + ' to Object', touches, MGPLPackage.Literals.TOUCHES__RIGHT);
		}
	}

	/**
	 * Checks of all arithmetic expressions are type correct (of type int).
	 * Only need to check Operations and UnaryOperations.
	 */
	def private checkArithmeticExpressions(Prog prog, Map<String, String> anims, Map<String, String> simpleObjs, 
							Map<String, String> arrayObjs, Set<String> simpleVarNames, Set<String> arrayVarNames) {
		for (Operation op : prog.eAllContents.toIterable.filter(Operation)) {
			checkArithmeticType(op.left, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames, op, MGPLPackage.Literals.OPERATION__LEFT);
			checkArithmeticType(op.right, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames, op, MGPLPackage.Literals.OPERATION__RIGHT);
		}

		for (UnaryOperation op : prog.eAllContents.toIterable.filter(UnaryOperation)) {
			checkArithmeticType(op.expr, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames, op, MGPLPackage.Literals.UNARY_OPERATION__EXPR);
		}
	}
	
	/**
	 * Checks if both operands of an arithmetic expression are of type int.
	 */
	def private checkArithmeticType(Expr expr, Map<String, String> anims, Map<String, String> simpleObjs, 
							Map<String, String> arrayObjs, Set<String> simpleVarNames, Set<String> arrayVarNames,
							EObject obj, EReference ref) {
		var String type = resolveType(expr, anims, simpleObjs, arrayObjs, simpleVarNames, arrayVarNames);
		if (type != "int") {
			error('Type mismatch: cannot convert from ' + type + ' to int', obj, ref);
		}
	}


	/**
	 * TASK 4: Attributes
	 * Only certain attributes are allowed for the different objects. These are as follows:
	 * - game: height, width,speed,x,y
	 * - circle: animation_block,radius,visible,x,y
	 * - rectangle, triangle: animation_block,height,visible,width,x,y
	 *
	 * Instead of the attribute names height, radius, width, the short forms h, r, w 
	 * are also permissible. Within an attribute declaration part, each allowed attribute 
	 * must occur at most once. Program attributes, ie attributes of game, may only be 
	 * initialized with constants in the attribute declaration section.
	 * 
	 * Illegal attribute values ​​(e.g., h = -10) are handled at run time. Only for the 
	 * program attribute speed should a value between 0 and 100 be ensured (0 slowest 
	 * gameplay, 100 fastest gameplay, default 50).
	 */
	
	/**
	 * Checks if all game attributes are assigned with constants. Checks if the value of 
	 * the attribute speed is between 0 and 100.
	 */
	@Check
	def checkProgramAttributes(Prog prog) {
		checkObjAttrList("game", prog.attrAssList, GAME_ATTRIBUTES, GAME_ATTRIBUTES_SHORT);

		for (AttrAss attrAss : prog.attrAssList.attrList) {
			if (!(attrAss.expr instanceof Numeric)) {
				error('Game attributes have to be assigned only with constants', attrAss,
					MGPLPackage.Literals.ATTR_ASS__EXPR);
			} else {
				var int numeric = (attrAss.expr as Numeric).numeric;
				if (attrAss.name == 'speed' && (numeric < 0 || numeric > 100)) {
					error('Game speed value has to be between 0 and 100', attrAss, MGPLPackage.Literals.ATTR_ASS__EXPR);
				}
			}
		}
	}

	/**
	 * Checks all attribute assignments of an object declaration.
	 */
	@Check
	def checkObjectAttributes(SimpleObjDecl sod) {
		switch sod.objType {
			case "circle":
				checkObjAttrList("circle", sod.attrAssList, CIRCLE_ATTRIBUTES, CIRCLE_ATTRIBUTES_SHORT)
			case "rectangle",
			case "triangle":
				checkObjAttrList("triangle", sod.attrAssList, RECTANGLE_TRIANGLE_ATTRIBUTES,
					RECTANGLE_TRIANGLE_ATTRIBUTES_SHORT)
		}
	}
	
	/**
	 * Checks if no object attribute is assigned more than once in constructor and if the 
	 * object has an appropriate attribute.
	 */
	def private checkObjAttrList(String obj, AttrAssList aas, String[] names, String[] shortNames) {
		var HashSet<String> attrs = new HashSet<String>();
		for (AttrAss aa : aas.attrList) {
			if (!names.contains(aa.name) && !shortNames.contains(aa.name)) {
				error('Unknown attribute ' + aa.name + '. For ' + obj + " are only " + Arrays.toString(names) +
					" allowed.", aa, MGPLPackage.Literals.ATTR_ASS__NAME);
			}
			var boolean lName = !attrs.add(longName(aa.name));
			var boolean sName = !attrs.add(shortName(aa.name)) && shortName(aa.name) != aa.name;
			if (lName || sName) {
				error('Attribute ' + aa.name + " already assigned", aa, MGPLPackage.Literals.ATTR_ASS__NAME);
			}
		}
	}

	/**
	 * If the given attribute name is a abbreviation the long name will be returned, 
	 * otherwise the string itself.
	 */
	def private longName(String s) {
		switch s {
			case "w": return "width"
			case "h": return "height"
			case "r": return "radius"
		}
		return s
	}

	/**
	 * If the given attribute name has an optional abbreviation the abbreviation will be returned, 
	 * otherwise the string itself.
	 */
	def private shortName(String s) {
		switch s {
			case "width": return "w"
			case "height": return "h"
			case "radius": return "r"
		}
		return s
	}

	/**
	 * Returns a set of the names of all simple variables of type int.
	 */
	def private getSimpleVariables(Prog prog) {
		return prog.eAllContents.toSet.filter(SimpleVarDecl).map[v|v.name].toSet;
	}

	/**
	 * Returns a set of the names of all variables of type int[].
	 */
	def private getArrayVariables(Prog prog) {
		return prog.eAllContents.toSet.filter(ArrayVarDecl).map[v|v.name].toSet;
	}
}
