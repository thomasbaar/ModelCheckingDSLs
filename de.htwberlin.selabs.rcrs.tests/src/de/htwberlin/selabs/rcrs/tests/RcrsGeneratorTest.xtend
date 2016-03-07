package de.htwberlin.selabs.rcrs.tests

import com.google.inject.Inject
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.TemporaryFolder
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.xbase.compiler.CompilationTestHelper
import org.eclipse.xtext.xbase.lib.util.ReflectExtensions
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

//  NOTE: requires MANIFEST-Dependency to org.eclipse.xtext.xbase.junit (already per default)
//  NOTE: requires MANIFEST-Dependency to org.eclipse.jdt.core
//  NOTE: requires to setup RuntimeModule.java correctly  // not needed any longer

@RunWith(typeof(XtextRunner))
@InjectWith(typeof(RcrsDslInjectorProvider))
class RcrsGeneratorTest {
	
	@Rule
	@Inject public TemporaryFolder temporaryFolder
	
	@Inject extension CompilationTestHelper
	@Inject extension ReflectExtensions

	@Test
	def void testGeneratedCode() {
		'''
		project justatest
types Cop Dad Boy(2)
 
// Boat - specification (always two places: driver + 1 passenger; driver always needed)
boat_drivers Cop Dad 
     
// dangerous situations for river side + boat
dangerous

BoysUnsafe : !Dad && Boy ;
		'''.assertCompilesTo(
		'''
mtype = { Cop, Dad, Boy, Boat};

#define DONE (r[Cop] == 1 && r[Dad] == 1 && r[Boy] == 2 && r[Boat] == 1)

#define BoysUnsafe (check[Dad] == 0 && check[Boy] == 1)

/* Global arrays, initially = 0 */
int r[5];  // who is currently on right river side
int check[5];  // auxiliary array for checking constraints
                          // check[Boat] is never used, but we do not know
                          // the index for Boat

mtype prev_dr   = 0;
mtype prev_pass = 0;

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
	r[person] = r[person] + (1-2*r[Boat]);  // adds 1 or -1, depending on r[Boat]==0  or == 1
}

inline flipBoat()
{
	r[Boat] = 1-r[Boat];
}

inline move(dr, pass)
{
  printMove(dr, pass, r[Boat]);
  if
      :: dr == prev_dr && pass == prev_pass -> skip;
    :: else ->
        update_r(); 
		copyL2Check();
        if          
        :: BoysUnsafe ->  
            /* undo move */
            update_r();   // here we need update_r() to be reversible
        :: else -> copyR2Check();
        		if
        		:: BoysUnsafe ->  
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
	check[Cop]=r[Cop];
	check[Dad]=r[Dad];
	check[Boy]=r[Boy];
	}
}

inline copyL2Check()
{
	atomic{
	check[Cop]=1-r[Cop];
	check[Dad]=1-r[Dad];
	check[Boy]=2-r[Boy];
	}
}

inline chooseDriver()
{
	if
		:: r[Boat] == 1 -> //boat on right side
		if
			:: r[Cop] > 0 -> driver=Cop;
			:: r[Dad] > 0 -> driver=Dad;
		fi;	
	:: else -> // boat on left side	
		if 
			:: r[Cop] < 1 -> driver=Cop;
			:: r[Dad] < 1 -> driver=Dad;
		fi;
	fi;
}

inline choosePassenger()
{
	if
		:: r[Boat] == 1 -> //boat on right side
			if 
				:: r[Cop] > 0 && driver != Cop -> passenger=Cop;
				:: r[Dad] > 0 && driver != Dad -> passenger=Dad;
				:: r[Boy] > 0 -> passenger=Boy;
				:: true -> passenger=0;
			fi;
		:: else -> // boat on left side	
			if 
				:: r[Cop] < 1 && driver != Cop -> passenger=Cop;
				:: r[Dad] < 1 && driver != Dad -> passenger=Dad;
				:: r[Boy] < 2 -> passenger=Boy;
				:: true -> passenger=0;
			fi;
	fi;	
}

inline checkBoatCrew(){
	
	resetCheck();
	check[driver]=1;
	check[passenger]=1;
	
	if 
		:: BoysUnsafe -> isBoatCrewOk=0;
		:: else -> isBoatCrewOk=1;
	fi;
}


inline resetCheck(){
	atomic{
	check[1]=0;
	check[2]=0;
	check[3]=0;
	check[4]=0;
	}
}

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
''')
	}



}