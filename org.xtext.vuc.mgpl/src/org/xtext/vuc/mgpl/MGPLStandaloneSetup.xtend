/*
 * generated by Xtext 2.12.0
 */
package org.xtext.vuc.mgpl


/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class MGPLStandaloneSetup extends MGPLStandaloneSetupGenerated {

	def static void doSetup() {
		new MGPLStandaloneSetup().createInjectorAndDoEMFRegistration()
	}
}