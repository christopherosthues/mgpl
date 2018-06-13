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
package org.xtext.vuc.mgpl.generator.python

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.xtext.vuc.mgpl.mGPL.AnimBlock
import org.xtext.vuc.mgpl.mGPL.ArrayObjDecl
import org.xtext.vuc.mgpl.mGPL.ArrayVarDecl
import org.xtext.vuc.mgpl.mGPL.AssStmt
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

import static org.xtext.vuc.mgpl.generator.MGPLGenerator.*

/**
 * Generates Python code from the model files.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class MGPLPythonGenerator extends AbstractGenerator {
    
    private static val String PYTHON_PACKAGE_PATH = "python/" + PACKAGE_PATH;
    public static val String FILE_EXTENSION = ".py";
    
    private val String packageName = "com.xtext.vuc.mgpl";
    private var String programName;
    
    override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
    	new MGPLObjects().doGenerate(fsa, PYTHON_PACKAGE_PATH, packageName)
        for (prog : resource.allContents.toIterable.filter(Prog)) {
            var String gameName = prog.name.toLowerCase;
            
            programName = naming(prog.name).toFirstUpper
            fsa.generateFile(PYTHON_PACKAGE_PATH + gameName + "/" + programName.toFirstLower + FILE_EXTENSION, prog.compile())
            fsa.generateFile(PYTHON_PACKAGE_PATH + gameName + "/ui/" + programName.toFirstLower + '_ui' + FILE_EXTENSION, prog.gameUI());
        }
    }
    
    def gameUI(Prog prog) '''
        import pygame
        import sys
        from «packageName».«naming(prog.name).toFirstLower» import «programName»
        
        
        def main():
            game = «programName»(«prog.attrAssList.compile»)
            pygame.init()
            clock = pygame.time.Clock()
            
            fps = 50 * 1 / game.speed
            bg = [255, 255, 255]
            size = [game.width, game.height]
            
            screen = pygame.display.set_mode(size)
            
            while True:
                for event in pygame.event.get():
                    if event.type == pygame.QUIT:
                        return False
                
                key = pygame.key.get_pressed()
                
                «FOR event : prog.blocks.filter(EventBlock)»
                if key[pygame.«getKeyStroke(event.key)»]:
                    game.«event.key»_pressed()
                «ENDFOR»
                
                screen.fill(bg)
«««                TODO: draw objects
                pygame.display.update()
                clock.tick(fps)
            
            pygame.quit()
            sys.exit
        
        
        if __name__ == 'main':
            main()
    '''
    
    def naming(String s) {
        var String name = s;
        switch s {
            case "w": name = "width"
            case "h": name = "height"
            case "r": name = "radius"
        }
        return name;
    }
    
    def getKeyStroke(String key) {
        switch key {
            case "space": return "K_SPACE"
            case "leftarrow": return "K_LEFT"
            case "rightarrow": return "K_RIGHT"
            case "uparrow": return "K_UP"
            case "downarrow": return "K_DOWN"
        }
    }
    
    def compile(Prog prog) '''
        from «packageName».object.mgpl_rectangle import MGPLRectangle
        from «packageName».object.mgpl_triangle import MGPLTriangle
        from «packageName».object.mgpl_circle import MGPLCircle
        
        
        class «programName»:
            
            def __init__(self, x=0, y=0, height=100, width=100, speed=50):
                self.x = x
                self.y = y
                self.height = height
                self.width = width
                self.speed = speed
                «FOR decl : prog.decls»
                «decl.compile»
                «ENDFOR»
                «FOR mgplObj : prog.decls.filter(ArrayObjDecl)»
                «var String mgplName = naming(mgplObj.name)»
                for «mgplName»_i in range(len(self.«mgplName»)):
                    self.«mgplName»[i] = «getObjType(mgplObj.objType)»()
                «ENDFOR»
                «prog.stmtBlock.compile»
            
            def run_animations(self):
                «FOR mgplObj : prog.decls.filter(SimpleObjDecl)»
                self.«naming(mgplObj.name)».run_animation()
                «ENDFOR»
                «FOR mgplObj : prog.decls.filter(ArrayObjDecl)»
                for obj in self.«naming(mgplObj.name)»:
                    obj.run_animation()
                «ENDFOR»
            «FOR eventBlock : prog.blocks.filter(EventBlock)»
            «eventBlock.compile»
            «ENDFOR»
            «FOR animBlock : prog.blocks.filter(AnimBlock)»
            «animBlock.compile»
            «ENDFOR»
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
        self.«naming(decl.name)»«IF decl.init !== null» = «decl.init.compile»«ENDIF»'''
    
    def compile(ArrayVarDecl decl) '''
        «arrayInit("0", naming(decl.name), decl.len)»'''
    
    def compile(SimpleObjDecl decl) '''
        «var objType = getObjType(decl.objType)»
        self.«naming(decl.name)» = «objType»(«decl.attrAssList.compile»)'''
        
    def compile(ArrayObjDecl decl) '''
        «arrayInit("None", naming(decl.name), decl.len)»'''
    
    def arrayInit(String type, String name, int len) '''
        self.«name» = [«type»]*«len»'''
    
    def getObjType(String type) {
        switch type {
            case "rectangle": return "MGPLRectangle"
            case "triangle": return "MGPLTriangle"
            case "circle": return "MGPLCircle"
        }
    }
    
    def compile(AttrAssList aal) '''
        «FOR aa : aal.attrList SEPARATOR ','»«naming(aa.name)»=«attributeValue(aa.name, aa.expr.compile.toString)»«ENDFOR»'''
    
    def attributeValue(String attributeName, String value) {
    	if (attributeName == "animation_block") {
    		return naming(value) + "()";
    	} else if (attributeName == "visible") {
    		return "bool(" + value + ")";
    	} else {
    		return value;
    	}
    }

    def compile(EventBlock eventBlock) '''
        
        def «eventBlock.key»_pressed(self):
            «eventBlock.stmtBlock.compile»
    '''
    
    def compile(AnimBlock animBlock) '''
        
        def «naming(animBlock.name)»(self, «naming(animBlock.objName)»):
            «animBlock.stmtBlock.compile»
    '''
    
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
            AssStmt: (stmt as AssStmt).compile
        }
    }
    
    def compile(IfStmt is) '''
        if «is.expr.compile»:
            «is.thenBlock.compile»
        «IF is.^else»
        else:
            «is.elseBlock.compile»
        «ENDIF»
    '''
    
    def compile(ForStmt fs) '''
        «fs.init.compile»
        while «fs.condition.compile»:
            «fs.loopBody.compile»
            «fs.counter.compile»
    '''
    
    def compile(AssStmt asStmt) '''
        «asStmt.^var.compile» = «asStmt.expr.compile»'''
    
    def compile(Var v) '''
        self«IF naming(v.name) != programName».«naming(v.name)»«ENDIF»«IF v.array»[«v.arrayAccess.compile»]«ENDIF»«IF v.access».«v.accName»«ENDIF»'''
    
    def compile(Expr expr) {
        switch expr {
            Operation: (expr as Operation).compile
            UnaryOperation: (expr as UnaryOperation).compile
            BracketExpr: (expr as BracketExpr).compile
            ExprAtomic: (expr as ExprAtomic).compile
        }
    }
    
    def compile(Operation op) '''
        «var rel = op.op == "||" || op.op == "&&"»«intToBoolean(op.left.compile.toString, rel)» «operation(op.op)» «intToBoolean(op.right.compile.toString, rel)»'''
    
    def operation(String op) {
    	switch op {
    		case "&&": return "and"
    		case "||": return "or"
    		case "!": return "not "
    	}
    	return op
    }
    
    def compile(UnaryOperation up) '''
        «operation(up.op)»«intToBoolean(up.expr.compile.toString, up.op == "!")»'''
        
    def intToBoolean(String expr, boolean rel) '''
        «IF rel»bool(«expr»)«ELSE»«expr»«ENDIF»'''
    
    def compile(BracketExpr be) '''
        («be.expr.compile»)'''
    
    def compile(ExprAtomic expr) {
        switch expr {
            Numeric: (expr as Numeric).compile
            Var: (expr as Var).compile
            Touches: (expr as Touches).compile
        }
    }
    
    def compile(Numeric numeric) '''
        «numeric.numeric»'''
    
    def compile(Touches touches) '''
        «touches.left.compile».touches(«touches.right.compile»)'''
}
