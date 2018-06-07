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

import org.eclipse.xtext.generator.IFileSystemAccess2

import static org.xtext.vuc.mgpl.generator.python.MGPLPythonGenerator.FILE_EXTENSION

class MGPLObjects {
    
    def doGenerate(IFileSystemAccess2 fsa, String packagePath, String packageName) {
        fsa.generateFile(packagePath + 'object/mgpl_object' + FILE_EXTENSION, mgplObject(packageName))
        fsa.generateFile(packagePath + 'object/mgpl_circle' + FILE_EXTENSION, mgplCircle(packageName))
        fsa.generateFile(packagePath + 'object/mgpl_rectangle' + FILE_EXTENSION, mgplRectangle(packageName))
        fsa.generateFile(packagePath + 'object/mgpl_triangle' + FILE_EXTENSION, mgplTriangle(packageName))
    }
    
    def mgplObject(String packageName) '''
«««        import javafx.scene.shape.Shape;
        
«««        import «packageName».Animation;
        
        class MGPLObject {
            
            def __init__(self, x=0, y=0, visible=True, animation_block=None):
                self.x = x
                self.y = y
                self.animation_block = animation_block
                self.visible = visible
                self.shape = None
            
            
            def touches(self, MGPLObject m):
                \'\'\'Collision detection
                \'\'\'
«««                point_in_poly(gon)?
«««                return Shape.intersect(this.shape, m.getShape()).getBoundsInLocal().getWidth() != -1;
                return True
            
            
            def run_animation():
                if (self.animation_block != None):
                    self.animation_block.run(self)
        
    '''
    
    def mgplCircle(String packageName) '''
«««        package «packageName».object;
        
«««        import javafx.scene.shape.Circle;
        
«««        import «packageName».Animation;
        
        \'\'\'Class to represent a circle. The x and y values are interpreted as the center of the circle.
        \'\'\'
        class MGPLCircle(MGPLObject):
            
            def __init__(self, x=0, y=0, radius=10, visible=True, animation_block=None):
                super().__init__(x, y, visible, animation_block)
«««                self.shape = circle
                self.radius = radius
        
    '''
    
    def mgplRectangle(String packageName) '''
«««        package «packageName».object;
        
«««        import javafx.scene.shape.Rectangle;
        
«««        import «packageName».Animation;
        
        \'\'\'Class to represent a rectangle. The x and y values are interpreted as the 
          center of the rectangle.
        \'\'\'
        class MGPLRectangle(MGPLObject):
            
            def __init__(self, x=0, y=0, width=100, height=100, visible=True, animation_block=None):
                super().__init__(x, y, visible, animation_block)
                self.width = width
                self.height = height
        
    '''
    
    def mgplTriangle(String packageName) '''
«««        package «packageName».object;
        
«««        import javafx.collections.ObservableList;
«««        import javafx.scene.shape.Polygon;
        
«««        import «packageName».Animation;
        
        \'\'\'Class to represent a triangle. The x and y values are interpreted as the upper left corner of the triangle.
        \'\'\'
        class MGPLTriangle(MGPLRectangle):
            
            def __init__(self, x=0, y=0, width=100, height=100, visible=True, animation_block=None):
                super().__init__(x, y, visible, animation_block)
                self.width = width
                self.height = height
        
«««            /**
«««             * Clears the current shape of the triangle and recalculates it.
«««             */
«««            private void drawTriangle() {
«««                if (this.width == 0 || this.height == 0) return;
«««                ObservableList<Double> points = ((Polygon) shape).getPoints();
«««                // Clear current shape of the triangle.
«««                points.clear();
«««                
«««                // Triangle points downwards
«««                // Upper left corner
«««                double x1 = this.x;
«««                double y1 = this.y;
«««                
«««                // Low corner
«««                double x2 = this.x + this.width / 2;
«««                double y2 = this.y + this.height;
«««                
«««                // Upper right corner
«««                double x3 = this.x + this.width;
«««                double y3 = this.y;
«««                points.addAll(x1, y1, x2, y2, x3, y3);
«««            }
    '''
}