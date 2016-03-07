/*
 * generated by Xtext 2.9.0
 */
package de.htwberlin.selabs.rcrs.validation

import de.htwberlin.selabs.rcrs.rcrsDsl.Type
import de.htwberlin.selabs.rcrs.rcrsDsl.RcrsDslPackage
import org.eclipse.xtext.validation.Check
import de.htwberlin.selabs.rcrs.rcrsDsl.RcrsModel

import static extension org.eclipse.xtext.EcoreUtil2.*
/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class RcrsDslValidator extends AbstractRcrsDslValidator {
	
  public static val INVALID_NAME = 'invalidName'
  public static val WRONG_NUMBER = 'wrongNumber'
  public static val DRIVER_NO_NUMBER = 'driverNoNumber'

	@Check
	def checkNoBoatAsType(Type type) {
		if (type.name=='Boat') {
			error('"Boat" is not allowed as a type', 
					RcrsDslPackage.Literals.TYPE__NAME,
					INVALID_NAME)
		}
	}
	
	@Check
	def checkNumberGreaterTwo(Type type) {
		if (type.num!=0 && type.num<2) {
			error('Explicit number must be greater 1', 
					RcrsDslPackage.Literals.TYPE__NUM,
					WRONG_NUMBER)
		}
	}
	
	@Check
	def checkDriverHasNumber(Type type) {
		if (type.num!=0 && type.root.bd.drivers.contains(type)) {
			error('Drivers must NOT have an explicit number', 
					RcrsDslPackage.Literals.TYPE__NUM,
					DRIVER_NO_NUMBER)
		}
	}
	
		//TODO: move to util
	def getRoot(Type t) {
		t.getContainerOfType(typeof(RcrsModel))
	}
		
}
