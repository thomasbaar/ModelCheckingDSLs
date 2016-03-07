// status: works correctly, with breadth-first



mtype = {Cop, Criminal, Mom, Dad, Girl, Boy, Boat};
 
#define DONE (r[Cop] == 1 && r[Criminal] == 1 &&  r[Mom] == 1 && r[Dad] == 1 &&  r[Girl] == 2 && r[Boy] == 2 && r[Boat] == 1)


#define CheckCriminalUnsafe (check[Criminal] == 1 && check[Cop] == 0 && (check[Mom] == 1 || check[Dad] == 1 || check[Boy] > 0 || check[Girl] > 0 ) )
#define CheckBoysUnsafe ( check[Mom] == 1 && check[Dad] == 0 && check[Boy] > 0)
#define CheckGirlsUnsafe ( check[Dad] == 1 && check[Mom] == 0 && check[Girl] > 0 )


/* Global array for positions, initially = 0 */
int r[8]; 
int check[8];  // auxiliary array to make the checking simpler


mtype prev_dr   = 0;
mtype prev_pass = 0;



inline printMove(driver, passenger, boat)
{
	// TB: this looks quite ugly (code duplication in then/else), but there seems
	// to be a lack of string-variables
    if
        :: boat == 0 ->
            if
            :: passenger == 0 ->
                printf("%e goes there alone.\n", driver); 
            :: else  ->   
//                printf("%e with %e %d go there.\n", driver, passenger, passenger); 
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
      :: dr == prev_dr && pass == prev_pass -> skip;  // same effect as printf()
                       // TODO: somehow we need the repetition detection and staying in the same 
                       // not fully understood yet
    :: else ->
        update_r(); 
		copyL2Check();
        if          
//        :: CriminalUnsafe || BoysUnsafe || GirlsUnsafe ->  
        :: CheckCriminalUnsafe || CheckBoysUnsafe || CheckGirlsUnsafe ->  
            /* undo move */
            update_r();   // here we need update_r() to be reversible
        :: else -> copyR2Check();
        		if
        		:: CheckCriminalUnsafe || CheckBoysUnsafe || CheckGirlsUnsafe ->  
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
	check[1]=r[1];
	check[2]=r[2];
	check[3]=r[3];
	check[4]=r[4];
	check[5]=r[5];
	check[6]=r[6];
	check[7]=r[7];
	}
}

inline copyL2Check()
{
	atomic{
//	check[0]=1-r[0];
	check[1]=1-r[1];
	check[2]=1-r[2];
	check[3]=1-r[3];
	check[4]=1-r[4];
	check[5]=1-r[5];
	check[6]=1-r[6];
	check[7]=1-r[7];
	
	check[Boy]=2-r[Boy];
	check[Girl]=2-r[Girl];
	}
}



inline chooseDriver()
{
	if
		:: r[Boat] == 1 -> //boat on right side
		if
			:: r[Cop] > 0 -> driver = Cop;
			:: r[Dad] > 0 -> driver = Dad;
			:: r[Mom] > 0 -> driver = Mom;
		fi;	
	:: else -> // boat on left side	
		if 
			:: r[Cop] < 1 -> driver = Cop;
			:: r[Dad] < 1 -> driver = Dad;
			:: r[Mom] < 1 -> driver = Mom;
		fi;
	fi;
}

inline choosePassenger()
{
	if
		:: r[Boat] == 1 -> //boat on right side
			if 
				:: r[Dad] > 0 && driver != Dad -> passenger=Dad;
				:: r[Mom] > 0 && driver != Mom -> passenger=Mom;
				:: r[Cop] > 0 && driver != Cop -> passenger=Cop;
				:: r[Criminal] > 0 && driver != Criminal -> passenger=Criminal;
				:: r[Boy] > 0 && driver != Boy -> passenger=Boy;
				:: r[Girl] > 0 && driver != Girl -> passenger=Girl;
				:: true -> passenger=0;
			fi;
		:: else -> // boat on left side	
			if 
				:: r[Dad] < 1 && driver != Dad -> passenger=Dad;
				:: r[Mom] < 1 && driver != Mom -> passenger=Mom;
				:: r[Cop] < 1 && driver != Cop -> passenger=Cop;
				:: r[Criminal] < 1 && driver != Criminal -> passenger=Criminal;
				:: r[Boy] < 2 && driver != Boy -> passenger=Boy;
				:: r[Girl] < 2 && driver != Girl -> passenger=Girl;
				:: true -> passenger=0;
			fi;
	fi;	
}

inline checkBoatCrew(){
	
	resetCheck();
	check[driver]=1;
	check[passenger]=1;
	
	if 
		:: CheckCriminalUnsafe || CheckBoysUnsafe || CheckGirlsUnsafe -> isBoatCrewOk=0;
		:: else -> isBoatCrewOk=1;
	fi;
}


inline resetCheck(){
	//TODO: make it as for-loop
	atomic{
	check[0]=0;
	check[1]=0;
	check[2]=0;
	check[3]=0;
	check[4]=0;
	check[5]=0;
	check[6]=0;
	check[7]=0;
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
//      :: else -> printf("WHAT?!\n"); assert(0); break; /* Should never happen! */ 
    od;    
}




