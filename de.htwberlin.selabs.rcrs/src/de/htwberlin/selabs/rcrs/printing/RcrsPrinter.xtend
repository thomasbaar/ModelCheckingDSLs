package de.htwberlin.selabs.rcrs.printing

import de.htwberlin.selabs.rcrs.rcrsDsl.Fml
import de.htwberlin.selabs.rcrs.rcrsDsl.AndFml
import de.htwberlin.selabs.rcrs.rcrsDsl.Neg
import de.htwberlin.selabs.rcrs.rcrsDsl.Plain
import de.htwberlin.selabs.rcrs.rcrsDsl.OrFml
import de.htwberlin.selabs.rcrs.rcrsDsl.Compound

class RcrsPrinter {
		def String stringRepr(Fml t, String arr) {
		switch (t) {
			OrFml: '''«t.left.stringRepr(arr)» || «t.right.stringRepr(arr)»'''
			AndFml: '''«t.left.stringRepr(arr)» && «t.right.stringRepr(arr)»'''
			Neg: '''«arr»[«t.nv.name»] == 0'''
			Plain: '''«arr»[«t.v.name»] == 1'''
			Compound: '''(«t.t.stringRepr(arr)»)'''
		}
	}

	
}