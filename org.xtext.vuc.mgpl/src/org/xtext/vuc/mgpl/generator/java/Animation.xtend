package org.xtext.vuc.mgpl.generator.java

class Animation {
	static def animation(String packageName) '''
		package «packageName»;
		
		import «packageName».object.MGPLObject;
		
		/**
		 * Interface for all animations.
		 */
		public interface Animation {
			void run(MGPLObject mgplObject);
		}
	'''
}