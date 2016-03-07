package de.htwberlin.selabs.pml.validation

import org.eclipse.emf.ecore.EReference
import com.google.inject.Inject
import de.htwberlin.selabs.pml.typing.TermTypeProvider
import de.htwberlin.selabs.pml.pmlDsl.Fml
import de.htwberlin.selabs.pml.typing.TermType

/**
 * provides useful methods to be used in sub-classes
 */
class PmlDslValidatorHelper {

	@Inject extension TermTypeProvider
	@Inject  PmlDslValidator v

	def checkExpectedBoolean(Fml exp, EReference reference) {
		checkExpectedType(exp, TermTypeProvider::boolType, reference)
	}

	def checkExpectedInt(Fml exp, EReference reference) {
		checkExpectedType(exp, TermTypeProvider::intType, reference)
	}

	def protected checkExpectedType(Fml exp, TermType expectedType, EReference reference) {
		val actualType = getTypeAndCheckNotNull(exp, reference)
		if (actualType != expectedType)
			v.perror("expected " + expectedType + " type, but was " + actualType, reference, PmlDslValidator::WRONG_TYPE)
	}

	def protected TermType getTypeAndCheckNotNull(Fml exp, EReference reference) {
		var type = exp?.typeFor
		if (type == null)
			v.perror("null type", reference, PmlDslValidator::WRONG_TYPE)
		return type;
	}

}