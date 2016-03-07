package de.htwberlin.selabs.pml.typing

import de.htwberlin.selabs.pml.pmlDsl.OrFml
import de.htwberlin.selabs.pml.pmlDsl.Fml
import de.htwberlin.selabs.pml.pmlDsl.AndFml
import de.htwberlin.selabs.pml.pmlDsl.BoolConstant
import de.htwberlin.selabs.pml.pmlDsl.CompareFml
import de.htwberlin.selabs.pml.pmlDsl.PlusMinus
import de.htwberlin.selabs.pml.pmlDsl.MultDiv
import de.htwberlin.selabs.pml.pmlDsl.IntConstant
import de.htwberlin.selabs.pml.pmlDsl.Compound
import de.htwberlin.selabs.pml.pmlDsl.ArrAccess
import de.htwberlin.selabs.pml.pmlDsl.SymbolRef
import de.htwberlin.selabs.pml.pmlDsl.DFunc
import de.htwberlin.selabs.pml.pmlDsl.Symbol
import de.htwberlin.selabs.pml.pmlDsl.LVar
import de.htwberlin.selabs.pml.pmlDsl.Var
import de.htwberlin.selabs.pml.pmlDsl.Para

class TermTypeProvider {
	public static val intType = new IntType
	public static val boolType = new BoolType

	def dispatch TermType typeFor(Fml e) {
		switch (e) {
			OrFml: boolType
			AndFml: boolType
			CompareFml: boolType
			BoolConstant: boolType
			PlusMinus: intType
			MultDiv: intType
			IntConstant: intType
			Compound: e.t.typeFor
			ArrAccess: intType
			SymbolRef: e.sym.typeFor
		}
	}
	
	def dispatch TermType typeFor(Symbol e){
		if (e instanceof DFunc) boolType else intType
//		if (e.typeof(DFunc))  boolType else intType  // Strange: does not work 
	}

	def dispatch TermType typeFor(LVar e){
		intType
	}

	def dispatch TermType typeFor(Var e){
		intType
	}

	def dispatch TermType typeFor(Para e){
		intType
	}


	def isInt(TermType type) { type == intType }

	def isBoolean(TermType type) { type == boolType }

}