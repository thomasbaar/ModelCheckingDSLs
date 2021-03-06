/*
 * generated by Xtext 2.9.0
 */
package de.htwberlin.selabs.rcrs.generator


import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import de.htwberlin.selabs.rcrs.rcrsDsl.RcrsModel
import de.htwberlin.selabs.rcrs.printing.RcrsPrinter
import com.google.inject.Inject
import de.htwberlin.selabs.rcrs.rcrsDsl.Type


/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class RcrsDslGenerator extends AbstractGenerator {

	@Inject extension RcrsPrinter

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		fsa.generateFile('lastGenerated.pml',// '//res-name' + resource.URI + '\n\n' +
			compile(resource.allContents
				.filter(typeof(RcrsModel)).head))
	}
	
	def compile(RcrsModel model){
		  model.tMType  // prefix 't' means 'target'
		+ model.tDefineDONE
		+ model.tDefineConstraints
		+ model.tGlobalArrays
		+ model.tLocalVars
		+ model.tInlinePrintMove
		+ model.tInlineUpdateRAndFlips
		+ model.tInlineMoveAndCopies
		+ model.tInlineChooseDriver
		+ model.tInlineChoosePassenger
		+ model.tInit
	}
	
	
	
	// constants
	val boat='Boat'
	
	def String tMType(RcrsModel model){
		val types = model.td.types
		'''
		mtype = { «types.map[name].join(', ')», «boat»};
		
		'''
	}
	
	private def  hasNumberAttached(Type type){
		type.num!=0
	}
	
	/**
	 * returns 1 for types having no number attached
	 */
	private def  getNormalizedNumber(Type type){
		if (type.hasNumberAttached) type.num else 1
	}
	
	
	
	def String tDefineDONE(RcrsModel model){
		val types = model.td.types
		
		'''
		#define DONE («types.map['r['+name+'] == '+normalizedNumber ].join(' && ')» && r[«boat»] == 1)

		'''
	}
	
	def String tDefineConstraints(RcrsModel model){
		val constraints = model.dd.constraints
		
		constraints.map['#define ' + name + ' (' + body.stringRepr('check') + ')'].join('\n') +
		'''


		'''
	}
	
	def String tGlobalArrays(RcrsModel model){
		val typesSize = model.td.types.size
		'''
		/* Global arrays, initially = 0 */
		int r[«typesSize+2»];  // who is currently on right river side
		int check[«typesSize+2»];  // auxiliary array for checking constraints
		                          // check[«boat»] is never used, but we do not know
		                          // the index for «boat»

		'''
	}
	
	def String tLocalVars(RcrsModel model){
		'''
		mtype prev_dr   = 0;
		mtype prev_pass = 0;
		
		'''
	}

	def String tInlinePrintMove(RcrsModel model){
		'''
inline printMove(driver, passenger, boat)
{
    if
        :: boat == 0 ->
            if
            :: passenger == 0 ->
                printf("%e goes there alone.\n", driver); 
            :: else  ->   
                printf("%e with %e go there.\n", driver, passenger); 
            fi;    
        :: else ->
            if
            :: passenger == 0 ->
                printf("%e goes back alone.\n", driver); 
            :: else  ->   
                printf("%e with %e go back.\n", driver, passenger); 
            fi;    
    fi;  
}

		'''
	}
	
	def String tInlineUpdateRAndFlips(RcrsModel model){
		'''
// note that update_r() is reversible: when executed twice, it results in the same state
inline update_r()
{
	atomic{
  flipPerson(driver);
  flipPerson(passenger);  // even if passenger = 0, it works since the r[0] place does not matter
  
  flipBoat(); // has to be done as last step
  }
}

inline flipPerson(person)
{
	r[person] = r[person] + (1-2*r[«boat»]);  // adds 1 or -1, depending on r[«boat»]==0  or == 1
}

inline flipBoat()
{
	r[«boat»] = 1-r[«boat»];
}

		'''
	}	
	
	def String tInlineMoveAndCopies(RcrsModel model){
		val constraints = model.dd.constraints
		val types = model.td.types
		
	
		'''
inline move(dr, pass)
{
  printMove(dr, pass, r[«boat»]);
  if
      :: dr == prev_dr && pass == prev_pass -> skip;
    :: else ->
        update_r(); 
		copyL2Check();
        if          
        :: «constraints.map[name].join(' || ')» ->  
            /* undo move */
            update_r();   // here we need update_r() to be reversible
        :: else -> copyR2Check();
        		if
        		:: «constraints.map[name].join(' || ')» ->  
            		/* undo move */
            		update_r();  
         		:: else ->          
            		prev_dr = dr; prev_pass = pass;
        		fi;
        fi;
  fi;   
}


inline copyR2Check()
{
	atomic{
	check[0]=r[0];
	«FOR type : types»
	check[«type.name»]=r[«type.name»];
	«ENDFOR»
	}
}

inline copyL2Check()
{
	atomic{
	«FOR type : types»
	check[«type.name»]=«type.normalizedNumber»-r[«type.name»];
	«ENDFOR»
	}
}

		'''
	}	

	def String tInlineChooseDriver(RcrsModel model){
		val drivers = model.bd.drivers
		
	
		'''
inline chooseDriver()
{
	if
		:: r[«boat»] == 1 -> //boat on right side
		if
			«FOR type : drivers»
			:: r[«type.name»] > 0 -> driver=«type.name»;
			«ENDFOR»			
		fi;	
	:: else -> // boat on left side	
		if 
			«FOR type : drivers»
			:: r[«type.name»] < «type.normalizedNumber» -> driver=«type.name»;
			«ENDFOR»			
		fi;
	fi;
}

		'''
	}
	
	
	def String tInlineChoosePassenger(RcrsModel model){
		val constraints = model.dd.constraints

		val types = model.td.types
		val drivers = model.bd.drivers
		val nondrivers = types.filter[t|!drivers.contains(t)]
	
		'''
inline choosePassenger()
{
	if
		:: r[«boat»] == 1 -> //boat on right side
			if 
				«FOR type : drivers»
				:: r[«type.name»] > 0 && driver != «type.name» -> passenger=«type.name»;
				«ENDFOR»							
				«FOR type : nondrivers»
				:: r[«type.name»] > 0 -> passenger=«type.name»;
				«ENDFOR»											
				:: true -> passenger=0;
			fi;
		:: else -> // boat on left side	
			if 
				«FOR type : drivers»
				:: r[«type.name»] < 1 && driver != «type.name» -> passenger=«type.name»;
				«ENDFOR»
				«FOR type : nondrivers»
				:: r[«type.name»] < «type.normalizedNumber» -> passenger=«type.name»;
				«ENDFOR»															
				:: true -> passenger=0;
			fi;
	fi;	
}

inline checkBoatCrew(){
	
	resetCheck();
	check[driver]=1;
	check[passenger]=1;
	
	if 
		:: «constraints.map[name].join(' || ')» -> isBoatCrewOk=0;
		:: else -> isBoatCrewOk=1;
	fi;
}


inline resetCheck(){
	atomic{
	«FOR i : 1..types.size+1»
		check[«i»]=0;
	«ENDFOR»							
	}
}

	'''
	}	


	def String tInit(RcrsModel model){
	
	'''
init {
    local mtype driver    = 0; 
    local mtype passenger = 0; 
    local int isBoatCrewOk = 0; //0 -> false; 1 -> true
  
    /* Run */    
    do
      :: true ->
    	chooseDriver();
    	choosePassenger();
    	checkBoatCrew();
    	if 
    		:: isBoatCrewOk==1 -> move(driver, passenger);
    		:: else -> skip;
    	fi;	
  
      :: DONE -> printf("SOLVED\n"); assert(0); break;
    od;    
}
	'''
	}			
}	

