package org.xtext.vuc.mgpl.generator.java

class Game {
	static def game(String packageName) '''
		package «packageName»;
		
		import javafx.collections.FXCollections;
		import javafx.collections.ObservableList;
		import javafx.scene.shape.Shape;
		
		/**
		 * This is an abstract superclass for all games.
		 */
		public abstract class Game {
			private int speed = 50;
			
			/** The name of the game. */
			protected String name;
			
			/**
			 * A list of all object shapes.
			 */
			protected ObservableList<Shape> shapes = FXCollections.observableArrayList();
			
			public Game(String name) {
				this.name = name;
			}
			
			public Game(String name, int speed) {
				this(name);
				this.speed = speed;
			}
			
			public int getSpeed() {
				return speed;
			}
			
			public void setSpeed(int speed) {
				this.speed = speed;
			}
			
			public String getName() {
				return name;
			}
			
			public void setName(String name) {
				this.name = name;
			}
			
			public ObservableList<Shape> getShapes() {
				return shapes;
			}
			
			public void spacePressed(){};
			
			public void leftarrowPressed(){};
			
			public void rightarrowPressed(){};
			
			public void uparrowPressed(){};
			
			public void downarrowPressed(){};
			
			public abstract void runAnimations();
		}
	'''
}