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
        class MGPLObject:
            
            def __init__(self, x=0, y=0, visible=True, animation_block=None):
                self.x = x
                self.y = y
                self.animation_block = animation_block
                self.visible = visible
                self.shape = None
            
            def touches(self, mgpl_obj):
                """Collision detection
                """
ллл                point_in_poly(gon)?
ллл                return Shape.intersect(this.shape, m.getShape()).getBoundsInLocal().getWidth() != -1;
                return True
            
            def run_animation(self):
                if self.animation_block is not None:
                    self.animation_block(self)
        
    '''
    
    def mgplCircle(String packageName) '''
        from com.xtext.vuc.mgpl.object.mgpl_object import MGPLObject
        
        
        class MGPLCircle(MGPLObject):
            """Class to represent a circle. The x and y values are interpreted as the center of the circle.
            """
            
            def __init__(self, x=0, y=0, radius=10, visible=True, animation_block=None):
                super().__init__(x, y, visible, animation_block)
ллл                self.shape = circle
                self.radius = radius
    '''
    
    def mgplRectangle(String packageName) '''
        from com.xtext.vuc.mgpl.object.mgpl_object import MGPLObject
        
        
        class MGPLRectangle(MGPLObject):
            """Class to represent a rectangle. The x and y values are interpreted as the 
               center of the rectangle.
            """
            
            def __init__(self, x=0, y=0, width=100, height=100, visible=True, animation_block=None):
                super().__init__(x, y, visible, animation_block)
                self.width = width
                self.height = height
    '''
    
    def mgplTriangle(String packageName) '''
        from com.xtext.vuc.mgpl.object.mgpl_object import MGPLObject
        
        
        class MGPLTriangle(MGPLObject):
            """Class to represent a triangle. The x and y values are interpreted as the upper left corner of the triangle.
            """
            
            def __init__(self, x=0, y=0, width=100, height=100, visible=True, animation_block=None):
                super().__init__(x, y, visible, animation_block)
                self.width = width
                self.height = height
        
ллл            /**
ллл             * Clears the current shape of the triangle and recalculates it.
ллл             */
ллл            private void drawTriangle() {
ллл                if (this.width == 0 || this.height == 0) return;
ллл                ObservableList<Double> points = ((Polygon) shape).getPoints();
ллл                // Clear current shape of the triangle.
ллл                points.clear();
ллл                
ллл                // Triangle points downwards
ллл                // Upper left corner
ллл                double x1 = this.x;
ллл                double y1 = this.y;
ллл                
ллл                // Low corner
ллл                double x2 = this.x + this.width / 2;
ллл                double y2 = this.y + this.height;
ллл                
ллл                // Upper right corner
ллл                double x3 = this.x + this.width;
ллл                double y3 = this.y;
ллл                points.addAll(x1, y1, x2, y2, x3, y3);
ллл            }
    '''
}