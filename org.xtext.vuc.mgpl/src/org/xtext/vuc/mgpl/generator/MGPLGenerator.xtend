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
import org.xtext.vuc.mgpl.generator.java.MGPLJavaGenerator

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class MGPLGenerator extends AbstractGenerator {
	
	public static val String[] GAME_ATTRIBUTES = #["speed"];
	public static val String[] RECTANGLE_ATTRIBUTES = #["x", "y", "width", "height", "visible", "animation_block"];
	public static val String[] CIRCLE_ATTRIBUTES = #["x", "y", "radius", "visible", "animation_block"];
	public static val String[] TRIANGLE_ATTRIBUTES = #["x", "y", "width", "height", "visible", "animation_block"];
	
	public static val String PACKAGE_PATH = "com/xtext/vuc/mgpl/";
	
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		// initialize new Java code generator
		new MGPLJavaGenerator().doGenerate(resource, fsa, context);
	}
	
	def static shortNames(String s) {
		switch s {
			case "width": return "w"
			case "height": return "h"
			case "radius": return "r"
		}
		return null
	}
}
