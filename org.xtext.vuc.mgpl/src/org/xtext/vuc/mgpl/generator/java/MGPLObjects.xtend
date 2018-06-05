package org.xtext.vuc.mgpl.generator.java

import org.eclipse.xtext.generator.IFileSystemAccess2

class MGPLObjects {
	
	def doGenerate(IFileSystemAccess2 fsa, String packagePath, String packageName) {
		fsa.generateFile(packagePath + "object/MGPLObject.java", mgplObject(packageName))
		fsa.generateFile(packagePath + "object/MGPLCircle.java", mgplCircle(packageName))
		fsa.generateFile(packagePath + "object/MGPLRectangle.java", mgplRectangle(packageName))
		fsa.generateFile(packagePath + "object/MGPLTriangle.java", mgplTriangle(packageName))
	}
	
	def mgplObject(String packageName) '''
		package «packageName».object;
		
		import javafx.scene.shape.Shape;
		
		import «packageName».Animation;
		
		public abstract class MGPLObject {
			/** Shape to handle collision detection. */
			protected Shape shape;
			
			/** Animation handler. */
			private Animation animation;
			
			public MGPLObject() {}
			
			abstract int getX();
			
			abstract void setX(int x);
			
			abstract int getY();
			
			abstract void setY(int y);
			
			public Shape getShape() {
				return shape;
			}
			
			public boolean isVisible() {
				return shape.isVisible();
			}
			
			public void setVisible(boolean visible) {
				shape.setVisible(visible);
			}
			
			public Animation getAnimationBlock() {
				return animation;
			}
			
			public void setAnimationBlock(Animation animation) {
				this.animation = animation;
			}
			
			public boolean touches(MGPLObject m) {
				// Collision detection
				return Shape.intersect(this.shape, m.getShape()).getBoundsInLocal().getWidth() != -1;
			}
			
			public void runAnimation() {
				if (animation != null) {
					animation.run(this);
				}
			}
		}
	'''
	
	def mgplCircle(String packageName) '''
		package «packageName».object;
		
		import javafx.scene.shape.Circle;
		
		import «packageName».Animation;
		
		/**
		 * Class to represent a circle. The x and y values are interpreted as the 
		 * center of the circle.
		 */
		public class MGPLCircle extends MGPLObject {
			public MGPLCircle() {
			    shape = new Circle();
			    shape.setVisible(true);
			}
			
			public MGPLCircle(int x, int y, int radius) {
				this();
				setX(x);
				setY(y);
				setRadius(radius);
			}
			
			public MGPLCircle(int x, int y, int radius, boolean visible) {
				this(x, y, radius);
				setVisible(visible);
			}
			
			public MGPLCircle(int x, int y, int radius, Animation animation) {
				this(x, y, radius);
				setAnimationBlock(animation);
			}
			
			public MGPLCircle(int x, int y, int radius, boolean visible, Animation animation) {
				this(x, y, radius, visible);
				setAnimationBlock(animation);
			}
			
			@Override
			public int getX() {
			    return (int) ((Circle)shape).getCenterX();
			}
			
			@Override
			public void setX(int x) {
			    ((Circle)shape).setCenterX(x);
			}
			
			@Override
			public int getY() {
			    return (int) ((Circle)shape).getCenterY();
			}
			
			@Override
			public void setY(int y) {
			    ((Circle)shape).setCenterY(y);
			}
			
			public int getRadius() {
				return (int) ((Circle)shape).getRadius();
			}
			
			public void setRadius(int radius) {
				((Circle)shape).setRadius(radius);
			}
		}
	'''
	
	def mgplRectangle(String packageName) '''
		package «packageName».object;
		
		import javafx.scene.shape.Rectangle;
		
		import «packageName».Animation;
		
		/**
		 * Class to represent a rectangle. The x and y values are interpreted as the 
		 * center of the rectangle.
		 */
		public class MGPLRectangle extends MGPLObject {
			
			public MGPLRectangle() {
			    shape = new Rectangle();
			    shape.setVisible(true);
			}
			
			public MGPLRectangle(int x, int y, int width, int height) {
				this();
				setX(x);
				setY(y);
				setWidth(width);
				setHeight(height);
			}
			
			public MGPLRectangle(int x, int y, int width, int height, boolean visible) {
				this(x, y, width, height);
				setVisible(visible);
			}
			
			public MGPLRectangle(int x, int y, int width, int height, Animation animation) {
				this(x, y, width, height);
				setAnimationBlock(animation);
			}
			
			public MGPLRectangle(int x, int y, int width, int height, boolean visible, Animation animation) {
				this(x, y, width, height, visible);
				setAnimationBlock(animation);
			}
			
			@Override
			public int getX() {
			    return (int) ((Rectangle)shape).getX();
			}
			
			@Override
			public void setX(int x) {
			    ((Rectangle)shape).setX(x);
			}
			
			@Override
			public int getY() {
			    return (int) ((Rectangle)shape).getY();
			}
			
			@Override
			public void setY(int y) {
			    ((Rectangle)shape).setY(y);
			}
			
			public int getHeight() {
				return (int) ((Rectangle)shape).getHeight();
			}
			
			public void setHeight(int height) {
				((Rectangle)shape).setHeight(height);
			}
			
			public int getWidth() {
				return (int) ((Rectangle)shape).getWidth();
			}
			
			public void setWidth(int width) {
				((Rectangle)shape).setWidth(width);
			}
		}
	'''
	
	def mgplTriangle(String packageName) '''
		package «packageName».object;
		
		import javafx.collections.ObservableList;
		import javafx.scene.shape.Polygon;
		
		import «packageName».Animation;
		
		/**
		 * Class to represent a triangle. The x and y values are interpreted as 
		 * the upper left corner of the triangle.
		 */
		public class MGPLTriangle extends MGPLRectangle {
			/**
			 * Need to save the x, y values and width and height because there is no triangle 
			 * class for JavaFX.
			 */
		    private int x, y;
		    private int width, height;
			
			public MGPLTriangle() {
			    shape = new Polygon();
			    shape.setVisible(true);
			}
			
			public MGPLTriangle(int x, int y, int width, int height) {
				this();
				this.x = x;
				this.y = y;
				this.width = width;
				this.height = height;
				this.drawTriangle();
			}
			
			public MGPLTriangle(int x, int y, int width, int height) {
				this(x, y, width, height);
				setVisible(visible);
				this.drawTriangle();
			}
			
			public MGPLTriangle(int x, int y, int width, int height, Animation animation) {
				this(x, y, width, height);
				setAnimationBlock(animation);
			}
			
			public MGPLTriangle(int x, int y, int width, int height, boolean visible, Animation animation) {
				this(x, y, width, height, visible);
				setAnimationBlock(animation);
			}
			
			@Override
			public int getX() {
			    return x;
			}
			
			@Override
			public void setX(int x) {
			    this.x = x;
			    this.drawTriangle();
			}
			
			@Override
			public int getY() {
			    return y;
			}
			
			@Override
			public void setY(int y) {
			    this.y = y;
			    this.drawTriangle();
			}
			
			public int getHeight() {
				return height;
			}
			
			public void setHeight(int height) {
			    this.height = height;
			    this.drawTriangle();
			}
			
			public int getWidth() {
				return width;
			}
			
			public void setWidth(int width) {
			    this.width = width;
			    this.drawTriangle();
			}
			
			/**
			 * Clears the current shape of the triangle and recalculates it.
			 */
			private void drawTriangle() {
				if (this.width == 0 || this.height == 0) return;
				ObservableList<Double> points = ((Polygon) shape).getPoints();
				// Clear current shape of the triangle.
				points.clear();
				
				// Triangle points downwards
				// Upper left corner
				double x1 = this.x;
				double y1 = this.y;
				
				// Low corner
				double x2 = this.x + this.width / 2;
				double y2 = this.y + this.height;
				
				// Upper right corner
				double x3 = this.x + this.width;
				double y3 = this.y;
				points.addAll(x1, y1, x2, y2, x3, y3);
			}
		}
	'''
}